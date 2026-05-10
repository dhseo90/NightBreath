# Clean Simulator QA 2026-05-10

이 문서는 iPhone 17 Pro simulator를 shutdown, erase, boot 한 뒤 NightBreath / 밤숨을 새로 설치해 확인한 clean-state QA 결과입니다.

반복 실행용 스크립트는 `Tools/UI/run_clean_simulator_smoke.sh`입니다. 이 스크립트는 simulator erase, Debug build, fresh install, first launch capture, 주요 screenshot scenario capture를 자동화하고, system permission prompt/짧은 수면 리포트처럼 실제 탭이 필요한 항목은 manifest에 `manual-required`로 남깁니다.

## 환경

- Simulator: iPhone 17 Pro, iOS 26.4
- Simulator UDID: redacted in public docs
- Build: Debug simulator build
- App bundle id: `com.local.NightBreath`
- Reset: `simctl shutdown`, `simctl erase`, `simctl boot`
- Install: freshly built `SleepSoundApp.app`

## 임시 캡처

임시 검수 캡처 위치:

```text
/private/tmp/nightbreath_clean_state_qa_20260510/
```

검수 파일:

- `first_launch.png`
- `home_after_onboarding.png`
- `report_after_short_sleep.png`
- `sleep_finalizing_slow.png`
- `health_refresh_states.png`
- `debug_audio_samples_fixture.png`
- `privacy_snapshot.png`

## Clean-State Flow

| 단계 | 결과 | 판정 |
| --- | --- | --- |
| First launch | 앱 데이터가 없는 상태에서 온보딩 첫 화면 진입 | 통과 |
| Onboarding | 다음 버튼으로 개인정보, 전체 오디오 미저장, opt-in, 배치, 마이크 권한, 캘리브레이션 안내를 순서대로 확인 | 통과 |
| Home after onboarding | 홈 루트 진입, 하단 tab bar 배경 정상, 검정/파랑 bar 재현 없음 | 통과 |
| Sleep start root | 홈 CTA로 수면 시작 화면 진입, 마이크 권한 미결정 상태와 privacy copy 표시 | 통과 |
| Microphone permission | 수면 시작 시점에만 simulator mic permission prompt 표시 | 통과 |
| Short sleep session | 권한 허용 후 기록 시작, 약 10초 측정 뒤 수면 종료와 리포트 생성 완료 | 통과 |
| Health entry | 홈의 건강 상세 CTA로 Health dashboard 진입, HealthKit read-only 안내와 연결 버튼 표시 | 통과 |

## DEBUG Scenario Smoke

| Scenario | 결과 | 판정 |
| --- | --- | --- |
| `sleepFinalizingSlow` | clean simulator에서 launch argument 직접 진입, 녹음 중단과 리포트 정리 상태 분리 표시 | 통과 |
| `healthRefreshStates` | 새로고침 대기/읽는 중/완료/빈 결과/차단 상태 fixture 표시 | 통과 |
| `debugAudioSamplesFixture` | 실제 오디오 파일 없이 다건 샘플 fixture 표시 | 통과 |
| `privacySnapshot` | 개인정보 보호 cover 표시 | 통과 |

정식 gallery 추적용 capture는 `Docs/Screenshots/screenshot_status.tsv`와 `Docs/Screenshots/screenshot_visual_review.tsv`에 별도로 반영했습니다. DEBUG 3개는 internal-only로 유지하고, privacy snapshot cover는 QA navigation chrome을 제거한 뒤 UI Gallery 전용 `release-approved`로 판정했습니다.

## 관찰

- clean install 후 첫 실행에서 HealthKit 권한을 자동 요청하지 않았습니다.
- 이벤트 오디오 샘플 opt-in 기본값은 꺼짐으로 표시됐습니다.
- 수면 시작 시점에만 마이크 권한 prompt가 표시됐고, permission copy는 원본 전체 오디오 미저장/온디바이스 분석 경계를 유지했습니다.
- 짧은 simulator 측정 종료 후 리포트 생성은 완료됐고, 종료 후 장시간 멈춤은 재현되지 않았습니다.
- DEBUG-only scenario는 release-facing 문서 이미지로 렌더링하지 않고 pending/internal tracking만 유지합니다.

## 남은 범위

- 실제 iPhone overnight, 잠금/백그라운드, 배터리/발열 검증은 simulator로 대체할 수 없습니다.
- 실제 HealthKit 권한 조합과 실제 Health 데이터 표시 검증은 실기기에서 별도 확인해야 합니다.
- 실제 Fitdays 앱 export/share sheet는 simulator clean-state flow에서 확인하지 않았습니다.
