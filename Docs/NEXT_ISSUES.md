# Next Issues

이 문서는 Daily Rhythm 전환, Extended Health Metrics, Fitdays CSV import, README/UI Gallery screenshot 반영 이후의 후속 작업 후보를 정리합니다.

## 우선순위 후보

1. 최종 앱 아이콘 고품질 아트워크 제작
2. App Store screenshot marketing version 준비
3. Fitdays export availability 재확인 및 fallback UX 보강
4. EHM regression test 강화
5. 혈압/체성분/교차 보기/edge screenshot 추가
6. 실제 HealthKit permission flow manual QA
7. App Store screenshot final export 절차 정리
8. 실제 iPhone smoke test
9. TestFlight 준비
10. Legal/App Review audit
11. detector threshold tuning with real data
12. Core ML model 실제 앱 target 적용

## Release / App Store 준비

- 최종 앱 아이콘 제작과 device별 asset 확인
- App Store screenshot headline copy와 mock scenario plan은 정리 완료
- App Store screenshot marketing visual 재캡처와 App Store Connect size export
- App Store Connect용 screenshot size/export 절차 정리
- App Store product page copy 최종 점검
- `Docs/APP_RELEASE_GUIDE.md` 최신화
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

## Extended Health Metrics / Fitdays Import

- 실제 Fitdays 앱에서 CSV/export 메뉴가 보이는지 재확인
- export 메뉴가 계속 보이지 않으면 Apple 건강앱 read-only 표준 지표를 기본 경로로 유지
- Fitdays 고유 지표는 manual input 또는 로컬 입력 기능 follow-up으로 분리
- 실제 Fitdays CSV/export file을 확보한 경우에만 수동 import QA
- 실제 Fitdays share/export에서 Open in NightBreath가 표시되는지 iPhone에서 확인
- Share Extension 필요 여부는 실제 export/share 경로가 확인된 뒤 결정
- invalid CSV, unknown column, 날짜 parsing 실패, 중복 import 처리 확인
- 지원 지표 column 없음, import 가능한 sample 0개인 파일을 저장 전에 거부하는지 확인
- import result, batch 삭제, extended metric sample 삭제 흐름 확인
- HealthKit 기반 지표와 Fitdays 로컬 전용 지표 배지/출처 표시 재점검
- HealthMetricsOverviewView category grouping 회귀 테스트 보강 완료
- MetricDetailView 기간 선택, source filter, empty state 회귀 테스트 보강
- HealthCalendarView 월 이동, 날짜 선택, DailyMeasurementDetailView grouping 회귀 테스트 보강
- `Docs/HEALTH_DATA_GUIDE.md`의 Fitdays CSV/export 차이 추적

주의:

- Fitdays 서버/API에 직접 연결하지 않습니다.
- 비공식 연결 방식이나 reverse engineering을 사용하지 않습니다.
- Fitdays 계정 로그인, 앱 내부 데이터 접근, UI automation, 자동 scraping을 만들지 않습니다.
- HealthKit에 Fitdays import 값을 쓰지 않습니다.
- 실제 개인 CSV 파일을 repository에 포함하지 않습니다.

## Daily Health Card

- `ImageRenderer` 기반 SwiftUI view to image renderer는 카드 미리보기 화면에 반영 완료
- `minimal`, `standard`, `detailed` privacy level별 export preview UI 보강
- 민감 수치가 포함된 카드의 별도 confirmation sheet 구현 완료
- 공유 취소/completed state UI 보강 완료
- 사진 앱 또는 파일 저장 전용 흐름 구현 완료
- privacy level별 export snapshot/regression test 추가 완료
- 서버 업로드, 외부 SDK, 자동 공유가 없음을 확인하는 privacy test 유지/확장
- README용 대표 카드와 App Store용 카드의 표시 데이터 분리 완료
- App Store 후보 카드가 `appStoreMarketing` display profile과 minimal privacy를 사용하는지 screenshot 재캡처 때 확인

주의:

- 자동 공유, 서버 업로드, 외부 SDK 사용은 제외합니다.
- 사용자가 명시적으로 선택하기 전에는 민감 데이터가 들어간 이미지를 export/share하지 않습니다.
- export preview에는 실제 personal CSV 파일명, 실제 local path, 실제 HealthKit device 식별자를 표시하지 않습니다.

## 실제 iPhone QA

