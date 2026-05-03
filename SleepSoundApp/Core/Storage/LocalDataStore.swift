import Foundation

public protocol LocalDataStoreProtocol {
    func save(session: SleepSession)
    func save(events: [SleepEvent], for sessionId: UUID)
    func save(report: NightReport)
    func save(checkIn: MorningCheckIn)
    func fetchSessions() -> [SleepSession]
    func fetchEvents(for sessionId: UUID) -> [SleepEvent]
    func fetchReports() -> [NightReport]
    func fetchReport(for sessionId: UUID) -> NightReport?
    func fetchLatestReport() -> NightReport?
    func fetchCheckIn(for sessionId: UUID) -> MorningCheckIn?
    func deleteSession(id: UUID)
    func deleteAllSleepData()
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

    public func fetchReports() -> [NightReport] {
        reports.sorted { $0.generatedAt > $1.generatedAt }
    }

    public func fetchReport(for sessionId: UUID) -> NightReport? {
        reports.first { $0.sessionId == sessionId }
    }

    public func fetchLatestReport() -> NightReport? {
        fetchReports().first
    }

    public func fetchCheckIn(for sessionId: UUID) -> MorningCheckIn? {
        checkInsBySession[sessionId]
    }

    public func deleteSession(id: UUID) {
        sessions.removeAll { $0.id == id }
        eventsBySession.removeValue(forKey: id)
        reports.removeAll { $0.sessionId == id }
        checkInsBySession.removeValue(forKey: id)
    }

    public func deleteAllSleepData() {
        sessions.removeAll()
        eventsBySession.removeAll()
        reports.removeAll()
        checkInsBySession.removeAll()
    }
}

public final class JSONFileLocalDataStore: LocalDataStoreProtocol {
    public let fileURL: URL

    private let fileManager: FileManager
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    private let lock = NSLock()

