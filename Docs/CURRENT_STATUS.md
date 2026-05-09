# Current Status

이 문서는 NightBreath / 밤숨 V1 프로토타입의 현재 구현 상태와 의도적으로 남겨둔 범위를 정리합니다.

## 2026-05-07 Simulator-first Batch

실기기 없이 진행 가능한 후속 개발 batch는 privacy/export, Fitdays local import, health dashboard edge state, detector diagnostics, event audio snippet guard, real-device QA runbook, screenshot 문서 상태 정렬까지 완료했습니다.

- 실제 iPhone이 필요한 항목은 capture/background/overnight, 실제 HealthKit 권한 조합, 실제 Fitdays export/share 노출, 실제 코골기 배치별 detector evidence로 남겼습니다.
- README 대표 8개는 루트 README의 문서 preview로 렌더링하지만 `release-approved`는 아닙니다. App Store 후보 8개는 여전히 `blocked, recapture required`로 관리합니다.
- 전체 밤 원본 오디오 저장, 서버/네트워크 전송, HealthKit write, 실제 개인 오디오/CSV fixture 추가는 하지 않았습니다.
- 현재 안정화 기준은 `git diff --check`, `swift test --no-parallel`, generic iOS Debug build입니다.

## 2026-05-08 Simulator-first Stability Follow-up

수면 시작 직후 UI가 느려지고 장시간 세션 중 종료될 수 있다는 실기기 피드백 이후, 실기기 없이 검증 가능한 장시간 처리 guard를 우선 보강했습니다.

- `SleepAudioProcessingPipeline`은 5시간 synthetic chunk 세션 finalize가 bounded state로 빠르게 끝나는 회귀 테스트를 추가했습니다.
- DEBUG `AudioDebugView`는 live RMS/energy/low-band 분포를 bounded sampler로 요약하고, smoothing 진단용 raw output은 최근 후보만 유지합니다.
- AppState의 chunk별 feature/detector processing task는 detached utility task로 실행하고, UI snapshot 반영만 MainActor로 되돌립니다.
- 건강 tab 첫 화면은 최근 날짜 상세, 건강 캘린더, Fitdays 붙여넣기 바로가기를 상단에 배치해 건강 데이터 탐색 단계를 줄였습니다.
- Fitdays 월간 붙여넣기는 synthetic 31일 comma text preview와 건강 캘린더 detail build를 함께 돌리는 성능 회귀 테스트로 보호합니다.
- EveningCheckIn은 화면 안 임시 상태가 아니라 기기 안 JSON 저장소에 로컬 저장하고, HealthCalendar/DailyMeasurementDetail의 저녁 체크인 section에 연결합니다.
- Screenshot review sheet manifest는 canonical `screenshot_status.tsv`보다 느슨한 승인 상태를 표시하지 않도록 회귀 테스트를 추가했습니다.
- AppState audio processing source test는 UI publish가 chunk마다 발생하지 않고 throttle된 snapshot으로 반영되는 구조를 확인합니다.
- Trend, morning/evening check-in, Daily Health Card export/share state, report empty, SimulatorScenarioView screenshot은 직접 launch scenario로 캡처했고 visual QA 전까지 quality review pending/internal-only 상태로 유지합니다.

## 완료

