# Architecture README

이 문서는 NightBreath / 밤숨의 코드 구조와 주요 경계를 설명합니다.

## 앱 구조

```text
SleepSoundApp
- App
- Features
  - Sleep
  - DailyRhythm
  - Dashboard
  - Onboarding
  - Settings
- Core
  - Audio
  - Analysis
  - Design
  - DailyRhythm
  - FutureHealth
  - Models
  - Privacy
  - Storage
Tests
Tools
Docs
```

## 설계 원칙

- 비즈니스 로직은 SwiftUI View와 분리합니다.
- 서비스 경계에는 가능한 한 protocol을 둡니다.
- 점수 계산, 이벤트 집계, Daily Rhythm 계산은 테스트 가능해야 합니다.
- HealthKit 실제 연결은 adapter 뒤에 두고 mock service와 교체 가능하게 유지합니다.
- Fitdays import는 로컬 파일/붙여넣기 입력만 처리하며 원격 연결을 만들지 않습니다.
- DEBUG 도구와 Release 사용자 화면의 경계를 분리합니다.

## 핵심 모델

- `SleepSession`
- `SleepEvent`
- `NightReport`
- `MorningCheckIn`
- `UnifiedHealthMetricSample`
- `ImportBatch`
- `DailyRhythmReport`
- `DailyRhythmScore`
- `DailyHealthCardContent`

## 분석 경계

V1은 rule-based detector와 Core ML adapter placeholder를 함께 둡니다. 현재 목표는 임상적 정확도 확정이 아니라 pipeline, diagnostics, replay, regression guard를 갖추는 것입니다.

## 관련 문서

| 문서 | 내용 |
| --- | --- |
| [CORE_ML_MODEL_INTEGRATION](../CORE_ML_MODEL_INTEGRATION.md) | Core ML adapter와 모델 통합 기준 |
| [RULE_BASED_VS_ML_COMPARISON](../RULE_BASED_VS_ML_COMPARISON.md) | rule-based와 ML detector 비교 기준 |
| [MULTICLASS_EVENT_CLASSIFIER](../MULTICLASS_EVENT_CLASSIFIER.md) | multiclass classifier 준비 방향 |
| [SNORE_ML_V0](../SNORE_ML_V0.md) | 코골기 ML v0 준비 문서 |
| [SUSPECTED_BREATHING_PAUSE](../SUSPECTED_BREATHING_PAUSE.md) | 호흡정지 의심 구간 감지 기준 |
| [FEEDBACK_LOOP](../FEEDBACK_LOOP.md) | 사용자 feedback과 향후 개선 loop |
