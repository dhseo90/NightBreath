# NightBreath / 밤숨

밤숨(NightBreath)은 iPhone 온디바이스 기반 수면 소리 리포트 앱입니다.

사용자가 자기 전 수면 측정을 시작하면 앱은 iPhone 내부에서 마이크 입력을 처리하고, 아침에 감지된 수면 중 소리 이벤트를 바탕으로 웰니스 성격의 “수면 소리 점수”와 리포트를 보여주는 것을 목표로 합니다.

이 앱은 진단 목적의 의료기기가 아니며, 질병을 확정하거나 치료 판단을 제공하지 않습니다.

## 앱 이름

- 한국어 표시 이름: 밤숨
- 영어 프로젝트 / 브랜드 이름: NightBreath
- 한국어 부제: 수면 소리 리포트
- 영어 부제: Sleep Sound Report

## V1 기능

V1 프로토타입은 실제 iPhone에서 기본적인 오디오 캡처 흐름과 로컬 리포트 생성을 확인하는 단계입니다. 분석 정확도보다 앱 구조, 개인정보 원칙, 테스트 가능한 파이프라인을 우선합니다.

- SwiftUI 기반 앱 구조
- 수면 시작/종료 흐름
- 마이크 권한 요청 및 오디오 캡처 시작/종료
- AVAudioEngine 기반 오디오 청크 생성
- rule-based 수면 소리 감지 placeholder
- 수면 이벤트 집계
- 수면 소리 점수 계산
- 아침 수면 리포트 UI
- 수면 이벤트 타임라인
- 최근 7일 추세 UI
- 아침 컨디션 체크인
- 로컬 저장소 기반 세션/이벤트/리포트/체크인 저장
- 개인정보 설정의 로컬 데이터 삭제
- DEBUG 빌드 전용 오디오 디버그 화면
- 향후 HealthKit 확장을 위한 모델과 placeholder

## V1에서 하지 않는 것

- HealthKit 권한 요청
- Apple 건강앱 데이터 읽기/쓰기
- 혈압, 체중, 체성분 그래프
- Apple Watch 연동
- 서버 업로드
- 클라우드 처리 또는 동기화
- 외부 API 호출
- 외부 분석 SDK
- 광고 SDK
- 계정/로그인 시스템
- Core ML 모델 추가
- 전체 밤 원본 오디오 파일 저장
- 잠꼬대/말소리 텍스트 변환
- 임상 지표로서의 AHI 계산
- 질병 확정 판단

## 주요 표현 원칙

앱 문구는 수면 중 소리 기반 웰니스 지표로 제한합니다.

사용하는 표현:

- 코골기
- 이갈이 의심 소리
- 호흡정지 의심 구간
- gasp-like 회복 호흡
- 기침 의심 소리
- 환경 소음
- 움직임 의심 소리
- 각성 의심 구간
- 수면 소리 점수

피하는 표현:

- 수면무호흡증 진단
- AHI 정확 측정
- 이갈이 확진
- 질병 판정
- 치료 필요

## 프로젝트 구조

```text
SleepSoundApp
- App
  - SleepSoundApp.swift
  - AppState.swift
  - Formatting.swift

- Features
  - Sleep
    - SleepStartView.swift
    - SleepRecordingView.swift
    - SleepReportView.swift
    - SleepTimelineView.swift
    - MorningCheckInView.swift
  - Dashboard
    - HomeDashboardView.swift
    - TrendChartView.swift
  - Settings
    - PrivacySettingsView.swift
    - DevicePlacementGuideView.swift
    - AudioDebugView.swift

- Core
  - Audio
    - AudioSessionManager.swift
    - AudioCaptureService.swift
    - AudioCaptureServiceProtocol.swift
    - AudioCaptureState.swift
    - AudioRingBuffer.swift
    - AudioChunk.swift
  - Analysis
    - SleepAnalyzer.swift
    - SleepEventDetector.swift
    - DetectorOutput.swift
    - AudioFeatureExtractor.swift
    - AudioFeatures.swift
    - RuleBasedSleepEventDetector.swift
    - DetectionSmoothingPolicy.swift
    - SleepEventAggregator.swift
    - SleepScoreCalculator.swift
  - Models
  - Storage
  - Privacy
  - FutureHealth

Tests
```

