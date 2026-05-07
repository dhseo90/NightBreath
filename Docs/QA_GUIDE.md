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
- Daily Rhythm data readiness / missing input explanation
- HealthKit read-only policy
- Fitdays CSV import
- EHM metric catalog / trend / calendar / detail
- Cross Metric matched sample / low audio coverage edge states
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
- Morning Brief와 Daily Rhythm Report의 준비된 입력/제한 항목 상태
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

Event audio snippet safeguard 확인:

- 기본값 OFF에서 새 샘플이 저장되지 않아야 합니다.
- ON 상태에서도 이벤트 전 2초/후 3초, 최대 10초 샘플만 로컬에 저장되어야 합니다.
- 세션당 최대 개수는 다른 세션의 기존 샘플 때문에 막히면 안 됩니다.
- 새 샘플 저장 후 폴더 용량 제한을 넘으면 새 파일이 제거되고 저장 실패로 처리되어야 합니다.
- 연결되지 않은 샘플 정리는 orphan만 삭제하고 연결된 이벤트 샘플은 유지해야 합니다.

EHM screenshot / 화면 상태 scenario:

- `ScreenshotHealthMetricsOverviewScenario`
- `ScreenshotFitdaysImportScenario`
- `ScreenshotFitdaysImportResultScenario`
- `ScreenshotHealthCalendarScenario`
- `ScreenshotDailyMeasurementDetailScenario`
- `ScreenshotMetricDetailScenario`
- `ScreenshotImportErrorScenario`
- `ScreenshotLocalOnlyMetricScenario`

`SimulatorScenarioView`의 `EHM 화면 상태` section은 DEBUG 전용입니다. 여기에서 HealthKit 사용 불가, 권한 없음, 일부 권한 허용, 데이터 없음, HealthKit 기반 출처, Fitdays CSV 로컬 전용 출처, 출처 혼합 상태를 mock/synthetic data로 확인합니다.

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
- verySensitive / sensitive / balanced / conservative / veryConservative profile 비교
- zero-event 원인 비교
- reject reason, raw 후보 수, 최종 이벤트 수 확인
- threshold 변경 후보를 수동 검토용 보고서로 생성

`OfflineProfileCompare`의 `tuning_report.md`에서는 Quick Comparison, Recall / Risk Matrix, Snore / Negative Snapshot, Delta From Balanced, Zero Event Stage Breakdown을 순서대로 확인합니다. 특히 Snore / Negative Snapshot은 expected snore hit와 silence/unknown/environmentalNoise negative segment의 final snore 발생률을 함께 보여주므로, 민감 profile에서 누락이 줄어도 소음 구간 코골기 오탐 위험이 늘었는지 먼저 확인합니다.

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
- `snoreLikeFeatureCandidateCount`, `snoreLikeFeatureRejectedCount`, `snoreLikeFeatureRejectReasonCounts`
- `snoreRawCandidateCount`, `snoreRejectedCount`, `snoreRejectReasonTop`
- `rejectReasonCounts` top 3
- RMS/energy p50/p90, low-band p50/p90, zero crossing p50, spectral centroid p50
- `inputLevelAssessment`
- `thresholdSnapshot`, `activeDetectorBackend`, `tuningProfile`, `modelInstalled`, `fallbackUsed`
- `latestFeatureDebugSummary`, `latestRawCandidateDebugSummary`

DEBUG 확인:

- `AudioDebugView`에서 live RMS / energy, current threshold, last raw candidate, last reject reason을 봅니다.
- feature 분포 p50/p90, 코골기 feature 후보/제외 수, raw candidate count by type과 smoothing 전/후 count가 증가하는지 봅니다.
- `DatasetReplayView`에서는 synthetic 또는 사용자가 준비한 로컬 짧은 segment로 같은 pipeline count를 비교합니다.
- DEBUG의 `SleepReportView`, `DetectorTuningView`, `DatasetReplayView`에서 `QA readout 공유`를 눌러 detector diagnostics 텍스트를 private QA note에 붙여 넣을 수 있습니다.
- 이 과정은 원본 전체 오디오 저장이나 서버 전송 없이 수행합니다.
- QA readout에는 원본 오디오, 이벤트 오디오 파일 경로, 개인 오디오 파일 경로를 포함하지 않습니다.