- SwiftUI 앱 구조
- 실제 iPhone 오디오 캡처 구조
- 마이크 권한 요청 흐름
- AVAudioSession recording 설정
- AVAudioEngine input tap 기반 audio chunk 생성
- 앱 세션 시간과 실제 오디오 수신 시간 분리
- 실제 분석 시간 tracking
- 오디오 커버리지 계산
- 수면 종료 tap 이후 capture-first stop flow와 post-stop chunk diagnostics
- 수면 세션 시작/종료 flow
- 수면 이벤트 모델
- 수면 리포트 모델
- 아침 컨디션 체크인 모델
- 로컬 저장소
- 수면 리포트 UI
- 홈 대시보드
- 이벤트 타임라인
- 최근 7일/30일/90일 수면 트렌드 UI
- 수면 소리 점수
- 이벤트 집계
- rule-based detector
- detector protocol
- Core ML adapter placeholder
- detector diagnostics
- real-device zero-event detector observability
- snore-like feature candidate / raw candidate split diagnostics
- raw/pre-smoothing/post-smoothing/final event type count diagnostics
- feature distribution diagnostics for RMS/energy/band/zero-crossing/centroid
- latest feature/raw candidate debug summary in diagnostics
- zero-event analysis
- low-amplitude snore-like recall guard for balanced rule-based profile
- 이벤트 오디오 샘플 저장/재생/삭제
- 이벤트별 사용자 feedback 저장/삭제/export 구조
- 이벤트 오디오 샘플 opt-in 설정
- 저장된 이벤트 오디오 용량 표시
- 이벤트 오디오 샘플 세션별 개수/폴더 용량 초과 guard
- orphan sample cleanup
- 온보딩, iPhone 배치 가이드, 30초 캘리브레이션 flow
- 개인정보/저장소 관리 UI
- DEBUG 오디오 디버그 화면
- DEBUG 수동 짧은 샘플 수집 화면
- Dataset Replay
- Offline Evaluation
- Offline Evaluation sample manifest local validation gate
- profile comparison 도구
- Detector Offline Evaluation profile 비교 markdown quick summary
- Detector Offline Evaluation snore/negative snapshot과 balanced delta markdown summary
- Detector Offline Evaluation zero-event stage breakdown markdown summary
- Detector Offline Evaluation public negative category hotspot markdown summary
- ESC-50 public dataset local manifest generator for detector smoke QA
- DEBUG detector diagnostics QA readout 공유
- snore baseline/backend comparison 도구
- Snore ML v0 training/변환 준비 도구
- Snore ML future log-mel shape-only placeholder schema
- multiclass event classifier 준비 도구
- Core ML model target 적용 전 dry-run validation gate
- Recording 화면 UI refresh throttle과 상세 diagnostics collapse
- close low+mid snore-like texture guard와 voice-like/steady hum negative regression
- cough/movement dominant transient가 snore로 동시에 승격되는 경로 guard
- retained input chunk 전체를 보는 spectral feature extraction과 delayed snore chunk regression
- Simulator QA scenarios
- Real-device QA runbook preflight/redaction/failure triage
- Regression Test Suite
- NightBreath 디자인 시스템
- HealthKit mock/protocol 기반 건강 데이터 dashboard 방향
- HealthKit read-only 권한 요청과 quantity sample query adapter
- mock 기반 혈압/체중/체성분 건강 데이터 dashboard 설계
- Health dashboard integration
- 혈압/체성분 건강 데이터 dashboard
- 수면 소리 지표와 건강 지표 교차 보기
- Extended Health Metrics
- `UnifiedHealthMetricID`
- `UnifiedHealthMetricSample`
- `HealthMetricSourceType`
- `MetricCatalog`
- Fitdays CSV/import flow
- Fitdays CSV/TSV/text import compatibility guard
- Fitdays 월별 데이터 복사 텍스트 붙여넣기 import preview
- Fitdays 월별 붙여넣기 compact date / Korean alias parser regression
- Fitdays import 미리보기 판단 섹션
- Fitdays 고유 지표 로컬 수동 입력
- Fitdays 저장된 가져오기 기록/삭제 UI
- Fitdays 저장 완료 후 최신 가져온 날짜 상세 바로가기
- Fitdays 저장된 batch별 최신 날짜 상세 바로가기
- Fitdays CSV/export 미확보 시 HealthKit read-only fallback UX
- `ImportBatch`
- synthetic Fitdays CSV fixture
- HealthKit 기반 지표와 Fitdays 로컬 전용 지표 출처 구분
- Fitdays CSV 로컬 import source badge/detail
- 전체 건강 지표 overview
- Health Dashboard 데이터 상태/로컬 import edge state
- MetricChartView
- 건강 지표 통계/그래프
- HealthMetricsOverviewView
- HealthMetricsOverviewView recovery metric grouping
- Cross Metric matched sample / low coverage edge state 설명
- 월 건강 캘린더
- HealthCalendarView
- DailyMeasurementDetailView
- 저녁 체크인 로컬 persistence와 건강 캘린더 연결
- 하단 건강 tab의 HealthDashboardView 직접 진입
- 건강 tab 첫 화면의 최근 날짜 상세 CTA
- 하단 tab 역할 정리: 홈=종합 평가, 수면=측정/결과, 건강=HealthKit+수면+Fitdays 데이터 허브, 설정=앱 설정
- 수면 tab의 최근 리포트/타임라인/수면 트렌드 직행
- MetricDetailView
- EHM 관련 unit test
- EHM 관련 문서
- Daily Rhythm 제품 방향 문서화
- Daily Rhythm 도메인 모델
- Mock Health Data Service
- DailyHealthSnapshotBuilder
- Daily Rhythm Score 계산기
- Daily Insight 생성기
- Daily Rhythm Report Builder
- Morning Brief 화면
- Daily Rhythm Report 화면
- Morning Brief / Daily Rhythm Report 데이터 준비 상태와 제한 항목 표시
- Evening Check-in 화면
- Daily Health Card 화면
- Daily Health Card template/privacy level 구조
- Daily Health Card renderer placeholder
- Daily Rhythm 관련 unit test
- UI gallery 문서 구조
- mock/simulator screenshot 폴더 구조
- DEBUG 전용 screenshot scenario preset
- screenshot capture workflow 문서와 simctl helper script
- README 대표 screenshot section 품질 격리 상태 문서화
- README 대표 mock/simulator screenshot 8개 후보 생성
- README 대표 cropped screenshot 8개 후보 생성
- UI Gallery screenshot/pending/quality review 연결
- UI Gallery direct simulator screenshot 6개 후보 생성
- 혈압/체성분/교차 보기와 health/metric/cross edge screenshot 6개 후보 생성
- App Store screenshot mock scenario/headline plan
- Daily Health Card 미리보기의 명시 액션 기반 로컬 PNG 생성/시스템 공유 sheet 연결
- Daily Health Card 민감 수치 export confirmation sheet
- Daily Health Card 공유 완료/취소 상태 UI
- Daily Health Card 사진 앱/파일 앱 저장 전용 흐름
- Daily Health Card privacy level별 export snapshot regression test
- Daily Health Card template/privacy matrix export safety regression test
- Daily Health Card README/App Store display profile 분리
- 실제 iPhone QA runbook과 기록 템플릿
- Health/QA/App Release 문서 통합 정리
- App Icon generate/validate/review sheet 로컬 도구
- App Store product page ko-KR/en-US 후보 copy 정리
- Release readiness 자동 gate 테스트
- Privacy/storage audit 자동 회귀 테스트
- UI Gallery screenshot captured/pending/quality review 상태와 App Store 후보 재캡처 gate 정리
- UI Gallery screenshot quarantine regression test
- Screenshot raw/crop contact sheet 생성 workflow
- Screenshot approval status manifest
- Screenshot manifest/schema/local file reference validation gate
- README screenshot 후보를 문서 preview와 App Store/release-approved gate로 분리
- user-facing screenshot launch scenario의 내부 QA source badge 노출 방지
- 수동 navigation이 필요했던 trend, morning/evening check-in, Daily Health Card export/share state, report empty, simulator scenario 화면에 DEBUG launch scenario와 captured screenshot 후보 추가

