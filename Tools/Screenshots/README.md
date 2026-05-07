# Screenshot Capture Workflow

NightBreath / 밤숨의 README와 UI Gallery screenshot은 DEBUG 빌드에서 mock data 또는 simulator scenario만 사용해 생성합니다.

2026-05-07 리뷰 기준 기존 README/App Store 후보 이미지는 crop 정렬과 내부 QA label 노출 문제가 확인되어 사용자-facing 문서에서 숨긴 상태입니다. 아래 workflow로 파일을 생성해도, contact sheet와 실제 문서 렌더링을 눈으로 확인하기 전에는 release-approved로 보지 않습니다.

## 준비

1. Xcode 또는 `xcodebuild`로 DEBUG 빌드를 실행합니다.
2. Simulator에서 앱을 엽니다.
3. 앱의 `설정 > 개발 > Simulator QA / Screenshot Scenario`로 이동합니다.
4. `Screenshot Preset`에서 원하는 scenario를 선택합니다.
5. `스크린샷 프리셋 적용`을 누릅니다.
6. `선택 화면 열기`로 대상 화면을 엽니다.

Release 빌드에는 screenshot/debug mode가 노출되지 않아야 합니다.

## Scenario

- `ScreenshotHomeScenario`
- `ScreenshotSleepStartScenario`
- `ScreenshotRecordingScenario`
- `ScreenshotSleepReportScenario`
- `ScreenshotTimelineScenario`
- `ScreenshotMorningBriefScenario`
- `ScreenshotDailyRhythmScenario`
- `ScreenshotDailyHealthCardScenario`
- `ScreenshotHealthDashboardScenario`
- `ScreenshotBloodPressureDashboardScenario`
- `ScreenshotBodyCompositionDashboardScenario`
- `ScreenshotCrossMetricDashboardScenario`
- `ScreenshotFitdaysImportScenario`
- `ScreenshotFitdaysImportResultScenario`
- `ScreenshotHealthMetricsOverviewScenario`
- `ScreenshotHealthCalendarScenario`
- `ScreenshotDailyMeasurementDetailScenario`
- `ScreenshotMetricDetailScenario`
- `ScreenshotImportErrorScenario`
- `ScreenshotLocalOnlyMetricScenario`
- `ScreenshotHealthPermissionEmptyScenario`
- `ScreenshotMetricDetailEmptyScenario`
- `ScreenshotCrossMetricInsufficientScenario`
- `ScreenshotPrivacyScenario`
- `ScreenshotZeroEventScenario`
- `ScreenshotLowCoverageScenario`
- `ScreenshotEventAudioStorageOffScenario`
- `ScreenshotDebugScenario`

## Light / Dark

Simulator appearance는 수동으로 전환하거나 아래 명령을 사용합니다.

```bash
xcrun simctl ui booted appearance light
xcrun simctl ui booted appearance dark
```

같은 scenario에서 light/dark를 각각 확인하고, 긴 한국어 문구, 배지, chart axis, empty state가 잘리지 않는지 봅니다.

## 저장 경로

README 대표 screenshot 후보:

```text
Docs/Screenshots/README/
```

전체 UI Gallery screenshot 후보:

```text
Docs/Screenshots/Home/
Docs/Screenshots/Sleep/
Docs/Screenshots/DailyRhythm/
Docs/Screenshots/Health/
Docs/Screenshots/Privacy/
Docs/Screenshots/EdgeStates/
Docs/Screenshots/Debug/
```

## Capture 명령

수동 capture 예시:

```bash
xcrun simctl io booted screenshot Docs/Screenshots/README/home_dashboard_light.png
```

보조 스크립트:

```bash
Tools/Screenshots/capture_screenshots.sh Docs/Screenshots/README/home_dashboard_light.png light
```

스크립트는 simulator 목록과 boot 상태를 확인하고, 지정한 경로에 현재 화면을 저장합니다. 앱 navigation과 scenario 선택은 사용자가 DEBUG 화면에서 직접 수행합니다.

## README용 Crop

README 대표 screenshot은 capture 후 상단 status bar, 시간, Dynamic Island 영역을 제거한 crop 버전을 사용합니다. 원본은 보존하고 crop 결과만 `Docs/Screenshots/README/cropped/`에 생성합니다.

```bash
Tools/Screenshots/crop_readme_screenshots.sh
```

현재 crop 기준은 1206x2622 simulator screenshot에서 상단 180px, 하단 320px을 제거하며, 결과 이미지는 1206x2122입니다. 하단 crop은 floating tab bar가 본문 카드나 버튼을 가려 보이지 않게 하기 위한 문서용 처리입니다. README에는 crop 결과를 `width="260"` 정도로 제한해 넣습니다.

