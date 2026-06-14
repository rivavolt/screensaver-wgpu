# OLED Screensaver GPU Project

## Purpose
GPU-rendered screensaver videos optimized for OLED displays. Pre-rendered on cloud GPUs (A100/RTX), played back locally via hardware decode.

## Target Hardware
- **Playback**: Intel HD 620 with VAAPI hardware decoding
- **Rendering**: Cloud GPUs (ThunderCompute A100XL, RunPod RTX)
- **Display**: 2560x1440 OLED

## Video Specs
- Resolution: 2560x1440
- Framerate: 60fps
- Duration: 5 minutes (300 seconds)
- Codec: H.264 (libx264)
- Quality: CRF 8 for high quality, CRF 18 for rendering intermediates
- Target bitrate: ~25-125 Mbps depending on content complexity

## Shaders

### WGSL (Real-time streaming from riva)
- **shader** (`src/shader.wgsl`) - Default plasma shader with kaleidoscope fractals
- **genesis** (`src/shader-genesis.wgsl`) - Cosmic jellyfish, impossible geometry, central eye, fibonacci spiral
- **ocean** (`src/shader-ocean.wgsl`) - Bioluminescent deep-sea with jellyfish, particles, light rays
- **anima** (`src/shader-anima.wgsl`) - Neural lightning, sacred geometry, aurora ribbons, heartbeat
- **zen** (`src/shader-zen.wgsl`) - Living meditation with fireflies, enso circle, moon, stars
- **night** (`src/shader-night.wgsl`) - Night sky with orbs, shooting stars, aurora wisps
- **fractal** (`src/shader-fractal.wgsl`) - Deep zoom infinite fractals with color cycling
- **electric** (`src/shader-electric.wgsl`) - Neon grids, plasma arcs, synthwave vibes
- **liquid** (`src/shader-liquid.wgsl`) - Iridescent fluid dynamics, oil on water
- **mandala** (`src/shader-mandala.wgsl`) - Sacred geometry, kaleidoscopic symmetry
- **prism** (`src/shader-prism.wgsl`) - Rainbow light dispersion, crystalline refractions

### CUDA (Cloud rendering - for reference)
Located in `shaders/cuda/` - Python+CuPy scripts for A100/RTX batch rendering

## Architecture

### CUDA Shaders (cloud rendering)
Python scripts using CuPy for GPU kernels. Pattern:
```python
import cupy as cp
KERNEL = r'''
extern "C" __global__ void shader_name(unsigned char* output, int width, int height, float time) {
    // CUDA kernel code
}
'''
kernel = cp.RawKernel(KERNEL, 'shader_name')
# Render frames, pipe to ffmpeg
```

### Local Playback
- `scripts/screensaver.sh` - Main screensaver script with swayidle integration
- `scripts/play-video.sh` - mpv with VAAPI acceleration
- Uses mpv with `--hwdec=vaapi` for Intel HD 620 decode

## Encoding Notes
- Lossless intermediate: `-c:v libx264rgb -preset ultrafast -crf 0 -pix_fmt gbrp`
- Final HQ encode: `-c:v libx264 -preset medium -crf 8 -pix_fmt yuv420p`
- Intel HD 620 can decode ~125 Mbps H.264 smoothly via VAAPI

## Design Principles
- **OLED-optimized**: True blacks, high contrast, avoid burn-in with movement
- **Ambient**: Slow, hypnotic motion - not distracting
- **Rich detail**: Leverage cloud GPU power for complex raymarching/particles
- **Seamless loops**: 5-minute duration with potential for seamless looping

## Cloud Rendering
- **ThunderCompute**: A100XL ($1.79/hr), good for batch rendering
- **RunPod**: RTX 4080/4090 ($0.44-0.69/hr), potential for real-time streaming

## Real-Time Streaming from M2 Mac

The wgpu Rust renderer runs on the Asahi Linux M2 Mac ("riva") and streams to the local machine via tailscale.

### Headless Mode (Recommended)
Direct GPU rendering without screen capture - true blacks, no compositor overhead.

```bash
# Build once on riva
ssh riva "cd ~/screensaver-gpu && nix-shell --run 'cargo build --release'"

# Stream headless (best quality)
./scripts/stream-headless.sh

# Custom settings
WIDTH=2560 HEIGHT=1440 FPS=60 CRF=15 ./scripts/stream-headless.sh
```

### Screen Capture Mode (Alternative)
Uses wf-recorder to capture the screen - requires display session.

```bash
./scripts/stream-from-riva.sh
```

### Headless Renderer CLI
```bash
./target/release/screensaver --headless --width 2560 --height 1440 --fps 60
# Outputs raw RGBA frames to stdout, pipe to ffmpeg
```

### Architecture (Headless)
- **Renderer**: wgpu headless on Apple M2 (OpenGL via Mesa AGX)
- **Output**: Raw RGBA frames to stdout (no display needed)
- **Encoding**: ffmpeg libx264 with yuv444p for accurate colors
- **Transport**: TCP over tailscale (100.64.0.x)
- **Playback**: mpv with full color range

### Environment
The `shell.nix` sets up all dependencies:
- wayland, libxkbcommon, libglvnd for runtime
- WGPU_BACKEND=gl for OpenGL backend
- Rust toolchain for building

## Future Ideas
- Audio-reactive shaders
- Time-of-day variations
- Simpler shaders that run locally on Intel HD 620

## File Organization
```
screensaver-gpu/
├── CLAUDE.md           # This file
├── Cargo.toml          # Rust project config
├── shell.nix           # Nix development shell
├── shaders/
│   ├── cuda/           # Python+CuPy GPU shaders for cloud rendering
│   └── glsl/           # GLSL shaders
├── scripts/            # Shell scripts for rendering and playback
├── renders/            # Pre-rendered video files
├── src/                # Rust wgpu renderer source
└── target/             # Rust build output
```

## Shader Selection

Stream a specific shader:
```bash
# Available: shader, genesis, ocean, anima, zen, night
SHADER=ocean ./scripts/stream-headless.sh

# Or with custom settings
SHADER=zen CRF=15 FPS=60 ./scripts/stream-headless.sh
```

List all shaders:
```bash
./target/release/screensaver --list
```
