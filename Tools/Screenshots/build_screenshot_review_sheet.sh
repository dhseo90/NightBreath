#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
OUTPUT_DIR="${SCREENSHOT_REVIEW_OUTPUT_DIR:-$REPO_ROOT/Docs/Screenshots/review}"
HTML_OUTPUT="$OUTPUT_DIR/screenshot_review_sheet.html"
MANIFEST_OUTPUT="$OUTPUT_DIR/screenshot_review_manifest.tsv"

ITEMS=(
  "README|Home dashboard|Docs/Screenshots/README/home_dashboard_light.png|Docs/Screenshots/README/cropped/home_dashboard_light.png|blocked, recapture required"
  "README|Sleep start|Docs/Screenshots/README/sleep_start_light.png|Docs/Screenshots/README/cropped/sleep_start_light.png|blocked, recapture required"
  "README|Sleep report|Docs/Screenshots/README/sleep_report_light.png|Docs/Screenshots/README/cropped/sleep_report_light.png|blocked, recapture required"
  "README|Event timeline|Docs/Screenshots/README/sleep_timeline_light.png|Docs/Screenshots/README/cropped/sleep_timeline_light.png|blocked, recapture required"
  "README|Morning brief|Docs/Screenshots/README/morning_brief_light.png|Docs/Screenshots/README/cropped/morning_brief_light.png|blocked, recapture required"
  "README|Daily rhythm report|Docs/Screenshots/README/daily_rhythm_report_light.png|Docs/Screenshots/README/cropped/daily_rhythm_report_light.png|blocked, recapture required"
  "README|Daily health card|Docs/Screenshots/README/daily_health_card_light.png|Docs/Screenshots/README/cropped/daily_health_card_light.png|blocked, recapture required"
  "README|Health dashboard|Docs/Screenshots/README/health_dashboard_light.png|Docs/Screenshots/README/cropped/health_dashboard_light.png|blocked, recapture required"
  "App Store|Home dashboard|Docs/Screenshots/AppStore/raw/01_home_dashboard_light.png|Docs/Screenshots/AppStore/review-cropped/01_home_dashboard_light.png|blocked, recapture required"
  "App Store|Sleep report|Docs/Screenshots/AppStore/raw/02_sleep_report_light.png|Docs/Screenshots/AppStore/review-cropped/02_sleep_report_light.png|blocked, recapture required"
  "App Store|Event timeline|Docs/Screenshots/AppStore/raw/03_sleep_timeline_light.png|Docs/Screenshots/AppStore/review-cropped/03_sleep_timeline_light.png|blocked, recapture required"
  "App Store|Daily rhythm report|Docs/Screenshots/AppStore/raw/04_daily_rhythm_report_light.png|Docs/Screenshots/AppStore/review-cropped/04_daily_rhythm_report_light.png|blocked, recapture required"
  "App Store|Daily health card|Docs/Screenshots/AppStore/raw/05_daily_health_card_light.png|Docs/Screenshots/AppStore/review-cropped/05_daily_health_card_light.png|blocked, recapture required"
  "App Store|Health metrics overview|Docs/Screenshots/AppStore/raw/06_health_metrics_overview_light.png|Docs/Screenshots/AppStore/review-cropped/06_health_metrics_overview_light.png|blocked, recapture required"
  "App Store|Privacy settings|Docs/Screenshots/AppStore/raw/07_privacy_settings_light.png|Docs/Screenshots/AppStore/review-cropped/07_privacy_settings_light.png|blocked, recapture required"
  "App Store|Zero-event report|Docs/Screenshots/AppStore/raw/08_zero_event_report_light.png|Docs/Screenshots/AppStore/review-cropped/08_zero_event_report_light.png|blocked, recapture required"
  "Health|Health metrics overview|Docs/Screenshots/Health/health_metrics_overview_light.png|Docs/Screenshots/Health/cropped/health_metrics_overview_light.png|captured, quality review pending"
  "Health|Fitdays import|Docs/Screenshots/Health/fitdays_import_light.png|Docs/Screenshots/Health/cropped/fitdays_import_light.png|captured, quality review pending"
  "Health|Fitdays import result|Docs/Screenshots/Health/fitdays_import_result_light.png|Docs/Screenshots/Health/cropped/fitdays_import_result_light.png|blocked, recapture required"
  "Health|Health calendar|Docs/Screenshots/Health/health_calendar_light.png|Docs/Screenshots/Health/cropped/health_calendar_light.png|captured, quality review pending"
  "Health|Daily measurement detail|Docs/Screenshots/Health/daily_measurement_detail_light.png|Docs/Screenshots/Health/cropped/daily_measurement_detail_light.png|captured, quality review pending"
  "Health|Metric detail body water|Docs/Screenshots/Health/metric_detail_body_water_light.png|Docs/Screenshots/Health/cropped/metric_detail_body_water_light.png|captured, quality review pending"
  "Health|Metric detail BMR|Docs/Screenshots/Health/metric_detail_basal_metabolic_rate_light.png|Docs/Screenshots/Health/cropped/metric_detail_basal_metabolic_rate_light.png|captured, quality review pending"
  "Health|Blood pressure dashboard|Docs/Screenshots/Health/blood_pressure_dashboard_light.png|Docs/Screenshots/Health/cropped/blood_pressure_dashboard_light.png|captured, quality review pending"
  "Health|Body composition dashboard|Docs/Screenshots/Health/body_composition_dashboard_light.png|Docs/Screenshots/Health/cropped/body_composition_dashboard_light.png|captured, quality review pending"
  "Health|Cross metric dashboard|Docs/Screenshots/Health/cross_metric_dashboard_light.png|Docs/Screenshots/Health/cropped/cross_metric_dashboard_light.png|captured, quality review pending"
  "Privacy|Privacy settings|Docs/Screenshots/Privacy/privacy_settings_light.png|Docs/Screenshots/Privacy/cropped/privacy_settings_light.png|captured, quality review pending"
  "Privacy|Onboarding|Docs/Screenshots/Privacy/onboarding_light.png|Docs/Screenshots/Privacy/cropped/onboarding_light.png|captured, quality review pending"
  "Privacy|Device placement|Docs/Screenshots/Privacy/device_placement_guide_light.png|Docs/Screenshots/Privacy/cropped/device_placement_guide_light.png|captured, quality review pending"
  "Privacy|Calibration|Docs/Screenshots/Privacy/calibration_light.png|Docs/Screenshots/Privacy/cropped/calibration_light.png|captured, quality review pending"
)

