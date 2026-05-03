# NightBreath / 밤숨 App Store Screenshot Guide

## 상태

App Store 제출은 아직 보류 상태입니다. Apple Developer Program 등록 여부와 무관하게, 지금은 screenshot 후보 화면, demo state, headline copy, capture 절차만 준비합니다.

실제 screenshot 생성은 나중에 Simulator 또는 실제 iPhone에서 진행합니다. 이번 작업에서는 최종 screenshot 이미지를 만들거나 App Store Connect에 업로드하지 않습니다.

## Screenshot 후보 화면

| Scenario | 화면 | Demo state | Headline copy 초안 |
| --- | --- | --- | --- |
| `ScreenshotHomeScenario` | 홈 대시보드 | 최근 리포트와 점수, 측정 품질, privacy notice | 수면 중 소리 기반 지표를 한눈에 |
| `ScreenshotRecordingScenario` | 수면 녹음 중 | 녹음 중, 실제 오디오 수신 시간, 커버리지 | iPhone 안에서 조용히 분석 |
| `ScreenshotReportScenario` | 수면 리포트 | 수면 소리 점수, 주요 이벤트, diagnostics 요약 | 아침에 읽기 쉬운 수면 소리 리포트 |
| `ScreenshotTimelineScenario` | 이벤트 타임라인 | 코골기, 환경 소음, 샘플 상태 | 코골기와 환경 소음 흐름 확인 |
| `ScreenshotPrivacyScenario` | 개인정보 설정 | opt-in, 저장 용량, 삭제 액션 | 전체 밤 오디오는 저장하지 않습니다 |
| `ScreenshotHealthDashboardScenario` | 건강 대시보드 | read-only 방향, 혈압/체성분 진입 | 혈압/체성분 대시보드 준비 |

## DEBUG Screenshot Preset

코드 위치:

- `SleepSoundApp/Features/ScreenshotScenarios.swift`

이 파일은 `#if DEBUG` 안에서만 빌드됩니다. Release 사용자 화면에는 screenshot mode가 노출되지 않습니다.

제공 항목:

- `ScreenshotScenario`
- `ScreenshotScenarioFactory.makeAppState(for:)`
- scenario별 headline copy와 capture note
- 기존 `SimulatorQAScenarioFactory` 기반 mock report state

실제 오디오 파일, 서버 전송, HealthKit 권한 요청, storage schema 변경은 포함하지 않습니다.

## Capture 원칙

- iPhone 최신 기본 크기와 작은 화면을 모두 확인합니다.
- Light/Dark 중 App Store 메시지가 더 잘 드러나는 쪽을 우선하되, 앱 내부 품질은 둘 다 확인합니다.
- headline은 짧고 설명적이어야 합니다.
- 화면에 Debug badge나 raw detector tuning UI가 보이지 않게 합니다.
- 개인정보 문구는 screenshot 안에서도 자연스럽게 보여야 합니다.

## 사용할 수 있는 문구

- 수면 중 소리 기반 지표
- 수면 소리 점수
- 온디바이스 분석
- 서버로 전송하지 않습니다
- 전체 밤 오디오는 저장하지 않습니다
- 이벤트 샘플은 opt-in
- 분석은 iPhone 안에서 수행됩니다
- 혈압/체성분 대시보드 준비
- 개인 패턴을 살펴보기 위한 참고용 보기입니다

## 피해야 할 문구 방향

- 질병을 확정하는 표현
- 특정 임상 지표를 정확히 산출한다고 보이는 표현
- 검사나 전문가 판단을 대신한다고 보이는 표현
- 치료 판단을 유도하는 표현
- HealthKit 데이터를 서버로 보내는 것처럼 보이는 표현

## Asset Catalog Placeholder

위치:

- `SleepSoundApp/App/Assets.xcassets/Screenshots/`

현재는 문서와 future placement를 위한 metadata-only placeholder입니다. App Store Connect에 업로드할 실제 screenshot asset 저장소가 아니며, 최종 screenshot PNG를 이번 단계에서 추가하지 않습니다.

Placeholder slot:

- `home_dashboard_placeholder`
- `recording_placeholder`
- `sleep_report_placeholder`
- `timeline_placeholder`
- `privacy_placeholder`
- `health_dashboard_placeholder`

## 나중에 실제 캡처할 때

1. DEBUG 빌드에서 screenshot scenario state를 적용합니다.
2. 각 후보 화면으로 이동합니다.
3. 개인정보/웰니스 문구와 버튼이 잘리지 않는지 확인합니다.
4. Simulator 또는 실제 기기 screenshot을 생성합니다.
5. App Store 제출 전, 최종 screenshot 파일은 별도 review를 거쳐 관리 위치를 정합니다.