Crop 후에는 title, 주요 card, CTA가 잘리지 않는지 확인합니다. crop이 실패했거나 화면을 오해하게 만들면 fake screenshot을 만들지 않고 원본을 다시 capture하거나 crop 값을 조정합니다.

현재 고정 crop 출력은 검토 후보입니다. 화면별로 좌우 치우침, 하단 잘림, 주요 content 가독성, 내부 QA label 노출 여부를 확인한 뒤 README에 연결합니다.

## README 대표 screenshot 파일

현재 README 대표 후보는 아래 8개 light screenshot입니다. 원본은 모두 DEBUG simulator와 mock data 상태에서 생성해야 하며, 품질 gate 통과 전에는 README에 렌더링하지 않습니다.

- `Docs/Screenshots/README/home_dashboard_light.png`
- `Docs/Screenshots/README/sleep_start_light.png`
- `Docs/Screenshots/README/sleep_report_light.png`
- `Docs/Screenshots/README/sleep_timeline_light.png`
- `Docs/Screenshots/README/morning_brief_light.png`
- `Docs/Screenshots/README/daily_rhythm_report_light.png`
- `Docs/Screenshots/README/daily_health_card_light.png`
- `Docs/Screenshots/README/health_dashboard_light.png`

README에서 참조하는 crop output:

- `Docs/Screenshots/README/cropped/home_dashboard_light.png`
- `Docs/Screenshots/README/cropped/sleep_start_light.png`
- `Docs/Screenshots/README/cropped/sleep_report_light.png`
- `Docs/Screenshots/README/cropped/sleep_timeline_light.png`
- `Docs/Screenshots/README/cropped/morning_brief_light.png`
- `Docs/Screenshots/README/cropped/daily_rhythm_report_light.png`
- `Docs/Screenshots/README/cropped/daily_health_card_light.png`
- `Docs/Screenshots/README/cropped/health_dashboard_light.png`

EHM 상세 screenshot 후보는 README에 모두 넣지 않고 UI Gallery 중심으로 관리합니다.

- `Docs/Screenshots/Health/health_metrics_overview_light.png`
- `Docs/Screenshots/Health/fitdays_import_light.png`
- `Docs/Screenshots/Health/fitdays_import_result_light.png`
- `Docs/Screenshots/Health/health_calendar_light.png`
- `Docs/Screenshots/Health/daily_measurement_detail_light.png`
- `Docs/Screenshots/Health/metric_detail_body_water_light.png`
- `Docs/Screenshots/Health/metric_detail_basal_metabolic_rate_light.png`
- `Docs/Screenshots/Health/fitdays_import_error_light.png`
- `Docs/Screenshots/Health/blood_pressure_dashboard_light.png`
- `Docs/Screenshots/Health/body_composition_dashboard_light.png`
- `Docs/Screenshots/Health/cross_metric_dashboard_light.png`
- `Docs/Screenshots/EdgeStates/health_permission_empty_light.png`
- `Docs/Screenshots/EdgeStates/metric_detail_empty_light.png`
- `Docs/Screenshots/EdgeStates/cross_metric_insufficient_light.png`

위 파일이 실제 capture 전이면 `Docs/UI_GALLERY.md`에 `screenshot pending`으로 남기고 image markdown을 만들지 않습니다.

EHM screenshot은 DEBUG app이 설치된 booted simulator에서 launch argument로 바로 열 수 있습니다.

```bash
Tools/Screenshots/capture_ehm_screenshots.sh
```

이 스크립트는 `--nightbreath-screenshot-scenario` launch argument로 EHM 화면을 열고 `Docs/Screenshots/Health/`에 원본을 저장한 뒤, `Docs/Screenshots/Health/cropped/`에 gallery용 crop을 생성합니다. README 후보 4개는 추가로 `Docs/Screenshots/README/cropped/`에 저장합니다.

특정 scenario만 재캡처할 때는 comma-separated filter를 사용합니다.

```bash
SCREENSHOT_SCENARIOS=bloodPressureDashboard,bodyCompositionDashboard,crossMetricDashboard Tools/Screenshots/capture_ehm_screenshots.sh
```

## Onboarding / Privacy / DEBUG Support Screenshot

Onboarding, device placement, calibration, DEBUG-only observability/replay 화면은 별도 script로 캡처합니다. 모든 DEBUG 화면은 synthetic/mock state만 사용하며, 실제 개인 오디오 파일명이나 실제 샘플 내용을 노출하지 않습니다.

```bash
Tools/Screenshots/capture_support_screenshots.sh
```

출력 위치:

```text
Docs/Screenshots/Privacy/
Docs/Screenshots/Privacy/cropped/
Docs/Screenshots/Debug/
Docs/Screenshots/Debug/cropped/
```

