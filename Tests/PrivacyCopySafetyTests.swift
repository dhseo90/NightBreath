import Foundation
import Testing

@Suite("Privacy Copy Safety")
struct PrivacyCopySafetyTests {
  @Test
  func appSourceDoesNotContainDefinitiveMedicalClaims() throws {
    let repositoryRoot = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
    let scannedRoots = [
      repositoryRoot.appendingPathComponent("SleepSoundApp"),
      repositoryRoot.appendingPathComponent("README.md"),
      repositoryRoot.appendingPathComponent("Docs"),
      repositoryRoot.appendingPathComponent("QA_CHECKLIST.md"),
      repositoryRoot.appendingPathComponent("Tools/OfflineEvaluation"),
    ]
    let forbiddenPhrases = [
      "수면무호흡증 " + "진단",
      "AHI " + "정확 측정",
      "이갈이 " + "확진",
      "고혈압" + "입니다",
      "비만" + "입니다",
      "정상" + "입니다",
      "위험" + "합니다",
      "질병 " + "예측",
      "치료 " + "필요",
      "치료가 " + "필요합니다",
      "건강 " + "진단 " + "점수",
      "코골기 " + "때문에 혈압이 올랐습니다",
    ]

    for fileURL in textFiles(in: scannedRoots) {
      let contents = try String(contentsOf: fileURL, encoding: .utf8)
      for phrase in forbiddenPhrases {
        #expect(
          !contents.contains(phrase),
          "\(fileURL.path) contains a restricted claim phrase: \(phrase)"
        )
      }
    }
  }

  @Test
  func sourceRootsDoNotContainAudioFixtures() {
    let repositoryRoot = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
    let scannedRoots = [
      repositoryRoot.appendingPathComponent("SleepSoundApp"),
      repositoryRoot.appendingPathComponent("Tests"),
      repositoryRoot.appendingPathComponent("Tools/OfflineEvaluation"),
    ]

    for root in scannedRoots where FileManager.default.fileExists(atPath: root.path) {
      let audioFiles = audioFilesUnder(root)
      #expect(audioFiles.isEmpty, "Audio fixture files must stay outside git-tracked test fixtures.")
    }
  }

  @Test
  func fitdaysFixturesAreSyntheticAndNonIdentifying() throws {
    let repositoryRoot = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
    let fixtureRoot = repositoryRoot.appendingPathComponent("Tests/Fixtures/Fitdays")
    let csvFiles = files(under: fixtureRoot, extensions: ["csv"])

    #expect(csvFiles.map(\.lastPathComponent).sorted() == [
      "sample_fitdays_export.csv",
      "sample_fitdays_export_ko.csv",
    ])

    let restrictedFixtureTokens = [
      "Name",
      "Email",
      "Phone",
      "Address",
      "Birth",
      "DOB",
      "Seoul",
      "이름",
      "이메일",
      "전화",
      "주소",
      "생년",
      "서울",
      "@",
    ]

    for fileURL in csvFiles {
      let contents = try String(contentsOf: fileURL, encoding: .utf8)
      #expect(contents.contains("Synthetic fixture row"))
      for token in restrictedFixtureTokens {
        #expect(!contents.contains(token), "\(fileURL.path) contains identifying fixture token: \(token)")
      }
    }
  }

  @Test
  func repositoryTextDoesNotContainPersonalLocalPaths() throws {
    let repositoryRoot = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
    let scannedRoots = [
      repositoryRoot.appendingPathComponent("SleepSoundApp"),
      repositoryRoot.appendingPathComponent("Tests"),
      repositoryRoot.appendingPathComponent("Docs"),
      repositoryRoot.appendingPathComponent("README.md"),
      repositoryRoot.appendingPathComponent("QA_CHECKLIST.md"),
      repositoryRoot.appendingPathComponent("Package.swift"),
    ]
    let forbiddenPathFragments = [
      "/" + "Users/",
      "file:///" + "Users/",
      "C:" + "\\Users\\",
      "/" + "home/",
      "Desktop/" + "workspace",
    ]

    for fileURL in textFiles(in: scannedRoots) {
      let contents = try String(contentsOf: fileURL, encoding: .utf8)
      for fragment in forbiddenPathFragments {
        #expect(!contents.contains(fragment), "\(fileURL.path) contains a personal local path fragment: \(fragment)")
      }
    }
  }

  @Test
  func gitignoreKeepsPersonalAndPublicAudioOutOfTheRepo() throws {
    let repositoryRoot = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
    let gitignore = try String(
      contentsOf: repositoryRoot.appendingPathComponent(".gitignore"),
      encoding: .utf8
    )

    #expect(gitignore.contains(".DS_Store"))
    #expect(gitignore.contains("Datasets/"))
    #expect(gitignore.contains("Samples/Personal/"))
    #expect(gitignore.contains("Samples/Public/"))
    #expect(gitignore.contains("*.wav"))
    #expect(gitignore.contains("*.caf"))
    #expect(gitignore.contains("*.m4a"))
    #expect(gitignore.contains("Tools/FeatureLab/output/"))
    #expect(gitignore.contains("Tools/Training/output/"))
    #expect(gitignore.contains("Tools/DatasetReplay/output/"))
    #expect(gitignore.contains("Tools/OfflineEvaluation/output/"))
  }

  @Test
  func appDoesNotContainNetworkServerOrExternalSDKCode() throws {
    let repositoryRoot = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
    let scannedRoots = [
      repositoryRoot.appendingPathComponent("SleepSoundApp"),
      repositoryRoot.appendingPathComponent("Package.swift"),
    ]
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

    for fileURL in sourceFiles(in: scannedRoots) {
      let contents = try String(contentsOf: fileURL, encoding: .utf8)
      for signature in forbiddenSignatures {
        #expect(
          !contents.contains(signature),
          "\(fileURL.path) contains a forbidden network/server/external SDK signature: \(signature)"
        )
      }
    }
  }

  @Test
  func healthKitImplementationStaysReadOnlyAndScoped() throws {
    let repositoryRoot = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
    let scannedRoots = [
      repositoryRoot.appendingPathComponent("SleepSoundApp"),
      repositoryRoot.appendingPathComponent("Package.swift"),
      repositoryRoot.appendingPathComponent("SleepSoundApp.xcodeproj/project.pbxproj"),
    ]
    let scopedHealthKitSignatures = [
      "import HealthKit",
      "HKHealthStore",
      "requestAuthorization",
      "HKSampleQuery",
      "HKSampleType",
      "HKQuantityType",
    ]
    let allowedImplementationSuffix = "SleepSoundApp/Core/FutureHealth/HealthKitService.swift"
    let allowedMetadataSuffixes = [
      "SleepSoundApp/App/Info.plist",
      "SleepSoundApp/App/SleepSoundApp.entitlements",
      "SleepSoundApp.xcodeproj/project.pbxproj",
    ]

    for fileURL in textFiles(in: scannedRoots) {
      let contents = try String(contentsOf: fileURL, encoding: .utf8)
      for signature in scopedHealthKitSignatures where contents.contains(signature) {
        #expect(
          fileURL.path.hasSuffix(allowedImplementationSuffix),
          "\(fileURL.path) contains HealthKit implementation outside RealHealthKitService: \(signature)"
        )
      }

      if contents.contains("NSHealthShareUsageDescription")
          || contents.contains("com.apple.developer.healthkit")
          || contents.contains("com.apple.HealthKit") {
        #expect(
          allowedMetadataSuffixes.contains { fileURL.path.hasSuffix($0) },
          "\(fileURL.path) contains HealthKit metadata outside app configuration."
        )
      }
    }
  }

  @Test
  func healthKitWriteAndStreamingQueriesAreNotUsed() throws {
    let repositoryRoot = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
    let scannedRoots = [
      repositoryRoot.appendingPathComponent("SleepSoundApp"),
      repositoryRoot.appendingPathComponent("Package.swift"),
    ]
    let forbiddenHealthKitSignatures = [
      "HKAnchoredObjectQuery",
      "HKObserverQuery",
      "HKDeletedObject",
      "HKWorkout",
      "HKCategorySample",
      "NSHealthUpdateUsageDescription",
    ]

    for fileURL in textFiles(in: scannedRoots) {
      let contents = try String(contentsOf: fileURL, encoding: .utf8)
      for signature in forbiddenHealthKitSignatures {
        #expect(
          !contents.contains(signature),
          "\(fileURL.path) contains forbidden HealthKit write or streaming usage: \(signature)"
        )
      }
    }

    let healthKitService = try String(
      contentsOf: repositoryRoot.appendingPathComponent("SleepSoundApp/Core/FutureHealth/HealthKitService.swift"),
      encoding: .utf8
    )
    for signature in [".save(", ".delete("] {
      #expect(
        !healthKitService.contains(signature),
        "RealHealthKitService contains forbidden HealthKit write/delete usage: \(signature)"
      )
    }
  }

  @Test
  func appAudioFileWritesAreLimitedToShortSampleStores() throws {
    let repositoryRoot = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
    let appRoot = repositoryRoot.appendingPathComponent("SleepSoundApp")
    let allowedSuffixes = [
      "SleepSoundApp/Core/Storage/EventAudioSnippetStore.swift",
      "SleepSoundApp/Features/Settings/SampleCaptureView.swift",
    ]

    for fileURL in swiftAndMarkdownFiles(under: appRoot) where fileURL.pathExtension == "swift" {
      let contents = try String(contentsOf: fileURL, encoding: .utf8)
      guard contents.contains("AVAudioFile(forWriting") else { continue }

      #expect(
        allowedSuffixes.contains { fileURL.path.hasSuffix($0) },
        "\(fileURL.path) writes audio outside the approved short sample stores."
      )
    }
  }

  private func swiftAndMarkdownFiles(under root: URL) -> [URL] {
    guard let enumerator = FileManager.default.enumerator(
      at: root,
      includingPropertiesForKeys: [.isRegularFileKey],
      options: [.skipsHiddenFiles]
    ) else {
      return []
    }

    return enumerator.compactMap { item in
      guard let url = item as? URL,
            ["swift", "md"].contains(url.pathExtension.lowercased()) else {
        return nil
      }
      return url
    }
  }

  private func textFiles(in roots: [URL]) -> [URL] {
    roots.flatMap { root in
      if root.hasDirectoryPath {
        return textFiles(under: root)
      }

      return FileManager.default.fileExists(atPath: root.path) ? [root] : []
    }
  }

  private func textFiles(under root: URL) -> [URL] {
    guard let enumerator = FileManager.default.enumerator(
      at: root,
      includingPropertiesForKeys: [.isRegularFileKey],
      options: [.skipsHiddenFiles]
    ) else {
      return []
    }

    return enumerator.compactMap { item in
      guard let url = item as? URL,
            [
              "swift",
              "md",
              "plist",
              "entitlements",
              "pbxproj",
              "json",
              "xml",
            ].contains(url.pathExtension.lowercased()) else {
        return nil
      }
      return url
    }
  }

  private func sourceFiles(in roots: [URL]) -> [URL] {
    roots.flatMap { root in
      if root.hasDirectoryPath {
        return swiftAndMarkdownFiles(under: root).filter { $0.pathExtension == "swift" }
      }

      return FileManager.default.fileExists(atPath: root.path) ? [root] : []
    }
  }

  private func audioFilesUnder(_ root: URL) -> [URL] {
    guard let enumerator = FileManager.default.enumerator(
      at: root,
      includingPropertiesForKeys: [.isRegularFileKey],
      options: [.skipsHiddenFiles]
    ) else {
      return []
    }

    return enumerator.compactMap { item in
      guard let url = item as? URL,
            !url.path.contains("/output/"),
            ["wav", "caf", "m4a"].contains(url.pathExtension.lowercased()) else {
        return nil
      }
      return url
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
    .sorted { $0.path < $1.path }
  }
}
