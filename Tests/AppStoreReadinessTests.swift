import Foundation
import Testing

@Suite("App Store Readiness")
struct AppStoreReadinessTests {
    @Test
    func infoPlistUsesKoreanAppNameAndPermissionCopy() throws {
        let plist = try infoPlist()

        #expect(plist["CFBundleDisplayName"] as? String == "밤숨")

        let microphoneCopy = try #require(plist["NSMicrophoneUsageDescription"] as? String)
        #expect(microphoneCopy.contains("수면 중 소리 기반 지표"))
        #expect(microphoneCopy.contains("iPhone 안에서"))
        #expect(microphoneCopy.contains("원본 전체 오디오는 저장하지 않습니다"))

        let healthCopy = try #require(plist["NSHealthShareUsageDescription"] as? String)
        #expect(healthCopy.contains("건강 데이터 연결을 선택한 경우에만"))
        #expect(healthCopy.contains("혈압"))
        #expect(healthCopy.contains("체중"))
        #expect(healthCopy.contains("활동"))
        #expect(healthCopy.contains("로컬 대시보드"))
        #expect(healthCopy.contains("HealthKit에 데이터를 쓰지 않고"))
        #expect(healthCopy.contains("서버로 전송하지 않습니다"))
        #expect(plist["NSHealthUpdateUsageDescription"] == nil)

        let photoAddCopy = try #require(plist["NSPhotoLibraryAddUsageDescription"] as? String)
        #expect(photoAddCopy.contains("하루 리듬 카드"))
        #expect(photoAddCopy.contains("선택한 경우에만"))
        #expect(photoAddCopy.contains("서버로 업로드하지 않습니다"))
    }

    @Test
    func infoPlistDeclaresSafeFitdaysOpenInDocumentTypes() throws {
        let plist = try infoPlist()
        let documentTypes = try #require(plist["CFBundleDocumentTypes"] as? [NSDictionary])
        let fitdaysDocumentType = try #require(
            documentTypes.first { ($0["CFBundleTypeName"] as? String) == "Fitdays CSV Export" }
        )
        let itemContentTypes = try #require(fitdaysDocumentType["LSItemContentTypes"] as? [String])

