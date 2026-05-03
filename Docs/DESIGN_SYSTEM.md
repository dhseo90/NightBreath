# NightBreath / 밤숨 디자인 시스템

## 디자인 원칙

밤숨은 iPhone 안에서 수면 중 소리를 분석해 아침 리포트로 정리하는 웰니스 앱입니다. 화면은 조용함, 신뢰감, 밤, 호흡, 수면, 프라이버시를 중심으로 구성합니다.

- 차분하지만 의료기기처럼 딱딱하지 않은 웰니스 톤을 유지합니다.
- 점수는 “수면 소리 점수”로 표현하고, 단정 대신 맥락과 측정 품질을 함께 보여줍니다.
- 개인정보 보호 상태는 항상 이해하기 쉬운 문장과 아이콘으로 함께 표시합니다.
- 색상만으로 상태를 구분하지 않고 텍스트, SF Symbols, 배지를 함께 사용합니다.
- 기존 화면의 정보 구조를 크게 바꾸지 않고 재사용 가능한 SwiftUI 컴포넌트로 일관성을 높입니다.

## 브랜드 톤

- 한국어 앱 이름: 밤숨
- 영어 브랜드명: NightBreath
- 부제: 수면 소리 리포트 / Sleep Sound Report
- 키워드: 밤, 호흡, 조용함, 온디바이스 분석, 프라이버시, 아침 리포트

## 색상 토큰

파일: `SleepSoundApp/Core/Design/NBColor.swift`

`NBColor`는 SwiftUI dynamic color로 정의합니다. 화면별로 직접 RGB/hex 값을 반복하지 않고, Light/Dark appearance 차이는 token 안에서 처리합니다.

- `background`: 앱 전체 배경
- `groupedBackground`: 섹션이 많은 화면의 그룹 배경
- `cardBackground`: 기본 카드 표면
- `elevatedCardBackground`: 카드 내부 보조 표면
- `primaryText`, `secondaryText`, `tertiaryText`: 텍스트 계층
- `accent`, `accentSoft`: 기본 액션과 부드러운 강조
- `success`, `warning`, `caution`, `danger`: 상태 색상
- `border`, `divider`: 경계와 구분선
- `privacy`, `sleep`, `breath`: 밤숨 고유 의미 색상
- `chartPrimary`, `chartSecondary`: 차트 기본 색상

기존 화면 호환을 위해 `pageBackground`, `surface`, `elevatedSurface`, `nightInk`, `mutedText`, `breathBlue`, `privacyTint`, `sleepTint`, `audioTint` alias도 유지합니다.

Light mode는 깨끗한 blue-gray 배경, 밝은 card surface, 부드러운 shadow를 사용합니다. Dark mode는 깊은 night background, 살짝 밝은 elevated surface, 높은 text contrast, shadow보다 border 중심의 구분을 사용합니다.

## 타이포그래피

파일: `SleepSoundApp/Core/Design/NBTypography.swift`

- `titleLarge`, `title`, `headline`, `subheadline`
- `body`, `bodyEmphasis`
- `caption`, `captionEmphasis`
- `metricNumber`, `metricLabel`

숫자 지표는 `monospacedDigit()`을 사용해 녹음 시간, 커버리지, 점수 변화가 안정적으로 보이게 합니다. 모든 토큰은 Dynamic Type을 고려한 system font 기반입니다.

## Spacing

파일: `SleepSoundApp/Core/Design/NBSpacing.swift`

- 기본 단위: `xxs`, `xs`, `sm`, `md`, `lg`, `xl`, `xxl`
- 화면/섹션 단위: `screenHorizontal`, `sectionVertical`
- 컴포넌트 단위: `cardPadding`, `rowPadding`

기존 호출 호환을 위해 `xSmall`, `small`, `medium`, `large`, `xLarge`, `xxLarge`도 유지합니다.

## Corner Radius

파일: `SleepSoundApp/Core/Design/NBCornerRadius.swift`

- `small`: 작은 아이콘 배경
- `medium`: 버튼과 리스트 요소
- `large`: 넓은 표면
- `card`: 카드
- `pill`: 배지

카드는 8pt 반경을 기본으로 사용해 과하게 둥근 인상을 피합니다.

## Shadow

파일: `SleepSoundApp/Core/Design/NBShadow.swift`

- `subtle`: 구분이 필요한 작은 표면
- `card`: 기본 카드
- `elevated`: 중요 안내 카드

