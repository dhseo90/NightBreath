#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
HOME_DASHBOARD="$REPO_ROOT/SleepSoundApp/Features/Dashboard/HomeDashboardView.swift"

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

fail() {
  echo "error: $*" >&2
  exit 1
}

[[ -f "$HOME_DASHBOARD" ]] || fail "Missing HomeDashboardView.swift"

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

cat <<EOF
Navigation chrome validation passed.

Root tabs:
  home, sleep, health, settings

Detail screens checked:
  $checked

Policy:
  - root screens keep the bottom tab bar
  - pushed detail screens use the top back chevron and hide the bottom tab bar
EOF