## 현재 개발 전략

반복 개발은 Simulator-first로 진행합니다.

- unit test로 비즈니스 로직 확인
- synthetic audio로 detector 기본 동작 확인
- Dataset Replay로 로컬 오디오 segment 재현
- Offline Evaluation으로 profile 결과 비교
- Simulator QA scenarios로 UI edge case 확인
- 실제 iPhone은 오디오 캡처/background/배터리/overnight 안정성 확인 시점에 사용

## 의도적으로 미구현 / 제한

- HealthKit 쓰기
- 앱 첫 실행 또는 수면 측정 시작 시 HealthKit 권한 요청
- HealthKit에 수면 소리 점수/이벤트/리포트/피드백 기록
- Apple 건강앱 수면 데이터 query
- Apple Watch 연동
- 서버 업로드
- 클라우드 동기화
- 외부 API 호출
- 외부 분석 SDK
- 광고 SDK
- 계정/로그인 시스템
- 전체 밤 원본 오디오 저장
- 이벤트와 무관한 연속 오디오 보관
- sleep talk 텍스트 변환
- App Store 제출
- 실제 기기 홈 화면/Settings/TestFlight 표면의 최종 앱 아이콘 확인
- App Store screenshot marketing final visual/export version
- README preview screenshot의 release-approved 승격 여부 검토와 App Store 후보 재캡처/visual QA 승인
- App Store Connect 화면에서 product page copy 글자 수/locale 최종 확인
- 외부 테스터/TestFlight 배포
- 실제 App Store screenshot export
- UI Gallery 수동 진입 상세 screenshot 전체 캡처
- 실제 개인 Fitdays CSV 장기 검증
- 실제 Fitdays CSV import manual QA
- 실제 Fitdays 앱 내 CSV/export 메뉴 확인
- Fitdays 고유 지표 로컬 수동 입력 실제 데이터 UX 확인
- 실제 `.mlmodel` 앱 bundle 적용. 적용 전 `Docs/CORE_ML_MODEL_INTEGRATION.md` gate 통과 필요
- detector 성능 확정 검증
- 실제 iPhone 장시간 overnight 안정성 검증
- 실제 HealthKit 데이터 기반 장기 검증
- 임상 지표 산출
- 건강 상태를 확정하는 기능

## 개인정보 상태

