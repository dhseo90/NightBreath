# Dependency Inventory

이 문서는 public repository에서 확인할 수 있는 외부 의존성 이름, 선언된 version constraint, 라이선스, 배포 범위를 정리합니다.

## 요약

| 영역 | 상태 |
| --- | --- |
| Swift Package Manager | 외부 package dependency 없음 |
| CocoaPods / Carthage | 사용하지 않음 |
| Vendored third-party source | 없음 |
| Python training dependencies | `Tools/Training/requirements.txt`에 선언 |
| Apple SDK frameworks | Xcode/iOS SDK 제공 framework 사용, repository에 vendoring하지 않음 |
| GitHub Actions | `actions/checkout@v6` 사용, repository에 vendoring하지 않음 |
| Public dataset | ESC-50을 포함 배포하는 경우 upstream CC license 유지 |

## Swift / iOS

`Package.swift`는 local target만 정의합니다. `Package.resolved`, `XCRemoteSwiftPackageReference`, CocoaPods, Carthage dependency는 없습니다.

| Dependency | Declared version | Scope | License handling |
| --- | --- | --- | --- |
| External Swift package | none | app/tests/tools | 해당 없음 |

## Apple SDK Frameworks

아래 framework는 Apple platform SDK에서 제공되며 repository에 포함하거나 재배포하지 않습니다. 사용 조건은 Apple developer terms와 SDK license를 따릅니다.

| Framework / module | Use |
| --- | --- |
| SwiftUI | app UI |
| Foundation | models, storage, utilities |
| Combine | app state and audio pipeline coordination |
| AVFoundation | audio capture, playback, replay |
| HealthKit | read-only health data adapter |
| CoreML | optional local model provider path |
| Charts | dashboard and report charts |
| UIKit / Photos / UniformTypeIdentifiers | iOS integration, export/share, document import |
| CoreGraphics / CoreText / ImageIO | local app icon and review sheet tooling |
| Testing | Swift test suite |

## Python Training Tools

Python dependencies are development/training dependencies only. They are not vendored in this repository, not bundled into the iOS app, and currently have minimum-version constraints rather than exact lockfile pins.

Declared in `Tools/Training/requirements.txt`:

| Package | Declared version constraint | Use | Upstream license |
| --- | --- | --- | --- |
| `joblib` | `>=1.3` | model serialization | BSD-3-Clause |
| `numpy` | `>=1.26` | numeric feature handling | BSD-style / modified BSD |
| `PyYAML` | `>=6.0` | training config parsing | MIT |
| `scikit-learn` | `>=1.4` | baseline classifier training/evaluation | BSD |
| `coremltools` | `>=7.2` | local Core ML conversion | BSD-3-Clause |

Because no lockfile is committed, exact installed versions are environment-specific. This is acceptable while training remains local/development-only and model artifacts are not part of the release build. If reproducible training builds become release-critical, generate a local frozen snapshot such as `Tools/Training/requirements.lock.local.txt`, review it, then commit an intentionally named lockfile and update this table with exact resolved versions.

Local snapshot command:

```sh
cd Tools/Training
python3 -m pip freeze --require-virtualenv > requirements.lock.local.txt
```

## CI / Automation

CI workflow dependencies are not vendored in this repository. They are pinned by action major version in `.github/workflows/`.

| Dependency | Declared version | Scope | Upstream license |
| --- | --- | --- | --- |
| `actions/checkout` | `v6` | GitHub Actions repository checkout | MIT |

## Dataset Content

| Dataset | Repository path if included | License |
| --- | --- | --- |
| ESC-50 full dataset | `Datasets/ESC-50-master/**` | CC BY-NC 3.0 |
| ESC-10 subset | `Datasets/ESC-50-master/**` clips marked as ESC-10 by upstream metadata | CC BY 3.0 |

ESC-50/ESC-10 files are not covered by NightBreath's Apache-2.0 code license. See `LICENSE`, `LICENSES/`, `THIRD_PARTY_NOTICES.md`, and `Docs/LICENSING.md`.

## Maintenance Checklist

Update this file when:

- a new Swift package, Python package, SDK wrapper, binary framework, model runtime, or vendored source dependency is added;
- a GitHub Actions dependency or action version changes;
- a dependency version constraint changes;
- a lockfile is introduced;
- a public dataset or generated model artifact is committed or distributed;
- App Store/TestFlight packaging starts bundling any third-party binary or model artifact.
- `Tools/Release/audit_tracked_artifacts.sh`, `Tools/Release/audit_app_bundle_artifacts.sh`, or `Tools/Training/validate_model_provenance_gate.sh` changes the release artifact policy.
