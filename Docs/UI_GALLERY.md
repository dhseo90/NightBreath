# UI Gallery

이 문서는 NightBreath / 밤숨의 화면별 역할, 표시 데이터, 액션, 개인정보/안전 원칙, screenshot scenario, screenshot 저장 후보를 정리합니다. README에는 대표 화면만 짧게 소개하고, 가능한 UI와 상태별 설명은 이 문서를 기준으로 관리합니다.

## 개요

NightBreath는 수면 중 소리 기반 지표에서 시작해 하루 건강 리듬을 참고용으로 정리하는 온디바이스 앱입니다. UI gallery는 README 대표 screenshot, 상세 gallery screenshot, App Store 후보 screenshot, 아직 pending인 화면 범위를 함께 추적하기 위한 문서입니다.

## Screenshot 원칙

- 실제 screenshot 파일이 없는 화면은 `screenshot pending`으로 표시합니다.
- 실제 파일이 생기기 전에는 README나 문서에 image markdown을 추가하지 않습니다.
- README에는 품질 gate를 통과한 대표 화면만 싣고, 전체 화면과 edge state는 이 문서에서 관리합니다.
- README 대표 screenshot은 `Docs/Screenshots/README/cropped/`의 crop 버전을 후보로 사용했지만, 현재는 재캡처가 필요하므로 README에 렌더링하지 않습니다.
- README 대표 crop은 status bar, 시간, Dynamic Island 영역만 제거하고 화면 title과 주요 content는 유지해야 합니다.
- 원본 capture는 `Docs/Screenshots/README/`에 보존하며, 상세 gallery screenshot은 화면별 필요에 따라 원본 또는 crop 버전을 구분해 관리합니다.
- App Store 후보 screenshot은 `Docs/APP_RELEASE_GUIDE.md`와 함께 검토합니다.
- Light/Dark screenshot은 같은 예시 state에서 각각 확인하고, 긴 한국어 문구가 잘리지 않는지 봅니다.
- Debug-only 화면은 Release 사용자 screenshot 후보에 포함하지 않습니다.

현재 README 대표 screenshot, EHM/Health 상세 screenshot, privacy/support screenshot, DEBUG observability screenshot, edge state screenshot, App Store raw/review-cropped 후보는 `iPhone 17 Pro` simulator, DEBUG build, 예시 데이터 상태에서 생성했지만, 2026-05-07 문서/이미지 리뷰에서 품질 문제가 확인되어 release-approved 상태가 아닙니다. 기존 파일은 재캡처 기준을 잡기 위한 후보이며, 수동 navigation이 필요했던 상세 화면도 직접 launch scenario로 캡처해 quality review pending 상태로 관리합니다.

## Screenshot Quality Gate

현재 저장된 screenshot 후보는 다음 이유로 README/App Store/사용자-facing 문서에 바로 노출하지 않습니다.

- App Store 후보 `01_home_dashboard_light.png` 계열에 내부 QA source label인 `Simulator QA`가 노출되었습니다. 이후 코드에서는 user-facing screenshot launch scenario가 public source copy를 사용하도록 보강했지만, 기존 image 파일은 재캡처 전까지 계속 blocked입니다.
- 고정 상하단 crop만으로 처리해 화면별 여백, 주요 card 위치, 하단 content 가독성이 충분히 검수되지 않았습니다.
- DEBUG-only 화면은 개발 문서에서 경로만 추적하고, Release/App Store/README 이미지로 렌더링하지 않습니다.
- 파일 존재 여부만으로 승인하지 않습니다. README/App Store 후보는 현재 `blocked, recapture required`로 보고, 상세 gallery 후보만 `captured, quality review pending`으로 추적합니다.

상태 source-of-truth:

- `Docs/Screenshots/screenshot_status.tsv`에서 각 후보의 상태를 관리합니다.
- 허용 상태값은 `screenshot pending`, `captured, quality review pending`, `internal-only, quality review pending`, `blocked, recapture required`, `release-approved`입니다.
- `Docs/UI_GALLERY.md`와 `Docs/UI_SCREEN_MAP.md`에 적는 모든 screenshot `.png` 경로는 `screenshot_status.tsv`의 `raw_source` 또는 `review_asset`에 함께 등록합니다.
- screenshot 경로나 상태를 바꾼 뒤에는 `Tools/Screenshots/validate_screenshot_manifest.sh`를 실행해 manifest schema, 파일 존재 여부, 문서 참조 누락을 먼저 확인합니다.
- `release-approved`로 바꾸려면 contact sheet 확인, App Store export 확인, user-facing 문서 렌더링 확인을 모두 통과해야 합니다.

