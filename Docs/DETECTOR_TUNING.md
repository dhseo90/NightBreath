# Detector Tuning Guide

이 문서는 NightBreath / 밤숨의 rule-based detector threshold/profile을 Offline Evaluation 결과로 비교하고, 수동 검토용 변경 후보를 만드는 절차를 설명합니다.

## 원칙

- threshold는 자동으로 변경하지 않습니다.
- `suggested_changes.json`은 수동 검토용입니다.
- false positive-like 이벤트가 늘어날 위험을 항상 함께 봅니다.
- Release 기본 profile은 `balanced`입니다.
- `conservative`는 크게 바꾸지 않고, `balanced`는 충분한 baseline 근거가 있을 때만 보수적으로 조정합니다.
- `sensitive`는 DEBUG/비교용으로 더 민감하게 둘 수 있지만 Release 기본값으로 바로 올리지 않습니다.
- 공개/개인 오디오 파일은 repo에 넣지 않습니다.
- 서버 전송, 클라우드 처리, 외부 API 호출은 사용하지 않습니다.
- 이 비교는 detector 개발용이며 의학적 성능 검증이 아닙니다.

## 현재 Profile 상태

`DetectorTuningProfile.releaseDefault`는 `balanced`입니다. DEBUG 선택 profile은 `conservative`, `balanced`, `sensitive`를 유지합니다.

| Profile | 용도 | snore RMS | snore energy | minimum confidence | minimum duration | merge gap |
| --- | --- | ---: | ---: | ---: | ---: | ---: |
| conservative | 더 신중한 후보 확인용 | 0.060 | 0.0036 | 0.42 | 0.30s | 0.80s |
| balanced | Release 기본값 | 0.045 | 0.0020 | 0.35 | 0.20s | 1.00s |
| sensitive | DEBUG 누락 비교용 | 0.040 | 0.0016 | 0.32 | 0.16s | 1.20s |

현재 값은 `RuleBasedDetectionThresholds`와 `DetectionSmoothingPolicy`로 전달되고, diagnostics의 `thresholdSnapshot`에 `tuning.*` key로 저장됩니다. `balanced`의 낮은 RMS 구간은 별도 texture guard를 통과해야 합니다. RMS 0.050 미만 코골기 후보는 low-band 0.58 이상, zero-crossing 0.28 이하, high-band 0.22 이하, spectral centroid 1200Hz 이하 조건을 함께 만족해야 raw snore 후보가 됩니다.

## 실제 iPhone zero-event triage

실제 현장에서 코골기가 들렸는데 리포트 이벤트가 0개인 경우에도 threshold를 바로 낮추지 않습니다. 먼저 세션의 `DetectorDiagnostics`를 보고 capture → feature → raw candidate → smoothing → final event → report aggregation 중 어디에서 후보가 사라졌는지 분리합니다.

확인 순서:

1. `audioChunkCount`, `analyzedChunkCount`, `receivedAudioSeconds`, `analyzedAudioSeconds`, `audioCoverageRatio`로 실제 입력과 분석 시간이 충분했는지 확인합니다.
2. `rmsSummary`, `energySummary`, `lowBandEnergySummary`, `zeroCrossingRateSummary`, `spectralCentroidSummary`의 p50/p90 값을 threshold snapshot과 비교합니다.
3. `snoreLikeFeatureCandidateCount`와 `snoreLikeFeatureRejectReasonCounts`로 feature 단계의 코골기 유사 신호가 raw 후보 전 단계에서 제외되었는지 확인합니다.
4. `rawCandidateCountByType`에서 `snore` 후보가 올라왔는지 확인합니다.
5. `preSmoothingCandidateCountByType`와 `postSmoothingEventCountByType`를 비교해 raw 후보가 smoothing 단계에서 사라졌는지 봅니다.
6. `finalEventCountByType`와 리포트 이벤트 집계가 같은지 확인합니다.
7. `rejectedCountByReason`, `snoreRejectedCount`, `snoreRejectReasonTop`으로 confidence, duration, low-band ratio, 환경 소음 후보 영향 중 어떤 이유가 큰지 확인합니다.
8. `latestFeatureDebugSummary`, `latestRawCandidateDebugSummary`, `detectorBackend`, `tuningProfile`, `modelInstalled`, `modelFallbackCount`, `fallbackUsed`를 함께 기록합니다.

zero-event 해석 문구는 다음 범위를 넘지 않습니다.

- “오디오 입력은 수신되었지만 detector 기준을 통과한 이벤트가 없었습니다.”
- “감지 기준이 보수적으로 동작했을 수 있습니다.”
- “측정 환경이나 iPhone 배치 영향을 받을 수 있습니다.”

이 문구는 수면 중 소리 기반 detector 상태를 설명하기 위한 것이며 건강 상태를 확정하지 않습니다.

threshold 후보는 feature 후보, raw 후보, smoothing drop, report aggregation 중 어느 단계에서 누락이 발생했는지 분리한 뒤에만 검토합니다. 이 문서의 triage만으로 Release 기본 threshold를 바로 낮추지 않습니다.

## 2026-05-05 로컬 zero-event recall 검토

