#!/usr/bin/env bash
# Play a pre-rendered video as screensaver (fullscreen, looping)
# Usage: ./play-video.sh [video_file]

VIDEO="${1:-$(ls -t ~/screensaver-gpu/*.mkv 2>/dev/null | head -1)}"

if [ -z "$VIDEO" ] || [ ! -f "$VIDEO" ]; then
    echo "No video found. Record one first with ./record.sh"
    echo "Or specify a video: ./play-video.sh /path/to/video.mkv"
    exit 1
fi

echo "Playing: $VIDEO"
echo "Press Q or ESC to exit"

mpv --fullscreen --loop --no-osc --no-input-default-bindings \
    --input-conf=/dev/stdin "$VIDEO" << 'EOF'
q quit
ESC quit
EOF