zero-event 판독:

- 실제 오디오 수신이 거의 없으면 capture/background 문제를 먼저 봅니다.
- audio coverage는 충분하지만 `inputLevelAssessment == goodCoverageLowInputLevel`이면 detector 민감도를 더 올리기 전에 iPhone 거리, 마이크 방향, 케이스/침구 가림을 먼저 확인합니다.
- audio coverage는 충분하지만 코골기 feature 후보와 raw 후보가 모두 0개이면 feature scale과 threshold snapshot을 비교합니다.
- 코골기 feature 후보는 있었지만 raw 후보가 0개이면 `snoreLikeFeatureRejectReasonCounts`와 `latestFeatureDebugSummary`를 확인합니다.
- raw 후보는 있었지만 post-smoothing이 0이면 confidence/duration/drop reason을 확인합니다.
- `snore` raw 후보가 있었지만 최종 이벤트가 0이면 confidence histogram과 `snoreRejectReasonTop`을 우선 확인합니다.
- user-facing 문구는 “감지 기준을 통과한 이벤트가 없었습니다”, “감지 기준이 보수적으로 동작했을 수 있습니다” 수준으로 유지합니다.

## 실제 코골이 짧은 샘플 디버깅

실제 코골이 소리가 있었지만 리포트 이벤트가 0개인 경우, 전체 밤 원본 오디오 저장을 만들지 않고 짧은 local debug sample로만 원인을 좁힙니다.

수집 원칙:

- DEBUG 빌드의 `SampleCaptureView`에서 사용자가 직접 누른 2초/3초/5초 샘플만 저장합니다.
- 저장 위치는 앱 sandbox의 `Documents/Samples/Personal/`이며, repo에 복사할 때도 `Samples/Personal/` 또는 repo 밖 gitignore 경로만 사용합니다.
- 파일명에는 이름, 장소, 날짜의 민감한 맥락 같은 개인 정보를 넣지 않습니다.
- sleep talk 내용은 메모나 파일명에 기록하지 않고 텍스트로 변환하지 않습니다.
- 샘플은 detector 개발용 참고 자료이며 의료 검증 자료가 아닙니다.

DEBUG 수집 후 확인:

- 저장 결과에 `.caf`, `.metadata.json`, `.features.csv`가 함께 생성되는지 봅니다.
- `feature summary`에서 RMS/energy, low/mid/high band, zero crossing, spectral centroid를 확인합니다.
- 앱 실행당 샘플 수, 샘플 1개 최대 길이, 폴더 용량, 오래된 샘플 정리 상태를 확인합니다.
- 저장 실패 메시지가 표시되더라도 앱이 crash하지 않아야 합니다.

Replay 연결:

- Mac 또는 simulator에서 `Dataset Replay` 화면의 `파일 선택`으로 짧은 WAV/CAF/M4A 샘플을 선택합니다.
- 화면의 raw 후보 수, 코골기 feature/raw/제외 수, smoothing 전/후 수, RMS/energy p90, 탈락 이유를 기록합니다.
- 같은 파일을 `Tools/OfflineEvaluation/sample_manifest.example.json`을 복사한 manifest의 `localFilePath`로 지정할 수 있습니다.
- `snore` expected segment만 보지 말고 `silence`, `unknown`, `environmentalNoise` 같은 negative segment도 함께 넣어 false-positive-like 위험을 같이 봅니다.

2026-05-05 detector smoke 항목:

- 앱 `설정` 탭 → `측정 준비` → `코골기 감지 민감도`에서 preset이 `많이 민감`, `민감`, `보통`, `둔감`, `많이 둔감` 5단계로 표시되는지 확인합니다.
- Release 기본값인 `보통`/`balanced` profile에서 threshold snapshot의 `tuning.snoreRmsThreshold`가 0.045인지 확인합니다.
- 실제 코골이처럼 들린 짧은 DEBUG 샘플에서 `snoreLikeFeatureCandidateCount`, `snoreRawCandidateCount`, `postSmoothingEventCountByType.snore`, `finalEventCountByType.snore`가 어느 단계에서 0이 되는지 기록합니다.
- 같은 기기 배치에서 조용한 구간 또는 주변 소음 negative sample도 함께 replay해 snore raw/final count가 증가하지 않는지 확인합니다.
- RMS가 `tuning.snoreRmsThreshold` 0.045보다 낮은데 snore 후보가 된 경우 `rule.lowLevelSnoreRMS`, `rule.lowLevelSnoreEnergy`, `rule.lowLevelSnoreLowBandRatio`, `rule.snoreRelativeEnergyRatio`와 low-band p90, zero-crossing p50, high-band p50, spectral centroid p50가 low-amplitude guard에 맞는지 확인합니다.
- 리포트에는 final snore event가 있으면 `코골기 시간`과 timeline에 표시되고, final event가 0이면 zero-event explanation과 diagnostics만 표시되어야 합니다.

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

## P0 Fix 이후 실제 iPhone 짧은 재테스트

이 절차는 P0 stop capture fix와 코골기 zero-event diagnostics/recall 보정 이후 overnight 전에 수행하는 짧은 실제 iPhone smoke test입니다. 실제 개인 오디오 파일, 실제 오디오 파일명, local path, 개인 정보는 repository에 기록하지 않습니다. 테스트는 수동으로 실행하며 자동화하지 않습니다.

결과 기록은 `Docs/REAL_DEVICE_QA_RUNBOOK.md`의 `Result Template`을 우선 사용합니다.
실기기 연결 전에는 같은 문서의 `Preflight Without Device`와 `Evidence Redaction Checklist`를 먼저 확인합니다.

사전 조건:

- 테스트 대상 commit hash를 기록합니다.
- Debug 빌드를 실제 iPhone에 설치합니다.
- 이벤트 오디오 샘플 저장은 필요한 경우에만 사용자가 명시적으로 켭니다.
- 전체 밤 원본 오디오 저장, 서버 전송, HealthKit write가 없는 상태를 유지합니다.
- 결과 문구는 detector 동작과 측정 품질 설명으로만 기록합니다.

### Test 1. Foreground stop smoke

목적: 수면 종료 tap 이후 실제 오디오 캡처가 먼저 멈추는지 확인합니다.

1. 앱을 foreground에 둡니다.
2. `수면 시작`을 탭합니다.
3. 30초 동안 대기하며 실제 오디오 수신 시간이 증가하는지 봅니다.
4. `수면 종료`를 탭합니다.
5. 1~2초 안에 audio chunk 수신이 멈추는지 확인합니다.
6. `chunksReceivedAfterStopRequest`가 0 또는 매우 작은 값인지 기록합니다.
7. 종료 이후 `actual audio received time` 또는 `receivedAudioDuration`이 계속 증가하지 않는지 확인합니다.
8. 리포트 생성은 capture stop 이후 계속 진행될 수 있음을 확인합니다.

통과 기준:

- `captureStopStartedAt`, `audioEngineStoppedAt`, `lastAudioChunkReceivedAt`가 stop tap 직후 순서상 가깝게 남습니다.
- 종료 후 실제 오디오 수신 시간이 계속 증가하지 않습니다.
- 리포트 생성이 늦어져도 캡처 상태는 먼저 종료됩니다.

### Test 2. Double stop tap

목적: stop flow idempotency를 실제 UI에서 확인합니다.

1. `수면 시작`을 탭합니다.
2. 10~30초 뒤 `수면 종료` 버튼을 빠르게 여러 번 탭합니다.
3. 앱 crash가 없는지 확인합니다.
4. 중복 리포트가 생성되지 않는지 확인합니다.
5. stop diagnostics가 한 세션에 일관되게 남는지 확인합니다.

통과 기준:

- duplicate report가 없습니다.
- capture stop은 한 번만 실제 teardown을 완료합니다.
- 추가 tap은 무시되거나 이미 종료 중인 상태로 안전하게 처리됩니다.