재노출 gate:

- screenshot scenario에서 내부 QA 문구, 실제 개인 데이터, 실제 파일명, local path가 보이지 않아야 합니다.
- 화면별 crop은 title, 주요 card, CTA, tab/navigation 상태를 자르거나 한쪽으로 치우치게 만들지 않아야 합니다.
- README와 App Store 후보는 `Tools/Screenshots/build_screenshot_review_sheet.sh`로 만든 contact sheet에서 raw source와 crop을 같이 검토하고 승인된 파일만 image markdown/HTML `img`로 연결합니다.
- App Store 후보는 raw source와 export 산출물 모두 눈으로 확인한 뒤에만 `release-approved`로 전환합니다.

## Capture Status Summary

| 범위 | 상태 | 비고 |
| --- | --- | --- |
| README 대표 8개 | blocked, recapture required | crop 정렬과 내부 QA label 노출 여부를 재확인하기 전까지 README 렌더링 금지 |
| Health/EHM 상세 | mixed, see manifest | 대부분 quality review pending, Fitdays import result는 internal fixture filename 노출로 recapture required |
| Privacy/Support | captured, quality review pending | privacy settings, onboarding, device placement, calibration |
| Sleep/Edge direct scenario | mixed, see manifest | sleep recording은 비현실적 duration/state mismatch로 recapture required, edge states는 quality review pending |
| DEBUG observability | internal-only, quality review pending | dataset replay, detector tuning, audio debug, sample capture |
| App Store 후보 8개 | blocked, recapture required | raw/review-cropped에 내부 QA label 노출 가능성이 있어 재캡처 전 사용 금지 |
| 직접 scenario 상세 캡처 | captured/internal-only, quality review pending | trend, morning/evening check-in, Daily Health Card export/share state, report empty, simulator scenario |

## App Store Screenshot Candidate Flow

App Store 후보 screenshot은 README 대표 screenshot과 분리해 관리합니다. `Tools/Screenshots/capture_app_store_screenshots.sh`가 raw source를 `Docs/Screenshots/AppStore/raw/`에 저장하고, 내부 검토용 crop을 `Docs/Screenshots/AppStore/review-cropped/`에 생성합니다. App Store Connect size별 export는 raw source에서 재생성하며 `Docs/Screenshots/AppStore/export/` 산출물은 커밋하지 않습니다.

현재 후보 흐름은 재캡처가 필요합니다. 아래 파일은 존재하더라도 release-approved가 아니며, App Store Connect export 입력으로 쓰지 않습니다.

| 순서 | 후보 | raw source | review crop | 상태 |
| --- | --- | --- | --- | --- |
| 1 | Home dashboard | `Docs/Screenshots/AppStore/raw/01_home_dashboard_light.png` | `Docs/Screenshots/AppStore/review-cropped/01_home_dashboard_light.png` | blocked, recapture required |
| 2 | Sleep report | `Docs/Screenshots/AppStore/raw/02_sleep_report_light.png` | `Docs/Screenshots/AppStore/review-cropped/02_sleep_report_light.png` | blocked, recapture required |
| 3 | Event timeline | `Docs/Screenshots/AppStore/raw/03_sleep_timeline_light.png` | `Docs/Screenshots/AppStore/review-cropped/03_sleep_timeline_light.png` | blocked, recapture required |
| 4 | Daily rhythm report | `Docs/Screenshots/AppStore/raw/04_daily_rhythm_report_light.png` | `Docs/Screenshots/AppStore/review-cropped/04_daily_rhythm_report_light.png` | blocked, recapture required |
| 5 | Daily health card | `Docs/Screenshots/AppStore/raw/05_daily_health_card_light.png` | `Docs/Screenshots/AppStore/review-cropped/05_daily_health_card_light.png` | blocked, recapture required |
| 6 | Health metrics overview | `Docs/Screenshots/AppStore/raw/06_health_metrics_overview_light.png` | `Docs/Screenshots/AppStore/review-cropped/06_health_metrics_overview_light.png` | blocked, recapture required |
| 7 | Privacy settings | `Docs/Screenshots/AppStore/raw/07_privacy_settings_light.png` | `Docs/Screenshots/AppStore/review-cropped/07_privacy_settings_light.png` | blocked, recapture required |
| 8 | Zero-event report | `Docs/Screenshots/AppStore/raw/08_zero_event_report_light.png` | `Docs/Screenshots/AppStore/review-cropped/08_zero_event_report_light.png` | blocked, recapture required |

