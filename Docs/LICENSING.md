# Licensing

NightBreath / 밤숨은 mixed-license repository입니다.

## 기본 범위

별도 표기가 없는 NightBreath 소스 코드, 테스트, 로컬 개발 도구, 프로젝트 소유 문서, 프로젝트 소유 앱 asset은 Apache License 2.0으로 배포합니다.

관련 파일:

- `LICENSE`
- `LICENSES/Apache-2.0.txt`
- `NOTICE.md`
- `THIRD_PARTY_NOTICES.md`
- `Docs/DEPENDENCIES.md`

## 외부 의존성 표기

외부 dependency 이름, 선언된 version constraint, 라이선스, vendoring 여부는 [DEPENDENCIES](DEPENDENCIES.md)에 따로 정리합니다.

현재 Swift/iOS 앱 target은 외부 Swift package, CocoaPods, Carthage dependency를 사용하지 않습니다. Python training 도구만 `Tools/Training/requirements.txt`의 minimum-version constraint를 사용하며, exact lockfile은 아직 없습니다.

## ESC-50 경계

`Datasets/ESC-50-master/**`가 repository 또는 배포 archive에 포함되는 경우, 해당 파일은 NightBreath 소유물이 아니며 Apache-2.0으로 재라이선스하지 않습니다.

ESC-50 upstream 기준:

| 범위 | 라이선스 | NightBreath 처리 |
| --- | --- | --- |
| ESC-50 전체 dataset | CC BY-NC 3.0 | upstream license와 attribution 유지 |
| ESC-10 subset | CC BY 3.0 | upstream license와 attribution 유지 |

ESC-50의 full dataset에는 NonCommercial 제한이 있습니다. App Store 상업 배포, 유료 제품, 회사/상업 모델 학습, 상업적 재배포와 연결할 때는 ESC-50 사용 여부를 별도 법무 검토 대상으로 둡니다.

## 모델과 출력물

생성된 `.mlmodel`, `.mlpackage`, 평가 output, checkpoint, 개인 sample, 실제 local manifest는 생성 시점의 데이터 출처와 라이선스를 따릅니다. 명시적으로 검토하고 표시하지 않은 출력물을 Apache-2.0으로 간주하지 않습니다.

현재 기본 원칙:

- 개인 오디오 sample은 repository에 포함하지 않습니다.
- 실제 개인 CSV/export file은 repository에 포함하지 않습니다.
- 공개 dataset은 자동 다운로드하지 않습니다.
- 공개 dataset을 포함해 배포하는 경우 upstream license와 attribution을 함께 보존합니다.

## 문서/스크린샷/아이콘

NightBreath가 직접 만든 문서, screenshot, app icon, review sheet는 별도 표기가 없으면 Apache-2.0 범위에 포함합니다. 단, screenshot 안에 등장하는 Apple platform surface, HealthKit, App Store, TestFlight, Fitdays, Omron 같은 이름은 각 소유자의 상표 또는 서비스명일 수 있으며, NightBreath 라이선스가 그 상표권을 부여하지 않습니다.

## 공개 레포 표시 문구

공개 레포 소개에는 다음처럼 표현합니다.

```text
NightBreath code and project-owned materials are licensed under Apache-2.0.
The repository is mixed-license when third-party dataset content is present.
ESC-50 dataset files remain under their upstream Creative Commons licenses and
are not covered by Apache-2.0.
```