### Test 3. Lock/background short stop

목적: 화면 잠금 또는 짧은 background 이후에도 stop tap이 캡처를 즉시 멈추는지 확인합니다.

1. `수면 시작`을 탭합니다.
2. iPhone 화면을 잠그고 3분 대기합니다.
3. 잠금 해제 후 앱으로 복귀합니다.
4. `수면 종료`를 탭합니다.
5. stop 이후 `receivedAudioDuration`이 증가하지 않는지 확인합니다.
6. interruption count, longest audio gap, audio coverage를 함께 기록합니다.

통과 기준:

- 앱 복귀 후 stop tap이 정상 동작합니다.
- stop 이후 실제 오디오 수신 시간 증가가 없습니다.
- force stop path가 발생했다면 reason이 diagnostics에 남고 crash가 없습니다.

### Test 4. Snore signal smoke

목적: 실제 코골기 또는 명확한 코골기 유사 소리에서 detector 경로가 어디까지 진행되는지 확인합니다.

1. 실제 코골기처럼 들리는 짧은 상황 또는 명확한 코골기 유사 소리를 준비합니다.
2. `수면 시작` 후 해당 소리가 들어가는 위치에 iPhone을 둡니다.
3. 30~60초 정도 foreground에서 측정합니다.
4. `수면 종료` 후 detector diagnostics를 확인합니다.
5. `rawCandidateCountByType`, `snoreRawCandidateCount`, `snoreRejectReasonTop`, `postSmoothingEventCountByType`, `finalEventCountByType`를 기록합니다.
6. `rmsP90`, `energyP90`, low-band p90, zero-crossing p50, spectral centroid p50를 threshold snapshot과 비교합니다.

통과 기준:

- final event가 0개여도 raw/reject diagnostics가 남습니다.
- `snore` raw 후보가 있으면 smoothing과 final count를 이어서 확인할 수 있습니다.
- raw 후보가 0개이면 feature scale, low-band, ZCR, threshold snapshot으로 다음 tuning 가설을 세울 수 있습니다.

### Test 5. Zero-event explanation

목적: 이벤트 0개 리포트가 원인을 분해해 설명하는지 확인합니다.

1. 조용한 foreground 짧은 측정 또는 Test 4 결과 중 이벤트 0개 케이스를 엽니다.
2. zero-event 분석이 다음 중 하나로 분류되는지 확인합니다.
   - no audio 또는 audio coverage 부족
   - audio received but no raw candidates
   - snore-like feature 후보가 raw 전 단계에서 제외
   - raw candidates dropped by smoothing
   - conservative threshold 또는 feature scale mismatch 가능성
   - backend fallback 또는 disabled 상태
3. 사용자-facing 문구가 “detector 기준을 통과한 이벤트가 없었습니다”, “감지 기준이 보수적으로 동작했을 수 있습니다”, “측정 환경이나 iPhone 배치 영향을 받을 수 있습니다” 수준을 유지하는지 확인합니다.

통과 기준:

- 이벤트 0개여도 raw/reject/feature diagnostics가 비어 있지 않거나, 입력 부족 사유가 명확합니다.
- 특정 건강 상태를 단정하는 문구가 없습니다.

### Evidence Template

아래 template은 issue, QA note, local memo에 붙여 사용합니다. 실제 개인 오디오 파일명, local path, 실제 대화 내용은 기록하지 않습니다.

```text
commit hash:
device model:
iOS version:
build configuration:
test start time:
test end time:

Test result:
- Foreground stop smoke:
- Double stop tap:
- Lock/background short stop:
- Snore signal smoke:
- Zero-event explanation:

Stop diagnostics:
- stopButtonTappedAt:
- captureStopStartedAt:
- audioEngineStoppedAt:
- lastAudioChunkReceivedAt:
- chunksReceivedAfterStopRequest:
- receivedAudioDurationBeforeStop:
- receivedAudioDurationAfterStop:

Detector diagnostics:
- rawCandidateCountByType:
- postSmoothingEventCountByType:
- finalEventCountByType:
- topRejectReason:
- rmsP90:
- energyP90:

Notes:
- report generation after stop:
- force stop reason, if any:
- detector backend / tuning profile:
- sensitive data included in repo: No
```

