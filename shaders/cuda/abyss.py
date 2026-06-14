#!/usr/bin/env python3
"""
ABYSS - Deep Ocean Bioluminescence
Organic, flowing creatures of light in the deep dark ocean.
Particles dance like jellyfish and plankton in the abyss.
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

// Hash functions for pseudo-randomness
__device__ float hash11(float p) {
    p = fract(p * 0.1031f);
    p *= p + 33.33f;
    p *= p + p;
    return fract(p);
}

__device__ float hash21(float x, float y) {
    float3 p3 = make_float3(fract(x * 0.1031f), fract(y * 0.1030f), fract(x * 0.0973f));
    p3.x += (p3.x + p3.y + p3.z) * (p3.y + 19.19f);
    return fract((p3.x + p3.y) * p3.z);
}

// Simplex-like noise
__device__ float noise(float x, float y) {
    float ix = floorf(x);
    float iy = floorf(y);
    float fx = fract(x);
    float fy = fract(y);

    float ux = fx * fx * (3.0f - 2.0f * fx);
    float uy = fy * fy * (3.0f - 2.0f * fy);

    float a = hash21(ix, iy);
    float b = hash21(ix + 1.0f, iy);
    float c = hash21(ix, iy + 1.0f);
    float d = hash21(ix + 1.0f, iy + 1.0f);

    return a + (b-a)*ux + (c-a)*uy + (a-b-c+d)*ux*uy;
}

// Fractal Brownian Motion
__device__ float fbm(float x, float y, int octaves) {
    float value = 0.0f;
    float amplitude = 0.5f;
    float frequency = 1.0f;

    for (int i = 0; i < octaves; i++) {
        value += amplitude * noise(x * frequency, y * frequency);
        amplitude *= 0.5f;
        frequency *= 2.0f;
    }
    return value;
}

// Jellyfish-like pulsing creature
__device__ float jellyfish(float x, float y, float cx, float cy, float time, float phase) {
    float dx = x - cx;
    float dy = y - cy;
    float r = sqrtf(dx*dx + dy*dy);
    float angle = atan2f(dy, dx);

    // Pulsing body
    float pulse = 0.15f + 0.05f * sinf(time * 2.0f + phase);
    float tentacles = 0.03f * sinf(angle * 8.0f + time * 3.0f + phase);
    float body = smoothstep(pulse + tentacles, pulse * 0.8f, r);

    // Inner glow
    float glow = expf(-r * r * 40.0f);

    // Trailing tendrils
    float trail = 0.0f;
    if (dy > 0.0f) {
        float wave = sinf(dy * 20.0f - time * 4.0f + phase) * 0.02f;
        float trail_width = 0.02f * expf(-dy * 3.0f);
        trail = smoothstep(trail_width, 0.0f, fabsf(dx - wave));
        trail *= smoothstep(0.5f, 0.0f, dy);
    }

    return body * 0.8f + glow * 0.6f + trail * 0.3f;
}

// Plankton particles
__device__ float plankton(float x, float y, float time) {
    float intensity = 0.0f;

    for (int i = 0; i < 20; i++) {
        float fi = (float)i;
        float px = hash11(fi * 17.3f) * 2.0f - 1.0f;
        float py = hash11(fi * 31.7f) * 2.0f - 1.0f;

        // Gentle floating motion
        px += sinf(time * 0.5f + fi) * 0.3f;
        py += cosf(time * 0.3f + fi * 0.7f) * 0.2f;
        py = fmodf(py + time * 0.05f + 1.0f, 2.0f) - 1.0f;

        float dx = x - px;
        float dy = y - py;
        float r = sqrtf(dx*dx + dy*dy);

        // Twinkling
        float twinkle = 0.5f + 0.5f * sinf(time * 5.0f + fi * 7.0f);
        intensity += expf(-r * r * 500.0f) * twinkle;
    }

    return intensity;
}

// Deep sea ambient caustics
__device__ float caustics(float x, float y, float time) {
    float c1 = fbm(x * 3.0f + time * 0.2f, y * 3.0f, 4);
    float c2 = fbm(x * 3.0f - time * 0.15f, y * 3.0f + time * 0.1f, 4);
    return powf(c1 * c2, 2.0f) * 3.0f;
}

extern "C" __global__ void abyss(
    unsigned char* output,
    int width, int height,
    float time
) {
    int x = blockIdx.x * blockDim.x + threadIdx.x;
    int y = blockIdx.y * blockDim.y + threadIdx.y;
    if (x >= width || y >= height) return;

    float u = (2.0f * x - width) / (float)height;
    float v = (2.0f * y - height) / (float)height;

    // Deep blue-black base
    float depth = 0.02f + 0.01f * fbm(u * 2.0f, v * 2.0f + time * 0.02f, 3);
    float r = depth * 0.1f;
    float g = depth * 0.2f;
    float b = depth * 0.4f;

    // Subtle caustics from above
    float caust = caustics(u, v, time) * 0.03f;
    r += caust * 0.2f;
    g += caust * 0.5f;
    b += caust;

    // Multiple jellyfish at different positions
    for (int i = 0; i < 5; i++) {
        float fi = (float)i;
        float phase = fi * 1.7f;

        // Slowly drifting positions
        float cx = sinf(time * 0.1f + phase) * 0.6f + hash11(fi * 13.0f) * 0.4f - 0.2f;
        float cy = cosf(time * 0.07f + phase * 1.3f) * 0.5f + hash11(fi * 23.0f) * 0.3f - 0.2f;

        float jelly = jellyfish(u, v, cx, cy, time, phase);

        // Bioluminescent colors - cyan, magenta, blue variations
        float hue = fmodf(0.5f + fi * 0.1f + time * 0.02f, 1.0f);
        float jr, jg, jb;

        if (hue < 0.33f) {
            jr = 0.2f; jg = 0.8f; jb = 1.0f;  // Cyan
        } else if (hue < 0.66f) {
            jr = 0.8f; jg = 0.2f; jb = 1.0f;  // Magenta
        } else {
            jr = 0.3f; jg = 0.5f; jb = 1.0f;  // Blue
        }

        r += jelly * jr * (0.5f + 0.3f * sinf(time + phase));
        g += jelly * jg * (0.5f + 0.3f * sinf(time + phase));
        b += jelly * jb * (0.5f + 0.3f * sinf(time + phase));
    }

    // Floating plankton sparkles
    float plank = plankton(u, v, time);
    r += plank * 0.3f;
    g += plank * 0.8f;
    b += plank * 1.0f;

    // Subtle color shifting waves
    float wave = 0.5f + 0.5f * sinf(v * 3.0f - time * 0.5f);
    r *= 0.9f + 0.1f * wave;
    g *= 0.95f + 0.05f * wave;

    // Vignette for depth
    float vignette = 1.0f - (u*u + v*v) * 0.3f;
    r *= vignette;
    g *= vignette;
    b *= vignette;

    // Gamma correction and clamp
    r = powf(fmaxf(r, 0.0f), 0.9f);
    g = powf(fmaxf(g, 0.0f), 0.9f);
    b = powf(fmaxf(b, 0.0f), 0.9f);

    r = fminf(r, 1.0f);
    g = fminf(g, 1.0f);
    b = fminf(b, 1.0f);

    int idx = (y * width + x) * 3;
    output[idx + 0] = (unsigned char)(r * 255.0f);
    output[idx + 1] = (unsigned char)(g * 255.0f);
    output[idx + 2] = (unsigned char)(b * 255.0f);
}
'''

def main():
    print(f"Rendering ABYSS: {WIDTH}x{HEIGHT} @ {FPS}fps, {DURATION}s", flush=True)

    kernel = cp.RawKernel(KERNEL, 'abyss')
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
        'abyss.mkv'
    ], stdin=subprocess.PIPE)

    for frame in range(total_frames):
        time_val = frame / FPS
        kernel(grid, block, (frame_gpu, WIDTH, HEIGHT, cp.float32(time_val)))
        ffmpeg.stdin.write(frame_gpu.get().tobytes())

        if frame % (FPS * 10) == 0:
            print(f"  {int(time_val)}s / {DURATION}s", flush=True)

    ffmpeg.stdin.close()
    ffmpeg.wait()
    print("Done! abyss.mkv created", flush=True)

if __name__ == '__main__':
    main()
