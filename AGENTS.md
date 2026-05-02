# NightBreath / 밤숨 프로젝트 지침

## 제품

이 프로젝트는 iPhone 온디바이스 기반 수면 소리 분석 앱입니다.

한국어 앱 표시 이름:
- 밤숨

영어 프로젝트 / 브랜드 이름:
- NightBreath

앱 콘셉트:
- 온디바이스 수면 소리 리포트 앱
- 한국어 부제: 수면 소리 리포트
- 영어 부제: Sleep Sound Report

앱은 수면과 관련된 소리를 분석해 웰니스 성격의 아침 리포트를 생성합니다.

앱은 질병을 진단한다고 주장하면 안 됩니다.

사용할 표현:
- 코골기
- 이갈이 의심 소리
- 호흡정지 의심 구간
- gasp-like 회복 호흡
- 기침 의심 소리
- 환경 소음
- 움직임 의심 소리
- 각성 의심 구간
- 수면 소리 점수

확정적 주장으로 피해야 할 표현:
- 수면무호흡증 진단
- AHI 정확 측정
- 이갈이 확진
- 질병 판정
- 치료 필요
- 의료 진단

## 개인정보 보호

앱은 개인정보 보호를 최우선으로 설계합니다.

규칙:
- 서버 업로드를 하지 않습니다.
- 클라우드 처리를 하지 않습니다.
- V1에서는 외부 API 호출을 하지 않습니다.
- 외부 분석 SDK를 추가하지 않습니다.
- 광고 SDK를 추가하지 않습니다.
- V1에서는 계정 시스템을 만들지 않습니다.
- 기본 동작으로 밤새 원본 오디오 전체를 저장하지 않습니다.
- 잠꼬대/말소리를 텍스트로 변환하지 않습니다.
- 명시적으로 요청되지 않는 한 로컬 이벤트 요약만 저장합니다.
- 향후 원본 오디오 샘플 저장 기능을 만들더라도 짧은 이벤트 샘플에 한정하고 선택 기능으로만 제공합니다.

## V1 범위

구현할 것:
- SwiftUI 앱 구조
- 수면 시작/종료 흐름
- 로컬 수면 세션 모델
- 로컬 수면 이벤트 모델
- 밤 수면 리포트 모델
- 아침 컨디션 체크인 모델
- mock 리포트 UI
- 수면 이벤트 타임라인
- 수면 소리 점수
- rule-based 분석 placeholder
- 오디오 캡처 서비스 skeleton
- 향후 HealthKit 모듈 placeholder

V1에서 구현하지 않을 것:
- 실제 HealthKit 권한 요청
- 혈압 그래프
- 체중/체성분 그래프
- Apple Watch 연동
- 원격 API
- 클라우드 동기화
- 의료 진단
- 전체 ML 학습 파이프라인
- 임상 지표로서의 AHI 계산

## 향후 건강 데이터 방향

앱은 나중에 Apple 건강앱 데이터를 읽어 종합 건강 대시보드로 확장할 수 있습니다.

향후 읽을 수 있는 데이터 예시:
- 수축기 혈압
- 이완기 혈압
- 체중
- 체지방률
- BMI
- 제지방량
- 수면 시간
- 심박수
- 호흡수

배경:
- 사용자는 현재 Omron Connect의 혈압 데이터를 Apple 건강앱에 동기화하고 있습니다.
- 사용자는 현재 Fitdays의 체중/체성분 데이터를 Apple 건강앱에 동기화하고 있습니다.
- 사용자는 기본 건강앱 화면보다 더 보기 좋은 건강 대시보드를 원합니다.

현재 원칙:
- 확장 가능한 모델과 placeholder만 정의합니다.
- V1에서는 HealthKit 권한을 요청하지 않습니다.
- V1에서는 HealthKit 데이터를 읽거나 쓰지 않습니다.

## 아키텍처

권장 구조:

