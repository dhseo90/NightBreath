# Health Data Dashboard

NightBreath / 밤숨의 건강 데이터 대시보드는 Daily Rhythm 확장의 상세 보기입니다. 현재 방향은 mock/protocol 기반 preview와 Apple 건강앱 read-only 연결을 함께 지원하며, 혈압, 체중, 체성분, 활동, 심박수 sample을 보기 쉽게 정리하는 것입니다.

## 구조

`HealthDashboardView`는 건강 데이터 연결 상태와 주요 진입점을 보여주는 허브입니다.

- `BloodPressureDashboardView`: 혈압 전용 화면
- `BodyCompositionDashboardView`: 체중/체성분 전용 화면
- `HealthMetricTrendCalculator`: 7일/30일/90일 추세 계산
- `HealthPeriodOverviewSection`: 7일/30일/90일 sample 수와 평균 변화 요약
- `HealthLatestSampleDetailSection`: metric별 최근 측정값, 측정 시각, source 표시
- `HealthSourceSummarySection`: sourceName/sourceBundleIdentifier 표시

## 혈압 Dashboard

혈압 화면은 다음을 표시합니다.

- 최근 혈압 pair
- 최근 수축기 혈압
- 최근 이완기 혈압
- 최근 측정 시각과 sourceName
- 선택한 7일/30일/90일 그래프
- 7일/30일/90일 기간별 sample 수와 평균 변화
- 아침/저녁 측정 sample 수
- sourceName과 sourceBundleIdentifier
- Daily Rhythm 참고 데이터 안내

Omron Connect에서 Apple 건강앱으로 동기화된 혈압 데이터는 HealthKit sample source로 표시될 수 있습니다. 밤숨은 Omron Connect 앱에 직접 연결하지 않습니다.

## 체중/체성분 Dashboard

체중/체성분 화면은 다음을 표시합니다.

- 체중
- 체지방률
- BMI
- 제지방량
- 최근 측정 시각과 sourceName
- 선택한 7일/30일/90일 그래프
- 7일/30일/90일 기간별 체중 sample 수와 평균 변화
- metric별 평균/최신/min/max/이전 기간 대비 변화
- sourceName과 sourceBundleIdentifier
- Daily Rhythm 참고 데이터 안내

Fitdays에서 Apple 건강앱으로 동기화된 체중/체성분 데이터는 HealthKit sample source로 표시될 수 있습니다. 밤숨은 Fitdays 앱에 직접 연결하지 않습니다.

## Trend 계산

`HealthMetricTrendCalculator`는 선택한 기간에 대해 다음 값을 계산합니다.

- `average`
- `latest`
- `min`
- `max`
- `changeFromPreviousPeriod`
- `sampleCount`

`changeFromPreviousPeriod`는 선택한 기간의 평균과 바로 이전 같은 길이 기간의 평균 차이입니다. 이전 기간 sample이 부족하면 표시하지 않습니다.

대시보드는 같은 calculator를 사용해 다중 metric summary, 7일/30일/90일 period summary, 기간별 source grouping을 만듭니다. 모든 값은 개인 참고용 보기이며, 수치에 대한 확정적 건강 상태 표현을 붙이지 않습니다.

## Daily Rhythm 연결

혈압 및 체성분 dashboard는 Daily Rhythm 확장의 상세 보기입니다. 아침 리포트, 오늘의 리듬 점수, 하루 리듬 카드에서 허용된 건강 sample을 함께 정리할 수 있지만, 수면 소리 지표와 건강 지표 사이의 원인과 결과를 의미하지 않습니다.

## 데이터 없음 / 권한 없음

데이터가 없으면 다음처럼 안내합니다.

- “Apple 건강앱에 해당 데이터가 없습니다.”
- “Omron Connect 또는 Fitdays 연동 상태를 확인하세요.”

특정 앱 설치를 강제하지 않습니다. 사용자가 Apple 건강앱에 저장한 source만 읽습니다.

HealthKit 권한이 없으면 “건강 데이터 읽기 권한이 필요합니다.”로 안내하고, 권한은 iOS 설정 또는 Apple 건강앱에서 관리할 수 있다고 설명합니다.

## Read-Only 방향

- HealthKit 권한 요청은 건강 데이터 연결 버튼을 누를 때만 발생해야 합니다.
- adapter는 read type만 요청하고 share type은 빈 set으로 유지합니다.
- HealthKit save/delete API를 사용하지 않습니다.
- 밤숨의 수면 소리 점수, 이벤트, 리포트, 피드백은 HealthKit에 쓰지 않습니다.
- 서버/클라우드 전송은 없습니다.
- 외부 분석 SDK나 광고 SDK를 추가하지 않습니다.

## 표현 제한

이 대시보드는 Apple 건강앱 sample을 정리해 보여주는 화면입니다.

- 혈압 수치에 대해 확정적 건강 해석을 하지 않습니다.
- 체성분 수치에 대해 확정적 상태 해석을 하지 않습니다.
- 특정 조치가 필요하다고 말하지 않습니다.
- 전문적인 건강 판단을 대신하지 않습니다.
