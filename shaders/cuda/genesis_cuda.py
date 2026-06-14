#!/usr/bin/env python3
"""Genesis shader rendered via CUDA - for ThunderCompute A100"""
import numpy as np
import cupy as cp
import subprocess
import sys

# Resolution and duration
WIDTH, HEIGHT = 1920, 1080  # 1080p
FPS = 60
DURATION_SEC = 300  # 5 minutes
TOTAL_FRAMES = FPS * DURATION_SEC

# CUDA kernel for Genesis shader
genesis_kernel = cp.RawKernel(r'''
#include <math.h>

#define TAU 6.28318530718f
#define PHI 1.61803398875f

__device__ float hash(float2 p) {
    return fract(sinf(p.x * 127.1f + p.y * 311.7f) * 43758.5453f);
}

__device__ float noise(float2 p) {
    float2 i = make_float2(floorf(p.x), floorf(p.y));
    float2 f = make_float2(p.x - i.x, p.y - i.y);
    float2 u = make_float2(f.x * f.x * (3.0f - 2.0f * f.x), f.y * f.y * (3.0f - 2.0f * f.y));

    float a = hash(i);
    float b = hash(make_float2(i.x + 1.0f, i.y));
    float c = hash(make_float2(i.x, i.y + 1.0f));
    float d = hash(make_float2(i.x + 1.0f, i.y + 1.0f));

    return a + (b - a) * u.x + (c - a) * u.y + (a - b - c + d) * u.x * u.y;
}

__device__ float fbm(float2 p, int octaves) {
    float v = 0.0f, a = 0.5f;
    for (int i = 0; i < octaves; i++) {
        v += a * noise(p);
        float px = p.x * 0.8f - p.y * 0.6f;
        float py = p.x * 0.6f + p.y * 0.8f;
        p = make_float2(px * 2.0f, py * 2.0f);
        a *= 0.5f;
    }
    return v;
}

__device__ float3 dreamColor(float t, float mood) {
    float3 c1 = make_float3(0.1f, 0.0f, 0.2f);
    float3 c2 = make_float3(0.0f, 0.3f, 0.4f);
    float3 c3 = make_float3(0.4f, 0.1f, 0.3f);

    float m1 = sinf(t * TAU) * 0.5f + 0.5f;
    float m2 = sinf(t * TAU * PHI) * 0.5f + 0.5f;

    return make_float3(
        c1.x + (c2.x - c1.x) * m1 + (c3.x - c1.x) * m2,
        c1.y + (c2.y - c1.y) * m1 + (c3.y - c1.y) * m2,
        c1.z + (c2.z - c1.z) * m1 + (c3.z - c1.z) * m2
    );
}

__device__ float3 soul(float t) {
    return make_float3(
        0.5f + 0.5f * cosf(TAU * t),
        0.5f + 0.5f * cosf(TAU * (t + 0.1f)),
        0.5f + 0.5f * cosf(TAU * (t + 0.2f))
    );
}

extern "C" __global__ void genesis(unsigned char* output, int width, int height, float time) {
    int x = blockIdx.x * blockDim.x + threadIdx.x;
    int y = blockIdx.y * blockDim.y + threadIdx.y;

    if (x >= width || y >= height) return;

    float2 uv = make_float2((float)x / width, (float)y / height);
    float2 p = make_float2((uv.x * 2.0f - 1.0f) * (float)width / height, uv.y * 2.0f - 1.0f);

    float t = time * 0.08f;
    float3 col = make_float3(0.0f, 0.0f, 0.0f);

    float breath = sinf(t * 0.5f) * 0.5f + 0.5f;
    float heartbeat = powf(sinf(t * 1.2f) * 0.5f + 0.5f, 8.0f);

    // Void
    float vn = fbm(make_float2(p.x * 3.0f + t * 0.1f, p.y * 3.0f), 5);
    float3 vc = dreamColor(vn, t);
    col.x += vc.x * vn * vn * 0.1f * (0.7f + breath * 0.3f);
    col.y += vc.y * vn * vn * 0.1f * (0.7f + breath * 0.3f);
    col.z += vc.z * vn * vn * 0.1f * (0.7f + breath * 0.3f);

    // Jellyfish (simplified)
    for (int i = 0; i < 4; i++) {
        float fi = (float)i;
        float jt = t * 0.3f + fi * PHI;
        float2 jc = make_float2(sinf(jt) * 0.5f, cosf(jt * 0.7f) * 0.4f);
        float jd = sqrtf((p.x - jc.x) * (p.x - jc.x) + (p.y - jc.y) * (p.y - jc.y));
        float pulse = sinf(t * 2.0f + fi * 1.5f) * 0.3f + 0.7f;
        float bell = fmaxf(0.0f, 1.0f - jd / (0.15f * pulse));
        float glow = expf(-jd * 4.0f) * 0.4f;

        float3 jcol = soul(fi * 0.25f + t * 0.1f);
        float intensity = (bell * 0.5f + glow) * (0.5f + heartbeat * 0.2f);
        col.x += jcol.x * intensity;
        col.y += jcol.y * intensity;
        col.z += jcol.z * intensity;
    }

    // Cosmic strings
    for (int i = 0; i < 5; i++) {
        float fi = (float)i;
        float sy = sinf(t * 0.15f + fi * TAU / 5.0f) * 0.5f;
        float wave = sinf(p.x * 5.0f + t * 2.0f + fi) * 0.1f;
        float sd = fabsf(p.y - sy - wave);
        float str = expf(-sd * 15.0f) * 0.3f;

        float3 sc = dreamColor(fi * 0.2f + t * 0.05f, sinf(fi));
        col.x += sc.x * str;
        col.y += sc.y * str;
        col.z += sc.z * str;
    }

    // Impossible geometry
    float2 geo = p;
    for (int i = 0; i < 4; i++) {
        float fi = (float)i;
        geo.x = fabsf(geo.x) - 0.4f + sinf(t * 0.3f + fi) * 0.1f;
        geo.y = fabsf(geo.y) - 0.4f + sinf(t * 0.3f + fi) * 0.1f;
        float c = cosf(t * 0.1f + fi);
        float s = sinf(t * 0.1f + fi);
        float gx = geo.x * c - geo.y * s;
        float gy = geo.x * s + geo.y * c;
        geo = make_float2(gx, gy);

        float d = sqrtf(geo.x * geo.x + geo.y * geo.y) - 0.1f;
        float shape = expf(-fabsf(d) * 15.0f) * 0.12f;

        float pl = sqrtf(p.x * p.x + p.y * p.y);
        float3 gc = soul(pl + fi * 0.2f + t * 0.3f);
        col.x += gc.x * shape;
        col.y += gc.y * shape;
        col.z += gc.z * shape;
    }

    // River of light
    float ry = sinf(p.x * 2.0f + t) * 0.3f;
    float rd = fabsf(p.y - ry);
    float river = expf(-rd * 8.0f) * 0.25f;
    float3 rc = dreamColor(p.x + t * 0.2f, t);
    col.x += rc.x * river;
    col.y += rc.y * river;
    col.z += rc.z * river;

    // Central eye
    float ed = sqrtf(p.x * p.x + p.y * p.y);
    for (int i = 0; i < 3; i++) {
        float fi = (float)i;
        float rr = 0.15f + fi * 0.1f + sinf(t * 0.7f) * 0.05f;
        float ring = fmaxf(0.0f, 1.0f - fabsf(ed - rr) * 50.0f);
        float3 ec = soul(fi * 0.3f + t * 0.15f);
        col.x += ec.x * ring * 0.35f;
        col.y += ec.y * ring * 0.35f;
        col.z += ec.z * ring * 0.35f;
    }
    float pupil = fmaxf(0.0f, 1.0f - ed / 0.08f);
    col.x *= (1.0f - pupil * 0.8f);
    col.y *= (1.0f - pupil * 0.8f);
    col.z *= (1.0f - pupil * 0.8f);

    // OLED protection - vignette
    float vd = sqrtf(p.x * p.x + p.y * p.y);
    float vig = 1.0f - fminf(1.0f, fmaxf(0.0f, (vd * 0.7f - 0.3f) / 0.8f));
    vig = vig * vig;
    col.x *= vig;
    col.y *= vig;
    col.z *= vig;

    // Darkness variation
    float dark = fbm(make_float2(p.x * 1.5f + t * 0.15f, p.y * 1.5f), 4);
    float shadow = fminf(1.0f, fmaxf(0.0f, (dark - 0.3f) / 0.3f));
    col.x *= 0.5f + shadow * 0.5f;
    col.y *= 0.5f + shadow * 0.5f;
    col.z *= 0.5f + shadow * 0.5f;

    // Breathing
    col.x *= 0.7f + breath * 0.2f + heartbeat * 0.1f;
    col.y *= 0.7f + breath * 0.2f + heartbeat * 0.1f;
    col.z *= 0.7f + breath * 0.2f + heartbeat * 0.1f;

    // Clamp and convert
    col.x = fminf(0.85f, fmaxf(0.0f, col.x - 0.02f));
    col.y = fminf(0.85f, fmaxf(0.0f, col.y - 0.02f));
    col.z = fminf(0.85f, fmaxf(0.0f, col.z - 0.02f));

    int idx = (y * width + x) * 3;
    output[idx] = (unsigned char)(col.x * 255.0f);
    output[idx + 1] = (unsigned char)(col.y * 255.0f);
    output[idx + 2] = (unsigned char)(col.z * 255.0f);
}
''', 'genesis')

