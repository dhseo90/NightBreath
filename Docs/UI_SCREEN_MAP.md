# NightBreath / 밤숨 UI Screen Map

이 문서는 밤숨 앱의 주요 화면 역할, 표시 데이터, 주요 액션, navigation 관계를 한눈에 보기 위한 요약입니다. 디자인 토큰과 공통 컴포넌트 설명은 `Docs/DESIGN_SYSTEM.md`를 기준으로 합니다.

## Tab Role Contract

| Tab | 역할 | 포함하는 것 | 포함하지 않는 것 |
| --- | --- | --- | --- |
| 홈 | 종합 평가와 최종 상태 | 최근 수면 리포트 기반 점수, 측정 품질, 주요 이벤트 요약, 하루 리듬 카드/아침 리포트 진입 | 날짜별 건강 데이터 탐색, Fitdays import 관리, DEBUG 도구 |
| 수면 | 수면 기능 동작과 결과 확인 | 수면 시작/종료, 마이크/배치 준비, 최근 수면 리포트, 타임라인, 수면 트렌드 | HealthKit 연결, Fitdays import, 앱 전체 설정 |
| 건강 | Apple 건강앱 + 밤숨 수면 결과 + Fitdays 등 로컬 건강 데이터 허브 | read-only HealthKit 연결, 앱 계산 수면 지표, Fitdays 로컬 import, 전체/개별 지표, 건강 캘린더, 날짜별 상세 | 수면 녹음 시작/종료, 개인정보/디버그 설정 |
| 설정 | 앱 설정 | 온보딩, 개인정보/저장소, 감지 민감도, iPhone 배치, 캘리브레이션, DEBUG 도구 | 건강 데이터 탐색 허브, 홈 종합 평가 |

## 화면 목록

