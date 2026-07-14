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
- HealthKit-backed 지표와 Fitdays local-only 확장 지표를 함께 표현하는 Extended Health Metrics catalog
- 사용자가 직접 선택한 Fitdays CSV/export file의 로컬 import flow
- Daily Rhythm 확장을 위한 제품 문서와 설계 기준

현재 구현하지 않을 것:
- Apple Watch 연동
- 원격 API
- 클라우드 동기화
- 의료 진단
- Fitdays 서버/API 직접 연결
- 비공식 API reverse engineering
- 전체 ML 학습 파이프라인
- 임상 지표로서의 AHI 계산
- HealthKit 데이터 쓰기
- HealthKit에 수면 소리 점수나 오늘의 리듬 점수 쓰기
- 앱 첫 실행 시점의 HealthKit 권한 요청
- 건강 데이터를 서버로 전송하는 기능
- 실제 개인 CSV 파일을 repository에 포함하는 것

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

Extended Health Metrics 방향:
- `UnifiedHealthMetricID`는 HealthKit 표준 지표, Fitdays extended local-only 지표, 앱 계산 지표를 하나의 catalog에서 표현합니다.
- `UnifiedHealthMetricSample`은 값, 단위, 측정 시각, source type, source name, import batch 정보를 함께 보관합니다.
- `HealthMetricSourceType`은 `healthKit`, `fitdaysCSV`, `manual`, `appComputed`, `mock` 출처를 구분합니다.
- `MetricCatalog`는 표시 이름, 단위, category, HealthKit-backed 여부, local-only 여부를 제공합니다.
- HealthKit-backed metric은 Apple 건강앱에서 read-only로 읽은 표준 지표입니다.
- Fitdays extended local-only metric은 HealthKit에 없는 지표이며 HealthKit으로 읽으려 하지 않습니다.
- Fitdays CSV/import 값은 HealthKit 표준 지표가 포함되어 있어도 `sourceType == fitdaysCSV`로 유지합니다.
- Fitdays import는 사용자가 직접 선택한 로컬 CSV/export file만 처리합니다.
- Fitdays 서버/API 연결, 비공식 연결 방식, reverse engineering은 하지 않습니다.
- HealthKit에 custom type을 만들거나 Fitdays import 값을 쓰지 않습니다.
- 실제 개인 CSV 파일은 repository에 포함하지 않습니다.

Fitdays local-only metric 예시:
- 체수분률
- 내장지방 레벨
- 복부지방률
- 골격근량
- 근육량
- 무기질
- 골량
- 기초대사량
- 단백질률
- 피하지방률
- 대사 나이

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
- Core/HealthImport
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

UnifiedHealthMetricSample:
- id
- metricID
  - HealthKit-backed standard metric
  - Fitdays extended local-only metric
  - app-specific computed metric
- value
- unit
- measuredAt
- sourceType
  - healthKit
  - fitdaysCSV
  - manual
  - appComputed
  - mock
- sourceName
- sourceBundleIdentifier
- externalRecordId
- importBatchId
- notes
- createdAt

ImportBatch:
- id
- sourceName
- sourceType
- importedAt
- fileName
- rowCount
- sampleCount
- skippedRowCount
- errorCount
- notes

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

## 5.6 모델 및 추론 추천 기준

로드맵 작성, 후속 작업 제시, 작업 분해, QA 계획 제안 시 권장 모델과 추론 수준을 함께 제시합니다.

출력 형식:
- 추천 모델: 5.6 Terra
- 추론 수준: 높음 (high)
- 선정 근거: 여러 스크립트와 Docker 빌드 경계를 검증하지만 모델 정확도 계약을 변경하지 않는 통합 작업

공식 모델 명칭:
- 5.6 Sol: 최상위 성능이 필요한 flagship 작업
- 5.6 Terra: 지능과 비용의 균형
- 5.6 Luna: 고효율·대량 처리

공식 명칭은 Runa가 아니라 Luna입니다.
문서, 로드맵, 이슈, 커밋 메시지, 작업 제안에서 Runa라고 쓰지 않습니다.

