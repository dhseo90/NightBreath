# Screenshot Folder Guide

이 폴더는 NightBreath / 밤숨의 README 대표 screenshot과 UI gallery용 screenshot 후보를 정리하기 위한 구조입니다.

## 원칙

- 모든 screenshot은 mock data 또는 simulator scenario 기반으로 생성합니다.
- 실제 개인 건강 데이터, 실제 HealthKit 데이터, 실제 오디오 파일, 실제 이벤트 오디오 샘플을 사용하지 않습니다.
- README에는 대표 screenshot만 사용합니다.
- 가능한 모든 화면과 edge state 설명은 `Docs/UI_GALLERY.md`에서 관리합니다.
- 실제 screenshot 파일이 없는 경우 문서에는 `screenshot pending`으로 표시하고 broken image link를 만들지 않습니다.
- screenshot 생성 방법은 `Tools/Screenshots/README.md`에서 관리합니다.
- DEBUG 앱의 `Simulator QA / Screenshot Scenario` 화면에서 screenshot preset을 선택한 뒤 캡처합니다.
- 2026-05-07 리뷰 기준 기존 README/App Store 후보 이미지는 품질 재검토 전까지 사용자-facing 문서에 렌더링하지 않습니다.
- 파일이 존재해도 내부 QA label, crop 정렬, 주요 content 가독성 gate를 통과하기 전에는 `captured, quality review pending`으로 봅니다.
- 각 screenshot 후보의 승인 상태는 `Docs/Screenshots/screenshot_status.tsv`에서 관리합니다.
- `Docs/UI_GALLERY.md`나 `Docs/UI_SCREEN_MAP.md`에 `.png` 경로를 추가하면 같은 경로를 `screenshot_status.tsv`의 `raw_source` 또는 `review_asset`에 등록합니다.

## 폴더

- `README/`: README 대표 screenshot 후보
- `Home/`: 홈과 대시보드 계열
- `Sleep/`: 수면 시작, 녹음 중, 리포트, 타임라인
- `DailyRhythm/`: 아침 리포트, 오늘의 리듬 리포트, 하루 리듬 카드
- `Health/`: 건강 대시보드, 전체 건강 지표, Fitdays import, 월 건강 캘린더, 날짜별 상세, metric detail, 혈압, 체성분, 교차 보기
- `Privacy/`: 개인정보 설정, 배치 가이드, 온보딩
- `EdgeStates/`: empty, 권한 없음, 데이터 부족, 낮은 측정 품질
- `Debug/`: DEBUG 전용 검증 화면
- `AppStore/`: App Store marketing screenshot raw source, review crop, App Store Connect export 후보

## 현재 README 대표 screenshot

다음 파일은 DEBUG simulator와 mock data 상태에서 생성한 후보입니다. 2026-05-07 visual review에서 crop 정렬과 내부 QA label 노출 가능성이 확인되어 현재 상태는 `blocked, recapture required`입니다. README에서는 렌더링하지 않으며, 재캡처와 crop 재검토 후 승인된 파일만 다시 연결합니다.

- `README/home_dashboard_light.png`
- `README/sleep_start_light.png`
- `README/sleep_report_light.png`
- `README/sleep_timeline_light.png`
- `README/morning_brief_light.png`
- `README/daily_rhythm_report_light.png`
- `README/daily_health_card_light.png`
- `README/health_dashboard_light.png`

README 본문에는 위 원본을 직접 쓰지 않고, status bar, 시간, Dynamic Island 영역과 하단 floating tab bar 겹침 영역을 제거한 crop 버전을 후보로 사용합니다. 단, 현재 crop 후보는 화면별 visual QA를 통과하지 못했으므로 README에서 숨깁니다.

- 원본 위치: `Docs/Screenshots/README/*.png`
- README용 crop 위치: `Docs/Screenshots/README/cropped/*.png`
- 현재 기준: 1206x2622 simulator capture에서 상단 180px 제거
- 현재 crop 결과: 1206x2122

Crop은 화면 title과 주요 content를 자르지 않아야 합니다. crop 결과가 title을 자르거나 UI를 오해하게 만들면 fake image를 만들지 말고 원본을 다시 캡처하거나 crop 값을 조정합니다. 고정 crop script 출력은 검토 후보일 뿐 최종 승인물이 아닙니다.

