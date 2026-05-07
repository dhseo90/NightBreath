# Health Data Guide

이 문서는 NightBreath / 밤숨의 HealthKit read-only 연동, mock health data, Extended Health Metrics, Fitdays CSV import, 건강 대시보드, metric trend, 월 건강 캘린더, Metric Detail, 수면/건강 지표 교차 보기를 한곳에 묶은 기준 문서입니다.

이전에는 주제별로 작은 문서가 나뉘어 있었지만, 현재 제품 방향에서는 모두 같은 건강 데이터 흐름의 일부입니다.

## 핵심 원칙

- HealthKit은 read-only로만 사용합니다.
- 앱은 HealthKit에 데이터를 쓰지 않습니다.
- 앱 첫 실행, 수면 시작, 수면 종료 흐름에서는 HealthKit 권한을 요청하지 않습니다.
- HealthKit 권한 요청은 사용자가 건강 데이터 연결을 명시적으로 선택한 경우에만 시작합니다.
- HealthKit 데이터를 서버로 전송하지 않습니다.
- Fitdays 서버/API 직접 연결, 비공식 연결 방식, reverse engineering은 하지 않습니다.
- Fitdays CSV/TSV 또는 structured text export file은 사용자가 직접 확보하고 선택한 로컬 파일만 처리합니다.
- Fitdays 앱 안에서 CSV/export 경로가 보이지 않는 경우에는 Apple 건강앱 read-only 표준 지표만 사용합니다.
- 실제 개인 CSV 파일은 repository에 포함하지 않습니다.
- 건강 데이터는 개인 참고용으로만 표시하며, 상태를 단정하거나 지표 사이의 원인과 결과를 주장하지 않습니다.

## 서비스 구조

주요 경계:

- `HealthKitServiceProtocol`
- `DisabledHealthKitService`
- `RealHealthKitService`
- `MockHealthKitService`
- `MockHealthDataService`
- `FitdaysImportService`
- `UnifiedHealthMetricSampleRepository`

`RealHealthKitService`는 Apple 건강앱 read-only 권한 요청과 quantity sample query를 담당합니다. 테스트와 preview에서는 mock service를 사용하며, 권한 없음/데이터 없음/일부 권한 허용 상태도 protocol 뒤에서 안전하게 표현합니다.

HealthKit mock과 Fitdays import mock은 다릅니다.

- HealthKit mock: Apple 건강앱에 들어오는 표준 지표를 미리 보기 위한 preview/test fallback입니다.
- Fitdays CSV/structured export import mock: HealthKit에 없는 확장 로컬 전용 지표를 미리 보기 위한 synthetic import fixture입니다.

HealthKit mock service가 Fitdays 서버 연결, HealthKit custom type, HealthKit write를 의미하지 않습니다.

## HealthKit Read-Only 범위

현재 read-only 대상:

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
- 호흡수

권한 거부 또는 데이터 없음 상태에서는 수면 기능이 계속 동작해야 합니다. 건강 대시보드는 연결 안내, empty state, 데이터 품질 안내를 표시합니다.

HealthKit 제한:

- `requestAuthorization(toShare: Set<HKSampleType>(), read: ...)`처럼 share 대상은 비워 둡니다.
- `save`, `delete`, streaming query, write/update usage description을 사용하지 않습니다.
- 수면 소리 점수, 오늘의 리듬 점수, 이벤트, 리포트, 피드백을 HealthKit에 기록하지 않습니다.

## Extended Health Metrics

통합 metric catalog는 HealthKit 표준 지표, Fitdays 로컬 전용 확장 지표, 앱 계산 지표를 같은 UI 흐름에서 다루기 위한 구조입니다.

주요 타입:

- `UnifiedHealthMetricID`
- `UnifiedHealthMetricSample`
- `HealthMetricSourceType`
- `MetricDisplayMetadata`
- `MetricCatalog`

`HealthMetricSourceType`:

- `healthKit`
- `fitdaysCSV`
- `manual`
- `appComputed`
- `mock`

HealthKit 기반 지표는 Apple 건강앱에서 read-only로 읽은 표준 지표입니다. Fitdays 확장 로컬 전용 지표는 HealthKit에 없는 지표이며 HealthKit으로 읽으려 하지 않습니다.

Fitdays 로컬 전용 지표 예시:

- 체수분률
- 내장지방 레벨
- 복부지방률
- 골격근량
- 근육량
- 무기질
- 골량
- 기초대사량
- 단백질률
- 피하지방률
- 대사 나이

