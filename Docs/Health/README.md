# Health README

이 문서는 NightBreath / 밤숨의 Daily Rhythm, HealthKit read-only, Extended Health Metrics, Fitdays local import 흐름을 설명합니다.

## Daily Rhythm 방향

Daily Rhythm은 수면 소리 리포트를 하루 리듬의 시작점으로 삼습니다. 아침 리포트는 지난밤 수면 소리와 아침 컨디션을 보여주고, 이후 건강 대시보드와 하루 리듬 카드는 사용 가능한 건강 데이터와 컨디션 기록을 함께 정리합니다.

`오늘의 리듬 점수`는 웰니스/개인 참고용 점수입니다. 건강 상태를 확정하거나 질병 가능성을 예측하지 않으며, 치료나 의학적 조치를 권하지 않습니다.

## HealthKit read-only

HealthKit은 사용자가 건강 데이터 대시보드에서 연결을 선택한 경우에만 read-only로 사용합니다.

읽을 수 있는 지표 예시:

- 수축기 혈압
- 이완기 혈압
- 체중
- 체지방률
- BMI
- 제지방량
- 걸음 수
- 활동량
- 심박수
- 안정시 심박수
- 호흡수

앱은 HealthKit에 데이터를 쓰지 않습니다.

## Fitdays local import

Fitdays 관련 데이터는 다음 경로만 허용합니다.

- Apple 건강앱에 동기화된 표준 지표를 HealthKit read-only로 읽기
- 사용자가 직접 확보한 CSV/TSV/text export 파일을 로컬에서 선택해 가져오기
- 사용자가 직접 복사한 월별 데이터 텍스트를 붙여넣어 미리보기 후 저장하기
- 사용자가 직접 입력한 Fitdays local-only 지표를 로컬 샘플로 저장하기

Fitdays 서버/API 직접 연결, 로그인 구현, 자동 scraping, 비공식 연결 방식은 제외합니다.

## Extended Health Metrics

`UnifiedHealthMetricID`와 `UnifiedHealthMetricSample`은 HealthKit 표준 지표, Fitdays 로컬 전용 지표, 앱 계산 지표를 같은 catalog에서 표현합니다.

source type은 다음처럼 구분합니다.

- `healthKit`
- `fitdaysCSV`
- `manual`
- `appComputed`
- `mock`

Fitdays CSV/import 값은 HealthKit 표준 지표가 포함되어 있어도 `sourceType == fitdaysCSV`로 유지합니다.

## 관련 문서

| 문서 | 내용 |
| --- | --- |
| [HEALTH_DATA_GUIDE](../HEALTH_DATA_GUIDE.md) | HealthKit, Fitdays, EHM 통합 가이드 |
| [DAILY_RHYTHM_SCORE](../DAILY_RHYTHM_SCORE.md) | 오늘의 리듬 점수 계산 방향 |
| [DAILY_HEALTH_CARD](../DAILY_HEALTH_CARD.md) | 하루 리듬 카드와 privacy level |
| [TRENDS_DASHBOARD](../TRENDS_DASHBOARD.md) | 수면/건강 trend dashboard 방향 |
