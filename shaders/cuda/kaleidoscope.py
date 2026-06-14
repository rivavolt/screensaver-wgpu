#!/usr/bin/env python3
"""
KALEIDOSCOPE INFINITY
Maximum A100 power - complex raymarched fractals with kaleidoscopic symmetry.
Rich, intricate patterns that would be impossible in real-time.
Compressed for smooth playback.
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

__device__ float3 hsv2rgb(float h, float s, float v) {
    float c = v * s;
    float x = c * (1.0f - fabsf(fmodf(h * 6.0f, 2.0f) - 1.0f));
    float m = v - c;
    float3 rgb;
    int i = (int)(h * 6.0f) % 6;
    if (i == 0) { rgb.x = c; rgb.y = x; rgb.z = 0; }
    else if (i == 1) { rgb.x = x; rgb.y = c; rgb.z = 0; }
    else if (i == 2) { rgb.x = 0; rgb.y = c; rgb.z = x; }
    else if (i == 3) { rgb.x = 0; rgb.y = x; rgb.z = c; }
    else if (i == 4) { rgb.x = x; rgb.y = 0; rgb.z = c; }
    else { rgb.x = c; rgb.y = 0; rgb.z = x; }
    rgb.x += m; rgb.y += m; rgb.z += m;
    return rgb;
}

// Rotate 2D
__device__ void rot2d(float& x, float& y, float a) {
    float c = cosf(a), s = sinf(a);
    float nx = x*c - y*s;
    float ny = x*s + y*c;
    x = nx; y = ny;
}

// Kaleidoscope fold - reflect around N mirrors
__device__ void kaleido(float& x, float& y, int n) {
    float angle = 3.14159265f / (float)n;
    float r = sqrtf(x*x + y*y);
    float a = atan2f(y, x);
    a = fabsf(fmodf(a + angle, angle * 2.0f) - angle);
    x = r * cosf(a);
    y = r * sinf(a);
}

// Simplex-like noise for 3D variation
__device__ float hash(float3 p) {
    p = make_float3(
        fract(p.x * 127.1f + p.y * 311.7f + p.z * 74.7f),
        fract(p.y * 269.5f + p.z * 183.3f + p.x * 246.1f),
        fract(p.z * 113.5f + p.x * 271.9f + p.y * 124.6f)
    );
    return fract(sinf(p.x + p.y + p.z) * 43758.5453f);
}

// SDF for a 3D mandelbulb-like fractal
__device__ float mandelbulb(float3 pos, float power, int iters) {
    float3 z = pos;
    float dr = 1.0f;
    float r = 0.0f;
    
    for (int i = 0; i < iters; i++) {
        r = sqrtf(z.x*z.x + z.y*z.y + z.z*z.z);
        if (r > 2.0f) break;
        
        float theta = acosf(z.z / r);
        float phi = atan2f(z.y, z.x);
        dr = powf(r, power - 1.0f) * power * dr + 1.0f;
        
        float zr = powf(r, power);
        theta *= power;
        phi *= power;
        
        z.x = zr * sinf(theta) * cosf(phi) + pos.x;
        z.y = zr * sinf(theta) * sinf(phi) + pos.y;
        z.z = zr * cosf(theta) + pos.z;
    }
    
    return 0.5f * logf(r) * r / dr;
}

// Raymarched scene
__device__ float scene(float3 p, float time) {
    // Apply time-varying rotation
    rot2d(p.x, p.z, time * 0.1f);
    rot2d(p.y, p.z, time * 0.07f);
    
    // Kaleidoscopic folding in 3D
    kaleido(p.x, p.y, 6);
    kaleido(p.y, p.z, 5);
    
    // Multiple scaled fractals
    float d = 1e10f;
    float scale = 1.0f;
    
    for (int i = 0; i < 3; i++) {
        float3 q = p;
        q.x = fmodf(q.x + 2.0f, 4.0f) - 2.0f;
        q.y = fmodf(q.y + 2.0f, 4.0f) - 2.0f;
        q.z = fmodf(q.z + 2.0f, 4.0f) - 2.0f;
        
        float power = 8.0f + sinf(time * 0.3f + (float)i) * 2.0f;
        float3 q_scaled = make_float3(q.x * 0.5f, q.y * 0.5f, q.z * 0.5f);
        float fractal = mandelbulb(q_scaled, power, 6) * 2.0f;
        d = fminf(d, fractal / scale);
        
        p.x *= 1.5f; p.y *= 1.5f; p.z *= 1.5f;
        scale *= 1.5f;
    }
    
    return d;
}

extern "C" __global__ void kaleidoscope(
    unsigned char* output,
    int width, int height,
    float time
) {
    int x = blockIdx.x * blockDim.x + threadIdx.x;
    int y = blockIdx.y * blockDim.y + threadIdx.y;
    if (x >= width || y >= height) return;
    
    float u = (2.0f * x - width) / (float)height;
    float v = (2.0f * y - height) / (float)height;
    
    // Apply 2D kaleidoscope
    int kaleido_n = 6 + (int)(sinf(time * 0.2f) * 2.0f);
    kaleido(u, v, kaleido_n);
    
    // Camera setup
    float3 ro = make_float3(0.0f, 0.0f, -3.0f + sinf(time * 0.1f));
    float3 rd = make_float3(u, v, 1.5f);
    float rd_len = sqrtf(rd.x*rd.x + rd.y*rd.y + rd.z*rd.z);
    rd.x /= rd_len; rd.y /= rd_len; rd.z /= rd_len;
    
    // Camera rotation
    rot2d(rd.x, rd.z, time * 0.05f);
    rot2d(rd.y, rd.z, time * 0.03f);
    rot2d(ro.x, ro.z, time * 0.05f);
    rot2d(ro.y, ro.z, time * 0.03f);
    
    // Raymarch
    float3 col = make_float3(0.0f, 0.0f, 0.0f);
    float t = 0.0f;
    float glow = 0.0f;
    
    for (int i = 0; i < 60; i++) {
        float3 p = make_float3(ro.x + rd.x*t, ro.y + rd.y*t, ro.z + rd.z*t);
        float d = scene(p, time);
        
        if (d < 0.001f) {
            // Hit - calculate color based on position and iteration
            float hue = fmodf(t * 0.1f + time * 0.05f + p.x * 0.1f, 1.0f);
            float sat = 0.7f + 0.3f * sinf(p.y * 5.0f + time);
            float val = 0.8f - t * 0.05f;
            col = hsv2rgb(hue, sat, fmaxf(val, 0.1f));
            break;
        }
        
        // Glow accumulation for rays passing near surface
        glow += 0.01f / (1.0f + d * d * 20.0f);
        
        t += d * 0.8f;
        if (t > 10.0f) break;
    }
    
    // Add glow
    float3 glow_col = hsv2rgb(fmodf(time * 0.1f + glow * 0.5f, 1.0f), 0.8f, 1.0f);
    col.x += glow * glow_col.x * 0.5f;
    col.y += glow * glow_col.y * 0.5f;
    col.z += glow * glow_col.z * 0.5f;
    
    // Post processing
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
    print(f"Rendering KALEIDOSCOPE: {WIDTH}x{HEIGHT} @ {FPS}fps, {DURATION}s", flush=True)
    
    k_kernel = cp.RawKernel(KERNEL, 'kaleidoscope')
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
        '-c:v', 'libx264',
        '-preset', 'medium',
        '-crf', '18',
        '-pix_fmt', 'yuv420p',
        'kaleidoscope.mkv'
    ], stdin=subprocess.PIPE)
    
    for frame in range(total_frames):
        time_val = frame / FPS
        k_kernel(grid, block, (frame_gpu, WIDTH, HEIGHT, cp.float32(time_val)))
        ffmpeg.stdin.write(frame_gpu.get().tobytes())
        
        if frame % (FPS * 10) == 0:
            print(f"  {int(time_val)}s / {DURATION}s", flush=True)
    
    ffmpeg.stdin.close()
    ffmpeg.wait()
    print("Done! kaleidoscope.mkv created", flush=True)

if __name__ == '__main__':
    main()
