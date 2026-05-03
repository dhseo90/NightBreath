# Metric Detail View

NightBreath / 밤숨의 `MetricDetailView`는 하나의 health metric을 선택해 기간별 흐름, 통계, raw sample 목록, 데이터 출처를 자세히 보는 화면입니다. 이 화면은 개인 참고용 데이터 탐색 화면이며 수치에 대한 확정적 해석을 제공하지 않습니다.

## 목적

- 특정 `UnifiedHealthMetricID` 하나만 집중해서 봅니다.
- HealthKit 표준 지표와 Fitdays extended local-only 지표를 같은 화면 구조로 표시합니다.
- 기간 선택과 source filter를 함께 제공해 원하는 기록만 좁혀 봅니다.
- chart, 요약 통계, raw sample list를 한 화면에서 확인합니다.

## 입력

기본 입력:
- `metricID`
- `samples`

호환 입력:
- `MetricDisplayMetadata`
- `samples`
- 기존 overview 화면에서 선택한 `HealthMetricTrendPeriod`

화면 내부에서는 `MetricDetailViewModel`이 `metricID`, 기간, source filter를 기준으로 sample을 다시 계산합니다.

## 기간 선택

지원 기간:
- 7일
- 30일
- 90일
- 1년
- 전체

`전체`는 선택한 metric과 source filter에 해당하는 sample의 첫 측정일부터 최근 측정일 또는 현재 시점까지를 포함합니다.

## Source Filter

지원 source:
- 전체
- HealthKit
- Fitdays CSV
- Manual
- App Computed
- Mock, DEBUG 빌드에서만 UI 노출

source filter는 raw sample list, chart, 통계, source breakdown에 모두 적용됩니다.

## 표시 항목

상단:
- metric 표시 이름
- 설명
- 최근 값
- 최근 측정 시각
- 데이터 출처
- unit
- HealthKit read-only 또는 local-only badge

요약 통계:
- 최신값
- 평균
- 최소
- 최대
- 최근 변화
- 측정 횟수
- 첫 측정 시각
- 최근 측정 시각

그래프:
- Swift Charts 기반 line/point chart
- source type과 source name별 series 구분
- 외부 chart SDK 없음

기록 목록:
- 측정 시간
- value + unit
- sourceName
- sourceType
- importBatchId, 있으면
- notes, 있으면

## HealthKit-Backed Metric

HealthKit-backed metric은 Apple 건강앱에서 read-only로 읽은 데이터입니다.

원칙:
- 앱은 HealthKit에 데이터를 쓰지 않습니다.
- HealthKit에 앱 전용 건강 타입을 만들지 않습니다.
- sourceName과 측정 시각을 함께 표시합니다.
- 권한이 없거나 sample이 없으면 empty state를 표시합니다.

예:
- 수축기 혈압
- 이완기 혈압
- 체중
- 체지방률
- BMI
- 제지방량
- 걸음 수
- 활동 에너지
- 심박수
- 안정시 심박수

## Fitdays Extended Local-Only Metric

Fitdays extended metric은 HealthKit 표준 지표가 아니며, Fitdays CSV import 또는 수동 입력으로 저장된 local-only 지표입니다.

예:
- 체수분률
- 복부지방률
- 내장지방 레벨
- 골격근량
- 무기질
- 골량
- 기초대사량
- 단백질률

이 값들은 Fitdays 원격 서비스에 연결해서 가져오지 않습니다. 사용자가 직접 선택한 파일 또는 로컬 입력 구조를 통해서만 표시합니다.

## Empty State

상태:
- 해당 metric sample 없음
- 선택한 기간에 sample 없음
- 선택한 source에 sample 없음
- HealthKit 권한 없음, 필요한 화면에서 안내

empty state는 기간이나 source filter를 바꿔볼 수 있도록 안내합니다.

## 안전 원칙

- 개인 참고용 데이터 탐색 화면입니다.
- 수치의 원인과 결과를 단정하지 않습니다.
- 확정적 상태 해석을 제공하지 않습니다.
- HealthKit read-only 정책을 유지합니다.
- HealthKit write를 하지 않습니다.
- 서버 전송을 하지 않습니다.
- 외부 SDK를 추가하지 않습니다.
