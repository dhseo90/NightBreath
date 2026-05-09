import Foundation
import Testing

@Suite("Release Readiness Gate")
struct ReleaseReadinessGateTests {
    @Test
    func releaseGateCoversAppStorePrivacyHealthKitNetworkAndAudioPolicies() throws {
        let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        let releaseGuide = try contents("Docs/APP_RELEASE_GUIDE.md", root: root)
        let productCopy = try contents("Docs/APP_STORE_PRODUCT_PAGE_COPY.md", root: root)
        let reviewAudit = try contents("Docs/APP_REVIEW_AUDIT.md", root: root)
        let privacyAudit = try contents("Docs/PRIVACY_STORAGE_AUDIT.md", root: root)
        let qaGuide = try contents("Docs/QA_GUIDE.md", root: root)
        let releaseAuditScript = try contents("Tools/Release/audit_release_copy.sh", root: root)
        let combinedReleaseDocs = [
            releaseGuide,
            productCopy,
            reviewAudit,
            privacyAudit,
            qaGuide,
        ].joined(separator: "\n")

        #expect(releaseGuide.contains("Automated Release Readiness Gate"))
        #expect(releaseGuide.contains("ReleaseReadiness"))
        #expect(releaseGuide.contains("AppStoreReadiness"))
        #expect(releaseGuide.contains("UIGalleryDocumentation"))
        #expect(releaseGuide.contains("SimulatorQAScenario"))
        #expect(releaseGuide.contains("Privacy"))
        #expect(releaseGuide.contains("HealthKitReadOnlyPolicy"))
        #expect(releaseGuide.contains("Tools/Release/audit_release_copy.sh"))
        #expect(releaseGuide.contains("Tools/Docs/validate_readme_links.sh"))
        #expect(releaseGuide.contains("Tools/Screenshots/validate_app_store_release_approval.sh"))
        #expect(releaseGuide.contains("REQUIRE_APP_STORE_RELEASE_APPROVED=1"))
        #expect(releaseAuditScript.contains("--filter ReleaseReadiness"))
        #expect(releaseAuditScript.contains("--filter AppStoreReadiness"))
        #expect(releaseAuditScript.contains("--filter UIGalleryDocumentation"))
        #expect(releaseAuditScript.contains("--filter SimulatorQAScenario"))
        #expect(releaseAuditScript.contains("--filter PrivacyCopySafety"))
        #expect(releaseAuditScript.contains("--filter HealthKitReadOnlyPolicy"))
        #expect(productCopy.contains("Primary Locale: ko-KR"))
        #expect(productCopy.contains("Secondary Locale: en-US"))
        #expect(productCopy.contains("서버 업로드나 클라우드 처리를 사용하지 않습니다"))
        #expect(productCopy.contains("HealthKit은 사용자가 건강 데이터 연결을 선택한 경우에만 read-only"))
        #expect(productCopy.contains("전체 밤 원본 오디오는 기본 저장하지 않습니다"))
        #expect(reviewAudit.contains("Required Scans Before Submission"))
        #expect(reviewAudit.contains("Tools/Release/audit_release_copy.sh"))
        #expect(reviewAudit.contains("UI Gallery screenshot quarantine"))
        #expect(reviewAudit.contains("Docs/REAL_DEVICE_QA_RUNBOOK.md"))
        #expect(reviewAudit.contains("Docs/TESTFLIGHT_INTERNAL_TEST_PLAN.md"))
        #expect(reviewAudit.contains("Final App Store screenshot visual inspection"))
        #expect(privacyAudit.contains("전체 밤 원본 오디오를 파일로 저장하는 코드는 없습니다"))
        #expect(privacyAudit.contains("`.csv`, `.tsv`, `.txt` 외의 파일"))
        #expect(qaGuide.contains("Sensitive data included in repo: No"))

        for phrase in restrictedClaimPhrases {
            #expect(!combinedReleaseDocs.contains(phrase), "Release docs contain restricted wording: \(phrase)")
        }

        try assertAppSourceHasNoNetworkServerOrExternalSDK(root: root)
        try assertHealthKitImplementationStaysReadOnly(root: root)
        try assertAudioFileWritesStayInApprovedShortSampleStores(root: root)
    }

