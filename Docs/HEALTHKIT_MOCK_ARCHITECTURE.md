# HealthKit Mock Architecture

NightBreath / 밤숨은 iPhone 온디바이스 수면 소리 분석에서 시작해 개인 건강 리듬 리포트 앱으로 확장합니다. 이 문서는 HealthKit read-only adapter와 함께 preview/test fallback으로 유지할 mock health 구조를 설명합니다.

## 현재 범위

- mock service는 preview, 테스트, 권한 없음 상태 안내, Daily Rhythm 점수 설계에 사용합니다.
- 실제 HealthKit 구현은 read-only이며 HealthKit에 데이터를 쓰지 않습니다.
- 서버나 네트워크 코드를 추가하지 않습니다.
- 건강 데이터 화면은 mock/protocol 기반 preview와 실제 read-only 연결 상태를 함께 지원합니다.
- HealthKit mock은 Apple 건강앱에 들어오는 표준 지표 preview를 뜻합니다.
- Fitdays CSV import mock은 HealthKit에 없는 extended local-only 지표 preview를 뜻하며 HealthKit mock과 구분합니다.
- 화면 문구는 웰니스 참고용으로 유지하며 전문적인 건강 판단을 대신하지 않습니다.

## Core 구조

- `HealthMetricType`: 향후 읽을 metric 목록을 정의합니다.
- `HealthMetricSample`: metric 값, 단위, 측정 시각, 출처 앱 정보를 담습니다.
- `HealthMetricDateRange`: mock fetch filtering에 쓰는 기간 모델입니다.
- `HealthKitServiceProtocol`: 향후 건강앱 read service와 mock service를 같은 UI에서 다루기 위한 protocol입니다.
- `DisabledHealthKitService`: HealthKit을 사용할 수 없는 환경에서 권한 요청 없이 empty/unavailable state를 반환하는 service입니다.
- `RealHealthKitService`: Apple 건강앱 read-only 권한 요청과 quantity sample query를 담당하는 adapter입니다.
- `HealthKitService`: 기존 호출부 호환을 위한 `RealHealthKitService` typealias입니다.
- `MockHealthKitService`: mock sample을 반환하는 개발용 service입니다.
- `HealthMetricChartDataBuilder`: chart 표시용 point와 최근 변화량을 만듭니다.
- `UnifiedHealthMetricID`: HealthKit 표준 지표, Fitdays extended local-only 지표, 앱 계산 지표를 함께 표현하는 catalog ID입니다.
- `UnifiedHealthMetricSample`: HealthKit read-only sample, Fitdays CSV import sample, manual/appComputed/mock sample을 같은 UI 모델로 다룹니다.
- `HealthMetricSourceType`: `healthKit`, `fitdaysCSV`, `manual`, `appComputed`, `mock` 출처를 구분합니다.
- `MetricCatalog`: metric 표시 이름, 단위, category, HealthKit-backed 여부, local-only 여부를 제공합니다.
- `FitdaysImportService`: 사용자가 직접 선택한 local CSV/export file을 parsing해 `UnifiedHealthMetricSample`과 `ImportBatch`로 변환합니다.
- `ImportBatch`: import source, file name, row/sample count, skipped/error count를 묶어 관리합니다.

## Metric 범위

- `systolicBloodPressure`
- `diastolicBloodPressure`
- `bodyMass`
- `bodyFatPercentage`
- `bodyMassIndex`
- `leanBodyMass`
- `stepCount`
- `activeEnergy`
- `heartRate`
- `restingHeartRate`
- `sleepDuration`
- `respiratoryRate`

## Mock Data Source

HealthKit mock data는 다음 흐름을 가정합니다.

- Omron Connect: Apple 건강앱으로 동기화될 혈압 mock sample
- Fitdays: Apple 건강앱으로 동기화될 체중, 체지방률, BMI, 제지방량 mock sample
- Apple Health Mock: 안정시 심박수, 수면 시간, 호흡수 mock sample

이 mock은 실제 Omron/Fitdays 앱에서 직접 데이터를 가져오는 구조가 아닙니다. Apple 건강앱에 동기화된 표준 지표를 read-only로 읽는 화면 상태를 preview하기 위한 데이터입니다.

Fitdays CSV import mock은 별도 흐름입니다.

- HealthKit에 없는 Fitdays extended local-only metric을 preview합니다.
- 예: 체수분률, 내장지방 레벨, 복부지방률, 골격근량, 근육량, 무기질, 골량, 기초대사량, 단백질률, 피하지방률, 대사 나이
- 사용자가 직접 선택한 CSV/export file을 로컬에서 parsing하는 흐름만 가정합니다.
- HealthKit custom type, Fitdays 서버/API 연결, 비공식 연결 방식, 자동 동기화를 의미하지 않습니다.
- HealthKit 표준 지표가 CSV에 포함되어 있어도 sourceType은 `fitdaysCSV`로 유지합니다.

## UI 구조

`HealthDashboardView`는 mock service와 read-only adapter, import repository의 sample을 같은 화면 흐름에서 다룰 수 있게 구성합니다.

- 혈압
- 체중
- 체지방률
- BMI
- 최근 변화
- 데이터 출처
- 전체 건강 지표
- 월 건강 캘린더
- Fitdays CSV 가져오기
- Metric Detail

`HealthMetricChartView`는 Swift Charts를 사용합니다. 외부 SDK는 추가하지 않습니다.

## 향후 Read-Only 연동

향후 read-only 연동 세부 정책은 `Docs/HEALTHKIT_READ_ONLY.md`를 참고합니다. Mock 구조는 계속 유지하며, 권한 거부/데이터 없음/Simulator preview 상태에서도 화면이 깨지지 않도록 사용합니다.

## 구분 원칙

- HealthKit mock은 Apple 건강앱 read-only 표준 지표를 미리 보기 위한 preview/test fallback입니다.
- Fitdays CSV import mock은 사용자가 직접 가져온 local-only 확장 지표를 미리 보기 위한 preview/test fixture입니다.
- Fitdays extended local-only metric은 HealthKit mock service가 읽는 항목이 아닙니다.
- HealthKit mock service가 Fitdays 서버 연결, HealthKit custom type, HealthKit write를 의미하지 않습니다.
- 두 흐름 모두 서버 전송 없이 로컬에서만 계산하고 표시합니다.
