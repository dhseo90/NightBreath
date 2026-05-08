import Foundation
import Testing

@Suite("UI Gallery Documentation")
struct UIGalleryDocumentationTests {
  @Test
  func uiGalleryQuarantinesScreenshotImagesUntilQualityReviewPasses() throws {
    let uiGallery = try sourceContents("Docs/UI_GALLERY.md")
    let readme = try sourceContents("README.md")
    let regex = try NSRegularExpression(pattern: #"!\[[^\]]*\]\((Screenshots/[^)\s]+)\)"#)
    let nsRange = NSRange(uiGallery.startIndex..<uiGallery.endIndex, in: uiGallery)
    let matches = regex.matches(in: uiGallery, range: nsRange)

    #expect(matches.isEmpty, "UI Gallery should not render screenshot candidates before visual QA passes.")
    #expect(!readme.contains("<img src=\"Docs/Screenshots/"), "README should not render quarantined screenshot candidates.")
    #expect(uiGallery.contains("Screenshot Quality Gate"))
    #expect(uiGallery.contains("captured, quality review pending"))
    #expect(uiGallery.contains("blocked, recapture required"))
    #expect(uiGallery.contains("| README 대표 8개 | blocked, recapture required |"))
    #expect(uiGallery.contains("Simulator QA"))
    #expect(readme.contains("품질 재검토 중"))
  }

  @Test
  func supportAndDebugScreensStayTrackedButNotRenderedUntilQualityReviewPasses() throws {
    let root = repositoryRoot()
    let uiGallery = try sourceContents("Docs/UI_GALLERY.md")
    let screenMap = try sourceContents("Docs/UI_SCREEN_MAP.md")
    let screenshotGuide = try sourceContents("Docs/Screenshots/README.md")
    let toolGuide = try sourceContents("Tools/Screenshots/README.md")
    let reviewSheetScript = try sourceContents("Tools/Screenshots/build_screenshot_review_sheet.sh")
    let expectedCapturedPaths = [
      "Docs/Screenshots/Privacy/cropped/privacy_settings_light.png",
      "Docs/Screenshots/Privacy/cropped/onboarding_light.png",
      "Docs/Screenshots/Privacy/cropped/device_placement_guide_light.png",
      "Docs/Screenshots/Privacy/cropped/calibration_light.png",
      "Docs/Screenshots/Debug/cropped/dataset_replay_light.png",
      "Docs/Screenshots/Debug/cropped/detector_tuning_light.png",
      "Docs/Screenshots/Debug/cropped/audio_debug_light.png",
      "Docs/Screenshots/Debug/cropped/sample_capture_light.png",
    ]

    #expect(uiGallery.contains("Privacy/Support"))
    #expect(uiGallery.contains("DEBUG observability"))
    #expect(screenMap.contains("captured, quality review pending"))
    #expect(screenMap.contains("internal-only, quality review pending"))
    #expect(!screenMap.contains("onboarding/device/calibration pending"))
    #expect(!screenMap.contains("replay/audio/sample capture pending"))

    for path in expectedCapturedPaths {
      #expect(FileManager.default.fileExists(atPath: root.appendingPathComponent(path).path), "\(path) should exist.")

      let galleryRelativePath = path.replacingOccurrences(of: "Docs/", with: "")
      #expect(uiGallery.contains(galleryRelativePath), "\(path) should stay tracked in UI Gallery.")
      #expect(!uiGallery.contains("](\(galleryRelativePath))"), "\(path) should not render as an image before quality review passes.")
      #expect(screenMap.contains(path), "\(path) should be listed in UI_SCREEN_MAP.")
      #expect(screenshotGuide.contains(galleryRelativePath.replacingOccurrences(of: "Screenshots/", with: "")), "\(path) should be documented in screenshot folder guide.")
    }

    #expect(toolGuide.contains("capture_support_screenshots.sh"))
    #expect(toolGuide.contains("현재 캡처 세트"))
    #expect(toolGuide.contains("Review Sheet"))
    #expect(screenshotGuide.contains("screenshot_review_sheet.html"))
    #expect(reviewSheetScript.contains("manual_gate"))
    #expect(reviewSheetScript.contains("DEBUG-only 화면 분리"))
  }

  @Test
  func directScenarioCaptureQueueDoesNotCreateBrokenImageMarkdown() throws {
    let root = repositoryRoot()
    let uiGallery = try sourceContents("Docs/UI_GALLERY.md")
    let capturedPaths = [
      "Docs/Screenshots/Home/cropped/trend-dashboard.png",
      "Docs/Screenshots/Sleep/cropped/morning-check-in.png",
      "Docs/Screenshots/DailyRhythm/cropped/evening-check-in.png",
      "Docs/Screenshots/DailyRhythm/cropped/daily-health-card-export-preview.png",
      "Docs/Screenshots/EdgeStates/cropped/report-empty.png",
      "Docs/Screenshots/Debug/cropped/simulator-scenario.png",
    ]

    #expect(uiGallery.contains("Direct Scenario Capture Queue"))

    for path in capturedPaths {
      let galleryRelativePath = path.replacingOccurrences(of: "Docs/", with: "")

      #expect(FileManager.default.fileExists(atPath: root.appendingPathComponent(path).path), "\(path) should exist.")
      #expect(uiGallery.contains(path), "\(path) should stay in the direct scenario capture queue.")
      #expect(!uiGallery.contains("](\(galleryRelativePath))"), "\(path) should not be linked as an image until visual QA passes.")
    }
  }

  @Test
  func appStoreScreenshotCandidateFlowDocumentsRawAndReviewCrops() throws {
    let root = repositoryRoot()
    let uiGallery = try sourceContents("Docs/UI_GALLERY.md")
    let expectedFiles = [
      "01_home_dashboard_light.png",
      "02_sleep_report_light.png",
      "03_sleep_timeline_light.png",
      "04_daily_rhythm_report_light.png",
      "05_daily_health_card_light.png",
      "06_health_metrics_overview_light.png",
      "07_privacy_settings_light.png",
      "08_zero_event_report_light.png",
    ]

    #expect(uiGallery.contains("App Store Screenshot Candidate Flow"))
    #expect(uiGallery.contains("Tools/Screenshots/build_screenshot_review_sheet.sh"))
    #expect(uiGallery.contains("Docs/Screenshots/AppStore/export/"))
    #expect(uiGallery.contains("커밋하지 않습니다"))
    #expect(uiGallery.contains("mock/synthetic data"))
    #expect(uiGallery.contains("실제 개인 건강 데이터"))
    #expect(uiGallery.contains("실제 오디오 파일명"))
    #expect(uiGallery.contains("blocked, recapture required"))
    #expect(uiGallery.contains("release-approved가 아니며"))

    for fileName in expectedFiles {
      let rawPath = "Docs/Screenshots/AppStore/raw/\(fileName)"
      let reviewPath = "Docs/Screenshots/AppStore/review-cropped/\(fileName)"

      #expect(FileManager.default.fileExists(atPath: root.appendingPathComponent(rawPath).path), "\(rawPath) should exist.")
      #expect(FileManager.default.fileExists(atPath: root.appendingPathComponent(reviewPath).path), "\(reviewPath) should exist.")
      #expect(uiGallery.contains(rawPath), "\(rawPath) should be documented in UI Gallery.")
      #expect(uiGallery.contains(reviewPath), "\(reviewPath) should be documented in UI Gallery.")
    }
  }

  @Test
  func screenshotStatusManifestDefinesAllowedApprovalStates() throws {
    let root = repositoryRoot()
    let manifest = try sourceContents("Docs/Screenshots/screenshot_status.tsv")
    let uiGallery = try sourceContents("Docs/UI_GALLERY.md")
    let screenshotGuide = try sourceContents("Docs/Screenshots/README.md")
    let toolGuide = try sourceContents("Tools/Screenshots/README.md")
    let rows = manifest
      .split(separator: "\n", omittingEmptySubsequences: true)
      .map { String($0).split(separator: "\t", omittingEmptySubsequences: false).map(String.init) }
    let header = try #require(rows.first)
    let dataRows = Array(rows.dropFirst())
    let allowedStatuses: Set<String> = [
      "screenshot pending",
      "captured, quality review pending",
      "internal-only, quality review pending",
      "blocked, recapture required",
      "release-approved",
    ]

    #expect(header == [
      "id",
      "group",
      "view_or_surface",
      "scenario",
      "raw_source",
      "review_asset",
      "status",
      "release_surface",
      "notes",
    ])
    #expect(dataRows.count >= 30)
    #expect(uiGallery.contains("Docs/Screenshots/screenshot_status.tsv"))
    #expect(screenshotGuide.contains("Docs/Screenshots/screenshot_status.tsv"))
    #expect(toolGuide.contains("release-approved"))

