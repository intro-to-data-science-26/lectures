#!/bin/sh
# Batch-convert all PNGs in png/ to JPEG in jpg/ and report the space saved.
# Uses sips, which ships with macOS (no install needed).
# On Linux, install ImageMagick and swap the sips line for:
#   magick "$f" "jpg/$(basename "${f%.png}").jpg"
# Usage: ./convert-images.sh

mkdir -p jpg

for f in png/*.png
do
  out="jpg/$(basename "${f%.png}").jpg"
  sips -s format jpeg -s formatOptions 80 "$f" --out "$out" > /dev/null &&
    echo "converted: $f -> $out"
done

echo ""
echo "Before (png/): $(du -sh png | cut -f1)"
echo "After  (jpg/): $(du -sh jpg | cut -f1)"