밤숨의 그림자는 낮은 opacity와 작은 y offset으로 제한합니다.

`NBCard`는 Light mode에서 `NBShadow.card`를 사용하고, Dark mode에서는 shadow를 거의 제거한 뒤 `border`와 `cardBackground`/`elevatedCardBackground` 대비로 표면을 구분합니다.

## Animation

파일: `SleepSoundApp/Core/Design/NBAnimation.swift`

- `buttonPress`: 버튼 눌림
- `stateChange`: 상태 전환
- `breathingPulse`: 녹음/호흡 계열의 잔잔한 반복 표현

애니메이션은 수면 앱의 조용한 분위기를 해치지 않게 짧고 부드럽게 사용합니다.

## 컴포넌트

Core/Design 컴포넌트:

- `NBPrimaryButton`, `NBSecondaryButton`, `NBDangerButton`, `NBIconButton`
- `NBCard`
- `NBMetricCard`
- `NBStatusBadge`
- `NBReportSection`
- `NBListRow`
- `NBTimelineRow`
- `NBPrivacyNoticeCard`
- `NBDiagnosticCard`
- `NBEmptyStateView`
- `NBLoadingStateView`
- `NBIllustration`

기존 화면에서 이미 쓰는 `NBPrimaryButtonStyle`, `NBSecondaryButtonStyle`, `NBStatusBadge(_:, systemImage:, tint:)`, `NBMetricCard(title:value:systemImage:tint:footnote:)` 호출은 계속 사용할 수 있습니다.

## Metric Card

`NBMetricCard`는 다음 정보를 표시할 수 있습니다.

- `title`
- `value`
- `unit`
- `subtitle`
- `systemImage`
- `status`
- `trend`
- `accessibilityLabel`

사용 예: 수면 소리 점수, 측정 품질, 실제 오디오 수신 시간, 녹음 커버리지, 저장된 이벤트 오디오 용량, 코골기 시간, 이갈이 의심 소리 횟수, 호흡정지 의심 구간 횟수.

## Status Badge

`NBStatusKind`:

- `good`
- `warning`
- `caution`
- `danger`
- `neutral`
- `privacy`
- `debug`

사용 예: 측정 품질 좋음, 오디오 커버리지 낮음, 이벤트 샘플 저장 꺼짐, 원본 전체 오디오 저장 안 함, DEBUG, Core ML fallback.

상태 배지는 색상만으로 의미를 전달하지 않습니다. `NBStatusBadge`는 텍스트와 SF Symbol을 함께 사용하고, Dark mode에서는 배경 tint와 stroke opacity를 높여 작은 caption 크기에서도 상태를 읽기 쉽게 유지합니다.

## Chart Color

- 차트의 주요 선/막대는 `NBColor.chartPrimary`, 보조 선/막대는 `NBColor.chartSecondary`를 사용합니다.
- 낮은 측정 품질 marker는 `NBColor.warning`과 diamond symbol을 함께 사용해 색상만으로 구분하지 않습니다.
- grid line은 `NBColor.divider`, axis label은 `NBColor.secondaryText`를 사용해 Light/Dark mode 모두에서 과하게 튀지 않게 합니다.

## Timeline Row

`NBTimelineRow`는 다음 정보를 표시할 수 있습니다.

- `eventType`
- `title`
- `time`
- `duration`
- `confidence`
- `subtitle`
- `hasAudioSample`
- play/delete action

`SleepEventType`별 기본 아이콘과 색상은 `NBEventTypeIcon`에서 관리합니다. 기존 커스텀 accessory 기반 initializer도 유지합니다.

이벤트 표시명과 기본 아이콘:

- `snore`: 코골기, `waveform` 또는 `NBBreathWaveIcon`
- `bruxismLike`: 이갈이 의심 소리, `NBBruxismLikeIcon`
- `breathingPauseSuspected`: 호흡정지 의심 구간, `NBMoonBreathIcon`
- `gaspLike`: gasp-like 회복 호흡, `wind`
- `coughLike`: 기침 의심 소리, `exclamationmark.triangle`
- `sleepTalkLike`: 잠꼬대/말소리 의심, `bubble.left.and.waveform`
- `movementLike`: 움직임 의심 소리, `figure.walk` 또는 `figure.roll`
- `environmentalNoise`: 환경 소음, `speaker.wave.2`
- `awakeningSuspected`: 각성 의심 구간, `eye`
- `unknown`: 알 수 없음, `questionmark.circle`

## Privacy Notice