## 빌드 방법

Xcode에서 열기:

```bash
open SleepSoundApp.xcodeproj
```

명령줄 Debug iOS generic build:

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

테스트:

```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
xcrun swift test --cache-path .build/swiftpm-cache
```

## 실제 iPhone 테스트 방법

1. Xcode에서 `SleepSoundApp.xcodeproj`를 엽니다.
2. 실제 iPhone을 실행 대상으로 선택합니다.
3. Signing & Capabilities에서 개발 팀을 설정합니다.
4. 앱을 iPhone에 설치하고 실행합니다.
5. “수면 시작”을 누릅니다.
6. 마이크 권한 팝업이 표시되면 허용합니다.
7. 캡처 중 화면에서 상태, 경과 시간, RMS 레벨, 감지 이벤트 수가 갱신되는지 확인합니다.
8. 주변에서 짧은 소리를 내고 이벤트 후보 또는 level 값이 변하는지 확인합니다.
9. “수면 종료”를 누릅니다.
10. 수면 리포트가 생성되고 홈/리포트 화면에서 다시 볼 수 있는지 확인합니다.
11. 앱을 종료 후 재실행해 최근 리포트가 유지되는지 확인합니다.
12. 개인정보 설정에서 로컬 데이터 삭제가 동작하는지 확인합니다.

권한을 거부한 경우 iOS 설정 앱에서 밤숨의 마이크 권한을 다시 허용한 뒤 재시도합니다.

## DEBUG 오디오 화면

DEBUG 빌드에서는 개발자용 오디오 디버그 화면을 통해 다음 값을 확인할 수 있습니다.

- capture state
- current RMS
- current energy
- silence/noise 추정 상태
- latest detector output
- event type
- confidence
- intensity
- debug reason
- 임시 threshold 값

이 화면은 튜닝용이며 App Store용 최종 UI가 아닙니다. 원본 전체 오디오를 파일로 저장하거나 서버로 전송하지 않습니다.

## 개인정보 원칙

- 모든 분석은 iPhone 앱 내부에서 수행하는 방향을 우선합니다.
- V1에서는 서버 업로드가 없습니다.
- V1에서는 클라우드 처리가 없습니다.
- V1에서는 외부 API 호출이 없습니다.
- V1에서는 외부 분석 SDK와 광고 SDK가 없습니다.
- V1에서는 계정 시스템이 없습니다.
- 전체 밤 원본 오디오 파일을 기본 저장하지 않습니다.
- 잠꼬대/말소리 내용을 텍스트로 변환하지 않습니다.
- 저장 대상은 로컬 수면 세션, 이벤트 요약, 리포트, 아침 컨디션 체크인입니다.

## HealthKit 상태

V1에는 HealthKit 실제 연동이 없습니다.

현재 포함된 것은 향후 확장을 위한 모델과 placeholder입니다. 나중에 Apple 건강앱 데이터를 읽는 기능을 별도 작업으로 추가할 수 있지만, 현재 앱은 HealthKit 권한을 요청하지 않고 HealthKit 데이터를 읽거나 쓰지 않습니다.

향후 확장 후보:

- 수축기 혈압
- 이완기 혈압
- 체중
- 체지방률
- BMI
- 제지방량
- 수면 시간
- 심박수
- 호흡수

## 테스트와 QA

상세한 수동 QA 절차는 `QA_CHECKLIST.md`를 확인합니다.

기본 확인 명령:

```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
xcrun swift test --cache-path .build/swiftpm-cache
```

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
