# Offline Evaluation

Offline Evaluation은 실제 iPhone 녹음 없이 로컬 오디오 segment를 detector에 반복 주입해 결과를 비교하는 개발용 도구입니다.

이 도구는 Swift로 구현했습니다. 이유는 앱의 `SleepSoundCore` detector, Dataset Replay 로직, smoothing, diagnostics, 수면 소리 점수 계산기를 그대로 재사용할 수 있기 때문입니다. Python은 CSV 분석에는 편하지만 detector 로직을 별도로 복제해야 해서 지금 단계에서는 Swift가 더 안전합니다.

## 원칙

- 공개 데이터셋을 자동 다운로드하지 않습니다.
- 공개/개인 오디오 파일을 repository에 커밋하지 않습니다.
- output 파일은 `Tools/OfflineEvaluation/output/`에 저장하고 gitignore합니다.
- 이 평가는 detector 개발과 회귀 비교용입니다.
- 의료 성능 검증이 아니며, 이 앱은 진단 목적의 의료기기가 아닙니다.
- 전체 밤 원본 오디오 저장 기능을 만들지 않습니다.

## Manifest 작성법

manifest는 JSON이며 `segments` 배열을 가집니다.

Top-level 필드:
- `datasetName`: 데이터셋 또는 평가 묶음 이름
- `datasetLicenseNote`: 라이선스 확인 메모. 누락 시 warning
- `segments`: 평가할 segment 배열

Segment 필드:
- `fileId`: 파일/segment 식별자
- `localFilePath`: 로컬 오디오 파일 경로. manifest 파일 위치 기준 상대 경로 또는 절대 경로
- `subjectId`: 익명화된 subject 식별자
- `recordingType`: `publicDataset`, `personalDebugSample`, `synthetic`
- `microphoneType`: `unknown`, `ambient`, `tracheal`, `iPhone`, `other`
- `segmentStartSeconds`: 평가 시작 위치
- `segmentDurationSeconds`: 평가할 길이
- `expectedLabels`: 기대 label 배열
- `negativeLabels`: 이 segment에서 나오지 않기를 기대하는 label 배열
- `confidenceNote`: label 신뢰도 메모
- `notes`: 선택 메모

허용 label:
- `snore`
- `bruxismLike`
- `breathingPauseSuspected`
- `gaspLike`
- `coughLike`
- `sleepTalkLike`
- `movementLike`
- `environmentalNoise`
- `awakeningSuspected`
- `unknown`
- `silence`

자세한 schema와 작성 원칙은 `Docs/DATASET_MANIFEST_GUIDE.md`를 참고하세요. 예시는 `sample_manifest.example.json`에 있습니다.

## Manifest Validation

로컬 sample/replay manifest를 만들거나 수정한 뒤에는 오디오를 로드하기 전에 schema와 privacy guard를 먼저 확인합니다.

```bash
Tools/OfflineEvaluation/validate_sample_manifest.py \
  --manifest Tools/OfflineEvaluation/sample_manifest.example.json
```

기본 gate는 JSON schema, label, recording type, segment duration, git-tracked audio 참조 여부를 확인합니다. 실제 파일이 아직 준비되지 않은 경로는 missing count로만 보고하며, 파일 존재까지 강제하려면 `--require-files`를 추가합니다. 짧은 DEBUG/replay 샘플 기준은 기본 30초 이하이며 `OFFLINE_MANIFEST_MAX_SEGMENT_SECONDS`로 더 좁힐 수 있습니다.

## 실행

```bash
swift run OfflineEvaluation \
  --manifest Tools/OfflineEvaluation/sample_manifest.example.json \
  --output Tools/OfflineEvaluation/output \
  --profiles verySensitive,sensitive,balanced,conservative,veryConservative \
  --backends hybrid
```

프로필은 쉼표로 나열합니다.

- `verySensitive`
- `sensitive`
- `balanced`
- `conservative`
- `veryConservative`

backend도 쉼표로 나열할 수 있습니다.

- `ruleBased`
- `coreML`
- `hybrid`

예를 들어 같은 segment를 세 backend로 평가하려면 `--backends ruleBased,coreML,hybrid`를 사용합니다.

## Output

도구는 같은 timestamp로 CSV와 JSON을 저장합니다.

CSV 주요 컬럼:
- `evaluatedAt`
- `detectorBackend`
- `tuningProfile`
- `fileId`
- `segmentStartSeconds`
- `segmentDurationSeconds`
- `receivedAudioSeconds`
- `analyzedAudioSeconds`
- `audioCoverageRatio`
- `rawCandidateCount`
- `preSmoothingCandidateCount`
- `postSmoothingEventCount`
- `finalEventCountByType`
- `rejectReasonTop`
- `zeroEventReason`
- `rmsMean`, `rmsP90`, `rmsP95`
- `energyMean`, `energyP90`, `energyP95`
- `sleepSoundScore`
- `mainDisturbanceReason`
- `errorMessage`

