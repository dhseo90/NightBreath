# NightBreath / 밤숨 UI Screen Map

이 문서는 밤숨 앱의 주요 화면 역할, 표시 데이터, 주요 액션, navigation 관계를 한눈에 보기 위한 요약입니다. 디자인 토큰과 공통 컴포넌트 설명은 `Docs/DESIGN_SYSTEM.md`를 기준으로 합니다.

## 화면 목록

| 화면 | 역할 | 주요 표시 데이터 | 주요 액션 |
| --- | --- | --- | --- |
| `HomeDashboardView` | 앱 홈과 최근 리포트 허브 | 앱 이름, 최근 수면 리포트, 수면 소리 점수, 측정 품질, 실제 오디오 수신 시간, 녹음 커버리지, 주요 이벤트 요약, 이벤트 오디오 샘플 저장 상태 | 수면 시작, 리포트 보기, 타임라인 보기, Daily Rhythm/트렌드/건강/개인정보/가이드 진입 |
| `SleepStartView` | 오늘 밤 측정 시작 전 준비 화면 | 측정 안내, 기기 배치 요약, 마이크 권한, 이벤트 오디오 샘플 저장 ON/OFF, 원본 전체 오디오 저장 안 함, 온디바이스 분석 안내 | 수면 시작, 배치 가이드/개인정보 설정 진입 |
| `SleepRecordingView` | 수면 기록 중 상태 화면 | 세션 경과 시간, 실제 오디오 수신 시간, 실제 분석 시간, 녹음 커버리지, 마지막 입력/분석 시각, 입력 공백, detector backend, tuning profile, 이벤트 오디오 샘플 저장 상태 | 수면 종료, 리포트 보기 |
| `SleepReportView` | 아침 수면 소리 리포트 | 수면 소리 점수, 측정 품질, 측정 시간, 오디오 커버리지, 주요 이벤트 카드, 저장된 이벤트 오디오 시간/용량, detector diagnostics 요약, zero-event analysis, 주요 원인 설명 | 타임라인 보기, 아침 체크인 진입, 개인정보 설정 진입 |
| `SleepTimelineView` | 수면 이벤트 상세 목록 | 이벤트 시간, 이벤트 타입, duration, confidence, 설명, 오디오 샘플 보유 여부, feedback 상태 | 오디오 샘플 재생/삭제, 이벤트 feedback 저장 |
| `MorningCheckInView` | 아침 주관적 컨디션 기록 | 개운함, 피로감, 두통 여부, 입마름 여부, 목아픔 여부, 기억나는 중간 각성 횟수, 메모 | 체크인 저장 |
| `MorningBriefView` | 오늘 아침 리포트 | 지난밤 수면 요약, 수면 소리 점수, 측정 품질, 아침 컨디션, mock 아침 혈압/체중/체성분, 데이터 품질, 개인 참고용 안내 | 수면 리포트와 Daily Rhythm 흐름 확인 |
| `DailyRhythmReportView` | 오늘의 리듬 리포트 | 오늘의 리듬 점수, data quality, 수면/회복/활동/혈압/체성분 component, Daily Insight 목록, 인과관계 아님 안내 | 하루 리듬 요약 확인 |
| `EveningCheckInView` | 저녁 컨디션 기록 | 하루 피로도, 스트레스, optional 기분, 카페인/음주/야식/운동/낮잠, 메모 | mock/in-memory 체크인 저장 |
| `DailyHealthCardView` | 하루 리듬 카드 표시 | 날짜, 오늘의 리듬 점수, 수면 소리 점수, 측정 품질, 핵심 지표, 한 줄 요약, 개인 참고용 문구 | 카드 UI 확인 |
| `DailyHealthCardPreviewView` | 카드 template/privacy 미리보기 | template 선택, privacy level 선택, mock 리포트 기반 카드 preview | template/privacy level 전환 |
| `PrivacySettingsView` | 로컬 저장과 개인정보 설정 | 이벤트 오디오 샘플 opt-in, 저장된 샘플 수, 총 시간, 용량, orphan 샘플 수, feedback 데이터 상태, 전체 밤 원본 오디오 저장 안 함, 서버 전송 없음 | 이벤트 샘플 저장 토글, orphan 샘플 정리, 전체 이벤트 샘플 삭제, feedback 삭제 |
| `DevicePlacementGuideView` | iPhone 배치와 캘리브레이션 안내 | 침대 옆 배치, 마이크 가림 방지, 충전 연결 권장, 저전력 모드 확인, 너무 멀거나 밀폐된 위치 피하기 | 30초 캘리브레이션 실행 |
| `TrendDashboardView` | 최근 7일/30일/90일 수면 소리 지표 흐름 | 수면 소리 점수, 코골기 시간, 호흡정지 의심 구간, 이갈이 의심 소리, 환경 소음, 측정 품질 추세 | 기간 선택 |
| `HealthDashboardView` | 건강 데이터 dashboard 허브 | mock/future read-only 상태, 최근 건강 지표, 데이터 출처, BloodPressure/BodyComposition/CrossMetric 진입 | 건강 데이터 연결 방향 안내, 하위 dashboard 진입 |
| `BloodPressureDashboardView` | 혈압 데이터 보기 | 최근 수축기/이완기 혈압, 최근 측정 시각, 데이터 출처, 기간별 추세, 데이터 없음/권한 없음 상태 | 기간 선택, 향후 HealthKit 연결 흐름 진입 |
| `BodyCompositionDashboardView` | 체중/체성분 데이터 보기 | 체중, 체지방률, BMI, 제지방량, 데이터 출처, 기간별 추세, 데이터 없음/권한 없음 상태 | 기간 선택, 향후 HealthKit 연결 흐름 진입 |
| `CrossMetricDashboardView` | 수면 소리 지표와 건강 지표 참고용 비교 | 선택한 수면 소리 지표, 선택한 건강 지표, matched sample count, 데이터 부족 상태, 인과관계 아님 안내 | 비교 항목/기간 선택 |

