# Development Workflow

NightBreath / 밤숨은 Simulator-first 방식으로 개발합니다.

목표는 실제 iPhone 테스트를 매번 반복하지 않고, 가능한 많은 회귀 검증을 Simulator, synthetic audio, Dataset Replay, Offline Evaluation으로 빠르게 수행하는 것입니다.

## 일반 개발 루틴

1. 코드 수정
2. unit test 실행
3. synthetic audio test 실행
4. Dataset Replay로 pipeline 확인
5. Offline Evaluation으로 detector/profile 결과 비교
6. Simulator QA scenario로 UI edge case 확인
7. 빌드 확인
8. 커밋

권장 명령:

```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
swift test --no-parallel
```

```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
xcodebuild \
  -project SleepSoundApp.xcodeproj \
  -scheme SleepSoundApp \
  -configuration Debug \
  -destination generic/platform=iOS \
  -derivedDataPath .derivedData \
  CODE_SIGNING_ALLOWED=NO \
  build
```

## Synthetic Audio Test

실제 오디오 파일 없이 코드에서 생성한 synthetic pattern으로 detector와 report pipeline을 확인합니다.

사용 예:

- silence
- lowEnergyNoise
- highEnergyNoise
- snoreLikeBurst
- coughLikeBurst
- gaspLikeBurst
- movementLikeNoise

주요 목적:

- detector가 완전히 깨졌는지 빠르게 확인
- zero-event analysis가 동작하는지 확인
- measurementDuration과 receivedAudioDuration이 구분되는지 확인
- privacy/storage 회귀를 자동 점검

## Dataset Replay

Dataset Replay는 로컬 WAV/CAF/M4A 파일을 `AudioChunk` stream으로 변환해 `SleepAnalyzer`에 주입합니다.

원칙:

- 공개 데이터셋을 자동 다운로드하지 않습니다.
- 개인 오디오 파일을 repo에 포함하지 않습니다.
- 데이터셋 라이선스는 사용자가 직접 확인합니다.
- replay 결과는 detector 개발/회귀 테스트용이며 실사용 품질을 확정하지 않습니다.

문서:

- `Docs/DATASET_REPLAY.md`

## Offline Evaluation

Offline Evaluation은 manifest에 정의된 segment를 여러 detector profile로 평가합니다.

확인 항목:

- rawCandidateCount
- preSmoothingCandidateCount
- postSmoothingEventCount
- finalEventCountByType
- reject reason
- zero-event reason
- RMS/energy summary
- profile별 결과 차이

threshold 변경은 자동 적용하지 않습니다. 결과를 보고 개발자가 수동으로 검토합니다.

문서:

- `Tools/OfflineEvaluation/README.md`
- `Docs/DETECTOR_TUNING.md`

## Simulator QA

Simulator QA는 실제 iPhone 없이 다양한 리포트 상태를 mock으로 재현합니다.

DEBUG 빌드에서:

```text
설정 > 개발 > Simulator QA Scenario
```

확인 대상:

- 홈 화면
- 수면 리포트
- 이벤트 타임라인
- 개인정보/저장소 화면
- detector diagnostics
- zero-event analysis
- 이벤트 오디오 저장 ON/OFF
- orphan sample 상태
- 낮은 오디오 커버리지

문서:

- `Docs/SIMULATOR_QA.md`

## 실기기 테스트가 필요한 조건

다음 작업은 실제 iPhone에서 확인합니다.

- `AudioCaptureService` 또는 `AudioSessionManager` 변경
- 마이크 권한 흐름 변경
- background audio mode 또는 lifecycle 처리 변경
- 이벤트 오디오 샘플 저장/재생/삭제 흐름 변경
- 장시간 실행 안정성 확인
- 배터리/발열 확인
- overnight smoke test
- 출시 전 smoke test

## 실기기 테스트를 생략해도 되는 조건

다음 변경은 대체로 Simulator-first 검증만으로 충분합니다.

- 순수 모델/계산 로직 수정
- 수면 점수 계산 수정
- 이벤트 aggregation 수정
- detector threshold 문서화
- Offline Evaluation 도구 수정
- Dataset Replay 도구 수정
- Simulator QA preset 수정
- README/Docs만 수정
- UI copy 또는 레이아웃의 작은 정리

단, 오디오 캡처, 권한, background 동작, 저장 파일 재생처럼 iOS 기기 동작에 의존하는 부분을 건드렸다면 실기기 확인으로 넘어갑니다.

## 커밋 전 체크

- `swift test --no-parallel`
- `xcodebuild ... generic/platform=iOS ... build`
- `git ls-files "*.wav" "*.caf" "*.m4a"` 결과 없음
- HealthKit은 read-only이고 권한 요청이 건강 데이터 연결 flow에만 묶여 있음
- HealthKit save/delete/write API 없음
- 서버/네트워크 코드 없음
- 전체 밤 원본 오디오 저장 코드 없음
- 확정적 의료 표현 없음
