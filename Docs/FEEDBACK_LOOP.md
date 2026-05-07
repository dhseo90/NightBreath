# Feedback Loop Guide

NightBreath / 밤숨의 event feedback loop는 detector 개발을 돕기 위한 로컬 metadata 흐름입니다. 사용자가 이벤트별로 `맞음`, `아님`, `모르겠음`을 남기고, 필요하면 다른 이벤트 label로 수정해 다음 offline evaluation/training 자료로 사용할 수 있습니다.

이 기능은 수면 중 소리 이벤트 감지 개선용입니다. 의료적 판단이나 질병 확정 목적으로 사용하지 않습니다.

## 저장 방식

앱은 `Application Support/NightBreath/sleep-event-feedback.json`에 feedback metadata를 저장합니다.

저장 필드:

- `id`
- `eventId`
- `sessionId`
- `eventType`
- `selectedFeedback`: `correct`, `incorrect`, `unsure`
- `correctedLabel`: optional
- `createdAt`
- `note`: optional
- `hasAudioSample`
- `audioSampleId`: optional

`correctedLabel` 허용값:

- `snore`
- `bruxismLike`
- `breathingPauseSuspected`
- `gaspLike`
- `coughLike`
- `sleepTalkLike`
- `movementLike`
- `environmentalNoise`
- `unknown`

## 개인정보 보호 원칙

- 서버 전송을 하지 않습니다.
- 클라우드 처리를 하지 않습니다.
- HealthKit 실제 연동을 추가하지 않습니다.
- 전체 밤 원본 오디오를 저장하지 않습니다.
- sleep talk 내용을 텍스트로 변환하지 않습니다.
- 이벤트 오디오 샘플이 없어도 feedback을 남길 수 있습니다.
- 이벤트 오디오 샘플은 opt-in이 켜진 경우에만 짧은 로컬 샘플로 저장됩니다.

## 오디오 샘플 opt-in과의 관계

feedback metadata와 이벤트 오디오 샘플은 분리되어 있습니다.

- 이벤트 오디오 샘플 저장 OFF: feedback만 저장할 수 있습니다.
- 이벤트 오디오 샘플 저장 ON: private/ignored export에만 `audioSampleId`와 local path reference를 남길 수 있습니다.
- export 파일은 실제 오디오 파일을 포함하지 않습니다.
- 실제 local path가 들어간 export는 repository에 커밋하지 않습니다. 커밋되는 문서와 예시에는 익명 `audioSampleId`나 placeholder만 사용합니다.

## Training Manifest Export

`EventFeedbackManifestExporter`는 feedback metadata를 다음 파일로 export합니다.

```text
export_feedback_manifest.json
export_feedback_manifest.csv
```

권장 output 위치:

```text
Tools/Training/output/
```

이 폴더는 `.gitignore`에 포함되어 있어 export 결과와 local path reference가 repo에 들어가지 않습니다. 실제 개인 export를 문서 예시로 복사하지 않습니다.

앱 컨테이너에서 feedback store를 로컬로 복사한 뒤 training helper를 실행할 수도 있습니다.

```sh
cd Tools/Training
python3 export_feedback_manifest.py --feedback-store /path/to/sleep-event-feedback.json --output-dir output
```

JSON 구조 예:

```json
{
  "datasetName": "NightBreath Local Event Feedback",
  "datasetLicenseNote": "Local user feedback metadata only. Audio files are not included.",
  "records": [
    {
      "eventType": "snore",
      "selectedFeedback": "incorrect",
      "correctedLabel": "environmentalNoise",
      "expectedLabels": ["environmentalNoise"],
      "negativeLabels": ["snore"],
      "labelConfidence": 0.9,
      "trainingAction": "correctedLabel",
      "hasAudioSample": false
    }
  ]
}
```

## Training Mapping

`Tools/Training/dataset.py`는 feedback manifest를 읽을 수 있습니다.

- `correct`: 현재 `eventType`을 높은 confidence label로 사용합니다.
- `incorrect` + `correctedLabel`: 수정된 label로 사용합니다.
- `incorrect` + correctedLabel 없음: snore detector에서는 negative/unknown 신호로 사용합니다.
- `unsure`: 학습 record에서 제외합니다.

snore v0 pipeline은 `snore`를 positive로, `silence`, `unknown`, `environmentalNoise`, `movementLike`, `coughLike`, `sleepTalkLike`, `bruxismLike`를 non-snore negative로 다룹니다.

## 한계

사용자 feedback은 detector 개선을 위한 개발 자료입니다. 사용자의 기억, 주변 환경, 기기 위치, 오디오 샘플 유무에 따라 label 신뢰도가 달라질 수 있습니다. 실제 iPhone 반복 테스트와 offline baseline 비교를 함께 확인해야 합니다.
