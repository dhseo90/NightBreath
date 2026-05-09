# TestFlight Local Preflight Evidence

이 문서는 실제 TestFlight 설치/실행이나 실기기 QA 없이 진행한 로컬 대체 preflight 결과입니다. 실제 내부 테스트 완료를 의미하지 않으며, 실제 TestFlight evidence는 private QA store에 별도로 기록합니다.

## Run Summary

| 항목 | 값 |
| --- | --- |
| run date | 2026-05-09 |
| reviewer | Codex local substitute |
| TestFlight install/run | not run |
| real device required flows | excluded |
| private evidence draft | generated outside repository; path intentionally omitted |
| repository status during draft generation | clean |
| result | local preflight pass; TestFlight manual run pending |

## Commands

```sh
Tools/Release/prepare_testflight_evidence.sh
Tools/Docs/validate_readme_links.sh
Tools/Release/audit_release_copy.sh
git diff --check
```

## Local Result Matrix

| Check | Local result | Evidence |
| --- | --- | --- |
| private evidence draft generation | pass | `Tools/Release/prepare_testflight_evidence.sh` refused repository output and generated a draft outside the repo |
| release-facing document links | pass | `Tools/Docs/validate_readme_links.sh` |
| release copy/privacy/HealthKit gates | pass | `Tools/Release/audit_release_copy.sh` |
| repository whitespace | pass | `git diff --check` |
| TestFlight install/first launch | not run | Requires TestFlight and real device |
| foreground/background/overnight behavior | not run | Requires real device |

## Remaining Manual Gate

- TestFlight internal build must still be installed on a real iPhone.
- Foreground/background/overnight behavior must still be recorded in private evidence.
- HealthKit permission combinations and Fitdays export/manual import evidence remain real-device/manual pending.
- Completed private evidence must not be committed to the repository.