### Overnight Gate

Overnight test는 아래 gate를 모두 통과한 뒤에만 수행합니다.

- Foreground stop smoke가 실패하면 overnight 금지.
- Lock/background short stop에서 stop 이후 audio received time이 증가하면 overnight 금지.
- Double stop tap에서 duplicate report 또는 crash가 있으면 overnight 금지.
- Snore signal smoke에서 raw diagnostics가 전혀 없으면 detector 판단용 overnight 금지.
- Detector가 final event를 만들지 못하더라도 raw/reject diagnostics가 남아야 다음 tuning으로 진행합니다.
- Evidence template에 `sensitive data included in repo: No`가 명시되어야 합니다.

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
- stop tap 후 1~2초 안에 chunk 수신이 멈추고, 이후 수신된 chunk는 분석/리포트 입력이 아니라 diagnostics로만 집계되는지
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
5. HealthKit 기반 지표와 Fitdays 로컬 전용 지표가 배지와 설명으로 구분되는지 확인합니다.
6. 앱이 HealthKit에 데이터를 쓰지 않는지 코드 scan과 실제 동작으로 확인합니다.
7. 수면 기능은 HealthKit 권한 거부 후에도 정상 동작해야 합니다.

실기기 permission flow smoke:

1. 앱을 새로 설치하거나 Health 권한을 초기화한 뒤 첫 실행에서 HealthKit sheet가 뜨지 않는지 확인합니다.
2. 수면 시작/종료 smoke를 먼저 실행하고, 이 흐름에서도 HealthKit sheet가 뜨지 않는지 확인합니다.
3. 건강 데이터 대시보드에서 `건강 데이터 연결` 버튼을 누를 때만 HealthKit read 권한 sheet가 표시되는지 확인합니다.
4. 권한 sheet에서 share/write 항목이 없고 read 항목만 보이는지 확인합니다. iOS 표시 항목은 기기/OS/데이터 가용성에 따라 달라질 수 있습니다.
5. 전체 허용 시 허용된 표준 지표가 sourceName과 측정 시각을 포함해 표시되는지 확인합니다.
6. 일부 허용 시 허용하지 않은 항목은 비어 있고, 허용한 항목만 표시되는지 확인합니다.
7. 거부 또는 데이터 없음 상태에서도 수면 소리 기능, Fitdays CSV fallback, mock/empty 화면이 crash 없이 유지되는지 확인합니다.
8. iOS 건강앱 또는 설정의 앱 접근 화면에서 NightBreath가 쓰기 권한을 갖지 않는지 확인합니다.

Simulator-first mock state 확인:

| 상태 | 확인 화면 | 기대 표시 |
| --- | --- | --- |
| HealthKit 사용 불가 | `HealthDashboardView(DisabledHealthKitService)` | 건강 데이터 읽기를 사용할 수 없다는 안내, 샘플 없음 |
| 권한 없음 | `HealthMetricsOverviewView(permissionState: .denied)` | 로컬 가져오기 샘플은 볼 수 있다는 안내 |
| 일부 권한 허용 | `HealthMetricsOverviewView(permissionState: .readRequestCompleted)` | 허용된 지표 샘플만 표시 |
| 데이터 없음 | `HealthMetricsOverviewView(samples: [])` | empty state와 연결/import 안내 |
| 데이터 있음 | mock HealthKit 기반 샘플 | sourceName, 측정 시각, 기간별 통계 표시 |
| Fitdays CSV 로컬 전용 | synthetic Fitdays 샘플 | 로컬 전용 배지와 Fitdays CSV 출처 표시 |
| 출처 혼합 | HealthKit 기반 + Fitdays CSV + 앱 계산 샘플 | 출처별 breakdown과 원본 샘플 목록 구분 |

기록 시 실제 수치 대신 다음처럼 요약합니다.

