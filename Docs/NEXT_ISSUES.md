# Next Issues

이 문서는 Daily Rhythm 전환, Extended Health Metrics, Fitdays CSV/text import, detector diagnostics, README/UI Gallery screenshot 상태 정리 이후의 후속 작업 후보를 정리합니다.

실기기 없이 진행 가능한 simulator-first batch는 2026-05-07 기준 대부분 완료했습니다. 이제 가장 중요한 evidence는 실제 iPhone에서만 얻을 수 있는 capture/background/overnight, 실제 HealthKit 권한 조합, 실제 Fitdays export/share 노출, 실제 침대 배치 detector 결과입니다.

## 우선순위 후보

1. Fitdays export availability 실기기 재확인 실행 및 private evidence 기록
2. 실제 HealthKit permission flow manual QA 실행 및 private evidence 기록
3. 실제 iPhone smoke test
4. TestFlight 내부 테스트 실행
5. Legal/App Review 최종 재확인
6. detector threshold tuning with real data
7. Core ML model 실제 앱 target 적용. `Docs/CORE_ML_MODEL_INTEGRATION.md` gate와 실제 iPhone smoke evidence 확보 후 진행
8. log-mel spectrogram extractor/model 검토. 현재는 `log_mel_v0_placeholder` shape contract만 고정했고, 실제 extraction/training은 충분한 local reviewed sample과 false-positive-like 검토 후 별도 진행

## Release / App Store 준비

- 최종 앱 아이콘 asset 검증 도구와 review sheet 준비 완료. 제출 전 실제 기기 홈 화면/TestFlight 표면 확인 필요
- App Store screenshot headline copy와 mock scenario plan은 정리 완료
- App Store screenshot marketing visual은 현재 blocked 상태입니다. 내부 QA label과 crop 품질 문제를 고친 뒤 재캡처하고 App Store Connect size export를 다시 실행합니다.
- App Store Connect용 screenshot size/export 절차 정리
- App Store product page copy 후보 정리 완료. 제출 직전 App Store Connect 화면에서 글자 수/locale 최종 확인 필요
- `Docs/APP_RELEASE_GUIDE.md` 최신화
- Release readiness 자동 gate 테스트 추가 완료. TestFlight 후보 전 반복 실행 필요
- TestFlight 내부 테스트 체크리스트 정리 완료, 실제 내부 테스트 실행은 TestFlight build와 실기기 필요
- App Review 관점에서 HealthKit read-only, 개인정보, 비의료 목적 문구 audit 문서화 완료, 제출 직전 최종 재확인 필요

주의:

- App Store screenshot은 mock data와 simulator scenario 기반으로만 생성합니다.
- 실제 개인 건강 데이터, 실제 HealthKit 데이터, 실제 오디오 샘플을 사용하지 않습니다.
- 건강 상태를 단정하거나 수면 소리와 건강 지표 사이의 원인과 결과를 주장하지 않습니다.
- 기존 README/App Store screenshot 후보는 release-approved가 아니며, 품질 gate 통과 전에는 README/App Store/user-facing 문서에 렌더링하지 않습니다.

## Daily Rhythm / Health Dashboard

- 실제 HealthKit permission flow를 iPhone에서 manual QA
- `Docs/QA_GUIDE.md`의 HealthKit permission flow smoke와 evidence template 준비 완료
- 권한 없음/일부 허용/데이터 없음 상태를 실제 기기에서 확인
- Omron Connect 혈압 source와 Fitdays 체중/체성분 source 표시를 실제 Apple 건강앱 데이터로 장기 검증
- 혈압/체성분 dashboard의 7일/30일/90일 추세 copy와 empty state 재점검
- Cross Metric 화면의 matched sample 부족 상태와 낮은 오디오 커버리지 표시는 no-match / low-coverage-excluded / included-count-shortfall로 분리 완료. 실제 데이터로 manual QA 필요
- Daily Rhythm Report와 Morning Brief의 데이터 준비 상태/제한 항목 표시를 실제 사용 흐름에서 확인
- 저녁 체크인 로컬 저장은 구현 완료. 실제 사용 흐름에서 같은 날짜 저장/재진입/건강 캘린더 표시가 자연스러운지 manual QA 필요

