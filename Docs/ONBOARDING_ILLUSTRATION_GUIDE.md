# NightBreath / 밤숨 Onboarding Illustration Guide

## 목적

온보딩과 empty state에 필요한 NightBreath 고유 illustration placeholder를 정의합니다. 현재 앱은 외부 이미지 없이 SwiftUI `Shape`, `Path`, `Circle`, `RoundedRectangle`, SF Symbols를 조합한 original placeholder를 사용합니다.

최종 고품질 bitmap illustration은 별도 디자인 작업으로 제작할 수 있지만, 지금 단계에서는 앱에 복잡한 이미지 asset을 넣지 않습니다.

## 필요한 일러스트 목록

| 이름 | SwiftUI View | 목적 | Asset placeholder |
| --- | --- | --- | --- |
| 온보딩 소개 | `NBOnboardingIntroIllustration` | 첫 온보딩, 브랜드 첫인상 | `Illustrations/onboarding_breath_placeholder` |
| 달 + 숨결 파형 | `NBMoonBreathIllustration` | 수면 소리 흐름 보조 illustration | `Illustrations/onboarding_breath_placeholder` |
| 온디바이스 프라이버시 | `NBPrivacyOnDeviceIllustration` | 로컬 분석, 서버 전송 없음 안내 | `Illustrations/onboarding_privacy_placeholder` |
| 기기 배치 | `NBDevicePlacementIllustration` | 머리맡 주변 iPhone 배치 안내 | `Illustrations/onboarding_device_placement_placeholder` |
| 이벤트 오디오 샘플 | `NBEventAudioSamplesIllustration` | opt-in 짧은 샘플 저장 안내 | `Illustrations/event_audio_samples_placeholder` |
| 마이크 권한 | `NBMicrophonePermissionIllustration` | 마이크 접근과 로컬 처리 안내 | `Illustrations/microphone_permission_placeholder` |
| 캘리브레이션 확인 | `NBCalibrationCheckIllustration` | 입력 baseline 확인 안내 | `Illustrations/calibration_check_placeholder` |
| 수면 리포트 | `NBSleepReportIllustration` | 리포트 없음, 리포트 소개 | `Illustrations/empty_report_placeholder` |
| 건강 대시보드 | `NBHealthDashboardIllustration` | HealthKit read-only 확장 방향 | 별도 bitmap 필요 시 future slot 추가 |
| 리포트 없음 | `NBEmptyReportIllustration` | 수면 기록 전 empty state | `Illustrations/empty_report_placeholder` |
| 타임라인 없음 | `NBEmptyTimelineIllustration` | 이벤트 없음 empty state | `Illustrations/empty_timeline_placeholder` |
| 호흡 파형 | `NBBreathWaveIllustration` | 이벤트 샘플, empty timeline, 소리 흐름 | `Illustrations/empty_timeline_placeholder` |

## 화면 연결

- `OnboardingView`
  - Intro: `NBIllustration(kind: .onboardingIntro)`
  - Privacy: `NBIllustration(kind: .privacyOnDevice)`
  - 전체 밤 오디오 미저장: `NBIllustration(kind: .sleepReport)`
  - 이벤트 샘플: `NBIllustration(kind: .eventAudioSamples)`
  - 기기 배치: `NBIllustration(kind: .devicePlacement)`
  - 마이크 권한: `NBIllustration(kind: .microphonePermission)`
  - 캘리브레이션: `NBIllustration(kind: .calibrationCheck)`
- `DevicePlacementGuideView`
  - 기기 배치 안내에서 SwiftUI original illustration을 사용합니다.
- Empty state
  - 리포트 없음: `NBIllustration(kind: .emptyReport)`
  - 타임라인 이벤트 없음: `NBIllustration(kind: .emptyTimeline)`

## Style Guide

- 둥근 카드, 낮은 대비의 배경, 부드러운 breath wave를 중심으로 합니다.
- 선은 너무 얇지 않게 유지해 작은 iPhone 화면에서도 보이게 합니다.
- 색상은 `NBColor.sleep`, `NBColor.breath`, `NBColor.privacy`, `NBColor.cardBackground`, `NBColor.divider`를 기준으로 합니다.
- Light/Dark Mode에서는 `NBColor` dynamic token에 맡기고, 화면마다 별도 색상을 반복하지 않습니다.
- SF Symbols는 보조 cue로만 사용하고, 핵심 형태는 SwiftUI original shape로 만듭니다.
- 경고/병원/검사 장비처럼 보이는 visual cue는 피합니다.

## 외부 자산 제한

- 타사 이미지, 로고, 앱 아이콘, 스크린샷을 프로젝트에 넣지 않습니다.
- Toss/TDS 또는 외부 디자인 시스템의 색상, 아이콘, 컴포넌트, 일러스트 스타일을 복제하지 않습니다.
- 최종 bitmap illustration을 제작하더라도 source reference 파일은 앱 bundle에 포함하지 않습니다.

## 최종 이미지 제작 시 남은 일

1. 위 SwiftUI placeholder와 같은 의미 구조를 유지한 고품질 artwork를 제작합니다.
2. iPhone 작은 화면에서 문양이 뭉개지지 않는지 확인합니다.
3. Light/Dark 배경에서 contrast를 확인합니다.
4. Xcode asset slot에 export 파일만 추가합니다.
5. 앱 빌드와 onboarding preview를 다시 확인합니다.
