# 실제 iPhone이 필요한 테스트

NightBreath / 밤숨은 Simulator-first 방식으로 개발합니다.

반복 개발 중에는 실제 iPhone 테스트를 매번 수행하지 않습니다. Dataset Replay, Offline Evaluation, Simulator QA, synthetic regression test로 먼저 확인하고, 실제 기기 특성에 의존하는 항목만 iPhone에서 확인합니다.

## 지금 당장 매번 하지 않아도 되는 경우

- 문서만 수정한 경우
- 순수 모델/계산 로직만 수정한 경우
- 수면 점수 또는 이벤트 집계만 수정한 경우
- synthetic audio test로 재현 가능한 detector 로직만 수정한 경우
- Dataset Replay / Offline Evaluation 도구만 수정한 경우
- Simulator QA preset 또는 mock UI 상태만 수정한 경우
- 작은 UI copy 정리만 한 경우

이 경우 권장 확인:

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

## 실제 iPhone 테스트가 필요한 조건

다음 항목은 실제 iPhone에서 확인합니다.

- `AudioCaptureService` 변경
- `AudioSessionManager` 변경
- 마이크 권한 UX 변경
- background audio mode 변경
- 앱 lifecycle 처리 변경
- interruption 처리 변경
- 이벤트 오디오 샘플 실제 저장/재생/삭제 변경
- 저장소 경로 또는 파일 정책 변경
- 배터리/발열 확인
- 장시간 안정성 확인
- 출시 전 smoke test

## 실제 iPhone에서만 충분히 확인 가능한 항목

- 실제 iPhone 마이크 입력 품질
- 화면 잠금 상태에서 오디오 수신 유지 여부
- 앱 백그라운드 상태에서 오디오 수신 유지 여부
- 충전 중 장시간 실행 시 배터리와 발열
- 전화, 알림, 이어폰 연결 같은 오디오 interruption
- overnight 안정성
- 침대 옆, 매트리스 옆 등 device placement 영향
- 이벤트 전후 짧은 오디오 샘플 opt-in 저장/재생/삭제 동작

## 권장 실기기 흐름

1. foreground 1분 테스트
2. 화면 잠금 3분 테스트
3. 앱 백그라운드 3분 테스트
4. 잠금 30분 테스트
5. 충전 상태 overnight 테스트
6. 저장 용량, 이벤트 수, 배터리, 발열 확인

자세한 background/lock 절차는 `Docs/BACKGROUND_RECORDING_QA.md`를 참고합니다.

## Dataset Replay로 대체할 수 없는 이유

Simulator와 로컬 파일은 마이크 하드웨어, iOS background audio 정책, 기기 발열, 사용자의 방 환경을 그대로 반영하지 않습니다. 따라서 replay 결과가 좋아도 실제 overnight 테스트는 별도로 진행해야 합니다.

리포트는 수면 중 소리 기반 지표입니다. 이 앱은 진단 목적의 의료기기가 아닙니다.
