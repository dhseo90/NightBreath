# NightBreath / 밤숨 테스트 가이드

이 문서는 실기기 없이 빠르게 돌릴 수 있는 회귀 테스트와, 실제 iPhone에서만 확인해야 하는 항목을 구분합니다. 테스트 fixture에는 개인 오디오나 공개 데이터셋 원본을 넣지 않습니다.

## 빠른 회귀 테스트

Swift Package 테스트:

```bash
swift test --no-parallel
```

Xcode 프로젝트 빌드:

```bash
xcodebuild -project SleepSoundApp.xcodeproj -scheme SleepSoundApp -configuration Debug -destination 'generic/platform=iOS' -derivedDataPath .derivedData CODE_SIGNING_ALLOWED=NO build
```

## 테스트 범위

현재 회귀 테스트는 다음 흐름을 우선 확인합니다.

- synthetic audio source가 실제 마이크 없이 `AudioChunk`를 생성하는지
- detector가 무음, 낮은 에너지 소음, 큰 환경 소음, 코골기 유사 burst, 기침 의심 burst, gasp-like burst, 움직임 의심 소리를 처리하는지
- `SleepAnalyzer` → smoothing → `SleepEvent` → `NightReport` 흐름이 깨지지 않는지
- detector diagnostics에 raw 후보 수, smoothing 전/후 후보 수, reject reason, RMS/energy 요약, threshold snapshot이 남는지
- 이벤트 0개 세션에서 zero-event 분석이 생성되는지
- 이벤트 오디오 샘플 저장 기본값이 OFF인지
- opt-in OFF 상태에서 오디오 샘플 파일을 저장하지 않는지
- opt-in ON 상태에서 짧은 이벤트 샘플만 저장 가능한지
- linked/orphan 이벤트 오디오 샘플 통계와 삭제가 안전한지
- 리포트에서 앱 세션 시간, 실제 오디오 수신 시간, 실제 분석 시간이 분리되는지
- 앱 소스에 확정적 의료 주장 문구가 들어가지 않는지

## Synthetic Audio 테스트

`SyntheticAudioSource`는 실제 iPhone 마이크 없이 테스트용 `AudioChunk`를 만듭니다.

지원 패턴:

- `silence`
- `lowEnergyNoise`
- `highEnergyNoise`
- `snoreLikeBurst`
- `coughLikeBurst`
- `gaspLikeBurst`
- `movementLikeNoise`
- `breathingPauseLikeLowActivity`

이 패턴은 detector 회귀 테스트용입니다. 실제 수면 소리 분포나 iPhone 마이크 배치를 완전히 대체하지 않습니다.

## Dataset Replay 테스트

로컬 오디오 파일 replay는 `DatasetReplayAudioSource`와 `DatasetReplayView`에서 확인합니다.

원칙:

- 공개 데이터셋은 자동 다운로드하지 않습니다.
- 공개/개인 오디오 파일은 repo에 커밋하지 않습니다.
- 데이터셋 라이선스는 사용자가 직접 확인합니다.
- replay 결과는 detector 개발과 회귀 비교용이며, 의료 성능 검증이 아닙니다.

자세한 사용법은 `Docs/DATASET_REPLAY.md`를 참고합니다.

## Offline Evaluation

`Tools/OfflineEvaluation`은 manifest에 적힌 로컬 오디오 segment를 profile별로 평가하고 CSV/JSON 결과를 생성하는 개발용 도구입니다.

출력 위치:

- `Tools/OfflineEvaluation/output/`

이 폴더는 gitignore 대상이어야 하며, 결과 파일과 오디오 원본을 repo에 포함하지 않습니다.

## 실기기에서만 확인할 항목

Simulator, synthetic audio, dataset replay로 대체할 수 없는 항목:

- 실제 iPhone 마이크 입력
- 화면 잠금 상태의 오디오 수신 유지
- 앱 백그라운드 상태의 오디오 수신 유지
- 배터리 사용량과 발열
- 전화/알림/오디오 interruption 처리
- 기기 배치에 따른 감도 차이
- 장시간 overnight 안정성

자세한 절차는 `Docs/REAL_DEVICE_REQUIRED_TESTS.md`와 `Docs/BACKGROUND_RECORDING_QA.md`를 참고합니다.

## 개인정보 테스트 원칙

- 전체 밤 원본 오디오 저장 기능을 만들지 않습니다.
- 이벤트 오디오 샘플은 사용자가 opt-in으로 켠 경우에만 짧게 저장합니다.
- sleep talk 내용을 텍스트로 변환하지 않습니다.
- 서버 전송, 클라우드 처리, 외부 분석 SDK를 추가하지 않습니다.
- 테스트 fixture에는 개인 오디오와 공개 데이터셋 원본을 넣지 않습니다.