## Navigation 구조

```text
HomeDashboardView
- SleepStartView
  - DevicePlacementGuideView
    - CalibrationView
  - PrivacySettingsView
  - SleepRecordingView
    - SleepReportView
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
  - BloodPressureDashboardView
  - BodyCompositionDashboardView
  - CrossMetricDashboardView
- PrivacySettingsView
- DevicePlacementGuideView
```

Navigation은 기존 SwiftUI `NavigationLink` 흐름을 유지합니다. 홈은 최근 리포트와 수면 시작 CTA의 허브 역할을 하고, 리포트 화면은 타임라인과 아침 체크인으로 이어지는 상세 흐름을 제공합니다.

## DEBUG 전용 화면

다음 화면은 개발/검증용이며 DEBUG 빌드에서만 노출합니다.

| 화면 | 역할 | 주요 표시 데이터 | 주요 액션 |
| --- | --- | --- | --- |
| `DatasetReplayView` | 로컬 오디오 또는 synthetic audio를 분석 pipeline에 넣는 검증 화면 | replay 상태, manifest/file 상태, detector diagnostics, raw 후보 수, smoothing 전/후 수, 최종 이벤트 수 | replay 실행, 결과 확인 |
| `DetectorTuningView` | detector profile과 threshold 확인용 화면 | current backend, tuning profile, Core ML model installed 여부, fallback count, zero-event analysis | profile 선택, diagnostics 확인 |
| `SimulatorScenarioView` | mock 수면 시나리오 적용 화면 | QuietNight, SnoreHeavyNight, LowAudioCoverageNight 등 simulator QA scenario | scenario 적용, 관련 화면 진입 |
| `AudioDebugView` | 오디오 입력과 detector output 요약 화면 | 최근 RMS/energy, detector backend, Core ML fallback 상태, 최신 output | DEBUG 입력 확인 |
| `SampleCaptureView` | 짧은 개발용 샘플 수집 화면 | sample count, 저장 경로, capture 상태, 저장 정책 안내 | 짧은 샘플 캡처 |

Release 빌드에서는 detector threshold 조정, dataset replay, raw feature stream, sample capture 화면을 노출하지 않습니다.

## 개인정보 관련 화면

- `PrivacySettingsView`는 이벤트 오디오 샘플 저장 opt-in, 저장 용량, orphan cleanup, 전체 삭제, feedback 데이터 삭제 UI를 담당합니다.
- `SleepStartView`, `SleepRecordingView`, `SleepReportView`, `DevicePlacementGuideView`는 분석이 iPhone 안에서 수행되고 서버로 전송하지 않는다는 안내를 반복적으로 보여줍니다.
- 전체 밤 원본 오디오는 저장하지 않습니다.
- 이벤트 오디오 샘플은 사용자가 켠 경우에만 짧게 로컬 저장할 수 있고, 저장된 샘플은 앱에서 삭제할 수 있습니다.
- 이 앱은 진단 목적의 의료기기가 아닙니다.

## Health Dashboard 방향

Health dashboard는 향후 Apple 건강앱 데이터를 read-only로 읽어 로컬 화면에 정리하는 확장 영역입니다. 현재 화면과 Daily Rhythm 흐름은 mock/protocol 기반 데이터를 사용합니다.

- 권한 요청은 후속 HealthKit 작업에서 사용자가 `HealthDashboardView`의 연결 액션을 선택할 때만 검토합니다.
- 앱은 HealthKit에 데이터를 쓰지 않습니다.
- 건강 데이터는 서버나 외부 앱으로 전송하지 않습니다.
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
