# HealthKit Mock Architecture

NightBreath / 밤숨은 iPhone 온디바이스 수면 소리 분석에서 시작해 개인 건강 리듬 리포트 앱으로 확장합니다. 이 문서는 Apple 건강앱 실제 연동 전 단계에서 사용할 mock health 구조와, 향후 read-only 연동 이후에도 preview/test fallback으로 유지할 mock service를 설명합니다.

## 현재 범위

- 이번 방향 전환 단계에서는 실제 HealthKit 권한 요청과 sample query를 새로 구현하지 않습니다.
- mock service는 preview, 테스트, 권한 없음 상태 안내, Daily Rhythm 점수 설계에 사용합니다.
- 향후 실제 구현도 HealthKit에 데이터를 쓰지 않습니다.
- 서버나 네트워크 코드를 추가하지 않습니다.
- 건강 데이터 화면은 먼저 mock/protocol 기반 preview와 empty state를 검증합니다.
- 화면 문구는 웰니스 참고용으로 유지하며 전문적인 건강 판단을 대신하지 않습니다.

## Core 구조

- `HealthMetricType`: 향후 읽을 metric 목록을 정의합니다.
- `HealthMetricSample`: metric 값, 단위, 측정 시각, 출처 앱 정보를 담습니다.
- `HealthMetricDateRange`: mock fetch filtering에 쓰는 기간 모델입니다.
- `HealthKitServiceProtocol`: 향후 건강앱 read service와 mock service를 같은 UI에서 다루기 위한 protocol입니다.
- `DisabledHealthKitService`: HealthKit을 사용할 수 없는 환경에서 권한 요청 없이 empty/unavailable state를 반환하는 service입니다.
- `HealthKitService`: 후속 단계에서 Apple 건강앱 read-only 권한 요청과 quantity sample query를 담당할 수 있는 adapter 경계입니다.
- `MockHealthKitService`: mock sample을 반환하는 개발용 service입니다.
- `HealthMetricChartDataBuilder`: chart 표시용 point와 최근 변화량을 만듭니다.

## Metric 범위

- `systolicBloodPressure`
- `diastolicBloodPressure`
- `bodyMass`
- `bodyFatPercentage`
- `bodyMassIndex`
- `leanBodyMass`
- `restingHeartRate`
- `sleepDuration`
- `respiratoryRate`

## Mock Data Source

현재 mock data는 다음 흐름을 가정합니다.

- Omron Connect: Apple 건강앱으로 동기화될 혈압 mock sample
- Fitdays: Apple 건강앱으로 동기화될 체중, 체지방률, BMI, 제지방량 mock sample
- Apple Health Mock: 안정시 심박수, 수면 시간, 호흡수 mock sample

실제 Omron/Fitdays 앱에서 직접 데이터를 가져오는 구조가 아닙니다. 장기적으로는 사용자가 Apple 건강앱에 동기화한 데이터를 읽는 방향만 가정합니다.

## UI 구조

`HealthDashboardView`는 mock service의 sample을 사용해 다음 섹션을 표시합니다.

- 혈압
- 체중
- 체지방률
- BMI
- 최근 변화
- 데이터 출처

`HealthMetricChartView`는 Swift Charts를 사용합니다. 외부 SDK는 추가하지 않습니다.

## 향후 Read-Only 연동

향후 read-only 연동 세부 정책은 `Docs/HEALTHKIT_READ_ONLY.md`를 참고합니다. Mock 구조는 계속 유지하며, 권한 거부/데이터 없음/Simulator preview 상태에서도 화면이 깨지지 않도록 사용합니다.