`NBPrivacyNoticeCard` 기본 문구:

- 분석은 iPhone 안에서 수행됩니다.
- 원본 전체 오디오는 저장하지 않습니다.
- 이벤트 오디오 샘플은 사용자가 켠 경우에만 저장됩니다.
- 서버로 전송하지 않습니다.
- 이 앱은 진단 목적의 의료기기가 아닙니다.

## Diagnostic Card

`NBDiagnosticCard`는 detector diagnostics와 zero-event analysis를 표시하기 위한 컴포넌트입니다.

표시 가능 항목:

- raw 후보 수
- smoothing 전/후 수
- 최종 이벤트 수
- 주요 탈락 이유
- RMS/energy 요약
- detector backend
- tuning profile
- Core ML model installed 여부
- fallback count

일반 사용자 화면에서는 요약 중심으로 쓰고, DEBUG 화면에서는 `NBDiagnosticItem`과 `showsDetails`를 사용해 상세 정보를 표시합니다.

## 적용 화면

현재 주요 화면 적용 현황입니다. 화면별 역할, 표시 데이터, 주요 액션, navigation 관계는 `Docs/UI_SCREEN_MAP.md`에서 관리합니다.

- `HomeDashboardView`: `NBCard`, `NBMetricCard`, `NBStatusBadge`, `NBReportSection`, `NBListRow`, `NBEmptyStateView`, `NBPrivacyNoticeCard`로 최근 리포트, 수면 소리 점수, 측정 품질, 커버리지, 이벤트 오디오 샘플 상태, 온디바이스 분석 안내를 정리합니다.
- `SleepStartView`: `NBMoonBreathIcon`, `NBCard`, `NBReportSection`, `NBListRow`, `NBPrimaryButton`, `NBPrivacyNoticeCard`로 측정 시작 안내, 기기 배치, 마이크 권한, 이벤트 샘플 opt-in 상태를 표시합니다.
- `SleepRecordingView`: `NBRecordingPulseIcon`, `NBMetricCard`, `NBStatusBadge`, `NBDangerButton`, `NBPrivacyNoticeCard`로 녹음/분석 중 상태, 실제 오디오 수신/분석 시간, 커버리지, 오디오 중단 정보를 보여줍니다.
- `SleepReportView`: `NBMetricCard`, `NBReportSection`, `NBStatusBadge`, `NBDiagnosticCard`, `NBEmptyStateView`, `NBPrivacyNoticeCard`로 리포트 요약, detector diagnostics, zero-event analysis, 진단 목적 아님 안내를 정돈합니다.
- `SleepTimelineView`: `NBTimelineRow`, `NBStatusBadge`, `NBEmptyStateView`로 이벤트 타입, 시간, duration, confidence, 오디오 샘플 재생/삭제 상태를 표시합니다.
- `MorningCheckInView`: `NBCard`, `NBMetricCard`, `NBReportSection`, `NBStatusBadge`, `NBPrimaryButton`, `NBPrivacyNoticeCard`로 개운함, 피로감, 기억나는 각성, 메모 저장 흐름을 주관적 컨디션 기록 톤으로 정리합니다.
- `PrivacySettingsView`: `NBPrivacyNoticeCard`, `NBMetricCard`, `NBSecondaryButton`, `NBDangerButton`, `NBDiagnosticCard`로 이벤트 오디오 샘플 opt-in, 저장량, orphan cleanup, 전체 삭제, feedback 삭제 UI를 유지합니다.
- `DevicePlacementGuideView`: `NBIllustration`, `NBCard`, `NBReportSection`, `NBListRow`, `NBStatusBadge`, `NBPrivacyNoticeCard`로 iPhone 배치, 마이크 가림 방지, 충전 연결, 저전력 모드 확인, 30초 캘리브레이션 진입을 정리합니다.
- `HealthDashboardView`: 허브 구조를 유지하면서 `NBCard`, `NBListRow`, `NBMetricCard`, `NBStatusBadge`, `NBEmptyStateView`, `NBPrivacyNoticeCard`로 mock/future read-only 건강 데이터 안내와 BloodPressure/BodyComposition/CrossMetric 진입을 정리합니다.
- `BloodPressureDashboardView`: 최근 수축기/이완기 혈압, 측정 시각, 데이터 출처, 추세와 데이터 없음 상태를 `NBMetricCard`, `NBListRow`, `NBEmptyStateView` 중심으로 표시합니다.
- `BodyCompositionDashboardView`: 체중, 체지방률, BMI, 제지방량과 추세를 `NBMetricCard`와 `NBReportSection`으로 정리합니다.
- `CrossMetricDashboardView`: 수면 소리 지표와 건강 지표 비교, matched sample count, 데이터 부족 상태, 인과관계 아님 안내를 `NBMetricCard`, `NBStatusBadge`, `NBEmptyStateView`, `NBPrivacyNoticeCard`로 표시합니다.
- `TrendDashboardView`: `NBMetricCard`, `NBReportSection`, `NBStatusBadge`, `NBEmptyStateView`, `NBPrivacyNoticeCard`로 7일/30일/90일 수면 소리 지표 추세, 낮은 측정 품질 구분, 리포트 없음 상태를 표시합니다.
- DEBUG 화면: `DatasetReplayView`, `DetectorTuningView`, `SimulatorScenarioView`, `AudioDebugView`, `SampleCaptureView`는 `NBDiagnosticCard`, `NBMetricCard`, `NBStatusBadge`, `NBEmptyStateView`, `NBPrivacyNoticeCard`를 사용하고 `#if DEBUG` 경계를 유지합니다.

