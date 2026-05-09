# NightBreath Feature Validation

Feature Validation은 실제 Core ML 모델을 붙이기 전에 현재 `AudioFeatureExtractor`와 `RuleBasedSleepEventDetector`가 어떤 값을 만들고 어떤 후보를 내는지 확인하기 위한 개발용 절차입니다.

## 현재 feature 목록

`AudioFeatures`는 다음 값을 제공합니다.

- `timestamp`
- `duration`
- `rms`
- `energy`
- `peak`
- `zeroCrossingRate`
- `spectralCentroid`
- `lowBandEnergy`
- `midBandEnergy`
- `highBandEnergy`
- `estimatedNoiseLevel`
- `isLikelySilence`
- `debugSummary`

호환용 alias:

- `startedAt`
- `endedAt`
- `lowFrequencyEnergyRatio`
- `highFrequencyActivity`

## feature 계산 방식

- `rms`: sample 평균 제곱근입니다.
- `energy`: sample 평균 제곱값입니다.
- `zeroCrossingRate`: 인접 sample의 부호 변화 비율입니다.
- `spectralCentroid`: 작은 DFT window에서 추정한 주파수 중심입니다.
- `lowBandEnergy`: 300 Hz 미만 대역의 정규화된 에너지 비율입니다.
- `midBandEnergy`: 300 Hz 이상 2,000 Hz 미만 대역의 정규화된 에너지 비율입니다.
- `highBandEnergy`: 2,000 Hz 이상 대역의 정규화된 에너지 비율입니다.
- `estimatedNoiseLevel`: RMS, zero crossing, high band 값을 조합한 개발용 소음 level 추정값입니다.
- `isLikelySilence`: 낮은 RMS 기반의 무음/저에너지 후보 표시입니다.

이 값들은 rule-based detector 튜닝과 이후 모델 입력 설계를 돕기 위한 개발용 feature입니다.

## Detector diagnostics에서 확인할 feature 분포

실제 iPhone 세션의 이벤트가 0개일 때는 feature CSV를 만들기 전에 리포트에 저장된 `DetectorDiagnostics`를 먼저 확인합니다.

주요 분포 필드:

- `rmsMin`, `rmsP50`, `rmsP90`, `rmsMax`
- `energyMin`, `energyP50`, `energyP90`, `energyMax`
- `lowBandEnergyP50`, `lowBandEnergyP90`
- `midBandEnergyP50`
- `highBandEnergyP50`
- `zeroCrossingRateP50`
- `spectralCentroidP50`

pipeline count 필드:

- `audioChunkCount`
- `analyzedChunkCount`
- `rawCandidateCountByType`
- `preSmoothingCandidateCountByType`
- `postSmoothingEventCountByType`
- `finalEventCountByType`
- `rejectReasonCounts`
- `snoreLikeFeatureCandidateCount`
- `snoreLikeFeatureRejectedCount`
- `snoreLikeFeatureRejectReasonCounts`
- `snoreRawCandidateCount`
- `snoreRejectedCount`
- `snoreRejectReasonTop`
- `inputLevelAssessment`
- `latestFeatureDebugSummary`
- `latestRawCandidateDebugSummary`
- `thresholdSnapshot`
- `activeDetectorBackend`
- `tuningProfile`
- `modelInstalled`
- `fallbackUsed`

판독 기준:

- audio chunk가 거의 없으면 먼저 capture/background 상태를 확인합니다.
- audio coverage는 충분한데 `inputLevelAssessment == goodCoverageLowInputLevel`이면 실제 입력 RMS/energy가 저진폭 코골기 후보 기준보다 크게 낮은 상태입니다. 이 경우 threshold를 바로 낮추기보다 iPhone 거리, 마이크 방향, 케이스/침구 가림을 먼저 짧은 foreground 테스트로 비교합니다.
- 코골기 feature 후보와 raw 후보가 모두 0개이면 RMS/energy/low-band 분포가 threshold 근처까지 올라왔는지 확인합니다.
- 코골기 feature 후보는 있지만 raw 후보가 0개이면 `snoreLikeFeatureRejectReasonCounts`로 RMS, energy, low-band ratio, confidence 근접 여부를 확인합니다.
- raw 후보는 있는데 post-smoothing이 0이면 confidence, duration, merge/drop reason을 봅니다.
- `snore` raw 후보는 있는데 최종 이벤트가 0이면 `snoreRejectReasonTop`과 confidence histogram을 우선 확인합니다.
- feature 분포가 threshold보다 낮으면 iPhone 위치, 마이크 방향, 케이스, 주변 소리 영향을 짧은 foreground 테스트로 비교합니다.
- RMS가 `tuning.snoreRmsThreshold`보다 낮아도 `rule.lowLevelSnoreRMS`, `rule.lowLevelSnoreLowBandRatio`, `rule.snoreRelativeEnergyRatio`를 통과하면 raw snore 후보가 될 수 있습니다. 이 경우 low-band가 충분히 높고 high-band/ZCR/centroid가 낮은지 negative sample과 함께 확인합니다.

## rule-based detector의 한계

현재 detector는 정확한 판정을 목표로 하지 않습니다.

