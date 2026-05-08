# NightBreath Snore Detector Training

이 폴더는 밤숨의 첫 번째 ML detector 후보인 `snore vs non-snore` baseline 모델을 로컬 Mac에서 학습하기 위한 개발 도구입니다.

이 파이프라인은 코골기 소리 후보를 찾기 위한 웰니스/수면 습관 지표 개발용입니다. 질병을 판단하거나 의료적 상태를 확정하기 위한 도구가 아닙니다.

## 원칙

- 공개 데이터셋을 자동 다운로드하지 않습니다.
- 개인 오디오 파일을 git에 커밋하지 않습니다.
- 서버 업로드, 외부 API 호출, 클라우드 학습을 하지 않습니다.
- 앱 target에 `.mlmodel`을 자동으로 추가하지 않습니다.
- 이번 범위는 코골기 감지만 다룹니다.
- sleep talk 내용을 텍스트로 변환하지 않습니다.

## 모델 선택

첫 버전은 `scikit-learn`의 `StandardScaler + LogisticRegression` baseline을 사용합니다.

선택 이유:
- 개인 샘플 수가 처음에는 적을 가능성이 큽니다.
- feature 수가 작고 해석하기 쉽습니다.
- 학습/평가 속도가 빠릅니다.
- 나중에 Core ML 변환 전 baseline 성능을 확인하기 좋습니다.

log-mel spectrogram 기반 모델은 더 많은 데이터가 쌓인 뒤 진행합니다. 현재는 `audio_features.py`에 shape-only placeholder schema만 두고, 실제 extraction/training은 의도적으로 비활성화했습니다.

## 데이터 준비

DEBUG 빌드의 “개발자용 샘플 수집” 화면에서 짧은 2초/3초/5초 샘플을 만들고, Xcode에서 앱 컨테이너를 내려받아 `Documents/Samples/Personal/` 내용을 로컬 repo의 다음 폴더로 복사합니다.

```text
Samples/Personal/
```

지원 입력:

```text
Samples/Personal/metadata.csv
Samples/Personal/metadata.json
Samples/Personal/*.metadata.json
Samples/Personal/*.features.csv
Tools/OfflineEvaluation/sample_manifest.example.json 형식의 manifest
Tools/Training/output/export_feedback_manifest.json
```

manifest를 사용하는 경우 각 segment에 `features` 또는 `featureSummary` 블록을 넣는 것을 권장합니다. 실제 오디오 파일은 private/ignored manifest의 `localFilePath`로만 참조하고 repo에는 넣지 않습니다. 커밋되는 예시에는 익명 placeholder 경로만 사용합니다. `duration`은 `features.duration`이 없으면 `segmentDurationSeconds`에서 읽습니다.

사용자 feedback export manifest를 사용하는 경우 `selectedFeedback == unsure` record는 학습에서 제외합니다. `correct`는 현재 event label을 높은 신뢰도 label로 사용하고, `incorrect`는 `correctedLabel`이 있으면 수정 label로, 없으면 snore detector 기준의 negative/unknown 신호로 처리합니다. export 파일은 metadata와 local path reference만 포함하며 실제 오디오 파일을 포함하지 않습니다. 실제 path가 들어간 export 파일은 private/ignored output으로만 둡니다.

`label == snore`는 positive class입니다.

다음 라벨은 non-snore negative class로 처리합니다.

```text
bruxismLike
silence
unknown
environmentalNoise
movementLike
coughLike
sleepTalkLike
```

## Git 보호

`.gitignore`는 다음을 무시합니다.

```text
Samples/Personal/
Samples/Public/
Tools/Training/output/
*.wav
*.caf
*.m4a
```

학습용 output과 개인 오디오 파일은 repo에 올리지 않습니다.

## 설치

```sh
cd Tools/Training
python3 -m venv .venv
source .venv/bin/activate
python3 -m pip install -r requirements.txt
```

## Feature export

```sh
python3 export_features.py
python3 export_features.py --manifest ../OfflineEvaluation/sample_manifest.example.json
```

기본 출력:

```text
Tools/Training/output/snore_features.csv
```

## Feedback manifest export

앱 컨테이너에서 `sleep-event-feedback.json`을 로컬로 복사한 뒤 feedback metadata를 training manifest로 변환할 수 있습니다. 실제 오디오 파일은 복사하지 않고, `audioSampleId`/`localFilePath`는 private/ignored 로컬 참조만 남깁니다. 커밋되는 문서나 fixture에는 실제 path를 옮기지 않습니다.

```sh
python3 export_feedback_manifest.py --feedback-store /path/to/sleep-event-feedback.json --output-dir output
```

기본 출력:

```text
Tools/Training/output/export_feedback_manifest.json
Tools/Training/output/export_feedback_manifest.csv
```

## 학습

```sh
python3 train_snore_detector.py
python3 train_snore_detector.py --manifest ../OfflineEvaluation/sample_manifest.example.json
python3 train_snore_detector.py --manifest output/export_feedback_manifest.json
```

기본 출력:

```text
Tools/Training/output/snore_model.pkl
Tools/Training/output/snore_evaluation.json
Tools/Training/output/snore_evaluation.md
```

데이터가 부족하면 학습을 시작하지 않고 필요한 샘플 수를 안내합니다.

## 평가

```sh
python3 evaluate_snore_detector.py
python3 evaluate_snore_detector.py --manifest ../OfflineEvaluation/sample_manifest.example.json --output-dir output
```

