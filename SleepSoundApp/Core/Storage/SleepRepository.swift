import Foundation

public final class SleepRepository {
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

    public func latestReport() -> NightReport? {
        store.fetchLatestReport()
    }

    public func events(for sessionId: UUID) -> [SleepEvent] {
        store.fetchEvents(for: sessionId)
    }

    public func checkIn(for sessionId: UUID) -> MorningCheckIn? {
        store.fetchCheckIn(for: sessionId)
    }
}
