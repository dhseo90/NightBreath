# Product Direction

NightBreath / 밤숨은 iPhone 온디바이스 수면 소리 리포트에서 시작해, 하루 동안의 수면, 혈압, 체중, 체성분, 활동, 컨디션 기록을 함께 살펴보는 온디바이스 개인 건강 리듬 리포트 앱으로 확장합니다.

이 방향은 기존 수면 소리 분석 기능을 대체하지 않습니다. 수면 중 소리 이벤트와 아침 리포트는 앱의 첫 번째 축으로 유지하고, 이후 Apple 건강앱에 모인 건강 데이터와 사용자의 주관적 컨디션 기록을 같은 날짜 흐름 안에서 보기 쉽게 정리합니다.

## 핵심 원칙

- 모든 기본 분석과 리포트는 iPhone 안에서 처리합니다.
- 서버 업로드, 클라우드 처리, 외부 API 호출, 외부 분석 SDK, 광고 SDK를 추가하지 않습니다.
- 계정 시스템을 만들지 않습니다.
- 전체 밤 원본 오디오를 기본 저장하지 않습니다.
- 이벤트 오디오 샘플은 사용자가 opt-in한 경우에만 짧은 로컬 샘플로 저장합니다.
- 건강 데이터는 Apple 건강앱 read-only 방향으로만 다룹니다.
- HealthKit 권한 요청은 사용자가 건강 데이터 연결을 선택한 경우에만 수행합니다.
- HealthKit adapter는 protocol 기반으로 mock service와 교체 가능하게 유지합니다.
- 리포트는 웰니스와 개인 참고용이며, 진단 목적의 의료기기가 아닙니다.

## 현재 Daily Rhythm 구현 범위

현재 앱에는 Daily Rhythm 확장을 위한 기반이 mock/protocol 중심으로 들어가 있습니다.

- `DailyHealthSnapshot`, `DailyRhythmReport`, `DailyRhythmScore`, `DailyInsight`, `EveningCheckIn` 등 하루 단위 도메인 모델
- `HealthDataServiceProtocol`, `MockHealthDataService`, `DailyHealthSnapshotBuilder` 기반 mock 건강 데이터 구조
- Omron Connect 혈압, Fitdays 체중/체성분, Apple Health Mock 활동/심박수 source 예시
- `UnifiedHealthMetricID`, `UnifiedHealthMetricSample`, `HealthMetricSourceType`, `MetricCatalog` 기반 Extended Health Metrics catalog
- Fitdays CSV/export file을 사용자가 직접 선택해 가져오는 local import 구조
- `HealthMetricsOverviewView`, `HealthCalendarView`, `DailyMeasurementDetailView`, `MetricDetailView` 기반 건강 지표 탐색 화면
- `DailyRhythmScoreCalculator`, `DailyInsightGenerator`, `DailyRhythmReportBuilder`
- `MorningBriefView`, `DailyRhythmReportView`, `EveningCheckInView`
- `DailyHealthCardView`, `DailyHealthCardPreviewView`, 카드 template/privacy level 구조

이 구현은 mock data, 실제 HealthKit read-only adapter, Fitdays 로컬 전용 import data를 분리합니다. HealthKit 쓰기, 서버 전송, 외부 SDK는 포함하지 않습니다.

## 수면 소리 리포트에서 개인 건강 리듬 리포트로

기존 앱의 중심은 수면 시작, 수면 종료, 수면 소리 점수, 이벤트 타임라인, 아침 컨디션 체크인입니다. 확장 방향에서는 이 수면 리포트를 하루 리듬의 시작점으로 봅니다.

하루 리듬 리포트는 아침에 확인하는 수면 소리 리포트와 낮 동안의 건강 데이터, 저녁 컨디션 기록을 같은 날짜의 흐름으로 묶습니다. 앱은 개별 지표를 단정적으로 해석하지 않고, 사용자가 자신의 생활 패턴을 살펴볼 수 있게 정리합니다.

## 하루 리듬 리포트

하루 리듬 리포트는 특정 하루에 대해 다음 정보를 모아 보여주는 참고용 보기입니다.

- 지난밤 수면 소리 리포트
- 수면 소리 점수와 측정 품질
- 아침 컨디션 체크인
- 혈압, 체중, 체성분, 활동, 호흡수, 심박수 같은 향후 read-only 건강 지표
- 저녁 컨디션 또는 하루 메모
- 데이터가 있는 항목과 없는 항목의 품질 안내

