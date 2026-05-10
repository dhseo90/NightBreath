#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
HOME_DASHBOARD="$REPO_ROOT/SleepSoundApp/Features/Dashboard/HomeDashboardView.swift"
SIMULATOR_SCENARIO_VIEW="$REPO_ROOT/SleepSoundApp/Features/Settings/SimulatorScenarioView.swift"

DETAIL_VIEW_FILES=(
  "SleepSoundApp/Features/Dashboard/BloodPressureDashboardView.swift"
  "SleepSoundApp/Features/Dashboard/BodyCompositionDashboardView.swift"
  "SleepSoundApp/Features/Dashboard/CrossMetricDashboardView.swift"
  "SleepSoundApp/Features/Dashboard/FitdaysImportView.swift"
  "SleepSoundApp/Features/Dashboard/HealthCalendarView.swift"
  "SleepSoundApp/Features/Dashboard/HealthMetricsOverviewView.swift"
  "SleepSoundApp/Features/Dashboard/TrendDashboardView.swift"
  "SleepSoundApp/Features/DailyRhythm/MorningBriefView.swift"
  "SleepSoundApp/Features/DailyRhythm/DailyRhythmReportView.swift"
  "SleepSoundApp/Features/DailyRhythm/DailyHealthCardPreviewView.swift"
  "SleepSoundApp/Features/DailyRhythm/DailyHealthCardView.swift"
  "SleepSoundApp/Features/DailyRhythm/EveningCheckInView.swift"
  "SleepSoundApp/Features/Sleep/SleepReportView.swift"
  "SleepSoundApp/Features/Sleep/SleepTimelineView.swift"
  "SleepSoundApp/Features/Sleep/MorningCheckInView.swift"
  "SleepSoundApp/Features/Settings/DevicePlacementGuideView.swift"
  "SleepSoundApp/Features/Settings/PrivacySettingsView.swift"
  "SleepSoundApp/Features/Onboarding/CalibrationView.swift"
)

