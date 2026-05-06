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
        #expect(releaseGuide.contains("Privacy"))
        #expect(releaseGuide.contains("HealthKitReadOnlyPolicy"))
        #expect(productCopy.contains("Primary Locale: ko-KR"))
        #expect(productCopy.contains("Secondary Locale: en-US"))
        #expect(productCopy.contains("서버 업로드나 클라우드 처리를 사용하지 않습니다"))
        #expect(productCopy.contains("HealthKit은 사용자가 건강 데이터 연결을 선택한 경우에만 read-only"))
        #expect(productCopy.contains("전체 밤 원본 오디오는 기본 저장하지 않습니다"))
        #expect(reviewAudit.contains("Required Scans Before Submission"))
        #expect(privacyAudit.contains("전체 밤 원본 오디오를 파일로 저장하는 코드는 없습니다"))
        #expect(qaGuide.contains("Sensitive data included in repo: No"))

        for phrase in restrictedClaimPhrases {
            #expect(!combinedReleaseDocs.contains(phrase), "Release docs contain restricted wording: \(phrase)")
        }

        try assertAppSourceHasNoNetworkServerOrExternalSDK(root: root)
        try assertHealthKitImplementationStaysReadOnly(root: root)
        try assertAudioFileWritesStayInApprovedShortSampleStores(root: root)
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
