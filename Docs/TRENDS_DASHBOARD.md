# 수면 트렌드 대시보드

NightBreath / 밤숨의 트렌드 대시보드는 앱 내부에 저장된 `NightReport`만 사용해 최근 수면 소리 지표를 살펴보기 위한 화면입니다. HealthKit 데이터, 서버 데이터, 외부 API는 사용하지 않습니다.

## 표시 기간

사용자는 다음 기간을 선택할 수 있습니다.

- 최근 7일
- 최근 30일
- 최근 90일

각 기간은 로컬 저장소의 `NightReport.generatedAt`을 기준으로 필터링합니다. 같은 `sessionId`의 리포트가 중복으로 들어오면 더 최근에 생성된 리포트를 사용합니다.

## Trend Metric

대시보드는 다음 `TrendMetricType` 값을 사용합니다.

- `sleepSoundScore`: 수면 소리 점수
- `audioCoverageRatio`: 오디오 커버리지, 퍼센트로 표시
- `snoreTotalSeconds`: 코골기 총 시간, 분 단위로 표시
- `bruxismLikeCount`: 이갈이 의심 소리 횟수
- `coughLikeCount`: 기침 의심 소리 횟수
- `gaspLikeCount`: gasp-like 회복 호흡 횟수
- `suspectedBreathingPauseCount`: 호흡정지 의심 구간 횟수
- `environmentalNoiseCount`: 환경 소음 횟수
- `awakeningSuspectedCount`: 각성 의심 구간 횟수

## Summary 계산

각 metric은 현재 기간의 data point를 만든 뒤 다음 값을 계산합니다.

- `average`
- `min`
- `max`
- `latest`
- `changeFromPreviousPeriod`
- `lowQualityDataCount`

`changeFromPreviousPeriod`는 현재 선택 기간의 평균에서 직전 같은 길이 기간의 평균을 뺀 값입니다. 예를 들어 30일 화면에서는 최근 30일 평균과 그 직전 30일 평균을 비교합니다.

## 낮은 측정 품질 처리

`MeasurementQuality.limited`와 `MeasurementQuality.poor`는 낮은 측정 품질로 표시합니다. 현재 기준은 기존 오디오 커버리지 기반 `MeasurementQuality` 정책을 따릅니다.

- `excellent`: 오디오 커버리지 95% 이상
- `good`: 오디오 커버리지 85% 이상
- `limited`: 오디오 커버리지 60% 이상
- `poor`: 오디오 커버리지 60% 미만

낮은 측정 품질 리포트는 차트에 남겨 사용자가 해당 날의 존재를 확인할 수 있게 합니다. 다만 평균, 최솟값, 최댓값 계산에서는 제외합니다. 최근값(`latest`)은 사용자가 마지막 리포트 상태를 확인할 수 있도록 낮은 측정 품질이어도 표시합니다.

## 개인정보 보호와 범위

트렌드는 앱 내부 리포트만 읽습니다.

- HealthKit 권한을 요청하지 않습니다.
- HealthKit 데이터를 읽거나 쓰지 않습니다.
- 서버 전송을 하지 않습니다.
- 네트워크 코드를 사용하지 않습니다.
- 밤새 원본 오디오 전체를 저장하지 않습니다.

이 화면은 웰니스 성격의 수면 소리 변화 확인용입니다. 전문적인 의료 목적이나 임상 지표 산출을 대신하지 않습니다.