하루 리듬 리포트는 지표 사이의 인과관계를 주장하지 않습니다. 예를 들어 코골기 시간이 긴 날과 다음날 혈압 데이터를 함께 보여줄 수는 있지만, 한 지표가 다른 지표를 변화시켰다고 말하지 않습니다.

## 오늘의 리듬 점수

오늘의 리듬 점수는 의료 점수가 아니라 웰니스 성격의 개인 참고용 점수입니다.

초기 방향은 다음 요소를 참고합니다.

- 수면 소리 점수
- 수면 측정 품질과 오디오 커버리지
- 아침 컨디션 기록
- 낮 동안의 활동 또는 컨디션 기록
- 향후 사용자가 허용한 read-only 건강 데이터의 존재 여부와 데이터 품질

점수는 사용자가 하루 흐름을 빠르게 돌아보기 위한 요약입니다. 건강 상태를 단정하거나, 의학적 조치를 안내하지 않습니다.

## 아침 리포트, 하루 리듬 카드, 건강 대시보드

아침 리포트는 지난밤 수면 소리와 아침 컨디션을 가장 먼저 보여주는 화면입니다. 기존 수면 리포트의 역할을 유지합니다.

하루 리듬 카드는 하루 중 확인할 수 있는 핵심 지표를 작게 묶은 카드입니다. 수면, 혈압, 체중, 체성분, 활동, 컨디션 중 데이터가 있는 항목만 조심스럽게 보여줍니다. 현재는 `simple`, `sleepFocused`, `healthSummary`, `privacyMinimal` template과 `minimal`, `standard`, `detailed` privacy level을 준비해 민감 수치 표시 범위를 조절합니다.

이미지 export/share/save는 `DailyHealthCardPreviewView`에서 사용자가 명시적으로 `이미지 만들기`를 선택한 경우에만 로컬 PNG를 생성하고, 이미지가 준비된 뒤에만 시스템 share sheet, 사진 앱 저장, 파일 앱 저장을 여는 방식으로 구현했습니다. 자동 공유, 자동 저장, 서버 업로드, 외부 SDK는 사용하지 않습니다.

건강 대시보드는 사용자가 더 자세히 보고 싶을 때 들어가는 화면입니다. 혈압, 체중, 체성분, 활동, 수면 지표를 각각의 출처와 측정 시각, 데이터 품질과 함께 보여줍니다.

세 화면은 같은 데이터를 서로 다른 깊이로 보여줍니다. 아침 리포트는 시작점, 하루 리듬 카드는 요약, 건강 대시보드는 상세 보기입니다.

## HealthKit 방향

HealthKit은 read-only로만 사용합니다.

- 사용자가 건강 데이터 대시보드에서 연결 버튼을 누를 때만 권한 요청을 고려합니다.
- 앱 첫 실행, 수면 시작, 수면 종료 흐름에서는 HealthKit 권한을 요청하지 않습니다.
- 앱은 HealthKit에 데이터를 쓰지 않습니다.
- 수면 소리 점수, 이벤트, 리포트, 피드백, 컨디션 기록을 HealthKit에 기록하지 않습니다.
- Apple 건강앱 데이터를 서버나 외부 앱으로 전송하지 않습니다.
- Omron Connect와 Fitdays에는 직접 연결하지 않고, 사용자가 Apple 건강앱에 동기화한 데이터를 읽는 방향만 가정합니다.

현재 실제 adapter는 `RealHealthKitService`로 분리하고, `HealthDataServiceProtocol`과 mock service로 화면, 점수 계산, empty state, 권한 제한 안내를 계속 검증합니다.

## Fitdays 확장 지표 방향

Fitdays에는 Apple 건강앱/HealthKit 표준 지표로 직접 표현되지 않는 체성분 항목이 있을 수 있습니다. 밤숨은 이런 항목을 HealthKit custom type으로 만들거나 HealthKit에 쓰지 않고, 앱 안의 로컬 전용 확장 metric으로 관리합니다.

EHM 원칙은 HealthKit 기반 지표와 Fitdays 로컬 전용 지표를 분리하는 것입니다. HealthKit 기반 지표는 Apple 건강앱에서 read-only로 읽은 표준 지표이고, Fitdays 로컬 전용 지표는 사용자가 직접 가져온 CSV/export file 또는 수동 입력/앱 계산 데이터로만 표시합니다.

