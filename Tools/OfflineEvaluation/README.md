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

필드:
- `datasetName`: 데이터셋 이름
- `filePath`: 로컬 오디오 파일 경로. manifest 파일 위치 기준 상대 경로 또는 절대 경로
- `fileId`: 파일/segment 식별자
- `segmentStartSeconds`: 평가 시작 위치
- `segmentDurationSeconds`: 평가할 길이
- `expectedLabels`: 기대 label 배열
- `notes`: 선택 메모
- `licenseNote`: 라이선스 확인 메모

예시는 `sample_manifest.example.json`을 참고하세요.

## 실행

```bash
swift run OfflineEvaluation \
  --manifest Tools/OfflineEvaluation/sample_manifest.example.json \
  --output Tools/OfflineEvaluation/output \
  --profiles conservative,balanced,sensitive
```

프로필은 쉼표로 나열합니다.

- `conservative`
- `balanced`
- `sensitive`

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

- evaluated segments
- evaluated records
- zero-event records
- failed records
- snore candidates
- final snore events
- top reject reason
- csv/json output path

## Profile 비교

evaluation JSON을 만든 뒤 profile 비교 도구로 conservative, balanced, sensitive 결과를 비교할 수 있습니다.

```bash
swift run OfflineProfileCompare \
  --input Tools/OfflineEvaluation/output/offline_evaluation_YYYYMMDD_HHMMSS.json \
  --output Tools/OfflineEvaluation/output
```

생성 파일:
- `tuning_report.md`
- `suggested_changes.json`

이 도구는 possible false-positive-like / possible false-negative-like finding과 threshold 수동 검토 후보를 출력합니다. `suggested_changes.json`은 코드에 자동 적용되지 않습니다.

## 실제 iPhone 테스트와의 관계

Offline Evaluation은 detector 변경 전후 비교에는 좋지만 실제 iPhone 마이크 입력, 화면 잠금/백그라운드 녹음, 배터리/발열, interruption, overnight 안정성, device placement 검증을 대체하지 못합니다.