현재 캡처 세트:

- `onboarding`
- `devicePlacement`
- `calibration`
- `audioDebug`
- `sampleCapture`
- `datasetReplay`
- `debugTools`

특정 scenario만 재캡처:

```bash
SUPPORT_SCREENSHOT_SCENARIOS=onboarding,audioDebug,debugTools Tools/Screenshots/capture_support_screenshots.sh
```

## App Store Marketing Screenshot

App Store 후보 screenshot은 README 대표 screenshot과 분리해 관리합니다. 원본은 status bar를 포함한 simulator raw capture를 보존하고, 내부 검토용으로만 상하단 crop 이미지를 함께 생성합니다.

현재 저장된 App Store 후보는 재캡처가 필요합니다. 특히 홈/리포트 header에 `Simulator QA` 같은 내부 label이 남아 있으면 App Store 후보로 사용할 수 없습니다.

```bash
Tools/Screenshots/capture_app_store_screenshots.sh
```

출력 위치:

```text
Docs/Screenshots/AppStore/raw/
Docs/Screenshots/AppStore/review-cropped/
```

현재 캡처 세트:

- `homeDashboard`
- `sleepReport`
- `eventTimeline`
- `dailyRhythmReport`
- `dailyHealthCard`
- `healthMetricsOverview`
- `privacySettings`
- `zeroEventReport`

특정 scenario만 재캡처:

```bash
APP_STORE_SCREENSHOT_SCENARIOS=homeDashboard,sleepReport Tools/Screenshots/capture_app_store_screenshots.sh
```

App Store Connect에 올릴 size별 파일은 raw source에서 별도 export합니다. review-cropped 파일은 README/UI Gallery 검토용 crop과 같은 성격이며, App Store Connect 업로드 원본으로 쓰지 않습니다.

### App Store Connect size export

Apple App Store Connect의 screenshot 규격은 Apple Developer의 `Screenshot specifications` 문서를 기준으로 확인합니다: https://developer.apple.com/help/app-store-connect/reference/screenshot-specifications/

```bash
Tools/Screenshots/export_app_store_connect_screenshots.sh
```

기본 출력 위치:

```text
Docs/Screenshots/AppStore/export/
Docs/Screenshots/AppStore/export/manifest.tsv
```

기본 export는 `Docs/Screenshots/AppStore/raw/`에 있는 PNG를 App Store Connect에서 허용하는 iPhone portrait size 후보별로 재생성합니다. 이 출력 폴더는 raw capture에서 재생성 가능한 산출물이므로 gitignore 대상입니다.

지원 size label:

- `iphone_6_9_1260x2736`
- `iphone_6_9_1290x2796`
- `iphone_6_9_1320x2868`
- `iphone_6_5_1284x2778`
- `iphone_6_5_1242x2688`
- `iphone_6_3_1206x2622`
- `iphone_6_3_1179x2556`
- `iphone_6_1_1170x2532`
- `iphone_6_1_1125x2436`
- `iphone_6_1_1080x2340`
- `iphone_5_5_1242x2208`

특정 size나 screenshot만 export할 때:

```bash
APP_STORE_EXPORT_SIZES=iphone_6_9_1290x2796,iphone_6_5_1284x2778 Tools/Screenshots/export_app_store_connect_screenshots.sh
APP_STORE_EXPORT_FILES=01_home_dashboard_light.png Tools/Screenshots/export_app_store_connect_screenshots.sh
```

기본 fit mode는 `contain`입니다. 이 모드는 화면 내용을 자르지 않고 남는 영역을 앱 배경색 계열로 pad합니다. 업로드 전에는 반드시 생성 PNG를 눈으로 확인하고, 잘림 없는 실제 기기별 simulator capture가 가능하면 해당 raw capture를 우선 사용합니다.

## 금지

- fake screenshot을 만들지 않습니다.
- 실제 개인 건강 데이터, 실제 HealthKit 데이터, 실제 오디오 파일, 실제 이벤트 오디오 샘플을 사용하지 않습니다.
- 공개/개인 오디오 파일을 repo에 커밋하지 않습니다.
- 서버 전송, 자동 공유, 외부 SDK를 사용하지 않습니다.
- 건강 상태를 단정하거나 수면 소리와 건강 지표 사이의 원인과 결과를 주장하는 copy를 쓰지 않습니다.

## README와 UI Gallery 구분

- README에는 대표 screenshot만 넣습니다.
- 화면별 상세 상태, edge state, DEBUG-only 화면은 `Docs/UI_GALLERY.md`에서 관리합니다.
- 실제 screenshot 파일이 준비되기 전에는 image markdown을 추가하지 않고 `screenshot pending` 상태로 둡니다.
