# NightBreath Feature Lab Dataset Guide

이 문서는 실제 Core ML 모델을 만들기 전에 수면 소리 feature와 rule-based detector 동작을 검증하기 위한 개발용 라벨링 가이드입니다.

V1 원칙:
- 공개 데이터셋을 자동 다운로드하지 않습니다.
- 개인 오디오 파일을 git에 커밋하지 않습니다.
- 공개 데이터셋을 repository 또는 배포 archive에 포함하는 경우 upstream license와 attribution을 그대로 유지합니다.
- 원본 전체 오디오를 앱 저장 기능으로 추가하지 않습니다.
- sleep talk 내용을 텍스트로 변환하지 않습니다.
- 결과는 수면 중 소리 기반 웰니스 참고 정보로만 다룹니다.

## 샘플 위치

개인 샘플:

```text
Samples/Personal/
```

공개 데이터셋을 수동으로 내려받아 검토하는 위치:

```text
Samples/Public/
```

두 폴더는 기본적으로 `.gitignore`에 포함되어 있습니다. 로컬 테스트에서는 repo에 올리지 않고 사용합니다. 다만 공개 데이터셋을 의도적으로 repository 또는 배포 archive에 포함하는 경우에는 [LICENSING](LICENSING.md)의 mixed-license 경계를 따르고, 해당 데이터셋의 upstream license와 attribution을 함께 보존합니다.

## 공개 데이터셋 라이선스

NightBreath 소스 코드와 프로젝트 소유 문서는 Apache-2.0이지만, 공개 데이터셋은 각 upstream 라이선스를 따릅니다.

| 데이터셋 | 기본 처리 |
| --- | --- |
| ESC-50 전체 dataset | CC BY-NC 3.0. NonCommercial 제한이 있어 상업 앱/모델 학습/재배포에는 별도 검토가 필요합니다. |
| ESC-10 subset | CC BY 3.0. upstream attribution을 유지합니다. |
| license unknown dataset | repository에 포함하지 않고 local-only 참고용으로만 둡니다. |

## 라벨 목록

Feature Lab에서 사용하는 라벨은 앱의 `SleepEventType`과 맞춥니다.

| Label | 한국어 UI 표현 | 설명 |
| --- | --- | --- |
| `snore` | 코골기 | 낮은 주파수 성분과 반복적인 에너지가 있는 코골기 후보 |
| `bruxismLike` | 이갈이 의심 소리 | 마찰음 또는 고주파성 반복 패턴이 있는 후보 |
| `breathingPauseSuspected` | 호흡정지 의심 구간 | 긴 저에너지/무음 구간 후보 |
| `gaspLike` | gasp-like 회복 호흡 | 짧고 급격한 회복 호흡처럼 보이는 후보 |
| `coughLike` | 기침 의심 소리 | 짧고 강한 burst 패턴 후보 |
| `sleepTalkLike` | 잠꼬대/말소리 의심 | 말소리처럼 보이는 이벤트 여부만 기록, 내용 텍스트화 없음 |
| `movementLike` | 움직임 의심 소리 | 침구 마찰 또는 기기 주변 움직임 후보 |
| `environmentalNoise` | 환경 소음 | 외부 소음, 생활 소음, 기기 주변 큰 소리 후보 |
| `awakeningSuspected` | 각성 의심 구간 | 큰 소리 또는 움직임 뒤 각성 가능성이 있는 후보 |
| `unknown` | 알 수 없는 소리 | 위 라벨로 분류하기 어려운 후보 |

## 라벨링 규칙

- 한 샘플에는 가능한 가장 중요한 라벨 하나를 우선 지정합니다.
- 여러 이벤트가 섞인 경우 짧은 구간으로 나누어 라벨링합니다.
- 기침 의심 소리, gasp-like 회복 호흡, 환경 소음은 서로 섞이기 쉬우므로 peak가 큰 생활 소음은 `environmentalNoise`로 우선 분리합니다.
- `bruxismLike`는 이갈이 의심 소리 후보로만 사용합니다. 조용한 clenching은 iPhone 마이크만으로 감지하기 어렵습니다.
- `bruxismLike`는 침구 마찰음, 손톱 긁힘, 침대 소음, 반려동물 소리와 혼동될 수 있어 아침 feedback으로 다시 확인합니다.
- gasp-like 라벨은 “회복 호흡으로 의심되는 소리” 후보를 뜻하며 상태를 확정하는 의미가 아닙니다.
- 사람 말소리는 `sleepTalkLike` 여부만 표시하고 내용을 기록하지 않습니다.
- 주변 대화 내용, 이름, 주소, 민감 정보가 들어간 샘플은 Feature Lab에 넣지 않습니다.
- 라벨이 애매하면 `unknown`으로 둡니다.
- `breathingPauseSuspected`는 소리 기반 후보일 뿐이며 상태를 확정하는 표현으로 쓰지 않습니다.

## 권장 메타데이터

샘플별로 별도 로컬 메모를 남길 때는 다음 정도만 기록합니다.

```text
fileName,label,startTime,endTime,notes
sample-001.wav,snore,00:00:02.0,00:00:05.0,low-frequency repeating pattern
```

주의:
- 이 메타데이터도 개인 정보가 들어갈 수 있으므로 기본적으로 git에 올리지 않습니다.
- 원본 오디오에서 텍스트 내용을 추출하거나 저장하지 않습니다.

## 합성 샘플 우선 사용

현재 테스트는 실제 녹음 파일 대신 코드로 만든 synthetic audio fixture를 사용합니다.

예:
- silence
- low energy noise
- high energy noise
- short burst
- repeated pulse pattern
- low frequency tone

개인 샘플은 rule-based detector 튜닝이 꼭 필요할 때만 로컬에서 수동으로 추가합니다.

## iPhone DEBUG 샘플 수집

실제 iPhone에서 짧은 검증 샘플이 필요하면 DEBUG 빌드의 “개발자용 샘플 수집” 화면을 사용합니다.

- 라벨을 먼저 선택합니다.
- 2초/3초/5초 중 하나를 눌러 명시적으로 캡처합니다.
- 파일명은 timestamp와 label을 포함합니다.
- metadata JSON과 feature CSV가 함께 저장됩니다.
- 전체 밤 오디오를 저장하는 용도로 사용하지 않습니다.
