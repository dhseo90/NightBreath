# Dataset Replay

Dataset Replay는 실제 iPhone 마이크를 쓰지 않고도 detector, smoothing, 리포트 생성 흐름을 검증하기 위한 개발용 구조입니다.

## 원칙

- 공개 데이터셋은 자동 다운로드하지 않습니다.
- 공개/개인 오디오 파일은 repository에 커밋하지 않습니다.
- 데이터셋 라이선스는 사용자가 직접 확인해야 합니다.
- Dataset Replay는 detector 개발과 회귀 테스트용입니다.
- 공개 데이터 또는 로컬 파일은 실제 iPhone 마이크, 방 위치, 충전 상태, 화면 잠금 상태와 다를 수 있습니다.
- 이 앱은 수면 중 소리 기반 지표를 제공하는 웰니스 앱이며 진단 목적의 의료기기가 아닙니다.

## Synthetic Replay

DEBUG 빌드에서 `설정 > 개발 > Dataset Replay`로 들어가 synthetic pattern을 선택합니다.

지원 pattern:
- silence
- lowEnergyNoise
- highEnergyNoise
- snoreLikeBurst
- coughLikeBurst
- gaspLikeBurst
- movementLikeNoise
- breathingPauseLikeLowActivity

`빠른 재생`은 테스트를 빠르게 끝내기 위한 mode이고, `실시간`은 chunk 간 시간을 실제 오디오 길이에 맞춰 흘려보냅니다.

## 로컬 오디오 파일 Replay

1. Simulator 또는 Mac에서 WAV/CAF/M4A 파일을 준비합니다.
2. 파일은 repo 밖 또는 gitignore된 `Datasets/`, `Samples/Public/`, `Samples/Personal/` 아래에 둡니다.
3. DEBUG 빌드의 `Dataset Replay` 화면에서 파일을 선택합니다.
4. replay mode를 선택한 뒤 `파일 Replay`를 실행합니다.
5. 화면에서 AudioChunk 수, 실제 수신 시간, 분석 시간, detector diagnostics, 생성된 NightReport를 확인합니다.

오디오 파일은 replay 입력으로만 사용하며 앱이 전체 밤 원본 오디오를 저장하는 기능으로 확장하지 않습니다.

## Manifest

`PublicDatasetManifest`는 로컬 파일 경로와 expected/negative label을 기록하기 위한 모델입니다. 실제 오디오 파일은 포함하지 않고, 라이선스 메모와 segment 정보를 별도로 남기는 용도입니다.

manifest 작성법과 Offline Evaluation validation 규칙은 `Docs/DATASET_MANIFEST_GUIDE.md`를 참고합니다.

## Git 보호

다음 경로와 확장자는 gitignore 대상입니다.

- `Datasets/`
- `Samples/Public/`
- `Samples/Personal/`
- `Tools/DatasetReplay/output/`
- `*.wav`
- `*.caf`
- `*.m4a`

예외가 필요한 아주 작은 테스트 fixture가 생긴다면, 별도 검토 후 명시적으로 추가해야 합니다.
