#!/usr/bin/env bash
# Auto-stop ThunderCompute instances after timeout
# Usage: ./thunder-autostop.sh [timeout_minutes]

TIMEOUT_MIN=${1:-30}
echo "Will stop all ThunderCompute instances in $TIMEOUT_MIN minutes"
echo "Started at: $(date)"

sleep $((TIMEOUT_MIN * 60))

echo "Timeout reached at: $(date)"
echo "Stopping all instances..."

for i in 0 1 2 3 4 5; do
    uvx tnr stop $i 2>/dev/null && echo "Stopped instance $i"
done

echo "Done."
