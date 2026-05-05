#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
INPUT_DIR="$REPO_ROOT/Docs/Screenshots/README"
OUTPUT_DIR="$INPUT_DIR/cropped"
TOP_CROP_PX="${TOP_CROP_PX:-180}"
BOTTOM_CROP_PX="${BOTTOM_CROP_PX:-320}"
FFMPEG_BIN="${FFMPEG_BIN:-ffmpeg}"

README_SCREENSHOTS=(
  "home_dashboard_light.png"
  "sleep_start_light.png"
  "sleep_report_light.png"
  "sleep_timeline_light.png"
  "morning_brief_light.png"
  "daily_rhythm_report_light.png"
  "daily_health_card_light.png"
  "health_dashboard_light.png"
)

if ! command -v "$FFMPEG_BIN" >/dev/null 2>&1; then
  echo "error: ffmpeg is required. Install it or set FFMPEG_BIN to an ffmpeg-compatible binary." >&2
  exit 1
fi

mkdir -p "$OUTPUT_DIR"

for screenshot in "${README_SCREENSHOTS[@]}"; do
  input="$INPUT_DIR/$screenshot"
  output="$OUTPUT_DIR/$screenshot"

  if [[ ! -f "$input" ]]; then
    echo "error: missing input screenshot: $input" >&2
    exit 1
  fi

  "$FFMPEG_BIN" -hide_banner -loglevel error -y \
    -i "$input" \
    -vf "crop=iw:ih-${TOP_CROP_PX}-${BOTTOM_CROP_PX}:0:${TOP_CROP_PX}" \
    -frames:v 1 \
    -update 1 \
    "$output"

  echo "cropped $screenshot -> Docs/Screenshots/README/cropped/$screenshot (top ${TOP_CROP_PX}px, bottom ${BOTTOM_CROP_PX}px)"
done