    var appStoreBlockedCount = 0
    var readmeBlockedCount = 0
    var debugInternalCount = 0
    var releaseApprovedCount = 0

    for row in dataRows {
      #expect(row.count == header.count, "Every screenshot status row should keep the TSV schema: \(row)")
      let group = row[1]
      let rawSource = row[4]
      let reviewAsset = row[5]
      let status = row[6]

      #expect(allowedStatuses.contains(status), "Unexpected screenshot status: \(status)")

      if status == "release-approved" {
        releaseApprovedCount += 1
      }
      if group == "App Store", status == "blocked, recapture required" {
        appStoreBlockedCount += 1
      }
      if group == "README", status == "blocked, recapture required" {
        readmeBlockedCount += 1
      }
      if group == "Debug", status == "internal-only, quality review pending" {
        debugInternalCount += 1
      }

      if status != "screenshot pending" {
        #expect(FileManager.default.fileExists(atPath: root.appendingPathComponent(rawSource).path), "\(rawSource) should exist.")
        #expect(FileManager.default.fileExists(atPath: root.appendingPathComponent(reviewAsset).path), "\(reviewAsset) should exist.")
      }
    }

    #expect(appStoreBlockedCount == 8)
    #expect(readmeBlockedCount == 8)
    #expect(debugInternalCount >= 4)
    #expect(releaseApprovedCount == 0)
  }

  @Test
  func screenshotManifestValidationScriptRunsLocalGate() throws {
    let root = repositoryRoot()
    let script = root.appendingPathComponent("Tools/Screenshots/validate_screenshot_manifest.sh")
    let scriptContents = try sourceContents("Tools/Screenshots/validate_screenshot_manifest.sh")
    let toolGuide = try sourceContents("Tools/Screenshots/README.md")
    let screenshotGuide = try sourceContents("Docs/Screenshots/README.md")
    let uiGallery = try sourceContents("Docs/UI_GALLERY.md")

    #expect(FileManager.default.fileExists(atPath: script.path))
    #expect(scriptContents.contains("EXPECTED_HEADER"))
    #expect(scriptContents.contains("ALLOWED_STATUSES"))
    #expect(scriptContents.contains("release-approved"))
    #expect(scriptContents.contains("DEBUG only"))
    #expect(scriptContents.contains("Docs/UI_GALLERY.md"))
    #expect(scriptContents.contains("Docs/UI_SCREEN_MAP.md"))
    #expect(toolGuide.contains("validate_screenshot_manifest.sh"))
    #expect(screenshotGuide.contains("validate_screenshot_manifest.sh"))
    #expect(uiGallery.contains("validate_screenshot_manifest.sh"))

    let process = Process()
    let output = Pipe()
    process.executableURL = script
    process.currentDirectoryURL = root
    process.standardOutput = output
    process.standardError = output

    try process.run()
    process.waitUntilExit()

    let data = output.fileHandleForReading.readDataToEndOfFile()
    let outputText = String(data: data, encoding: .utf8) ?? ""

    #expect(process.terminationStatus == 0, "Script failed: \(outputText)")
    #expect(outputText.contains("Screenshot manifest validation passed."))
  }

  @Test
  func screenshotReviewManifestDoesNotLoosenCanonicalStatus() throws {
    let statusRows = try screenshotStatusRows()
    let reviewRows = try reviewManifestRows()
    let canonicalStatusByAsset = Dictionary(uniqueKeysWithValues: statusRows.compactMap { row -> (String, String)? in
      guard
        let rawSource = row["raw_source"],
        let reviewAsset = row["review_asset"],
        let status = row["status"],
        !rawSource.isEmpty,
        !reviewAsset.isEmpty
      else {
        return nil
      }

      return ("\(rawSource)|\(reviewAsset)", status)
    })

    var checkedRows = 0
    for row in reviewRows {
      let rawSource = row["raw_source"] ?? ""
      let reviewCrop = row["review_crop"] ?? ""
      let reviewStatus = row["status"] ?? ""
      let key = "\(rawSource)|\(reviewCrop)"

      guard let canonicalStatus = canonicalStatusByAsset[key] else { continue }

      checkedRows += 1
      #expect(
        reviewStatus == canonicalStatus,
        "Review sheet status should match screenshot_status.tsv for \(key)."
      )
    }

    #expect(checkedRows >= 30)
  }

  @Test
  func screenshotStatusManifestCoversGalleryAndScreenMapPngReferences() throws {
    let rows = try screenshotStatusRows()
    let manifestPaths = Set(rows.flatMap { row in
      [row["raw_source"], row["review_asset"]]
        .compactMap { $0 }
        .filter { !$0.isEmpty }
    })
    let documentationFiles = [
      "Docs/UI_GALLERY.md",
      "Docs/UI_SCREEN_MAP.md",
    ]

    for relativePath in documentationFiles {
      let contents = try sourceContents(relativePath)
      let referencedPaths = try screenshotPNGPaths(in: contents)

      for path in referencedPaths {
        #expect(manifestPaths.contains(path), "\(relativePath) references \(path), but screenshot_status.tsv does not track it.")
      }
    }
  }

  private func sourceContents(_ relativePath: String) throws -> String {
    try String(contentsOf: repositoryRoot().appendingPathComponent(relativePath), encoding: .utf8)
  }

  private func repositoryRoot() -> URL {
    URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
  }

  private func screenshotStatusRows() throws -> [[String: String]] {
    let manifest = try sourceContents("Docs/Screenshots/screenshot_status.tsv")
    return try tsvRows(from: manifest)
  }

  private func reviewManifestRows() throws -> [[String: String]] {
    let root = repositoryRoot()
    let outputDirectory = URL(fileURLWithPath: NSTemporaryDirectory())
      .appendingPathComponent("nightbreath-screenshot-review-\(UUID().uuidString)")
    let script = root.appendingPathComponent("Tools/Screenshots/build_screenshot_review_sheet.sh")
    var environment = ProcessInfo.processInfo.environment
    environment["SCREENSHOT_REVIEW_OUTPUT_DIR"] = outputDirectory.path

    try FileManager.default.createDirectory(at: outputDirectory, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: outputDirectory) }

    let process = Process()
    let output = Pipe()
    process.executableURL = script
    process.currentDirectoryURL = root
    process.environment = environment
    process.standardOutput = output
    process.standardError = output

    try process.run()
    process.waitUntilExit()

    let outputText = String(
      data: output.fileHandleForReading.readDataToEndOfFile(),
      encoding: .utf8
    ) ?? ""
    #expect(process.terminationStatus == 0, "Review sheet script failed: \(outputText)")

    let manifest = try String(
      contentsOf: outputDirectory.appendingPathComponent("screenshot_review_manifest.tsv"),
      encoding: .utf8
    )
    return try tsvRows(from: manifest)
  }

  private func tsvRows(from manifest: String) throws -> [[String: String]] {
    let rows = manifest
      .split(separator: "\n", omittingEmptySubsequences: true)
      .map { String($0).split(separator: "\t", omittingEmptySubsequences: false).map(String.init) }
    let header = try #require(rows.first)

    return rows.dropFirst().map { row in
      Dictionary(uniqueKeysWithValues: zip(header, row))
    }
  }

  private func screenshotPNGPaths(in contents: String) throws -> Set<String> {
    let regex = try NSRegularExpression(pattern: #"Docs/Screenshots/[^\s`\|\)\]]+\.png"#)
    let nsRange = NSRange(contents.startIndex..<contents.endIndex, in: contents)
    let matches = regex.matches(in: contents, range: nsRange)

    return Set(matches.compactMap { match in
      guard let range = Range(match.range, in: contents) else { return nil }
      return String(contents[range])
    })
  }
}