모든 후보는 mock/synthetic data 기반이어야 하며, 실제 개인 건강 데이터, 실제 HealthKit 데이터, 실제 Fitdays CSV 파일명, 실제 오디오 파일명, 실제 이벤트 오디오 샘플을 사용하지 않습니다.

## Direct Scenario Capture Queue

아래 항목은 simulator 직접 launch scenario로 캡처했고, visual QA 전까지 image markdown을 추가하지 않습니다. DEBUG-only 화면은 internal-only로 유지합니다.

| 항목 | 상태 | Review crop |
| --- | --- | --- |
| `TrendDashboardView` | captured, quality review pending | `Docs/Screenshots/Home/cropped/trend-dashboard.png` |
| `MorningCheckInView` | captured, quality review pending | `Docs/Screenshots/Sleep/cropped/morning-check-in.png` |
| `EveningCheckInView` | captured, quality review pending | `Docs/Screenshots/DailyRhythm/cropped/evening-check-in.png` |
| `DailyHealthCardPreviewView` export/share state | captured, quality review pending | `Docs/Screenshots/DailyRhythm/cropped/daily-health-card-export-preview.png` |
| Report empty state | captured, quality review pending | `Docs/Screenshots/EdgeStates/cropped/report-empty.png` |
| `SimulatorScenarioView` | internal-only, quality review pending | `Docs/Screenshots/Debug/cropped/simulator-scenario.png` |

## 예시 데이터 사용 원칙

- 모든 screenshot은 예시 데이터 또는 simulator scenario 기반이어야 합니다.
- 실제 개인 건강 데이터, 실제 HealthKit 데이터, 실제 오디오 파일, 실제 이벤트 오디오 샘플을 사용하지 않습니다.
- Daily Rhythm, Health Dashboard, Cross Metric 화면은 예시/protocol 또는 사용자가 명시적으로 연결한 read-only 흐름을 전제로 문서화합니다.
- screenshot용 샘플 값은 개인 참고용 맥락으로만 표시하고 건강 상태를 단정하지 않습니다.

## 실제 개인 데이터 금지

- 개인 이름, 실제 생년월일, 실제 건강 샘플, 실제 source device serial, 실제 개인 오디오 파일명, 실제 녹음 파일명을 노출하지 않습니다.
- 서버 전송, 자동 공유, 외부 SDK 사용을 암시하지 않습니다.
- 수면 소리 지표와 건강 지표를 함께 보여도 인과관계를 의미하지 않는다는 안내를 유지합니다.
- 모든 건강 관련 화면에는 필요 시 “이 앱은 진단 목적의 의료기기가 아닙니다.” 또는 동등한 안전 문구를 포함합니다.

## EHM Screenshot Status

EHM screenshot은 `ScreenshotScenario`의 DEBUG launch argument로 직접 진입해 캡처합니다. 원본은 `Docs/Screenshots/Health/`에 보존하고, UI Gallery에는 `Docs/Screenshots/Health/cropped/` 경로를 사용합니다.

| 범위 | 상태 | 파일 |
| --- | --- | --- |
| 전체 건강 지표 | captured, quality review pending | `Docs/Screenshots/Health/cropped/health_metrics_overview_light.png` |
| Fitdays import empty | captured, quality review pending | `Docs/Screenshots/Health/cropped/fitdays_import_light.png` |
| Fitdays import result | blocked, recapture required | `Docs/Screenshots/Health/cropped/fitdays_import_result_light.png` |
| Fitdays import error | captured, quality review pending | `Docs/Screenshots/Health/cropped/fitdays_import_error_light.png` |
| 월 건강 캘린더 | captured, quality review pending | `Docs/Screenshots/Health/cropped/health_calendar_light.png` |
| 날짜별 전체 데이터 상세 | captured, quality review pending | `Docs/Screenshots/Health/cropped/daily_measurement_detail_light.png` |
| Metric detail 체수분 | captured, quality review pending | `Docs/Screenshots/Health/cropped/metric_detail_body_water_light.png` |
| Metric detail 로컬 전용 기초대사량 | captured, quality review pending | `Docs/Screenshots/Health/cropped/metric_detail_basal_metabolic_rate_light.png` |
| 혈압 dashboard | captured, quality review pending | `Docs/Screenshots/Health/cropped/blood_pressure_dashboard_light.png` |
| 체성분 dashboard | captured, quality review pending | `Docs/Screenshots/Health/cropped/body_composition_dashboard_light.png` |
| Cross metric dashboard | captured, quality review pending | `Docs/Screenshots/Health/cropped/cross_metric_dashboard_light.png` |
| Health permission empty state | captured, quality review pending | `Docs/Screenshots/EdgeStates/cropped/health_permission_empty_light.png` |
| Metric detail empty state | captured, quality review pending | `Docs/Screenshots/EdgeStates/cropped/metric_detail_empty_light.png` |
| Cross metric insufficient state | captured, quality review pending | `Docs/Screenshots/EdgeStates/cropped/cross_metric_insufficient_light.png` |

