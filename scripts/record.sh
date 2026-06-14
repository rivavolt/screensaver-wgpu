#!/usr/bin/env bash
# Record the screensaver to a lossless video
# Usage: ./record.sh [duration_seconds] [output_name]
#
# Examples:
#   ./record.sh 300 genesis      # 5 minutes of genesis
#   ./record.sh 600 kaleidoscope # 10 minutes

DURATION=${1:-300}  # Default 5 minutes
NAME=${2:-screensaver}
OUTPUT="$HOME/screensaver-gpu/${NAME}_$(date +%Y%m%d_%H%M%S).mkv"

echo "Recording for ${DURATION}s to: $OUTPUT"
echo "Starting screensaver in background..."

cd ~/screensaver-gpu
nix-shell --run "./target/release/screensaver" &
SCREENSAVER_PID=$!

sleep 2  # Wait for window to open

echo "Recording... Press Ctrl+C to stop early"
wf-recorder -g "$(slurp -o)" -c libx264rgb -p crf=0 -f "$OUTPUT" &
RECORDER_PID=$!

# Wait for duration or Ctrl+C
sleep $DURATION 2>/dev/null || true

kill $RECORDER_PID 2>/dev/null
kill $SCREENSAVER_PID 2>/dev/null

echo ""
echo "Done! Video saved to: $OUTPUT"
echo "Play with: mpv --loop '$OUTPUT'"