Crop script:

```bash
Tools/Screenshots/crop_readme_screenshots.sh
```

Review sheet:

```bash
Tools/Screenshots/build_screenshot_review_sheet.sh
```

Review sheet는 `Docs/Screenshots/review/screenshot_review_sheet.html`과 `Docs/Screenshots/review/screenshot_review_manifest.tsv`를 생성합니다. 이 폴더는 재생성 가능한 visual QA 산출물이므로 gitignore 대상입니다. README/App Store/user-facing 문서에 screenshot을 다시 렌더링하기 전에는 raw source와 crop을 나란히 보고 내부 label, crop 정렬, 주요 content 가독성, 실제 개인 데이터 노출 여부를 확인합니다.

## EHM 상세 screenshot 후보

다음 파일은 Extended Health Metrics/Fitdays import/metric detail 문서용 screenshot입니다. 원본은 `Health/`에 보존하고, UI Gallery에는 status bar, 시간, Dynamic Island 영역을 제거한 `Health/cropped/` 버전을 우선 사용합니다. 실제 capture 전에는 `Docs/UI_GALLERY.md`에 `screenshot pending`으로 남기고 image markdown을 만들지 않습니다.

- `Health/health_metrics_overview_light.png`
- `Health/fitdays_import_light.png`
- `Health/fitdays_import_result_light.png`
- `Health/health_calendar_light.png`
- `Health/daily_measurement_detail_light.png`
- `Health/metric_detail_body_water_light.png`
- `Health/metric_detail_basal_metabolic_rate_light.png`
- `Health/fitdays_import_error_light.png`
- `Health/blood_pressure_dashboard_light.png`
- `Health/body_composition_dashboard_light.png`
- `Health/cross_metric_dashboard_light.png`

UI Gallery crop 위치:

- `Health/cropped/health_metrics_overview_light.png`
- `Health/cropped/fitdays_import_light.png`
- `Health/cropped/fitdays_import_result_light.png`
- `Health/cropped/health_calendar_light.png`
- `Health/cropped/daily_measurement_detail_light.png`
- `Health/cropped/metric_detail_body_water_light.png`
- `Health/cropped/metric_detail_basal_metabolic_rate_light.png`
- `Health/cropped/fitdays_import_error_light.png`
- `Health/cropped/blood_pressure_dashboard_light.png`
- `Health/cropped/body_composition_dashboard_light.png`
- `Health/cropped/cross_metric_dashboard_light.png`

## UI Gallery 직접 캡처 screenshot

다음 파일은 DEBUG simulator에서 `--nightbreath-screenshot-scenario` launch argument로 바로 진입 가능한 pending 화면을 캡처한 것입니다. 원본은 각 폴더에 보존하고, UI Gallery에는 `cropped/` 버전을 우선 사용합니다.

- `Sleep/sleep_recording_light.png`
- `Privacy/privacy_settings_light.png`
- `EdgeStates/zero_event_report_light.png`
- `EdgeStates/low_coverage_report_light.png`
- `EdgeStates/event_audio_storage_off_light.png`
- `EdgeStates/health_permission_empty_light.png`
- `EdgeStates/metric_detail_empty_light.png`
- `EdgeStates/cross_metric_insufficient_light.png`
- `Debug/detector_tuning_light.png`
- `Privacy/onboarding_light.png`
- `Privacy/device_placement_guide_light.png`
- `Privacy/calibration_light.png`
- `Debug/audio_debug_light.png`
- `Debug/sample_capture_light.png`
- `Debug/dataset_replay_light.png`
- `Debug/simulator-scenario.png`
- `Home/trend-dashboard.png`
- `Sleep/morning-check-in.png`
- `DailyRhythm/evening-check-in.png`
- `DailyRhythm/daily-health-card-export-preview.png`
- `EdgeStates/report-empty.png`

UI Gallery crop 위치:

