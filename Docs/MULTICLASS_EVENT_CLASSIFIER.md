# Multiclass Event Classifier

NightBreath / 밤숨의 multiclass event classifier는 snore binary detector 이후 단계로 준비하는 로컬 개발용 classifier입니다. 목표는 여러 수면 소리 이벤트 후보를 같은 feature schema로 비교하고, rule-based placeholder를 점진적으로 대체할 수 있는지 확인하는 것입니다.

이 문서와 도구는 detector 개발용입니다. 의료적 정확도, 진단 성능, 질병 판단을 의미하지 않습니다.

## 목표 Label

- `snore`
- `bruxismLike`
- `gaspLike`
- `coughLike`
- `movementLike`
- `environmentalNoise`
- `sleepTalkLike`
- `unknown`
- `silence`

`bruxismLike`는 이갈이 확정이 아니라 이갈이 의심 소리 후보입니다. 침구 마찰, 손톱 긁힘, 주변 소음과 섞일 수 있어 사용자 feedback과 오디오 샘플 opt-in 여부를 함께 확인해야 합니다.

`gaspLike`는 회복 호흡처럼 들리는 소리 후보 표현입니다. 특정 수면 관련 질환 판단이나 임상 지표 계산으로 해석하지 않습니다.

## 데이터 준비

입력은 기존 local metadata, dataset manifest, feedback export manifest를 사용할 수 있습니다.

```text
Samples/Personal/metadata.csv
Samples/Personal/metadata.json
Tools/OfflineEvaluation/sample_manifest.example.json 형식의 manifest
Tools/Training/output/export_feedback_manifest.json
```

공개/개인 오디오 파일은 repo에 넣지 않습니다. 실제 local path reference가 들어간 manifest나 feedback export는 private/ignored output으로만 보관하고, 커밋되는 예시에는 익명 placeholder만 남깁니다.

## Feedback Manifest 사용

feedback loop에서 export한 `export_feedback_manifest.json`은 multiclass training 입력으로 사용할 수 있습니다.

```sh
cd Tools/Training
python3 train_multiclass_event_detector.py --manifest output/export_feedback_manifest.json
```

mapping 원칙:

- `correct`: 현재 event label을 사용합니다.
- `incorrect` + `correctedLabel`: 수정 label을 사용합니다.
- `incorrect` + correctedLabel 없음: `unknown` 또는 negative 후보로 사용합니다.
- `unsure`: 학습에서 제외합니다.

## Training

config:

```text
Tools/Training/config/multiclass_event_detector.yaml
```

실행:

```sh
cd Tools/Training
python3 train_multiclass_event_detector.py --manifest ../OfflineEvaluation/sample_manifest.example.json
```

기본 guard:

- 전체 샘플 180개 이상
- label별 샘플 20개 이상
- label imbalance warning ratio 4.0x

기준 미달이면 학습을 시작하지 않고 label별 count와 warning을 출력합니다. `exclude_underrepresented_labels`를 켜면 부족한 label을 제외한 subset 학습을 허용할 수 있지만, 최소 2개 label이 남아야 합니다.

## Evaluation

```sh
cd Tools/Training
python3 evaluate_multiclass_event_detector.py \
  --manifest output/export_feedback_manifest.json \
  --model output/multiclass_event_model.pkl \
  --output-dir output
```

출력:

- label별 precision-like / recall-like 개발용 지표
- confusion matrix
- false-positive-like cases
- false-negative-like cases
- label별 샘플 개수
- confidence distribution

이 지표는 detector 개발용 비교 자료입니다. 실제 iPhone 환경과 사용자 feedback을 함께 봐야 합니다.

## Core ML 변환

placeholder:

```sh
cd Tools/Training
python3 convert_multiclass_event_detector_to_coreml.py
```

아직 multiclass model file이 없으면 안내만 출력합니다. 모델 bundle이 있어도 label 품질, class balance, app-side mapping 검토 전에는 변환을 의도적으로 막아 둡니다.

계획된 위치:

```text
Models/CoreML/SleepEventClassifier.mlmodel
```

## 앱 Fallback

기존 snore detector는 유지됩니다.

- 기본 release backend는 기존 `hybrid` 흐름을 유지합니다.
- `SnoreDetector`만 있으면 현재 Core ML snore path를 그대로 사용합니다.
- `SleepEventClassifier`가 없으면 `coreMLMulticlass` backend는 rule-based fallback으로 돌아갑니다.
- 알 수 없는 label이나 `silence`는 안전하게 `unknown`으로 매핑합니다.
- confidence는 0...1로 clamp합니다.

## 개인정보와 범위

- 서버 전송을 하지 않습니다.
- 네트워크 코드를 추가하지 않습니다.
- HealthKit 실제 연동을 하지 않습니다.
- 전체 밤 원본 오디오를 저장하지 않습니다.
- sleep talk 내용을 텍스트로 변환하지 않습니다.
- 공개/개인 오디오 파일은 repo에 포함하지 않습니다.