주의:

- HealthKit은 read-only로 유지합니다.
- HealthKit에 수면 소리 점수, 오늘의 리듬 점수, 이벤트, 리포트, 피드백을 쓰지 않습니다.
- HealthKit 데이터는 서버로 전송하지 않습니다.

## Extended Health Metrics / Fitdays Import

- 실제 Fitdays 앱에서 CSV/export 메뉴와 월별 데이터 복사 텍스트 구조를 재확인
- `Docs/QA_GUIDE.md`와 `Docs/HEALTH_DATA_GUIDE.md`의 실기기 export availability runbook 준비 완료
- export 메뉴가 계속 보이지 않으면 Apple 건강앱 read-only 표준 지표를 기본 경로로 유지
- `FitdaysImportFallbackGuidance`와 `FitdaysImportView`의 read-only fallback UX 보강 완료
- `.csv`, `.tsv`, `.txt` 지원 안내와 sample 0개 preview recovery 안내 보강 완료
- 월별 붙여넣기 parser는 compact date, 주요 한국어 alias, `짜` date column, time-first date, annotated header, `--` placeholder regression을 포함합니다. 새 구조가 확인되면 개인값을 제거한 synthetic fixture만 추가합니다.
- import preview는 처리 row, 저장 가능 샘플, 건너뛴 row 해석, 확인 필요 row, 지원하지 않는 column을 분리해 보여줍니다.
- 큰 월별 붙여넣기는 화면에 전체 원문을 계속 렌더링하지 않고 요약/앞부분 preview만 표시하며, parsing은 UI thread 밖에서 수행합니다.
- 붙여넣기 입력, 미리보기, 저장 버튼은 가까운 위치로 정리했고 저장 완료 메시지는 저장 버튼 근처에 표시합니다. 실제 Fitdays 월별 텍스트로 manual QA 필요
- 중복 import는 같은 source type, metric, measuredAt 기준으로 정리하고, 값이 다른 중복은 새 붙여넣기 기준 교체를 사용자가 명시해야 저장합니다.
- 저장된 가져오기 기록은 현재 저장소 기준 샘플 수와 삭제 흐름을 제공하며, 실제 파일명/local path는 표시하지 않습니다.
- Fitdays 고유 지표 로컬 수동 입력은 구현 완료. 실제 개인 값은 repository에 남기지 말고, private QA note로 입력 UX와 중복 교체 흐름만 확인
- 실제 Fitdays CSV/export file을 확보한 경우에만 수동 import QA
- 실제 Fitdays 월별 데이터 복사 텍스트를 확보한 경우 붙여넣기 preview/import QA
- 실제 Fitdays share/export에서 Open in NightBreath가 표시되는지 iPhone에서 확인
- Share Extension 필요 여부는 실제 export/share 경로가 확인된 뒤 결정
- invalid CSV/TSV, unknown column, 날짜 parsing 실패, 중복 import 처리 확인
- 지원 지표 column 없음, import 가능한 sample 0개인 파일을 저장 전에 거부하는지 확인
- import result, batch 삭제, extended metric sample 삭제 흐름은 구현되어 있으며 실제 Fitdays 파일/붙여넣기 데이터로 manual QA 필요
- HealthKit 기반 지표와 Fitdays 로컬 전용 지표 배지/출처 표시는 `Fitdays CSV · 로컬`과 내부 ID 숨김 기준으로 보강 완료. 실제 데이터로 manual QA 필요
- HealthMetricsOverviewView category grouping 회귀 테스트 보강 완료
- Health Dashboard는 권한 없음/HealthKit 샘플 없음/로컬 import만 있음/mixed source edge state를 분리 표시하고, Apple 건강앱 read-only 조회 범위와 원본 앱 동기화 확인 안내를 최근 1년 기준으로 제공합니다. 실제 HealthKit 권한 조합과 Fitdays import 결과로 manual QA 필요
- Health Dashboard는 한 번 연결한 뒤 앱 재실행/업데이트 후에도 permission sheet 없이 HealthKit sample을 재조회하고, `HealthKit 읽기 결과`와 `혈압 HealthKit 샘플` date range를 표시합니다. 실제 iPhone에서 2월~4월 혈압 sample이 calendar에 들어오는지 manual QA 필요
- 홈은 종합 평가, 수면은 측정/결과, 건강은 HealthKit+수면+Fitdays 데이터 허브, 설정은 앱 설정으로 역할을 재정리했습니다. 실제 개인 데이터 규모에서 건강 tab CTA가 기대 날짜를 고르는지, 캘린더 상세가 너무 길거나 느리지 않은지 manual QA 필요
- 건강 캘린더 월 이동 계산 재사용, 대량 synthetic dataset 회귀 테스트, metric 그래프 평균선/요약/출처 범례/empty copy guard는 simulator-first로 보강했습니다. 실제 개인 데이터 규모에서 체감 성능과 가독성 QA 필요
- MetricDetailView 기간 선택, source filter, empty state 회귀 테스트 보강
- HealthCalendarView 월 이동, 날짜 선택, inline DailyMeasurementDetailContent grouping 회귀 테스트 보강
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
- template/privacy matrix 기반 민감 수치/source 노출 회귀 테스트 보강 완료
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
- 실제 iPhone smoke result template, preflight, redaction checklist, failure triage는 `Docs/REAL_DEVICE_QA_RUNBOOK.md`에 준비 완료, 실행과 private evidence는 실기기 피드백 대기
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
- `recentAudioReplaySummary`로 최근 미리듣기 buffer를 같은 analyzer에 replay했을 때 raw/final 이벤트가 생기는지 확인
- `inputLevelAssessment == goodCoverageLowInputLevel` 세션은 민감도 조정보다 iPhone 거리, 마이크 방향, 케이스/침구 가림을 먼저 바꿔 재측정
- 매우 낮은 RMS의 low-band/낮은 ZCR near-miss가 `balanced`에서는 raw-only 후보로 남고 `conservative`에서는 꺼지는지 실제 배치별로 비교
- balanced low-amplitude snore guard 이후 실제 코골이 짧은 DEBUG 샘플과 quiet/noise negative 샘플을 같은 배치에서 replay
- RMS 0.045 미만 snore 후보는 `rule.lowLevelSnore*`/relative-energy/low-band/ZCR/high-band/centroid guard 통과 여부를 QA 기록에 남김
- 침대 위 충전 상태 거리에서 snore raw 후보가 생기는지, 같은 배치의 조용한 구간/주변 소음 negative에서 snore raw 후보가 늘지 않는지 확인
- Offline Evaluation으로 verySensitive / sensitive / balanced / conservative / veryConservative profile 비교
- `Tools/OfflineEvaluation/validate_sample_manifest.py`로 replay manifest schema, 짧은 segment duration, git-tracked audio 참조 여부를 로컬에서 먼저 확인
- 민감도 preset synthetic guard는 보강 완료. 실제 iPhone 배치별 raw/final count와 false-positive-like negative는 private evidence로 확인 필요
- Offline Evaluation profile 비교 markdown quick summary 보강 완료
- Offline Evaluation snore/negative snapshot과 balanced delta markdown summary 보강 완료
- Offline Evaluation zero-event stage breakdown markdown summary 보강 완료
- DEBUG detector diagnostics QA readout 공유 보강 완료
- 이벤트 오디오 샘플 세션별 개수/폴더 용량 초과 guard 보강 완료
- false-positive-like / false-negative-like segment 검토
- tuning report 기반 threshold 후보 정리
- Core ML 변환 결과를 앱 target에 추가하는 절차 gate 문서화 완료. 실제 artifact target 적용은 보류
- `Tools/Training/validate_coreml_integration_gate.sh`로 모델 artifact/app target 참조가 gate 전 상태에 섞이지 않았는지 로컬 확인 가능
- Rule-based와 Core ML backend 비교 결과를 실제 iPhone QA 기록에 연결