## Home / Dashboard

| View name | 역할 | 주요 표시 데이터 | 주요 액션 | Privacy / Safety notes | Suggested scenario | Suggested screenshot path | Screenshot | Release 노출 | 관련 문서 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `HomeDashboardView` | 종합 평가와 최근 상태 허브 | 최근 수면 리포트, 수면 소리 점수, 측정 품질, 주요 이벤트, Daily Rhythm 진입점 | 수면 시작, 최근 리포트, 수면 트렌드, 건강 tab 상세 진입 | 온디바이스 분석, 서버 전송 없음, 원본 전체 오디오 미저장 안내 | `ScreenshotHomeScenario` | `Docs/Screenshots/README/cropped/home_dashboard_light.png` | blocked, recapture required | Release | `Docs/UI_SCREEN_MAP.md`, `Docs/DESIGN_SYSTEM.md` |
| `TrendDashboardView` | 7일/30일/90일 수면 소리 흐름 | 수면 소리 점수, 코골기 시간, 측정 품질 추세 | 기간 선택 | 낮은 측정 품질은 배지와 문장으로 구분 | `ScreenshotTrendDashboardScenario` | `Docs/Screenshots/Home/cropped/trend-dashboard.png` | quality review pending | Release | `Docs/UI_SCREEN_MAP.md` |

## Sleep Flow

| View name | 역할 | 주요 표시 데이터 | 주요 액션 | Privacy / Safety notes | Suggested scenario | Suggested screenshot path | Screenshot | Release 노출 | 관련 문서 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `SleepStartView` | 수면 기능 동작과 결과 확인 | 측정 안내, 기기 배치, 마이크 권한, 최근 수면 결과, 이벤트 오디오 샘플 opt-in 상태 | 수면 시작, 최근 리포트, 타임라인, 수면 트렌드, 배치 가이드 | 원본 전체 오디오는 저장하지 않으며 이벤트 샘플은 opt-in일 때만 저장 | `ScreenshotSleepStartScenario` | `Docs/Screenshots/README/cropped/sleep_start_light.png` | blocked, recapture required | Release | `Docs/QA_GUIDE.md` |
| `SleepRecordingView` | 수면 기록 중 상태 | 경과 시간, 실제 오디오 수신/분석 시간, 커버리지, detector backend | 수면 종료 | 수신 시간과 앱 실행 시간을 분리해 표시 | `ScreenshotRecordingScenario` | `Docs/Screenshots/Sleep/cropped/sleep_recording_light.png` | blocked, recapture required | Release | `Docs/QA_GUIDE.md` |
| `SleepReportView` | 아침 수면 소리 리포트 | 수면 소리 점수, 측정 품질, 이벤트 요약, diagnostics, zero-event 안내 | 타임라인 보기, 아침 체크인, 개인정보 설정 | 수면 중 소리 기반 지표이며 진단 목적이 아님 | `ScreenshotSleepReportScenario` | `Docs/Screenshots/README/cropped/sleep_report_light.png` | blocked, recapture required | Release | `Docs/UI_SCREEN_MAP.md` |
| `SleepTimelineView` | 수면 이벤트 상세 목록 | 이벤트 타입, 시간, duration, confidence, 색상 legend, 샘플 보유 여부 | 샘플 재생/삭제, feedback 저장 | 샘플은 짧은 이벤트 구간만 opt-in 저장 | `ScreenshotTimelineScenario` | `Docs/Screenshots/README/cropped/sleep_timeline_light.png` | blocked, recapture required | Release | `Docs/PRIVACY_STORAGE_AUDIT.md` |
| `MorningCheckInView` | 아침 주관적 컨디션 기록 | 개운함, 피로감, 각성 기억, 메모 | 체크인 저장 | 사용자가 직접 입력한 주관 기록으로 표시 | `ScreenshotMorningCheckInScenario` | `Docs/Screenshots/Sleep/cropped/morning-check-in.png` | quality review pending | Release | `Docs/UI_SCREEN_MAP.md` |

## Daily Rhythm