| 화면 | 역할 | 주요 표시 데이터 | 주요 액션 |
| --- | --- | --- | --- |
| `HomeDashboardView` | 종합 평가와 최근 상태 허브 | 앱 이름, 최근 수면 리포트, 수면 소리 점수, 측정 품질, 실제 오디오 수신 시간, 녹음 커버리지, 주요 이벤트 요약, 이벤트 오디오 샘플 저장 상태, Daily Rhythm 카드 진입 | 수면 시작, 최근 리포트, 트렌드, 아침 리포트/오늘의 리듬/하루 리듬 카드, 건강 tab 상세 진입 |
| `SleepStartView` | 수면 기능 동작과 결과 확인 화면 | 측정 안내, 기기 배치 요약, 마이크 권한, 최근 수면 결과, 이벤트 오디오 샘플 저장 ON/OFF, 원본 전체 오디오 저장 안 함, 온디바이스 분석 안내 | 수면 시작, 최근 리포트/타임라인/수면 트렌드, 배치 가이드/개인정보 설정 진입 |
| `SleepRecordingView` | 수면 기록 중 상태 화면 | 세션 경과 시간, 실제 오디오 수신 시간, 실제 분석 시간, 녹음 커버리지, 마지막 입력/분석 시각, 입력 공백, detector backend, tuning profile, 이벤트 오디오 샘플 저장 상태 | 수면 종료, 리포트 보기 |
| `SleepReportView` | 아침 수면 소리 리포트 | 수면 소리 점수, 측정 품질, 측정 시간, 오디오 커버리지, 주요 이벤트 카드, 저장된 이벤트 오디오 시간/용량, detector diagnostics 요약, zero-event analysis, 주요 원인 설명 | 타임라인 보기, 아침 체크인 진입, 개인정보 설정 진입 |
| `SleepTimelineView` | 수면 이벤트 상세 목록 | 이벤트 시간, 이벤트 타입, duration, confidence, 설명, 오디오 샘플 보유 여부, feedback 상태 | 오디오 샘플 재생/삭제, 이벤트 feedback 저장 |
| `MorningCheckInView` | 아침 주관적 컨디션 기록 | 개운함, 피로감, 두통 여부, 입마름 여부, 목아픔 여부, 기억나는 중간 각성 횟수, 메모 | 체크인 저장 |
| `MorningBriefView` | 오늘 아침 리포트 | 지난밤 수면 요약, 수면 소리 점수, 측정 품질, 아침 컨디션, 예시 아침 혈압/체중/체성분, 데이터 준비 상태, 제한 항목, 개인 참고용 안내 | 수면 리포트와 Daily Rhythm 흐름 확인 |
| `DailyRhythmReportView` | 오늘의 리듬 리포트 | 오늘의 리듬 점수, data quality, 데이터 준비 상태, 수면/회복/활동/혈압/체성분 component, Daily Insight 목록, 인과관계 아님 안내 | 하루 리듬 요약 확인 |
| `EveningCheckInView` | 저녁 컨디션 기록 | 하루 피로도, 스트레스, optional 기분, 카페인/음주/야식/운동/낮잠, 메모 | 기기 안 로컬 체크인 저장, 같은 날짜 기록 불러오기 |
| `DailyHealthCardView` | 하루 리듬 카드 표시 | 날짜, 오늘의 리듬 점수, 수면 소리 점수, 측정 품질, 핵심 지표, 한 줄 요약, 개인 참고용 문구 | 카드 UI 확인 |
| `DailyHealthCardPreviewView` | 카드 template/privacy 미리보기 | template 선택, privacy level 선택, 예시 리포트 기반 카드 미리보기 | template/privacy level 전환 |
| `PrivacySettingsView` | 로컬 저장과 개인정보 설정 | 이벤트 오디오 샘플 opt-in, 저장된 샘플 수, 총 시간, 용량, orphan 샘플 수, feedback 데이터 상태, 전체 밤 원본 오디오 저장 안 함, 서버 전송 없음 | 이벤트 샘플 저장 토글, orphan 샘플 정리, 전체 이벤트 샘플 삭제, feedback 삭제 |
| `DevicePlacementGuideView` | iPhone 배치와 캘리브레이션 안내 | 침대 옆 배치, 마이크 가림 방지, 충전 연결 권장, 저전력 모드 확인, 너무 멀거나 밀폐된 위치 피하기 | 30초 캘리브레이션 실행 |
| `TrendDashboardView` | 최근 7일/30일/90일 수면 소리 지표 흐름 | 수면 소리 점수, 코골기 시간, 호흡정지 의심 구간, 이갈이 의심 소리, 환경 소음, 측정 품질 추세 | 기간 선택 |
| `HealthDashboardView` | Apple 건강앱 + 밤숨 수면 결과 + Fitdays 로컬 데이터 허브 | 예시 미리보기/read-only 연결 상태, 앱 계산 수면 지표, 로컬 import edge state, 최근 날짜 바로가기, 최근 건강 지표, 데이터 출처, 전체 지표/캘린더/Fitdays import/BloodPressure/BodyComposition/CrossMetric 진입 | 건강 데이터 연결, 최근 날짜 상세 진입, 하위 dashboard 진입 |
| `HealthMetricsOverviewView` | 전체 건강 지표 통계/그래프 허브 | HealthKit 기반 지표, Fitdays 로컬 전용 지표, 최근 값, 평균, 최소, 최대, 최근 변화, 출처별 샘플 수 | 기간 선택, 지표별 `MetricDetailView` 진입 |
| `MetricDetailView` | 특정 health metric 상세 탐색 화면 | 지표 설명, 최근 값, 측정 시각, source, 기간별 그래프, 요약 통계, 원본 샘플 목록 | 기간 선택, source filter, 로컬 수동 입력 샘플 표시 확인 |
| `HealthCalendarView` | 월 단위 건강/수면 데이터 캘린더 | 월별 날짜 cell, 수면/혈압/체성분/활동/check-in dot, 샘플 수, data quality, source type, 선택 날짜 inline 상세 | 이전/다음 월 이동, 오늘 이동, 날짜 선택 시 상세 즉시 확인 |
| `DailyMeasurementDetailView` | 특정 날짜의 전체 측정 데이터 상세 | 수면, 아침 컨디션, 저녁 체크인, 혈압, 체성분, Fitdays 확장 체성분, 활동, 앱 계산 지표, 데이터 출처 | 카테고리별 row 확인, metric detail 진입 |
| `FitdaysImportView` | 사용자가 선택한 Fitdays CSV/export 파일, 월별 데이터 복사 텍스트, Fitdays 고유 지표 수동 입력 화면 | 파일 선택 상태, 붙여넣기 입력, local-only 지표 수동 입력, import preview/result, 저장된 가져오기 기록, 생성 샘플 수, 건너뛴 행, 지원하지 않는 열, 오류 | 파일 선택, 월별 데이터 붙여넣기, 수동 값 로컬 저장, preview 확인, import result 확인, 저장된 batch 최신 날짜 보기, 저장된 기록 삭제 |
| `BloodPressureDashboardView` | 혈압 데이터 보기 | 최근 수축기/이완기 혈압, 최근 측정 시각, 데이터 출처, 기간별 추세, 데이터 없음/권한 없음 상태 | 기간 선택 |
| `BodyCompositionDashboardView` | 체중/체성분 데이터 보기 | 체중, 체지방률, BMI, 제지방량, 데이터 출처, 기간별 추세, 데이터 없음/권한 없음 상태 | 기간 선택 |
| `CrossMetricDashboardView` | 수면 소리 지표와 건강 지표 참고용 비교 | 선택한 수면 소리 지표, 선택한 건강 지표, 매칭 상태, 날짜별 매칭 목록, 낮은 측정 품질 구분, 데이터 부족 이유, 인과관계 아님 안내 | 비교 항목/기간 선택 |

