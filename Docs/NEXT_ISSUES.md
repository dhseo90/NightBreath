# Next Issues

이 문서는 Daily Rhythm 전환과 README/UI Gallery screenshot 반영 이후의 후속 작업 후보를 정리합니다.

## 우선순위 후보

1. 최종 앱 아이콘 고품질 아트워크 제작
2. App Store screenshot marketing version 준비
3. Daily Health Card image export/share 설계와 구현
4. 실제 iPhone smoke test
5. 실제 HealthKit permission flow manual QA
6. TestFlight 준비
7. App Store copy draft 보강
8. Legal/App Review audit
9. detector threshold tuning with real data
10. Core ML model 실제 앱 target 적용

## Release / App Store 준비

- 최종 앱 아이콘 제작과 device별 asset 확인
- App Store screenshot headline copy와 mock scenario 재캡처
- App Store Connect용 screenshot size/export 절차 정리
- App Store product page copy 최종 점검
- `Docs/APP_STORE_COPY_DRAFT.md`와 `Docs/APP_STORE_SCREENSHOT_GUIDE.md` 최신화
- TestFlight 내부 테스트 체크리스트 정리
- App Review 관점에서 HealthKit read-only, 개인정보, 비의료 목적 문구 재검토

주의:

- App Store screenshot은 mock data와 simulator scenario 기반으로만 생성합니다.
- 실제 개인 건강 데이터, 실제 HealthKit 데이터, 실제 오디오 샘플을 사용하지 않습니다.
- 건강 상태를 단정하거나 수면 소리와 건강 지표 사이의 원인과 결과를 주장하지 않습니다.

## Daily Rhythm / Health Dashboard

- 실제 HealthKit permission flow를 iPhone에서 manual QA
- 권한 없음/일부 허용/데이터 없음 상태를 실제 기기에서 확인
- Omron Connect 혈압 source와 Fitdays 체중/체성분 source 표시를 실제 Apple 건강앱 데이터로 장기 검증
- 혈압/체성분 dashboard의 7일/30일/90일 추세 copy와 empty state 재점검
- Cross Metric 화면의 matched sample 부족 상태와 낮은 오디오 커버리지 표시 재점검
- Daily Rhythm Report와 Morning Brief의 data quality 표시를 실제 사용 흐름에서 확인

주의:

- HealthKit은 read-only로 유지합니다.
- HealthKit에 수면 소리 점수, 오늘의 리듬 점수, 이벤트, 리포트, 피드백을 쓰지 않습니다.
- HealthKit 데이터는 서버로 전송하지 않습니다.

## Daily Health Card

- SwiftUI view to image rendering 방식 검토
- `minimal`, `standard`, `detailed` privacy level별 export 전 확인 화면 설계
- 민감 수치가 포함된 카드의 사용자 명시 액션 흐름 설계
- 저장/공유 실패 state와 취소 state 설계
- README용 대표 카드와 App Store용 카드의 표시 데이터 분리

주의:

- 자동 공유, 서버 업로드, 외부 SDK 사용은 제외합니다.
- 사용자가 명시적으로 선택하기 전에는 민감 데이터가 들어간 이미지를 export/share하지 않습니다.

## 실제 iPhone QA

- foreground 1분 smoke test
- 화면 잠금 3분 smoke test
- 앱 백그라운드 3분 smoke test
- 잠금 30분 테스트
- 충전 상태 overnight test
- 이벤트 오디오 샘플 opt-in ON/OFF 각각 확인
- HealthKit 연결/거부/일부 허용 흐름 확인
- 배터리/발열 확인

`QA_CHECKLIST.md`는 일상 개발 중 매번 실행하는 체크리스트가 아니라 release/TestFlight 전 실제 iPhone manual QA 문서로 유지합니다.

## Detector / ML

- 공개 또는 로컬 데이터셋 manifest 작성
- snore / non-snore labeled segment 정리
- Offline Evaluation으로 conservative / balanced / sensitive profile 비교
- false-positive-like / false-negative-like segment 검토
- tuning report 기반 threshold 후보 정리
- Core ML 변환 결과를 앱 target에 추가하는 절차 검증
- Rule-based와 Core ML backend 비교 DEBUG UI 보강

주의:

- 모델 성능을 확정적으로 표현하지 않습니다.
- 공개/개인 오디오 파일을 repo에 포함하지 않습니다.
- threshold 변경은 자동 적용하지 않고 수동 검토합니다.

## UI Gallery / Screenshot

- README 대표 screenshot 8개는 `Docs/Screenshots/README/`에 반영 완료
- Privacy, edge state, DEBUG-only 상세 screenshot은 `Docs/UI_GALLERY.md`의 `screenshot pending` 항목으로 유지
- Light/Dark 쌍을 추가로 캡처할 때 같은 mock state를 사용
- README에는 대표 화면만 유지하고 전체 화면 설명은 `Docs/UI_GALLERY.md`에서 관리

## 문서 유지보수

- `Docs/CURRENT_STATUS.md` 완료/보류 항목 최신화
- `Docs/UI_SCREEN_MAP.md` screenshot 상태와 navigation 관계 최신화
- `Docs/DESIGN_SYSTEM.md` screenshot 문서화 원칙 유지
- `QA_CHECKLIST.md` 실제 iPhone manual QA 역할 유지
- forbidden wording scan과 민감정보 scan을 release 전 반복
