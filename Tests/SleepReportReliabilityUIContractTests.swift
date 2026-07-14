import Foundation
import Testing

@Suite("Sleep Report Reliability UI Contract")
struct SleepReportReliabilityUIContractTests {
  @Test
  func sleepStartViewExposesHistoryAndSessionDetailNavigation() throws {
    let source = try sourceFile("SleepSoundApp/Features/Sleep/SleepStartView.swift")

    #expect(source.contains("SleepStartDestination.history"))
    #expect(source.contains("SleepSessionHistoryView"))
    #expect(source.contains("SleepSessionDetailView"))
    #expect(source.contains("수면 기록 히스토리"))
    #expect(source.contains("날짜별 리포트"))
    #expect(source.contains("측정 신뢰도"))
    #expect(source.contains("아침 체크인 연결"))
    #expect(source.contains("SleepTimelineView(report: item.report, events: item.events)"))
    #expect(source.contains("MorningCheckInView(sessionId: item.id)"))
  }

  @Test
  func appStateBuildsHistoryFromStoredSessionReportEventsAndCheckIn() throws {
    let source = try sourceFile("SleepSoundApp/App/AppState.swift")

    #expect(source.contains("struct SleepSessionHistoryItem"))
    #expect(source.contains("func sleepSessionHistory(limit: Int = 90)"))
    #expect(source.contains("func sleepSessionHistoryItem(for sessionId: UUID)"))
    #expect(source.contains("repository.sessions().compactMap"))
    #expect(source.contains("repository.report(for: session.id)"))
    #expect(source.contains("repository.events(for: session.id)"))
    #expect(source.contains("morningCheckIn: checkIn(for: session.id)"))
  }

  @Test
  func morningCheckInLoadsHistoricalSessionCheckIn() throws {
    let source = try sourceFile("SleepSoundApp/Features/Sleep/MorningCheckInView.swift")

    #expect(source.contains("appState.checkIn(for: sessionId)"))
    #expect(!source.contains("guard appState.morningCheckIn.sessionId == sessionId else { return }"))
  }

  private func sourceFile(_ path: String) throws -> String {
    let url = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
      .appendingPathComponent(path)
    return try String(contentsOf: url, encoding: .utf8)
  }
}
