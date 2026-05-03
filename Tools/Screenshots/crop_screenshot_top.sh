#!/usr/bin/env bash
set -euo pipefail

INPUT_PATH="${1:-}"
OUTPUT_PATH="${2:-}"
TOP_CROP_PX="${TOP_CROP_PX:-180}"
FFMPEG_BIN="${FFMPEG_BIN:-ffmpeg}"

if [[ -z "$INPUT_PATH" || -z "$OUTPUT_PATH" ]]; then
  echo "Usage: Tools/Screenshots/crop_screenshot_top.sh <input.png> <output.png>" >&2
  exit 64
fi

if [[ ! -f "$INPUT_PATH" ]]; then
  echo "error: missing input screenshot: $INPUT_PATH" >&2
  exit 66
fi

if ! command -v "$FFMPEG_BIN" >/dev/null 2>&1; then
  echo "error: ffmpeg is required. Install it or set FFMPEG_BIN to an ffmpeg-compatible binary." >&2
  exit 69
fi

mkdir -p "$(dirname "$OUTPUT_PATH")"

"$FFMPEG_BIN" -hide_banner -loglevel error -y \
  -i "$INPUT_PATH" \
  -vf "crop=iw:ih-${TOP_CROP_PX}:0:${TOP_CROP_PX}" \
  -frames:v 1 \
  -update 1 \
  "$OUTPUT_PATH"

echo "cropped $INPUT_PATH -> $OUTPUT_PATH (top ${TOP_CROP_PX}px)"
