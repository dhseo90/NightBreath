# QA Guide

이 문서는 NightBreath / 밤숨의 테스트, simulator QA, 실제 iPhone QA, background recording 확인, HealthKit/Fitdays manual QA 기준을 한곳에 모은 문서입니다.

일상 개발 중에는 unit test와 simulator-first 흐름을 우선합니다. 실제 iPhone QA는 마이크, 화면 잠금, 백그라운드, 배터리/발열, overnight 안정성처럼 simulator가 대체할 수 없는 시점에 수행합니다.

## 빠른 개발 검증

기본 명령:

```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer /usr/bin/xcrun swift test --no-parallel
```

iOS generic build:

```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
xcodebuild \
  -project SleepSoundApp.xcodeproj \
  -scheme SleepSoundApp \
  -configuration Debug \
  -destination generic/platform=iOS \
  -derivedDataPath .derivedData \
  CODE_SIGNING_ALLOWED=NO \
  build
```

주요 회귀 영역:

- audio capture metrics
- synthetic audio source
- dataset replay source
- rule-based detector
- detection smoothing
- event aggregation
- sleep score calculation
- detector diagnostics
- zero-event analysis
- event audio opt-in
- storage stats / orphan cleanup
- Daily Rhythm score / insight / card content
- HealthKit read-only policy
- Fitdays CSV import
- EHM metric catalog / trend / calendar / detail
- privacy copy safety
- simulator QA scenarios

## Simulator QA

Simulator QA는 mock 수면 세션, mock 수면 이벤트, mock NightReport, mock detector diagnostics, mock 이벤트 오디오 저장소 통계를 사용합니다. 실제 오디오 파일을 만들거나 전체 밤 원본 오디오를 저장하지 않습니다.

확인 가능한 항목:

- 홈 화면의 최근 수면 리포트 요약
- 수면 소리 점수 표시
- 측정 품질 표시
- 앱 동작 시간과 실제 오디오 수신 시간 구분
- 주요 이벤트 수와 이벤트 타임라인 표시
- 이벤트 오디오 샘플 저장 ON/OFF 상태
- 저장된 이벤트 오디오 샘플 개수, 시간, 용량 표시
- detector diagnostic summary
- zero-event 분석 문구
- Health/Daily Rhythm mock 화면 상태
- “서버 전송 없음”, “원본 전체 오디오 미저장”, “온디바이스 분석” 안내 문구

확인 불가능한 항목:

- 실제 iPhone 마이크 입력 품질
- 화면 잠금 상태 녹음 유지 여부
- 백그라운드 녹음 유지 여부
- AVAudioSession interruption 처리
- 장시간 overnight 안정성
- 배터리 사용량과 발열
- 실제 이벤트 오디오 샘플 녹음/재생 품질

Simulator preset 예시:

- `QuietNight`
- `SnoreHeavyNight`
- `NoiseHeavyNight`
- `CoughGaspNight`
- `BruxismLikeNight`
- `ZeroEventButGoodAudioCoverage`
- `ZeroEventBecauseNoAudioReceived`
- `LowAudioCoverageNight`
- `EventAudioStorageOff`
- `EventAudioStorageOnWithSamples`
- `OrphanSamplesPresent`

DEBUG 빌드의 `SimulatorScenarioView`에서 preset을 적용하고 주요 화면을 확인합니다. QA 후에는 preset을 해제합니다.

EHM screenshot / 화면 상태 scenario:

- `ScreenshotHealthMetricsOverviewScenario`
- `ScreenshotFitdaysImportScenario`
- `ScreenshotFitdaysImportResultScenario`
- `ScreenshotHealthCalendarScenario`
- `ScreenshotDailyMeasurementDetailScenario`
- `ScreenshotMetricDetailScenario`
- `ScreenshotImportErrorScenario`
- `ScreenshotLocalOnlyMetricScenario`

`SimulatorScenarioView`의 `EHM 화면 상태` section은 DEBUG 전용입니다. 여기에서 HealthKit unavailable, 권한 없음, 일부 권한 허용, 데이터 없음, HealthKit-backed source, Fitdays CSV local-only source, source mixed 상태를 mock/synthetic data로 확인합니다.

## Dataset Replay / Offline Evaluation

Dataset Replay는 실제 마이크 없이 synthetic audio 또는 로컬 오디오 파일을 `AudioChunk` stream으로 변환해 분석 pipeline에 넣는 개발용 구조입니다.

원칙:

- 공개 데이터셋을 자동 다운로드하지 않습니다.
- 공개/개인 오디오 파일을 repo에 커밋하지 않습니다.
- 로컬 파일은 사용자가 직접 준비합니다.
- 최종 실사용 검증은 실제 iPhone에서 별도로 진행합니다.

