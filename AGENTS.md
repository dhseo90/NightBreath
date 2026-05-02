# NightBreath / 밤숨 Project Instructions

## Product

This is an iPhone on-device sleep sound analysis app.

Korean app display name:
- 밤숨

English project / brand name:
- NightBreath

App concept:
- On-device sleep sound report app
- Korean subtitle: 수면 소리 리포트
- English subtitle: Sleep Sound Report

The app analyzes sleep-related sounds and produces a wellness-style morning report.

The app must not claim to diagnose diseases.

Use these terms:
- 코골기
- 이갈이 의심 소리
- 호흡정지 의심 구간
- gasp-like 회복 호흡
- 기침 의심 소리
- 환경 소음
- 움직임 의심 소리
- 각성 의심 구간
- 수면 소리 점수

Avoid these terms as definitive claims:
- 수면무호흡증 진단
- AHI 정확 측정
- 이갈이 확진
- 질병 판정
- 치료 필요
- 의료 진단

## Privacy

The app is privacy-first.

Rules:
- No server upload.
- No cloud processing.
- No external API calls in V1.
- No external analytics SDK.
- No advertising SDK.
- No account system in V1.
- Do not store full-night raw audio by default.
- Do not transcribe sleep talk into text.
- Store only local event summaries unless explicitly requested otherwise.
- Raw audio snippets, if implemented later, must be optional and short.

## V1 Scope

Implement:
- SwiftUI app structure
- Sleep start/end flow
- Local sleep session model
- Local sleep event model
- Night report model
- Morning check-in model
- Mock report UI
- Sleep event timeline
- Sleep Sound Score
- Rule-based analysis placeholders
- Audio capture service skeleton
- Future HealthKit module placeholder

Do not implement in V1:
- Actual HealthKit permission request
- Blood pressure graph
- Weight/body composition graph
- Apple Watch integration
- Remote API
- Cloud sync
- Medical diagnosis
- Full ML training pipeline
- AHI calculation as a clinical metric

## Future Health Direction

The app will later read Apple Health data such as:
- systolic blood pressure
- diastolic blood pressure
- body mass
- body fat percentage
- body mass index
- lean body mass
- sleep duration
- heart rate
- respiratory rate

Context:
- The user currently syncs blood pressure data from Omron Connect to Apple Health.
- The user currently syncs weight and body composition data from Fitdays to Apple Health.
- The user wants a better dashboard than the default Health app view.

For now:
- Define future-friendly models and placeholders only.
- Do not request HealthKit permission in V1.
- Do not read or write HealthKit data in V1.

## Architecture

Preferred structure:

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

Keep business logic separate from SwiftUI views.

Use protocols for services when possible.

Make scoring and event aggregation testable.

## Core Models

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

## UI Language

Use Korean UI copy first.

Examples:
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

## Sleep Sound Score

Initial scoring rule:
- Start from 100.
- Subtract points for high snore ratio.
- Subtract points for bruxism-like events.
- Subtract points for suspected breathing pause events.
- Subtract points for gasp-like recovery breathing.
- Subtract points for cough-like events.
- Subtract points for environmental noise events.
- Subtract points for suspected awakening events.
- Subtract points if measurement duration is too short.
- Clamp result between 0 and 100.
- Generate a Korean mainDisturbanceReason.

The score is a wellness-style “수면 소리 점수”.
It is not a medical score.

## Development Rules

Before editing:
1. Read AGENTS.md.
2. Inspect the repository.
3. Identify the current Xcode project structure.
4. Propose a brief implementation plan.
5. Then implement only the requested scope.

After editing:
1. Run a build command if possible.
2. Run tests if possible.
3. Summarize changed files.
4. Summarize remaining issues.

## Safety Rules

Do not add:
- Network calls
- Server integration
- Cloud sync
- External analytics SDK
- Advertising SDK
- Account/login system
- HealthKit permission request unless explicitly requested
- Medical diagnosis copy
- Full-night raw audio storage