## Screenshot 문서 상태

README 대표 screenshot 8개는 예시 데이터와 screenshot scenario 기반으로 생성한 crop을 루트 README의 문서 preview로 렌더링합니다. 이 상태는 `captured, quality review pending`이며, release-approved 또는 App Store 제출용 승인을 의미하지 않습니다. 전체 화면별 설명과 pending 상태는 `Docs/UI_GALLERY.md`, 폴더 원칙은 `Docs/Screenshots/README.md`, capture 절차는 `Tools/Screenshots/README.md`를 기준으로 합니다.

실제 screenshot 파일이 없는 화면은 `screenshot pending`으로 관리하고 broken image link를 만들지 않습니다. 현재 직접 launch scenario가 있는 상세/edge/DEBUG-only 화면은 캡처 후보를 생성했으며, `release-approved`가 아닌 항목은 visual QA 전까지 image markdown을 만들지 않습니다.

| 화면 그룹 | Suggested scenario | Screenshot path | 현재 상태 | README 대표 후보 | Release/Debug |
| --- | --- | --- | --- | --- | --- |
| Home / Dashboard | `ScreenshotHomeScenario` | `Docs/Screenshots/README/cropped/home_dashboard_light.png` | captured, quality review pending | 렌더링 중 | Release |
| Sleep Flow | `ScreenshotSleepStartScenario`, `ScreenshotRecordingScenario`, `ScreenshotSleepReportScenario`, `ScreenshotTimelineScenario` | `Docs/Screenshots/README/cropped/sleep_start_light.png`, `Docs/Screenshots/Sleep/cropped/sleep_recording_light.png`, `Docs/Screenshots/README/cropped/sleep_report_light.png`, `Docs/Screenshots/README/cropped/sleep_timeline_light.png` | README 대표 captured; recording detail recapture required | 일부 렌더링 중 | Release |
| Daily Rhythm | `ScreenshotMorningBriefScenario`, `ScreenshotDailyRhythmScenario`, `ScreenshotDailyHealthCardScenario`, `ScreenshotEveningCheckInScenario`, `ScreenshotDailyHealthCardExportScenario` | `Docs/Screenshots/README/cropped/morning_brief_light.png`, `Docs/Screenshots/README/cropped/daily_rhythm_report_light.png`, `Docs/Screenshots/README/cropped/daily_health_card_light.png`, `Docs/Screenshots/DailyRhythm/cropped/evening-check-in.png`, `Docs/Screenshots/DailyRhythm/cropped/daily-health-card-export-preview.png` | README 대표 captured; detail captured, quality review pending | 일부 렌더링 중 | Release |
| Health Dashboard | `ScreenshotHealthDashboardScenario`, `ScreenshotHealthMetricsOverviewScenario`, `ScreenshotHealthCalendarScenario`, `ScreenshotDailyMeasurementDetailScenario`, `ScreenshotMetricDetailScenario`, `ScreenshotFitdaysImportScenario`, `ScreenshotFitdaysImportResultScenario`, `ScreenshotImportErrorScenario`, `ScreenshotLocalOnlyMetricScenario`, `ScreenshotBloodPressureDashboardScenario`, `ScreenshotBodyCompositionDashboardScenario`, `ScreenshotCrossMetricDashboardScenario` | `Docs/Screenshots/README/cropped/health_dashboard_light.png`, `Docs/Screenshots/Health/cropped/health_metrics_overview_light.png`, `Docs/Screenshots/Health/cropped/health_calendar_light.png`, `Docs/Screenshots/Health/cropped/daily_measurement_detail_light.png`, `Docs/Screenshots/Health/cropped/metric_detail_body_water_light.png`, `Docs/Screenshots/Health/cropped/metric_detail_basal_metabolic_rate_light.png`, `Docs/Screenshots/Health/cropped/fitdays_import_light.png`, `Docs/Screenshots/Health/cropped/fitdays_import_result_light.png`, `Docs/Screenshots/Health/cropped/fitdays_import_error_light.png`, `Docs/Screenshots/Health/cropped/blood_pressure_dashboard_light.png`, `Docs/Screenshots/Health/cropped/body_composition_dashboard_light.png`, `Docs/Screenshots/Health/cropped/cross_metric_dashboard_light.png` | README 대표 captured; Health/Fitdays detail release-approved for UI Gallery only | 일부 렌더링 중 | Release |
| Privacy / Settings | `ScreenshotPrivacyScenario`, `ScreenshotOnboardingScenario`, `ScreenshotDevicePlacementScenario`, `ScreenshotCalibrationScenario` | `Docs/Screenshots/Privacy/cropped/privacy_settings_light.png`, `Docs/Screenshots/Privacy/cropped/onboarding_light.png`, `Docs/Screenshots/Privacy/cropped/device_placement_guide_light.png`, `Docs/Screenshots/Privacy/cropped/calibration_light.png` | UI Gallery 전용 release-approved | 제외 | Release |
| Empty / Edge States | `ScreenshotZeroEventScenario`, `ScreenshotLowCoverageScenario`, `ScreenshotEventAudioStorageOffScenario`, `ScreenshotHealthPermissionEmptyScenario`, `ScreenshotMetricDetailEmptyScenario`, `ScreenshotCrossMetricInsufficientScenario` | `Docs/Screenshots/EdgeStates/cropped/zero_event_report_light.png`, `Docs/Screenshots/EdgeStates/cropped/low_coverage_report_light.png`, `Docs/Screenshots/EdgeStates/cropped/event_audio_storage_off_light.png`, `Docs/Screenshots/EdgeStates/cropped/health_permission_empty_light.png`, `Docs/Screenshots/EdgeStates/cropped/metric_detail_empty_light.png`, `Docs/Screenshots/EdgeStates/cropped/cross_metric_insufficient_light.png` | UI Gallery 전용 release-approved | README에는 보통 제외 | Release |
| Debug-only Screens | `ScreenshotDebugScenario`, `ScreenshotDatasetReplayScenario`, `ScreenshotAudioDebugScenario`, `ScreenshotSampleCaptureScenario`, `ScreenshotSimulatorScenario` | `Docs/Screenshots/Debug/cropped/detector_tuning_light.png`, `Docs/Screenshots/Debug/cropped/dataset_replay_light.png`, `Docs/Screenshots/Debug/cropped/audio_debug_light.png`, `Docs/Screenshots/Debug/cropped/sample_capture_light.png`, `Docs/Screenshots/Debug/cropped/simulator-scenario.png` | internal-only, quality review pending | 제외 | DEBUG only |