이번 로컬 검토에서는 실제 개인 오디오 파일이나 실제 iPhone 샘플을 repository에 넣지 않았습니다. 현재 workspace에서 확인 가능한 자료는 detector diagnostics 경로, 짧은 local sample/replay 경로, synthetic regression뿐이므로 실제 세션의 최종 원인은 다음 실제 iPhone DEBUG 샘플 또는 diagnostics snapshot으로 확정해야 합니다.

현재 분류:

| 단계 | 로컬 확인 결과 |
| --- | --- |
| capture | stop lifecycle와 실제 오디오 수신 시간 diagnostics는 준비되어 있습니다. 이번 작업에는 실제 iPhone 원본 세션 snapshot이 없었습니다. |
| feature | RMS/energy/low-band/ZCR/centroid 분포를 남기는 collector와 DEBUG/Replay 표시가 준비되어 있습니다. |
| raw candidate | synthetic low-amplitude snore-like sample은 기존 balanced RMS 0.050 경계에서 raw 후보 0개가 될 수 있는 병목을 재현했습니다. |
| smoothing | 1초 이상 snore-like 후보는 balanced smoothing을 통과하도록 regression test를 추가했습니다. |
| final/report | 최종 snore 이벤트가 `NightReport.snoreTotalSeconds`와 `SleepReportView`에 연결되는 contract를 테스트했습니다. |
| UI | zero-event 문구는 detector 기준을 통과한 이벤트가 없었다는 설명과 diagnostics 분리 표시를 유지합니다. |
| backend | Release 기본 profile은 계속 `balanced`이며, `sensitive`는 DEBUG 비교용으로 유지합니다. |

적용한 보정:

- `balanced` snore RMS를 0.050에서 0.045로 작게 완화했습니다.
- `balanced` snore energy snapshot을 0.0025에서 0.0020으로 맞췄습니다.
- RMS 0.050 미만 구간에는 low-band/ZCR/high-band/centroid guard를 추가해 pure silence, quiet/high-frequency negative, broadband-like noise가 snore로 올라오지 않게 했습니다.
- smoothing threshold와 Release 기본 profile 선택은 바꾸지 않았습니다.

False-positive-like guard:

- `silence`, `lowEnergyNoise`, high-frequency synthetic negative는 최종 snore 이벤트를 만들지 않아야 합니다.
- Offline Evaluation support test는 balanced profile에서 low-amplitude snore-like segment는 final snore로 남기고 high-frequency negative segment는 snore raw/final count 0을 유지하는지 확인합니다.

## 2026-05-03 이전 로컬 Report 판독

2026-05-03 로컬 `Tools/OfflineEvaluation/output/tuning_report.md`와 `offline_evaluation_20260503_030614.json`을 확인했습니다.

- 입력 profile: `balanced`만 포함
- evaluated records: 2
- failed records: 2
- 실패 이유: manifest가 가리키는 로컬 오디오 파일 없음
- raw candidates: 0
- final events: 0
- possible false-positive-like: 0
- possible false-negative-like: 0
- 기존 `suggested_changes.json`: 변경 제안 없음

이 결과는 detector threshold를 평가한 데이터가 아니라 missing file 검증 결과에 가깝습니다. 따라서 threshold 코드는 변경하지 않았습니다.

다음 threshold 검토에 필요한 최소 데이터:

- 실제 존재하는 로컬 오디오 segment가 있는 manifest
- `snore`, `silence` 또는 `unknown`, `environmentalNoise` segment가 함께 포함된 baseline
- `conservative`, `balanced`, `sensitive` 세 profile 모두 실행한 `OfflineEvaluation` 또는 `OfflineSnoreBaseline` 결과
- missing file/failed record가 아닌 정상 analyzed record
- false positive-like 증가 여부를 볼 수 있는 quiet/noise negative segment

실제 iPhone에서 들린 코골이 상황은 전체 밤 오디오 저장 대신 2초/3초/5초 DEBUG 샘플로 분리합니다. 같은 배치에서 `snore` expected segment와 `silence`/`unknown`/`environmentalNoise` negative segment를 함께 준비해야 threshold 완화 후보의 부작용을 볼 수 있습니다. 샘플과 manifest는 local-only이며, threshold 변경은 이 결과만으로 자동 적용하지 않습니다.

## 1. Offline Evaluation 실행

먼저 manifest에 정의된 로컬 오디오 segment를 profile별로 평가합니다.

```bash
swift run OfflineEvaluation \
  --manifest Tools/OfflineEvaluation/sample_manifest.example.json \
  --output Tools/OfflineEvaluation/output \
  --profiles conservative,balanced,sensitive
```

결과는 다음 위치에 생성됩니다.

- `Tools/OfflineEvaluation/output/offline_evaluation_YYYYMMDD_HHMMSS.json`
- `Tools/OfflineEvaluation/output/offline_evaluation_YYYYMMDD_HHMMSS.csv`

`output/`은 gitignore 대상입니다.

## 2. Profile 비교 실행

생성된 JSON을 입력으로 profile 비교 도구를 실행합니다.

