# Daily Rhythm Score

이 문서는 NightBreath / 밤숨의 `오늘의 리듬 점수` 계산 방향과 문구 원칙을 정리합니다. 점수는 웰니스/개인 참고용 요약이며, 건강 상태를 확정하는 목적이 아닙니다.

## 목적

`오늘의 리듬 점수`는 하루 동안 사용할 수 있는 데이터를 한눈에 보기 위한 요약입니다. 수면 소리 리포트, 아침/저녁 컨디션, mock 또는 HealthKit read-only 건강 데이터, 활동 데이터를 하나의 리포트 안에서 살펴볼 수 있게 합니다.

점수의 역할:

- 하루 리듬을 빠르게 돌아보기
- 데이터가 있는 항목과 없는 항목을 분리해서 보여주기
- 수면, 회복 리듬, 활동, 혈압, 체성분 component를 독립적으로 확인하기
- 데이터 품질이 낮은 날에는 점수보다 제한 안내를 우선하기

## Component Score

`DailyRhythmScoreCalculator`는 다음 component를 분리합니다.

- `sleepComponent`: 수면 소리 점수와 오디오 커버리지를 참고합니다.
- `recoveryComponent`: 아침 체크인과 저녁 체크인의 피로도/스트레스/기분 기록을 참고합니다.
- `activityComponent`: mock 또는 read-only 걸음 수와 활동량 데이터를 참고합니다.
- `bloodPressureComponent`: mock 또는 HealthKit read-only 수축기/이완기 혈압 sample 존재 여부와 데이터 품질을 참고합니다.
- `bodyMetricComponent`: mock, HealthKit read-only, Fitdays CSV 로컬 전용 sample 존재 여부와 데이터 품질을 참고합니다.
- `dataCompleteness`: 하루 snapshot에 연결된 수면, 체크인, 건강 데이터의 완성도를 0...1 범위로 저장합니다.

각 component는 0...100 범위로 clamp합니다. 혈압이나 체성분 수치 자체를 평가하지 않고, 리포트에 사용할 수 있는 데이터가 있는지와 품질을 중심으로 다룹니다.

## Data Quality

`DailyDataQuality`는 `dataCompleteness`를 다음 단계로 표현합니다.

- `excellent`
- `good`
- `limited`
- `poor`
- `insufficient`

데이터 품질은 점수 해석보다 먼저 보여줘야 합니다. 데이터가 부족한 날에는 `totalScore`를 과하게 낮추기보다 `limited`, `poor`, `insufficient` 같은 상태로 리포트 범위를 설명합니다.

`DailyRhythmDataReadinessSummary`는 Morning Brief와 Daily Rhythm Report에서 같은 기준으로 다음 항목을 분리합니다.

- 준비된 입력: 수면 리포트, 아침 컨디션, 저녁 기록, 혈압 데이터, 체성분 데이터, 활동/회복 데이터 중 연결된 항목
- 제한 항목: 같은 항목 중 해당 날짜에 없거나 로드되지 않은 항목
- 데이터 품질: `DailyDataQuality` display name
- 완성도: `dataCompleteness` percent

이 상태 블록은 점수보다 먼저 표시되며, “사용 가능한 항목만 참고용으로 표시한다”는 방향을 유지합니다.

## 데이터 부족 시 처리

데이터가 없는 component는 리포트 전체를 실패시키지 않습니다.

- 수면 리포트가 없으면 수면 component는 제한적으로 표시합니다.
- 아침/저녁 체크인이 없으면 회복 리듬 component는 제한적으로 표시합니다.
- 혈압 sample이 없으면 혈압 component는 데이터 없음으로 다룹니다.
- 체성분 sample이 없으면 체성분 component는 데이터 없음으로 다룹니다.
- 오디오 커버리지가 낮으면 수면 component의 신뢰도를 낮춰 반영합니다.
- 비교 가능한 데이터가 부족하면 Daily Insight에서 제한 안내를 먼저 보여줍니다.

## Daily Insight 문구

`DailyInsightGenerator`는 관찰 중심의 문장만 생성합니다.

사용 가능한 방향:

- 어젯밤 코골기 시간이 비교적 길게 기록되었습니다.
- 아침 컨디션은 보통으로 기록되었습니다.
- 오늘 혈압과 체중 데이터가 함께 기록되었습니다.
- 비교 가능한 데이터가 부족해 일부 리포트가 제한됩니다.
- 수면 소리 지표와 건강 데이터를 함께 살펴볼 수 있습니다.

피해야 할 방향:

- 특정 질환명을 확정하는 문장
- 혈압, 체중, 체성분 수치를 질병 여부로 해석하는 문장
- 치료나 의학적 조치를 직접 권하는 문장
- 수면 소리 이벤트가 건강 지표 변화를 만들었다고 단정하는 문장
- 임상 지표처럼 정확도를 보장하는 문장

## 인과관계 금지

앱은 수면 소리와 건강 데이터를 같은 날짜 또는 인접한 날짜에서 함께 보여줄 수 있습니다. 하지만 두 지표 사이의 원인과 결과를 단정하지 않습니다.

허용 방향:

- 코골기 시간이 긴 날과 다음날 혈압 데이터를 함께 보여줍니다.
- 개인 패턴을 살펴보기 위한 참고용 보기입니다.
- 데이터가 충분한 날만 비교 보기에서 사용합니다.

피해야 할 방향:

- 한 지표가 다른 지표를 변화시켰다고 말하는 문장
- 수면 소리 이벤트를 건강 지표 변화의 이유로 설명하는 문장
- 특정 건강 상태를 앱이 판단한다는 문장

## HealthKit Read-only 단계

현재 Daily Rhythm Score는 `HealthDataServiceProtocol` 기반 snapshot을 입력으로 사용하므로 mock data와 `RealHealthKitService` read-only adapter 결과를 같은 계산 경로에서 다룹니다.

- `HealthDataServiceProtocol`로 건강 데이터 접근을 추상화합니다.
- `MockHealthDataService`가 Omron Connect, Fitdays, Apple Health Mock source를 제공합니다.
- `RealHealthKitService`는 HealthKit read-only 권한 요청과 quantity sample query를 담당합니다.
- 권한 요청은 사용자가 건강 데이터 대시보드에서 연결을 선택한 경우에만 수행합니다.
- HealthKit share/write 대상은 비워 두고 read-only로만 사용합니다.
- 실제 HealthKit source data와 권한 허용/거부/일부 허용 흐름은 실제 iPhone manual QA가 필요합니다.
- 건강 데이터는 서버로 전송하지 않습니다.

## 관련 파일

- `SleepSoundApp/Core/DailyRhythm/DailyRhythmScore.swift`
- `SleepSoundApp/Core/DailyRhythm/DailyRhythmScoreCalculator.swift`
- `SleepSoundApp/Core/DailyRhythm/DailyInsightGenerator.swift`
- `SleepSoundApp/Core/DailyRhythm/DailyRhythmReportBuilder.swift`
- `SleepSoundApp/Core/DailyRhythm/DailyHealthSnapshotBuilder.swift`
- `Tests/DailyRhythmScoreCalculatorTests.swift`
- `Tests/DailyInsightGeneratorTests.swift`
- `Tests/DailyRhythmReportBuilderTests.swift`
