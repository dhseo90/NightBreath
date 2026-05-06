# Dataset Manifest Guide

NightBreath / 밤숨의 dataset manifest는 detector 개발과 Offline Evaluation을 위해 로컬 오디오 파일 위치와 짧은 segment label을 기록하는 JSON입니다.

이 manifest는 오디오 파일을 포함하지 않습니다. 공개 데이터셋, 개인 디버그 샘플, synthetic 샘플 모두 사용자가 직접 로컬에 준비하고 `Datasets/`처럼 gitignore된 경로 또는 repo 밖 경로에 둡니다.

## 원칙

- 공개 데이터셋은 자동 다운로드하지 않습니다.
- 공개 데이터 파일을 repo에 커밋하지 않습니다.
- 개인 오디오 파일을 repo에 커밋하지 않습니다.
- 데이터셋 라이선스와 재배포 제한은 사용자가 직접 확인합니다.
- 서버 업로드, 네트워크 호출, 클라우드 처리를 추가하지 않습니다.
- HealthKit 실제 연동과 권한 요청을 추가하지 않습니다.
- 전체 밤 원본 오디오 저장 기능을 추가하지 않습니다.
- 평가 결과는 detector 개발/회귀 비교용이며 의료 성능 검증이 아닙니다.

## 파일 위치

예시 manifest:

```text
Tools/OfflineEvaluation/sample_manifest.example.json
```

로컬 오디오는 다음처럼 gitignore된 위치에 둘 수 있습니다.

```text
Datasets/public-example/snore_segment.wav
Datasets/personal-debug/cough_segment.caf
Samples/Public/
Samples/Personal/
```

`localFilePath`는 manifest 파일 위치 기준 상대 경로 또는 절대 경로를 사용할 수 있습니다.

실제 iPhone DEBUG 샘플은 앱 sandbox에서 꺼낸 뒤 `Samples/Personal/` 또는 repo 밖 로컬 폴더에 둡니다. 이때 `.caf`, `.metadata.json`, `.features.csv`를 함께 보관하면 `Dataset Replay`와 feature 분포 확인을 같은 샘플 기준으로 맞출 수 있습니다.

## Schema

Top-level 필드:

- `datasetName`: manifest에 기록된 데이터셋/평가 묶음 이름
- `datasetLicenseNote`: 라이선스 확인 메모. 누락되면 warning으로 출력됩니다.
- `segments`: 평가할 segment 배열

Segment 필드:

- `fileId`: 파일 또는 segment 식별자
- `localFilePath`: 로컬 오디오 파일 경로
- `subjectId`: 공개/개인 식별자를 익명화한 값. 선택 필드입니다.
- `recordingType`: `publicDataset`, `personalDebugSample`, `synthetic`
- `microphoneType`: `unknown`, `ambient`, `tracheal`, `iPhone`, `other`
- `segmentStartSeconds`: 오디오 파일 안에서 평가를 시작할 초 단위 위치
- `segmentDurationSeconds`: 평가할 길이. 0보다 커야 합니다.
- `expectedLabels`: detector가 잡기를 기대하는 label 배열
- `negativeLabels`: 이 segment에서 나오지 않기를 기대하는 label 배열
- `features`: 선택 필드. Snore ML v0 training에 사용할 feature summary입니다.
- `confidenceNote`: label 신뢰도나 확인 방식에 대한 메모
- `notes`: 자유 메모

`expectedLabels`와 `negativeLabels` 허용값:

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

`silence`는 앱의 수면 이벤트 타입이 아니라 조용한 구간이나 false-positive-like 확인을 위한 manifest label입니다.

Snore ML v0 training에 manifest를 직접 입력할 때 권장하는 `features` 필드:

- `rms`
- `energy`
- `zeroCrossingRate`
- `spectralCentroid`
- `lowBandEnergy`
- `midBandEnergy`
- `highBandEnergy`
- `duration`

`duration`이 없으면 training tool은 `segmentDurationSeconds`를 사용합니다.

## 예시

```json
{
  "datasetName": "local-detector-evaluation-example",
  "datasetLicenseNote": "사용 전 공개 데이터셋 라이선스를 직접 확인하세요.",
  "segments": [
    {
      "fileId": "public-snore-001",
      "localFilePath": "../../Datasets/public-example/snore_segment.wav",
      "subjectId": "public-subject-anonymous-001",
      "recordingType": "publicDataset",
      "microphoneType": "ambient",
      "segmentStartSeconds": 0,
      "segmentDurationSeconds": 10,
      "expectedLabels": ["snore"],
      "negativeLabels": ["coughLike", "gaspLike"],
      "confidenceNote": "짧은 구간을 직접 확인한 detector 개발용 참고 label입니다.",
      "notes": "오디오 파일은 repo에 포함하지 않습니다."
    }
  ]
}
```

실제 코골이 zero-event 원인 분석용 manifest는 짧은 positive segment와 negative segment를 함께 둡니다.

```json
{
  "datasetName": "local-snore-debug-short-samples",
  "datasetLicenseNote": "개인 DEBUG 샘플은 본인 기기 로컬에서만 사용하고 repository에 포함하지 않습니다.",
  "segments": [
    {
      "fileId": "debug-snore-short-001",
      "localFilePath": "../../Samples/Personal/debug-snore-short-001.caf",
      "subjectId": "self-debug-local",
      "recordingType": "personalDebugSample",
      "microphoneType": "iPhone",
      "segmentStartSeconds": 0,
      "segmentDurationSeconds": 3,
      "expectedLabels": ["snore"],
      "negativeLabels": ["coughLike", "environmentalNoise"],
      "confidenceNote": "사용자가 직접 들은 짧은 구간을 detector 개발용 참고 label로 표시합니다.",
      "notes": "파일명과 메모에 개인 정보나 sleep talk 내용을 넣지 않습니다."
    },
    {
      "fileId": "debug-quiet-short-001",
      "localFilePath": "../../Samples/Personal/debug-quiet-short-001.caf",
      "subjectId": "self-debug-local",
      "recordingType": "personalDebugSample",
      "microphoneType": "iPhone",
      "segmentStartSeconds": 0,
      "segmentDurationSeconds": 3,
      "expectedLabels": ["silence"],
      "negativeLabels": ["snore"],
      "confidenceNote": "같은 기기 배치에서 조용한 짧은 구간을 함께 비교합니다.",
      "notes": "false-positive-like 비교용 로컬 전용 segment입니다."
    }
  ]
}
```

## Validation

Offline Evaluation은 실행 전에 manifest를 validation하고 다음 요약을 출력합니다.

- valid segments
- missing files
- unsupported labels
- license warnings
- missing required fields
- invalid durations
- field warnings

파일이 없으면 crash하지 않고 warning과 실패 record로 남깁니다. invalid label, 필수 필드 누락, 0 이하 duration은 blocking issue로 보고 해당 segment는 평가 대상에서 제외합니다.

## 실행

```bash
swift run OfflineEvaluation \
  --manifest Tools/OfflineEvaluation/sample_manifest.example.json \
  --output Tools/OfflineEvaluation/output \
  --profiles verySensitive,sensitive,balanced,conservative,veryConservative
```

예시 manifest의 `localFilePath`는 실제 파일을 가리키지 않을 수 있습니다. 사용자는 공개 데이터셋 또는 개인 디버그 샘플을 직접 준비한 뒤 경로를 자신의 로컬 환경에 맞게 수정해야 합니다.
