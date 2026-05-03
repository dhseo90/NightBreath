# HealthKit Mock Architecture

NightBreath / 밤숨은 V1에서 iPhone 온디바이스 수면 소리 분석에 집중합니다. 이 문서는 Apple 건강앱 연동 전 단계에서 혈압, 체중, 체성분, 수면 관련 UI와 데이터 흐름을 mock data로 검증하기 위한 구조를 설명합니다.

## 현재 범위

- 실제 건강앱 권한 요청을 하지 않습니다.
- 실제 건강앱 데이터를 읽거나 쓰지 않습니다.
- 서버나 네트워크 코드를 추가하지 않습니다.
- 건강 데이터 화면은 mock sample만 사용합니다.
- 화면 문구는 웰니스 참고용으로 유지하며 전문적인 건강 판단을 대신하지 않습니다.

## Core 구조

- `HealthMetricType`: 향후 읽을 metric 목록을 정의합니다.
- `HealthMetricSample`: metric 값, 단위, 측정 시각, 출처 앱 정보를 담습니다.
- `HealthMetricDateRange`: mock fetch filtering에 쓰는 기간 모델입니다.
- `HealthKitServiceProtocol`: 향후 건강앱 read service를 붙이기 위한 protocol입니다.
- `DisabledHealthKitService`: V1에서 권한 요청을 하지 않는 비활성 service입니다.
- `MockHealthKitService`: mock sample을 반환하는 개발용 service입니다.
- `HealthMetricChartDataBuilder`: chart 표시용 point와 최근 변화량을 만듭니다.

## 읽을 예정인 Metric

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

## 다음 단계에서 할 일

실제 건강앱 연동은 별도 작업으로 진행합니다. 그 단계에서만 권한 안내, 권한 요청, 실제 sample query 구현을 검토합니다. 현재 mock architecture에는 실제 권한 요청이나 실제 건강앱 store 생성이 없습니다.
