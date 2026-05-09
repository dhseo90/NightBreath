# Release README

이 문서는 NightBreath / 밤숨의 App Store 준비와 release gate를 설명합니다.

## Release 기준

출시 준비에서는 기능 동작뿐 아니라 개인정보, 문구, screenshot, App Review surface를 함께 확인합니다.

필수 확인:

- 서버 업로드, 클라우드 처리, 외부 API 호출 없음
- 외부 분석 SDK, 광고 SDK, 계정 시스템 없음
- HealthKit read-only 유지
- HealthKit write usage 없음
- 전체 밤 원본 오디오 기본 미저장
- 이벤트 오디오 샘플 opt-in, 제한, 삭제 기능 유지
- 진단적 판단처럼 읽히는 문구 없음
- 실제 개인 건강 데이터, 실제 CSV 파일명, 실제 오디오 파일명이 screenshot에 없음
- main/sub README 링크 검증 통과

## Screenshot approval

README 대표 screenshot과 App Store screenshot은 별도로 관리합니다.

- README 이미지는 제품 구조를 설명하는 문서용 preview입니다.
- App Store 이미지는 raw capture, review crop, App Store Connect export를 별도 flow로 검토합니다.
- DEBUG-only 화면은 App Store/README 대표 이미지에 포함하지 않습니다.
- screenshot status는 `Docs/Screenshots/screenshot_status.tsv`에서 추적합니다.
- App Store export manifest와 size별 visual evidence는 `Tools/Screenshots/validate_app_store_export_manifest.sh`로 검증합니다.
- App Store 8개 후보를 `release-approved`로 승격하기 전에는 `Tools/Screenshots/validate_app_store_release_approval.sh`를 실행합니다.
- 제출 직전 hard gate는 `REQUIRE_APP_STORE_RELEASE_APPROVED=1 Tools/Screenshots/validate_app_store_release_approval.sh`로 실행합니다.
- 현재 release evidence 요약은 `Docs/Release/RELEASE_READINESS_EVIDENCE.md`에서 한 장으로 확인합니다.

## 문서 링크 gate

루트 README와 주요 sub README의 문서/이미지 링크는 release gate 전에 자동 검증합니다.

```bash
Tools/Docs/validate_readme_links.sh
```

이 gate는 루트 README가 `Product`, `UI`, `Architecture`, `Privacy`, `Health`, `QA`, `Release` sub README를 모두 링크하는지와 각 README 내부의 상대 링크/이미지 경로가 실제 파일로 이어지는지를 확인합니다.

## App Store 문구

App Store 문구는 웰니스/개인 참고용 표현을 사용합니다. 질병 진단, 임상 정확도, 치료 판단으로 읽히는 표현은 사용하지 않습니다.

## 관련 문서

| 문서 | 내용 |
| --- | --- |
| [APP_RELEASE_GUIDE](../APP_RELEASE_GUIDE.md) | release checklist와 gate |
| [APP_REVIEW_AUDIT](../APP_REVIEW_AUDIT.md) | App Review 관점 audit |
| [APP_STORE_CONNECT_PREVIEW_QA](../APP_STORE_CONNECT_PREVIEW_QA.md) | App Store Connect upload preview 수동 QA runbook |
| [APP_STORE_CONNECT_LOCAL_PREVIEW_EVIDENCE](../APP_STORE_CONNECT_LOCAL_PREVIEW_EVIDENCE.md) | App Store Connect 실제 화면 전 로컬 대체 QA evidence |
| [APP_STORE_PRODUCT_PAGE_COPY](../APP_STORE_PRODUCT_PAGE_COPY.md) | ko-KR/en-US product page copy 후보 |
| [RELEASE_READINESS_EVIDENCE](RELEASE_READINESS_EVIDENCE.md) | screenshot/copy/gate evidence summary |
| [REVIEW_UPLOAD_SET](../REVIEW_UPLOAD_SET.md) | review/upload 후보 묶음 |
| [TESTFLIGHT_INTERNAL_TEST_PLAN](../TESTFLIGHT_INTERNAL_TEST_PLAN.md) | TestFlight 내부 테스트 계획 |
| [TESTFLIGHT_INTERNAL_EVIDENCE_TEMPLATE](../TESTFLIGHT_INTERNAL_EVIDENCE_TEMPLATE.md) | TestFlight private evidence 작성 템플릿 |
| [TESTFLIGHT_LOCAL_PREFLIGHT_EVIDENCE](../TESTFLIGHT_LOCAL_PREFLIGHT_EVIDENCE.md) | 실기기 없이 가능한 TestFlight local preflight evidence |
| [REAL_DEVICE_SIMULATOR_SUBSTITUTE_EVIDENCE](../REAL_DEVICE_SIMULATOR_SUBSTITUTE_EVIDENCE.md) | 실제 iPhone 전 대체 가능한 simulator/local QA evidence |