```bash
swift run OfflineProfileCompare \
  --input Tools/OfflineEvaluation/output/offline_evaluation_YYYYMMDD_HHMMSS.json \
  --output Tools/OfflineEvaluation/output
```

여러 evaluation 결과를 합쳐 비교할 수도 있습니다.

```bash
swift run OfflineProfileCompare \
  --inputs file1.json,file2.json \
  --output Tools/OfflineEvaluation/output
```

생성 파일:

- `Tools/OfflineEvaluation/output/tuning_report.md`
- `Tools/OfflineEvaluation/output/suggested_changes.json`

## 2-1. Snore Baseline 실행

코골기 detector만 더 자세히 볼 때는 Snore Baseline 도구를 함께 실행합니다.

```bash
swift run OfflineSnoreBaseline \
  --manifest Tools/OfflineEvaluation/sample_manifest.example.json \
  --output Tools/OfflineEvaluation/output \
  --profiles conservative,balanced,sensitive
```

생성 파일:

- `Tools/OfflineEvaluation/output/snore_baseline_YYYYMMDD_HHMMSS.json`
- `Tools/OfflineEvaluation/output/snore_baseline_YYYYMMDD_HHMMSS.csv`
- `Tools/OfflineEvaluation/output/snore_baseline_report.md`

이 report에서 `finalSnoreEventCount`, `zeroEventCount`, `possibleFalsePositive`, `possibleFalseNegative`, `confidenceSummary`를 함께 봅니다.

## 3. 비교 항목

profile별로 다음 값을 비교합니다.

- total evaluated segments
- raw candidate count
- pre-smoothing candidate count
- post-smoothing event count
- final event count by type
- zero-event count
- top reject reasons
- average confidence
- possible false-positive-like cases
- possible false-negative-like cases

## 4. expectedLabels 기반 mismatch 해석

manifest에 `expectedLabels`가 있으면 도구가 간단한 mismatch 후보를 표시합니다.

- expected label에 `snore`가 있는데 최종 `snore` 이벤트가 없으면 possible false-negative-like로 표시합니다.
- expected label이 `unknown`, `silence`, `quiet` 계열인데 이벤트가 생성되면 possible false-positive-like로 표시합니다.

이 값은 개발용 참고 지표입니다. 데이터셋 라벨 품질과 iPhone 마이크 특성 차이를 함께 봐야 합니다.

## 5. Threshold 제안 방식

도구는 다음과 같은 경우 수동 검토 후보를 만듭니다.

- balanced에서 zero-event가 많고 expected event가 누락되는 경우
- sensitive에서 후보는 늘지만 quiet/unknown segment 이벤트가 과도하게 늘어나는 경우
- conservative에서 raw 후보가 거의 없고 zero-event가 많은 경우

제안 파일에는 다음이 포함됩니다.

- profile
- thresholdName
- currentValue
- suggestedDirection
- reason
- falsePositiveRisk

중요: 이 파일은 코드에 자동 반영되지 않습니다. `DetectorThresholdConfiguration` 값은 개발자가 직접 검토한 뒤 별도 변경해야 합니다.

## 5-1. 적용 판단 기록

당시 판독에서는 threshold 변경을 적용하지 않았습니다.

| 항목 | 판단 |
| --- | --- |
| zero-event 과다 여부 | 평가 record가 모두 missing file 실패라 판단 불가 |
| raw candidate 대비 final event 부족 | 정상 분석 record가 없어 판단 불가 |
| belowConfidenceThreshold reject 과다 | reject reason 없음 |
| tooShort reject 과다 | reject reason 없음 |
| environmentalNoise false-positive-like | 정상 quiet/noise 분석 record가 없어 판단 불가 |
| snore expected missed case | snore label segment가 missing file 실패라 판단 불가 |

보수적 적용 원칙상, false positive-like 위험을 추정할 수 없는 상태에서는 `balanced` threshold를 낮추지 않습니다.

## 6. 실제 iPhone 검증이 필요한 항목

Offline Evaluation은 detector 변경 전후 비교에 유용하지만 아래 항목은 대체하지 못합니다.

- 실제 iPhone 마이크 입력
- 화면 잠금 상태 오디오 수신
- 앱 백그라운드 상태 오디오 수신
- 배터리와 발열
- 전화/알림/interruption
- 기기 배치와 침대 주변 환경
- overnight 안정성

threshold 후보를 Release 기본값으로 바꾸기 전에는 짧은 foreground 테스트, 잠금 3분 테스트, 백그라운드 3분 테스트, overnight 테스트 순서로 확인합니다.

## 7. 권장 반복 흐름

1. labeled segment를 manifest에 추가합니다.
2. `OfflineEvaluation`을 conservative/balanced/sensitive로 실행합니다.
3. `OfflineProfileCompare`로 `tuning_report.md`와 `suggested_changes.json`을 생성합니다.
4. possible false-positive-like와 possible false-negative-like를 함께 확인합니다.
5. 작은 threshold 변경 후보만 수동으로 검토합니다.
6. synthetic regression test와 Offline Evaluation을 다시 실행합니다.
7. 실제 iPhone에서 짧은 테스트 후 overnight 테스트로 넘어갑니다.