        #expect(fitdaysDocumentType["CFBundleTypeRole"] as? String == "Viewer")
        #expect(fitdaysDocumentType["LSHandlerRank"] as? String == "Alternate")
        #expect(itemContentTypes.contains("public.comma-separated-values-text"))
        #expect(itemContentTypes.contains("public.tab-separated-values-text"))
        #expect(itemContentTypes.contains("public.plain-text"))
        #expect(!itemContentTypes.contains("public.data"))
        #expect(plist["LSSupportsOpeningDocumentsInPlace"] as? Bool == false)
    }

    @Test
    func appRoutesOpenInURLsToFitdaysImportPreview() throws {
        let repositoryRoot = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        let appEntry = try String(
            contentsOf: repositoryRoot.appendingPathComponent("SleepSoundApp/App/SleepSoundApp.swift"),
            encoding: .utf8
        )
        let appState = try String(
            contentsOf: repositoryRoot.appendingPathComponent("SleepSoundApp/App/AppState.swift"),
            encoding: .utf8
        )
        let importView = try String(
            contentsOf: repositoryRoot.appendingPathComponent("SleepSoundApp/Features/Dashboard/FitdaysImportView.swift"),
            encoding: .utf8
        )

        #expect(appEntry.contains(".onOpenURL"))
        #expect(appEntry.contains("appState.handleOpenURL"))
        #expect(appEntry.contains("FitdaysImportView("))
        #expect(appEntry.contains("initialFileURL"))
        #expect(appState.contains("pendingFitdaysImportFile"))
        #expect(appState.contains("FitdaysImportFilePolicy.isSupportedFileName"))
        #expect(importView.contains("previewInitialFileIfNeeded"))
        #expect(importView.contains("service.previewImport(from: fileURL)"))
        #expect(importView.contains("FitdaysImportFallbackGuidance.privacyMessages"))
        #expect(importView.contains("FitdaysImportFallbackGuidance.emptyStateMessage"))
        #expect(importView.contains("exportUnavailableSection"))
        #expect(importView.contains("파일이 없어도 괜찮습니다"))
        #expect(importView.contains("FitdaysImportFallbackGuidance.healthDashboardFallbackTitle"))
        #expect(importView.contains("건강 데이터 대시보드 보기"))
        #expect(importView.contains("FitdaysImportFallbackGuidance.localOnlyFollowUpTitle"))
        #expect(importView.contains("Fitdays 로그인, 서버/API 연결, 자동 동기화, 비공식 연결 방식을 사용하지 않습니다."))
    }

    @Test
    func fitdaysExportRecheckRunbookKeepsRealDeviceEvidencePrivateAndLocalOnly() throws {
        let repositoryRoot = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        let qaGuide = try String(
            contentsOf: repositoryRoot.appendingPathComponent("Docs/QA_GUIDE.md"),
            encoding: .utf8
        )
        let healthGuide = try String(
            contentsOf: repositoryRoot.appendingPathComponent("Docs/HEALTH_DATA_GUIDE.md"),
            encoding: .utf8
        )
        let checklist = try String(
            contentsOf: repositoryRoot.appendingPathComponent("QA_CHECKLIST.md"),
            encoding: .utf8
        )
        let combined = [qaGuide, healthGuide, checklist].joined(separator: "\n")

        #expect(qaGuide.contains("실기기 export availability 재확인 smoke"))
        #expect(qaGuide.contains("Export menu visible: yes / no"))
        #expect(qaGuide.contains("Fitdays app version recorded in repo: no"))
        #expect(qaGuide.contains("Fitdays account/login details recorded in repo: no"))
        #expect(healthGuide.contains("Personal Data Request"))
        #expect(healthGuide.contains("private QA note"))
        #expect(checklist.contains("UI scraping"))
        #expect(combined.contains("Apple 건강앱 read-only"))
        #expect(combined.contains("repository 밖"))

        let forbiddenFallbacks = [
            "Fitdays 서버/API에 직접 연결합니다",
            "비공식 연결 방식을 구현합니다",
            "자동 동기화를 구현합니다",
            "HealthKit에 Fitdays import 값을 씁니다",
        ]

        for fallback in forbiddenFallbacks {
            #expect(!combined.contains(fallback), "Fitdays runbook should not introduce forbidden fallback: \(fallback)")
        }
    }

    @Test
    func appIconCatalogContainsGeneratedArtworkAndTargetUsesIt() throws {
        let repositoryRoot = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        let appIconRoot = repositoryRoot.appendingPathComponent("SleepSoundApp/App/Assets.xcassets/AppIcon.appiconset")
        let contentsURL = appIconRoot.appendingPathComponent("Contents.json")
        let data = try Data(contentsOf: contentsURL)
        let object = try JSONSerialization.jsonObject(with: data)
        let contents = try #require(object as? NSDictionary)
        let images = try #require(contents["images"] as? [NSDictionary])
        let filenames = Set(images.compactMap { $0["filename"] as? String })
        let project = try String(
            contentsOf: repositoryRoot.appendingPathComponent("SleepSoundApp.xcodeproj/project.pbxproj"),
            encoding: .utf8
        )

        #expect(images.count >= 18)
        #expect(filenames.contains("AppIcon-1024.png"))
        #expect(filenames.contains("AppIcon-60@3x.png"))
        #expect(filenames.contains("AppIcon-60@2x.png"))
        #expect(project.contains("ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;"))
        #expect(try Data(contentsOf: appIconRoot.appendingPathComponent("AppIcon-1024.png")).count > 100_000)
        #expect(try Data(contentsOf: appIconRoot.appendingPathComponent("AppIcon-60@3x.png")).count > 10_000)

        for filename in filenames {
            let url = appIconRoot.appendingPathComponent(filename)
            #expect(FileManager.default.fileExists(atPath: url.path), "\(filename) should exist in AppIcon.appiconset.")
        }
    }

    @Test
    func appStoreDocumentsExistAndUseSafeCopy() throws {
        let repositoryRoot = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        let documentPaths = [
            "Docs/APP_RELEASE_GUIDE.md",
        ]
        let forbiddenPhrases = [
            "수면무호흡증 " + "진단",
            "AHI " + "정확 측정",
            "이갈이 " + "확진",
            "질병 " + "판정",
            "치료 " + "필요",
        ]

        for path in documentPaths {
            let url = repositoryRoot.appendingPathComponent(path)
            #expect(FileManager.default.fileExists(atPath: url.path), "\(path) should exist.")

            let contents = try String(contentsOf: url, encoding: .utf8)
            #expect(contents.contains("밤숨"))
            #expect(contents.contains("HealthKit"))
            #expect(contents.contains("서버"))
            #expect(contents.contains("원본 전체 오디오"))

            for phrase in forbiddenPhrases {
                #expect(!contents.contains(phrase), "\(path) contains restricted wording: \(phrase)")
            }
        }
    }

    @Test
    func appStoreProductPageCopyIsLocalizedSafeAndWithinDraftLimits() throws {
        let repositoryRoot = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        let productCopy = try String(
            contentsOf: repositoryRoot.appendingPathComponent("Docs/APP_STORE_PRODUCT_PAGE_COPY.md"),
            encoding: .utf8
        )
        let releaseGuide = try String(
            contentsOf: repositoryRoot.appendingPathComponent("Docs/APP_RELEASE_GUIDE.md"),
            encoding: .utf8
        )
        let reviewAudit = try String(
            contentsOf: repositoryRoot.appendingPathComponent("Docs/APP_REVIEW_AUDIT.md"),
            encoding: .utf8
        )
        let nextIssues = try String(
            contentsOf: repositoryRoot.appendingPathComponent("Docs/NEXT_ISSUES.md"),
            encoding: .utf8
        )

        let koreanSubtitle = "수면 소리와 하루 리듬"
        let koreanPromotionalText = "밤새 수면 중 소리 기반 지표와 아침 컨디션, 하루 리듬을 iPhone 안에서 개인 참고용으로 정리합니다."
        let koreanKeywords = "수면,코골기,수면기록,건강리듬,HealthKit,컨디션,리포트"
        let englishSubtitle = "Sleep Sound Report"
        let englishKeywords = "sleep,snore,wellness,rhythm,HealthKit,checkin,report"

        #expect(productCopy.contains("Primary Locale: ko-KR"))
        #expect(productCopy.contains("Secondary Locale: en-US"))
        #expect(productCopy.contains("| App Name | 밤숨 |"))
        #expect(productCopy.contains("| App Name | NightBreath |"))
        #expect(productCopy.contains(koreanSubtitle))
        #expect(productCopy.contains(koreanPromotionalText))
        #expect(productCopy.contains(koreanKeywords))
        #expect(productCopy.contains(englishSubtitle))
        #expect(productCopy.contains(englishKeywords))
        #expect(koreanSubtitle.count <= 30)
        #expect(koreanPromotionalText.count <= 170)
        #expect(koreanKeywords.count <= 100)
        #expect(englishSubtitle.count <= 30)
        #expect(englishKeywords.count <= 100)
        #expect(productCopy.contains("서버 업로드나 클라우드 처리를 사용하지 않습니다"))
        #expect(productCopy.contains("HealthKit은 사용자가 건강 데이터 연결을 선택한 경우에만 read-only"))
        #expect(productCopy.contains("HealthKit에 데이터를 쓰지 않습니다"))
        #expect(productCopy.contains("전체 밤 원본 오디오는 기본 저장하지 않습니다"))
        #expect(productCopy.contains("mock/synthetic data"))
        #expect(releaseGuide.contains("Docs/APP_STORE_PRODUCT_PAGE_COPY.md"))
        #expect(reviewAudit.contains("Docs/APP_STORE_PRODUCT_PAGE_COPY.md"))
        #expect(nextIssues.contains("product page copy 후보 정리 완료"))

        let forbiddenPhrases = [
            "수면무호흡증 " + "진단",
            "AHI " + "정확 측정",
            "이갈이 " + "확진",
            "질병 " + "판정",
            "치료 " + "필요",
            "정상" + "입니다",
            "코골이가 " + "없었습니다",
            "서버 업로드를 사용합니다",
            "HealthKit에 데이터를 씁니다",
            "전체 밤 원본 오디오를 저장합니다",
        ]

        for phrase in forbiddenPhrases {
            #expect(!productCopy.contains(phrase), "Product page copy contains restricted wording: \(phrase)")
        }
    }

    @Test
    func appStoreScreenshotPlanDocumentsMockScenariosAndSafeHeadlines() throws {
        let repositoryRoot = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        let guide = try String(
            contentsOf: repositoryRoot.appendingPathComponent("Docs/APP_RELEASE_GUIDE.md"),
            encoding: .utf8
        )
        let scenarioSource = try String(
            contentsOf: repositoryRoot.appendingPathComponent("SleepSoundApp/Features/ScreenshotScenarios.swift"),
            encoding: .utf8
        )
        let expectedRows = [
            (
                "ScreenshotHomeScenario",
                "수면 중 소리 기반 지표를 한눈에",
                "Docs/Screenshots/AppStore/raw/01_home_dashboard_light.png"
            ),
            (
                "ScreenshotSleepReportScenario",
                "아침에 읽기 쉬운 수면 소리 리포트",
                "Docs/Screenshots/AppStore/raw/02_sleep_report_light.png"
            ),
            (
                "ScreenshotTimelineScenario",
                "코골기와 환경 소음 흐름 확인",
                "Docs/Screenshots/AppStore/raw/03_sleep_timeline_light.png"
            ),
            (
                "ScreenshotDailyRhythmScenario",
                "오늘의 리듬 점수를 참고용으로",
                "Docs/Screenshots/AppStore/raw/04_daily_rhythm_report_light.png"
            ),
            (
                "ScreenshotDailyHealthCardScenario",
                "하루 리듬을 카드 한 장으로",
                "Docs/Screenshots/AppStore/raw/05_daily_health_card_light.png"
            ),
            (
                "ScreenshotHealthMetricsOverviewScenario",
                "모든 건강 지표를 출처와 함께",
                "Docs/Screenshots/AppStore/raw/06_health_metrics_overview_light.png"
            ),
            (
                "ScreenshotPrivacyScenario",
                "전체 밤 오디오는 저장하지 않습니다",
                "Docs/Screenshots/AppStore/raw/07_privacy_settings_light.png"
            ),
            (
                "ScreenshotZeroEventScenario",
                "이벤트가 적은 밤도 측정 맥락과 함께",
                "Docs/Screenshots/AppStore/raw/08_zero_event_report_light.png"
            ),
        ]

        #expect(guide.contains("mock data와 simulator scenario"))
        #expect(guide.contains("실제 개인 건강 데이터"))
        #expect(guide.contains("실제 HealthKit 데이터"))
        #expect(guide.contains("실제 Fitdays CSV 파일명"))
        #expect(guide.contains("실제 오디오 파일명"))
        #expect(guide.contains("서버 미전송"))
        #expect(guide.contains("opt-in 샘플 정책"))
        #expect(guide.contains("readmeRepresentative"))
        #expect(guide.contains("appStoreMarketing"))
        #expect(guide.contains("민감 수치를 노출하지 않습니다"))
        #expect(guide.contains("blocked, recapture required"))
        #expect(guide.contains("release-approved 상태가 아닙니다"))
        #expect(guide.contains("내부 `Simulator QA` label"))

        for (scenario, headline, screenshotPath) in expectedRows {
            #expect(guide.contains(scenario), "\(scenario) should be documented in the App Store screenshot plan.")
            #expect(guide.contains(headline), "\(headline) should be documented in the App Store screenshot plan.")
            #expect(guide.contains(screenshotPath), "\(screenshotPath) should be documented in the App Store screenshot plan.")
            #expect(scenarioSource.contains(scenario), "\(scenario) should exist in ScreenshotScenario.")
            #expect(scenarioSource.contains(headline), "\(headline) should stay aligned with ScreenshotScenario headline copy.")
        }

        let forbiddenMarketingClaims = [
            "정상입니다",
            "코골이가 없었습니다",
            "수면무호흡증 " + "없음",
            "질병 " + "아님",
            "치료 " + "필요",
            "건강 상태를 예측",
        ]

        for claim in forbiddenMarketingClaims {
            #expect(!guide.contains(claim), "App Store screenshot plan contains unsafe marketing copy: \(claim)")
        }
    }

    @Test
    func appStoreMarketingScreenshotCaptureWorkflowIsDocumentedAndMockOnly() throws {
        let repositoryRoot = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        let captureScript = try String(
            contentsOf: repositoryRoot.appendingPathComponent("Tools/Screenshots/capture_app_store_screenshots.sh"),
            encoding: .utf8
        )
        let reviewSheetScript = try String(
            contentsOf: repositoryRoot.appendingPathComponent("Tools/Screenshots/build_screenshot_review_sheet.sh"),
            encoding: .utf8
        )
        let screenshotGuide = try String(
            contentsOf: repositoryRoot.appendingPathComponent("Docs/Screenshots/README.md"),
            encoding: .utf8
        )
        let toolGuide = try String(
            contentsOf: repositoryRoot.appendingPathComponent("Tools/Screenshots/README.md"),
            encoding: .utf8
        )
        let releaseGuide = try String(
            contentsOf: repositoryRoot.appendingPathComponent("Docs/APP_RELEASE_GUIDE.md"),
            encoding: .utf8
        )
        let expectedRawFiles = [
            "01_home_dashboard_light.png",
            "02_sleep_report_light.png",
            "03_sleep_timeline_light.png",
            "04_daily_rhythm_report_light.png",
            "05_daily_health_card_light.png",
            "06_health_metrics_overview_light.png",
            "07_privacy_settings_light.png",
            "08_zero_event_report_light.png",
        ]

        #expect(captureScript.contains("--nightbreath-screenshot-scenario"))
        #expect(captureScript.contains("Docs/Screenshots/AppStore/raw"))
        #expect(captureScript.contains("Docs/Screenshots/AppStore/review-cropped"))
        #expect(captureScript.contains("APP_STORE_SCREENSHOT_SCENARIOS"))
        #expect(reviewSheetScript.contains("screenshot_review_sheet.html"))
        #expect(reviewSheetScript.contains("screenshot_review_manifest.tsv"))
        #expect(reviewSheetScript.contains("internal label"))
        #expect(reviewSheetScript.contains("Docs/Screenshots/AppStore/raw/01_home_dashboard_light.png"))
        #expect(reviewSheetScript.contains("Docs/Screenshots/README/cropped/home_dashboard_light.png"))
        #expect(screenshotGuide.contains("App Store Marketing Screenshot"))
        #expect(screenshotGuide.contains("Tools/Screenshots/build_screenshot_review_sheet.sh"))
        #expect(screenshotGuide.contains("screenshot_review_sheet.html"))
        #expect(toolGuide.contains("App Store Marketing Screenshot"))
        #expect(toolGuide.contains("Review Sheet"))
        #expect(toolGuide.contains("build_screenshot_review_sheet.sh"))
        #expect(releaseGuide.contains("App Store marketing capture source"))
        #expect(releaseGuide.contains("review sheet script"))
        #expect(releaseGuide.contains("screenshot_review_sheet.html"))
        #expect(releaseGuide.contains("DEBUG simulator scenario"))
        #expect(releaseGuide.contains("synthetic/mock data"))
        #expect(screenshotGuide.contains("재캡처 전까지 사용 금지"))
        #expect(toolGuide.contains("재캡처가 필요합니다"))
        #expect(releaseGuide.contains("재캡처 전까지 App Store Connect export 입력으로 사용하지 않습니다"))

        for filename in expectedRawFiles {
            #expect(captureScript.contains(filename), "\(filename) should be part of the App Store capture script.")
            #expect(screenshotGuide.contains("AppStore/raw/\(filename)"), "\(filename) should be documented.")
        }
    }

    @Test
    func appStoreConnectScreenshotExportWorkflowUsesRawSourceAndIgnoredDerivedOutput() throws {
        let repositoryRoot = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        let exportScriptPath = repositoryRoot.appendingPathComponent("Tools/Screenshots/export_app_store_connect_screenshots.sh")
        let exportScript = try String(contentsOf: exportScriptPath, encoding: .utf8)
        let screenshotGuide = try String(
            contentsOf: repositoryRoot.appendingPathComponent("Docs/Screenshots/README.md"),
            encoding: .utf8
        )
        let toolGuide = try String(
            contentsOf: repositoryRoot.appendingPathComponent("Tools/Screenshots/README.md"),
            encoding: .utf8
        )
        let releaseGuide = try String(
            contentsOf: repositoryRoot.appendingPathComponent("Docs/APP_RELEASE_GUIDE.md"),
            encoding: .utf8
        )
        let gitignore = try String(
            contentsOf: repositoryRoot.appendingPathComponent(".gitignore"),
            encoding: .utf8
        )
        let expectedSizeLabels = [
            "iphone_6_9_1290x2796",
            "iphone_6_5_1284x2778",
            "iphone_6_3_1206x2622",
            "iphone_6_1_1170x2532",
            "iphone_5_5_1242x2208",
        ]

        #expect(FileManager.default.fileExists(atPath: exportScriptPath.path))
        #expect(exportScript.contains("Docs/Screenshots/AppStore/raw"))
        #expect(exportScript.contains("Docs/Screenshots/AppStore/export"))
        #expect(exportScript.contains("manifest.tsv"))
        #expect(exportScript.contains("APP_STORE_EXPORT_SIZES"))
        #expect(exportScript.contains("APP_STORE_EXPORT_FILES"))
        #expect(exportScript.contains("APP_STORE_EXPORT_FIT_MODE"))
        #expect(exportScript.contains("force_original_aspect_ratio=decrease"))
        #expect(exportScript.contains("force_original_aspect_ratio=increase"))
        #expect(gitignore.contains("Docs/Screenshots/AppStore/export/"))
        #expect(gitignore.contains("Docs/Screenshots/review/"))
        #expect(screenshotGuide.contains("App Store Connect size별 export"))
        #expect(toolGuide.contains("App Store Connect size export"))
        #expect(toolGuide.contains("https://developer.apple.com/help/app-store-connect/reference/screenshot-specifications/"))
        #expect(releaseGuide.contains("App Store Connect size export script"))
        #expect(releaseGuide.contains("manifest.tsv"))
        #expect(releaseGuide.contains("커밋하지 않습니다"))

        for label in expectedSizeLabels {
            #expect(exportScript.contains(label), "\(label) should be supported by the export script.")
            #expect(toolGuide.contains(label), "\(label) should be documented.")
        }
    }

    @Test
    func testFlightInternalPlanDocumentsBlockingGatesAndPrivateEvidence() throws {
        let repositoryRoot = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        let testFlightPlan = try String(
            contentsOf: repositoryRoot.appendingPathComponent("Docs/TESTFLIGHT_INTERNAL_TEST_PLAN.md"),
            encoding: .utf8
        )
        let releaseGuide = try String(
            contentsOf: repositoryRoot.appendingPathComponent("Docs/APP_RELEASE_GUIDE.md"),
            encoding: .utf8
        )
        let qaChecklist = try String(
            contentsOf: repositoryRoot.appendingPathComponent("QA_CHECKLIST.md"),
            encoding: .utf8
        )
        let nextIssues = try String(
            contentsOf: repositoryRoot.appendingPathComponent("Docs/NEXT_ISSUES.md"),
            encoding: .utf8
        )
        let combined = [testFlightPlan, releaseGuide, qaChecklist, nextIssues].joined(separator: "\n")

        #expect(testFlightPlan.contains("Blocking gate"))
        #expect(testFlightPlan.contains("Evidence Template"))
        #expect(testFlightPlan.contains("foreground stop smoke"))
        #expect(testFlightPlan.contains("double stop tap"))
        #expect(testFlightPlan.contains("zero-event diagnostics present"))
        #expect(testFlightPlan.contains("HealthKit read-only permission flow"))
        #expect(testFlightPlan.contains("Fitdays local import fallback"))
        #expect(testFlightPlan.contains("Daily Health Card export/share explicit action"))
        #expect(testFlightPlan.contains("sensitive data included in repo: No"))
        #expect(testFlightPlan.contains("real personal audio committed: No"))
        #expect(testFlightPlan.contains("real personal CSV committed: No"))
        #expect(testFlightPlan.contains("server/network code added: No"))
        #expect(testFlightPlan.contains("HealthKit write observed: No"))
        #expect(testFlightPlan.contains("diagnosis wording observed: No"))
        #expect(releaseGuide.contains("Docs/TESTFLIGHT_INTERNAL_TEST_PLAN.md"))
        #expect(qaChecklist.contains("Docs/TESTFLIGHT_INTERNAL_TEST_PLAN.md"))
        #expect(nextIssues.contains("TestFlight 내부 테스트 체크리스트 정리 완료"))

        let forbiddenPhrases = [
            "수면무호흡증 " + "진단",
            "질병 " + "판정",
            "치료 " + "필요",
            "서버 업로드를 사용합니다",
            "HealthKit에 데이터를 씁니다",
            "전체 밤 원본 오디오를 저장합니다",
        ]

        for phrase in forbiddenPhrases {
            #expect(!combined.contains(phrase), "TestFlight plan should not introduce restricted wording: \(phrase)")
        }
    }

    @Test
    func realDeviceSmokeRunbookDocumentsSafeResultTemplate() throws {
        let repositoryRoot = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        let runbook = try String(
            contentsOf: repositoryRoot.appendingPathComponent("Docs/REAL_DEVICE_QA_RUNBOOK.md"),
            encoding: .utf8
        )
        let qaGuide = try String(
            contentsOf: repositoryRoot.appendingPathComponent("Docs/QA_GUIDE.md"),
            encoding: .utf8
        )
        let testFlightPlan = try String(
            contentsOf: repositoryRoot.appendingPathComponent("Docs/TESTFLIGHT_INTERNAL_TEST_PLAN.md"),
            encoding: .utf8
        )
        let nextIssues = try String(
            contentsOf: repositoryRoot.appendingPathComponent("Docs/NEXT_ISSUES.md"),
            encoding: .utf8
        )

        #expect(runbook.contains("Codex가 이 테스트를 자동 실행하지 않습니다"))
        #expect(runbook.contains("Preflight Without Device"))
        #expect(runbook.contains("Evidence Redaction Checklist"))
        #expect(runbook.contains("Failure Triage Matrix"))
        #expect(runbook.contains("Result Template"))
        #expect(runbook.contains("Foreground stop smoke"))
        #expect(runbook.contains("Lock/background short stop"))
        #expect(runbook.contains("Snore signal smoke"))
        #expect(runbook.contains("Zero-event explanation"))
        #expect(runbook.contains("QA readout 공유"))
        #expect(runbook.contains("Detector QA readout captured"))
        #expect(runbook.contains("Event audio snippet safeguard"))
        #expect(runbook.contains("stopButtonTappedAt"))
        #expect(runbook.contains("chunksReceivedAfterStopRequest"))
        #expect(runbook.contains("secondsReceivingAudioAfterStopRequest"))
        #expect(runbook.contains("rawCandidateCountByType"))
        #expect(runbook.contains("postSmoothingEventCountByType"))
        #expect(runbook.contains("finalEventCountByType"))
        #expect(runbook.contains("full-night raw audio observed: No"))
        #expect(runbook.contains("real personal audio committed: No"))
        #expect(runbook.contains("real personal CSV committed: No"))
        #expect(runbook.contains("server/network transfer observed: No"))
        #expect(runbook.contains("HealthKit write observed: No"))
        #expect(runbook.contains("diagnosis wording observed: No"))
        #expect(runbook.contains("Stop 이후 received audio 증가"))
        #expect(runbook.contains("detector QA readout"))
        #expect(qaGuide.contains("Docs/REAL_DEVICE_QA_RUNBOOK.md"))
        #expect(qaGuide.contains("Preflight Without Device"))
        #expect(qaGuide.contains("Evidence Redaction Checklist"))
        #expect(testFlightPlan.contains("Docs/REAL_DEVICE_QA_RUNBOOK.md"))
        #expect(nextIssues.contains("실제 iPhone smoke result template"))

        let forbiddenPhrases = [
            "sleep talk 내용을 기록합니다",
            "실제 개인 오디오 파일을 repository에 기록",
            "HealthKit write를 허용",
            "서버로 전송합니다",
            "정상입니다",
            "코골이가 없었습니다",
            "수면무호흡증 " + "없음",
        ]

        for phrase in forbiddenPhrases {
            #expect(!runbook.contains(phrase), "Real-device runbook should not introduce restricted wording: \(phrase)")
        }
    }

    @Test
    func appReviewAuditDocumentsPrivacyHealthKitAndWellnessBoundaries() throws {
        let repositoryRoot = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        let audit = try String(
            contentsOf: repositoryRoot.appendingPathComponent("Docs/APP_REVIEW_AUDIT.md"),
            encoding: .utf8
        )
        let releaseGuide = try String(
            contentsOf: repositoryRoot.appendingPathComponent("Docs/APP_RELEASE_GUIDE.md"),
            encoding: .utf8
        )
        let privacyAudit = try String(
            contentsOf: repositoryRoot.appendingPathComponent("Docs/PRIVACY_STORAGE_AUDIT.md"),
            encoding: .utf8
        )
        let nextIssues = try String(
            contentsOf: repositoryRoot.appendingPathComponent("Docs/NEXT_ISSUES.md"),
            encoding: .utf8
        )

        #expect(audit.contains("App Review Notes"))
        #expect(audit.contains("Privacy / Data Boundary"))
        #expect(audit.contains("HealthKit Review Checklist"))
        #expect(audit.contains("Audio / Storage Review Checklist"))
        #expect(audit.contains("Data Safety Questionnaire Notes"))
        #expect(audit.contains("Open Manual Gates"))
        #expect(audit.contains("HealthKit is used only when the user explicitly chooses"))
        #expect(audit.contains("read access only"))
        #expect(audit.contains("does not write data to HealthKit"))
        #expect(audit.contains("does not upload health data or audio to a server"))
        #expect(audit.contains("does not store full-night raw audio by default"))
        #expect(audit.contains("Short event audio snippets can be stored locally only when the user explicitly enables"))
        #expect(audit.contains("No tracking, ads, external analytics SDK, or account login"))
        #expect(audit.contains("rg -n \"URLSession"))
        #expect(audit.contains("rg -n \"import HealthKit"))
        #expect(audit.contains("rg -n \"AVAudioFile"))
        #expect(releaseGuide.contains("Docs/APP_REVIEW_AUDIT.md"))
        #expect(privacyAudit.contains("Docs/APP_REVIEW_AUDIT.md"))
        #expect(nextIssues.contains("App Review 관점"))

        let forbiddenPhrases = [
            "수면무호흡증 " + "진단",
            "AHI " + "정확 측정",
            "이갈이 " + "확진",
            "질병 " + "판정",
            "치료 " + "필요",
            "정상" + "입니다",
            "코골이가 " + "없었습니다",
            "HealthKit에 데이터를 씁니다",
            "서버 업로드를 사용합니다",
            "전체 밤 원본 오디오를 저장합니다",
        ]

        for phrase in forbiddenPhrases {
            #expect(!audit.contains(phrase), "App Review audit should not introduce restricted wording: \(phrase)")
        }
    }

    @Test
    func debugOnlyScreensStayBehindDebugCompilation() throws {
        let repositoryRoot = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        let homeDashboard = try String(
            contentsOf: repositoryRoot.appendingPathComponent("SleepSoundApp/Features/Dashboard/HomeDashboardView.swift"),
            encoding: .utf8
        )

        let debugSectionRange = try #require(homeDashboard.range(of: "#if DEBUG"))
        let debugEndRange = try #require(
            homeDashboard.range(of: "#endif", range: debugSectionRange.upperBound..<homeDashboard.endIndex)
        )
        let debugSection = homeDashboard[debugSectionRange.lowerBound...debugEndRange.upperBound]

        for viewName in debugViewNames {
            #expect(debugSection.contains(viewName), "\(viewName) should only be linked inside #if DEBUG.")
        }

        for filePath in debugViewFilePaths {
            let contents = try String(
                contentsOf: repositoryRoot.appendingPathComponent(filePath),
                encoding: .utf8
            )
            #expect(contents.trimmingCharacters(in: .whitespacesAndNewlines).hasPrefix("#if DEBUG"))
        }
    }

    @Test
    func sampleCaptureViewStaysDebugOnlyAndShortManualCaptureOnly() throws {
        let repositoryRoot = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        let contents = try String(
            contentsOf: repositoryRoot.appendingPathComponent("SleepSoundApp/Features/Settings/SampleCaptureView.swift"),
            encoding: .utf8
        )

        #expect(contents.trimmingCharacters(in: .whitespacesAndNewlines).hasPrefix("#if DEBUG"))
        #expect(contents.contains("sampleButton(seconds: 2)"))
        #expect(contents.contains("sampleButton(seconds: 3)"))
        #expect(contents.contains("sampleButton(seconds: 5)"))
        #expect(!contents.contains("sampleButton(seconds: 10)"))
        #expect(!contents.contains("sampleButton(seconds: 30)"))
        #expect(contents.contains("storagePolicy.clampedSampleDuration(duration)"))
        #expect(contents.contains("maxSampleCount"))
        #expect(contents.contains("metadataFileName"))
        #expect(contents.contains("featureCSVFileName"))
        #expect(contents.contains("AVAudioFile(forWriting"))
        #expect(contents.contains("전체 밤 오디오는 저장하지 않습니다"))
        #expect(contents.contains("사용자가 누른 2초/3초/5초 구간만 DEBUG 빌드에서 저장합니다"))
    }

    @Test
    func privacySettingsCopyCoversStorageAndHealthKitPolicy() throws {
        let repositoryRoot = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        let contents = try String(
            contentsOf: repositoryRoot.appendingPathComponent("SleepSoundApp/Features/Settings/PrivacySettingsView.swift"),
            encoding: .utf8
        )

        #expect(contents.contains("기본값은 꺼짐입니다"))
        #expect(contents.contains("전체 밤 오디오는 저장하지 않습니다"))
        #expect(contents.contains("읽기 전용"))
        #expect(contents.contains("HealthKit에 데이터를 쓰지 않고"))
        #expect(contents.contains("서버로 전송하지 않습니다"))
        #expect(contents.contains("이벤트 피드백 삭제"))
        #expect(contents.contains("저장된 이벤트 오디오 샘플 전체 삭제"))
    }

    @Test
    func appSourceDoesNotIncludeTossOrTDSAssetsOrSDKNames() throws {
        let repositoryRoot = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        let appRoot = repositoryRoot.appendingPathComponent("SleepSoundApp")
        let restrictedTokens = [
            "To" + "ss",
            "T" + "DS",
            "TossPayments",
            "TossDesign",
        ]

        for fileURL in appFiles(under: appRoot) {
            let contents = try String(contentsOf: fileURL, encoding: .utf8)
            for token in restrictedTokens {
                #expect(!fileURL.lastPathComponent.contains(token), "\(fileURL.path) uses a restricted external asset name.")
                #expect(!contents.contains(token), "\(fileURL.path) contains a restricted external asset token.")
            }
        }
    }

    private var debugViewNames: [String] {
        [
            "SampleCaptureView",
            "AudioDebugView",
            "DebugAudioSamplesView",
            "DetectorTuningView",
            "DatasetReplayView",
            "SimulatorScenarioView",
        ]
    }

    private var debugViewFilePaths: [String] {
        [
            "SleepSoundApp/Features/Settings/SampleCaptureView.swift",
            "SleepSoundApp/Features/Settings/AudioDebugView.swift",
            "SleepSoundApp/Features/Settings/DebugAudioSamplesView.swift",
            "SleepSoundApp/Features/Settings/DetectorTuningView.swift",
            "SleepSoundApp/Features/Settings/DatasetReplayView.swift",
            "SleepSoundApp/Features/Settings/SimulatorScenarioView.swift",
        ]
    }

    private func infoPlist() throws -> NSDictionary {
        let repositoryRoot = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        let url = repositoryRoot.appendingPathComponent("SleepSoundApp/App/Info.plist")
        let data = try Data(contentsOf: url)
        let object = try PropertyListSerialization.propertyList(from: data, format: nil)
        return try #require(object as? NSDictionary)
    }

    private func appFiles(under root: URL) -> [URL] {
        guard let enumerator = FileManager.default.enumerator(
            at: root,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles]
        ) else {
            return []
        }

        return enumerator.compactMap { item in
            guard let url = item as? URL,
                  ["swift", "plist", "entitlements", "json", "xml"].contains(url.pathExtension.lowercased()) else {
                return nil
            }
            return url
        }
    }
}
