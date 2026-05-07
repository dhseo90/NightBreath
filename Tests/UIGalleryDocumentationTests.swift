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
  }

  @Test
  func pendingCaptureQueueDoesNotCreateBrokenImageMarkdown() throws {
    let uiGallery = try sourceContents("Docs/UI_GALLERY.md")
    let pendingPaths = [
      "Docs/Screenshots/Home/trend-dashboard.png",
      "Docs/Screenshots/Sleep/morning-check-in.png",
      "Docs/Screenshots/DailyRhythm/evening-check-in.png",
      "Docs/Screenshots/DailyRhythm/daily-health-card-export-preview.png",
      "Docs/Screenshots/EdgeStates/report-empty.png",
      "Docs/Screenshots/Debug/simulator-scenario.png",
    ]

    #expect(uiGallery.contains("Pending Capture Queue"))

    for path in pendingPaths {
      let galleryRelativePath = path.replacingOccurrences(of: "Docs/", with: "")

      #expect(uiGallery.contains(path), "\(path) should stay in the pending queue.")
      #expect(!uiGallery.contains("](\(galleryRelativePath))"), "\(path) should not be linked as an image until the file exists.")
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

  private func sourceContents(_ relativePath: String) throws -> String {
    try String(contentsOf: repositoryRoot().appendingPathComponent(relativePath), encoding: .utf8)
  }

  private func repositoryRoot() -> URL {
    URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
  }
}
