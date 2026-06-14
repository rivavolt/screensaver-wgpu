#!/usr/bin/env bash
# Stream screensaver from riva using headless rendering (no screen capture)
# Direct GPU -> ffmpeg -> TCP stream with proper colors

LOCAL_IP="${LOCAL_IP:-100.64.0.3}"
RIVA_HOST="${RIVA_HOST:-riva}"
PORT="${PORT:-9999}"
CRF="${CRF:-12}"  # 0=lossless, 10-12=visually lossless, 18=high quality
WIDTH="${WIDTH:-2560}"
HEIGHT="${HEIGHT:-1440}"
FPS="${FPS:-60}"
SHADER="${SHADER:-shader}"  # shader, ocean, genesis, night, kaleidoscope

echo "Headless streaming from $RIVA_HOST: ${WIDTH}x${HEIGHT}@${FPS}fps CRF=$CRF shader=$SHADER"
echo "  (CRF 0=lossless, 10-12=visually lossless, 18=high quality)"
echo "  Available shaders: shader, ocean, genesis, night, kaleidoscope"

# Kill any existing instances
ssh "$RIVA_HOST" "pkill -f 'screensaver --headless'; pkill ffmpeg" 2>/dev/null || true
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

# Stream using headless rendering -> ffmpeg -> TCP
# Raw RGBA frames piped directly to ffmpeg, no screen capture overhead
echo "Starting headless renderer on $RIVA_HOST..."
ssh "$RIVA_HOST" "cd ~/screensaver-gpu && nix-shell --run '\
    ./target/release/screensaver --headless --shader $SHADER --width $WIDTH --height $HEIGHT --fps $FPS 2>/dev/null | \
    ffmpeg -f rawvideo -pix_fmt rgba -s ${WIDTH}x${HEIGHT} -r $FPS -i - \
        -c:v libx264 \
        -preset ultrafast \
        -tune zerolatency \
        -crf $CRF \
        -pix_fmt yuv420p \
        -color_range pc \
        -f matroska \
        tcp://$LOCAL_IP:$PORT 2>/dev/null'" &
STREAM_PID=$!

echo "Stream started. Press Ctrl+C to stop."

# Wait and cleanup on exit
trap "kill $MPV_PID $STREAM_PID 2>/dev/null; ssh $RIVA_HOST 'pkill -f \"screensaver --headless\"; pkill ffmpeg' 2>/dev/null" EXIT
wait $MPV_PID