작업 성격 기본값:
- 반복 작업, 대량 점검, 단순 정리, 포맷 변환, 리스트업은 5.6 Luna를 우선 추천합니다.
- 간단한 개발 작업, 작은 버그 수정, 단일 화면/단일 모듈 변경은 5.6 Terra를 우선 추천합니다.
- 기본 작업 중 제품 판단, 안정성 판단, 릴리스 판단, 여러 문서/코드 경계를 함께 보는 작업은 5.6 Sol을 우선 추천합니다.
- 단, 아래 VATester 점수와 상향 규칙이 더 높은 모델을 요구하면 그 기준을 우선합니다.

추론 수준:
- none: 추론이 거의 필요 없는 기계적 변환, 단순 목록화
- low: 반복 확인, 간단한 문구 정리, 낮은 위험의 단일 파일 변경
- medium: 기본 출발점
- high: 품질 향상이 필요한 다중 파일 개발, 원인 분석, 테스트 설계, 릴리스 gate 해석
- xhigh: 아키텍처 변경, 복구/마이그레이션, 복잡한 디버깅, 높은 불확실성의 제품 판단
- max: 가장 어려운 품질 우선 작업에만 사용합니다.

medium을 기본 출발점으로 삼고, high/xhigh는 품질 향상이 필요한 경우에만 사용합니다.
max는 정확도, 동등성, 보안, 데이터 손상 위험이 매우 높고 실패 비용이 큰 작업에만 사용합니다.

VATester 작업 분류 기준:
- 영향도: 0점은 문서/표현 중심, 1점은 일부 사용자 흐름 또는 내부 로직, 2점은 핵심 기능/릴리스/사용자 데이터에 영향
- 불확실성: 0점은 요구와 구현 경계가 명확, 1점은 일부 탐색 필요, 2점은 원인 미상/설계 선택/외부 상태 의존
- 검증 난이도: 0점은 정적 확인 또는 단일 테스트, 1점은 여러 테스트/시나리오, 2점은 실기기/장시간/릴리스 gate 필요
- 변경 범위: 0점은 문서 또는 단일 파일, 1점은 소수 파일/단일 모듈, 2점은 다중 모듈/문서/테스트 동시 변경

VATester 점수별 모델:
- 0~2점: 5.6 Luna
- 3~5점: 5.6 Terra
- 6~8점: 5.6 Sol

상향 규칙:
- 정확도 계약, 동등성 보장, 회귀 방지, 릴리스 gate 판단이 포함되면 최소 5.6 Terra와 high를 권장합니다.
- 개인정보, 보안, 의료 오해 가능성, HealthKit write 금지, 서버/네트워크 금지, 실제 사용자 데이터 노출 가능성이 있으면 최소 5.6 Sol과 high를 권장합니다.
- 데이터 손상, 기록 유실, 마이그레이션, 삭제, 복구, 장시간 실기기 안정성에 영향이 있으면 5.6 Sol과 xhigh를 우선 검토합니다.
- max는 위 상향 규칙 중 둘 이상이 동시에 있고, 실패 시 되돌리기 어렵거나 릴리스 판단을 좌우하는 경우에만 사용합니다.

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
- Fitdays 서버/API 직접 연결
- 비공식 API reverse engineering
- 명시적으로 요청되지 않은 HealthKit 권한 요청
- 앱 첫 실행 시점의 HealthKit 권한 요청
- HealthKit 데이터 쓰기
- HealthKit에 앱 자체 점수 쓰기
- HealthKit custom type 생성
- Fitdays import 값을 HealthKit에 쓰는 기능
- HealthKit 데이터를 서버로 보내는 기능
- 실제 개인 CSV 파일을 repository에 추가하는 것
- 의료 진단 문구
- 밤새 원본 오디오 전체 저장

짧은 오디오 샘플 예외:
- 이벤트 판단 시점 확인을 위한 짧은 로컬 샘플은 사용자가 opt-in 설정을 켠 경우에만 허용합니다.
- 기본 정책은 이벤트 전 2초, 이벤트 후 3초, 샘플 최대 10초, 세션당 최대 100개, 폴더 최대 200MB입니다.
- 기존 저장 샘플은 자동 삭제하지 않고, 사용자가 삭제 버튼으로 지울 수 있어야 합니다.
- 샘플은 `Application Support/NightBreath/EventAudioSnippets/`에 저장할 수 있습니다.
- 샘플 재생과 개별/전체 삭제 기능을 유지해야 합니다.
- sleep talk 내용은 텍스트로 변환하지 않습니다.