Offline Evaluation은 manifest에 정의된 로컬 audio segment를 detector profile별로 평가하고 결과를 CSV/JSON으로 저장하는 개발 도구입니다.

용도:

- detector 변경 전후 비교
- conservative / balanced / sensitive profile 비교
- zero-event 원인 비교
- reject reason, raw 후보 수, 최종 이벤트 수 확인
- threshold 변경 후보를 수동 검토용 보고서로 생성

세부 detector/dataset 문서는 `Docs/DETECTOR_TUNING.md`, `Docs/DATASET_REPLAY.md`, `Docs/DATASET_GUIDE.md`, `Docs/DATASET_MANIFEST_GUIDE.md`를 참고합니다.

## 실제 iPhone zero-event diagnostics

실제 iPhone 세션에서 들리는 수면 중 소리가 있었는데 이벤트가 0개로 나온 경우, threshold 변경 전에 다음 값을 캡처합니다. 실제 오디오 파일명, local path, 개인 정보는 기록하지 않습니다.

필수 기록:

- 앱 동작 시간, 실제 오디오 수신 시간, 실제 분석 시간, audio coverage
- `audioChunkCount`, `analyzedChunkCount`
- `rawCandidateCountByType`
- `preSmoothingCandidateCountByType`
- `postSmoothingEventCountByType`
- `finalEventCountByType`
- `snoreRawCandidateCount`, `snoreRejectedCount`, `snoreRejectReasonTop`
- `rejectReasonCounts` top 3
- RMS/energy p50/p90, low-band p50/p90, zero crossing p50, spectral centroid p50
- `thresholdSnapshot`, `activeDetectorBackend`, `tuningProfile`, `modelInstalled`, `fallbackUsed`

DEBUG 확인:

- `AudioDebugView`에서 live RMS / energy, current threshold, last raw candidate, last reject reason을 봅니다.
- raw candidate count by type과 smoothing 전/후 count가 증가하는지 봅니다.
- `DatasetReplayView`에서는 synthetic 또는 사용자가 준비한 로컬 짧은 segment로 같은 pipeline count를 비교합니다.
- 이 과정은 원본 전체 오디오 저장이나 서버 전송 없이 수행합니다.

zero-event 판독:

- 실제 오디오 수신이 거의 없으면 capture/background 문제를 먼저 봅니다.
- audio coverage는 충분하지만 raw 후보가 0개이면 feature scale과 threshold snapshot을 비교합니다.
- raw 후보는 있었지만 post-smoothing이 0이면 confidence/duration/drop reason을 확인합니다.
- `snore` raw 후보가 있었지만 최종 이벤트가 0이면 confidence histogram과 `snoreRejectReasonTop`을 우선 확인합니다.
- user-facing 문구는 “감지 기준을 통과한 이벤트가 없었습니다”, “감지 기준이 보수적으로 동작했을 수 있습니다” 수준으로 유지합니다.

## 실제 iPhone QA가 필요한 경우

다음 변경 또는 확인 시점에는 실제 iPhone QA가 필요합니다.

- 오디오 캡처 코드 변경
- AVAudioSession/background 설정 변경
- 이벤트 오디오 샘플 실제 저장/재생 확인
- 화면 잠금 상태 녹음 확인
- 앱 백그라운드 녹음 확인
- 배터리/발열 확인
- 장시간 overnight 안정성 확인
- HealthKit permission flow 확인
- 실제 Fitdays CSV import 흐름 확인
- 출시 전 smoke test

## 실제 iPhone 준비

1. iPhone을 Mac에 연결하거나 같은 네트워크의 paired 상태로 준비합니다.
2. iPhone 잠금 해제, Trust This Computer, Developer Mode, 개발자 서명을 확인합니다.
3. Xcode에서 `SleepSoundApp.xcodeproj`와 `SleepSoundApp` scheme을 선택합니다.
4. 실제 기기 대상과 signing team을 설정합니다.
5. 앱 실행 전 unit test와 iOS Debug build를 통과시킵니다.

기기 감지 명령:

```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
xcrun devicectl list devices
```

```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
xcrun xctrace list devices
```

`devicectl`에서는 보이지만 `xctrace`에서 offline으로 표시되면 iPhone 잠금 해제, 신뢰 설정, Developer Mode, 케이블/네트워크 연결 상태를 먼저 확인합니다.

## 실제 iPhone Smoke Test

1. 앱 첫 실행
   - 온보딩이 표시되는지 확인합니다.
   - HealthKit 권한 sheet가 자동으로 표시되지 않는지 확인합니다.
   - 마이크 권한은 수면 시작 흐름에서만 요청되는지 확인합니다.