JSON은 summary와 record 전체를 보존합니다. CSV는 spreadsheet 비교용으로 납작하게 저장합니다.

## 터미널 요약

실행 후 다음 값이 출력됩니다.

- manifest validation
- valid segments
- missing files
- unsupported labels
- license warnings
- evaluated segments
- evaluated records
- zero-event records
- failed records
- snore candidates
- final snore events
- top reject reason
- csv/json output path

## Profile 비교

evaluation JSON을 만든 뒤 profile 비교 도구로 verySensitive, sensitive, balanced, conservative, veryConservative 결과를 비교할 수 있습니다.

```bash
swift run OfflineProfileCompare \
  --input Tools/OfflineEvaluation/output/offline_evaluation_YYYYMMDD_HHMMSS.json \
  --output Tools/OfflineEvaluation/output
```

생성 파일:
- `tuning_report.md`
- `suggested_changes.json`

`tuning_report.md`는 상단에 Quick Comparison, Recall / Risk Matrix, Snore / Negative Snapshot, Delta From Balanced, Zero Event Stage Breakdown을 포함합니다. profile별 zero-event rate, raw → final count, final event type, top reject reason, possible false-positive-like / false-negative-like count를 한 표에서 비교해 threshold를 조정하기 전에 어느 단계에서 후보가 사라졌는지 먼저 확인할 수 있습니다.

Snore / Negative Snapshot은 `expectedLabels`에 `snore`가 있는 segment의 final snore hit와 `silence`/`unknown`/`environmentalNoise` negative segment의 final snore 발생률을 함께 보여줍니다. `Delta From Balanced`는 Release 기본 profile인 `balanced` 대비 final event, zero-event, FP-like, FN-like 변화량을 표시해 sensitive 계열을 Release 기본값으로 올릴 근거가 충분한지 빠르게 확인하게 합니다.

Zero Event Stage Breakdown은 이벤트 0개 record를 `No Raw Candidate`, `Raw But No Final`, `Smoothing Dropped`, `Post Smoothing But No Final`로 나눕니다. 실제 코골이 후보가 feature/raw 단계에서 아예 생기지 않았는지, smoothing에서 사라졌는지, final/report 단계에서 빠졌는지 먼저 분리해서 봅니다.

이 도구는 possible false-positive-like / possible false-negative-like finding과 threshold 수동 검토 후보를 출력합니다. `suggested_changes.json`은 코드에 자동 적용되지 않습니다.

## Snore Baseline

코골기 detector baseline은 manifest segment를 profile별로 평가하고 JSON/CSV/Markdown report를 생성합니다.

```bash
swift run OfflineSnoreBaseline \
  --manifest Tools/OfflineEvaluation/sample_manifest.example.json \
  --output Tools/OfflineEvaluation/output \
  --profiles verySensitive,sensitive,balanced,conservative,veryConservative
```

생성 파일:
- `snore_baseline_YYYYMMDD_HHMMSS.json`
- `snore_baseline_YYYYMMDD_HHMMSS.csv`
- `snore_baseline_report.md`

manifest가 없거나 로컬 오디오 파일이 준비되지 않았을 때 도구는 crash하지 않고 사용법 또는 missing file warning/failed record를 남깁니다. 공개 데이터셋은 자동 다운로드하지 않으므로 `sample_manifest.example.json`을 복사한 뒤 `localFilePath`를 직접 준비한 synthetic/local WAV/CAF/M4A 파일로 바꿔 실행하세요.

자세한 해석 방법은 `Docs/SNORE_BASELINE_EVALUATION.md`를 참고하세요.

## Backend 비교

rule-based, Core ML, hybrid backend를 같은 manifest segment에서 비교하려면 다음 도구를 사용합니다.

```bash
swift run OfflineBackendCompare \
  --manifest Tools/OfflineEvaluation/sample_manifest.example.json \
  --output Tools/OfflineEvaluation/output \
  --profile balanced
```

생성 파일:
- `backend_comparison_YYYYMMDD_HHMMSS.json`
- `backend_comparison_YYYYMMDD_HHMMSS.csv`
- `backend_comparison_report.md`

이 리포트는 `ruleOnlySnore`, `mlOnlySnore`, `bothNoEvent`, `confidenceGapLarge` 같은 disagreement를 개발용으로 정리합니다. Core ML 모델이 없으면 crash하지 않고 ML zero-event/fallback 후보로 남기며, hybrid는 rule-based fallback 안정성을 유지합니다.

자세한 해석 방법은 `Docs/RULE_BASED_VS_ML_COMPARISON.md`를 참고하세요.

## 실제 iPhone 테스트와의 관계

Offline Evaluation은 detector 변경 전후 비교에는 좋지만 실제 iPhone 마이크 입력, 화면 잠금/백그라운드 녹음, 배터리/발열, interruption, overnight 안정성, device placement 검증을 대체하지 못합니다.
