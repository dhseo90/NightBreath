#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
XCRUN_BIN="${XCRUN_BIN:-/usr/bin/xcrun}"
XCODEBUILD_BIN="${XCODEBUILD_BIN:-/usr/bin/xcodebuild}"
DEVELOPER_DIR_VALUE="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}"
PROJECT_PATH="${PROJECT_PATH:-$REPO_ROOT/SleepSoundApp.xcodeproj}"
SCHEME="${SCHEME:-SleepSoundApp}"
CONFIGURATION="${CONFIGURATION:-Debug}"
BUNDLE_ID="${BUNDLE_ID:-com.local.NightBreath}"
DERIVED_DATA_PATH="${DERIVED_DATA_PATH:-$REPO_ROOT/.derivedData-clean-simulator-smoke}"
OUTPUT_DIR="${OUTPUT_DIR:-/tmp/nightbreath-clean-simulator-smoke-$(date +%Y%m%d-%H%M%S)}"
WAIT_SECONDS="${WAIT_SECONDS:-2}"
SIMULATOR_ID="${SIMULATOR_ID:-}"

fail() {
  echo "error: $*" >&2
  exit 1
}

require_tool() {
  local tool="$1"
  [[ -x "$tool" ]] || command -v "$tool" >/dev/null 2>&1 || fail "$tool is required."
}

if [[ -z "$SIMULATOR_ID" ]]; then
  fail "Set SIMULATOR_ID to the simulator UDID to erase for this clean-state smoke run."
fi

if [[ "${NIGHTBREATH_ALLOW_SIM_ERASE:-}" != "1" ]]; then
  fail "This script erases SIMULATOR_ID=$SIMULATOR_ID. Re-run with NIGHTBREATH_ALLOW_SIM_ERASE=1."
fi

require_tool "$XCRUN_BIN"
require_tool "$XCODEBUILD_BIN"

APP_PATH="$DERIVED_DATA_PATH/Build/Products/Debug-iphonesimulator/SleepSoundApp.app"
MANIFEST="$OUTPUT_DIR/clean_simulator_smoke_manifest.tsv"

mkdir -p "$OUTPUT_DIR"
printf 'step\tmode\tevidence\tstatus\tnotes\n' > "$MANIFEST"

record_step() {
  local step="$1"
  local mode="$2"
  local evidence="$3"
  local status="$4"
  local notes="$5"
  printf '%s\t%s\t%s\t%s\t%s\n' "$step" "$mode" "$evidence" "$status" "$notes" >> "$MANIFEST"
}

capture_screen() {
  local step="$1"
  local output_name="$2"
  local notes="$3"
  local output="$OUTPUT_DIR/$output_name"

  "$XCRUN_BIN" simctl io "$SIMULATOR_ID" screenshot "$output" >/dev/null
  [[ -f "$output" ]] || fail "Screenshot was not created: $output"
  record_step "$step" "automated" "$output_name" "captured" "$notes"
}

launch_scenario_and_capture() {
  local scenario="$1"
  local output_name="$2"
  local notes="$3"

  "$XCRUN_BIN" simctl launch --terminate-running-process "$SIMULATOR_ID" "$BUNDLE_ID" \
    --nightbreath-screenshot-scenario "$scenario" >/dev/null
  sleep "$WAIT_SECONDS"
  capture_screen "$scenario" "$output_name" "$notes"
}

echo "Resetting simulator: $SIMULATOR_ID"
"$XCRUN_BIN" simctl shutdown "$SIMULATOR_ID" >/dev/null 2>&1 || true
"$XCRUN_BIN" simctl erase "$SIMULATOR_ID"
"$XCRUN_BIN" simctl boot "$SIMULATOR_ID" >/dev/null 2>&1 || true
"$XCRUN_BIN" simctl bootstatus "$SIMULATOR_ID" -b >/dev/null
record_step "simulator-reset" "automated" "$SIMULATOR_ID" "passed" "shutdown, erase, boot, bootstatus completed"

echo "Building $SCHEME ($CONFIGURATION)"
DEVELOPER_DIR="$DEVELOPER_DIR_VALUE" "$XCODEBUILD_BIN" \
  -project "$PROJECT_PATH" \
  -scheme "$SCHEME" \
  -configuration "$CONFIGURATION" \
  -destination "id=$SIMULATOR_ID" \
  -derivedDataPath "$DERIVED_DATA_PATH" \
  CODE_SIGNING_ALLOWED=NO \
  build >/dev/null
[[ -d "$APP_PATH" ]] || fail "Built app was not found: $APP_PATH"
record_step "debug-build" "automated" "$APP_PATH" "passed" "Debug simulator build completed"

echo "Installing $BUNDLE_ID"
"$XCRUN_BIN" simctl install "$SIMULATOR_ID" "$APP_PATH"
"$XCRUN_BIN" simctl privacy "$SIMULATOR_ID" reset microphone "$BUNDLE_ID" >/dev/null 2>&1 || true
record_step "fresh-install" "automated" "$BUNDLE_ID" "passed" "App installed after simulator erase; microphone privacy reset attempted"

echo "Capturing first launch"
"$XCRUN_BIN" simctl launch --terminate-running-process "$SIMULATOR_ID" "$BUNDLE_ID" >/dev/null
sleep "$WAIT_SECONDS"
capture_screen "first-launch" "01_first_launch.png" "Clean install should open onboarding and must not request HealthKit"

launch_scenario_and_capture "sleepStart" "02_sleep_start_scenario.png" "Scenario-backed sleep start screen for layout/CTA smoke"
launch_scenario_and_capture "reportEmpty" "03_report_empty_scenario.png" "Scenario-backed no-report start path smoke"
launch_scenario_and_capture "privacySnapshot" "04_privacy_snapshot.png" "Privacy cover screenshot without app content"
launch_scenario_and_capture "sleepFinalizingSlow" "05_sleep_finalizing_slow.png" "Capture stopped vs report finalization state split"
launch_scenario_and_capture "healthRefreshStates" "06_health_refresh_states.png" "Health refresh idle/running/done/empty/blocked states"
launch_scenario_and_capture "debugAudioSamplesFixture" "07_debug_audio_samples_fixture.png" "DEBUG fixture; no real audio files"

record_step "microphone-permission-prompt" "manual-required" "manual-simulator-interaction" "not-run-by-script" "Tap through onboarding, press 수면 시작, confirm system microphone prompt copy"
record_step "short-sleep-report" "manual-required" "manual-simulator-interaction" "not-run-by-script" "Allow microphone, record briefly, press 수면 종료, confirm report generation"

cat <<EOF
Clean simulator smoke complete.

Output:
  $OUTPUT_DIR

Manifest:
  $MANIFEST

Manual follow-up in the same erased simulator state is still required for:
  - microphone permission prompt copy
  - short sleep session report generation

This script is simulator-only and does not replace real iPhone overnight,
background/lock, HealthKit real-data, or Fitdays app export QA.
EOF
