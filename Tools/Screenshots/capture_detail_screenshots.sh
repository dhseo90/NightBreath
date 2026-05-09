#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
XCRUN_BIN="${XCRUN_BIN:-/usr/bin/xcrun}"
DEVICE="${SIMULATOR_ID:-booted}"
BUNDLE_ID="${BUNDLE_ID:-com.local.NightBreath}"
APPEARANCE="${APPEARANCE:-light}"
WAIT_SECONDS="${SCREENSHOT_WAIT_SECONDS:-2}"

CAPTURES=(
  "trendDashboard:Docs/Screenshots/Home/trend-dashboard.png"
  "sleepRecording:Docs/Screenshots/Sleep/sleep_recording_light.png"
  "morningCheckIn:Docs/Screenshots/Sleep/morning-check-in.png"
  "eveningCheckIn:Docs/Screenshots/DailyRhythm/evening-check-in.png"
  "dailyHealthCardExport:Docs/Screenshots/DailyRhythm/daily-health-card-export-preview.png"
  "reportEmpty:Docs/Screenshots/EdgeStates/report-empty.png"
)

if [[ -n "${DETAIL_SCREENSHOT_SCENARIOS:-}" ]]; then
  IFS=',' read -r -a requested_scenarios <<< "$DETAIL_SCREENSHOT_SCENARIOS"
  filtered_captures=()

  for item in "${CAPTURES[@]}"; do
    scenario="${item%%:*}"
    for requested in "${requested_scenarios[@]}"; do
      if [[ "$scenario" == "$requested" ]]; then
        filtered_captures+=("$item")
      fi
    done
  done

  CAPTURES=("${filtered_captures[@]}")
fi

if ! command -v "$XCRUN_BIN" >/dev/null 2>&1; then
  echo "error: xcrun was not found. Install Xcode command line tools and try again." >&2
  exit 69
fi

if ! "$XCRUN_BIN" simctl list devices booted | grep -q "(Booted)"; then
  echo "error: no booted simulator found. Boot a simulator and install the DEBUG app first." >&2
  exit 65
fi

"$XCRUN_BIN" simctl ui "$DEVICE" appearance "$APPEARANCE"

for item in "${CAPTURES[@]}"; do
  scenario="${item%%:*}"
  output_rel="${item#*:}"
  output="$REPO_ROOT/$output_rel"

  mkdir -p "$(dirname "$output")"
  echo "Launching $BUNDLE_ID with detail screenshot scenario: $scenario"
  "$XCRUN_BIN" simctl launch --terminate-running-process "$DEVICE" "$BUNDLE_ID" \
    --nightbreath-screenshot-scenario "$scenario" >/dev/null
  sleep "$WAIT_SECONDS"
  "$XCRUN_BIN" simctl io "$DEVICE" screenshot "$output"
  echo "Saved $output_rel"

  output_name="$(basename "$output_rel")"
  output_dir="$(dirname "$output_rel")"
  crop_dir="$REPO_ROOT/$output_dir/cropped"
  mkdir -p "$crop_dir"
  "$SCRIPT_DIR/crop_screenshot_top.sh" "$output" "$crop_dir/$output_name"
done

cat <<EOF
Detail screenshot capture complete.

Generated candidates remain captured, quality review pending until visual QA approves them:
  Docs/Screenshots/Home
  Docs/Screenshots/Sleep
  Docs/Screenshots/DailyRhythm
  Docs/Screenshots/EdgeStates
EOF
