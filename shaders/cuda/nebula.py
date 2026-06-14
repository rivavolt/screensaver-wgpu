#!/usr/bin/env python3
"""
NEBULA GENESIS - Cosmic Gas Clouds
Volumetric nebulae with stars being born, swirling gas and dust.
Journey through a stellar nursery.
"""

import cupy as cp
import numpy as np
import subprocess
import sys

WIDTH = 2560
HEIGHT = 1440
FPS = 60
DURATION = 300

KERNEL = r'''
__device__ float smoothstep(float e0, float e1, float x) {
    x = fmaxf(0.0f, fminf(1.0f, (x - e0) / (e1 - e0)));
    return x * x * (3.0f - 2.0f * x);
}

__device__ float fract(float x) { return x - floorf(x); }

__device__ float hash31(float3 p) {
    p = make_float3(
        fract(p.x * 0.1031f),
        fract(p.y * 0.1030f),
        fract(p.z * 0.0973f)
    );
    float d = (p.x + p.y) * p.z + (p.y + p.z) * p.x + (p.z + p.x) * p.y;
    return fract(d * 19.19f);
}

__device__ float noise3d(float3 p) {
    float3 i = make_float3(floorf(p.x), floorf(p.y), floorf(p.z));
    float3 f = make_float3(fract(p.x), fract(p.y), fract(p.z));

    f.x = f.x * f.x * (3.0f - 2.0f * f.x);
    f.y = f.y * f.y * (3.0f - 2.0f * f.y);
    f.z = f.z * f.z * (3.0f - 2.0f * f.z);

    float n000 = hash31(i);
    float n001 = hash31(make_float3(i.x, i.y, i.z + 1.0f));
    float n010 = hash31(make_float3(i.x, i.y + 1.0f, i.z));
    float n011 = hash31(make_float3(i.x, i.y + 1.0f, i.z + 1.0f));
    float n100 = hash31(make_float3(i.x + 1.0f, i.y, i.z));
    float n101 = hash31(make_float3(i.x + 1.0f, i.y, i.z + 1.0f));
    float n110 = hash31(make_float3(i.x + 1.0f, i.y + 1.0f, i.z));
    float n111 = hash31(make_float3(i.x + 1.0f, i.y + 1.0f, i.z + 1.0f));

    float n00 = n000 + (n001 - n000) * f.z;
    float n01 = n010 + (n011 - n010) * f.z;
    float n10 = n100 + (n101 - n100) * f.z;
    float n11 = n110 + (n111 - n110) * f.z;

    float n0 = n00 + (n01 - n00) * f.y;
    float n1 = n10 + (n11 - n10) * f.y;

    return n0 + (n1 - n0) * f.x;
}

__device__ float fbm3d(float3 p, int octaves) {
    float value = 0.0f;
    float amplitude = 0.5f;
    float frequency = 1.0f;

    for (int i = 0; i < octaves; i++) {
        value += amplitude * noise3d(make_float3(p.x * frequency, p.y * frequency, p.z * frequency));
        amplitude *= 0.5f;
        frequency *= 2.0f;
    }
    return value;
}

// Nebula density function
__device__ float nebula_density(float3 p, float time) {
    // Swirling motion
    float angle = time * 0.05f + p.y * 0.5f;
    float c = cosf(angle), s = sinf(angle);
    float nx = p.x * c - p.z * s;
    float nz = p.x * s + p.z * c;
    p.x = nx;
    p.z = nz;

    // Multiple octaves of turbulent noise
    float density = fbm3d(make_float3(p.x * 0.5f, p.y * 0.5f, p.z * 0.5f + time * 0.02f), 5);

    // Add filament structures
    float filaments = fabsf(sinf(p.x * 3.0f + fbm3d(p, 3) * 2.0f));
    filaments *= fabsf(sinf(p.z * 3.0f + fbm3d(make_float3(p.z, p.x, p.y), 3) * 2.0f));
    density += filaments * 0.3f;

    // Spherical falloff with some variation
    float r = sqrtf(p.x*p.x + p.y*p.y + p.z*p.z);
    float falloff = smoothstep(4.0f, 1.0f, r);
    density *= falloff;

    return fmaxf(density - 0.2f, 0.0f);
}

// Star field
__device__ float stars(float3 rd, float time) {
    float stars = 0.0f;

    for (int i = 0; i < 100; i++) {
        float fi = (float)i;
        float3 star_dir = make_float3(
            hash31(make_float3(fi * 17.0f, 0.0f, 0.0f)) * 2.0f - 1.0f,
            hash31(make_float3(fi * 23.0f, 0.0f, 0.0f)) * 2.0f - 1.0f,
            hash31(make_float3(fi * 31.0f, 0.0f, 0.0f)) * 2.0f - 1.0f
        );
        float len = sqrtf(star_dir.x*star_dir.x + star_dir.y*star_dir.y + star_dir.z*star_dir.z);
        star_dir.x /= len; star_dir.y /= len; star_dir.z /= len;

        float dot = rd.x*star_dir.x + rd.y*star_dir.y + rd.z*star_dir.z;
        if (dot > 0.999f) {
            float twinkle = 0.7f + 0.3f * sinf(time * 3.0f + fi * 7.0f);
            stars += twinkle * powf((dot - 0.999f) * 1000.0f, 2.0f);
        }
    }

    return stars;
}

extern "C" __global__ void nebula(
    unsigned char* output,
    int width, int height,
    float time
) {
    int x = blockIdx.x * blockDim.x + threadIdx.x;
    int y = blockIdx.y * blockDim.y + threadIdx.y;
    if (x >= width || y >= height) return;

    float u = (2.0f * x - width) / (float)height;
    float v = (2.0f * y - height) / (float)height;

    // Camera flying through the nebula
    float cam_z = time * 0.3f;
    float cam_x = sinf(time * 0.1f) * 2.0f;
    float cam_y = cosf(time * 0.07f) * 1.0f;

    float3 ro = make_float3(cam_x, cam_y, cam_z);

    // Ray direction with subtle camera rotation
    float angle_h = time * 0.02f;
    float angle_v = sinf(time * 0.05f) * 0.1f;
    float3 rd = make_float3(u, v, 1.5f);
    float rd_len = sqrtf(rd.x*rd.x + rd.y*rd.y + rd.z*rd.z);
    rd.x /= rd_len; rd.y /= rd_len; rd.z /= rd_len;

    // Rotate ray
    float ch = cosf(angle_h), sh = sinf(angle_h);
    float cv = cosf(angle_v), sv = sinf(angle_v);
    float nx = rd.x * ch - rd.z * sh;
    float nz = rd.x * sh + rd.z * ch;
    rd.x = nx; rd.z = nz;
    float ny = rd.y * cv - rd.z * sv;
    nz = rd.y * sv + rd.z * cv;
    rd.y = ny; rd.z = nz;

    // Background stars
    float star_brightness = stars(rd, time);

    // Volumetric raymarching through nebula
    float3 col = make_float3(0.0f, 0.0f, 0.0f);
    float transmittance = 1.0f;
    float step_size = 0.1f;

    for (int i = 0; i < 64; i++) {
        float t = (float)i * step_size;
        float3 p = make_float3(ro.x + rd.x * t, ro.y + rd.y * t, ro.z + rd.z * t);

        float density = nebula_density(p, time);

        if (density > 0.001f) {
            // Nebula colors based on position and density
            float3 nebula_col;

            // Vary color based on position for interesting structure
            float color_var = fbm3d(make_float3(p.x * 0.3f, p.y * 0.3f, p.z * 0.3f), 3);

            if (color_var < 0.33f) {
                // Deep purple/blue region
                nebula_col = make_float3(0.3f, 0.1f, 0.8f);
            } else if (color_var < 0.5f) {
                // Pink/magenta emission
                nebula_col = make_float3(0.9f, 0.2f, 0.5f);
            } else if (color_var < 0.7f) {
                // Cyan/teal
                nebula_col = make_float3(0.1f, 0.7f, 0.9f);
            } else {
                // Golden/orange
                nebula_col = make_float3(1.0f, 0.6f, 0.2f);
            }

            // Add glow from embedded stars
            float embedded_star = powf(density, 4.0f) * 5.0f;
            nebula_col.x += embedded_star;
            nebula_col.y += embedded_star * 0.9f;
            nebula_col.z += embedded_star * 0.7f;

            // Accumulate color
            float alpha = density * step_size * 2.0f;
            col.x += nebula_col.x * alpha * transmittance;
            col.y += nebula_col.y * alpha * transmittance;
            col.z += nebula_col.z * alpha * transmittance;
            transmittance *= expf(-density * step_size * 2.0f);

            if (transmittance < 0.01f) break;
        }
    }

    // Add background stars through remaining transparency
    col.x += star_brightness * transmittance;
    col.y += star_brightness * 0.95f * transmittance;
    col.z += star_brightness * 0.9f * transmittance;

    // Subtle vignette
    float vignette = 1.0f - (u*u + v*v) * 0.15f;
    col.x *= vignette;
    col.y *= vignette;
    col.z *= vignette;

    // Tone mapping and gamma
    col.x = col.x / (col.x + 1.0f);
    col.y = col.y / (col.y + 1.0f);
    col.z = col.z / (col.z + 1.0f);

    col.x = powf(col.x, 0.85f);
    col.y = powf(col.y, 0.85f);
    col.z = powf(col.z, 0.85f);

    col.x = fminf(fmaxf(col.x, 0.0f), 1.0f);
    col.y = fminf(fmaxf(col.y, 0.0f), 1.0f);
    col.z = fminf(fmaxf(col.z, 0.0f), 1.0f);

    int idx = (y * width + x) * 3;
    output[idx + 0] = (unsigned char)(col.x * 255.0f);
    output[idx + 1] = (unsigned char)(col.y * 255.0f);
    output[idx + 2] = (unsigned char)(col.z * 255.0f);
}
'''