로컬 전용 확장 metric 예시는 다음과 같습니다.

- 체수분률
- 복부지방률 또는 복부지방 level
- 골격근량
- 근육량
- 무기질
- 골량
- 기초대사량
- 단백질률
- 피하지방률
- 신체 나이 또는 Fitdays score 성격의 값

사용자는 Fitdays 앱에서 직접 export/share한 CSV 또는 structured file을 선택해 가져옵니다. 앱은 선택된 로컬 파일을 기기 안에서 parsing하고, 결과를 `UnifiedHealthMetricSample`과 `ImportBatch`로 저장합니다.

Fitdays 확장 지표 원칙:

- Apple 건강앱/HealthKit에 없는 Fitdays 체성분 지표는 HealthKit query 대상에 넣지 않습니다.
- Fitdays 원격 서비스에 직접 연결하지 않습니다.
- 비공식 연결 방식이나 reverse engineering을 사용하지 않습니다.
- CSV 원본 파일은 사용자가 선택한 import 입력이며, repository에는 실제 개인 CSV를 포함하지 않습니다.
- HealthKit 표준 지표가 CSV에 포함되어 있어도 sourceType은 `fitdaysCSV`로 유지해 Apple 건강앱 read-only sample과 구분합니다.
- HealthKit 기반 지표와 로컬 전용 지표는 UI에서 배지, 설명, sourceName, sourceType으로 구분합니다.
- 확장 지표도 개인 참고용으로만 표시하고 건강 상태를 단정하지 않습니다.

## 개인정보와 오디오 저장

수면 소리 분석은 온디바이스 원칙을 유지합니다.

- 기본 동작으로 전체 밤 원본 오디오를 저장하지 않습니다.
- 로컬 수면 세션, 이벤트 요약, 리포트, 컨디션 기록만 저장합니다.
- 잠꼬대나 말소리를 텍스트로 변환하지 않습니다.
- 이벤트 전후 오디오 샘플은 사용자가 opt-in한 경우에만 저장합니다.
- 이벤트 샘플은 전체 밤 오디오가 아니어야 하며, 저장 시간, 개수, 용량 제한과 삭제 기능을 유지합니다.
- 기본 정책은 이벤트 전 2초, 이벤트 후 3초, 샘플 최대 10초, 세션당 최대 100개, 폴더 최대 200MB입니다.
- 이벤트 샘플 위치는 `Application Support/NightBreath/EventAudioSnippets/`를 사용할 수 있습니다.

## 표현 원칙

앱은 건강 데이터와 수면 소리 데이터를 함께 보여줄 수 있지만, 건강 상태 확정, 의학적 조치 안내, 확정적 인과관계 표현을 사용하지 않습니다.

권장 표현:

- 오늘의 리듬 점수
- 회복 리듬
- 아침 리포트
- 하루 리듬 카드
- 개인 패턴을 살펴보기 위한 참고용 보기
- 데이터가 충분한 날만 함께 표시
- 이 앱은 진단 목적의 의료기기가 아닙니다.

피해야 할 방향:

- 수면 소리 이벤트로 건강 상태를 단정하는 문구
- 혈압, 체중, 체성분 수치를 질병 여부로 해석하는 문구
- 특정 지표가 다른 지표를 변화시켰다고 말하는 문구
- 의학적 조치를 직접 권하는 문구
- 임상 지표처럼 정확도를 보장하는 문구

## 데이터 품질과 권한별 제한

하루 리듬 리포트는 데이터가 완전하다고 가정하지 않습니다.

- 수면 측정 시간이 짧거나 오디오 커버리지가 낮으면 리포트 품질을 제한적으로 표시합니다.
- HealthKit 연결 전에는 mock 미리보기 또는 연결 안내만 보여줍니다.
- HealthKit 권한이 일부만 허용되면 허용된 항목만 보여줍니다.
- Apple 건강앱에 데이터가 없거나 source app 동기화가 늦으면 해당 항목을 비어 있는 상태로 안내합니다.
- 같은 날짜에 여러 건강 지표가 있어도 인과관계 요약을 만들지 않습니다.
- 교차 보기는 충분한 데이터와 안정적인 측정 품질이 있는 날만 참고용으로 표시합니다.

이 제한은 제품의 약점이 아니라 개인정보와 안전한 해석을 지키기 위한 기본 설계 기준입니다.
