#!/bin/bash
set -e

echo "=== RENDER ALL SHADERS ==="
echo "Waiting for any existing ffmpeg to finish..."
while pgrep -x ffmpeg > /dev/null; do
    sleep 10
    echo "  Still waiting for ffmpeg..."
done
echo "ffmpeg done!"

# Install dependencies if needed
pip install -q cupy-cuda12x

echo ""
echo "=== RENDERING ABYSS (Deep Ocean Bioluminescence) ==="
python3 abyss.py

echo ""
echo "=== RENDERING NEBULA (Cosmic Gas Clouds) ==="
python3 nebula.py

echo ""
echo "=== RENDERING KALEIDOSCOPE (Raymarched Fractals) ==="
python3 kaleidoscope.py

echo ""
echo "=== RE-ENCODING ALL TO CRF 8 ==="

for f in abyss nebula kaleidoscope; do
    if [ -f "${f}.mkv" ]; then
        echo "Re-encoding ${f}.mkv to ${f}_hq.mkv..."
        ffmpeg -y -i "${f}.mkv" -c:v libx264 -preset medium -crf 8 -pix_fmt yuv420p "${f}_hq.mkv"
        echo "  Done: $(ls -lh ${f}_hq.mkv | awk '{print $5}')"
    fi
done

echo ""
echo "=== ALL RENDERS COMPLETE ==="
ls -lh *_hq.mkv *.mkv 2>/dev/null
echo ""
echo "DONE! Ready for download."
