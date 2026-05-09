#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
XCRUN_BIN="${XCRUN_BIN:-/usr/bin/xcrun}"
DEVICE="${SIMULATOR_ID:-booted}"
BUNDLE_ID="${BUNDLE_ID:-com.local.NightBreath}"
APPEARANCE="${APPEARANCE:-light}"
WAIT_SECONDS="${SCREENSHOT_WAIT_SECONDS:-2}"
SURFACE="${APP_STORE_SCREENSHOT_SURFACE:-appStoreMarketing}"
TOP_CROP_PX="${TOP_CROP_PX:-160}"
BOTTOM_CROP_PX="${BOTTOM_CROP_PX:-220}"
RAW_DIR="$REPO_ROOT/Docs/Screenshots/AppStore/raw"
REVIEW_DIR="$REPO_ROOT/Docs/Screenshots/AppStore/review-cropped"

CAPTURES=(
  "homeDashboard:01_home_dashboard_light.png"
  "sleepReport:02_sleep_report_light.png"
  "eventTimeline:03_sleep_timeline_light.png"
  "dailyRhythmReport:04_daily_rhythm_report_light.png"
  "dailyHealthCard:05_daily_health_card_light.png"
  "healthMetricsOverview:06_health_metrics_overview_light.png"
  "privacySettings:07_privacy_settings_light.png"
  "zeroEventReport:08_zero_event_report_light.png"
)

if [[ -n "${APP_STORE_SCREENSHOT_SCENARIOS:-}" ]]; then
  IFS=',' read -r -a requested_scenarios <<< "$APP_STORE_SCREENSHOT_SCENARIOS"
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

mkdir -p "$RAW_DIR" "$REVIEW_DIR"
"$XCRUN_BIN" simctl ui "$DEVICE" appearance "$APPEARANCE"

for item in "${CAPTURES[@]}"; do
  scenario="${item%%:*}"
  filename="${item#*:}"
  raw_output="$RAW_DIR/$filename"
  review_output="$REVIEW_DIR/$filename"

  echo "Launching $BUNDLE_ID with App Store screenshot scenario: $scenario"
  "$XCRUN_BIN" simctl launch --terminate-running-process "$DEVICE" "$BUNDLE_ID" \
    --nightbreath-screenshot-scenario "$scenario" \
    --nightbreath-screenshot-surface "$SURFACE" >/dev/null
  sleep "$WAIT_SECONDS"
  "$XCRUN_BIN" simctl io "$DEVICE" screenshot "$raw_output"
  echo "Saved raw App Store source: ${raw_output#$REPO_ROOT/}"

  TOP_CROP_PX="$TOP_CROP_PX" BOTTOM_CROP_PX="$BOTTOM_CROP_PX" \
    "$SCRIPT_DIR/crop_screenshot_top.sh" "$raw_output" "$review_output"
done

cat <<EOF
App Store screenshot capture complete.

Raw source screenshots:
  ${RAW_DIR#$REPO_ROOT/}

Review-cropped screenshots:
  ${REVIEW_DIR#$REPO_ROOT/}

Use raw source screenshots for App Store Connect size export.
EOF