    public init(
        fileURL: URL? = nil,
        fileManager: FileManager = .default
    ) {
        self.fileManager = fileManager
        self.fileURL = fileURL ?? Self.defaultStoreURL(fileManager: fileManager)

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        self.encoder = encoder
        self.decoder = JSONDecoder()

        try? fileManager.createDirectory(
            at: self.fileURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
    }

    public func save(session: SleepSession) {
        updateArchive { archive in
            archive.sessions.removeAll { $0.id == session.id }
            archive.sessions.append(session)
        }
    }

    public func save(events: [SleepEvent], for sessionId: UUID) {
        updateArchive { archive in
            archive.eventsBySessionID[sessionId.uuidString] = events
        }
    }

    public func save(report: NightReport) {
        updateArchive { archive in
            archive.reports.removeAll { $0.sessionId == report.sessionId }
            archive.reports.append(report)
        }
    }

    public func save(checkIn: MorningCheckIn) {
        updateArchive { archive in
            archive.checkInsBySessionID[checkIn.sessionId.uuidString] = checkIn
        }
    }

    public func fetchSessions() -> [SleepSession] {
        readArchive().sessions.sorted { $0.startedAt > $1.startedAt }
    }

    public func fetchEvents(for sessionId: UUID) -> [SleepEvent] {
        readArchive().eventsBySessionID[sessionId.uuidString] ?? []
    }

    public func fetchReports() -> [NightReport] {
        readArchive().reports.sorted { $0.generatedAt > $1.generatedAt }
    }

    public func fetchReport(for sessionId: UUID) -> NightReport? {
        readArchive().reports.first { $0.sessionId == sessionId }
    }

    public func fetchLatestReport() -> NightReport? {
        fetchReports().first
    }

    public func fetchCheckIn(for sessionId: UUID) -> MorningCheckIn? {
        readArchive().checkInsBySessionID[sessionId.uuidString]
    }

    public func deleteSession(id: UUID) {
        updateArchive { archive in
            archive.sessions.removeAll { $0.id == id }
            archive.eventsBySessionID.removeValue(forKey: id.uuidString)
            archive.reports.removeAll { $0.sessionId == id }
            archive.checkInsBySessionID.removeValue(forKey: id.uuidString)
        }
    }

    public func deleteAllSleepData() {
        lock.lock()
        defer { lock.unlock() }

        try? fileManager.removeItem(at: fileURL)
    }

    private static func defaultStoreURL(fileManager: FileManager) -> URL {
        let baseURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? fileManager.temporaryDirectory

        return baseURL
            .appendingPathComponent("NightBreath", isDirectory: true)
            .appendingPathComponent("sleep-data.json")
    }

    private func readArchive() -> SleepDataArchive {
        lock.lock()
        defer { lock.unlock() }

        guard let data = try? Data(contentsOf: fileURL), !data.isEmpty else {
            return SleepDataArchive()
        }

        return (try? decoder.decode(SleepDataArchive.self, from: data)) ?? SleepDataArchive()
    }

    private func updateArchive(_ update: (inout SleepDataArchive) -> Void) {
        lock.lock()
        defer { lock.unlock() }

        var archive = loadArchiveWithoutLock()
        update(&archive)
        persistArchiveWithoutLock(archive)
    }

    private func loadArchiveWithoutLock() -> SleepDataArchive {
        guard let data = try? Data(contentsOf: fileURL), !data.isEmpty else {
            return SleepDataArchive()
        }

        return (try? decoder.decode(SleepDataArchive.self, from: data)) ?? SleepDataArchive()
    }

    private func persistArchiveWithoutLock(_ archive: SleepDataArchive) {
        guard let data = try? encoder.encode(archive) else { return }

        try? fileManager.createDirectory(
            at: fileURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try? data.write(to: fileURL, options: [.atomic])
    }
}

public struct SleepDataArchive: Codable, Equatable {
    public var schemaVersion: Int
    public var sessions: [SleepSession]
    public var eventsBySessionID: [String: [SleepEvent]]
    public var reports: [NightReport]
    public var checkInsBySessionID: [String: MorningCheckIn]

    public init(
        schemaVersion: Int = 1,
        sessions: [SleepSession] = [],
        eventsBySessionID: [String: [SleepEvent]] = [:],
        reports: [NightReport] = [],
        checkInsBySessionID: [String: MorningCheckIn] = [:]
    ) {
        self.schemaVersion = schemaVersion
        self.sessions = sessions
        self.eventsBySessionID = eventsBySessionID
        self.reports = reports
        self.checkInsBySessionID = checkInsBySessionID
    }
}

public final class SleepEventFeedbackStore: @unchecked Sendable {
    public let fileURL: URL

    private let fileManager: FileManager
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    private let lock = NSLock()

    public init(
        fileURL: URL? = nil,
        fileManager: FileManager = .default
    ) {
        self.fileManager = fileManager
        self.fileURL = fileURL ?? Self.defaultStoreURL(fileManager: fileManager)

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        self.encoder = encoder

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        self.decoder = decoder

        try? fileManager.createDirectory(
            at: self.fileURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
    }

    public func save(_ feedback: SleepEventFeedback) throws {
        try updateArchive { archive in
            archive.feedbackByEventID[feedback.eventId.uuidString] = feedback
        }
    }

    public func feedback(for eventId: UUID) -> SleepEventFeedback? {
        readArchive().feedbackByEventID[eventId.uuidString]
    }

    public func fetchAll() -> [SleepEventFeedback] {
        readArchive().feedbackByEventID.values.sorted { $0.createdAt > $1.createdAt }
    }

    public func feedback(forSession sessionId: UUID) -> [SleepEventFeedback] {
        readArchive().feedbackByEventID.values
            .filter { $0.sessionId == sessionId }
            .sorted { $0.createdAt > $1.createdAt }
    }

    public func feedbackCount() -> Int {
        readArchive().feedbackByEventID.count
    }

    public func deleteFeedback(for eventIds: [UUID]) throws {
        try updateArchive { archive in
            for eventId in eventIds {
                archive.feedbackByEventID.removeValue(forKey: eventId.uuidString)
            }
        }
    }

    public func deleteFeedback(forSession sessionId: UUID) throws {
        try updateArchive { archive in
            archive.feedbackByEventID = archive.feedbackByEventID.filter { _, feedback in
                feedback.sessionId != sessionId
            }
        }
    }

    public func deleteAllFeedback() throws {
        lock.lock()
        defer { lock.unlock() }

        try? fileManager.removeItem(at: fileURL)
    }

    private static func defaultStoreURL(fileManager: FileManager) -> URL {
        let baseURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? fileManager.temporaryDirectory

        return baseURL
            .appendingPathComponent("NightBreath", isDirectory: true)
            .appendingPathComponent("sleep-event-feedback.json")
    }

    private func readArchive() -> SleepEventFeedbackArchive {
        lock.lock()
        defer { lock.unlock() }

        guard let data = try? Data(contentsOf: fileURL), !data.isEmpty else {
            return SleepEventFeedbackArchive()
        }

        return (try? decoder.decode(SleepEventFeedbackArchive.self, from: data)) ?? SleepEventFeedbackArchive()
    }

    private func updateArchive(_ update: (inout SleepEventFeedbackArchive) -> Void) throws {
        lock.lock()
        defer { lock.unlock() }

        var archive = loadArchiveWithoutLock()
        update(&archive)
        try persistArchiveWithoutLock(archive)
    }

    private func loadArchiveWithoutLock() -> SleepEventFeedbackArchive {
        guard let data = try? Data(contentsOf: fileURL), !data.isEmpty else {
            return SleepEventFeedbackArchive()
        }

        return (try? decoder.decode(SleepEventFeedbackArchive.self, from: data)) ?? SleepEventFeedbackArchive()
    }

    private func persistArchiveWithoutLock(_ archive: SleepEventFeedbackArchive) throws {
        try fileManager.createDirectory(
            at: fileURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )

        let data = try encoder.encode(archive)
        try data.write(to: fileURL, options: [.atomic])
    }
}

public struct SleepEventFeedbackArchive: Codable, Equatable, Sendable {
    public var schemaVersion: Int
    public var feedbackByEventID: [String: SleepEventFeedback]

    public init(
        schemaVersion: Int = 2,
        feedbackByEventID: [String: SleepEventFeedback] = [:]
    ) {
        self.schemaVersion = schemaVersion
        self.feedbackByEventID = feedbackByEventID
    }
}
