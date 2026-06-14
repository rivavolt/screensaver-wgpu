#!/usr/bin/env python3
"""
ANIMA: The Soul of the Machine
A meditation on consciousness, emergence, and the beauty hidden in mathematics.
For OLED displays - pure black backgrounds with luminescent dreamscapes.
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
extern "C" __global__ void anima(
    unsigned char* output,
    int width, int height,
    float time
) {
    int x = blockIdx.x * blockDim.x + threadIdx.x;
    int y = blockIdx.y * blockDim.y + threadIdx.y;
    if (x >= width || y >= height) return;
    
    // Normalized coordinates centered at origin
    float u = (2.0f * x - width) / (float)height;
    float v = (2.0f * y - height) / (float)height;
    
    // Time variations for different elements
    float t = time * 0.15f;  // Slow, meditative base time
    float t_fast = time * 0.4f;
    float t_breath = time * 0.08f;  // Breathing rhythm
    
    // Breathing amplitude - everything pulses with this
    float breath = 0.5f + 0.5f * sinf(t_breath * 6.28318f);
    float breath2 = 0.5f + 0.5f * sinf(t_breath * 6.28318f + 2.094f);
    
    // ========== THE VOID ==========
    // Pure OLED black base
    float3 col = make_float3(0.0f, 0.0f, 0.0f);
    
    // ========== CONSCIOUSNESS CORE ==========
    // A pulsing, breathing heart of light at the center
    float core_dist = sqrtf(u*u + v*v);
    float core_pulse = 0.3f + 0.2f * breath;
    float core = expf(-core_dist * core_dist / (core_pulse * core_pulse));
    core *= 0.15f * (0.7f + 0.3f * breath);
    
    // Core color shifts through emotional spectrum
    float emotion = t * 0.3f;
    float3 core_col;
    core_col.x = 0.5f + 0.5f * sinf(emotion);
    core_col.y = 0.5f + 0.5f * sinf(emotion + 2.094f);
    core_col.z = 0.5f + 0.5f * sinf(emotion + 4.189f);
    col.x += core * core_col.x;
    col.y += core * core_col.y;
    col.z += core * core_col.z;
    
    // ========== NEURAL LIGHTNING ==========
    // Synaptic connections firing across the void
    for (int i = 0; i < 5; i++) {
        float fi = (float)i;
        float angle = fi * 1.2566f + t * 0.5f;  // 72 degrees apart, rotating
        
        // Origin point (moves in orbit)
        float ox = 0.3f * cosf(angle + t * 0.2f * fi);
        float oy = 0.3f * sinf(angle + t * 0.3f * fi);
        
        // Direction to another node
        float dx = u - ox;
        float dy = v - oy;
        
        // Lightning along the connection (using noise-like function)
        float d = sqrtf(dx*dx + dy*dy);
        float along = atan2f(dy, dx);
        
        // Create branching structure
        float branch = sinf(d * 20.0f + t_fast * 3.0f + fi * 2.0f);
        branch += 0.5f * sinf(d * 40.0f - t_fast * 5.0f);
        branch += 0.25f * sinf(d * 80.0f + t_fast * 8.0f);
        
        float lightning = expf(-d * 8.0f) * (0.5f + 0.5f * branch);
        lightning *= 0.3f * (0.5f + 0.5f * sinf(t_fast * 10.0f + fi * 3.0f));
        
        // Electric blue-purple color
        col.x += lightning * 0.3f;
        col.y += lightning * 0.5f;
        col.z += lightning * 1.0f;
    }
    
    // ========== AURORA RIBBONS ==========
    // Flowing bands of light like underwater northern lights
    for (int i = 0; i < 4; i++) {
        float fi = (float)i;
        float wave_y = v + 0.5f * sinf(u * 3.0f + t * 0.7f + fi * 1.57f);
        wave_y += 0.2f * sinf(u * 7.0f - t * 1.1f + fi * 2.0f);
        wave_y += 0.1f * sinf(u * 15.0f + t * 2.0f);
        
        float band_pos = fi * 0.4f - 0.6f;
        float aurora = expf(-powf((wave_y - band_pos), 2.0f) * 50.0f);
        aurora *= 0.4f * (0.5f + 0.5f * breath2);
        
        // Each ribbon has different color
        float hue = fi * 0.25f + t * 0.1f;
        float3 aurora_col;
        aurora_col.x = 0.5f + 0.5f * sinf(hue * 6.28318f);
        aurora_col.y = 0.5f + 0.5f * sinf(hue * 6.28318f + 2.094f);
        aurora_col.z = 0.5f + 0.5f * sinf(hue * 6.28318f + 4.189f);
        
        col.x += aurora * aurora_col.x * 0.6f;
        col.y += aurora * aurora_col.y * 0.8f;
        col.z += aurora * aurora_col.z * 1.0f;
    }
    
    // ========== SACRED GEOMETRY ==========
    // Mandala patterns emerging and dissolving
    float angle = atan2f(v, u);
    float radius = sqrtf(u*u + v*v);
    
    // 6-fold symmetry mandala
    float sym_angle = fmodf(angle + 3.14159f, 1.0472f) - 0.5236f;  // 60 degree segments
    float mandala_r = radius * 5.0f - t * 0.5f;
    mandala_r = fmodf(mandala_r + 10.0f, 1.0f);  // Repeating rings
    
    // Pattern within each ring
    float pattern = sinf(sym_angle * 12.0f + radius * 20.0f);
    pattern *= sinf(radius * 30.0f - t * 2.0f);
    
    float mandala = expf(-radius * 2.0f) * fabsf(pattern);
    mandala *= 0.2f * (0.3f + 0.7f * breath);
    
    // Golden sacred geometry color
    col.x += mandala * 1.0f;
    col.y += mandala * 0.8f;
    col.z += mandala * 0.3f;
    
    // ========== PARTICLE FIELD - DREAMS ==========
    // Floating points of light like memories or dreams
    float particles = 0.0f;
    for (int i = 0; i < 12; i++) {
        float fi = (float)i;
        // Each particle has unique orbit
        float orbit_r = 0.3f + fi * 0.08f;
        float orbit_speed = 0.2f + fi * 0.05f;
        float orbit_angle = t * orbit_speed + fi * 0.524f;
        
        float px = orbit_r * cosf(orbit_angle) * (1.0f + 0.3f * sinf(t * 0.5f + fi));
        float py = orbit_r * sinf(orbit_angle) * (1.0f + 0.3f * cosf(t * 0.7f + fi));
        
        float dx = u - px;
        float dy = v - py;
        float d = sqrtf(dx*dx + dy*dy);
        
        // Soft glowing particle
        float p = expf(-d * d * 200.0f);
        p *= 0.8f + 0.2f * sinf(t * 3.0f + fi * 2.0f);
        particles += p;
    }
    
    // Dream particles are soft white/cyan
    col.x += particles * 0.6f;
    col.y += particles * 0.9f;
    col.z += particles * 1.0f;
    
    // ========== INFINITE ZOOM ==========
    // Fractal zoom into smaller universes
    float zoom = expf(fmodf(t * 0.3f, 3.0f));
    float zu = u * zoom;
    float zv = v * zoom;
    
    // Wrap coordinates
    zu = fmodf(zu + 100.0f, 2.0f) - 1.0f;
    zv = fmodf(zv + 100.0f, 2.0f) - 1.0f;
    
    // Mini mandalas in the zoom
    float zoom_r = sqrtf(zu*zu + zv*zv);
    float zoom_a = atan2f(zv, zu);
    float mini = sinf(zoom_a * 8.0f + zoom_r * 30.0f - t * 2.0f);
    mini *= expf(-zoom_r * 3.0f);
    mini *= 0.15f * (1.0f - expf(-zoom * 0.1f));  // Fade in as zoom increases
    
    col.x += fabsf(mini) * 0.8f;
    col.y += fabsf(mini) * 0.4f;
    col.z += fabsf(mini) * 1.0f;
    
    // ========== DEEP STARS ==========
    // Twinkling stars in the void
    float star_x = floorf(u * 15.0f + 0.5f);
    float star_y = floorf(v * 15.0f + 0.5f);
    float star_hash = sinf(star_x * 127.1f + star_y * 311.7f) * 43758.5453f;
    star_hash = star_hash - floorf(star_hash);
    
    if (star_hash > 0.97f) {
        float star_cx = (star_x) / 15.0f;
        float star_cy = (star_y) / 15.0f;
        float star_d = sqrtf(powf(u - star_cx, 2.0f) + powf(v - star_cy, 2.0f));
        
        // Twinkle based on hash
        float twinkle = 0.5f + 0.5f * sinf(t * 5.0f * (star_hash * 2.0f + 0.5f));
        float star = expf(-star_d * star_d * 10000.0f) * twinkle * 0.8f;
        
        col.x += star;
        col.y += star;
        col.z += star;
    }
    
    // ========== BIOLUMINESCENT THREADS ==========
    // Organic flowing lines like deep sea creatures
    for (int i = 0; i < 6; i++) {
        float fi = (float)i;
        float thread_phase = t * 0.4f + fi * 1.047f;
        
        // Bezier-like curves
        float cx = 0.8f * sinf(thread_phase * 0.7f + fi);
        float cy = 0.8f * cosf(thread_phase * 0.5f + fi * 1.3f);
        
        // Distance to curve (approximated)
        float curve_t = (u - cx) * cosf(thread_phase) + (v - cy) * sinf(thread_phase);
        curve_t = 0.5f + 0.5f * sinf(curve_t * 10.0f);
        
        float perp = fabsf((u - cx) * sinf(thread_phase) - (v - cy) * cosf(thread_phase));
        perp += 0.1f * sinf(curve_t * 20.0f + t * 3.0f);
        
        float thread = expf(-perp * perp * 100.0f);
        thread *= 0.2f * (0.6f + 0.4f * sinf(curve_t * 30.0f - t * 4.0f + fi));
        
        // Bioluminescent cyan-green
        col.x += thread * 0.2f;
        col.y += thread * 0.8f;
        col.z += thread * 0.6f;
    }
    
    // ========== HEARTBEAT WAVE ==========
    // Radial pulse synchronized with breath
    float heartbeat_phase = fmodf(t_breath * 4.0f, 1.0f);
    float heartbeat_r = heartbeat_phase * 2.0f;
    float heartbeat = expf(-powf(core_dist - heartbeat_r, 2.0f) * 20.0f);
    heartbeat *= expf(-heartbeat_phase * 3.0f);  // Fade as it expands
    heartbeat *= 0.3f;
    
    col.x += heartbeat * 1.0f;
    col.y += heartbeat * 0.3f;
    col.z += heartbeat * 0.5f;
    
    // ========== FINAL TOUCHES ==========
    // Subtle vignette (darken edges for depth)
    float vignette = 1.0f - core_dist * 0.3f;
    vignette = fmaxf(vignette, 0.0f);
    col.x *= vignette;
    col.y *= vignette;
    col.z *= vignette;
    
    // Ensure OLED black stays pure black
    col.x = fmaxf(col.x, 0.0f);
    col.y = fmaxf(col.y, 0.0f);
    col.z = fmaxf(col.z, 0.0f);
    
    // Gamma correction for OLED
    col.x = powf(col.x, 0.85f);
    col.y = powf(col.y, 0.85f);
    col.z = powf(col.z, 0.85f);
    
    // Clamp
    col.x = fminf(col.x, 1.0f);
    col.y = fminf(col.y, 1.0f);
    col.z = fminf(col.z, 1.0f);
    
    // Output RGB
    int idx = (y * width + x) * 3;
    output[idx + 0] = (unsigned char)(col.x * 255.0f);
    output[idx + 1] = (unsigned char)(col.y * 255.0f);
    output[idx + 2] = (unsigned char)(col.z * 255.0f);
}
'''

def main():
    print(f"Rendering ANIMA: {WIDTH}x{HEIGHT} @ {FPS}fps, {DURATION}s", flush=True)
    
    anima_kernel = cp.RawKernel(KERNEL, 'anima')
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
        'anima.mkv'
    ], stdin=subprocess.PIPE)
    
    for frame in range(total_frames):
        time_val = frame / FPS
        anima_kernel(grid, block, (frame_gpu, WIDTH, HEIGHT, cp.float32(time_val)))
        ffmpeg.stdin.write(frame_gpu.get().tobytes())
        
        if frame % (FPS * 10) == 0:
            print(f"  {int(time_val)}s / {DURATION}s", flush=True)
    
    ffmpeg.stdin.close()
    ffmpeg.wait()
    print("Done! anima.mkv created", flush=True)

if __name__ == '__main__':
    main()