```text
Commit:
Device model:
iOS version:
Build configuration:
Fresh install or reset permissions: yes / no
HealthKit sheet appeared on first launch: no
HealthKit sheet appeared on sleep start: no
HealthKit sheet appeared after health connect tap: yes / no
HealthKit permission: allowed / denied / partial
Metrics visible: blood pressure / body mass / body fat / activity
Source labels visible: yes / no
Write categories visible: no
Write attempt observed: no
Server transfer observed: no
Sleep flow after denial works: yes / no
Sensitive data included in repo: No
```

Health Dashboard edge-state smoke:

1. 연결 전 상태에서 `데이터 상태`가 예시 미리보기와 Apple 건강앱 read-only 요청 전 상태를 구분하는지 확인합니다.
2. HealthKit 권한 거부 또는 사용할 수 없음 상태에서 로컬 import 샘플이 없으면 empty state가 안전하게 표시되는지 확인합니다.
3. HealthKit 샘플이 없고 Fitdays CSV 로컬 import 샘플만 있을 때 `로컬 import만 표시`, `로컬 import 최근 값`, 전체 건강 지표/건강 캘린더 진입이 유지되는지 확인합니다.
4. HealthKit read-only 샘플과 Fitdays CSV 샘플이 함께 있으면 `Apple 건강앱 + 로컬 import` 상태와 출처별 분리 설명이 표시되는지 확인합니다.
5. 이 화면에서도 HealthKit write, 서버 전송, Fitdays 서버/API 연결, 실제 파일명/local path 노출이 없는지 확인합니다.

## Fitdays CSV Import QA

Fitdays 공식 문서상 Progress Report, History Records, Data Reports, data export request 경로에서 CSV 또는 CSV-compatible structured export 가능성이 있습니다. 2026-05-07 실제 사용 확인에서는 월별 데이터 복사 텍스트를 확보할 수 있는 경로가 확인되었습니다. 실제 앱 메뉴명은 앱 버전, 지역, Fitdays/Fitdays+ 차이, 로그인 상태에 따라 달라질 수 있으므로 QA 기록에서는 확인한 메뉴명을 private note에만 남기고 repository에는 실제 파일명/path/값을 기록하지 않습니다.

실기기 export availability 재확인 smoke:

1. 실제 iPhone에서 Fitdays 앱 버전, 로그인 상태, 지역/언어 설정을 private note에만 기록합니다.
2. Reports / Data Reports / Chart / History Records / More Data / Account / Customer Service Center를 순서대로 확인합니다.
3. Share / Export / Progress Report / Data Report / Export My Data / Personal Data Request처럼 보이는 항목이 있는지 확인합니다.
4. CSV, TSV, text, 월별 데이터 복사, email attachment, Files 저장, iCloud Drive 저장, AirDrop 공유 중 하나라도 가능한지 확인합니다.
5. export가 보이면 실제 파일은 repository 밖에 저장하고, NightBreath에서는 파일 선택, Open in NightBreath preview, 또는 월별 데이터 붙여넣기 preview까지만 확인합니다.
6. export가 보이지 않으면 Fitdays 앱을 더 파고들지 않고 Apple 건강앱 read-only fallback과 향후 로컬 입력 follow-up으로 기록합니다.
7. 이 재확인은 Fitdays 서버/API 연결, 자동 로그인, UI scraping, 비공식 연결 방식, reverse engineering을 만들기 위한 근거로 사용하지 않습니다.

