# QA README

이 문서는 NightBreath / 밤숨의 Simulator-first 개발과 검증 흐름을 설명합니다.

## 개발 전략

반복 개발은 Simulator-first로 진행합니다. 실제 iPhone 테스트는 마이크 캡처, 화면 잠금/백그라운드 녹음, 배터리/발열, 장시간 overnight 안정성처럼 Simulator가 대체할 수 없는 범위에 집중합니다.

## 기본 검증

- `git diff --check`
- Swift unit tests
- synthetic audio tests
- Dataset Replay
- Offline Evaluation
- Simulator QA scenarios
- Clean simulator smoke automation
- main/sub README link validation
- iOS Debug build
- 필요 시 Release build

## Simulator QA

DEBUG 빌드에서는 Simulator QA Scenario를 통해 예시 수면 세션과 edge state를 적용할 수 있습니다.

주요 확인 항목:

- 수면 소리 점수
- 측정 품질
- 실제 오디오 수신 시간
- 이벤트 수
- 이벤트 오디오 샘플 저장 ON/OFF
- 저장 용량과 orphan 샘플 상태
- detector diagnostic summary
- zero-event analysis

완전 초기화 상태 회귀는 `Tools/UI/run_clean_simulator_smoke.sh`로 simulator erase, Debug build, fresh install, first launch capture, 주요 screenshot scenario capture를 한 번에 실행합니다. system permission prompt와 짧은 수면 리포트 생성처럼 실제 탭이 필요한 부분은 manifest에 `manual-required`로 남기고 수동 확인합니다.

## 문서 링크 QA

main README와 주요 sub README를 수정한 뒤에는 아래 gate를 실행합니다.

```bash
Tools/Docs/validate_readme_links.sh
```

루트 README의 sub README table, 문서 간 상대 링크, README에 렌더링하는 screenshot image path가 깨지면 실패합니다.

## 실제 iPhone 테스트가 필요한 경우

- 오디오 캡처 코드 변경
- AVAudioSession/background 설정 변경
- 이벤트 오디오 샘플 실제 저장/재생 확인
- 화면 잠금 상태 녹음 확인
- 앱 백그라운드 녹음 확인
- 배터리/발열 확인
- 장시간 overnight 안정성 확인
- 출시 전 smoke test

## 관련 문서

| 문서 | 내용 |
| --- | --- |
| [QA_GUIDE](../QA_GUIDE.md) | 전체 QA 기준 |
| [V1_1_ROADMAP](../V1_1_ROADMAP.md) | v1.1.0 안정화와 추가 기능 검증 범위 |
| [SIMULATOR_QA_AUTOMATION](../SIMULATOR_QA_AUTOMATION.md) | clean simulator smoke와 XcodeBuildMCP fallback 절차 |
| [DEVELOPMENT_WORKFLOW](../DEVELOPMENT_WORKFLOW.md) | 개발/검증 workflow |
| [DATASET_REPLAY](../DATASET_REPLAY.md) | Dataset Replay 사용법 |
| [DATASET_GUIDE](../DATASET_GUIDE.md) | 데이터셋 준비 원칙 |
| [LICENSING](../LICENSING.md) | 공개 repository의 mixed-license 경계 |
| [DEPENDENCIES](../DEPENDENCIES.md) | 외부 dependency와 version/license inventory |
| [DETECTOR_TUNING](../DETECTOR_TUNING.md) | detector tuning과 diagnostics |
| [FEATURE_VALIDATION](../FEATURE_VALIDATION.md) | feature validation 기준 |
| [REAL_DEVICE_QA_RUNBOOK](../REAL_DEVICE_QA_RUNBOOK.md) | 실제 iPhone QA runbook |
