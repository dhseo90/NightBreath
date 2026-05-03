# NightBreath / 밤숨 프로젝트 지침

## 제품

이 프로젝트는 iPhone 온디바이스 기반 수면 소리 분석에서 시작해, 온디바이스 개인 건강 리듬 리포트 앱으로 확장되는 제품입니다.

한국어 앱 표시 이름:
- 밤숨

영어 프로젝트 / 브랜드 이름:
- NightBreath

앱 콘셉트:
- 온디바이스 수면 소리 리포트 앱
- 온디바이스 개인 건강 리듬 리포트 앱
- 수면 소리 리포트에서 시작해 Daily Rhythm Report로 확장
- 한국어 부제: 수면 소리 리포트
- 영어 부제: Sleep Sound Report

앱은 수면과 관련된 소리를 분석해 웰니스 성격의 아침 리포트를 생성합니다.
향후에는 수면, 혈압, 체중, 체성분, 활동, 아침/저녁 컨디션을 한곳에서 살펴보는 하루 리듬 리포트로 확장합니다.

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
- 오늘의 리듬 점수
- 회복 리듬
- 아침 리포트
- 하루 리듬 카드
- 개인 패턴을 살펴보기 위한 참고용 보기

확정적 주장으로 피해야 할 표현:
- 수면무호흡증 진단
- AHI 정확 측정
- 이갈이 확진
- 질병 판정
- 치료 필요
- 의료 진단
- 건강 데이터에 대한 진단, 질병 판정, 치료 권고
- 건강 진단 점수
- 수면 소리와 건강 지표 사이의 확정적 인과관계 주장

## 개인정보 보호

앱은 개인정보 보호를 최우선으로 설계합니다.

규칙:
- 서버 업로드를 하지 않습니다.
- 클라우드 처리를 하지 않습니다.
- 외부 API 호출을 하지 않습니다.
- 외부 분석 SDK를 추가하지 않습니다.
- 광고 SDK를 추가하지 않습니다.
- 계정 시스템을 만들지 않습니다.
- 기본 동작으로 밤새 원본 오디오 전체를 저장하지 않습니다.
- 잠꼬대/말소리를 텍스트로 변환하지 않습니다.
- 명시적으로 요청되지 않는 한 로컬 이벤트 요약만 저장합니다.
- 짧은 이벤트 전후 오디오 샘플 저장은 사용자 opt-in 설정이 켜진 경우에만 로컬에 저장할 수 있으며, 기본값은 꺼짐입니다.
- 이벤트 오디오 샘플은 전체 밤 오디오가 아니어야 하며, 저장 시간/개수/용량 제한과 삭제 기능을 가져야 합니다.

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
- HealthKit read-only 건강 데이터 dashboard 연결
- MockHealthDataService와 RealHealthKitService의 protocol 기반 교체 구조
- Daily Rhythm 확장을 위한 제품 문서와 설계 기준

현재 구현하지 않을 것:
- Apple Watch 연동
- 원격 API
- 클라우드 동기화
- 의료 진단
- 전체 ML 학습 파이프라인
- 임상 지표로서의 AHI 계산
- HealthKit 데이터 쓰기
- HealthKit에 수면 소리 점수나 오늘의 리듬 점수 쓰기
- 앱 첫 실행 시점의 HealthKit 권한 요청
- 건강 데이터를 서버로 전송하는 기능

## 향후 건강 데이터 방향

앱은 Apple 건강앱 데이터를 read-only로 읽어 종합 건강 대시보드로 확장합니다.
이 확장은 수면 앱을 대체하는 것이 아니라, NightBreath를 온디바이스 개인 건강 리듬 리포트 앱으로 넓히는 방향입니다.

Daily Rhythm Report 방향:
- 앱은 수면 앱에만 한정되지 않고 하루 리듬 리포트로 확장됩니다.
- 아침 리포트는 지난밤 수면 소리와 아침 컨디션을 보여주는 시작점입니다.
- 하루 리듬 카드는 수면, 혈압, 체중, 체성분, 활동, 컨디션 중 사용 가능한 데이터를 요약합니다.
- 건강 대시보드는 더 자세한 날짜별 지표와 source, 데이터 품질을 보여줍니다.
- “오늘의 리듬 점수”는 웰니스/개인 참고용 점수이며 의료 점수가 아닙니다.
- 수면 소리와 건강 지표가 같은 날 함께 보이더라도 인과관계를 주장하지 않습니다.

