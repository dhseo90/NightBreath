import Foundation
import Testing
@testable import SleepSoundCore

@Suite("SleepRepository")
struct SleepRepositoryTests {
    @Test
    func jsonRepositoryPersistsSessionsReportsEventsAndCheckIns() throws {
        let fileURL = makeTemporaryStoreURL()
        let repository = JSONFileSleepRepository(fileURL: fileURL)
        let bundle = makeBundle(startOffset: -60 * 60, generatedOffset: -30)

        repository.save(session: bundle.session, events: bundle.events, report: bundle.report)
        repository.save(checkIn: bundle.checkIn)

        let reloadedRepository = JSONFileSleepRepository(fileURL: fileURL)

        #expect(reloadedRepository.session(for: bundle.session.id) == bundle.session)
        #expect(reloadedRepository.events(for: bundle.session.id) == bundle.events)
        #expect(reloadedRepository.report(for: bundle.session.id) == bundle.report)
        #expect(reloadedRepository.latestReport() == bundle.report)
        #expect(reloadedRepository.checkIn(for: bundle.session.id) == bundle.checkIn)

        try? FileManager.default.removeItem(at: fileURL.deletingLastPathComponent())
    }

    @Test
    func recentReportsReturnsOnlyRecentSevenDays() throws {
        let fileURL = makeTemporaryStoreURL()
        let repository = JSONFileSleepRepository(fileURL: fileURL)
        let recent = makeBundle(startOffset: -60 * 60, generatedOffset: -60)
        let old = makeBundle(startOffset: -9 * 24 * 60 * 60, generatedOffset: -9 * 24 * 60 * 60)

        repository.save(session: old.session, events: old.events, report: old.report)
        repository.save(session: recent.session, events: recent.events, report: recent.report)

        let reports = repository.recentReports(days: 7)

        #expect(reports.map(\.sessionId).contains(recent.session.id))
        #expect(!reports.map(\.sessionId).contains(old.session.id))

        try? FileManager.default.removeItem(at: fileURL.deletingLastPathComponent())
    }

    @Test
    func deleteSessionRemovesAssociatedSummaryData() throws {
        let fileURL = makeTemporaryStoreURL()
        let repository = JSONFileSleepRepository(fileURL: fileURL)
        let first = makeBundle(startOffset: -2 * 60 * 60, generatedOffset: -2 * 60 * 60)
        let second = makeBundle(startOffset: -60 * 60, generatedOffset: -60)

        repository.save(session: first.session, events: first.events, report: first.report)
        repository.save(checkIn: first.checkIn)
        repository.save(session: second.session, events: second.events, report: second.report)

        repository.deleteSession(id: first.session.id)

        #expect(repository.session(for: first.session.id) == nil)
        #expect(repository.events(for: first.session.id).isEmpty)
        #expect(repository.report(for: first.session.id) == nil)
        #expect(repository.checkIn(for: first.session.id) == nil)
        #expect(repository.session(for: second.session.id) == second.session)

        try? FileManager.default.removeItem(at: fileURL.deletingLastPathComponent())
    }

    @Test
    func deleteAllSleepDataClearsPersistentStore() throws {
        let fileURL = makeTemporaryStoreURL()
        let repository = JSONFileSleepRepository(fileURL: fileURL)
        let bundle = makeBundle(startOffset: -60 * 60, generatedOffset: -60)

        repository.save(session: bundle.session, events: bundle.events, report: bundle.report)
        repository.save(checkIn: bundle.checkIn)
        #expect(FileManager.default.fileExists(atPath: fileURL.path))

        repository.deleteAllSleepData()

        let reloadedRepository = JSONFileSleepRepository(fileURL: fileURL)
        #expect(reloadedRepository.sessions().isEmpty)
        #expect(reloadedRepository.latestReport() == nil)
        #expect(!FileManager.default.fileExists(atPath: fileURL.path))

        try? FileManager.default.removeItem(at: fileURL.deletingLastPathComponent())
    }

    private func makeTemporaryStoreURL() -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent("NightBreathTests-\(UUID().uuidString)", isDirectory: true)
            .appendingPathComponent("sleep-data.json")
    }

    private func makeBundle(
        startOffset: TimeInterval,
        generatedOffset: TimeInterval
    ) -> (session: SleepSession, events: [SleepEvent], report: NightReport, checkIn: MorningCheckIn) {
        let now = Date()
        let startedAt = now.addingTimeInterval(startOffset)
        let endedAt = startedAt.addingTimeInterval(7 * 60 * 60)
        let session = SleepSession(
            startedAt: startedAt,
            endedAt: endedAt,
            measurementDuration: endedAt.timeIntervalSince(startedAt),
            estimatedSleepDuration: 6.5 * 60 * 60,
            devicePlacement: .bedside
        )
        let event = SleepEvent(
            sessionId: session.id,
            type: .snore,
            startedAt: startedAt.addingTimeInterval(60),
            endedAt: startedAt.addingTimeInterval(180),
            confidence: 0.7,
            intensity: 0.4
        )
        let report = NightReport(
            sessionId: session.id,
            generatedAt: now.addingTimeInterval(generatedOffset),
            measurementDuration: session.measurementDuration,
            estimatedSleepDuration: session.estimatedSleepDuration,
            sleepSoundScore: 91,
            snoreTotalSeconds: event.duration,
            snoreRatio: event.duration / session.estimatedSleepDuration,
            bruxismLikeCount: 0,
            suspectedPauseCount: 0,
            gaspLikeCount: 0,
            coughLikeCount: 0,
            sleepTalkLikeCount: 0,
            environmentalNoiseCount: 0,
            awakeningSuspectedCount: 0,
            longestSuspectedPause: 0,
            mostDisturbedHourRange: nil,
            mainDisturbanceReason: "어젯밤은 비교적 조용하고 안정적인 수면 소리 패턴을 보였습니다."
        )
        let checkIn = MorningCheckIn(sessionId: session.id, refreshScore: 4, fatigueScore: 2, memo: "")

        return (session, [event], report, checkIn)
    }
}
