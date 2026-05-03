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
    }

    @Test
    func appStoreDocumentsExistAndUseSafeCopy() throws {
        let repositoryRoot = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        let documentPaths = [
            "Docs/APP_STORE_COPY_DRAFT.md",
            "Docs/TESTFLIGHT_CHECKLIST.md",
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
            "DetectorTuningView",
            "DatasetReplayView",
            "SimulatorScenarioView",
        ]
    }

    private var debugViewFilePaths: [String] {
        [
            "SleepSoundApp/Features/Settings/SampleCaptureView.swift",
            "SleepSoundApp/Features/Settings/AudioDebugView.swift",
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
