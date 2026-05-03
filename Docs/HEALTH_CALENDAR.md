# Health Calendar

NightBreath / 밤숨의 건강 캘린더는 월 단위로 수면 리포트, 체크인, HealthKit read-only sample, Fitdays CSV sample, 앱 계산 지표를 날짜별로 모아 보여주는 화면입니다. 모든 표시는 개인 참고용이며, 서로 다른 지표 사이의 원인과 결과를 단정하지 않습니다.

## 목적

- 한 달 안에서 데이터가 있는 날짜를 빠르게 찾습니다.
- 날짜를 선택하면 그날 기록된 수면, 컨디션, 건강 sample, 앱 계산 지표를 category별로 확인합니다.
- HealthKit, Fitdays CSV, manual, appComputed, mock source를 구분합니다.
- Daily Rhythm Report에서 쓰는 날짜별 기초 데이터를 확인할 수 있는 상세 보기로 사용합니다.

## 월 캘린더 표시 방식

`HealthCalendarView`는 선택한 월을 6주 grid로 표시합니다.

날짜 cell 표시:
- 수면 dot: 수면 소리 리포트가 있는 날
- 혈압 dot: 수축기/이완기 sample이 있는 날
- 체성분 dot: 체중, BMI, 체지방률, 제지방량 또는 Fitdays 확장 체성분 sample이 있는 날
- 활동 dot: 걸음 수, 활동 에너지, 심박수 sample이 있는 날
- 체크인 dot: 아침 컨디션 또는 저녁 체크인이 있는 날
- sample count: 해당 날짜의 unified health sample 개수
- data quality: 데이터 종류와 sample 수를 바탕으로 한 제한적 품질 표시

월 이동:
- 이전 월
- 다음 월
- 오늘로 이동
- 선택된 날짜 표시

## CalendarDaySummary

`CalendarDaySummary`는 날짜 cell에 필요한 최소 요약입니다.

필드:
- `date`
- `hasSleepReport`
- `hasBloodPressure`
- `hasBodyComposition`
- `hasActivity`
- `hasMorningCheckIn`
- `hasEveningCheckIn`
- `sampleCount`
- `sourceTypes`
- `dataQuality`

`HealthCalendarBuilder`가 날짜별 sample, 수면 리포트, 체크인을 묶어 summary를 생성합니다.

## 일별 상세 화면

`DailyMeasurementDetailView`는 특정 날짜를 선택했을 때 표시되는 상세 화면입니다.

섹션:
- 날짜 요약
- 수면
- 아침 컨디션
- 저녁 체크인
- 혈압
- 체성분
- Fitdays 확장 체성분
- 활동
- 앱 계산 지표
- 데이터 출처

수면 섹션:
- 수면 소리 점수
- 측정 품질
- 코골기
- 이갈이 의심 소리
- 호흡정지 의심 구간
- 실제 오디오 수신 시간

혈압 섹션:
- 수축기 혈압
- 이완기 혈압
- 측정 시간
- sourceName

체성분 섹션:
- 체중
- BMI
- 체지방률
- 제지방량

Fitdays 확장 체성분 섹션:
- 체수분률
- 복부지방률 또는 내장지방 레벨
- 골격근량
- 무기질
- 골량
- 기초대사량
- 단백질률
- 근육량, 피하지방률, 대사 나이 등 import된 local-only metric

활동 섹션:
- 걸음 수
- 활동 에너지
- 심박수
- 안정시 심박수

앱 계산 지표 섹션:
- 수면 소리 점수
- 오늘의 리듬 점수
- 오디오 커버리지

각 metric row는 `MetricDetailView`로 이동할 수 있게 구성합니다.

## Source 구분

source type:
- `healthKit`: Apple 건강앱에서 read-only로 읽은 sample
- `fitdaysCSV`: 사용자가 직접 가져온 Fitdays CSV/export file sample
- `manual`: 사용자가 직접 입력한 local sample
- `appComputed`: 밤숨 앱이 기기 안에서 계산한 참고용 지표
- `mock`: preview/test용 sample

HealthKit 표준 지표가 Fitdays CSV에 포함되어 있어도 sourceType은 `fitdaysCSV`로 유지합니다. Apple 건강앱에서 읽은 값과 사용자가 가져온 파일의 값을 구분하기 위해서입니다.

## Daily Rhythm과의 관계

건강 캘린더는 Daily Rhythm Report의 날짜별 상세 보기입니다.

- 아침 리포트와 하루 리듬 리포트에서 쓰는 데이터를 날짜 기준으로 다시 확인합니다.
- 수면 소리 지표와 건강 sample을 같은 날짜에 함께 표시할 수 있습니다.
- 같은 날짜에 표시되는 것은 원인과 결과를 의미하지 않습니다.
- 데이터가 부족한 날짜는 empty state 또는 제한 안내를 표시합니다.

## Empty State

표시 상태:
- 해당 날짜에 데이터 없음
- 해당 category에 데이터 없음
- HealthKit 권한 없음
- Fitdays import 없음

HealthKit 권한이 없어도 수면 리포트, 로컬 import sample, mock preview, 앱 계산 지표는 가능한 범위에서 표시할 수 있습니다.

## 안전 원칙

- HealthKit read-only 정책을 유지합니다.
- HealthKit에 데이터를 쓰지 않습니다.
- 서버 전송을 하지 않습니다.
- 외부 SDK를 추가하지 않습니다.
- Fitdays 서버/API에 연결하지 않습니다.
- 비공식 API를 사용하지 않습니다.
- 전체 밤 원본 오디오는 저장하지 않습니다.
- 표시 문구는 개인 참고용과 관찰 중심으로 유지합니다.
- 수면 소리 지표와 건강 sample 사이의 인과관계를 주장하지 않습니다.