    @Test
    func releaseFacingDocumentsAvoidMedicalNetworkAndIntegrationPromises() throws {
        let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        let documentPaths = [
            "README.md",
            "Docs/Product/README.md",
            "Docs/UI/README.md",
            "Docs/Architecture/README.md",
            "Docs/Privacy/README.md",
            "Docs/Health/README.md",
            "Docs/QA/README.md",
            "Docs/Release/README.md",
            "Docs/Screenshots/README.md",
            "Docs/UI_GALLERY.md",
            "Docs/UI_SCREEN_MAP.md",
            "Docs/APP_RELEASE_GUIDE.md",
            "Docs/APP_REVIEW_AUDIT.md",
            "Docs/APP_STORE_PRODUCT_PAGE_COPY.md",
            "Docs/TESTFLIGHT_INTERNAL_TEST_PLAN.md",
            "Docs/REAL_DEVICE_QA_RUNBOOK.md",
            "Docs/PRIVACY_STORAGE_AUDIT.md",
            "Docs/QA_GUIDE.md",
        ]
        let forbiddenPromisePhrases = [
            "수면무호흡증을 진단합니다",
            "수면무호흡증 진단 결과",
            "AHI를 정확하게 측정합니다",
            "이갈이를 확진합니다",
            "질병을 판정합니다",
            "치료가 필요합니다",
            "정상입니다",
            "코골이가 없었습니다",
            "서버에 업로드합니다",
            "클라우드에서 분석합니다",
            "클라우드 처리합니다",
            "외부 API로 전송합니다",
            "외부 분석 SDK를 사용합니다",
            "광고 SDK를 사용합니다",
            "계정 로그인을 사용합니다",
            "HealthKit에 기록합니다",
            "HealthKit에 데이터를 씁니다",
            "HealthKit write를 사용합니다",
            "수면 소리 점수를 HealthKit에 씁니다",
            "오늘의 리듬 점수를 HealthKit에 씁니다",
            "Fitdays와 자동 동기화합니다",
            "Fitdays 서버/API에 직접 연결합니다",
            "비공식 API를 사용합니다",
            "전체 밤 원본 오디오를 저장합니다",
        ]

        for path in documentPaths {
            let document = try contents(path, root: root)
            for phrase in forbiddenPromisePhrases {
                #expect(!document.contains(phrase), "\(path) contains forbidden release-facing promise: \(phrase)")
            }
        }
    }

    @Test
    func releaseCopyAuditScriptStaysLocalAndTestOnly() throws {
        let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        let script = try contents("Tools/Release/audit_release_copy.sh", root: root)
        let forbiddenShellFragments = [
            "curl ",
            "wget ",
            "gh ",
            "git push",
            "URLSession",
            "open ",
        ]

        #expect(script.contains("xcrun swift test"))
        #expect(script.contains("--no-parallel"))
        for fragment in forbiddenShellFragments {
            #expect(!script.contains(fragment), "Release audit script should stay local/test-only: \(fragment)")
        }
    }

    @Test
    func readmeLinkValidationCoversMainAndSubReadmes() throws {
        let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        let script = try contents("Tools/Docs/validate_readme_links.sh", root: root)
        let rootReadme = try contents("README.md", root: root)
        let requiredSubReadmes = [
            "Docs/Product/README.md",
            "Docs/UI/README.md",
            "Docs/Architecture/README.md",
            "Docs/Privacy/README.md",
            "Docs/Health/README.md",
            "Docs/QA/README.md",
            "Docs/Release/README.md",
        ]

        #expect(script.contains("README_FILES"))
        #expect(script.contains("ROOT_SUB_READMES"))
        #expect(script.contains("extract_markdown_targets"))
        #expect(script.contains("normalize_target"))

        for path in requiredSubReadmes {
            #expect(script.contains(path), "README link validation does not cover \(path)")
            #expect(rootReadme.contains("(\(path))"), "Root README does not link \(path)")
        }
    }

