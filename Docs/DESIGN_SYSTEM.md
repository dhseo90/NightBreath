# NightBreath / 밤숨 디자인 시스템

## 디자인 원칙

밤숨은 iPhone 안에서 수면 중 소리를 분석해 아침에 이해하기 쉬운 리포트를 보여주는 웰니스 앱입니다. 화면은 조용함, 신뢰감, 밤, 호흡, 온디바이스 개인정보 보호를 중심으로 구성합니다.

핵심 원칙:
- 첫 화면에서 최근 리포트와 수면 시작 동선을 빠르게 찾을 수 있게 합니다.
- 측정 중에는 앱 동작 시간, 실제 오디오 수신 시간, 분석 시간, 커버리지를 분리해 보여줍니다.
- 리포트는 점수보다 이유와 측정 품질을 함께 설명합니다.
- 이벤트 오디오 샘플 저장은 opt-in 상태와 저장 용량을 명확히 보여줍니다.
- 화면은 병원/의료기기처럼 보이지 않게 차분한 웰니스 톤을 유지합니다.

## 참고 범위

공개 참고 링크에서는 모바일 화면에서 정보 계층을 정리하는 방식, 큰 CTA, 카드형 요약, 리스트형 데이터 표시, 상태를 명확히 보여주는 원칙만 참고했습니다.

사용하지 않은 것:
- 특정 브랜드 자산, 로고, 아이콘, 이미지, 스크린샷
- 특정 디자인 키트 또는 컴포넌트
- 특정 색상 토큰 이름과 값
- 특정 브랜드명을 포함한 코드/문서/컴포넌트명

## 색상 토큰

파일: `SleepSoundApp/Core/Design/NBColor.swift`

주요 토큰:
- `pageBackground`: 화면 전체의 밝고 조용한 배경
- `surface`: 카드와 리스트의 기본 표면
- `elevatedSurface`: 카드 내부의 보조 표면
- `cardStroke`: 카드 경계선
- `nightInk`: 주요 텍스트
- `mutedText`: 보조 텍스트
- `breathBlue`: 주요 액션과 점수
- `sleepTint`: 수면 시작/녹음 흐름
- `audioTint`: 오디오와 detector 상태
- `privacyTint`: 개인정보 보호 안내
- `success`, `warning`, `danger`, `neutral`: 상태 표현

## 타이포그래피

파일: `SleepSoundApp/Core/Design/NBTypography.swift`

주요 토큰:
- `screenTitle`: 화면 주요 제목
- `sectionTitle`: 카드/섹션 제목
- `cardTitle`: 요약 카드 제목
- `metricValue`: 숫자 지표
- `body`, `callout`, `caption`, `footnote`: 설명과 보조 정보

숫자 지표는 가능한 한 monospaced digit을 사용해 녹음 시간과 점수 변화가 안정적으로 보이게 합니다.

## 여백과 반경

파일:
- `SleepSoundApp/Core/Design/NBSpacing.swift`
- `SleepSoundApp/Core/Design/NBCornerRadius.swift`
- `SleepSoundApp/Core/Design/NBShadow.swift`

카드는 8pt 이하의 차분한 반경을 사용합니다. 버튼도 같은 반경을 공유해 화면 전체의 밀도를 맞춥니다.

## 컴포넌트

파일:
- `NBCard`
- `NBReportSection`
- `NBPrivacyNoticeCard`
- `NBDiagnosticCard`
- `NBPrimaryButtonStyle`
- `NBSecondaryButtonStyle`
- `NBStatusBadge`
- `NBListRow`
- `NBMetricCard`
- `NBTimelineRow`

사용 기준:
- `NBCard`: 단일 정보 묶음
- `NBReportSection`: 리포트/측정 상태처럼 제목과 내용이 있는 영역
- `NBPrivacyNoticeCard`: 온디바이스 분석, 서버 전송 없음, 전체 오디오 미저장 안내
- `NBDiagnosticCard`: detector diagnostics와 zero-event 분석
- `NBMetricCard`: 점수, 시간, 이벤트 수, 저장 용량 같은 지표
- `NBTimelineRow`: 이벤트 타입, 시간, 신뢰도, 재생/삭제 액션

## 접근성

원칙:
- 중요한 상태는 색상만으로 구분하지 않고 텍스트로 함께 표시합니다.
- 버튼은 충분한 높이와 넓은 탭 영역을 유지합니다.
- 수면 소리 점수, 측정 품질, 저장 상태는 숫자와 설명을 함께 제공합니다.
- Dynamic Type에서 텍스트가 줄바꿈될 수 있게 카드와 리스트를 구성합니다.
- 이벤트 row는 VoiceOver에서 제목, 시간, duration, 신뢰도 정보를 함께 읽을 수 있게 유지합니다.

## 개인정보와 안전 문구

반드시 노출할 수 있는 문구:
- “수면 중 소리 기반 지표입니다.”
- “이 앱은 진단 목적의 의료기기가 아닙니다.”
- “원본 전체 오디오는 저장하지 않습니다.”
- “분석은 iPhone 안에서 수행됩니다.”

사용하지 않는 방향:
- 질병 확정처럼 보이는 표현
- 임상 수치처럼 보이는 점수 설명
- 특정 증상에 대한 단정적 판단
- 사용자가 켜지 않은 이벤트 오디오 샘플 저장을 암시하는 문구

## 화면 적용 범위

이번 디자인 시스템은 다음 화면에 적용합니다.
- 홈 대시보드
- 수면 시작
- 수면 기록 중
- 수면 리포트
- 이벤트 타임라인
- 아침 체크인
- 개인정보/저장소 관리
- 기기 배치 가이드
- DEBUG detector tuning/debug 화면

## 금지 자산 기준

프로젝트에 포함하면 안 되는 것:
- 참고 링크의 브랜드 로고, 아이콘, 이미지, 스크린샷
- 참고 링크의 UI Kit 또는 asset pack
- 참고 링크의 컴포넌트 구현체
- 참고 링크의 색상 토큰 이름과 값을 그대로 옮긴 코드

밤숨의 UI는 SF Symbols, SwiftUI Shape, NightBreath 전용 토큰과 컴포넌트만 사용합니다.
