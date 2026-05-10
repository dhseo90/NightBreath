# Simulator QA Automation

이 문서는 실기기 없이 반복 가능한 NightBreath / 밤숨 simulator QA 실행 방식을 정리합니다. 실제 iPhone overnight, 잠금/백그라운드, 실제 HealthKit 데이터, 실제 Fitdays 앱 export는 이 문서의 범위가 아닙니다.

## Clean Simulator Smoke

완전 초기화 상태 검증은 simulator 하나를 지정해 erase 후 새 Debug build를 설치합니다. 의도치 않은 삭제를 막기 위해 `SIMULATOR_ID`와 `NIGHTBREATH_ALLOW_SIM_ERASE=1`을 모두 요구합니다.

```bash
SIMULATOR_ID=<simulator-udid> \
NIGHTBREATH_ALLOW_SIM_ERASE=1 \
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
Tools/UI/run_clean_simulator_smoke.sh
```

기본 출력은 `/tmp/nightbreath-clean-simulator-smoke-*` 아래에 저장됩니다. 필요하면 `OUTPUT_DIR`로 바꿀 수 있습니다.

자동 캡처 항목:

- clean install 첫 실행 onboarding
- screenshot scenario 기반 `sleepStart`
- report empty state
- privacy snapshot cover
- slow sleep finalization state
- health refresh feedback states
- DEBUG audio sample fixture

스크립트는 `clean_simulator_smoke_manifest.tsv`를 함께 생성합니다. 시스템 permission prompt를 탭하거나 실제 짧은 수면 세션을 시작/종료하는 부분은 macOS/Xcode 환경마다 자동화 안정성이 낮아 `manual-required`로 남깁니다.

## Manual Remainder

clean simulator script 실행 뒤 실제 Simulator UI에서 아래만 손으로 확인합니다.

| 항목 | 기대 결과 |
| --- | --- |
| Microphone permission prompt | 온디바이스 분석과 전체 원본 오디오 미저장 copy가 보이고, 수면 시작 시점에만 표시 |
| Short sleep report | 마이크 허용 후 짧게 기록하고 수면 종료를 누르면 리포트 생성 완료 |
| HealthKit permission | 첫 실행과 수면 시작/종료 흐름에서는 HealthKit 권한을 자동 요청하지 않음 |

2026-05-10 clean-state manual evidence는 `Docs/Screenshots/CLEAN_SIMULATOR_QA_2026-05-10.md`에 기록했습니다.

## XcodeBuildMCP Fallback

XcodeBuildMCP가 `simctl`을 찾지 못하거나 CoreSimulator service 접근에 실패하면 아래 fallback을 사용합니다.

```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
/usr/bin/xcodebuild \
  -project SleepSoundApp.xcodeproj \
  -scheme SleepSoundApp \
  -configuration Debug \
  -destination id=<simulator-udid> \
  -derivedDataPath .derivedData-clean-simulator-smoke \
  CODE_SIGNING_ALLOWED=NO \
  build
```

시나리오별 캡처는 `xcrun simctl launch --terminate-running-process`와 `--nightbreath-screenshot-scenario`를 사용합니다. 이 fallback은 local simulator QA용이며, release build 검증은 별도로 `Release` configuration에서 실행합니다.

## Safety Boundary

- 실제 개인 건강 데이터, 실제 Fitdays CSV 파일명, 실제 오디오 파일명을 캡처하지 않습니다.
- DEBUG-only scenario는 README, App Store, release-facing marketing image로 렌더링하지 않습니다.
- 이 자동화는 real-device QA를 대체하지 않습니다.
- simulator erase는 지정한 simulator의 앱 데이터와 privacy permission을 삭제하므로 전용 QA simulator에서만 실행합니다.