| View name | 역할 | 주요 표시 데이터 | 주요 액션 | Privacy / Safety notes | Suggested scenario | Suggested screenshot path | Screenshot | Release 노출 | 관련 문서 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `MorningBriefView` | 오늘 아침 리포트 | 지난밤 요약, 수면 소리 점수, 아침 컨디션, 예시 아침 건강 데이터, 데이터 준비 상태와 제한 항목 | 수면 리포트와 Daily Rhythm 흐름 확인 | 개인 참고용 리포트이며 건강 상태를 단정하지 않음 | `ScreenshotMorningBriefScenario` | `Docs/Screenshots/README/cropped/morning_brief_light.png` | blocked, recapture required | Release | `Docs/PRODUCT_DIRECTION.md` |
| `DailyRhythmReportView` | 오늘의 리듬 리포트 | 오늘의 리듬 점수, component score, data quality, 데이터 준비 상태, Daily Insight | 하루 리듬 요약 확인 | 웰니스/개인 참고용 점수이며 인과관계를 의미하지 않음 | `ScreenshotDailyRhythmScenario` | `Docs/Screenshots/README/cropped/daily_rhythm_report_light.png` | blocked, recapture required | Release | `Docs/DAILY_RHYTHM_SCORE.md` |
| `EveningCheckInView` | 저녁 컨디션 기록 | 피로도, 스트레스, 기분, 생활 태그, 메모 | 예시/in-memory 체크인 저장 | 생활 태그는 개인 패턴 참고용 | `ScreenshotEveningCheckInScenario` | `Docs/Screenshots/DailyRhythm/cropped/evening-check-in.png` | quality review pending | Release | `Docs/UI_SCREEN_MAP.md` |
| `DailyHealthCardView` | 하루 리듬 카드 | 날짜, 오늘의 리듬 점수, 핵심 지표, 한 줄 요약 | 카드 UI 확인 | privacy level에 따라 민감 수치 표시를 줄임 | `ScreenshotDailyHealthCardScenario` | `Docs/Screenshots/README/cropped/daily_health_card_light.png` | blocked, recapture required | Release | `Docs/DAILY_HEALTH_CARD.md` |
| `DailyHealthCardPreviewView` | 카드 template/privacy 미리보기 | template 선택, privacy level, 예시 카드 미리보기 | template/privacy 전환 | 실제 export/share는 사용자 명시 액션 전까지 없음 | `ScreenshotDailyHealthCardScenario` | `Docs/Screenshots/README/cropped/daily_health_card_light.png` | blocked, recapture required | Release | `Docs/DAILY_HEALTH_CARD.md` |
| `DailyHealthCardPreviewView` export/share state | export/share 확인 흐름 | export preview, privacy level, 포함 항목, `DailyHealthCardExportConfirmationSheet`, 공유 완료/취소/실패 state | 이미지 만들기, 시스템 공유, 취소, 다시 시도 | 자동 공유 없음, 서버 업로드 없음, 외부 SDK 없음, local path와 파일명 미표시 | `ScreenshotDailyHealthCardExportScenario` | `Docs/Screenshots/DailyRhythm/cropped/daily-health-card-export-preview.png` | quality review pending | Release | `Docs/DAILY_HEALTH_CARD.md`, `Docs/PRIVACY_STORAGE_AUDIT.md` |

## Health Dashboard

