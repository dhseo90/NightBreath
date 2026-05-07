# Snore Baseline Evaluation

Snore Baseline Evaluation은 NightBreath / 밤숨의 코골기 detector를 manifest segment 기준으로 반복 평가해 threshold 튜닝의 기준점을 만드는 개발용 도구입니다.

이 결과는 의료 성능 검증이나 진단 목적의 지표가 아닙니다. 실제 iPhone 마이크, 기기 배치, 백그라운드 녹음 안정성은 나중에 별도로 확인해야 합니다.

## 목적

- 현재 detector가 `verySensitive`, `sensitive`, `balanced`, `conservative`, `veryConservative` profile에서 어떤 코골기 이벤트를 만드는지 비교합니다.
- `zero-event`, possible false-positive-like, possible false-negative-like 후보를 찾습니다.
- 다음 threshold 조정 후보를 자동 적용하지 않고 report로 남깁니다.

## 원칙

- 공개 데이터셋은 자동 다운로드하지 않습니다.
- 공개/개인 오디오 파일은 repo에 포함하지 않습니다.
- 오디오 파일은 `Datasets/` 또는 repo 밖 로컬 경로에 직접 준비합니다.
- 서버/네트워크 코드, HealthKit 실제 연동, 전체 밤 원본 오디오 저장 기능을 추가하지 않습니다.

## 실행 방법

```bash
swift run OfflineSnoreBaseline \
  --manifest Tools/OfflineEvaluation/sample_manifest.example.json \
  --output Tools/OfflineEvaluation/output \
  --profiles verySensitive,sensitive,balanced,conservative,veryConservative
```

단일 profile만 확인할 때는 다음처럼 실행할 수 있습니다.

```bash
swift run OfflineSnoreBaseline \
  --manifest Tools/OfflineEvaluation/sample_manifest.example.json \
  --output Tools/OfflineEvaluation/output \
  --profile balanced
```

manifest 파일이 없거나 로컬 오디오가 준비되지 않은 경우 도구는 사용법을 출력하거나 missing file warning/failed record를 남기고 종료합니다. `sample_manifest.example.json`을 복사한 뒤 `localFilePath`를 직접 만든 짧은 WAV/CAF/M4A 파일로 바꿔 synthetic 또는 local debug baseline을 시작하세요.

## 실제 코골이 DEBUG 샘플 구성

실제 iPhone에서 이벤트가 0개였던 코골이 상황을 볼 때는 다음처럼 짧은 로컬 전용 segment를 구성합니다.

- `snore` expected segment: 사용자가 직접 들은 2초/3초/5초 DEBUG 샘플
- negative segment: 같은 기기 배치의 `silence`, `unknown`, `environmentalNoise` 짧은 샘플
- profile: `verySensitive`, `sensitive`, `balanced`, `conservative`, `veryConservative` 모두 비교
- 확인 값: `rawCandidateCount`, `preSmoothingCandidateCount`, `postSmoothingEventCount`, `finalSnoreEventCount`, `rejectReasonTop`, `rmsSummary`, `energySummary`, `confidenceSummary`

샘플 파일은 `Samples/Personal/`처럼 gitignore된 개인 경로 또는 repo 밖 경로에 둡니다. 실제 개인 샘플 manifest는 private/ignored output으로만 보관하고, 커밋되는 예시 manifest와 문서에는 익명 placeholder만 남깁니다. sleep talk 내용은 기록하지 않으며, 이 baseline은 detector 개발용 참고 자료입니다.

## 2026-05-05 synthetic recall guard

실제 개인 샘플이 없는 상태에서는 synthetic/로컬 전용 baseline으로 detector 단계별 동작만 확인합니다.

- low-amplitude snore-like synthetic CAF를 temp directory에 생성해 `OfflineEvaluationRunner`로 balanced/rule-based 경로를 통과시킵니다.
- high-frequency negative synthetic CAF를 같은 manifest에 넣어 snore raw/final count가 0인지 확인합니다.
- 이 검증은 실제 iPhone input scale을 대체하지 않으며, 다음 실제 iPhone smoke test에서 `rmsP90`, `energyP90`, `lowBandEnergyP90`, `snoreLikeFeatureCandidateCount`, `snoreRawCandidateCount`, `snoreRejectReasonTop`을 함께 기록해야 합니다.