1. 실제 개인 CSV 또는 structured export file은 repository 밖에 둡니다.
2. screenshot이나 public review에는 synthetic CSV만 사용합니다.
3. Reports / Data Reports / Chart / History Records / More Data에서 Share / Export 버튼과 CSV format 선택지를 확인합니다.
4. Files / iCloud Drive / AirDrop / Mail 등으로 로컬 파일을 저장할 수 있는지 확인합니다.
5. CSV가 보이지 않으면 Account / Export My Data / Customer Service Center 경로를 확인합니다.
6. 그래도 export 파일을 확보할 수 없으면 Apple 건강앱 read-only 표준 지표만 사용하고, Fitdays 고유 지표는 manual input follow-up으로 남깁니다.
7. `FitdaysImportView`에 파일이 없어도 괜찮다는 fallback 섹션, CSV/export 메뉴를 찾지 못한 경우의 안내, 건강 데이터 대시보드 진입이 보이는지 확인합니다.
8. 사용자가 명시적으로 파일을 선택하거나 월별 데이터 텍스트를 붙여넣고 미리보기를 눌렀을 때만 import preview가 시작되는지 확인합니다.
9. valid CSV/TSV 또는 월별 데이터 복사 텍스트에서 preview, result, 샘플 개수, skipped row, unknown column이 표시되는지 확인합니다.
10. invalid date/time row가 앱을 멈추지 않고 skipped row로 처리되는지 확인합니다.
11. localized column name, 단위 suffix, 날짜/시간 형식 차이가 flexible mapping으로 처리되는지 확인합니다.
12. HealthKit 표준 지표가 CSV에 있어도 `sourceType == fitdaysCSV`로 보이는지 확인합니다.
13. Fitdays 확장 지표는 HealthKit 기반이 아니라 로컬 전용으로 설명되는지 확인합니다.
14. 저장 후 `저장된 가져오기` 섹션에 기록, 현재 저장소 기준 샘플 수, 처리 row, 건너뜀/오류 count가 표시되는지 확인합니다.
15. 가져오기 기록 삭제를 실행하면 해당 `importBatchId`의 sample도 함께 사라지고 원본 파일명/local path는 UI에 표시되지 않는지 확인합니다.
16. 지표 상세 화면에서 Fitdays CSV 샘플이 `Fitdays CSV · 로컬` badge와 로컬 import 설명으로 표시되고 raw `importBatchId`가 보이지 않는지 확인합니다.
17. `미리보기 판단` 섹션에서 처리한 row, 저장 가능 샘플, 건너뛴 row 해석, 확인 필요 row, 지원하지 않는 column이 구분되는지 확인합니다.
18. Files 앱에서 `.csv`, `.tsv` 또는 `.txt` synthetic export file을 NightBreath로 열었을 때 Fitdays import preview sheet로 연결되는지 확인합니다.
19. `FitdaysImportView`의 `월별 데이터 붙여넣기`에서 `클립보드 붙여넣고 미리보기`를 눌러 synthetic TSV/text table preview가 생성되는지 확인합니다.
20. 직접 입력칸에 붙여넣은 뒤 `입력 내용 미리보기`를 눌러도 같은 preview가 생성되는지 확인합니다.
21. 월 헤더, `5/1 07:20`, `5.2 오후 9:05`, `몸무게`, `수분`, `골격근`, `내장지방등급`, `기초대사`, `체나이`, `비만등급`처럼 실제 복사 텍스트에 가까운 익명화 구조가 sample로 변환되는지 확인합니다.
22. comma-separated 월별 복사 텍스트에서 `짜` date column, `HH:mm yyyy/MM/dd` time-first date, `골격근량 (클릭필수)`, `근육량(클릭필수)`, `기초대사량 (BMR)` header annotation, `체내수분량`, `골질량`, `--` placeholder가 저장 가능한 sample로 처리되거나 빈 metric으로 안전하게 건너뛰는지 확인합니다.
23. 큰 월별 텍스트를 붙여넣었을 때 입력창에는 앞부분만 표시되고, `붙여넣음 · N행 · N자` 상태와 미리보기 progress가 보이는지 확인합니다.
24. 붙여넣기 입력 바로 아래에 저장 전 미리보기와 저장 버튼이 보여, 긴 fallback 안내를 지나치지 않아도 저장할 수 있는지 확인합니다.
25. 저장 버튼을 누른 직후 버튼 근처에 저장 완료 메시지와 처리 시각이 표시되는지 확인합니다.
26. 같은 월 전체 데이터를 다시 붙여넣었을 때 중복 샘플 수, 새 샘플 수, 값이 다른 중복 수가 저장 전 화면에 표시되는지 확인합니다.
27. 값이 다른 중복이 있으면 `값이 다른 중복은 새 붙여넣기 기준으로 교체` 선택 전에는 저장 버튼이 비활성 또는 저장 차단되는지 확인합니다.
28. 중복 교체 저장 후 같은 metric과 측정시각의 기존 샘플이 중복으로 남지 않고 최신 import 값 하나만 남는지 확인합니다.
29. 빈 붙여넣기, unsupported extension 또는 structured export로 해석할 수 없는 text file은 저장 전에 거부되는지 확인합니다.
30. 측정일 column은 있지만 지원 지표 column이 없는 text file은 저장 전에 거부되는지 확인합니다.
31. 지원 지표 column은 있지만 import 가능한 sample이 0개인 file은 저장되지 않는지 확인합니다.
32. Open in flow와 붙여넣기 flow에서도 실제 local path가 UI나 screenshot에 표시되지 않는지 확인합니다.
33. Fitdays 로그인, 서버/API 직접 연결, 자동 동기화, 비공식 연결 방식이 추가되지 않았는지 확인합니다.

