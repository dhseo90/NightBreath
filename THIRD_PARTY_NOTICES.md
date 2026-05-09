# Third-Party Notices

This file summarizes third-party materials and development dependencies that
matter for the public repository licensing review. It is not a substitute for
the upstream license texts.

## ESC-50 Dataset

- Upstream project: https://github.com/karolpiczak/ESC-50
- Repository path if included: `Datasets/ESC-50-master/**`
- Upstream license: Creative Commons Attribution-NonCommercial 3.0 for the
  full ESC-50 dataset.
- Upstream subset note: clips marked as ESC-10 are distributed under Creative
  Commons Attribution 3.0.
- Required handling: keep the upstream ESC-50 `LICENSE` and clip attribution
  notices with any distribution that includes ESC-50 files.
- NightBreath license boundary: Apache-2.0 does not apply to ESC-50 dataset
  files.

Commercial App Store builds, paid products, commercial model training, and
commercial redistribution must not rely on ESC-50 content unless the use is
separately reviewed and allowed by the relevant rights holders.

## Dependency Inventory

The complete dependency inventory is maintained in `Docs/DEPENDENCIES.md`.

## Python Training Dependencies

The training tools under `Tools/Training/` depend on Python packages installed
by the developer; their source code is not vendored in this repository.

| Package | Declared version constraint | Use | Upstream license |
| --- | --- | --- | --- |
| `joblib` | `>=1.3` | model serialization | BSD-3-Clause |
| `numpy` | `>=1.26` | numeric feature handling | BSD-style / modified BSD |
| `PyYAML` | `>=6.0` | training config parsing | MIT |
| `scikit-learn` | `>=1.4` | baseline model training | BSD |
| `coremltools` | `>=7.2` | local Core ML conversion | BSD-3-Clause |

If these dependencies are vendored or redistributed in a binary package later,
include the corresponding upstream license notices in that distribution.

## Apple Platform Frameworks

The app uses Apple platform SDK frameworks such as SwiftUI, AVFoundation,
HealthKit, Core ML, and related iOS tooling. These frameworks are not vendored
in this repository. Their use is governed by Apple's developer terms and
platform documentation, not by this repository's Apache-2.0 license.

Apple, iPhone, HealthKit, Core ML, App Store, and TestFlight are third-party
names or marks. Mentions in this repository are descriptive and do not imply
endorsement, sponsorship, or affiliation.

## Fitdays and Omron References

Fitdays and Omron are referenced only to describe user-controlled local import
or Apple Health/HealthKit read-only scenarios. This repository does not include
Fitdays or Omron logos, SDKs, APIs, reverse-engineered integrations, or account
systems.
