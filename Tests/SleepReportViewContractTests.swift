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
    #expect(source.contains("coverageDiagnosticItems"))
    #expect(source.contains("커버리지 원인"))
    #expect(source.contains("수신되지 않은 시간"))
    #expect(source.contains("measurementReliabilityNotice"))
    #expect(source.contains("짧은 측정 기록"))
    #expect(source.contains("긴 세션의 커버리지 확인"))
    #expect(source.contains("장시간 측정 기준 충족"))
  }

  @Test
  func reportViewSeparatesRecoveredRecordingFromOrdinaryZeroEventReport() throws {
    let source = try sleepReportViewSource()

    #expect(source.contains("report.isRecoveredUnfinishedRecording"))
    #expect(source.contains("복구된 수면 기록"))
    #expect(source.contains("로컬 메타데이터 기반"))
    #expect(source.contains("이벤트 0개를 조용한 밤으로 해석하지 않습니다"))
    #expect(source.contains("복구된 기록에는 최종 이벤트가 없습니다"))
    #expect(source.contains("조용한 밤이라는 해석이 아니라 로컬 기록 정리용 참고 정보"))
  }

  private func sleepReportViewSource() throws -> String {
    let url = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
      .appendingPathComponent("SleepSoundApp/Features/Sleep/SleepReportView.swift")
    return try String(contentsOf: url, encoding: .utf8)
  }
}