2. Foreground 1분
   - 수면 시작 후 1분 동안 화면을 켠 상태로 둡니다.
   - 경과 시간, 실제 오디오 수신 시간, 커버리지 값이 움직이는지 확인합니다.
   - 수면 종료 후 리포트가 생성되는지 확인합니다.
   - 수면 종료 버튼을 누른 직후 캡처 상태가 `캡처 종료됨`으로 바뀌고 실제 오디오 수신 시간이 더 이상 증가하지 않는지 확인합니다.
   - 리포트 생성이 계속 진행되더라도 화면 문구가 “녹음은 중단되었습니다. 리포트를 정리하는 중입니다.” 계열로 바뀌는지 확인합니다.
   - DEBUG 상태에서 `종료 후 입력 chunk`가 0이거나 매우 작은 값인지 확인합니다.
3. 화면 잠금 3분
   - 수면 시작 후 iPhone을 잠급니다.
   - 3분 후 잠금 해제하고 수신 시간과 interruption count를 확인합니다.
4. 앱 백그라운드 3분
   - 수면 시작 후 홈 화면으로 나갑니다.
   - 3분 후 앱으로 돌아와 캡처 상태와 수신 시간을 확인합니다.
5. 잠금 30분
   - 충전 상태에서 30분 잠금 테스트를 수행합니다.
   - 배터리, 발열, 앱 복귀 상태를 기록합니다.
6. Overnight 후보
   - TestFlight 전 최소 1회 충전 상태 overnight 측정을 수행합니다.
   - 배터리, 발열, 리포트 생성, 저장 용량, 이벤트 오디오 샘플 정책을 확인합니다.

## Background Recording 확인

확인 포인트:

- 앱 세션 시간과 실제 오디오 수신 시간이 분리되어 표시되는지
- 수면 종료 tap 이후 실제 오디오 수신 시간이 더 이상 증가하지 않는지
- stop 이후에도 report finalization은 진행되지만 capture는 이미 멈춘 상태인지
- `chunksReceivedAfterStopRequest`가 0 또는 매우 작은 값인지
- stop timeout safety가 발생했다면 force stop reason이 detector diagnostics note 또는 DEBUG lifecycle log에 남는지
- 잠금/백그라운드 이후에도 수신 시간이 합리적으로 증가하는지
- interruption count와 longest gap이 기록되는지
- 낮은 오디오 커버리지 상태가 안전하게 표시되는지
- 앱이 crash하지 않고 리포트 생성까지 이어지는지

Simulator 결과가 좋아도 실제 iPhone의 background audio 정책, 발열, 배터리, 마이크 입력 품질은 별도 확인해야 합니다.

## HealthKit Read-Only QA

1. 앱 첫 실행과 수면 시작에서 HealthKit 권한 sheet가 표시되지 않는지 확인합니다.
2. `HealthDashboardView`에서 사용자가 건강 데이터 연결을 선택할 때만 권한 sheet가 표시되는지 확인합니다.
3. 전체 허용, 일부 허용, 거부, 데이터 없음 상태를 가능한 범위에서 확인합니다.
4. 혈압, 체중, 체성분, 활동 지표가 sourceName과 측정 시각을 함께 표시하는지 확인합니다.
5. HealthKit-backed metric과 Fitdays local-only metric이 badge와 설명으로 구분되는지 확인합니다.
6. 앱이 HealthKit에 데이터를 쓰지 않는지 코드 scan과 실제 동작으로 확인합니다.
7. 수면 기능은 HealthKit 권한 거부 후에도 정상 동작해야 합니다.

Simulator-first mock state 확인:

| 상태 | 확인 화면 | 기대 표시 |
| --- | --- | --- |
| HealthKit unavailable | `HealthDashboardView(DisabledHealthKitService)` | 건강 데이터 읽기를 사용할 수 없다는 안내, 샘플 없음 |
| 권한 없음 | `HealthMetricsOverviewView(permissionState: .denied)` | 로컬 import 샘플은 볼 수 있다는 안내 |
| 일부 권한 허용 | `HealthMetricsOverviewView(permissionState: .readRequestCompleted)` | 허용된 metric 샘플만 표시 |
| 데이터 없음 | `HealthMetricsOverviewView(samples: [])` | empty state와 연결/import 안내 |
| 데이터 있음 | mock HealthKit-backed samples | sourceName, 측정 시각, 기간별 통계 표시 |
| Fitdays CSV local-only | synthetic Fitdays samples | Local-only badge와 Fitdays CSV source 표시 |
| source mixed | HealthKit-backed + Fitdays CSV + app computed samples | source별 breakdown과 raw sample list 구분 |

기록 시 실제 수치 대신 다음처럼 요약합니다.

```text
HealthKit permission: allowed / denied / partial
Metrics visible: blood pressure / body mass / body fat / activity
Source labels visible: yes / no
Write attempt observed: no
Server transfer observed: no
```

## Fitdays CSV Import QA

