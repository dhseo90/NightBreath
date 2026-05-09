# Public Repository Final Review

이 문서는 NightBreath / 밤숨 repository를 public으로 전환하기 전 확인할 release/legal evidence입니다. 기준일은 2026-05-09입니다.

## 결론

현재 Git content 기준으로 public 전환을 막는 blocker는 발견하지 못했습니다.

전제:

- ESC-50 dataset file은 Git에 포함하지 않습니다.
- ESC-50은 local detector smoke QA에 사용한 사실을 문서화했습니다.
- repository는 mixed-license로 표기합니다.
- NightBreath 소유 code/docs/assets는 Apache-2.0으로 배포합니다.
- third-party dataset content가 나중에 포함되는 경우 upstream license와 attribution을 유지합니다.
- model artifact는 아직 Git이나 앱 target에 포함하지 않습니다.

## GitHub Actions First Run

| 항목 | 결과 |
| --- | --- |
| Local commit | `d5a6385 Add release artifact guardrails` pushed to `main` |
| Remote query via GitHub app | 404 / repository not visible to current tool |
| Public unauthenticated Actions API | 404 / repository not visible publicly at check time |
| Local equivalent gates | passed |
| Manual GitHub UI check | pending |

수동 확인:

1. GitHub repository의 Actions tab을 엽니다.
2. `Release Guardrails` workflow가 `main` push에서 실행됐는지 확인합니다.
3. `Licensing and Artifact Guardrails` job의 checkout, tracked artifact, Core ML pre-integration, model provenance, README link, trademark copy 단계가 통과했는지 확인합니다.
4. 실패한 경우 실패 step log를 private note에 기록하고 repository에는 민감한 account/email/token 값을 남기지 않습니다.

## Release Bundle Evidence

| 항목 | 결과 |
| --- | --- |
| Build command | `xcodebuild -project SleepSoundApp.xcodeproj -scheme SleepSoundApp -configuration Release -destination generic/platform=iOS -derivedDataPath .derivedData-release-audit CODE_SIGNING_ALLOWED=NO build` |
| Build result | passed after running with local Xcode/cache permissions |
| Bundle path | `.derivedData-release-audit/Build/Products/Release-iphoneos/SleepSoundApp.app` |
| Bundle artifact audit | `Tools/Release/audit_app_bundle_artifacts.sh` passed |
| Finding | no ESC-50, dataset/sample folder, local output, bundled audio, or training artifact found in the built app bundle |

## GitHub Public Settings Checklist

| 항목 | 상태 | 확인 방법 |
| --- | --- | --- |
| Repository visibility | manual pending | GitHub Settings에서 public 전환 직전 확인 |
| Repository description | manual pending | `NightBreath / 밤숨 - on-device sleep sound and daily rhythm report app` 같은 설명 사용 |
| Topics | manual pending | `ios`, `swiftui`, `healthkit`, `on-device`, `sleep`, `wellness`, `privacy` 후보 |
| License display | accepted caveat | GitHub badge가 mixed/custom license를 단순하게 표시하지 못할 수 있음. 기준 source는 `LICENSE`와 `Docs/LICENSING.md` |
| Actions permissions | configured | workflow는 `contents: read`만 사용 |
| Branch protection | manual pending | public 전환 후 `main`에 required checks를 설정할지 결정 |
| Secrets | local scan passed | `Tools/Release/audit_public_repo_privacy.sh` |

## Legal Final Pass

| 항목 | 상태 | evidence |
| --- | --- | --- |
| Main license | pass | `LICENSE`, `LICENSES/Apache-2.0.txt` |
| Mixed license boundary | pass | `Docs/LICENSING.md`, `THIRD_PARTY_NOTICES.md` |
| ESC-50 included in Git | pass: not included | `Tools/Release/audit_tracked_artifacts.sh` |
| ESC-50 local use disclosed | pass | `Docs/DETECTOR_TUNING.md`, `Tools/OfflineEvaluation/README.md` |
| ESC-50 NonCommercial caveat | pass | `LICENSE`, `Docs/LICENSING.md`, `Docs/MODEL_PROVENANCE_CHECKLIST.md` |
| Dependency inventory | pass | `Docs/DEPENDENCIES.md` |
| App bundle artifact check | pass | `Tools/Release/audit_app_bundle_artifacts.sh` on Release `.app` |
| Model artifact provenance | pass: no model present | `Tools/Training/validate_model_provenance_gate.sh` |
| Trademark/affiliation wording | pass | `Tools/Release/audit_trademark_copy.sh` |
| Secret/privacy scan | pass | `Tools/Release/audit_public_repo_privacy.sh` |

## Release Decision

Public repository conversion is acceptable after the manual GitHub UI checks above are completed. Do not claim GitHub Actions remote success until the Actions tab is checked with an authenticated GitHub session.