| View name | 역할 | 주요 표시 데이터 | 주요 액션 | Privacy / Safety notes | Suggested scenario | Suggested screenshot path | Screenshot | Release 노출 | 관련 문서 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `HealthDashboardView` | Apple 건강앱 + 밤숨 수면 결과 + Fitdays 데이터 허브 | read-only 연결 상태, 앱 계산 수면 지표, 로컬 import 상태, 최근 건강 지표, source, 하위 dashboard 진입점 | 건강 데이터 연결, 최근 날짜 상세, 혈압/체성분/교차 보기/Fitdays import 진입 | HealthKit read-only, 서버 전송 없음, 권한 거부 시 수면 기능 유지 | `ScreenshotHealthDashboardScenario` | `Docs/Screenshots/README/cropped/health_dashboard_light.png` | blocked, recapture required | Release | `Docs/HEALTH_DATA_GUIDE.md` |
| `HealthMetricsOverviewView` | 전체 건강 지표 통계/그래프 허브 | HealthKit 기반 지표, Fitdays 로컬 전용 지표, 기간별 최근값/평균/변화, 출처 badge | 기간 선택, metric detail 진입 | 출처 type을 구분하고 수치 해석을 단정하지 않음 | `ScreenshotHealthMetricsOverviewScenario` | `Docs/Screenshots/Health/cropped/health_metrics_overview_light.png` | quality review pending | Release | `Docs/HEALTH_DATA_GUIDE.md` |
| `MetricDetailView` | metric 하나의 상세 탐색 | metric 설명, 최근 값, 단위, HealthKit 기반/로컬 전용 badge, 기간/source filter, 그래프, 통계, raw 샘플 목록 | 기간 선택, source filter, 샘플 확인 | HealthKit 기반/로컬 전용 설명을 구분하고 개인 참고용으로 표시 | `ScreenshotMetricDetailScenario` | `Docs/Screenshots/Health/cropped/metric_detail_body_water_light.png` | quality review pending | Release | `Docs/HEALTH_DATA_GUIDE.md` |
| `MetricDetailView` 로컬 전용 예시 | Fitdays 확장 로컬 전용 metric 상세 예시 | 기초대사량 설명, 로컬 전용/Fitdays CSV badge, source filter, 기간별 그래프, 원본 샘플 목록 | 기간 선택, source filter, 샘플 확인 | HealthKit 표준 지표가 아닌 로컬 전용 샘플임을 명확히 표시 | `ScreenshotLocalOnlyMetricScenario` | `Docs/Screenshots/Health/cropped/metric_detail_basal_metabolic_rate_light.png` | quality review pending | Release | `Docs/HEALTH_DATA_GUIDE.md` |
| `HealthCalendarView` | 월 단위 건강 캘린더 | 날짜별 수면/혈압/체성분/활동/check-in 카테고리 dot, 출처 dot, 샘플 수, data quality, 선택 날짜 panel | 이전/다음 월, 오늘 이동, 날짜 선택, 날짜 상세 진입 | 같은 날짜 데이터가 인과관계를 의미하지 않음을 안내 | `ScreenshotHealthCalendarScenario` | `Docs/Screenshots/Health/cropped/health_calendar_light.png` | quality review pending | Release | `Docs/HEALTH_DATA_GUIDE.md` |
| `DailyMeasurementDetailView` | 날짜별 전체 데이터 상세 | 수면, 아침/저녁 체크인, 혈압, 체성분, Fitdays 확장, 활동, 앱 계산 지표, 출처 badge | metric detail 진입 | 날짜별 묶음은 개인 참고용이며 출처를 함께 표시 | `ScreenshotDailyMeasurementDetailScenario` | `Docs/Screenshots/Health/cropped/daily_measurement_detail_light.png` | quality review pending | Release | `Docs/HEALTH_DATA_GUIDE.md` |
| `FitdaysImportView` | Fitdays CSV/structured export file 가져오기 | 파일 선택 상태, preview, imported/skipped/error row count, unknown column | 파일 선택, preview 확인, 로컬 저장 | 사용자가 직접 선택한 로컬 파일만 읽고 원격 연결 없음 | `ScreenshotFitdaysImportScenario` | `Docs/Screenshots/Health/cropped/fitdays_import_light.png` | quality review pending | Release | `Docs/HEALTH_DATA_GUIDE.md` |
| `BloodPressureDashboardView` | 혈압 데이터 보기 | 최근 수축기/이완기 혈압, 측정 시각, sourceName, 7일/30일/90일 추세 | 기간 선택 | 수치를 상태 판정으로 표현하지 않음 | `ScreenshotBloodPressureDashboardScenario` | `Docs/Screenshots/Health/cropped/blood_pressure_dashboard_light.png` | quality review pending | Release | `Docs/HEALTH_DATA_GUIDE.md` |
| `BodyCompositionDashboardView` | 체중/체성분 데이터 보기 | 체중, 체지방률, BMI, 제지방량, sourceName, 추세 | 기간 선택 | 개인 참고용 데이터로만 표시 | `ScreenshotBodyCompositionDashboardScenario` | `Docs/Screenshots/Health/cropped/body_composition_dashboard_light.png` | quality review pending | Release | `Docs/HEALTH_DATA_GUIDE.md` |
| `CrossMetricDashboardView` | 수면 소리 지표와 건강 지표 참고용 비교 | 수면 지표, 건강 지표, 매칭 상태, 날짜별 매칭, 샘플 수, sourceName | 비교 항목/기간 선택 | 데이터가 부족하면 no-match/low-coverage/shortfall을 분리하고 인과관계를 의미하지 않는다고 안내 | `ScreenshotCrossMetricDashboardScenario` | `Docs/Screenshots/Health/cropped/cross_metric_dashboard_light.png` | quality review pending | Release | `Docs/HEALTH_DATA_GUIDE.md` |

