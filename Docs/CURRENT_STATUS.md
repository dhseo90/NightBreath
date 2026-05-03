# Current Status

이 문서는 NightBreath / 밤숨 V1 프로토타입의 현재 구현 상태와 의도적으로 남겨둔 범위를 정리합니다.

## 완료

- SwiftUI 앱 구조
- 실제 iPhone 오디오 캡처 구조
- 마이크 권한 요청 흐름
- AVAudioSession recording 설정
- AVAudioEngine input tap 기반 audio chunk 생성
- 앱 세션 시간과 실제 오디오 수신 시간 분리
- 실제 분석 시간 tracking
- 오디오 커버리지 계산
- 수면 세션 시작/종료 flow
- 수면 이벤트 모델
- 수면 리포트 모델
- 아침 컨디션 체크인 모델
- 로컬 저장소
- 수면 리포트 UI
- 홈 대시보드
- 이벤트 타임라인
- 최근 7일 추세 UI
- 수면 소리 점수
- 이벤트 집계
- rule-based detector placeholder
- detector protocol
- Core ML adapter placeholder
- detector diagnostics
- zero-event analysis
- 이벤트 오디오 샘플 저장/재생/삭제
- 이벤트 오디오 샘플 opt-in 설정
- 저장된 이벤트 오디오 용량 표시
- orphan sample cleanup
- 개인정보/저장소 관리 UI
- DEBUG 오디오 디버그 화면
- DEBUG 수동 짧은 샘플 수집 화면
- Dataset Replay
- Offline Evaluation
- profile comparison 도구
- Simulator QA scenarios
- Regression Test Suite
- NightBreath 디자인 시스템
- 향후 HealthKit 확장용 placeholder

## 현재 개발 전략

반복 개발은 Simulator-first로 진행합니다.

- unit test로 비즈니스 로직 확인
- synthetic audio로 detector 기본 동작 확인
- Dataset Replay로 로컬 오디오 segment 재현
- Offline Evaluation으로 profile 결과 비교
- Simulator QA scenarios로 UI edge case 확인
- 실제 iPhone은 오디오 캡처/background/배터리/overnight 안정성 확인 시점에 사용

## 의도적으로 미구현

- HealthKit 실제 연동
- HealthKit 권한 요청
- Apple 건강앱 데이터 읽기/쓰기
- Apple Watch 연동
- 혈압/체중/체성분 그래프
- 서버 업로드
- 클라우드 동기화
- 외부 API 호출
- 외부 분석 SDK
- 광고 SDK
- 계정/로그인 시스템
- 전체 밤 원본 오디오 저장
- 이벤트와 무관한 연속 오디오 보관
- sleep talk 텍스트 변환
- 실제 `.mlmodel` 앱 bundle 적용
- detector 성능 확정 검증
- 임상 지표 산출
- 질환명 확정 또는 의료적 판정

## 개인정보 상태

- 전체 밤 원본 오디오 파일은 저장하지 않습니다.
- 이벤트 오디오 샘플 저장은 기본값 OFF입니다.
- 사용자가 opt-in한 경우에만 이벤트 전후의 짧은 로컬 샘플을 저장합니다.
- 저장된 샘플은 개별/전체 삭제할 수 있습니다.
- orphan sample cleanup이 있습니다.
- 공개/개인 오디오 파일은 git에 포함하지 않습니다.
- 서버 전송, HealthKit 실제 연동, 외부 SDK는 없습니다.

## 실기기 확인이 남은 항목

- 화면 잠금 상태에서 장시간 오디오 수신 유지
- 앱 백그라운드 상태에서 장시간 오디오 수신 유지
- 실제 이벤트 오디오 샘플 재생 품질
- interruption 처리
- 배터리/발열
- overnight 안정성
- iPhone 배치별 입력 차이