Daily Rhythm 전환 이후 README에는 홈, 수면 시작, 수면 리포트, 이벤트 타임라인, 아침 리포트, 오늘의 리듬 리포트, 하루 리듬 카드, 건강 대시보드 대표 screenshot만 둡니다. DEBUG-only 화면은 개발 문서에만 사용하고 Release 사용자용 자료에는 포함하지 않습니다.

## Navigation 구조

```text
TabView
- 홈 tab: HomeDashboardView
  - SleepReportView
    - SleepTimelineView
    - MorningCheckInView
    - PrivacySettingsView
  - MorningBriefView
  - DailyRhythmReportView
  - EveningCheckInView
  - DailyHealthCardPreviewView
    - DailyHealthCardView
  - TrendDashboardView
  - HealthDashboardView
- 수면 tab: SleepStartView
  - SleepReportView
    - SleepTimelineView
  - SleepTimelineView
  - TrendDashboardView
  - DevicePlacementGuideView
    - CalibrationView
  - PrivacySettingsView
  - SleepRecordingView
    - SleepReportView
- 건강 tab: HealthDashboardView
  - HealthMetricsOverviewView
    - MetricDetailView
  - HealthCalendarView
    - DailyMeasurementDetailContent
    - MetricDetailView
  - FitdaysImportView
    - DailyMeasurementDetailView
  - BloodPressureDashboardView
  - BodyCompositionDashboardView
  - CrossMetricDashboardView
- 설정 tab: SettingsListView
  - PrivacySettingsView
  - DevicePlacementGuideView
```

