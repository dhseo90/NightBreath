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
      "치료 " + "필요",
      "진단 " + "요약",
      "Zero-event " + "진단"
    ]

    for phrase in forbiddenPhrases {
      #expect(!source.contains(phrase))
    }

    #expect(source.contains("Zero-event 분석"))
    #expect(source.contains("상세 분석"))
    #expect(source.contains("배치/거리 안내"))
    #expect(source.contains("iPhone을 베개 쪽에 더 가깝게"))
  }

  private func sleepReportViewSource() throws -> String {
    let url = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
      .appendingPathComponent("SleepSoundApp/Features/Sleep/SleepReportView.swift")
    return try String(contentsOf: url, encoding: .utf8)
  }
}
