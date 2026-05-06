#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
SOURCE_DIR="${APP_STORE_SOURCE_DIR:-$REPO_ROOT/Docs/Screenshots/AppStore/raw}"
OUTPUT_DIR="${APP_STORE_EXPORT_DIR:-$REPO_ROOT/Docs/Screenshots/AppStore/export}"
FFMPEG_BIN="${FFMPEG_BIN:-ffmpeg}"
FIT_MODE="${APP_STORE_EXPORT_FIT_MODE:-contain}"
PAD_COLOR="${APP_STORE_EXPORT_PAD_COLOR:-0xF4F7FF}"
SIZE_FILTER="${APP_STORE_EXPORT_SIZES:-}"
FILE_FILTER="${APP_STORE_EXPORT_FILES:-}"
MANIFEST_PATH="$OUTPUT_DIR/manifest.tsv"

SIZES=(
  "iphone_6_9_1260x2736:1260:2736"
  "iphone_6_9_1290x2796:1290:2796"
  "iphone_6_9_1320x2868:1320:2868"
  "iphone_6_5_1284x2778:1284:2778"
  "iphone_6_5_1242x2688:1242:2688"
  "iphone_6_3_1206x2622:1206:2622"
  "iphone_6_3_1179x2556:1179:2556"
  "iphone_6_1_1170x2532:1170:2532"
  "iphone_6_1_1125x2436:1125:2436"
  "iphone_6_1_1080x2340:1080:2340"
  "iphone_5_5_1242x2208:1242:2208"
)

if ! command -v "$FFMPEG_BIN" >/dev/null 2>&1; then
  echo "error: ffmpeg is required. Install it or set FFMPEG_BIN to an ffmpeg-compatible binary." >&2
  exit 69
fi

if [[ ! -d "$SOURCE_DIR" ]]; then
  echo "error: missing App Store raw source directory: $SOURCE_DIR" >&2
  exit 66
fi

case "$FIT_MODE" in
  contain|cover|stretch) ;;
  *)
    echo "error: APP_STORE_EXPORT_FIT_MODE must be contain, cover, or stretch." >&2
    exit 64
    ;;
esac

matches_filter() {
  local value="$1"
  local alias="$2"
  local filter="$3"

  if [[ -z "$filter" ]]; then
    return 0
  fi

  local old_ifs="$IFS"
  IFS=','
  for requested in $filter; do
    if [[ "$value" == "$requested" || "$alias" == "$requested" ]]; then
      IFS="$old_ifs"
      return 0
    fi
  done
  IFS="$old_ifs"
  return 1
}

video_filter() {
  local width="$1"
  local height="$2"

  case "$FIT_MODE" in
    contain)
      echo "scale=${width}:${height}:force_original_aspect_ratio=decrease,pad=${width}:${height}:(ow-iw)/2:(oh-ih)/2:color=${PAD_COLOR},setsar=1"
      ;;
    cover)
      echo "scale=${width}:${height}:force_original_aspect_ratio=increase,crop=${width}:${height},setsar=1"
      ;;
    stretch)
      echo "scale=${width}:${height},setsar=1"
      ;;
  esac
}

mkdir -p "$OUTPUT_DIR"
printf "size_label\twidth\theight\tfit_mode\tinput\toutput\n" > "$MANIFEST_PATH"

shopt -s nullglob
input_files=("$SOURCE_DIR"/*.png)

if (( ${#input_files[@]} == 0 )); then
  echo "error: no PNG screenshots found in $SOURCE_DIR" >&2
  exit 66
fi

export_count=0

for input_path in "${input_files[@]}"; do
  filename="$(basename "$input_path")"

  if ! matches_filter "$filename" "${filename%.png}" "$FILE_FILTER"; then
    continue
  fi

  for item in "${SIZES[@]}"; do
    label="${item%%:*}"
    dimensions="${item#*:}"
    width="${dimensions%%:*}"
    height="${dimensions##*:}"
    alias="${width}x${height}"

    if ! matches_filter "$label" "$alias" "$SIZE_FILTER"; then
      continue
    fi

    output_subdir="$OUTPUT_DIR/$label"
    output_path="$output_subdir/$filename"
    mkdir -p "$output_subdir"

    "$FFMPEG_BIN" -hide_banner -loglevel error -y \
      -i "$input_path" \
      -vf "$(video_filter "$width" "$height")" \
      -frames:v 1 \
      -update 1 \
      "$output_path"

    printf "%s\t%s\t%s\t%s\t%s\t%s\n" \
      "$label" "$width" "$height" "$FIT_MODE" \
      "${input_path#$REPO_ROOT/}" "${output_path#$REPO_ROOT/}" >> "$MANIFEST_PATH"
    export_count=$((export_count + 1))
  done
done

if (( export_count == 0 )); then
  echo "error: no screenshots were exported. Check APP_STORE_EXPORT_SIZES or APP_STORE_EXPORT_FILES." >&2
  exit 65
fi

cat <<EOF
App Store Connect screenshot export complete.

Output:
  ${OUTPUT_DIR#$REPO_ROOT/}

Manifest:
  ${MANIFEST_PATH#$REPO_ROOT/}

Fit mode:
  $FIT_MODE

Exported files:
  $export_count
EOF