- RMS threshold에 민감합니다.
- iPhone 모델, 케이스, 침대 위치, 방 구조에 따라 level이 달라질 수 있습니다.
- 코골기와 환경 소음이 비슷하게 보일 수 있습니다.
- 마찰음, 기침 의심 소리, gasp-like 회복 호흡은 임시 heuristic입니다.
- `bruxismLike`는 “이갈이 의심 소리” 후보입니다. iPhone 마이크 기반 소리 감지이므로 조용한 clenching은 감지하기 어렵습니다.
- `bruxismLike`는 침구 마찰음, 손톱 긁힘, 침대 소음, 반려동물 소리와 헷갈릴 수 있어 사용자 확인 feedback이 필요합니다.
- `breathingPauseSuspected`는 긴 저에너지 구간 후보일 뿐이며 상태를 확정하지 않습니다.
- 추후 Core ML 또는 SoundAnalysis 기반 detector로 교체할 수 있어야 합니다.

## Feature Lab 구조

```text
Tools/FeatureLab/
  README.md
  output/        # git ignore

Docs/
  DATASET_GUIDE.md
  FEATURE_VALIDATION.md

Samples/
  README.md
  Personal/      # git ignore
  Public/        # git ignore
```

## 개인 샘플을 안전하게 넣는 방법

1. repo 루트에 `Samples/Personal/` 폴더를 만듭니다.
2. 개인 샘플 오디오는 그 안에만 둡니다.
3. 샘플 파일명에 이름, 주소, 장소 같은 개인 정보를 넣지 않습니다.
4. 긴 원본 전체 녹음 대신 짧은 검증용 구간만 수동으로 준비합니다.
5. sleep talk 내용은 기록하거나 텍스트화하지 않습니다.
6. `git status --short`로 샘플 파일이 추적되지 않는지 확인합니다.

## DEBUG 샘플 수집 화면

DEBUG 빌드에서는 설정 탭의 “개발자용 샘플 수집” 화면에서 2초/3초/5초 샘플을 직접 캡처할 수 있습니다.

- 사용자가 버튼을 누른 짧은 구간만 저장합니다.
- 저장 위치는 앱 sandbox 내부의 `Documents/Samples/Personal/`입니다.
- 오디오 파일은 `.caf`, metadata는 `.metadata.json`, feature summary는 `.features.csv`로 저장합니다.
- Release 빌드에서는 이 화면이 노출되지 않습니다.
- 이 기능은 서버 전송, 클라우드 동기화, STT 변환을 하지 않습니다.
- 앱 실행당 샘플 수, 샘플 1개 최대 길이, 폴더 용량, 오래된 샘플 정리 정책을 `DebugSampleStoragePolicy`로 제한합니다.
- 이벤트가 0개인 세션에서도 사용자가 직접 누른 짧은 샘플은 feature scale 확인에 사용할 수 있습니다.
- 생성된 `.features.csv`는 원본 PCM이 아니라 feature summary이며, Dataset Replay와 Offline Evaluation 결과의 RMS/energy p90과 비교합니다.

## 공개 샘플을 다루는 방법

1. 공개 데이터셋은 자동 다운로드하지 않습니다.
2. 라이선스를 직접 확인한 뒤 기본 workflow에서는 로컬에서만 사용합니다.
3. `Samples/Public/` 아래에 둡니다.
4. 공개 데이터셋 원본 파일을 포함 배포하는 경우 upstream license와 attribution을 유지하고 `Docs/LICENSING.md`에 맞춰 표시합니다.

## git 커밋 방지 장치

`.gitignore`에는 다음 항목이 포함되어 있습니다.

```text
Samples/Personal/
Samples/Public/
Tools/FeatureLab/output/
*.wav
*.caf
*.m4a
```

확인 명령:

```bash
git status --short
```

오디오 파일 추적 여부 확인:

```bash
git ls-files "*.wav" "*.caf" "*.m4a"
```

## CSV export

`FeatureCSVExporter`는 원본 오디오가 아니라 feature summary만 CSV 문자열로 만듭니다.

CSV columns:

```text
timestamp,label,rms,energy,zeroCrossingRate,spectralCentroid,lowBandEnergy,midBandEnergy,highBandEnergy,detectorOutput,confidence
```

label별 feature 평균을 비교할 때는 `FeatureCSVExporter.summarizeByLabel(records:)` 또는 `makeLabelSummaryCSV(records:)`를 사용합니다.

label summary columns:

```text
label,sampleCount,averageRMS,averageEnergy,averageZeroCrossingRate,averageSpectralCentroid,averageLowBandEnergy,averageMidBandEnergy,averageHighBandEnergy
```

원본 PCM sample, 전체 오디오 파일, 텍스트 변환 결과는 export하지 않습니다.

## 이후 Core ML 확장 방향

다음 단계에서는 detector protocol을 유지한 채 새 detector를 추가할 수 있습니다.

- `SleepEventDetector` protocol은 유지합니다.
- `RuleBasedSleepEventDetector`는 baseline으로 남깁니다.
- Core ML detector는 별도 타입으로 추가합니다.
- UI와 저장소는 `DetectorOutput`과 `SleepEvent`에 계속 의존하게 둡니다.
- 학습용 샘플과 모델 파일 추가는 별도 작업에서 개인정보와 라이선스를 다시 검토한 뒤 진행합니다.
- `snore` binary baseline은 유지하고, `coughLike`, `gaspLike`, `environmentalNoise`, `unknown`은 향후 multiclass detector 후보로 분리 검토합니다.
