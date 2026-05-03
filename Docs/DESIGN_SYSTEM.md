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

## Asset Catalog

위치: `SleepSoundApp/App/Assets.xcassets`

- `AccentColor`: NightBreath accent 색상
- `AppIcon.appiconset`: placeholder 구조

이번 작업에서는 고품질 앱 아이콘 이미지를 만들지 않습니다. 실제 아이콘 제작은 별도 디자인 작업으로 남깁니다.

## 접근성

- 주요 버튼은 44pt 이상의 tappable area를 유지합니다.
- 중요한 상태는 색상만으로 구분하지 않고 텍스트와 아이콘을 함께 제공합니다.
- 수치 카드에는 의미 있는 `accessibilityLabel`을 제공합니다.
- Dynamic Type에서 긴 한국어 문구가 줄바꿈될 수 있게 `fixedSize(horizontal: false, vertical: true)`를 사용합니다.
- 아이콘 전용 버튼은 VoiceOver label을 반드시 가집니다.

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

피해야 할 방향:

- 질병을 확정하는 표현
- 임상 지표를 정확히 측정한다고 보이는 표현
- 치료나 검사를 대신한다고 보이는 표현
- 사용자가 켜지 않은 이벤트 오디오 샘플 저장을 암시하는 표현
