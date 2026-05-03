# Simulator End-to-End QA

이 문서는 NightBreath / 밤숨 앱을 실제 iPhone 마이크 없이 Simulator에서 확인하기 위한 개발용 QA 절차입니다.

Simulator QA는 mock 수면 세션, mock 수면 이벤트, mock NightReport, mock detector diagnostics, mock 이벤트 오디오 저장소 통계를 사용합니다. 실제 오디오 파일을 만들거나 전체 밤 원본 오디오를 저장하지 않습니다.

## 확인 가능한 항목

- 홈 화면의 최근 수면 리포트 요약
- 수면 소리 점수 표시
- 측정 품질 표시
- 앱 동작 시간과 실제 오디오 수신 시간 구분
- 주요 이벤트 수와 이벤트 타임라인 표시
- 이벤트 오디오 샘플 저장 ON/OFF 상태
- 저장된 이벤트 오디오 샘플 개수, 시간, 용량 표시
- 연결되지 않은 이벤트 오디오 샘플 상태와 정리 UI
- detector diagnostic summary
- 이벤트 0개 세션의 zero-event 분석 문구
- “진단 목적의 의료기기 아님”, “원본 전체 오디오 미저장”, “온디바이스 분석” 안내 문구
- 디자인 시스템 적용 후 edge case UI가 깨지지 않는지

## 확인 불가능한 항목

다음 항목은 Simulator QA로 대체할 수 없습니다.

- 실제 iPhone 마이크 입력 품질
- 화면 잠금 상태 녹음 유지 여부
- 백그라운드 녹음 유지 여부
- AVAudioSession interruption 처리
- 장시간 overnight 안정성
- 배터리 사용량과 발열
- iPhone 배치에 따른 감지 차이
- 실제 이벤트 오디오 샘플 녹음/재생 품질

위 항목은 `Docs/REAL_DEVICE_REQUIRED_TESTS.md`와 `Docs/BACKGROUND_RECORDING_QA.md` 절차로 별도 확인합니다.

## Scenario Preset

- `QuietNight`: 조용한 밤, 높은 점수, 빈 타임라인 확인
- `SnoreHeavyNight`: 코골기 시간이 긴 리포트와 주요 원인 설명 확인
- `NoiseHeavyNight`: 환경 소음과 각성 의심 구간이 많은 리포트 확인
- `CoughGaspNight`: 기침 의심 소리와 gasp-like 회복 호흡 표시 확인
- `BruxismLikeNight`: 이갈이 의심 소리 문구와 사용자 확인 UI 확인
- `ZeroEventButGoodAudioCoverage`: 오디오 입력은 충분하지만 최종 이벤트가 없는 상태 확인
- `ZeroEventBecauseNoAudioReceived`: 앱 동작 시간은 있으나 실제 오디오 수신이 거의 없는 상태 확인
- `LowAudioCoverageNight`: 낮은 오디오 커버리지와 측정 품질 안내 확인
- `EventAudioStorageOff`: 이벤트 오디오 저장 OFF 상태에서 리포트와 타임라인 확인
- `EventAudioStorageOnWithSamples`: 이벤트 오디오 저장 ON 상태의 저장 시간/용량 표시 확인
- `OrphanSamplesPresent`: 연결되지 않은 샘플 수, 용량, 정리 버튼 확인

## QA 순서

1. Xcode에서 Debug configuration으로 앱을 Simulator에 실행합니다.
2. 앱 하단 탭에서 `설정`을 엽니다.
3. DEBUG 섹션에서 `Simulator QA Scenario`를 엽니다.
4. preset을 선택하고 `시나리오 적용`을 누릅니다.
5. 같은 화면의 화면 확인 링크로 다음 화면을 확인합니다.
   - `HomeDashboardView`
   - `SleepReportView`
   - `SleepTimelineView`
   - `PrivacySettingsView`
6. 각 preset마다 다음 항목을 확인합니다.
   - 수면 소리 점수
   - 측정 품질
   - 실제 오디오 수신 시간
   - 이벤트 수
   - 이벤트 오디오 샘플 저장 상태
   - 저장 용량
   - 연결되지 않은 샘플 상태
   - detector diagnostic summary
   - zero-event 분석
   - 진단 목적 아님 문구
7. QA를 끝낸 뒤 `QA 시나리오 해제`를 눌러 저장된 실제/샘플 리포트 표시로 되돌립니다.

## 개인정보와 데이터 규칙

- Simulator QA preset은 mock 데이터만 생성합니다.
- 공개/개인 오디오 파일을 repo에 포함하지 않습니다.
- 서버 전송, 클라우드 동기화, 외부 API 호출을 하지 않습니다.
- HealthKit 권한 요청이나 데이터 읽기를 하지 않습니다.
- 전체 밤 원본 오디오 저장 기능을 추가하지 않습니다.
- 이벤트 오디오 샘플 ON preset도 실제 `.caf` 파일을 만들지 않고, UI 검증용 file name과 저장소 통계만 흉내냅니다.

## 실기기 테스트가 필요한 시점

Simulator QA에서 화면 상태와 리포트 구조가 정상임을 확인한 뒤, 실제 iPhone에서 다음을 확인합니다.

- foreground 1분 녹음
- 화면 잠금 3분 녹음
- 앱 백그라운드 3분 녹음
- 잠금 30분 녹음
- overnight 안정성
- 이벤트 오디오 opt-in 상태에서 짧은 이벤트 샘플 저장/재생/삭제

이 앱은 수면 중 소리 기반 웰니스 리포트 앱이며 진단 목적의 의료기기가 아닙니다.