relative_to_review_dir() {
  local path="$1"
  case "$path" in
    Docs/Screenshots/*)
      printf '../%s' "${path#Docs/Screenshots/}"
      ;;
    *)
      printf '%s' "$path"
      ;;
  esac
}

manual_gate="internal label 없음 / crop 정렬 / 주요 CTA와 title 노출 / 긴 한국어 문구 가독성 / 실제 개인 데이터 없음 / DEBUG-only 화면 분리"

mkdir -p "$OUTPUT_DIR"

cat > "$MANIFEST_OUTPUT" <<EOF
group	title	raw_source	review_crop	status	manual_gate
EOF

cat > "$HTML_OUTPUT" <<'EOF'
<!doctype html>
<html lang="ko">
<head>
  <meta charset="utf-8">
  <title>NightBreath Screenshot Review Sheet</title>
  <style>
    body { margin: 24px; font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif; color: #17202a; background: #f6f4ef; }
    h1 { margin-bottom: 4px; }
    .note { max-width: 960px; line-height: 1.55; color: #52616b; }
    .grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(360px, 1fr)); gap: 18px; margin-top: 24px; }
    .card { background: #fffdf8; border: 1px solid #ded8ca; border-radius: 10px; padding: 14px; box-shadow: 0 1px 4px rgba(0,0,0,0.06); }
    .meta { display: flex; justify-content: space-between; gap: 12px; margin-bottom: 10px; font-size: 13px; color: #52616b; }
    .status { font-weight: 700; color: #925f18; }
    .shots { display: grid; grid-template-columns: 1fr 1fr; gap: 10px; }
    figure { margin: 0; }
    figcaption { margin-bottom: 6px; font-size: 12px; color: #6b7280; }
    img { width: 100%; border: 1px solid #d7d0c2; border-radius: 6px; background: #eee7da; }
    .missing { min-height: 180px; display: grid; place-items: center; border: 1px dashed #b9aa91; border-radius: 6px; color: #8a6d3b; background: #fff6dd; }
    .gate { margin-top: 10px; font-size: 12px; color: #52616b; line-height: 1.45; }
    code { font-size: 11px; word-break: break-all; }
  </style>
</head>
<body>
  <h1>NightBreath Screenshot Review Sheet</h1>
  <p class="note">이 파일은 로컬 visual QA용 산출물입니다. README/App Store/user-facing 문서에 이미지를 다시 노출하기 전에 내부 QA label, crop 정렬, 주요 content 가독성, 실제 개인 데이터 노출 여부를 눈으로 확인합니다.</p>
  <div class="grid">
EOF

for item in "${ITEMS[@]}"; do
  IFS='|' read -r group title raw_source review_crop status <<< "$item"
  raw_abs="$REPO_ROOT/$raw_source"
  review_abs="$REPO_ROOT/$review_crop"
  raw_rel="$(relative_to_review_dir "$raw_source")"
  review_rel="$(relative_to_review_dir "$review_crop")"

  printf '%s\t%s\t%s\t%s\t%s\t%s\n' \
    "$group" "$title" "$raw_source" "$review_crop" "$status" "$manual_gate" >> "$MANIFEST_OUTPUT"

  {
    printf '    <section class="card">\n'
    printf '      <div class="meta"><strong>%s · %s</strong><span class="status">%s</span></div>\n' "$group" "$title" "$status"
    printf '      <div class="shots">\n'
    printf '        <figure><figcaption>Raw source<br><code>%s</code></figcaption>\n' "$raw_source"
    if [[ -f "$raw_abs" ]]; then
      printf '          <img src="%s" alt="%s raw source">\n' "$raw_rel" "$title"
    else
      printf '          <div class="missing">missing raw source</div>\n'
    fi
    printf '        </figure>\n'
    printf '        <figure><figcaption>Review crop<br><code>%s</code></figcaption>\n' "$review_crop"
    if [[ -f "$review_abs" ]]; then
      printf '          <img src="%s" alt="%s review crop">\n' "$review_rel" "$title"
    else
      printf '          <div class="missing">missing review crop</div>\n'
    fi
    printf '        </figure>\n'
    printf '      </div>\n'
    printf '      <div class="gate">%s</div>\n' "$manual_gate"
    printf '    </section>\n'
  } >> "$HTML_OUTPUT"
done

cat >> "$HTML_OUTPUT" <<'EOF'
  </div>
</body>
</html>
EOF

cat <<EOF
Screenshot review sheet generated.

HTML:
  ${HTML_OUTPUT#$REPO_ROOT/}

Manifest:
  ${MANIFEST_OUTPUT#$REPO_ROOT/}
EOF
