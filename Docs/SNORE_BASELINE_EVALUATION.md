# Snore Baseline Evaluation

Snore Baseline Evaluation은 NightBreath / 밤숨의 코골기 detector를 manifest segment 기준으로 반복 평가해 threshold 튜닝의 기준점을 만드는 개발용 도구입니다.

이 결과는 의료 성능 검증이나 진단 목적의 지표가 아닙니다. 실제 iPhone 마이크, 기기 배치, 백그라운드 녹음 안정성은 나중에 별도로 확인해야 합니다.

## 목적

- 현재 detector가 `conservative`, `balanced`, `sensitive` profile에서 어떤 코골기 이벤트를 만드는지 비교합니다.
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
  --profiles conservative,balanced,sensitive
```

단일 profile만 확인할 때는 다음처럼 실행할 수 있습니다.

```bash
swift run OfflineSnoreBaseline \
  --manifest Tools/OfflineEvaluation/sample_manifest.example.json \
  --output Tools/OfflineEvaluation/output \
  --profile balanced
```

manifest 파일이 없거나 로컬 오디오가 준비되지 않은 경우 도구는 사용법을 출력하거나 missing file warning/failed record를 남기고 종료합니다. `sample_manifest.example.json`을 복사한 뒤 `localFilePath`를 직접 만든 짧은 WAV/CAF/M4A 파일로 바꿔 synthetic 또는 local debug baseline을 시작하세요.

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

`Possible False-Positive-Like Cases`는 `expectedLabels`가 `silence`, `unknown`, `environmentalNoise` 중심인데 최종 코골기 이벤트가 생긴 segment입니다.

`Possible False-Negative-Like Cases`는 `expectedLabels`에 `snore`가 있는데 최종 코골기 이벤트가 0개인 segment입니다.

`Next Tuning Candidates`는 다음에 볼 threshold 방향을 제안하지만 코드에 자동 적용하지 않습니다.

## 한계

- manifest label은 detector 개발용 참고 label입니다.
- 공개 데이터셋의 녹음 환경은 iPhone 침실 환경과 다를 수 있습니다.
- synthetic/local baseline은 실제 기기 배치, 충전 상태, 화면 잠금, 백그라운드 interruption을 대체하지 못합니다.
- Release threshold 후보는 실제 iPhone 짧은 테스트와 QA checklist를 거쳐 별도 반영해야 합니다.