주의:

- 모델 성능을 확정적으로 표현하지 않습니다.
- 공개/개인 오디오 파일을 repo에 포함하지 않습니다.
- threshold 변경은 자동 적용하지 않고 수동 검토합니다.
- 전체 밤 원본 오디오 저장 없이 feature/diagnostics summary만 사용합니다.

## UI Gallery / Screenshot

- README 대표 screenshot 8개는 `Docs/Screenshots/README/`에 원본, `Docs/Screenshots/README/cropped/`에 crop 후보가 있지만 현재 `blocked, recapture required`입니다.
- README screenshot은 crop 정렬, 주요 content 가독성, 내부 QA label 노출 여부를 다시 본 뒤 승인된 파일만 README에 렌더링합니다.
- Health Calendar, Daily Measurement Detail, Metric Detail, Fitdays Import 대표 screenshot은 후보 파일이 있으나 visual QA 전까지 문서에서 이미지 렌더링하지 않습니다.
- SleepRecording, PrivacySettings, zero-event, low-coverage, event audio storage off, DetectorTuning screenshot은 simulator direct scenario 후보 파일이 있으나 visual QA 전까지 렌더링하지 않습니다.
- 혈압, 체성분, 교차 보기와 health/metric/cross edge screenshot은 simulator direct scenario 후보 파일이 있으나 visual QA 전까지 렌더링하지 않습니다.
- onboarding/device/calibration, replay/audio/sample capture 상세 screenshot은 simulator direct scenario 후보 파일이 있으나 DEBUG-only는 internal-only로 유지합니다.
- App Store raw/review-cropped 후보 8개는 기존 파일에 내부 `Simulator QA` label 노출 가능성이 있어 blocked/re-capture required 상태입니다. 새 screenshot launch scenario는 public source copy를 사용하지만 기존 이미지는 재캡처 전까지 승인하지 않습니다.
- `Docs/UI_GALLERY.md`는 품질 gate 전까지 screenshot image markdown을 만들지 않으며, regression test로 quarantine 상태를 확인합니다.
- trend, morning/evening check-in, Daily Health Card export/share state, report empty, simulator scenario 화면은 직접 launch scenario와 simulator capture 후보를 추가했습니다. visual QA 전까지는 quality review pending/internal-only 상태로 유지
- 재캡처 후 `Tools/Screenshots/build_screenshot_review_sheet.sh` 기반 visual QA와 App Store export PNG 확인 절차 유지
- `Docs/Screenshots/screenshot_status.tsv`의 상태값을 기준으로 `release-approved` 후보만 README/App Store/user-facing 문서에 렌더링
- screenshot 경로나 상태 변경 시 `Tools/Screenshots/validate_screenshot_manifest.sh`로 manifest schema, 파일 존재 여부, UI 문서 PNG 참조 등록 여부를 먼저 확인
- Light/Dark 쌍을 추가로 캡처할 때 같은 mock state를 사용
- README에는 대표 화면만 유지하고 전체 화면 설명은 `Docs/UI_GALLERY.md`에서 관리

## 문서 유지보수

- `Docs/CURRENT_STATUS.md` 완료/보류 항목 최신화
- `Docs/UI_SCREEN_MAP.md` screenshot 상태와 navigation 관계 최신화
- `Docs/DESIGN_SYSTEM.md` screenshot 문서화 원칙 유지
- `QA_CHECKLIST.md` 실제 iPhone manual QA 역할 유지
- forbidden wording scan과 민감정보 scan을 release 전 반복