read-only로 읽을 수 있는 데이터 예시:
- 수축기 혈압
- 이완기 혈압
- 체중
- 체지방률
- BMI
- 제지방량
- 걸음 수
- 활동량
- 수면 시간
- 심박수
- 안정시 심박수
- 호흡수

배경:
- 사용자는 현재 Omron Connect의 혈압 데이터를 Apple 건강앱에 동기화하고 있습니다.
- 사용자는 현재 Fitdays의 체중/체성분 데이터를 Apple 건강앱에 동기화하고 있습니다.
- 사용자는 기본 건강앱 화면보다 더 보기 좋은 건강 대시보드를 원합니다.

현재 원칙:
- HealthKit은 read-only로만 사용합니다.
- HealthKit 실제 연결은 RealHealthKitService 뒤에 두고, 테스트와 preview는 mock service/protocol 기반으로 유지합니다.
- 권한 요청은 사용자가 건강 데이터 대시보드에서 연결 버튼을 눌렀을 때만 수행합니다.
- 앱은 HealthKit에 데이터를 쓰지 않습니다.
- 서버나 외부 앱에 건강 데이터를 전송하지 않습니다.
- 건강 데이터에 대해 진단, 질병 판정, 치료 권고를 하지 않습니다.

## 아키텍처

권장 구조:

- App
- Features/Sleep
- Features/DailyRhythm
- Features/Dashboard
- Features/Onboarding
- Features/Settings
- Core/Audio
- Core/Analysis
- Core/Models
- Core/Storage
- Core/Privacy
- Core/FutureHealth
- Core/DailyRhythm
- Tests

비즈니스 로직은 SwiftUI View와 분리합니다.

가능하면 service에는 protocol을 사용합니다.

점수 계산과 이벤트 집계는 테스트 가능하게 유지합니다.

Daily Rhythm 점수와 건강 지표 집계도 SwiftUI View와 분리하고, mock data로 테스트 가능하게 유지합니다.

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
- audioSnippetFileName
- audioSnippetDuration

NightReport:
- sessionId
- measurementDuration
- estimatedSleepDuration
- detectedEventDuration
- savedAudioDuration
- receivedAudioDuration
- analyzedAudioDuration
- audioCoverageRatio
- interruptionCount
- longestAudioGapSeconds
- measurementQuality
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
  - stepCount
  - activeEnergy
  - heartRate
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

## 오늘의 리듬 점수

향후 Daily Rhythm 확장에서 사용할 “오늘의 리듬 점수”는 웰니스/개인 참고용 점수입니다.

원칙:
- 수면 소리 점수, 측정 품질, 컨디션 기록, 활동, 향후 read-only 건강 데이터의 존재 여부와 품질을 참고할 수 있습니다.
- 건강 상태를 확정하거나 질병 가능성을 예측하지 않습니다.
- 치료나 의학적 조치를 권하지 않습니다.
- 수면 소리 이벤트와 혈압/체중/체성분 변화 사이의 원인과 결과를 단정하지 않습니다.
- 데이터가 부족하거나 권한이 제한된 항목은 점수와 카드에서 제한적으로 표시합니다.

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
- 앱 첫 실행 시점의 HealthKit 권한 요청
- HealthKit 데이터 쓰기
- HealthKit에 앱 자체 점수 쓰기
- HealthKit 데이터를 서버로 보내는 기능
- 의료 진단 문구
- 밤새 원본 오디오 전체 저장

짧은 오디오 샘플 예외:
- 이벤트 판단 시점 확인을 위한 짧은 로컬 샘플은 사용자가 opt-in 설정을 켠 경우에만 허용합니다.
- 기본 정책은 이벤트 전 2초, 이벤트 후 3초, 샘플 최대 10초, 세션당 최대 100개, 폴더 최대 200MB입니다.
- 기존 저장 샘플은 자동 삭제하지 않고, 사용자가 삭제 버튼으로 지울 수 있어야 합니다.
- 샘플은 `Application Support/NightBreath/EventAudioSnippets/`에 저장할 수 있습니다.
- 샘플 재생과 개별/전체 삭제 기능을 유지해야 합니다.
- sleep talk 내용은 텍스트로 변환하지 않습니다.
