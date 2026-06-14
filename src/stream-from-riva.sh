#!/usr/bin/env bash
# Stream screensaver from riva (M2 Mac) to local mpv
# Uses wf-recorder with H.264 encoding over TCP via tailscale

LOCAL_IP="${LOCAL_IP:-100.64.0.3}"
RIVA_HOST="${RIVA_HOST:-riva}"
PORT="${PORT:-9999}"
CRF="${CRF:-22}"
SHADER="${SHADER:-shader}"
# Riva M2 display is 2560x1664, scale down to 2560x1440 for watts
RIVA_WIDTH="${RIVA_WIDTH:-2560}"
RIVA_HEIGHT="${RIVA_HEIGHT:-1664}"
OUT_WIDTH="${OUT_WIDTH:-2560}"
OUT_HEIGHT="${OUT_HEIGHT:-1440}"

echo "Streaming from $RIVA_HOST to $LOCAL_IP:$PORT (${RIVA_WIDTH}x${RIVA_HEIGHT} -> ${OUT_WIDTH}x${OUT_HEIGHT} CRF=$CRF shader=$SHADER)"

# Kill any existing instances
ssh "$RIVA_HOST" "pkill screensaver 2>/dev/null; pkill wf-recorder 2>/dev/null" || true
pkill -f "nc -l $PORT" 2>/dev/null || true
sleep 0.5

# Start the screensaver on riva in background and fullscreen it
echo "Starting screensaver on $RIVA_HOST (shader: $SHADER)..."
ssh "$RIVA_HOST" "cd ~/screensaver-gpu && nix-shell --run 'WAYLAND_DISPLAY=wayland-1 XDG_RUNTIME_DIR=/run/user/1000 ./target/release/screensaver --shader $SHADER &'
sleep 1
# Fullscreen the screensaver window
HYPRLAND_INSTANCE_SIGNATURE=\$(ls /tmp/hypr/ 2>/dev/null | head -1) hyprctl dispatch fullscreen 1 2>/dev/null || true" &

sleep 2

# Start nc listener piped to mpv on internal display
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
    --fs \
    --fs-screen=0 &
MPV_PID=$!

sleep 1

# Start streaming from riva with wf-recorder
# Use scale filter with explicit full range to preserve true blacks
echo "Starting wf-recorder stream..."
ssh "$RIVA_HOST" "cd ~/screensaver-gpu && nix-shell --run '
export WAYLAND_DISPLAY=wayland-1
export XDG_RUNTIME_DIR=/run/user/1000
wf-recorder -y \
    -c libx264 \
    -p preset=ultrafast \
    -p tune=zerolatency \
    -p crf=$CRF \
    -F \"scale=$OUT_WIDTH:$OUT_HEIGHT:in_range=full:out_range=full,format=yuv444p\" \
    -m matroska \
    -f tcp://$LOCAL_IP:$PORT 2>/dev/null
'" &
WF_PID=$!

echo "Stream started. Press Ctrl+C to stop."

# Wait and cleanup on exit
trap "kill $MPV_PID $WF_PID 2>/dev/null; ssh $RIVA_HOST 'pkill wf-recorder; pkill screensaver' 2>/dev/null" EXIT
wait $MPV_PID
