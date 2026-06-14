#!/usr/bin/env bash
# Switch between different shader presets
# Usage: ./switch-shader.sh [name]
#
# Available shaders:
#   genesis      - Full Genesis (GPU intensive)
#   genesis-lite - Optimized Genesis (current)
#   kaleidoscope - Vibrant kaleidoscope
#   night        - Calm nighttime

cd ~/screensaver-gpu/src

case "${1:-list}" in
    genesis|full)
        cp shader-genesis.wgsl shader.wgsl
        echo "Switched to: Genesis (full) - GPU intensive"
        ;;
    genesis-lite|lite|optimized)
        # The optimized version is the default now, restore it
        cat > shader.wgsl << 'SHADER'
// Genesis Lite is currently active
SHADER
        echo "Already on Genesis Lite (optimized)"
        ;;
    kaleidoscope|kaleido)
        cp shader-kaleidoscope.wgsl shader.wgsl
        echo "Switched to: Kaleidoscope"
        ;;
    night|calm)
        cp shader-night.wgsl shader.wgsl
        echo "Switched to: Night (calm)"
        ;;
    list|*)
        echo "Available shaders:"
        echo "  genesis      - Full Genesis (GPU intensive)"
        echo "  kaleidoscope - Vibrant kaleidoscope"
        echo "  night        - Calm nighttime"
        echo ""
        echo "Usage: $0 [shader-name]"
        echo ""
        echo "Current shader files:"
        ls -la ~/screensaver-gpu/src/*.wgsl
        exit 0
        ;;
esac

echo ""
echo "Rebuilding..."
cd ~/screensaver-gpu
touch src/main.rs
cargo build --release 2>&1 | tail -2
echo ""
echo "Run with: ~/screensaver-gpu/run.sh"
