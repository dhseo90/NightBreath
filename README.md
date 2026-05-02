# NightBreath / 밤숨

밤숨은 iPhone 온디바이스 기반 수면 소리 리포트 앱입니다.

앱은 사용자가 잠든 동안 감지된 소리를 바탕으로 아침에 “수면 소리 점수”와 이벤트 요약을 보여주는 웰니스 앱을 목표로 합니다. 모든 분석은 iPhone 내부에서 수행하는 방향을 우선하며, V1에서는 서버 업로드, 계정 시스템, 외부 API, 외부 분석 SDK를 사용하지 않습니다.

## 앱 이름

- 한국어 표시 이름: 밤숨
- 영어 프로젝트 / 브랜드 이름: NightBreath
- 한국어 부제: 수면 소리 리포트
- 영어 부제: Sleep Sound Report

## 제품 원칙

- 수면 중 소리 기반 지표를 제공하는 웰니스 앱입니다.
- 질병 진단, 치료 판단, 의료기기 역할을 주장하지 않습니다.
- “코골기”, “이갈이 의심 소리”, “호흡정지 의심 구간”, “기침 의심 소리”처럼 감지/의심 표현을 사용합니다.
- 잠꼬대/말소리는 이벤트 여부만 다루며, 말을 텍스트로 변환하지 않습니다.
- 원본 전체 오디오 파일은 기본 저장하지 않습니다.

## V1 범위

현재 V1의 목표는 기초 앱 구조와 mock 리포트 흐름을 만드는 것입니다.

구현 대상:
- SwiftUI 앱 구조
- 수면 시작/종료 흐름
- 로컬 수면 세션/이벤트/리포트 모델
- 아침 컨디션 체크인 모델
- mock 데이터 기반 홈 대시보드
- 수면 리포트 화면
- 이벤트 타임라인 화면
- 수면 소리 점수 계산
- 이벤트 집계 로직
- rule-based 분석 placeholder
- 오디오 캡처 서비스 skeleton
- 향후 HealthKit 확장을 위한 모델과 placeholder

V1에서 제외:
- 실제 HealthKit 권한 요청과 데이터 읽기
- Apple Watch 연동
- 혈압/체중/체성분 그래프
- 서버 업로드
- 클라우드 동기화
- 외부 API 호출
- 외부 분석/광고 SDK
- 의료 진단 문구
- 임상 지표로서의 AHI 계산
- 밤새 원본 오디오 전체 저장

## 주요 기능 흐름

1. 사용자가 자기 전 “수면 시작”을 누릅니다.
2. 앱은 수면 중 감지된 소리 이벤트를 로컬 데이터로 다루는 구조를 사용합니다.
3. 아침에 사용자가 “수면 종료”를 누릅니다.
4. 앱은 mock 분석 결과 기반 수면 리포트를 보여줍니다.
5. 사용자는 아침 컨디션을 체크인할 수 있습니다.

## 현재 프로젝트 구조

```text
SleepSoundApp
- App
- Features
  - Sleep
  - Dashboard
  - Settings
- Core
  - Audio
  - Analysis
  - Models
  - Storage
  - Privacy
  - FutureHealth
- Tests
```

## 핵심 모델

- `SleepSession`: 수면 측정 세션
- `SleepEvent`: 감지된 수면 중 소리 이벤트
- `NightReport`: 아침 수면 소리 리포트
- `MorningCheckIn`: 사용자의 아침 컨디션 기록
- `HealthMetricSample`: 향후 Apple 건강앱 데이터 확장을 위한 placeholder 모델

## 수면 소리 점수

수면 소리 점수는 100점에서 시작해 감지된 이벤트를 바탕으로 감점하는 웰니스 점수입니다.

감점 요인 예시:
- 코골기 비율
- 이갈이 의심 소리 이벤트 수
- 호흡정지 의심 구간 수
- gasp-like 회복 호흡 이벤트 수
- 기침 의심 소리 이벤트 수
- 환경 소음 이벤트 수
- 각성 의심 구간 수
- 너무 짧은 측정 시간

점수는 0점에서 100점 사이로 제한합니다.

## 빌드

Xcode에서 열기:

```bash
open SleepSoundApp.xcodeproj
```

명령줄 iOS generic build 예시:

```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
xcodebuild \
  -project SleepSoundApp.xcodeproj \
  -scheme SleepSoundApp \
  -configuration Debug \
  -destination generic/platform=iOS \
  -derivedDataPath .build/XcodeDerivedData \
  CODE_SIGNING_ALLOWED=NO \
  build
```

## 테스트

SwiftPM 기반 코어 테스트:

```bash
swift test --cache-path .build/swiftpm-cache
```

현재 테스트 대상:
- `SleepScoreCalculator`
- `SleepEventAggregator`

## 개인정보 보호 방향

- 서버 업로드 없음
- 클라우드 처리 없음
- 외부 API 호출 없음
- 외부 분석 SDK 없음
- 광고 SDK 없음
- V1 계정 시스템 없음
- 전체 원본 오디오 기본 저장 없음
- 잠꼬대 텍스트 변환 없음

## 향후 확장

향후 Apple HealthKit을 통해 다음 데이터를 읽는 건강 대시보드로 확장할 수 있습니다.

- 수축기 혈압
- 이완기 혈압
- 체중
- 체지방률
- BMI
- 제지방량
- 수면 시간
- 심박수
- 호흡수

다만 V1에서는 HealthKit 권한 요청과 실제 데이터 읽기를 구현하지 않습니다.