- `Sleep/cropped/sleep_recording_light.png`
- `Privacy/cropped/privacy_settings_light.png`
- `EdgeStates/cropped/zero_event_report_light.png`
- `EdgeStates/cropped/low_coverage_report_light.png`
- `EdgeStates/cropped/event_audio_storage_off_light.png`
- `EdgeStates/cropped/health_permission_empty_light.png`
- `EdgeStates/cropped/metric_detail_empty_light.png`
- `EdgeStates/cropped/cross_metric_insufficient_light.png`
- `Debug/cropped/detector_tuning_light.png`
- `Privacy/cropped/onboarding_light.png`
- `Privacy/cropped/device_placement_guide_light.png`
- `Privacy/cropped/calibration_light.png`
- `Debug/cropped/audio_debug_light.png`
- `Debug/cropped/sample_capture_light.png`
- `Debug/cropped/dataset_replay_light.png`
- `Debug/cropped/simulator-scenario.png`

Release onboarding/privacy와 DEBUG 전용 검증 화면은 다음 스크립트로 직접 캡처합니다.

```bash
Tools/Screenshots/capture_support_screenshots.sh
```

특정 scenario만 재캡처할 때:

```bash
SUPPORT_SCREENSHOT_SCENARIOS=onboarding,audioDebug Tools/Screenshots/capture_support_screenshots.sh
```

수동 navigation이 필요했던 상세/pending 화면은 다음 스크립트로 launch argument에서 바로 열어 캡처합니다.

```bash
Tools/Screenshots/capture_detail_screenshots.sh
```

특정 scenario만 재캡처할 때:

```bash
DETAIL_SCREENSHOT_SCENARIOS=trendDashboard,reportEmpty Tools/Screenshots/capture_detail_screenshots.sh
```

## App Store Marketing Screenshot

App Store screenshot은 README 대표 screenshot과 별도로 `Docs/Screenshots/AppStore/`에서 관리합니다. 실제 App Store Connect upload source는 status bar를 포함한 raw capture를 기준으로 하고, review-cropped 이미지는 내부 문서 검토용으로만 사용합니다. 현재 저장된 후보는 내부 QA label 노출과 crop 품질 문제로 재캡처 전까지 사용 금지입니다.

현재 marketing 후보 파일:

- `AppStore/raw/01_home_dashboard_light.png`
- `AppStore/raw/02_sleep_report_light.png`
- `AppStore/raw/03_sleep_timeline_light.png`
- `AppStore/raw/04_daily_rhythm_report_light.png`
- `AppStore/raw/05_daily_health_card_light.png`
- `AppStore/raw/06_health_metrics_overview_light.png`
- `AppStore/raw/07_privacy_settings_light.png`
- `AppStore/raw/08_zero_event_report_light.png`

캡처 명령:

```bash
Tools/Screenshots/capture_app_store_screenshots.sh
```

특정 scenario만 재캡처할 때:

```bash
APP_STORE_SCREENSHOT_SCENARIOS=homeDashboard,sleepReport Tools/Screenshots/capture_app_store_screenshots.sh
```

모든 App Store screenshot은 DEBUG simulator scenario와 synthetic/mock data만 사용합니다. 실제 HealthKit 데이터, 실제 Fitdays CSV, 실제 오디오 파일, 실제 이벤트 오디오 샘플은 사용하지 않습니다.

재캡처 gate:

- 홈/리포트 header에 `Simulator QA` 같은 내부 source label이 보이지 않아야 합니다.
- 예시 데이터는 사용자용 copy로 보이고, `synthetic`, local path, 실제 파일명처럼 내부 작업명이 보이지 않아야 합니다.
- 화면별 contact sheet에서 좌우 치우침, 하단 잘림, 긴 한국어 문구 겹침을 확인합니다.
- DEBUG-only 화면은 App Store/README 후보에서 제외합니다.

App Store Connect size별 export:

```bash
Tools/Screenshots/export_app_store_connect_screenshots.sh
```

Export 결과는 `Docs/Screenshots/AppStore/export/`에 생성되며, raw source에서 재생성 가능한 산출물이므로 repository에 커밋하지 않습니다. `manifest.tsv`에는 source file, target size label, width/height, fit mode가 남습니다.

## 주의

Screenshot은 앱의 제품 방향을 보여주는 문서 자료입니다. 건강 상태를 단정하거나 수면 소리와 건강 지표 사이의 원인과 결과를 주장하는 copy를 사용하지 않습니다.
