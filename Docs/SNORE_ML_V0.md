# Snore ML v0

Snore ML v0는 NightBreath / 밤숨의 첫 번째 실제 ML detector 후보입니다. 범위는 `snore vs non-snore` binary baseline이며, 수면 소리 이벤트 감지 개발용입니다. 의료적 정확도나 진단 성능을 의미하지 않습니다.

## 원칙

- 공개 데이터셋을 자동 다운로드하지 않습니다.
- 공개/개인 오디오 파일을 repo에 포함하지 않습니다.
- 서버 업로드, 네트워크 호출, 클라우드 학습을 추가하지 않습니다.
- HealthKit 실제 연동이나 권한 요청을 추가하지 않습니다.
- 전체 밤 원본 오디오 저장 기능을 추가하지 않습니다.
- sleep talk 내용은 텍스트로 변환하지 않습니다.

## 데이터 준비

입력은 feature metadata 또는 dataset manifest를 사용합니다.

```text
Samples/Personal/metadata.csv
Samples/Personal/metadata.json
Samples/Personal/*.metadata.json
Samples/Personal/*.features.csv
Tools/OfflineEvaluation/sample_manifest.example.json 형식의 manifest
```

Positive label:

```text
snore
```

Negative labels:

```text
silence
unknown
environmentalNoise
movementLike
coughLike
sleepTalkLike
bruxismLike
```

manifest를 학습 입력으로 쓸 때는 각 segment에 `features` 또는 `featureSummary`를 넣습니다. `duration`이 없으면 `segmentDurationSeconds`를 사용합니다.

## Feature Schema

Snore ML v0는 다음 scalar feature를 같은 순서로 사용합니다.

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

앱의 `ModelInputAdapter`도 동일한 이름과 순서로 Core ML 입력을 만듭니다.

## 학습

```sh
cd Tools/Training
python3 -m pip install -r requirements.txt
python3 train_snore_detector.py --manifest ../OfflineEvaluation/sample_manifest.example.json
```

기본 metadata 폴더를 사용할 때:

```sh
python3 train_snore_detector.py
```

학습 시작 최소 기준은 `snore 20개`, `non-snore 20개`, `전체 40개`입니다. 부족하면 학습하지 않고 안내만 출력합니다.

학습 output:

```text
Tools/Training/output/snore_model.pkl
Tools/Training/output/snore_evaluation.json
Tools/Training/output/snore_evaluation.md
```

## 평가

```sh
cd Tools/Training
python3 evaluate_snore_detector.py --manifest ../OfflineEvaluation/sample_manifest.example.json --output-dir output
```

출력은 detector 개발용 지표입니다. false-positive-like / false-negative-like 후보는 Offline Evaluation baseline report와 함께 검토합니다.

## Core ML 변환

```sh
cd Tools/Training
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

변환된 모델을 실제 앱에서 쓰려면 Xcode에서 `Models/CoreML/SnoreDetector.mlmodel` 또는 같은 이름의 compiled model을 앱 target에 추가합니다.

## 앱 Fallback

앱 기본 detector backend는 `hybrid`입니다.

- `SnoreDetector` 모델이 target에 있으면 Core ML snore 결과를 우선 사용합니다.
- 모델이 없으면 `CoreMLSleepEventDetector`는 unavailable 상태가 됩니다.
- `CompositeSleepEventDetector`는 crash하지 않고 rule-based detector로 fallback합니다.
- `ModelOutputMapper`는 `snore`, `non_snore`, `unknown`, `1`, `0` label을 안전하게 매핑하고 confidence를 0...1로 clamp합니다.

DEBUG 화면에서는 다음을 확인할 수 있습니다.

- `Snore ML model installed`
- `model version`
- `last ML confidence`
- `fallback count`
- `현재 backend`

## 한계

- feature table 기반 baseline이라 시간적 패턴을 충분히 보지 못합니다.
- 라벨 품질과 샘플 균형에 민감합니다.
- 공개 데이터셋은 라이선스와 재배포 제한을 직접 확인해야 합니다.
- 실제 iPhone threshold는 별도 기기 테스트로 보수적으로 확인해야 합니다.
- 결과는 코골기 소리 이벤트 detector 개발용이며 질병 판단이나 치료 필요 여부 판단에 사용하지 않습니다.