def main():
    print(f"Rendering NEBULA: {WIDTH}x{HEIGHT} @ {FPS}fps, {DURATION}s", flush=True)

    kernel = cp.RawKernel(KERNEL, 'nebula')
    frame_gpu = cp.zeros((HEIGHT, WIDTH, 3), dtype=cp.uint8)

    total_frames = FPS * DURATION
    block = (16, 16)
    grid = ((WIDTH + 15) // 16, (HEIGHT + 15) // 16)

    ffmpeg = subprocess.Popen([
        'ffmpeg', '-y',
        '-f', 'rawvideo',
        '-vcodec', 'rawvideo',
        '-s', f'{WIDTH}x{HEIGHT}',
        '-pix_fmt', 'rgb24',
        '-r', str(FPS),
        '-i', '-',
        '-c:v', 'libx264rgb',
        '-preset', 'ultrafast',
        '-crf', '0',
        '-pix_fmt', 'gbrp',
        'nebula.mkv'
    ], stdin=subprocess.PIPE)

    for frame in range(total_frames):
        time_val = frame / FPS
        kernel(grid, block, (frame_gpu, WIDTH, HEIGHT, cp.float32(time_val)))
        ffmpeg.stdin.write(frame_gpu.get().tobytes())

        if frame % (FPS * 10) == 0:
            print(f"  {int(time_val)}s / {DURATION}s", flush=True)

    ffmpeg.stdin.close()
    ffmpeg.wait()
    print("Done! nebula.mkv created", flush=True)

if __name__ == '__main__':
    main()