- foreground 1분 smoke test
- P0 fix 이후 `Docs/QA_GUIDE.md`의 Foreground stop smoke / Double stop tap / Lock/background short stop 통과
- stop 이후 actual audio received time이 증가하지 않는 evidence template 기록
- 화면 잠금 3분 smoke test
- 앱 백그라운드 3분 smoke test
- 실제 코골이 또는 코골기 유사 smoke에서 raw/reject/final diagnostics 기록
- zero-event인 경우 no audio / no raw / smoothing dropped / conservative threshold 가능성 중 하나로 분류되는지 확인
- 잠금 30분 테스트
- 충전 상태 overnight test
- 이벤트 오디오 샘플 opt-in ON/OFF 각각 확인
- HealthKit 연결/거부/일부 허용 흐름 확인
- 배터리/발열 확인

`QA_CHECKLIST.md`는 일상 개발 중 매번 실행하는 체크리스트가 아니라 release/TestFlight 전 실제 iPhone manual QA 문서로 유지합니다.

실제 실행 순서와 민감정보 없는 기록 템플릿은 `Docs/QA_GUIDE.md`를 기준으로 합니다. 실제 개인 건강 데이터, 실제 Fitdays CSV 파일명, 실제 오디오 파일명은 repository에 기록하지 않습니다.

## Detector / ML

- 공개 또는 로컬 데이터셋 manifest 작성
- snore / non-snore labeled segment 정리
- 실제 iPhone zero-event 세션에서 `DetectorDiagnostics` snapshot 수동 수집
- 수집된 diagnostics로 feature 후보 없음, raw 후보 전 제외, smoothing drop, confidence drop, feature scale mismatch를 분류
- `snoreLikeFeatureRejectReasonCounts`와 p50/p90 feature 분포를 실제 iPhone 배치별로 비교
- balanced low-amplitude snore guard 이후 실제 코골이 짧은 DEBUG 샘플과 quiet/noise negative 샘플을 같은 배치에서 replay
- RMS 0.050 미만 snore 후보는 low-band/ZCR/high-band/centroid guard 통과 여부를 QA 기록에 남김
- Offline Evaluation으로 conservative / balanced / sensitive profile 비교
- Offline Evaluation profile 비교 markdown quick summary 보강 완료
- false-positive-like / false-negative-like segment 검토
- tuning report 기반 threshold 후보 정리
- Core ML 변환 결과를 앱 target에 추가하는 절차 검증
- Rule-based와 Core ML backend 비교 결과를 실제 iPhone QA 기록에 연결

주의:

- 모델 성능을 확정적으로 표현하지 않습니다.
- 공개/개인 오디오 파일을 repo에 포함하지 않습니다.
- threshold 변경은 자동 적용하지 않고 수동 검토합니다.
- 전체 밤 원본 오디오 저장 없이 feature/diagnostics summary만 사용합니다.

## UI Gallery / Screenshot

- README 대표 screenshot 8개는 `Docs/Screenshots/README/`에 원본, `Docs/Screenshots/README/cropped/`에 README용 crop으로 반영 완료
- README screenshot crop/재캡처는 앱 UI나 simulator device가 바뀔 때 유지보수 항목으로 관리
- Health Calendar, Daily Measurement Detail, Metric Detail, Fitdays Import 대표 screenshot은 반영 완료
- SleepRecording, PrivacySettings, zero-event, low-coverage, event audio storage off, DetectorTuning screenshot은 simulator direct scenario로 캡처 완료
- 혈압, 체성분, 교차 보기, onboarding/device/calibration, replay/audio/sample capture 상세 screenshot은 추가 캡처 후보
- 직접 launch scenario가 없는 상세 화면은 `Docs/UI_GALLERY.md`의 `screenshot pending` 항목으로 유지
- Light/Dark 쌍을 추가로 캡처할 때 같은 mock state를 사용
- README에는 대표 화면만 유지하고 전체 화면 설명은 `Docs/UI_GALLERY.md`에서 관리

## 문서 유지보수

- `Docs/CURRENT_STATUS.md` 완료/보류 항목 최신화
- `Docs/UI_SCREEN_MAP.md` screenshot 상태와 navigation 관계 최신화
- `Docs/DESIGN_SYSTEM.md` screenshot 문서화 원칙 유지
- `QA_CHECKLIST.md` 실제 iPhone manual QA 역할 유지
- forbidden wording scan과 민감정보 scan을 release 전 반복