CSV 또는 structured export file에 HealthKit 표준 지표가 포함되어 있어도 `sourceType == fitdaysCSV`로 유지합니다. Apple 건강앱 read-only sample과 사용자가 가져온 export sample을 UI badge, sourceName, sourceType으로 구분하기 위해서입니다.

## Fitdays CSV Import

기능명은 V1에서 `Fitdays CSV Import`로 유지합니다. 다만 제품 설명과 importer 설계는 Fitdays 앱에서 사용자가 직접 확보한 CSV/TSV 또는 CSV-compatible structured text export file을 로컬에서 가져오는 흐름으로 둡니다. 실제 앱에서 export 경로가 보이지 않을 수 있으므로 이 기능은 선택적 보조 경로이며, 파일이 없을 때도 NightBreath의 HealthKit read-only 건강 대시보드는 동작해야 합니다.

2026-05-04 기준 조사 메모:

- Fitdays 공식 도움말의 Progress Report 공유 흐름에는 Image, PDF, CSV 형식 선택지가 있고 CSV는 분석용 raw data 형식으로 설명되어 있습니다. 참고: [Fitdays - How to share body data?](https://fitdays.org/docs/app-functions/share-body-data)
- Fitdays privacy 문서에는 앱 데이터가 CSV 형식으로 저장되며, History Records / Data Reports 같은 앱 기능에서 CSV export를 지원한다고 설명되어 있습니다. 참고: [Fitdays App Privacy Policy](https://fitdays.org/app-privacy)
- Fitdays+ privacy 문서에는 사용자가 personal data를 CSV 형식으로 export 요청할 권리가 있다고 설명되어 있습니다. 참고: [Fitdays+ Privacy Policy](https://plus.fitdays.cn/app/privacy?language=en&source=0)
- 실제 메뉴명과 export 위치는 앱 버전, 지역, Fitdays/Fitdays+ 차이, 로그인 상태, 연결된 scale 모델에 따라 다를 수 있습니다. NightBreath 문서는 특정 메뉴명을 단정하지 않고 사용자가 직접 확보한 로컬 export 파일만 다룹니다.
- 2026-05-06 실제 사용 확인에서는 앱 안에서 명확한 CSV/export 메뉴를 찾지 못했습니다. 따라서 QA와 제품 copy는 export 가능성을 단정하지 않고, 파일을 확보하지 못하면 Apple 건강앱 read-only 표준 지표를 우선 사용합니다.

### Fitdays 데이터 유입 경로

NightBreath가 허용하는 Fitdays 관련 데이터 유입 경로는 다음 세 가지입니다.

1. Apple Health -> HealthKit read-only
   - Fitdays가 Apple 건강앱에 동기화한 target data 중 HealthKit 표준 지표만 읽습니다.
   - NightBreath는 HealthKit write를 하지 않고, HealthKit custom type을 만들지 않습니다.
   - HealthKit에 없는 Fitdays 고유 지표는 이 경로로 읽으려 하지 않습니다.
2. Fitdays CSV/export -> 앱 내부 file import
   - 사용자가 Files, iCloud Drive, AirDrop, Mail 등으로 확보한 CSV/TSV 또는 structured text export file을 `FitdaysImportView`에서 직접 선택합니다.
   - CSV/export 파일이 없다면 이 경로는 사용하지 않습니다.
   - `fileImporter`는 CSV/text 기반 type을 열 수 있지만, preview validation을 통과한 structured export만 저장할 수 있습니다.
   - unknown column은 warning, invalid row는 skipped row로 처리합니다.
3. Fitdays share/export -> Open in NightBreath
   - iOS document type/open-in 등록으로 CSV 또는 plain text export 파일을 NightBreath로 열 수 있게 합니다.
   - 받은 file URL은 read-only 입력으로만 사용하고, 같은 preview/import validation을 통과해야 저장합니다.
   - 실제 개인 파일명이나 local path는 screenshot과 public 문서에 노출하지 않습니다.

명시적으로 제외하는 경로:

- Fitdays 서버/API 직접 호출
- Fitdays 계정 로그인 구현
- Fitdays 앱 내부 데이터 접근
- Fitdays 화면 UI automation
- 자동 scraping
- 비공식 API reverse engineering
- 자동 동기화 구현

자동 동기화가 필요한 경우에도 NightBreath가 허용하는 범위는 Apple 건강앱에 이미 들어온 표준 지표를 HealthKit read-only로 읽는 것뿐입니다.

구성:

- `FitdaysImportView`
- `FitdaysImportService`
- `FitdaysCSVColumnMapping`
- `ImportBatch`
- `UnifiedHealthMetricSampleRepository`

사용자 확인 경로:

- Fitdays 앱의 Reports / Data Reports / Chart / History Records / More Data 영역을 확인합니다.
- Account / Export My Data / Customer Service Center / Personal Data Request처럼 보이는 메뉴도 확인합니다.
- Share / Export 버튼이 있는지 확인합니다.
- Format 선택지에서 CSV 또는 유사한 structured export 형식이 있는지 확인합니다.
- Files, iCloud Drive, AirDrop, Mail 등으로 파일을 저장할 수 있는지 확인합니다.
- 실제 iPhone 재확인에서는 확인한 메뉴 path와 export 가능 여부만 private QA note에 기록합니다.
- export 파일의 column 이름, 날짜/시간 필드, 단위 표기, metric 값 형식을 private QA note에서만 확인합니다. 실제 파일명, 실제 path, 실제 수치는 repository와 screenshot에 남기지 않습니다.
- Fitdays 앱 버전, 로그인 상태, 지역/언어 설정은 repository가 아니라 private QA note에만 기록합니다.

CSV가 보이지 않을 때 fallback:

- Account / Export My Data / Customer Service Center 같은 데이터 추출 요청 경로가 있는지 확인합니다.
- Fitdays+ 사용자라면 personal data export 요청 경로를 확인합니다.
- 그래도 CSV 또는 structured export file을 확보할 수 없으면 Apple 건강앱 read-only 표준 지표만 사용합니다.
- HealthKit에 없는 Fitdays 고유 지표는 manual input 또는 향후 로컬 입력 기능의 follow-up으로 남깁니다.
- `FitdaysImportFallbackGuidance`와 `FitdaysImportView`는 파일이 없어도 괜찮다는 섹션, CSV/export 메뉴를 찾지 못한 경우의 안내, 건강 데이터 대시보드 진입을 제공해, 사용자가 CSV/export 없이도 read-only 표준 지표 흐름을 계속 볼 수 있게 합니다.
- NightBreath는 이 fallback을 위해 Fitdays 로그인, 서버/API 직접 연결, 자동 동기화, 비공식 연결 방식을 구현하지 않습니다.
- export가 보이지 않는 상황은 Fitdays 서버/API 연결이나 UI scraping을 추가할 근거가 아니며, 사용자 선택 기반 로컬 파일 또는 Apple 건강앱 read-only 경로만 유지합니다.

지원하는 mapping 예시:

- `Weight` -> `bodyMass`
- `BMI` -> `bodyMassIndex`
- `Body Fat` -> `bodyFatPercentage`
- `Muscle Mass` -> `muscleMass`
- `Skeletal Muscle` -> `skeletalMuscleMass`
- `Body Water` -> `bodyWaterPercentage`
- `Visceral Fat` -> `visceralFatLevel`
- `Bone Mass` -> `boneMass`
- `Mineral` -> `mineralMass`
- `BMR` -> `basalMetabolicRate`
- `Protein` -> `proteinPercentage`
- `Subcutaneous Fat` -> `subcutaneousFatPercentage`
- `Body Age` -> `metabolicAge`

Importer 설계 원칙:

- 입력은 사용자가 명시적으로 선택한 local file URL입니다.
- 앱 내부 파일 선택과 iOS open-in document URL은 같은 preview/import pipeline을 사용합니다.
- document type은 CSV/TSV와 plain text 기반 export 파일을 대상으로 하며, 모든 text 파일을 무조건 import하지 않습니다.
- `.csv`, `.tsv`, `.txt` 외의 파일은 preview parsing 전에 unsupported file type으로 거부합니다.
- CSV-compatible text를 우선 지원하고, 향후 structured export file이 확인되면 같은 privacy boundary 안에서 parser를 추가합니다.
- column mapping은 영어, 한국어, 축약 column, punctuation/space/case 차이를 유연하게 받아들입니다.
- unknown column은 전체 실패가 아니라 warning으로 남깁니다.
- invalid row는 전체 import 실패가 아니라 skipped row와 row error로 남깁니다.
- date column이 없거나 structured export로 해석할 수 없는 text 파일은 저장 전에 실패합니다.
- 측정일 column은 있지만 지원 지표 column이 없는 text 파일은 저장 전에 실패합니다.
- 지원 지표 column이 있어도 import 가능한 샘플이 0개인 파일은 저장하지 않습니다.
- CSV/TSV delimiter, decimal separator, 날짜/시간 format, localized column name, UTF-8 BOM, 단위 suffix 차이를 regression test로 점검합니다.
- 같은 `sourceName + fileName`을 다시 가져오면 duplicate import handling으로 이전 batch와 해당 sample을 교체합니다.
- 다른 file에서 같은 metric/source/external record key가 들어오면 중복 sample key 기준으로 기존 sample을 제거하고 새 import 값을 유지합니다.
- 가져온 sample의 `sourceType`은 항상 `fitdaysCSV`입니다. HealthKit 표준 지표가 export 파일에 있어도 `healthKit` source로 바꾸지 않습니다.
- import batch는 삭제 가능해야 하며, 삭제 시 해당 `importBatchId`를 가진 sample도 함께 정리할 수 있어야 합니다.
- UI에는 실제 local path를 표시하지 않고, screenshot에는 실제 개인 파일명도 사용하지 않습니다.
- 지표 상세 화면에서는 Fitdays CSV 값을 `Fitdays CSV · 로컬` badge로 표시하고, raw `importBatchId` 같은 내부 ID는 사용자 화면에 노출하지 않습니다.
- HealthKit-backed 표준 지표가 Fitdays CSV로 들어온 경우에도 HealthKit 값으로 바꾸지 않고 로컬 import 출처로 분리 표시합니다.

### Open in NightBreath / Share Extension 방침

V1에서는 Share Extension을 바로 추가하지 않고 document type/open-in을 먼저 지원합니다.

현재 구현 범위:

- `Info.plist`에 CSV/TSV/plain text document type을 등록합니다.
- 앱 root에서 `onOpenURL`로 file URL을 받아 `FitdaysImportView` preview sheet로 연결합니다.
- 같은 `FitdaysImportService` validation을 사용해 unsupported extension, missing date column, invalid row, unknown column을 처리합니다.
- 원본 파일은 읽기 입력으로만 사용하고, import 결과만 로컬 `ImportBatch`와 `UnifiedHealthMetricSample`로 저장합니다.

Share Extension 후보:

- 장점: Fitdays share sheet에서 NightBreath Import가 더 명확하게 보일 수 있습니다.
- 단점: App Group, extension target, extension UI, QA matrix가 늘어납니다.
- 결정 기준: 실제 Fitdays share/export UX를 iPhone에서 확인한 뒤, document type/open-in만으로 충분한지 판단합니다.

호환성 fixture는 synthetic data만 사용합니다. 현재 regression은 기본 영어 CSV, 한국어/세미콜론 CSV, 축약 column/탭 delimiter/decimal comma CSV, BOM이 포함된 TSV short export, 월별 복사 텍스트에 가까운 익명화 pasted text를 포함합니다. pasted text regression은 월 헤더, 축약 날짜, 한국어 오전/오후, label/value 분리 줄, `몸무게`, `수분`, `골격근`, `내장지방등급`, `기초대사`, `체나이`, `비만등급` alias를 확인합니다.

가져오기 결과는 `ImportBatch`와 `UnifiedHealthMetricSample`로 묶어 로컬 저장소에 보관합니다. 원본 CSV 파일 자체는 repository나 screenshot asset으로 보관하지 않습니다.

`FitdaysImportView`의 미리보기는 저장 전 단계입니다. `미리보기 판단` 섹션에서 처리한 row, 저장 가능한 샘플, 건너뛴 row 해석, 확인 필요 row, 지원하지 않는 column을 분리해 보여주고, 사용자가 `로컬에 저장`을 누르기 전에는 저장소에 쓰지 않습니다.

저장된 가져오기 기록은 같은 화면의 `저장된 가져오기` 섹션에서 확인합니다. 이 섹션은 현재 저장소 기준 샘플 수, 처리 row, 건너뜀/오류 count를 보여주고, 삭제 시 해당 `importBatchId`를 가진 로컬 샘플을 함께 제거합니다. 실제 파일명과 local path는 개인 정보가 섞일 수 있으므로 목록에 표시하지 않습니다.

검증해야 할 상태:

- valid CSV preview/result
- invalid date/time row skip
- unknown column warning
- duplicate import handling
- `저장된 가져오기` 목록과 batch 삭제 시 관련 sample 삭제
- 실제 파일명과 실제 개인 수치가 문서/screenshot에 노출되지 않음

## Health Dashboard

`HealthDashboardView`는 건강 데이터 흐름의 허브입니다.

진입점:

- HealthKit read-only 연결
- 혈압 대시보드
- 체성분 대시보드
- 수면/건강 지표 교차 보기
- 전체 건강 지표
- 월 건강 캘린더
- Fitdays CSV 가져오기

혈압/체성분 대시보드는 최근 값, 측정 시각, sourceName, 7일/30일/90일 추세를 보여줍니다. 수치를 상태 판정으로 표현하지 않고, 개인 참고용 데이터와 출처를 함께 표시합니다.

## Metric Trends

`HealthMetricsOverviewView`와 `MetricChartView`는 모든 health metric을 카테고리별로 보여줍니다.

지원 기간:

- 7일
- 30일
- 90일
- 1년

통계:

- 최근값
- 평균
- 최소
- 최대
- 이전 기간 대비 변화량
- 측정 횟수
- 첫 측정 시각
- 최근 측정 시각

`MetricStatisticsCalculator`와 `HealthMetricTrendCalculator`는 SwiftUI View 밖에서 계산합니다. 차트는 Swift Charts를 사용하고 외부 chart SDK는 추가하지 않습니다.

## Health Calendar

`HealthCalendarView`는 월 단위로 데이터가 있는 날짜를 표시합니다.

`CalendarDaySummary`는 다음 상태를 요약합니다.

- 수면 리포트 존재 여부
- 혈압 데이터 존재 여부
- 체성분 데이터 존재 여부
- 활동 데이터 존재 여부
- 아침/저녁 체크인 존재 여부
- 샘플 개수
- source types
- data quality

날짜를 선택하면 `DailyMeasurementDetailView`에서 해당 날짜의 수면, 체크인, 혈압, 체성분, Fitdays 확장 지표, 활동, 앱 계산 지표, 데이터 출처를 카테고리별로 보여줍니다.

## Metric Detail

`MetricDetailView`는 metric 하나를 자세히 보는 화면입니다.

표시:

- metric 표시 이름과 설명
- 최근 값과 측정 시각
- unit
- 기간 선택
- source filter
- trend chart
- summary stats
- 원본 샘플 목록

source filter:

- 전체
- HealthKit
- Fitdays CSV
- Manual
- App Computed
- Mock는 DEBUG/screenshot scenario에서만 사용합니다.

HealthKit 기반 지표는 Apple 건강앱 read-only 샘플로 설명하고, Fitdays 로컬 전용 지표는 CSV 가져오기 또는 수동/앱 계산 데이터로만 표시한다고 설명합니다.

## Cross Metric Analysis

수면 소리 지표와 건강 지표는 날짜 기준으로 함께 볼 수 있습니다. 이 화면은 개인 패턴 탐색용이며 지표 사이의 원인과 결과를 말하지 않습니다.

수면 지표 예시:

- 수면 소리 점수
- 코골기 시간
- 이갈이 의심 소리 수
- 호흡정지 의심 구간 수
- 기침 의심 소리 수
- 환경 소음 수
- 오디오 커버리지

건강 지표 예시:

- 수축기 혈압
- 이완기 혈압
- 체중
- 체지방률
- BMI
- 안정시 심박수

날짜 매칭:

- 수면 리포트 날짜
- 다음날 아침 혈압
- 같은 날짜 체중/체성분

matched sample 수가 부족하면 분석 요약을 만들지 않고 “비교 가능한 데이터가 아직 부족합니다”처럼 제한 안내를 표시합니다. 낮은 오디오 커버리지 데이터는 구분하거나 요약에서 제외합니다.

허용 표현:

- 코골기 시간이 긴 날과 다음날 혈압 데이터를 함께 표시합니다.
- 개인 패턴을 살펴보기 위한 참고용 보기입니다.
- 인과관계를 의미하지 않습니다.

## Screenshot / QA 원칙

- screenshot은 mock data 또는 simulator scenario 기반으로만 생성합니다.
- 실제 HealthKit 데이터, 실제 Fitdays CSV, 실제 오디오 파일을 screenshot에 사용하지 않습니다.
- DEBUG screenshot scenario는 Release 사용자에게 노출하지 않습니다.
- README에는 대표 screenshot만 두고 상세 화면은 `Docs/UI_GALLERY.md`에서 관리합니다.

관련 QA는 `Docs/QA_GUIDE.md`를 따릅니다.