README에는 화면별 짧은 제품 요약만 두고, 구현자가 확인할 화면 흐름과 DEBUG/Release 구분은 `Docs/UI_SCREEN_MAP.md`를 기준으로 합니다.

## 컴포넌트 사용 예

일반 지표:

```swift
NBMetricCard(
  title: "녹음 커버리지",
  value: "96",
  unit: "%",
  subtitle: "좋음",
  systemImage: "waveform",
  tint: NBColor.success,
  status: .good,
  accessibilityLabel: "녹음 커버리지 96%, 좋음"
)
```

개인정보 안내:

```swift
NBPrivacyNoticeCard(
  title: "온디바이스 분석",
  messages: [
    "분석은 iPhone 안에서 수행됩니다.",
    "서버로 전송하지 않습니다.",
    "원본 전체 오디오는 저장하지 않습니다.",
  ]
)
```

DEBUG 진단:

```swift
NBDiagnosticCard(
  title: "DEBUG Detector 진단",
  summary: "raw 후보부터 최종 이벤트까지 확인합니다.",
  items: [
    NBDiagnosticItem(title: "raw 후보 수", value: "12개", status: .neutral),
    NBDiagnosticItem(title: "fallback count", value: "0회", status: .good),
  ],
  showsDetails: true
)
```

## 아이콘 원칙

- 기본 아이콘은 SF Symbols를 우선 사용합니다.
- SF Symbols로 부족한 경우 SwiftUI `Shape`, `Path`, `Circle`, `RoundedRectangle` 기반 original icon view를 사용합니다.
- 타사 이미지, 타사 로고, 타사 앱 아이콘, 타사 스크린샷은 프로젝트에 추가하지 않습니다.
- Toss Design System, TDS UI Kit, Toss 브랜드 자산, Toss 색상 토큰, Toss 컴포넌트는 직접 사용하거나 복제하지 않습니다.

Original SwiftUI icon:

- `NBBreathWaveIcon`
- `NBMoonBreathIcon`
- `NBPrivacyShieldIcon`
- `NBRecordingPulseIcon`
- `NBSleepScoreIcon`
- `NBStorageIcon`
- `NBBruxismLikeIcon`
- `NBEventTypeIcon`

Original SwiftUI illustration:

- `NBBreathWaveIllustration`
- `NBMoonBreathIllustration`
- `NBMoonSleepIllustration`
- `NBPrivacyOnDeviceIllustration`
- `NBDevicePlacementIllustration`
- `NBSleepReportIllustration`
- `NBHealthDashboardIllustration`
- `NBIllustration(kind:)`

Illustration은 onboarding, device placement guide, privacy notice, empty report, empty timeline 상태에서 사용합니다. 실제 bitmap asset이 아니라 SwiftUI `Shape`, `Path`, `Circle`, `RoundedRectangle`, SF Symbols 기반의 original placeholder입니다.

온보딩 illustration 제작 원칙과 최종 bitmap 교체 기준은 `Docs/ONBOARDING_ILLUSTRATION_GUIDE.md`에서 관리합니다.

## Asset Catalog

위치: `SleepSoundApp/App/Assets.xcassets`

