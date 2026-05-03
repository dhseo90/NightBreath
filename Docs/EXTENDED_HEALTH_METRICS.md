# Extended Health Metrics

NightBreath / 밤숨은 Apple 건강앱에서 read-only로 읽는 표준 지표와, HealthKit에 없는 Fitdays 확장 체성분 지표를 하나의 metric catalog에서 구분해 다룹니다.

이 문서는 데이터 표현 범위를 정리하기 위한 설계 문서입니다. Fitdays 서버나 비공식 API에 연결하지 않으며, HealthKit에 custom type을 만들거나 데이터를 쓰지 않습니다.

## 목적

- HealthKit 표준 지표와 로컬 확장 지표를 같은 화면 모델에서 표현합니다.
- HealthKit에서 읽은 값, Fitdays CSV import 값, 수동 입력 값, 앱 계산값, mock data의 출처를 구분합니다.
- HealthKit에 없는 지표는 HealthKit query 대상에 넣지 않고 로컬 import/manual/app-computed sample로만 관리합니다.
- 모든 값은 개인 참고용 보기이며, 이 앱은 진단 목적의 의료기기가 아닙니다.

## Core Types

- `UnifiedHealthMetricID`: HealthKit 표준 지표, Fitdays 확장 지표, 앱 계산 지표를 모두 표현하는 통합 ID입니다.
- `HealthMetricSourceType`: `healthKit`, `fitdaysCSV`, `manual`, `appComputed`, `mock` 출처를 구분합니다.
- `UnifiedHealthMetricSample`: metric ID, 값, 단위, 측정 시각, 출처, import batch, 외부 record ID를 함께 저장할 수 있는 sample 모델입니다.
- `MetricDisplayMetadata`: 한국어/영어 표시 이름, 단위, category, HealthKit-backed 여부, local-only 여부를 담습니다.
- `MetricCatalog`: 전체 metric 목록, category별 목록, metadata lookup, HealthKit-backed/local-only 분류를 제공합니다.

## HealthKit-Backed Metrics

현재 `RealHealthKitService`가 read-only quantity sample로 읽는 지표입니다.

- `systolicBloodPressure`: 수축기 혈압, `mmHg`
- `diastolicBloodPressure`: 이완기 혈압, `mmHg`
- `bodyMass`: 체중, `kg`
- `bodyFatPercentage`: 체지방률, `%`
- `bodyMassIndex`: BMI
- `leanBodyMass`: 제지방량, `kg`
- `stepCount`: 걸음 수, `걸음`
- `activeEnergy`: 활동량, `kcal`
- `heartRate`: 심박수, `bpm`
- `restingHeartRate`: 안정시 심박수, `bpm`
- `respiratoryRate`: 호흡수, `회/분`

`sleepDuration`은 통합 catalog에 포함되지만, 현재 실제 HealthKit read adapter에서는 quantity sample로 읽지 않습니다. Daily Rhythm mock data나 향후 별도 sleep data 처리 단계에서 다룹니다.

## Fitdays Extended Local-Only Metrics

다음 항목은 HealthKit 표준 read adapter로 읽지 않습니다. 나중에 CSV import 또는 사용자가 직접 입력한 로컬 데이터로만 다룹니다.

- `visceralFatLevel`: 내장지방 레벨
- `visceralFatPercentage`: 복부지방률
- `bodyWaterPercentage`: 체수분
- `boneMass`: 골량
- `mineralMass`: 무기질
- `skeletalMuscleMass`: 골격근량
- `muscleMass`: 근육량
- `basalMetabolicRate`: 기초대사량
- `proteinPercentage`: 단백질률
- `subcutaneousFatPercentage`: 피하지방률
- `metabolicAge`: 대사 나이
- `bodyScore`: Fitdays 바디 점수
- `obesityLevel`: Fitdays 체형 레벨

이 값들은 원본 앱이나 사용자가 제공한 기록을 보기 쉽게 정리하기 위한 항목입니다. 앱은 값을 해석해 상태를 단정하지 않습니다.

## App-Specific Metrics

다음 항목은 HealthKit에 쓰지 않고 앱 내부 계산값으로만 다룹니다.

- `sleepSoundScore`: 수면 소리 점수
- `dailyRhythmScore`: 오늘의 리듬 점수
- `audioCoverageRatio`: 오디오 측정 커버리지

이 지표들은 Daily Rhythm 리포트와 카드에서 개인 참고용으로 사용할 수 있습니다. HealthKit에 저장하거나 외부로 전송하지 않습니다.

## Source Policy

`UnifiedHealthMetricSample.sourceType`은 값의 출처를 명확히 구분합니다.

- `healthKit`: Apple 건강앱에서 read-only로 읽은 값
- `fitdaysCSV`: 사용자가 가져온 Fitdays CSV/import 값
- `manual`: 사용자가 직접 입력한 값
- `appComputed`: 밤숨 앱이 로컬에서 계산한 값
- `mock`: preview, simulator, test용 mock 값

Omron Connect와 Fitdays가 Apple 건강앱에 동기화한 표준 지표는 HealthKit sample source로 표시될 수 있습니다. HealthKit에 없는 Fitdays 확장 지표는 Apple 건강앱에서 읽으려 하지 않습니다.

## Privacy And Safety

- HealthKit write는 구현하지 않습니다.
- HealthKit custom type을 만들지 않습니다.
- Fitdays 서버/API 연동을 하지 않습니다.
- 비공식 API reverse engineering을 하지 않습니다.
- 서버, 클라우드, 외부 SDK로 건강 데이터를 보내지 않습니다.
- 수면 소리 점수나 오늘의 리듬 점수도 HealthKit에 쓰지 않습니다.
- 지표 간 인과관계를 주장하지 않습니다.
- 모든 리포트는 개인 패턴을 살펴보기 위한 참고용 보기입니다.
