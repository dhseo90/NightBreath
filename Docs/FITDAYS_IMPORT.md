# Fitdays CSV Import

NightBreath / 밤숨은 사용자가 직접 export/share한 Fitdays CSV 또는 유사한 structured file을 로컬에서 읽어 `UnifiedHealthMetricSample`로 변환할 수 있습니다.

이 import는 Apple 건강앱 read-only 구조와 별개입니다. HealthKit에 없는 Fitdays 고유 체성분 지표는 HealthKit으로 읽으려 하지 않고, 앱의 로컬 확장 지표로만 관리합니다.

## 준비 방법

1. Fitdays 앱에서 체중/체성분 기록 export 또는 share 기능을 사용합니다.
2. CSV 또는 텍스트 기반 structured file을 iPhone의 파일 앱, iCloud Drive, AirDrop 등 사용자가 직접 접근 가능한 위치에 둡니다.
3. 밤숨 앱의 `건강 데이터` 화면에서 `Fitdays CSV 가져오기`를 선택합니다.
4. 파일 선택 화면에서 export 파일을 고릅니다.
5. 저장 전 preview에서 생성 sample 수, 건너뛴 row, 알 수 없는 column, 오류를 확인합니다.
6. 문제가 없으면 `로컬에 저장`을 선택합니다.

실제 개인 CSV 파일은 repository에 커밋하지 않습니다. 테스트에는 synthetic CSV fixture만 사용합니다.

## 지원하는 Metric Mapping

기본 mapping은 column 이름을 느슨하게 맞춥니다. 필요하면 `FitdaysCSVColumnMapping`으로 mapping rule을 바꿀 수 있습니다.

| CSV column 예시 | Metric ID | 저장 위치 |
| --- | --- | --- |
| `Weight`, `Body Weight` | `bodyMass` | HealthKit 표준 지표와 같은 unified sample, sourceType은 `fitdaysCSV` |
| `BMI`, `Body Mass Index` | `bodyMassIndex` | HealthKit 표준 지표와 같은 unified sample, sourceType은 `fitdaysCSV` |
| `Body Fat`, `Body Fat %` | `bodyFatPercentage` | HealthKit 표준 지표와 같은 unified sample, sourceType은 `fitdaysCSV` |
| `Muscle Mass` | `muscleMass` | Fitdays local-only |
| `Skeletal Muscle`, `Skeletal Muscle Mass` | `skeletalMuscleMass` | Fitdays local-only |
| `Body Water`, `Body Water %` | `bodyWaterPercentage` | Fitdays local-only |
| `Visceral Fat`, `Visceral Fat Level` | `visceralFatLevel` | Fitdays local-only |
| `Visceral Fat %` | `visceralFatPercentage` | Fitdays local-only |
| `Bone Mass` | `boneMass` | Fitdays local-only |
| `Mineral`, `Mineral Mass` | `mineralMass` | Fitdays local-only |
| `BMR`, `Basal Metabolic Rate` | `basalMetabolicRate` | Fitdays local-only |
| `Protein`, `Protein %` | `proteinPercentage` | Fitdays local-only |
| `Subcutaneous Fat`, `Subcutaneous Fat %` | `subcutaneousFatPercentage` | Fitdays local-only |
| `Body Age`, `Metabolic Age` | `metabolicAge` | Fitdays local-only |
| `Body Score` | `bodyScore` | Fitdays local-only |
| `Obesity Level`, `Body Type Level` | `obesityLevel` | Fitdays local-only |
| `Systolic BP`, `Diastolic BP`, `Heart Rate` | 혈압/심박수 표준 지표 | sourceType은 `fitdaysCSV` |

HealthKit 표준 지표가 CSV에 포함되어 있어도 sourceType은 `fitdaysCSV`로 남깁니다. Apple 건강앱에서 읽은 값과 사용자가 가져온 CSV 값을 구분하기 위해서입니다.

## 날짜와 시간

기본 parser는 다음 형태를 지원합니다.

- 날짜 column: `Date`, `Measure Date`, `Measurement Date`, `측정일`, `날짜`
- 시간 column: `Time`, `Measure Time`, `Measurement Time`, `측정시간`, `시간`
- 예시 format: `yyyy-MM-dd HH:mm`, `yyyy/MM/dd HH:mm`, `MM/dd/yyyy HH:mm`, `yyyy년 M월 d일 HH:mm`

날짜/시간을 해석할 수 없는 row는 건너뜁니다. 전체 import는 중단하지 않고 결과 화면에 오류 row를 표시합니다.

## 저장 방식

- `FitdaysImportService`가 CSV를 parsing하고 `ImportBatch`와 `UnifiedHealthMetricSample` 목록을 만듭니다.
- `JSONUnifiedHealthMetricSampleRepository`가 `Application Support/NightBreath/imported-health-metrics.json`에 로컬 저장합니다.
- 같은 source/fileName을 다시 import하면 이전 batch와 sample을 교체해 중복을 줄입니다.
- `deleteBatch(id:)`로 import batch와 연결 sample을 함께 삭제할 수 있습니다.

## Privacy And Safety

- Fitdays 서버/API 로그인 기능을 만들지 않습니다.
- 비공식 API reverse engineering을 하지 않습니다.
- 서버, 클라우드, 외부 SDK로 데이터를 보내지 않습니다.
- HealthKit write를 하지 않습니다.
- HealthKit custom type을 만들지 않습니다.
- 이 앱은 진단 목적의 의료기기가 아닙니다.
- 가져온 값은 개인 패턴을 살펴보기 위한 참고용 보기입니다.
