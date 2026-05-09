# Dataset Replay

Dataset Replay는 실제 iPhone 마이크를 쓰지 않고도 detector, smoothing, 리포트 생성 흐름을 검증하기 위한 개발용 구조입니다.

## 원칙

- 공개 데이터셋은 자동 다운로드하지 않습니다.
- 공개 오디오 파일은 기본 workflow에서 repository에 커밋하지 않습니다. 포함 배포가 필요한 공개 dataset은 upstream license와 attribution을 유지합니다.
- 개인 오디오 파일은 repository에 커밋하지 않습니다.
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

## 실제 코골이 짧은 샘플 Replay

실제 iPhone에서 코골이처럼 들린 상황을 detector 관점에서 확인할 때는 `SampleCaptureView` 또는 사용자가 직접 준비한 짧은 로컬 파일을 사용합니다.

권장 흐름:

1. DEBUG 빌드의 `개발자용 샘플 수집` 화면에서 `코골기` 라벨을 선택합니다.
2. 소리가 들리는 순간 사용자가 직접 2초/3초/5초 버튼 중 하나를 누릅니다.
3. 생성된 `.caf`, `.metadata.json`, `.features.csv`를 앱 sandbox에서 꺼낼 경우 `Samples/Personal/` 또는 repo 밖 로컬 폴더에만 둡니다.
4. 파일명에는 개인 정보나 대화 내용을 넣지 않습니다.
5. `Dataset Replay`에서 `.caf` 파일을 선택해 raw 후보, smoothing 전/후 count, reject reason, RMS/energy p90을 확인합니다.

이 경로는 이벤트가 0개라 event audio snippet이 생성되지 않는 상황을 보완하기 위한 DEBUG 경로입니다. 전체 밤 원본 오디오 저장이나 자동 수집 기능으로 확장하지 않습니다.

## Manifest

`PublicDatasetManifest`는 로컬 파일 경로와 expected/negative label을 기록하기 위한 모델입니다. 실제 오디오 파일은 포함하지 않고, 라이선스 메모와 segment 정보를 별도로 남기는 용도입니다. 공개 dataset을 repository 또는 배포 archive에 포함하는 경우에도 manifest와 dataset license notice를 분리해 관리합니다.

manifest 작성법과 Offline Evaluation validation 규칙은 `Docs/DATASET_MANIFEST_GUIDE.md`를 참고합니다.

짧은 personal debug sample은 `recordingType: "personalDebugSample"`, `microphoneType: "iPhone"`, `segmentDurationSeconds: 2`, `3`, 또는 `5`처럼 기록합니다. `localFilePath`는 manifest 위치 기준 상대 경로나 repo 밖 절대 경로를 사용할 수 있지만, 실제 파일과 실제 개인 경로가 들어간 manifest는 commit하지 않습니다.

## Git 보호

다음 경로와 확장자는 기본 workflow에서 gitignore 대상입니다.

- `Datasets/`
- `Samples/Public/`
- `Samples/Personal/`
- `Tools/OfflineEvaluation/output/`
- `*.wav`
- `*.caf`
- `*.m4a`

예외가 필요한 아주 작은 테스트 fixture나 공개 dataset 포함 배포가 생긴다면, 별도 검토 후 upstream license, attribution, NonCommercial 여부를 `LICENSE`, `THIRD_PARTY_NOTICES.md`, [LICENSING](LICENSING.md)에 맞춰 명시합니다.
