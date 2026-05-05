import Foundation
import Testing

@Suite("SleepReportView Contract")
struct SleepReportViewContractTests {
  @Test
  func reportViewDisplaysFinalSnoreReportMetricsAndTimelineEvents() throws {
    let source = try sleepReportViewSource()

    #expect(source.contains("title: \"코골기 시간\""))
    #expect(source.contains("report.snoreTotalSeconds"))
    #expect(source.contains("SleepTimelineView(report: report, events: events)"))
  }

  @Test
  func reportViewZeroEventCopyStaysNonDiagnostic() throws {
    let source = try sleepReportViewSource()
    let forbiddenPhrases = [
      "정상" + "입니다",
      "코골기가 " + "없었습니다",
      "수면무호흡증 " + "없음",
      "질병 " + "아님",
      "치료 " + "필요"
    ]

    for phrase in forbiddenPhrases {
      #expect(!source.contains(phrase))
    }
  }

  private func sleepReportViewSource() throws -> String {
    let url = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
      .appendingPathComponent("SleepSoundApp/Features/Sleep/SleepReportView.swift")
    return try String(contentsOf: url, encoding: .utf8)
  }
}