- `AccentColor`: NightBreath accent 색상
- `AppIcon.appiconset`: placeholder 구조
- `Illustrations/`: future bitmap illustration export를 위한 placeholder namespace
- `Illustrations/onboarding_privacy_placeholder.imageset`
- `Illustrations/onboarding_breath_placeholder.imageset`
- `Illustrations/onboarding_device_placement_placeholder.imageset`
- `Illustrations/empty_report_placeholder.imageset`
- `Illustrations/empty_timeline_placeholder.imageset`
- `Screenshots/`: App Store screenshot 후보를 문서화하기 위한 metadata-only placeholder namespace
- `Screenshots/home_dashboard_placeholder.imageset`
- `Screenshots/recording_placeholder.imageset`
- `Screenshots/sleep_report_placeholder.imageset`
- `Screenshots/timeline_placeholder.imageset`
- `Screenshots/privacy_placeholder.imageset`
- `Screenshots/health_dashboard_placeholder.imageset`

Illustrations image set은 현재 metadata-only placeholder입니다. 앱 화면에서는 `NBIllustration.swift`의 SwiftUI original illustration을 사용하며, 최종 bitmap illustration이 필요한 경우 별도 디자인 작업 후 같은 slot에 export합니다.

Screenshots image set은 실제 App Store Connect 업로드용 screenshot 저장소가 아니라 후보 화면과 future placement를 나타내는 placeholder입니다. 최종 screenshot 이미지는 별도 캡처/review 후 관리 위치를 정합니다.

이번 작업에서는 고품질 앱 아이콘 이미지를 만들지 않습니다. 실제 아이콘 제작은 별도 디자인 작업으로 남깁니다.

앱 아이콘 제작 가이드는 `Docs/APP_ICON_GUIDE.md`를 기준으로 합니다.

App Store screenshot 후보와 headline copy는 `Docs/APP_STORE_SCREENSHOT_GUIDE.md`를 기준으로 합니다.

## Screenshot Scenario

위치: `SleepSoundApp/Features/ScreenshotScenarios.swift`

- `ScreenshotScenario`: README와 UI Gallery에 사용할 DEBUG 전용 screenshot 후보를 정의합니다.
- `ScreenshotScenarioFactory`: 기존 mock/simulator QA state를 사용해 screenshot capture에 필요한 demo app state를 만듭니다.
- screenshot scenario는 `#if DEBUG` 안에 있으므로 Release 사용자 화면에는 노출되지 않습니다.
- 실제 screenshot PNG를 생성하거나 App Store 제출을 진행하지 않습니다.
- screenshot scenario는 `SimulatorScenarioView`의 `Screenshot Preset` 섹션에서 선택하고, mock data 또는 simulator scenario만 사용합니다.
- scenario 이름과 suggested path는 `Docs/UI_GALLERY.md`와 `Tools/Screenshots/README.md`에 맞춰 관리합니다.
- fake screenshot, 실제 개인 건강 데이터, 실제 HealthKit 데이터, 실제 오디오 파일, 실제 이벤트 오디오 샘플은 사용하지 않습니다.
- capture helper는 `Tools/Screenshots/capture_screenshots.sh`를 사용하되, scenario 선택과 화면 이동은 DEBUG 앱 안에서 사람이 확인합니다.

## Screenshot 문서화 원칙

Screenshot 문서 구조는 `Docs/UI_GALLERY.md`와 `Docs/Screenshots/`를 기준으로 관리합니다.

- README에는 대표 화면 screenshot만 추가합니다.
- 모든 화면, edge state, DEBUG-only 화면의 상세 설명은 `Docs/UI_GALLERY.md`에 둡니다.
- 실제 screenshot 파일이 없으면 image markdown을 만들지 않고 `screenshot pending`으로 표시합니다.
- screenshot은 mock data 또는 simulator scenario 기반으로만 생성합니다.
- 실제 개인 건강 데이터, 실제 HealthKit 데이터, 실제 오디오 파일, 실제 이벤트 오디오 샘플을 사용하지 않습니다.
- 외부 자산, 타사 앱 screenshot, 타사 로고, 타사 앱 아이콘을 추가하지 않습니다.
- Light/Dark screenshot은 같은 mock state에서 쌍으로 관리하고, text contrast, badge contrast, chart axis, empty state 문구를 함께 확인합니다.
- Daily Rhythm과 Health Dashboard 화면은 개인 참고용 문구, HealthKit read-only 원칙, 서버 전송 없음 안내를 유지합니다.
- Cross Metric 화면은 수면 소리 지표와 건강 지표를 함께 보여도 인과관계를 의미하지 않는다는 안내를 유지합니다.

