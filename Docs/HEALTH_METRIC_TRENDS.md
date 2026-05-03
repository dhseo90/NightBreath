# Health Metric Trends

NightBreath / 밤숨은 HealthKit read-only sample과 Fitdays CSV import sample을 `UnifiedHealthMetricSample`로 모아 지표별 통계와 그래프를 표시합니다. 이 화면은 개인 참고용 보기이며, 수치에 대한 확정적 해석을 제공하지 않습니다.

## 목적

- HealthKit 표준 지표와 Fitdays extended local-only 지표를 같은 방식으로 탐색합니다.
- 7일, 30일, 90일, 1년 기간을 선택해 그래프와 요약 통계를 확인합니다.
- HealthKit, Fitdays CSV, manual, appComputed, mock source를 구분해 표시합니다.
- 데이터가 없거나 기간 안에 sample이 부족하면 empty state와 제한 안내를 표시합니다.

## 통계 계산 방식

`MetricStatisticsCalculator`는 선택한 `metricID`와 `HealthMetricDateRange`를 기준으로 sample을 필터링합니다.

계산 항목:
- 최근 값
- 평균
- 최소
- 최대
- 이전 같은 길이 기간 평균 대비 변화량
- 측정 횟수
- 첫 측정 시각
- 최근 측정 시각

변화량은 현재 기간 평균에서 이전 기간 평균을 뺀 값입니다. 이전 기간이나 현재 기간 sample이 부족하면 변화량을 표시하지 않습니다.

## 기간 선택

지원 기간:
- 7일
- 30일
- 90일
- 1년

기간은 오늘을 종료 시점으로 하는 rolling window입니다. 예를 들어 30일 선택 시 최근 30일 안의 sample만 그래프와 통계에 포함합니다.

## 그래프

`MetricChartView`는 Swift Charts 기반 line/point chart를 사용합니다. 외부 chart SDK는 사용하지 않습니다.

그래프 원칙:
- 지표별 날짜와 값을 표시합니다.
- source type과 source name을 함께 보여줍니다.
- 여러 source가 섞이면 source별 series로 구분합니다.
- 선택 기간 안에 sample이 없으면 empty state를 표시합니다.

## Source 구분

source type:
- `healthKit`: Apple 건강앱에서 read-only로 읽은 sample
- `fitdaysCSV`: 사용자가 직접 선택한 Fitdays CSV/export file에서 가져온 local sample
- `manual`: 나중에 수동 입력으로 추가될 local sample
- `appComputed`: 밤숨 앱이 계산한 개인 참고용 지표
- `mock`: preview/test용 sample

Fitdays CSV에서 가져온 HealthKit 표준 지표도 `sourceType = fitdaysCSV`로 유지합니다. HealthKit에서 읽은 값처럼 표시하지 않습니다.

## Fitdays Extended Local-Only 지표

HealthKit에 없는 Fitdays 확장 지표는 HealthKit으로 읽으려 하지 않고 local-only sample로 관리합니다.

예시:
- 내장지방 레벨
- 복부지방률
- 체수분
- 골량
- 무기질
- 골격근량
- 근육량
- 기초대사량
- 단백질률
- 피하지방률
- 대사 나이

이 지표들은 Fitdays CSV import, 수동 입력, mock data 같은 로컬 경로로만 표시합니다.

## 데이터 부족 처리

- sample이 없으면 그래프 대신 empty state를 표시합니다.
- 평균, 최소, 최대, 변화량을 계산할 수 없는 경우 `--` 또는 제한 안내를 표시합니다.
- 변화량은 이전 기간과 현재 기간 모두에 sample이 있을 때만 표시합니다.
- 값이 표시되더라도 원인과 결과를 단정하지 않습니다.

## 안전 원칙

- HealthKit read-only 정책을 유지합니다.
- HealthKit에 데이터를 쓰지 않습니다.
- 서버 전송을 하지 않습니다.
- 외부 chart SDK를 추가하지 않습니다.
- 이 앱은 진단 목적의 의료기기가 아닙니다.
- 수치에 대해 확정적 해석이나 행동 지시를 제공하지 않습니다.