    private var restrictedClaimPhrases: [String] {
        [
            "수면무호흡증 " + "진단",
            "AHI " + "정확 측정",
            "이갈이 " + "확진",
            "질병 " + "판정",
            "치료 " + "필요",
            "정상" + "입니다",
            "코골이가 " + "없었습니다",
            "HealthKit에 데이터를 씁니다",
            "전체 밤 원본 오디오를 저장합니다",
            "Fitdays 서버/API에 직접 연결합니다",
        ]
    }

    private func assertAppSourceHasNoNetworkServerOrExternalSDK(root: URL) throws {
        let forbiddenSignatures = [
            "URLSession",
            "import Network",
            "NWConnection",
            "Alamofire",
            "Firebase",
            "AdMob",
            "GADMobileAds",
            "AppsFlyer",
            "Adjust",
            "Amplitude",
            "Mixpanel",
        ]

        for fileURL in swiftSourceFiles(in: [
            root.appendingPathComponent("SleepSoundApp"),
            root.appendingPathComponent("Package.swift"),
        ]) {
            let source = try String(contentsOf: fileURL, encoding: .utf8)
            for signature in forbiddenSignatures {
                #expect(
                    !source.contains(signature),
                    "\(relativePath(fileURL, root: root)) contains forbidden network/server/external SDK signature: \(signature)"
                )
            }
        }
    }

    private func assertHealthKitImplementationStaysReadOnly(root: URL) throws {
        let healthKitService = try contents("SleepSoundApp/Core/FutureHealth/HealthKitService.swift", root: root)
        let infoPlist = try contents("SleepSoundApp/App/Info.plist", root: root)
        let project = try contents("SleepSoundApp.xcodeproj/project.pbxproj", root: root)

        #expect(healthKitService.contains("toShare: Set<HKSampleType>()"))
        #expect(healthKitService.contains("HKSampleQuery"))
        #expect(infoPlist.contains("NSHealthShareUsageDescription"))
        #expect(!infoPlist.contains("NSHealthUpdateUsageDescription"))
        #expect(project.contains("com.apple.HealthKit"))

        let forbiddenHealthKitSignatures = [
            ".save(",
            ".delete(",
            "HKDeletedObject",
            "HKWorkout",
            "HKCategorySample",
            "HKObserverQuery",
            "HKAnchoredObjectQuery",
        ]

        for signature in forbiddenHealthKitSignatures {
            #expect(
                !healthKitService.contains(signature),
                "RealHealthKitService contains forbidden HealthKit write or streaming usage: \(signature)"
            )
        }
    }

    private func assertAudioFileWritesStayInApprovedShortSampleStores(root: URL) throws {
        let allowedSuffixes = [
            "SleepSoundApp/Core/Storage/EventAudioSnippetStore.swift",
            "SleepSoundApp/Features/Settings/SampleCaptureView.swift",
        ]

        for fileURL in swiftSourceFiles(in: [root.appendingPathComponent("SleepSoundApp")]) {
            let source = try String(contentsOf: fileURL, encoding: .utf8)
            guard source.contains("AVAudioFile(forWriting") else { continue }

            #expect(
                allowedSuffixes.contains { fileURL.path.hasSuffix($0) },
                "\(relativePath(fileURL, root: root)) writes audio outside approved short sample stores."
            )
        }
    }

    private func contents(_ relativePath: String, root: URL) throws -> String {
        try String(contentsOf: root.appendingPathComponent(relativePath), encoding: .utf8)
    }

    private func swiftSourceFiles(in roots: [URL]) -> [URL] {
        roots.flatMap { root in
            if root.hasDirectoryPath {
                return files(under: root, extensions: ["swift"])
            }

            return FileManager.default.fileExists(atPath: root.path) ? [root] : []
        }
    }

    private func files(under root: URL, extensions: Set<String>) -> [URL] {
        guard let enumerator = FileManager.default.enumerator(
            at: root,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles]
        ) else {
            return []
        }

        return enumerator.compactMap { item in
            guard let url = item as? URL,
                  extensions.contains(url.pathExtension.lowercased()) else {
                return nil
            }
            return url
        }
    }

    private func relativePath(_ fileURL: URL, root: URL) -> String {
        fileURL.path.replacingOccurrences(of: root.path + "/", with: "")
    }
}