Navigation은 기존 SwiftUI `NavigationLink` 흐름을 유지합니다. 홈은 최근 상태를 점수와 요약으로 보여주는 종합 평가 화면이고, 수면 tab은 측정 시작/종료와 최근 수면 결과를 담당합니다. 건강 tab은 Apple 건강앱 read-only, 밤숨 앱 계산 수면 지표, Fitdays 로컬 import를 한곳에서 탐색하는 데이터 허브입니다. 설정 tab은 개인정보, 감지 민감도, 배치, 캘리브레이션, DEBUG 도구처럼 앱 동작을 조정하는 항목만 둡니다.

## DEBUG 전용 화면

다음 화면은 개발/검증용이며 DEBUG 빌드에서만 노출합니다.

| 화면 | 역할 | 주요 표시 데이터 | 주요 액션 |
| --- | --- | --- | --- |
| `DatasetReplayView` | 로컬 오디오 또는 synthetic audio를 분석 pipeline에 넣는 검증 화면 | replay 상태, manifest/file 상태, detector diagnostics, raw 후보 수, smoothing 전/후 수, 최종 이벤트 수 | replay 실행, 결과 확인 |
| `DetectorTuningView` | detector profile과 threshold 확인용 화면 | current backend, tuning profile, Core ML model installed 여부, fallback count, zero-event analysis | profile 선택, diagnostics 확인 |
| `SimulatorScenarioView` | 예시 수면 시나리오 적용 화면 | QuietNight, SnoreHeavyNight, LowAudioCoverageNight 등 simulator QA scenario | scenario 적용, 관련 화면 진입 |
| `AudioDebugView` | 오디오 입력과 detector output 요약 화면 | 최근 RMS/energy, detector backend, Core ML fallback 상태, 최신 output | DEBUG 입력 확인 |
| `SampleCaptureView` | 짧은 개발용 샘플 수집 화면 | 샘플 수, 저장 경로, capture 상태, 저장 정책 안내 | 짧은 샘플 캡처 |