## Privacy / Settings

| View name | 역할 | 주요 표시 데이터 | 주요 액션 | Privacy / Safety notes | Suggested scenario | Suggested screenshot path | Screenshot | Release 노출 | 관련 문서 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `PrivacySettingsView` | 로컬 저장과 개인정보 설정 | 이벤트 오디오 샘플 opt-in, 저장량, orphan 샘플, HealthKit read-only 설명 | 샘플 토글, 삭제, orphan 정리 | 서버 전송 없음, HealthKit 쓰기 없음, 전체 밤 원본 오디오 미저장 | `ScreenshotPrivacyScenario` | `Docs/Screenshots/Privacy/cropped/privacy_settings_light.png` | quality review pending | Release | `Docs/PRIVACY_STORAGE_AUDIT.md` |
| `DevicePlacementGuideView` | iPhone 배치와 캘리브레이션 안내 | 배치 원칙, 충전, 마이크 가림 방지, 30초 캘리브레이션 | 캘리브레이션 실행 | 측정 품질을 높이기 위한 안내이며 결과를 단정하지 않음 | `ScreenshotDevicePlacementScenario` | `Docs/Screenshots/Privacy/cropped/device_placement_guide_light.png` | quality review pending | Release | `Docs/QA_GUIDE.md` |
| `OnboardingView` | 첫 사용 안내 | 온디바이스 분석, 개인정보 원칙, 이벤트 샘플 opt-in | 시작하기 | 초기 안내에서 서버 전송 없음과 원본 전체 오디오 미저장을 명확히 표시 | `ScreenshotOnboardingScenario` | `Docs/Screenshots/Privacy/cropped/onboarding_light.png` | quality review pending | Release | `Docs/ONBOARDING_ILLUSTRATION_GUIDE.md` |
| `CalibrationView` | 30초 입력 확인 | 입력 level, ambient baseline, calibration result | 캘리브레이션 시작/완료 | 마이크 입력 품질 확인용이며 건강 상태 해석이 아님 | `ScreenshotCalibrationScenario` | `Docs/Screenshots/Privacy/cropped/calibration_light.png` | quality review pending | Release | `Docs/UI_SCREEN_MAP.md` |

## Empty / Edge States

| View name | 역할 | 주요 표시 데이터 | 주요 액션 | Privacy / Safety notes | Suggested scenario | Suggested screenshot path | Screenshot | Release 노출 | 관련 문서 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Report empty state | 수면 리포트 없음 | 수면 기록 후 리포트 생성 안내 | 수면 시작 | 예시 state로만 문서화 | `ScreenshotReportEmptyScenario` | `Docs/Screenshots/EdgeStates/cropped/report-empty.png` | quality review pending | Release | `Docs/UI_SCREEN_MAP.md` |
| Timeline empty state | detector 기준 통과 이벤트 없음 | 이벤트가 없는 이유와 zero-event 안내 | 리포트로 돌아가기 | 이벤트 없음은 특정 건강 상태 해석이 아님 | `ScreenshotZeroEventScenario` | `Docs/Screenshots/EdgeStates/cropped/zero_event_report_light.png` | quality review pending | Release | `Docs/QA_GUIDE.md` |
| Low audio coverage state | 낮은 측정 품질 | 오디오 커버리지, 제한 안내 | 재측정 안내 확인 | 색상만으로 표시하지 않고 배지/문장 병행 | `ScreenshotLowCoverageScenario` | `Docs/Screenshots/EdgeStates/cropped/low_coverage_report_light.png` | quality review pending | Release | `Docs/QA_GUIDE.md` |
| Health permission empty state | 건강 데이터 권한 없음 | read-only 연결 필요 안내 | 건강 데이터 연결 | 권한 거부 시 수면 기능은 계속 사용 가능 | `ScreenshotHealthPermissionEmptyScenario` | `Docs/Screenshots/EdgeStates/cropped/health_permission_empty_light.png` | quality review pending | Release | `Docs/HEALTH_DATA_GUIDE.md` |
| Fitdays import empty state | 가져오기 전 상태 | 파일 선택 안내, 로컬 import 원칙 | 파일 선택 | 실제 개인 CSV를 screenshot에 사용하지 않음 | `ScreenshotFitdaysImportScenario` | `Docs/Screenshots/Health/cropped/fitdays_import_light.png` | quality review pending | Release | `Docs/HEALTH_DATA_GUIDE.md` |
| Fitdays import result state | 가져오기 미리보기/결과 | imported 샘플 수, skipped rows, unknown columns, errors | 저장 또는 상태 확인 | synthetic fixture 또는 예시 state만 사용 | `ScreenshotFitdaysImportResultScenario` | `Docs/Screenshots/Health/cropped/fitdays_import_result_light.png` | blocked, recapture required | Release | `Docs/HEALTH_DATA_GUIDE.md` |
| Fitdays import error state | invalid CSV 처리 | 오류 row, 건너뛴 row, 알 수 없는 column | 파일 다시 선택 | 실제 개인 CSV 파일명이나 경로를 노출하지 않음 | `ScreenshotImportErrorScenario` | `Docs/Screenshots/Health/cropped/fitdays_import_error_light.png` | quality review pending | Release | `Docs/HEALTH_DATA_GUIDE.md` |
| Metric detail empty state | 특정 기간/source 샘플 없음 | empty 안내, 기간/source 변경 제안 | 기간 변경, source filter 변경 | 데이터 부족을 상태 해석으로 바꾸지 않음 | `ScreenshotMetricDetailEmptyScenario` | `Docs/Screenshots/EdgeStates/cropped/metric_detail_empty_light.png` | quality review pending | Release | `Docs/HEALTH_DATA_GUIDE.md` |
| Cross metric insufficient state | 비교 가능한 데이터 부족 | matched 샘플 수, 제한 안내 | 기간/항목 변경 | 데이터가 부족하면 패턴 요약을 생성하지 않음 | `ScreenshotCrossMetricInsufficientScenario` | `Docs/Screenshots/EdgeStates/cropped/cross_metric_insufficient_light.png` | quality review pending | Release | `Docs/HEALTH_DATA_GUIDE.md` |
| Event audio storage off state | 이벤트 샘플 저장 꺼짐 | opt-in 상태, 저장 없음 안내 | 개인정보 설정 확인 | 사용자가 켜지 않으면 샘플을 저장하지 않음 | `ScreenshotEventAudioStorageOffScenario` | `Docs/Screenshots/EdgeStates/cropped/event_audio_storage_off_light.png` | quality review pending | Release | `Docs/PRIVACY_STORAGE_AUDIT.md` |

