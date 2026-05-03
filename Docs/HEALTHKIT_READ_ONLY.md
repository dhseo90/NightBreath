# Planned HealthKit Read-Only Integration

NightBreath / 밤숨의 건강 데이터 대시보드는 사용자가 Apple 건강앱에 이미 모아 둔 데이터를 더 보기 쉬운 형태로 로컬 표시하는 방향을 가집니다. 이번 Daily Rhythm 방향 전환 단계에서는 실제 HealthKit 권한 요청과 `HKHealthStore` query를 새로 구현하지 않으며, 먼저 mock service/protocol 기반으로 설계합니다.

향후 HealthKit을 연결하더라도 앱은 HealthKit 데이터를 읽기만 하며, HealthKit에 값을 쓰지 않습니다.

## 읽는 데이터 타입

향후 read-only 연동에서 우선 검토할 quantity type은 다음과 같습니다.

- `bloodPressureSystolic`: 수축기 혈압, `mmHg`
- `bloodPressureDiastolic`: 이완기 혈압, `mmHg`
- `bodyMass`: 체중, `kg`
- `bodyFatPercentage`: 체지방률, `%`
- `bodyMassIndex`: BMI
- `leanBodyMass`: 제지방량, `kg`
- `restingHeartRate`: 안정시 심박수, `bpm`
- `respiratoryRate`: 호흡수, `회/분`

`sleepDuration`은 Daily Rhythm 모델과 mock data에는 둘 수 있지만, 실제 HealthKit 수면 데이터는 quantity sample과 구조가 달라 별도 단계에서 다루는 것이 안전합니다.

## 권한 요청 시점

향후 실제 연동을 구현하더라도 권한 요청은 앱 첫 실행이나 수면 측정 시작 시 자동으로 발생하지 않아야 합니다.

1. 사용자가 `건강 데이터` 화면에 들어갑니다.
2. `건강 데이터 연결` 버튼을 누릅니다.
3. 그 시점에만 Apple 건강앱 읽기 권한 요청 sheet를 표시합니다.
4. 허용된 항목만 로컬에서 query해 대시보드에 표시합니다.

사용자가 권한을 거부하거나 항목별 권한을 일부만 허용해도 수면 소리 분석 기능은 계속 사용할 수 있습니다.

## Read-Only 정책

- 향후 실제 adapter는 `requestAuthorization(toShare: Set<HKSampleType>(), read: ...)` 형태로 share 대상을 빈 set으로 전달해야 합니다.
- HealthKit save/delete API를 사용하지 않습니다.
- 밤숨의 수면 소리 점수, 이벤트, 피드백, 리포트는 HealthKit에 쓰지 않습니다.
- HealthKit sample은 화면 표시용으로만 사용하며 서버나 클라우드로 전송하지 않습니다.
- 앱에는 광고 SDK, 외부 분석 SDK, 네트워크 전송 경로를 추가하지 않습니다.

## Source 표시

향후 실제 sample을 읽게 되면 `sourceName`과 `sourceBundleIdentifier`를 데이터 출처 섹션에 표시합니다.

- Omron Connect에서 Apple 건강앱으로 동기화된 혈압 데이터는 Apple 건강앱 source로 나타날 수 있습니다.
- Fitdays에서 Apple 건강앱으로 동기화된 체중/체성분 데이터도 Apple 건강앱 source로 나타날 수 있습니다.
- 밤숨은 Omron/Fitdays 앱에 직접 연결하지 않습니다.

## 데이터 없음 / 권한 없음 상태

다음 경우에는 대시보드가 비어 있거나 mock preview 상태로 남을 수 있습니다.

- 사용자가 HealthKit 읽기 권한을 거부한 경우
- Apple 건강앱에 해당 항목 데이터가 없는 경우
- 항목별 권한이 일부만 허용된 경우
- 기기나 실행 환경에서 HealthKit 데이터를 사용할 수 없는 경우

HealthKit은 항목별 읽기 권한 상태를 앱이 세밀하게 확인하지 못하는 경우가 있습니다. 따라서 빈 결과는 “데이터 없음” 또는 “해당 항목 권한 없음”으로 안전하게 안내합니다.

## Capability

실제 HealthKit 권한 요청을 구현하는 단계에서는 앱 target의 HealthKit capability와 entitlement 구성을 별도 변경으로 검토합니다. 이번 Daily Rhythm 문서화 작업에서는 capability 변경을 새로 추가하지 않습니다.

## 제한사항

- 이 화면은 Apple 건강앱 데이터를 로컬에서 정리해 보여주는 대시보드입니다.
- 혈압, 체중, 체성분, 심박수, 호흡수 값에 대한 전문적인 건강 판단을 대신하지 않습니다.
- 데이터의 정확도와 동기화 시점은 Apple 건강앱 및 원 source 앱의 기록 상태에 따라 달라집니다.
- 실기기에서 권한 sheet, 항목별 허용 상태, Omron/Fitdays source 표시는 별도로 확인해야 합니다.