- App
- Features/Sleep
- Features/Dashboard
- Features/Settings
- Core/Audio
- Core/Analysis
- Core/Models
- Core/Storage
- Core/Privacy
- Core/FutureHealth
- Tests

비즈니스 로직은 SwiftUI View와 분리합니다.

가능하면 service에는 protocol을 사용합니다.

점수 계산과 이벤트 집계는 테스트 가능하게 유지합니다.

## 핵심 모델

SleepSession:
- id
- startedAt
- endedAt
- estimatedSleepStart
- estimatedWakeTime
- measurementDuration
- estimatedSleepDuration
- devicePlacement
- ambientNoiseBaseline
- appVersion
- modelVersion

SleepEvent:
- id
- sessionId
- type
  - snore
  - bruxismLike
  - breathingPauseSuspected
  - gaspLike
  - coughLike
  - sleepTalkLike
  - movementLike
  - environmentalNoise
  - awakeningSuspected
  - unknown
- startedAt
- endedAt
- duration
- confidence
- intensity
- reviewedByUser

NightReport:
- sessionId
- sleepSoundScore
- snoreTotalSeconds
- snoreRatio
- bruxismLikeCount
- suspectedPauseCount
- gaspLikeCount
- coughLikeCount
- sleepTalkLikeCount
- environmentalNoiseCount
- awakeningSuspectedCount
- longestSuspectedPause
- mainDisturbanceReason

MorningCheckIn:
- sessionId
- refreshScore
- fatigueScore
- headache
- dryMouth
- soreThroat
- rememberedAwakenings
- memo

HealthMetricSample:
- id
- metricType
  - systolicBloodPressure
  - diastolicBloodPressure
  - bodyMass
  - bodyFatPercentage
  - bodyMassIndex
  - leanBodyMass
  - restingHeartRate
  - sleepDuration
  - respiratoryRate
- value
- unit
- measuredAt
- sourceName
- sourceBundleIdentifier

## UI 언어

UI 문구는 한국어를 우선 사용합니다.

예시:
- 밤숨
- 수면 시작
- 수면 종료
- 어젯밤 수면 리포트
- 수면 소리 점수
- 코골기 시간
- 이갈이 의심 소리
- 호흡정지 의심 구간
- 기침 의심 소리
- 환경 소음
- 각성 의심 구간
- 아침 컨디션

## 수면 소리 점수

초기 점수 계산 규칙:
- 100점에서 시작합니다.
- 코골기 비율이 높으면 감점합니다.
- 이갈이 의심 이벤트가 있으면 감점합니다.
- 호흡정지 의심 구간 이벤트가 있으면 감점합니다.
- gasp-like 회복 호흡 이벤트가 있으면 감점합니다.
- 기침 의심 이벤트가 있으면 감점합니다.
- 환경 소음 이벤트가 있으면 감점합니다.
- 각성 의심 이벤트가 있으면 감점합니다.
- 측정 시간이 너무 짧으면 감점합니다.
- 결과는 0점 이상 100점 이하로 clamp합니다.
- 한국어 mainDisturbanceReason을 생성합니다.

이 점수는 웰니스 성격의 “수면 소리 점수”입니다.
의료 점수가 아닙니다.

## 개발 규칙

수정 전:
1. AGENTS.md를 읽습니다.
2. repository를 확인합니다.
3. 현재 Xcode 프로젝트 구조를 파악합니다.
4. 간단한 구현 계획을 제안합니다.
5. 요청받은 범위만 구현합니다.

수정 후:
1. 가능하면 빌드 명령을 실행합니다.
2. 가능하면 테스트를 실행합니다.
3. 변경 파일을 요약합니다.
4. 남은 이슈를 요약합니다.

## 안전 규칙

추가하지 말 것:
- 네트워크 호출
- 서버 연동
- 클라우드 동기화
- 외부 분석 SDK
- 광고 SDK
- 계정/로그인 시스템
- 명시적으로 요청되지 않은 HealthKit 권한 요청
- 의료 진단 문구
- 밤새 원본 오디오 전체 저장