ROOT_SCREEN_SMOKE_CHECKS=(
  'SleepSoundApp/Features/Dashboard/HomeDashboardView.swift|TabView(selection: $selectedTab)|Home dashboard must keep explicit root tab state.'
  'SleepSoundApp/Features/Dashboard/HomeDashboardView.swift|Label("수면 시작하기"|Home dashboard must keep a sleep-start root CTA.'
  'SleepSoundApp/Features/Dashboard/HomeDashboardView.swift|Label("최근 리포트"|Home dashboard must keep a latest-report CTA.'
  'SleepSoundApp/Features/Dashboard/HomeDashboardView.swift|Label("트렌드"|Home dashboard must keep a sleep trend CTA.'
  'SleepSoundApp/Features/Dashboard/HomeDashboardView.swift|Label("아침 리포트"|Home dashboard must keep a morning report CTA.'
  'SleepSoundApp/Features/Dashboard/HomeDashboardView.swift|Label("오늘의 리듬"|Home dashboard must keep a daily rhythm report CTA.'
  'SleepSoundApp/Features/Dashboard/HomeDashboardView.swift|Label("저녁 체크인"|Home dashboard must keep an evening check-in CTA.'
  'SleepSoundApp/Features/Dashboard/HomeDashboardView.swift|Label("하루 리듬 카드"|Home dashboard must keep a daily health card CTA.'
  'SleepSoundApp/Features/Dashboard/HomeDashboardView.swift|Label("건강 탭에서 자세히"|Home dashboard must keep a health root CTA.'
  'SleepSoundApp/Features/Dashboard/HomeDashboardView.swift|Label("오디오와 데이터 보관"|Settings root must keep a privacy storage entry.'
  'SleepSoundApp/Features/Dashboard/HomeDashboardView.swift|Label("코골기 감지 민감도"|Settings root must keep detector sensitivity entry.'
  'SleepSoundApp/Features/Dashboard/HomeDashboardView.swift|Label("iPhone 배치 가이드"|Settings root must keep device placement entry.'
  'SleepSoundApp/Features/Dashboard/HomeDashboardView.swift|Label("30초 캘리브레이션"|Settings root must keep calibration entry.'
  'SleepSoundApp/Features/Dashboard/HomeDashboardView.swift|Simulator QA / Screenshot Scenario|Debug settings must keep the screenshot scenario entry behind DEBUG.'
  'SleepSoundApp/Features/Sleep/SleepStartView.swift|Text("수면 시작")|Sleep root must show the start state title.'
  'SleepSoundApp/Features/Sleep/SleepStartView.swift|permissionStatusCard|Sleep root must show microphone permission state.'
  'SleepSoundApp/Features/Sleep/SleepStartView.swift|NBPrimaryButton(title: startButtonTitle|Sleep root must keep an explicit start CTA.'
  'SleepSoundApp/Features/Sleep/SleepStartView.swift|sleepStartActionFeedbackView|Sleep root must keep action feedback states.'
  'SleepSoundApp/Features/Sleep/SleepStartView.swift|queueDeferredMicrophonePermissionRefresh|Sleep root must defer permission refresh off the immediate tab switch path.'
  'SleepSoundApp/Features/Sleep/SleepRecordingView.swift|finalizationDetailText|Sleep recording must keep stop/finalization progress feedback visible.'
  'SleepSoundApp/Features/Sleep/SleepReportView.swift|coverageDiagnosticItems|Sleep report must explain limited coverage causes.'
  'SleepSoundApp/Features/Dashboard/HealthDashboardView.swift|건강 데이터 허브|Health root must show the hub summary.'
  'SleepSoundApp/Features/Dashboard/HealthDashboardView.swift|connectHealthData()|Health root must keep explicit HealthKit read action.'
  'SleepSoundApp/Features/Dashboard/HealthDashboardView.swift|healthDataRefreshFeedbackView|Health root must keep visible refresh feedback.'
  'SleepSoundApp/Features/Dashboard/HealthDashboardView.swift|healthRefreshFeedbackSummary|Health root must keep immediate refresh feedback summary.'
  'SleepSoundApp/Features/Dashboard/FitdaysImportView.swift|FitdaysImportFlowStatus|Fitdays import must keep input-preview-save step status.'
  'SleepSoundApp/Features/Dashboard/FitdaysImportView.swift|미리보기 결과 로컬 저장|Fitdays import must keep an explicit preview-result save CTA.'
  'SleepSoundApp/Features/Settings/DebugAudioSamplesView.swift|모든 DEBUG 샘플 삭제|Debug audio samples must keep all-sample cleanup QA action.'
  'SleepSoundApp/App/SleepSoundApp.swift|PrivacySnapshotCoverQAView|Simulator QA must keep a direct privacy snapshot preview.'
  'SleepSoundApp/Features/Dashboard/HealthDashboardView.swift|recentMeasurementShortcutSection|Health root must keep recent measurement shortcut.'
  'SleepSoundApp/Features/Dashboard/HealthDashboardView.swift|dashboardEntrySection|Health root must keep dashboard entry section.'
  'SleepSoundApp/Features/Dashboard/HealthDashboardView.swift|HealthMetricsOverviewView|Health root must link to the metrics overview.'
  'SleepSoundApp/Features/Settings/PrivacySettingsView.swift|저장된 이벤트 오디오 샘플 전체 삭제|Privacy settings must keep event audio deletion action.'
  'SleepSoundApp/Features/Settings/PrivacySettingsView.swift|연결되지 않은 샘플 정리|Privacy settings must keep orphan sample cleanup action.'
  'SleepSoundApp/Features/Settings/PrivacySettingsView.swift|HealthKit에 데이터를 쓰지 않고|Privacy settings must keep HealthKit read-only copy.'
)

SCREENSHOT_DESTINATION_CHECKS=(
  'case .homeDashboard:|Screenshot home dashboard destination is missing.'
  'HomeDashboardView()|Screenshot home dashboard view is missing.'
  'case .sleepStart:|Screenshot sleep start destination is missing.'
  'SleepStartView()|Screenshot sleep start view is missing.'
  'case .sleepReport, .zeroEventReport, .lowCoverageReport:|Screenshot report edge destinations must share the report view.'
  'SleepReportView(report: appState.latestReport, events: appState.latestEvents)|Screenshot sleep report view is missing.'
  'case .eventTimeline:|Screenshot event timeline destination is missing.'
  'SleepTimelineView(report: appState.latestReport, events: appState.latestEvents)|Screenshot event timeline view is missing.'
  'case .dailyRhythmReport:|Screenshot daily rhythm report destination is missing.'
  'DailyRhythmReportView(|Screenshot daily rhythm report view is missing.'
  'case .dailyHealthCard:|Screenshot daily health card destination is missing.'
  'profile: dailyHealthCardProfile|Screenshot daily health card profile wiring is missing.'
  'case .healthDashboard:|Screenshot health dashboard destination is missing.'
  'HealthDashboardView()|Screenshot health dashboard view is missing.'
  'case .healthMetricsOverview:|Screenshot health metrics destination is missing.'
  'HealthMetricsOverviewView(|Screenshot health metrics overview view is missing.'
  'case .fitdaysImportResult:|Screenshot Fitdays result destination is missing.'
  'prioritizesInitialImportResult: true|Fitdays result screenshot must prioritize the public result card.'
  'case .privacySettings:|Screenshot privacy settings destination is missing.'
  'PrivacySettingsView()|Screenshot privacy settings view is missing.'
  'case .eventAudioStorageOff:|Screenshot event audio off destination is missing.'
  'ScreenshotEventAudioStorageOffView()|Screenshot event audio off view is missing.'
  'case .onboarding:|Screenshot onboarding destination is missing.'
  'OnboardingView()|Screenshot onboarding view is missing.'
  'case .devicePlacement:|Screenshot device placement destination is missing.'
  'DevicePlacementGuideView()|Screenshot device placement view is missing.'
  'case .calibration:|Screenshot calibration destination is missing.'
  'CalibrationView()|Screenshot calibration view is missing.'
  'case .reportEmpty:|Screenshot report empty destination is missing.'
  'ScreenshotReportEmptyStateView()|Screenshot report empty view is missing.'
)