def main():
    print(f"Rendering Genesis: {WIDTH}x{HEIGHT} @ {FPS}fps, {DURATION_SEC}s ({TOTAL_FRAMES} frames)")

    # Allocate GPU buffer
    frame_gpu = cp.zeros((HEIGHT * WIDTH * 3,), dtype=cp.uint8)

    # FFmpeg pipe for lossless encoding
    ffmpeg_cmd = [
        'ffmpeg', '-y',
        '-f', 'rawvideo',
        '-vcodec', 'rawvideo',
        '-s', f'{WIDTH}x{HEIGHT}',
        '-pix_fmt', 'rgb24',
        '-r', str(FPS),
        '-i', '-',
        '-c:v', 'libx264rgb',
        '-crf', '0',
        '-preset', 'ultrafast',
        'genesis_render.mkv'
    ]

    pipe = subprocess.Popen(ffmpeg_cmd, stdin=subprocess.PIPE)

    block = (16, 16)
    grid = ((WIDTH + 15) // 16, (HEIGHT + 15) // 16)

    for frame in range(TOTAL_FRAMES):
        time = frame / FPS

        genesis_kernel(grid, block, (frame_gpu, WIDTH, HEIGHT, cp.float32(time)))

        frame_cpu = frame_gpu.get()
        pipe.stdin.write(frame_cpu.tobytes())

        if frame % FPS == 0:
            print(f"  {frame // FPS}/{DURATION_SEC}s ({100 * frame // TOTAL_FRAMES}%)")

    pipe.stdin.close()
    pipe.wait()
    print("Done! Output: genesis_render.mkv")

if __name__ == '__main__':
    main()
