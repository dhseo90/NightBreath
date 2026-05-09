# Privacy README

이 문서는 NightBreath / 밤숨의 개인정보, 로컬 저장, 이벤트 오디오 샘플, HealthKit read-only 원칙을 설명합니다.

## 기본 원칙

- 서버 업로드를 하지 않습니다.
- 클라우드 처리를 하지 않습니다.
- 외부 API 호출을 하지 않습니다.
- 외부 분석 SDK와 광고 SDK를 추가하지 않습니다.
- 계정 시스템을 만들지 않습니다.
- 기본 동작으로 밤새 원본 오디오 전체를 저장하지 않습니다.
- 잠꼬대/말소리를 텍스트로 변환하지 않습니다.
- HealthKit은 read-only로만 사용합니다.
- Fitdays 서버/API 직접 연결, 비공식 연결 방식, reverse engineering을 하지 않습니다.

## 로컬 저장 대상

- 수면 세션
- 수면 이벤트 요약
- 밤 수면 리포트
- 아침/저녁 컨디션 기록
- 사용자가 opt-in한 짧은 이벤트 오디오 샘플
- 이벤트별 사용자 feedback metadata
- Fitdays local import sample과 import batch metadata

## 이벤트 오디오 샘플

이벤트 오디오 샘플은 사용자가 설정에서 켠 경우에만 저장됩니다. 기본값은 꺼짐입니다.

- 이벤트 전 2초, 이벤트 후 3초
- 샘플 최대 10초
- 세션당 최대 100개
- 폴더 최대 200MB
- 저장 위치: `Application Support/NightBreath/EventAudioSnippets/`
- 기존 저장 샘플은 자동 삭제하지 않고 사용자가 삭제할 수 있어야 합니다.

이 샘플은 전체 밤 원본 오디오가 아니며, sleep talk 내용을 텍스트로 변환하지 않습니다.

## HealthKit 개인정보 경계

- HealthKit 권한 요청은 건강 데이터 대시보드에서 사용자가 연결을 선택한 경우에만 수행합니다.
- 앱 첫 실행, 수면 시작, 수면 종료 흐름에서는 HealthKit 권한을 요청하지 않습니다.
- 앱은 HealthKit에 수면 소리 점수, 오늘의 리듬 점수, 이벤트, 리포트, feedback을 쓰지 않습니다.
- HealthKit 데이터를 서버나 외부 앱으로 전송하지 않습니다.

## 관련 문서

| 문서 | 내용 |
| --- | --- |
| [PRIVACY_STORAGE_AUDIT](../PRIVACY_STORAGE_AUDIT.md) | 개인정보/저장소 audit와 회귀 기준 |
| [APP_REVIEW_AUDIT](../APP_REVIEW_AUDIT.md) | App Review 관점의 privacy audit |
| [APP_RELEASE_GUIDE](../APP_RELEASE_GUIDE.md) | 출시 전 privacy/release gate |
| [HEALTH_DATA_GUIDE](../HEALTH_DATA_GUIDE.md) | HealthKit read-only와 Fitdays local import 경계 |