현재 balanced guard:

- RMS threshold: 0.045
- RMS 0.045 미만 snore 후보의 추가 조건: `rule.lowLevelSnoreRMS` 이상, `rule.lowLevelSnoreEnergy` 이상, low-band 0.64 이상, noise 대비 relative energy 1.35 이상, zero-crossing 0.24 이하, high-band 0.18 이하, spectral centroid 950Hz 이하
- Release 기본 profile은 `balanced`이며 `verySensitive`/`sensitive`는 DEBUG 비교용입니다.
- Synthetic sensitivity guard는 `verySensitive`/`sensitive`/`balanced`에서 distant snore-like 후보가 smoothing 이후까지 남는지, 전체 선택 profile에서 조용한 방/팬/공조음/이불 마찰/broadband noise negative가 snore로 바뀌지 않는지 확인합니다.

## Output

출력 위치는 기본적으로 `Tools/OfflineEvaluation/output/`입니다.

- `snore_baseline_YYYYMMDD_HHMMSS.json`
- `snore_baseline_YYYYMMDD_HHMMSS.csv`
- `snore_baseline_report.md`

JSON/CSV record에는 다음 값이 포함됩니다.

- `fileId`
- `segmentStartSeconds`
- `segmentDurationSeconds`
- `expectedLabels`
- `detectorProfile`
- `rawCandidateCount`
- `preSmoothingCandidateCount`
- `postSmoothingEventCount`
- `finalSnoreEventCount`
- `finalEventCountByType`
- `rejectReasonTop`
- `zeroEventReason`
- `rmsSummary`
- `energySummary`
- `confidenceSummary`
- `possibleFalsePositive`
- `possibleFalseNegative`

## Report 해석

`Profile Summary`는 profile별 raw 후보 수, smoothing 전후 후보 수, 최종 코골기 이벤트 수, zero-event 수를 비교합니다.

`Top Reject Reasons`는 detector 후보가 왜 버려졌는지 보여줍니다. 예를 들어 `belowRmsThreshold`, `belowEnergyThreshold`, `belowConfidenceThreshold`가 반복되면 threshold 후보를 수동 검토할 수 있습니다.

`OfflineProfileCompare`의 `tuning_report.md`는 profile별 `Snore / Negative Snapshot`, `Delta From Balanced`, `Zero Event Stage Breakdown`을 추가로 제공합니다. Snore / Negative Snapshot은 expected snore segment에서 final snore가 남았는지와 silence/unknown/environmentalNoise negative segment에서 final snore가 생겼는지를 나란히 보여줍니다. Delta From Balanced는 Release 기본 profile인 `balanced` 대비 final event, zero-event, FP-like, FN-like 변화량을 보여줘 sensitive 계열을 기본값 후보로 볼 수 있는지 빠르게 확인하는 용도입니다.

`Zero Event Stage Breakdown`은 zero-event record를 raw 후보 없음, raw 후보는 있었지만 final 없음, smoothing drop, post-smoothing 이후 final 누락으로 분리해 실제 코골이 후보가 어느 단계에서 사라졌는지 빠르게 확인하는 용도입니다.

`Possible False-Positive-Like Cases`는 `expectedLabels`가 `silence`, `unknown`, `environmentalNoise` 중심인데 최종 코골기 이벤트가 생긴 segment입니다.

`Possible False-Negative-Like Cases`는 `expectedLabels`에 `snore`가 있는데 최종 코골기 이벤트가 0개인 segment입니다.

`Next Tuning Candidates`는 다음에 볼 threshold 방향을 제안하지만 코드에 자동 적용하지 않습니다.

## 한계

- manifest label은 detector 개발용 참고 label입니다.
- 공개 데이터셋의 녹음 환경은 iPhone 침실 환경과 다를 수 있습니다.
- synthetic/local baseline은 실제 기기 배치, 충전 상태, 화면 잠금, 백그라운드 interruption을 대체하지 못합니다.
- Release threshold 후보는 실제 iPhone 짧은 테스트와 QA checklist를 거쳐 별도 반영해야 합니다.