출력 항목:
- accuracy
- precision
- recall
- F1
- confusion matrix
- threshold별 precision/recall
- false positive sample 목록
- false negative sample 목록

## Core ML 변환

학습이 끝난 뒤 다음 명령으로 Core ML 모델을 만들 수 있습니다.

```sh
python3 convert_snore_detector_to_coreml.py
```

기본 입력:

```text
Tools/Training/output/snore_model.pkl
```

기본 출력:

```text
Models/CoreML/SnoreDetector.mlmodel
```

변환 스크립트는 `coremltools`를 사용합니다. package가 없으면 다음 명령으로 설치합니다.

```sh
python3 -m pip install -r requirements.txt
```

현재 baseline 모델의 Core ML 입력 schema는 다음 feature를 각각 `Double` scalar input으로 받습니다.

```text
rms
energy
zeroCrossingRate
spectralCentroid
lowBandEnergy
midBandEnergy
highBandEnergy
duration
```

앱의 `ModelInputAdapter`는 같은 값을 제공하며, 향후 vector 입력 모델을 위해 `features` 배열도 함께 준비합니다. sklearn baseline은 numeric label을 사용하므로 앱에서는 `1`을 `snore`, `0`을 `non_snore`로 안전하게 해석합니다.

생성된 모델을 실제 앱에서 테스트하려면 `Docs/CORE_ML_MODEL_INTEGRATION.md`의 integration gate를 먼저 통과한 뒤 Xcode에서 `Models/CoreML/SnoreDetector.mlmodel`을 앱 target에 추가하세요. 앱 기본 backend는 `hybrid`이며, 모델이 없거나 target에 포함되지 않은 경우 crash하지 않고 rule-based detector로 fallback합니다.

앱 target에 모델을 붙이기 전 현재 repository가 모델 미포함 상태를 유지하는지 확인하려면 아래 local gate를 실행합니다.

```sh
Tools/Training/validate_coreml_integration_gate.sh
```

## Future log-mel placeholder

현재 snore baseline 학습 입력은 scalar feature table입니다. `audio_features.py`에는 future Core ML 후보를 위한 log-mel schema만 고정해 둡니다.

```text
schema_version: log_mel_v0_placeholder
sample_rate: 16000
window_size_ms: 25
hop_size_ms: 10
input_shape: 300 x 64
status: placeholder
```

주의:
- `extract_log_mel_spectrogram()`은 아직 `NotImplementedError`를 발생시킵니다.
- `build_log_mel_placeholder_tensor()`는 shape 테스트용 0-filled tensor만 만들며 학습에 사용하지 않습니다.
- 이 placeholder는 raw audio를 저장하지 않고, 네트워크나 외부 API를 필요로 하지 않습니다.
- 실제 extractor를 구현할 때도 개인 오디오 파일은 repo 밖 또는 gitignore 경로에만 둡니다.

## 최소 권장 샘플 수

스크립트의 학습 시작 최소값은 `snore 20개 + non-snore 20개 + 전체 40개`입니다. 이 기준보다 적으면 학습을 중단하고 추가 샘플 준비 방법을 안내합니다.

실제 detector 후보를 판단하려면 최소 다음 정도를 권장합니다.

- snore positive: 50개 이상
- non-snore negative: 50개 이상
- 가능하면 여러 밤, 여러 위치, 여러 환경 소음 조건에서 수집
- Core ML 변환 전에는 snore/non-snore 각각 200개 이상이 더 안정적입니다.

## 현재 한계

- feature table 기반 baseline이라 시간적 패턴을 충분히 보지 못합니다.
- 라벨 품질이 낮으면 모델 품질도 바로 낮아집니다.
- 개인 한 명의 데이터만 사용하면 다른 환경으로 일반화하기 어렵습니다.
- 코골기 감지는 웰니스 지표이며, 어떤 상태를 진단하거나 확정하지 않습니다.

## Multiclass event classifier 준비

snore binary baseline은 그대로 유지하고, 다음 label을 위한 multiclass 준비 pipeline을 별도 script로 둡니다.

```text
snore
bruxismLike
coughLike
gaspLike
movementLike
environmentalNoise
sleepTalkLike
unknown
silence
```

config:

```text
Tools/Training/config/multiclass_event_detector.yaml
```

실행:

```sh
python3 train_multiclass_event_detector.py --manifest output/export_feedback_manifest.json
python3 evaluate_multiclass_event_detector.py --manifest output/export_feedback_manifest.json --model output/multiclass_event_model.pkl --output-dir output
python3 convert_multiclass_event_detector_to_coreml.py
```

기본 guard는 전체 180개 이상, label별 20개 이상입니다. 부족하면 label별 count와 warning을 출력하고 학습을 시작하지 않습니다. `exclude_underrepresented_labels`를 켜면 부족한 label을 제외한 subset 학습을 허용할 수 있지만, 실제 앱 적용 전에는 label imbalance와 false-positive-like/false-negative-like case를 별도로 검토해야 합니다.

## 다음 단계

Core ML 변환 전에 필요한 조건:
- snore/non-snore 샘플 수와 라벨 균형 확보
- false positive/false negative 샘플 검토
- threshold 후보 결정
- feature scaling과 label mapping 고정
- `snore_model.pkl` baseline이 rule-based detector보다 나은지 확인
- 그 다음 단계에서 `coremltools` 변환 스크립트와 앱용 `.mlmodel` 추가 여부를 별도 작업으로 결정
