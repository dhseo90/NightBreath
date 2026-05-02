import Foundation

public protocol LocalDataStoreProtocol {
    func save(session: SleepSession)
    func save(events: [SleepEvent], for sessionId: UUID)
    func save(report: NightReport)
    func save(checkIn: MorningCheckIn)
    func fetchSessions() -> [SleepSession]
    func fetchEvents(for sessionId: UUID) -> [SleepEvent]
    func fetchLatestReport() -> NightReport?
    func fetchCheckIn(for sessionId: UUID) -> MorningCheckIn?
}

public final class InMemoryLocalDataStore: LocalDataStoreProtocol {
    private var sessions: [SleepSession] = []
    private var eventsBySession: [UUID: [SleepEvent]] = [:]
    private var reports: [NightReport] = []
    private var checkInsBySession: [UUID: MorningCheckIn] = [:]

    public init() {}

    public func save(session: SleepSession) {
        sessions.removeAll { $0.id == session.id }
        sessions.append(session)
    }

    public func save(events: [SleepEvent], for sessionId: UUID) {
        eventsBySession[sessionId] = events
    }

    public func save(report: NightReport) {
        reports.removeAll { $0.sessionId == report.sessionId }
        reports.append(report)
    }

    public func save(checkIn: MorningCheckIn) {
        checkInsBySession[checkIn.sessionId] = checkIn
    }

    public func fetchSessions() -> [SleepSession] {
        sessions.sorted { $0.startedAt > $1.startedAt }
    }

    public func fetchEvents(for sessionId: UUID) -> [SleepEvent] {
        eventsBySession[sessionId] ?? []
    }

    public func fetchLatestReport() -> NightReport? {
        reports.sorted { $0.generatedAt > $1.generatedAt }.first
    }

    public func fetchCheckIn(for sessionId: UUID) -> MorningCheckIn? {
        checkInsBySession[sessionId]
    }
}