Fitdays 공식 문서상 Progress Report, History Records, Data Reports, data export request 경로에서 CSV 또는 CSV-compatible structured export 가능성이 있습니다. 실제 앱 메뉴명은 앱 버전, 지역, Fitdays/Fitdays+ 차이, 로그인 상태에 따라 달라질 수 있으므로 QA 기록에서는 확인한 메뉴명을 private note에만 남기고 repository에는 실제 파일명/path/값을 기록하지 않습니다.

1. 실제 개인 CSV 또는 structured export file은 repository 밖에 둡니다.
2. screenshot이나 public review에는 synthetic CSV만 사용합니다.
3. Reports / Data Reports / Chart / History Records / More Data에서 Share / Export 버튼과 CSV format 선택지를 확인합니다.
4. Files / iCloud Drive / AirDrop / Mail 등으로 로컬 파일을 저장할 수 있는지 확인합니다.
5. CSV가 보이지 않으면 Account / Export My Data / Customer Service Center 경로를 확인합니다.
6. 그래도 export 파일을 확보할 수 없으면 Apple 건강앱 read-only 표준 지표만 사용하고, Fitdays 고유 지표는 manual input follow-up으로 남깁니다.
7. 사용자가 명시적으로 파일을 선택할 때만 import가 시작되는지 확인합니다.
8. valid CSV에서 preview, result, sample count, skipped row, unknown column이 표시되는지 확인합니다.
9. invalid date/time row가 앱을 멈추지 않고 skipped row로 처리되는지 확인합니다.
10. localized column name, 단위 suffix, 날짜/시간 형식 차이가 flexible mapping으로 처리되는지 확인합니다.
11. HealthKit 표준 지표가 CSV에 있어도 `sourceType == fitdaysCSV`로 보이는지 확인합니다.
12. Fitdays 확장 지표는 HealthKit-backed가 아니라 local-only로 설명되는지 확인합니다.
13. import batch 삭제 흐름이 있으면 sample도 함께 사라지는지 확인합니다.
14. Files 앱에서 `.csv` 또는 `.txt` synthetic export file을 NightBreath로 열었을 때 Fitdays import preview sheet로 연결되는지 확인합니다.
15. unsupported extension 또는 structured export로 해석할 수 없는 text file은 저장 전에 거부되는지 확인합니다.
16. Open in flow에서도 실제 local path가 UI나 screenshot에 표시되지 않는지 확인합니다.
17. Fitdays 로그인, 서버/API 직접 연결, 자동 동기화, 비공식 연결 방식이 추가되지 않았는지 확인합니다.

기록 시 실제 파일명과 실제 수치를 적지 않습니다.

```text
Export type: private Fitdays CSV or structured export / synthetic fixture
App path checked: Reports / Data Reports / Chart / History Records / More Data / Customer Service Center
NightBreath entry point: file picker / Open in NightBreath / Apple Health read-only fallback
Fallback used: CSV export / data request / Apple Health read-only / manual follow-up
Rows parsed:
Samples created:
Skipped rows:
Unknown columns:
Local-only metric visible: yes / no
Actual file name recorded in repo: no
Actual path recorded in screenshot: no
Share Extension used: no
```

## Event Audio Sample QA

1. 기본값 OFF에서 새 이벤트 오디오 샘플이 저장되지 않는지 확인합니다.
2. 사용자가 opt-in을 켠 경우에만 짧은 이벤트 전후 샘플이 저장되는지 확인합니다.
3. 저장 샘플은 전체 밤 오디오가 아닌지 확인합니다.
4. 개별 삭제, 전체 삭제, orphan cleanup이 동작하는지 확인합니다.
5. 저장소 통계가 앱 재실행 후에도 일관적인지 확인합니다.

## QA 세션 기록 템플릿

아래 내용은 private QA note에 기록하고, repository에는 민감 값이나 실제 파일명을 넣지 않습니다.

```text
Date:
Tester:
Commit:
iPhone model:
iOS version:
Build configuration:
Signing team:

Microphone permission:
HealthKit permission scenario:
Fitdays import scenario:
Event audio sample setting:

Result summary:
Blocking issue:
Follow-up issue:
Evidence location:
Sensitive data included in repo: No
```

## Blocking 기준

다음은 release/TestFlight 전 blocking으로 취급합니다.

- 앱 첫 실행에서 HealthKit 권한 sheet가 자동 표시됨
- HealthKit write 대상이 비어 있지 않음
- Fitdays 서버/API 연결 또는 비공식 연결 시도
- 실제 개인 CSV, 건강 데이터, 오디오 파일이 repository에 추가됨
- 전체 밤 원본 오디오 파일 생성
- 마이크 권한 거부 또는 HealthKit 권한 거부 시 앱 crash
- 의료 판단이나 인과관계처럼 읽히는 사용자-facing 문구
