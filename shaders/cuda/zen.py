#!/usr/bin/env python3
"""
ZEN: Minimal Expression
Intricate yet gentle, expressive yet restrained.
Optimized for playback - compressed but beautiful.
"""

import cupy as cp
import numpy as np
import subprocess
import sys

WIDTH = 2560
HEIGHT = 1440
FPS = 60
DURATION = 300  # 5 minutes

KERNEL = r'''
__device__ float smoothstep(float edge0, float edge1, float x) {
    x = fmaxf(0.0f, fminf(1.0f, (x - edge0) / (edge1 - edge0)));
    return x * x * (3.0f - 2.0f * x);
}

extern "C" __global__ void zen(
    unsigned char* output,
    int width, int height,
    float time
) {
    int x = blockIdx.x * blockDim.x + threadIdx.x;
    int y = blockIdx.y * blockDim.y + threadIdx.y;
    if (x >= width || y >= height) return;
    
    // Normalized coordinates
    float u = (2.0f * x - width) / (float)height;
    float v = (2.0f * y - height) / (float)height;
    
    float t = time * 0.1f;  // Very slow, meditative
    
    // Pure OLED black
    float3 col = make_float3(0.0f, 0.0f, 0.0f);
    
    // ========== ENSO - The Zen Circle ==========
    // An imperfect circle, symbol of enlightenment
    float angle = atan2f(v, u);
    float radius = sqrtf(u*u + v*v);
    
    // The circle breathes
    float breath = 0.4f + 0.05f * sinf(t * 0.5f);
    
    // Imperfection - slight wobble
    float wobble = 0.02f * sinf(angle * 3.0f + t);
    wobble += 0.01f * sinf(angle * 7.0f - t * 0.7f);
    
    // The brush stroke - thick to thin
    float brush_width = 0.03f + 0.02f * sinf(angle + 1.57f);
    float dist_to_circle = fabsf(radius - breath - wobble);
    
    // Gap in the circle (traditional enso)
    float gap = smoothstep(0.0f, 0.3f, fabsf(angle - 2.5f + t * 0.05f));
    
    float enso = expf(-dist_to_circle * dist_to_circle / (brush_width * brush_width)) * gap;
    enso *= 0.8f;
    
    // Ink color - warm off-white like aged paper
    col.x += enso * 0.95f;
    col.y += enso * 0.90f;
    col.z += enso * 0.85f;
    
    // ========== RIPPLES - Inner Peace ==========
    // Subtle concentric ripples from center
    float ripple_phase = radius * 20.0f - t * 2.0f;
    float ripple = sinf(ripple_phase) * 0.5f + 0.5f;
    ripple *= expf(-radius * 4.0f);  // Fade out from center
    ripple *= 0.05f;  // Very subtle
    
    col.x += ripple * 0.6f;
    col.y += ripple * 0.7f;
    col.z += ripple * 0.8f;
    
    // ========== FLOATING PARTICLES - Dust in Sunlight ==========
    // A few gentle motes
    float motes = 0.0f;
    for (int i = 0; i < 5; i++) {
        float fi = (float)i;
        // Each mote drifts slowly
        float mx = 0.5f * sinf(t * 0.3f + fi * 2.1f) * sinf(fi * 1.7f);
        float my = 0.5f * cosf(t * 0.2f + fi * 1.3f) + 0.3f * sinf(t * 0.1f + fi);
        
        float dx = u - mx;
        float dy = v - my;
        float d = sqrtf(dx*dx + dy*dy);
        
        // Soft glow
        float mote = expf(-d * d * 300.0f);
        mote *= 0.3f + 0.2f * sinf(t * 2.0f + fi * 3.0f);
        motes += mote;
    }
    
    // Warm golden dust
    col.x += motes * 0.8f;
    col.y += motes * 0.7f;
    col.z += motes * 0.4f;
    
    // ========== SINGLE WAVE - Quiet Motion ==========
    // One flowing wave across the bottom
    float wave_y = -0.6f + 0.1f * sinf(u * 2.0f + t);
    wave_y += 0.05f * sinf(u * 5.0f - t * 1.5f);
    float wave_dist = fabsf(v - wave_y);
    float wave = expf(-wave_dist * wave_dist * 50.0f);
    wave *= smoothstep(-1.5f, 0.5f, -u);  // Fade at edges
    wave *= 0.15f;
    
    // Blue-grey like ink wash
    col.x += wave * 0.3f;
    col.y += wave * 0.4f;
    col.z += wave * 0.5f;
    
    // ========== TEXTURE - Rice Paper ==========
    // Very subtle paper texture
    float tex_x = floorf(u * 50.0f);
    float tex_y = floorf(v * 50.0f);
    float paper = sinf(tex_x * 127.1f + tex_y * 311.7f) * 43758.5453f;
    paper = paper - floorf(paper);
    paper = paper * 0.02f * (col.x + col.y + col.z);  // Only visible where there's light
    
    col.x += paper;
    col.y += paper;
    col.z += paper;
    
    // ========== CALLIGRAPHY ACCENT ==========
    // A single brush stroke - like a breath
    float stroke_x = u - 0.5f * sinf(t * 0.2f);
    float stroke_y = v - 0.1f;
    float stroke_curve = stroke_y - 0.3f * stroke_x * stroke_x;
    
    // Only show partial stroke
    float stroke_mask = smoothstep(-0.3f, 0.3f, stroke_x);
    stroke_mask *= smoothstep(0.5f, -0.3f, stroke_x);
    
    float stroke = expf(-stroke_curve * stroke_curve * 500.0f) * stroke_mask;
    stroke *= 0.4f;
    stroke *= 0.5f + 0.5f * sinf(t * 0.3f + 1.0f);  // Fade in/out
    
    col.x += stroke * 0.2f;
    col.y += stroke * 0.2f;
    col.z += stroke * 0.3f;
    
    // ========== MOON GLOW ==========
    // Subtle moon in corner
    float moon_x = u - 0.7f;
    float moon_y = v - 0.5f;
    float moon_d = sqrtf(moon_x*moon_x + moon_y*moon_y);
    
    float moon = expf(-moon_d * moon_d * 20.0f);
    moon *= 0.1f * (0.7f + 0.3f * sinf(t * 0.1f));
    
    col.x += moon * 0.7f;
    col.y += moon * 0.8f;
    col.z += moon * 1.0f;
    
    // ========== FINAL ==========
    // Gentle gamma for OLED
    col.x = powf(fmaxf(col.x, 0.0f), 0.9f);
    col.y = powf(fmaxf(col.y, 0.0f), 0.9f);
    col.z = powf(fmaxf(col.z, 0.0f), 0.9f);
    
    col.x = fminf(col.x, 1.0f);
    col.y = fminf(col.y, 1.0f);
    col.z = fminf(col.z, 1.0f);
    
    int idx = (y * width + x) * 3;
    output[idx + 0] = (unsigned char)(col.x * 255.0f);
    output[idx + 1] = (unsigned char)(col.y * 255.0f);
    output[idx + 2] = (unsigned char)(col.z * 255.0f);
}
'''

def main():
    print(f"Rendering ZEN: {WIDTH}x{HEIGHT} @ {FPS}fps, {DURATION}s", flush=True)
    
    zen_kernel = cp.RawKernel(KERNEL, 'zen')
    frame_gpu = cp.zeros((HEIGHT, WIDTH, 3), dtype=cp.uint8)
    
    total_frames = FPS * DURATION
    block = (16, 16)
    grid = ((WIDTH + 15) // 16, (HEIGHT + 15) // 16)
    
    # Compressed encoding - CRF 18 is visually lossless but much smaller
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
        'zen.mkv'
    ], stdin=subprocess.PIPE)
    
    for frame in range(total_frames):
        time_val = frame / FPS
        zen_kernel(grid, block, (frame_gpu, WIDTH, HEIGHT, cp.float32(time_val)))
        ffmpeg.stdin.write(frame_gpu.get().tobytes())
        
        if frame % (FPS * 10) == 0:
            print(f"  {int(time_val)}s / {DURATION}s", flush=True)
    
    ffmpeg.stdin.close()
    ffmpeg.wait()
    print("Done! zen.mkv created", flush=True)

if __name__ == '__main__':
    main()