기록 시 실제 파일명과 실제 수치를 적지 않습니다.

## Health Dashboard / Graph QA

1. 건강 데이터 연결 후 Apple 건강앱 read-only 상태 메시지가 최근 1년 범위임을 설명하는지 확인합니다.
2. 4월처럼 이전 달 데이터가 비어 있으면 앱이 먼저 항목별 권한, Apple 건강앱 실제 샘플, 원본 앱의 Apple 건강앱 동기화 상태를 확인하라고 안내하는지 확인합니다.
3. 한 번 건강 데이터 연결을 완료한 뒤 앱을 재실행하거나 업데이트한 상태에서 건강 대시보드 진입 시 permission sheet 없이 HealthKit sample을 다시 읽는지 확인합니다.
4. `HealthKit 읽기 결과`가 전체 sample count와 가장 오래된 날짜/최신 날짜를 표시하는지 확인합니다.
5. `혈압 HealthKit 샘플`이 혈압 sample count와 날짜 범위를 표시하는지 확인합니다. 0개이면 혈압 항목별 권한과 원본 앱의 Apple 건강앱 동기화를 확인합니다.
6. Fitdays 로컬 import가 있는 상태에서 HealthKit 미연결 preview sample이 건강 캘린더에 실제 Apple 데이터처럼 섞이지 않는지 확인합니다.
7. 홈 화면의 `건강 기록 바로가기`에서 최근 건강 기록 상세와 건강 캘린더로 바로 이동할 수 있는지 확인합니다. 이 바로가기를 누르는 과정에서 HealthKit 권한 sheet가 새로 뜨면 안 됩니다.
8. 건강 캘린더에서 날짜를 선택하면 별도 `이 날짜 자세히 보기` tap 없이 같은 화면 아래에 선택 날짜 상세가 바로 펼쳐지는지 확인합니다.
9. 건강 캘린더에서 이전/다음 달을 여러 번 눌러도 셀 표시, 선택 날짜 패널, inline 상세가 눈에 띄게 늦지 않은지 확인합니다.
10. 그래프에 평균선, 최근값, 평균, 범위, 출처별 색상 범례가 표시되는지 확인합니다.
11. 그래프와 캘린더 copy가 건강 상태를 단정하거나 치료/진단 표현을 사용하지 않는지 확인합니다.

```text
Export type: private Fitdays CSV or structured export / synthetic fixture
App path checked: Reports / Data Reports / Chart / History Records / More Data / Customer Service Center
NightBreath entry point: file picker / Open in NightBreath / pasted monthly text / Apple Health read-only fallback
Fallback used: CSV export / monthly text copy / data request / Apple Health read-only / manual follow-up
Export menu visible: yes / no
Monthly text copy visible: yes / no
Fitdays app version recorded in repo: no
Fitdays account/login details recorded in repo: no
If no export menu: Apple Health read-only fallback / manual input follow-up
Rows parsed:
Samples created:
Skipped rows:
Unknown columns:
Duplicate samples:
Changed duplicate samples:
Duplicate overwrite explicitly confirmed: yes / no
로컬 전용 지표 표시: yes / no
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