fail() {
  echo "error: $*" >&2
  exit 1
}

require_text() {
  local relative_path="$1"
  local pattern="$2"
  local message="$3"
  local file="$REPO_ROOT/$relative_path"

  [[ -f "$file" ]] || fail "Missing file: $relative_path"
  grep -Fq "$pattern" "$file" || fail "$message"
}

[[ -f "$HOME_DASHBOARD" ]] || fail "Missing HomeDashboardView.swift"
[[ -f "$SIMULATOR_SCENARIO_VIEW" ]] || fail "Missing SimulatorScenarioView.swift"

grep -q 'TabView(selection: \$selectedTab)' "$HOME_DASHBOARD" || fail "Home dashboard must use explicit tab selection."
grep -q 'selectedTab = .sleep' "$HOME_DASHBOARD" || fail "Home sleep CTA must switch to the Sleep tab instead of pushing a second root."
grep -q 'selectedTab = .health' "$HOME_DASHBOARD" || fail "Home health CTA must switch to the Health tab instead of pushing a second root."

if grep -A2 'NavigationLink {' "$HOME_DASHBOARD" | grep -q 'SleepStartView()'; then
  fail "Home dashboard must not push SleepStartView as a detail screen."
fi

if grep -A2 'NavigationLink {' "$HOME_DASHBOARD" | grep -q 'HealthDashboardView()'; then
  fail "Home dashboard must not push HealthDashboardView as a detail screen."
fi

if grep -R 'navigationBarBackButtonHidden(true)' "$REPO_ROOT/SleepSoundApp/Features" "$REPO_ROOT/SleepSoundApp/App" >/dev/null; then
  fail "Feature screens must not hide the system back chevron."
fi

checked=0
for relative_path in "${DETAIL_VIEW_FILES[@]}"; do
  file="$REPO_ROOT/$relative_path"
  [[ -f "$file" ]] || fail "Missing detail view file: $relative_path"
  grep -q '\.navigationTitle' "$file" || fail "$relative_path must keep a navigation title."
  grep -q '\.toolbar(.hidden, for: .tabBar)' "$file" || fail "$relative_path must hide the bottom tab bar when pushed."
  checked=$((checked + 1))
done

root_smoke_checked=0
for check in "${ROOT_SCREEN_SMOKE_CHECKS[@]}"; do
  IFS='|' read -r relative_path pattern message <<< "$check"
  require_text "$relative_path" "$pattern" "$message"
  root_smoke_checked=$((root_smoke_checked + 1))
done

scenario_smoke_checked=0
for check in "${SCREENSHOT_DESTINATION_CHECKS[@]}"; do
  IFS='|' read -r pattern message <<< "$check"
  grep -Fq "$pattern" "$SIMULATOR_SCENARIO_VIEW" || fail "$message"
  scenario_smoke_checked=$((scenario_smoke_checked + 1))
done

cat <<EOF
Navigation chrome validation passed.

Major flow smoke validation passed.

Root tabs:
  home, sleep, health, settings

Detail screens checked:
  $checked

Root screen smoke checks:
  $root_smoke_checked

Screenshot scenario destinations checked:
  $scenario_smoke_checked

Policy:
  - root screens keep the bottom tab bar
  - pushed detail screens use the top back chevron and hide the bottom tab bar
  - core root CTAs and screenshot scenario destinations stay reachable for UI QA
EOF