## 접근성

- 주요 버튼은 44pt 이상의 tappable area를 유지합니다.
- 중요한 상태는 색상만으로 구분하지 않고 텍스트와 아이콘을 함께 제공합니다.
- 수치 카드에는 의미 있는 `accessibilityLabel`을 제공합니다.
- Dynamic Type에서 긴 한국어 문구가 줄바꿈될 수 있게 `fixedSize(horizontal: false, vertical: true)`를 사용합니다.
- 아이콘 전용 버튼은 VoiceOver label을 반드시 가집니다.

## Preview 확인

주요 화면의 Light/Dark preview는 `SleepSoundApp/Features/ScreenAppearancePreviews.swift`의 `NBPrimaryScreenAppearance_Previews`에서 확인합니다.

포함 화면:

- `HomeDashboardView`
- `SleepStartView`
- `SleepRecordingView`
- `SleepReportView`
- `SleepTimelineView`
- `PrivacySettingsView`
- `HealthDashboardView`
- `TrendDashboardView`
- DEBUG 대표 화면: `DetectorTuningView`

Xcode canvas에서 각 preview의 `Light`/`Dark` variant를 비교해 card surface, badge contrast, chart grid/axis, empty state, privacy notice 가독성을 확인합니다.

## Empty / Error State

- `NBEmptyStateView`는 리포트 없음, 이벤트 없음, 저장된 오디오 샘플 없음, HealthKit 권한 없음, HealthKit 데이터 없음, Dataset Replay 파일 없음, detector model 없음, 낮은 오디오 커버리지, zero-event session 상태에 사용합니다.
- empty state 문구는 원인을 단정하지 않고 현재 상태와 다음에 기대할 수 있는 정보를 짧게 설명합니다.
- zero-event session은 “이벤트가 없었다”가 아니라 “detector 기준을 통과한 이벤트가 없었습니다”처럼 감지 기준과 측정 맥락을 함께 표현합니다.
- 낮은 측정 품질은 색상만으로 표시하지 않고 `NBStatusBadge`와 안내 문구를 함께 사용합니다.

## 문구 원칙

사용 가능한 표현:

- 수면 중 소리 기반 지표
- 수면 소리 점수
- 코골기
- 이갈이 의심 소리
- 호흡정지 의심 구간
- gasp-like 회복 호흡
- 기침 의심 소리
- 환경 소음
- 각성 의심 구간
- 이 앱은 진단 목적의 의료기기가 아닙니다
- 원본 전체 오디오는 저장하지 않습니다
- 분석은 iPhone 안에서 수행됩니다
- 서버로 전송하지 않습니다
- 이벤트 오디오 샘플은 사용자가 켠 경우에만 저장됩니다
- 개인 패턴을 살펴보기 위한 참고용 보기입니다
- 인과관계를 의미하지 않습니다

피해야 할 방향:

- 질병을 확정하는 표현
- 임상 지표를 정확히 측정한다고 보이는 표현
- 치료나 검사를 대신한다고 보이는 표현
- 사용자가 켜지 않은 이벤트 오디오 샘플 저장을 암시하는 표현

## DEBUG / Release 구분

- DEBUG 화면은 `#if DEBUG`로 감싼 파일과 설정 화면의 DEBUG 전용 NavigationLink를 통해서만 접근합니다.
- DEBUG 화면에는 `NBStatusBadge("DEBUG 전용", kind: .debug)` 또는 `NBDiagnosticCard`를 사용해 일반 사용자 화면과 시각적으로 구분합니다.
- Release 화면에는 detector threshold 조정, dataset replay, raw feature stream, 샘플 수집 UI를 노출하지 않습니다.
- 일반 사용자 화면에서 detector diagnostics를 보여줄 때는 요약 중심으로 표현하고, 낮은 커버리지나 zero-event 상태도 단정하지 않습니다.

## 외부 디자인/자산 제한

- Toss Design System, TDS UI Kit, Toss 브랜드 자산, Toss 색상 토큰, Toss 컴포넌트를 직접 사용하거나 복제하지 않습니다.
- 타사 앱 스크린샷, 타사 로고, 타사 앱 아이콘, 타사 이미지를 프로젝트에 추가하지 않습니다.
- 필요한 아이콘은 SF Symbols를 우선 사용하고, 부족한 경우 SwiftUI Shape/Path 기반 NightBreath original icon view를 만듭니다.
