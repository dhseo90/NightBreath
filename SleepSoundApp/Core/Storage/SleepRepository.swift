import Foundation

public protocol SleepRepository: AnyObject {
    func save(session: SleepSession, events: [SleepEvent], report: NightReport)
    func save(checkIn: MorningCheckIn)
    func sessions() -> [SleepSession]
    func session(for sessionId: UUID) -> SleepSession?
    func latestReport() -> NightReport?
    func report(for sessionId: UUID) -> NightReport?
    func recentReports(days: Int) -> [NightReport]
    func events(for sessionId: UUID) -> [SleepEvent]
    func checkIn(for sessionId: UUID) -> MorningCheckIn?
    func deleteSession(id: UUID)
    func deleteAllSleepData()
}

public final class InMemorySleepRepository: SleepRepository {
    private let store: LocalDataStoreProtocol

    public init(store: LocalDataStoreProtocol = InMemoryLocalDataStore()) {
        self.store = store
    }

    public func save(session: SleepSession, events: [SleepEvent], report: NightReport) {
        store.save(session: session)
        store.save(events: events, for: session.id)
        store.save(report: report)
    }

    public func save(checkIn: MorningCheckIn) {
        store.save(checkIn: checkIn)
    }

    public func sessions() -> [SleepSession] {
        store.fetchSessions()
    }

    public func session(for sessionId: UUID) -> SleepSession? {
        store.fetchSessions().first { $0.id == sessionId }
    }

    public func latestReport() -> NightReport? {
        store.fetchLatestReport()
    }

    public func report(for sessionId: UUID) -> NightReport? {
        store.fetchReport(for: sessionId)
    }

    public func recentReports(days: Int = 7) -> [NightReport] {
        let cutoff = Date().addingTimeInterval(-TimeInterval(max(days, 1)) * 24 * 60 * 60)
        return store.fetchReports().filter { $0.generatedAt >= cutoff }
    }

    public func events(for sessionId: UUID) -> [SleepEvent] {
        store.fetchEvents(for: sessionId)
    }

    public func checkIn(for sessionId: UUID) -> MorningCheckIn? {
        store.fetchCheckIn(for: sessionId)
    }

    public func deleteSession(id: UUID) {
        store.deleteSession(id: id)
    }

    public func deleteAllSleepData() {
        store.deleteAllSleepData()
    }
}

public final class JSONFileSleepRepository: SleepRepository {
    private let store: LocalDataStoreProtocol

    public init(store: LocalDataStoreProtocol = JSONFileLocalDataStore()) {
        self.store = store
    }

    public convenience init(fileURL: URL) {
        self.init(store: JSONFileLocalDataStore(fileURL: fileURL))
    }

    public func save(session: SleepSession, events: [SleepEvent], report: NightReport) {
        store.save(session: session)
        store.save(events: events, for: session.id)
        store.save(report: report)
    }

    public func save(checkIn: MorningCheckIn) {
        store.save(checkIn: checkIn)
    }

    public func sessions() -> [SleepSession] {
        store.fetchSessions()
    }

    public func session(for sessionId: UUID) -> SleepSession? {
        store.fetchSessions().first { $0.id == sessionId }
    }

    public func latestReport() -> NightReport? {
        store.fetchLatestReport()
    }

    public func report(for sessionId: UUID) -> NightReport? {
        store.fetchReport(for: sessionId)
    }

    public func recentReports(days: Int = 7) -> [NightReport] {
        let cutoff = Date().addingTimeInterval(-TimeInterval(max(days, 1)) * 24 * 60 * 60)
        return store.fetchReports().filter { $0.generatedAt >= cutoff }
    }

    public func events(for sessionId: UUID) -> [SleepEvent] {
        store.fetchEvents(for: sessionId)
    }

    public func checkIn(for sessionId: UUID) -> MorningCheckIn? {
        store.fetchCheckIn(for: sessionId)
    }

    public func deleteSession(id: UUID) {
        store.deleteSession(id: id)
    }

    public func deleteAllSleepData() {
        store.deleteAllSleepData()
    }
}