## Debug-only Screens

| View name | 역할 | 주요 표시 데이터 | 주요 액션 | Privacy / Safety notes | Suggested scenario | Suggested screenshot path | Screenshot | Release 노출 | 관련 문서 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `DatasetReplayView` | 로컬/synthetic audio replay 검증 | replay 상태, diagnostics, 후보/이벤트 수 | replay 실행 | 개인 오디오 파일은 repo나 screenshot에 포함하지 않음 | `ScreenshotDatasetReplayScenario` | `Docs/Screenshots/Debug/cropped/dataset_replay_light.png` | quality review pending | DEBUG only | `Docs/DATASET_REPLAY.md` |
| `DetectorTuningView` | detector profile 확인 | backend, tuning profile, fallback, threshold | profile 선택 | 결과는 개발 검증용이며 사용자 판단 문구로 쓰지 않음 | `ScreenshotDebugScenario` | `Docs/Screenshots/Debug/cropped/detector_tuning_light.png` | quality review pending | DEBUG only | `Docs/DETECTOR_TUNING.md` |
| `SimulatorScenarioView` | 예시 scenario 적용 | scenario 목록, screenshot preset, 적용 상태, 화면 진입 링크 | scenario 적용/해제 | screenshot과 UI QA는 예시 데이터 기반 | `ScreenshotSimulatorScenario` | `Docs/Screenshots/Debug/cropped/simulator-scenario.png` | internal-only, quality review pending | DEBUG only | `Docs/QA_GUIDE.md` |
| `AudioDebugView` | 오디오 입력/debug output 확인 | RMS, energy, detector output | 입력 상태 확인 | 원본 전체 오디오 저장을 암시하지 않음 | `ScreenshotAudioDebugScenario` | `Docs/Screenshots/Debug/cropped/audio_debug_light.png` | quality review pending | DEBUG only | `Docs/UI_SCREEN_MAP.md` |
| `SampleCaptureView` | 짧은 개발용 샘플 캡처 | 샘플 수, 저장 경로, capture 상태 | 짧은 샘플 캡처 | 실제 screenshot에는 개인 오디오 파일명이나 샘플 내용을 노출하지 않음 | `ScreenshotSampleCaptureScenario` | `Docs/Screenshots/Debug/cropped/sample_capture_light.png` | quality review pending | DEBUG only | `Docs/QA_GUIDE.md` |