- 전체 밤 원본 오디오 파일은 저장하지 않습니다.
- 이벤트 오디오 샘플 저장은 기본값 OFF입니다.
- 사용자가 opt-in한 경우에만 이벤트 전후의 짧은 로컬 샘플을 저장합니다.
- 저장된 샘플은 개별/전체 삭제할 수 있습니다.
- orphan sample cleanup이 있습니다.
- 공개/개인 오디오 파일은 git에 포함하지 않습니다.
- HealthKit 권한 요청은 건강 데이터 연결 버튼을 선택한 경우에만 수행합니다.
- HealthKit은 read-only로만 사용합니다.
- Fitdays import는 사용자가 직접 확보하고 선택한 로컬 CSV/export file만 처리합니다.
- Fitdays 앱에서 CSV/export 파일을 확보하지 못하면 Apple 건강앱 read-only 표준 지표만 사용합니다.
- Fitdays 서버/API 연결과 비공식 연결 방식은 없습니다.
- 실제 개인 CSV 파일은 git에 포함하지 않습니다.
- 서버 전송, HealthKit 쓰기, 외부 SDK는 없습니다.

## P0 Stop / Detector Diagnostics 감사 기록

2026-05-05 기준 최근 P0 stop capture와 zero-event detector observability 수정 상태를 코드 기준으로 재확인했습니다.

- 수면 종료 tap은 `AppState.endSleepSession()`에서 `stopButtonTappedAt`과 `stopRequestedAt`을 먼저 기록한 뒤 `AudioCaptureService.stopCapture()`를 즉시 호출합니다.
- `AudioCaptureService.stopCapture()`는 input tap 제거, `AVAudioEngine.stop()`, audio session deactivate, chunk stream 종료, capture task cancel 기록을 analyzer finalize와 report generation보다 먼저 수행합니다.
- stop flow는 idempotent하며 double tap 중에는 기존 finalization을 유지하고 duplicate report 생성을 피합니다.
- stop 이후 chunk가 들어오면 `chunksReceivedAfterStopRequest`, `secondsReceivingAudioAfterStopRequest`, `lastChunkReceivedAt`, force stop reason으로 남깁니다.
- detector diagnostics는 raw/pre-smoothing/post-smoothing/final type count, reject reason, RMS/energy/band/zero-crossing/centroid summary, threshold snapshot, backend, tuning profile, model fallback 상태를 리포트에 보존합니다.
- 코골기 detector는 절대 RMS threshold 외에 저진폭 low-band/relative-energy guard를 사용해 침대 배치 거리로 작게 들어온 snore-like 후보를 raw candidate로 남길 수 있습니다. 앱 설정의 `코골기 감지 민감도`는 `많이 민감`, `민감`, `보통`, `둔감`, `많이 둔감` 5단계 preset이며 Release 기본 profile은 계속 `balanced`/`보통`입니다.
- 민감도 preset synthetic guard는 민감 계열의 distant snore-like recall과 전체 profile의 조용한 방/팬/공조음/이불 마찰/broadband noise negative 방어를 함께 확인합니다.
- Core ML adapter는 모델 미포함 상태에서 crash 없이 `modelInstalled == false`와 rule-based fallback을 유지합니다. 실제 모델 artifact는 아직 앱 target에 포함하지 않았고, target 적용 전 integration gate와 실제 iPhone smoke evidence가 필요합니다.
- 실제 iPhone 장시간 세션에서 audio coverage는 충분하지만 RMS/energy p90/p99가 저진폭 후보 기준보다 크게 낮은 경우를 `inputLevelAssessment == goodCoverageLowInputLevel`로 분리합니다. DEBUG/report/QA readout은 민감도 추가 조정보다 iPhone 거리, 마이크 방향, 케이스/침구 가림 확인을 먼저 안내합니다.
- raw 이벤트로 승격하지 않더라도 매우 낮은 RMS의 low-band/낮은 ZCR texture는 `snoreLikeFeatureCandidateCount`와 `inputLevelTooLow` near-miss reject reason으로 남겨 다음 배치 테스트의 근거를 보강합니다.
- 이벤트 오디오 샘플은 opt-in일 때만 짧게 저장되며, 전체 밤 원본 오디오 저장 경로는 추가하지 않았습니다.

## 실기기 확인이 남은 항목

- 화면 잠금 상태에서 장시간 오디오 수신 유지
- 앱 백그라운드 상태에서 장시간 오디오 수신 유지
- 실제 이벤트 오디오 샘플 재생 품질
- interruption 처리
- 배터리/발열
- overnight 안정성
- iPhone 배치별 입력 차이
