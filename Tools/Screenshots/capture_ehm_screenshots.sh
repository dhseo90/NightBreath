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
  "healthMetricsOverview:Docs/Screenshots/Health/health_metrics_overview_light.png"
  "fitdaysImport:Docs/Screenshots/Health/fitdays_import_light.png"
  "fitdaysImportResult:Docs/Screenshots/Health/fitdays_import_result_light.png"
  "importError:Docs/Screenshots/Health/fitdays_import_error_light.png"
  "healthCalendar:Docs/Screenshots/Health/health_calendar_light.png"
  "dailyMeasurementDetail:Docs/Screenshots/Health/daily_measurement_detail_light.png"
  "metricDetail:Docs/Screenshots/Health/metric_detail_body_water_light.png"
  "localOnlyMetric:Docs/Screenshots/Health/metric_detail_basal_metabolic_rate_light.png"
  "bloodPressureDashboard:Docs/Screenshots/Health/blood_pressure_dashboard_light.png"
  "bodyCompositionDashboard:Docs/Screenshots/Health/body_composition_dashboard_light.png"
  "crossMetricDashboard:Docs/Screenshots/Health/cross_metric_dashboard_light.png"
  "healthPermissionEmpty:Docs/Screenshots/EdgeStates/health_permission_empty_light.png"
  "metricDetailEmpty:Docs/Screenshots/EdgeStates/metric_detail_empty_light.png"
  "crossMetricInsufficient:Docs/Screenshots/EdgeStates/cross_metric_insufficient_light.png"
)

README_CROPS=(
  "Docs/Screenshots/Health/health_metrics_overview_light.png:Docs/Screenshots/README/cropped/health_metrics_overview_light.png"
  "Docs/Screenshots/Health/health_calendar_light.png:Docs/Screenshots/README/cropped/health_calendar_light.png"
  "Docs/Screenshots/Health/daily_measurement_detail_light.png:Docs/Screenshots/README/cropped/daily_measurement_detail_light.png"
  "Docs/Screenshots/Health/metric_detail_body_water_light.png:Docs/Screenshots/README/cropped/metric_detail_body_water_light.png"
)

if [[ -n "${SCREENSHOT_SCENARIOS:-}" ]]; then
  IFS=',' read -r -a requested_scenarios <<< "$SCREENSHOT_SCENARIOS"
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
  echo "Launching $BUNDLE_ID with screenshot scenario: $scenario"
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

if [[ -z "${SCREENSHOT_SCENARIOS:-}" ]]; then
  for item in "${README_CROPS[@]}"; do
    input_rel="${item%%:*}"
    output_rel="${item#*:}"
    "$SCRIPT_DIR/crop_screenshot_top.sh" "$REPO_ROOT/$input_rel" "$REPO_ROOT/$output_rel"
  done
fi
