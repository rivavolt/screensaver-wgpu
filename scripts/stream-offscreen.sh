#!/usr/bin/env bash
# Stream screensaver using headless Wayland compositor (no display needed)
# Uses weston headless backend + wf-recorder (DMA-BUF, no CPU readback)

LOCAL_IP="${LOCAL_IP:-100.64.0.3}"
RIVA_HOST="${RIVA_HOST:-riva}"
PORT="${PORT:-9999}"
CRF="${CRF:-18}"
WIDTH="${WIDTH:-2560}"
HEIGHT="${HEIGHT:-1440}"
SHADER="${SHADER:-shader}"

echo "Offscreen streaming from $RIVA_HOST: ${WIDTH}x${HEIGHT} CRF=$CRF shader=$SHADER"

# Kill any existing instances
ssh "$RIVA_HOST" "pkill -f 'weston.*headless'; pkill screensaver; pkill wf-recorder" 2>/dev/null || true
pkill -f "nc -l $PORT" 2>/dev/null || true
sleep 0.5

# Start nc listener piped to mpv (with full color range)
echo "Starting local player..."
nc -l "$PORT" | mpv - \
    --demuxer=lavf \
    --profile=low-latency \
    --untimed \
    --no-cache \
    --cache-pause=no \
    --demuxer-max-bytes=500KiB \
    --demuxer-max-back-bytes=100KiB \
    --video-output-levels=full \
    --fs &
MPV_PID=$!

sleep 1

# Start headless weston + screensaver + wf-recorder on riva
echo "Starting headless compositor on $RIVA_HOST..."
ssh "$RIVA_HOST" "cd ~/screensaver-gpu && nix-shell -p weston wf-recorder --run '
    # Create isolated runtime dir for headless weston
    export XDG_RUNTIME_DIR=/tmp/weston-offscreen-\$\$
    mkdir -p \$XDG_RUNTIME_DIR
    export WAYLAND_DISPLAY=wayland-offscreen

    # Start weston with headless backend
    weston --backend=headless --width=$WIDTH --height=$HEIGHT --socket=wayland-offscreen &
    WESTON_PID=\$!
    sleep 2

    # Start screensaver
    ./target/release/screensaver &
    SCREEN_PID=\$!
    sleep 1

    # Stream with wf-recorder - full color range
    wf-recorder -y \
        -c libx264 \
        -p preset=ultrafast \
        -p tune=zerolatency \
        -p crf=$CRF \
        -p \"x264-params=colorprim=bt709:transfer=bt709:colormatrix=bt709:fullrange=1\" \
        -m matroska \
        -f tcp://$LOCAL_IP:$PORT

    kill \$SCREEN_PID \$WESTON_PID 2>/dev/null
    rm -rf \$XDG_RUNTIME_DIR
'" &
STREAM_PID=$!

echo "Stream started. Press Ctrl+C to stop."

# Wait and cleanup on exit
cleanup() {
    kill $MPV_PID $STREAM_PID 2>/dev/null
    ssh "$RIVA_HOST" "pkill -f 'weston.*headless'; pkill screensaver; pkill wf-recorder" 2>/dev/null
}
trap cleanup EXIT
wait $MPV_PID