Release 빌드에서는 detector threshold 조정, dataset replay, raw feature stream, 샘플 캡처 화면을 노출하지 않습니다.

## 개인정보 관련 화면

- `PrivacySettingsView`는 이벤트 오디오 샘플 저장 opt-in, 저장 용량, orphan cleanup, 전체 삭제, feedback 데이터 삭제 UI를 담당합니다.
- `SleepStartView`, `SleepRecordingView`, `SleepReportView`, `DevicePlacementGuideView`는 분석이 iPhone 안에서 수행되고 서버로 전송하지 않는다는 안내를 반복적으로 보여줍니다.
- 전체 밤 원본 오디오는 저장하지 않습니다.
- 이벤트 오디오 샘플은 사용자가 켠 경우에만 짧게 로컬 저장할 수 있고, 저장된 샘플은 앱에서 삭제할 수 있습니다.
- 이 앱은 진단 목적의 의료기기가 아닙니다.

## Health Dashboard 방향

Health dashboard는 Apple 건강앱 데이터를 read-only로 읽고, 사용자가 직접 가져온 Fitdays CSV/export 샘플을 로컬 전용 지표로 정리하는 확장 영역입니다. preview와 테스트에서는 예시/protocol 기반 데이터를 사용할 수 있습니다.

- 권한 요청은 사용자가 `HealthDashboardView`의 연결 액션을 선택할 때만 수행합니다.
- 앱은 HealthKit에 데이터를 쓰지 않습니다.
- 건강 데이터는 서버나 외부 앱으로 전송하지 않습니다.
- HealthKit 기반 metric과 Fitdays 로컬 전용 metric은 출처 badge, 지표 설명, 샘플 목록에서 구분합니다.
- `HealthMetricsOverviewView`는 카테고리별 지표를 보여주고, 각 row는 `MetricDetailView`로 이어집니다.
- 홈은 종합 평가만 보여주고, 최근 날짜 상세와 건강 캘린더는 건강 tab에서 진입합니다. 이 진입은 HealthKit 권한 요청을 직접 시작하지 않습니다.
- `HealthCalendarView`는 날짜별 데이터 존재 여부를 표시하고, 날짜 선택 시 같은 화면의 inline `DailyMeasurementDetailContent`에서 카테고리별 샘플을 바로 보여줍니다.
- `FitdaysImportView`는 사용자가 직접 선택한 로컬 파일 또는 직접 붙여넣은 월별 데이터 복사 텍스트만 처리하며, Fitdays 원격 서비스나 비공식 연결 방식에 직접 연결하지 않습니다.
- `CrossMetricDashboardView`는 수면 소리 지표와 건강 지표를 개인 패턴 참고용으로 비교하며, 인과관계를 의미하지 않습니다.

## Empty / Error State

주요 화면의 비어 있는 상태와 오류 상태는 `NBEmptyStateView`, `NBStatusBadge`, `NBPrivacyNoticeCard`를 우선 사용합니다.

- 리포트 없음: 수면 기록 후 리포트가 표시된다는 안내를 제공합니다.
- 이벤트 없음: detector 기준을 통과한 이벤트가 없었다는 맥락과 zero-event analysis를 함께 보여줍니다.
- 저장된 오디오 샘플 없음: opt-in 상태와 삭제/저장 정책을 같이 안내합니다.
- HealthKit 권한 없음 또는 데이터 없음: read-only 연결 흐름과 로컬 표시 원칙을 안내합니다.
- 낮은 오디오 커버리지: 색상만이 아니라 배지와 문장으로 상태를 설명합니다.
- Daily Rhythm 데이터 부족: `DailyDataQuality`와 제한 안내를 우선 표시합니다.
- Daily Health Card 민감 수치 숨김: `minimal` privacy level에서 점수와 한 줄 요약 중심으로 표시합니다.
