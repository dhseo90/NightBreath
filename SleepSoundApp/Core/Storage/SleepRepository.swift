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

public struct SleepRecordingRecoveryDraft: Codable, Equatable, Sendable {
    public var session: SleepSession
    public var metrics: AudioCaptureMetrics
    public var detectorBackend: String
    public var modelInstalled: Bool
    public var thresholdsSnapshot: [String: Double]
    public var tuningProfile: String?
    public var eventAudioSampleStorageEnabled: Bool
    public var lastUpdatedAt: Date
    public var lifecycleNote: String?

    public init(
        session: SleepSession,
        metrics: AudioCaptureMetrics,
        detectorBackend: String,
        modelInstalled: Bool,
        thresholdsSnapshot: [String: Double] = [:],
        tuningProfile: String? = nil,
        eventAudioSampleStorageEnabled: Bool,
        lastUpdatedAt: Date = Date(),
        lifecycleNote: String? = nil
    ) {
        self.session = session
        self.metrics = metrics.snapshot(at: lastUpdatedAt)
        self.detectorBackend = detectorBackend
        self.modelInstalled = modelInstalled
        self.thresholdsSnapshot = thresholdsSnapshot.filter { $0.value.isFinite }
        self.tuningProfile = tuningProfile
        self.eventAudioSampleStorageEnabled = eventAudioSampleStorageEnabled
        self.lastUpdatedAt = lastUpdatedAt
        self.lifecycleNote = lifecycleNote?.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

public enum SleepRecordingRecoveryPolicy {
    public static func shouldRecover(
        _ draft: SleepRecordingRecoveryDraft,
        hasExistingReport: Bool
    ) -> Bool {
        draft.session.endedAt == nil && !hasExistingReport
    }
}

public struct SleepRecordingRecoveryBundle: Equatable, Sendable {
    public var session: SleepSession
    public var report: NightReport
    public var metrics: AudioCaptureMetrics

    public init(
        session: SleepSession,
        report: NightReport,
        metrics: AudioCaptureMetrics
    ) {
        self.session = session
        self.report = report
        self.metrics = metrics
    }
}

public struct SleepRecordingRecoveryReportBuilder {
    public init() {}

    public func makeBundle(
        from draft: SleepRecordingRecoveryDraft,
        recoveredAt explicitRecoveredAt: Date? = nil
    ) -> SleepRecordingRecoveryBundle {
        let recoveredAt = max(explicitRecoveredAt ?? draft.lastUpdatedAt, draft.session.startedAt)
        let completedSession = makeCompletedSession(from: draft.session, recoveredAt: recoveredAt, metrics: draft.metrics)
        let metrics = recoveredMetrics(from: draft, recoveredAt: recoveredAt)

        var report = SleepScoreCalculator().makeReport(
            session: completedSession,
            events: [],
            captureMetrics: metrics
        )
        report.mainDisturbanceReason = "앱 재실행으로 이전 수면 기록이 중단되어, 저장된 로컬 측정 정보만 참고용으로 정리했습니다."
        report.detectorDiagnostics = makeDiagnostics(
            draft: draft,
            completedSession: completedSession,
            metrics: metrics
        )

        return SleepRecordingRecoveryBundle(
            session: completedSession,
            report: report,
            metrics: metrics
        )
    }

    private func recoveredMetrics(
        from draft: SleepRecordingRecoveryDraft,
        recoveredAt: Date
    ) -> AudioCaptureMetrics {
        var metrics = draft.metrics
        if metrics.captureStartedAt == nil {
            let elapsed = max(0, recoveredAt.timeIntervalSince(draft.session.startedAt))
            metrics = AudioCaptureMetrics(
                captureStartedAt: draft.session.startedAt,
                captureStoppedAt: recoveredAt,
                sessionElapsedSeconds: elapsed,
                captureActiveSeconds: elapsed,
                receivedAudioSeconds: 0,
                analyzedAudioSeconds: 0,
                audioCoverageRatio: 0
            )
        }

        metrics.stop(at: recoveredAt)
        if metrics.captureErrorCount == 0 {
            metrics.recordCaptureError(at: recoveredAt)
        }
        if draft.lifecycleNote == AudioCaptureError.captureInterrupted.message,
           metrics.interruptionCount == 0 {
            metrics.recordInterruption(at: recoveredAt)
        }
        return metrics
    }

    private func makeCompletedSession(
        from session: SleepSession,
        recoveredAt: Date,
        metrics: AudioCaptureMetrics
    ) -> SleepSession {
        let measuredDuration = max(
            recoveredAt.timeIntervalSince(session.startedAt),
            session.measurementDuration,
            metrics.sessionElapsedSeconds
        )
        let estimatedSleepStart = session.estimatedSleepStart ?? session.startedAt
        let estimatedWakeTime = session.estimatedWakeTime ?? recoveredAt
        let estimatedSleepDuration = max(estimatedWakeTime.timeIntervalSince(estimatedSleepStart), 0)

        return SleepSession(
            id: session.id,
            startedAt: session.startedAt,
            endedAt: recoveredAt,
            estimatedSleepStart: estimatedSleepStart,
            estimatedWakeTime: estimatedWakeTime,
            measurementDuration: measuredDuration,
            estimatedSleepDuration: estimatedSleepDuration,
            devicePlacement: session.devicePlacement,
            ambientNoiseBaseline: session.ambientNoiseBaseline,
            appVersion: session.appVersion,
            modelVersion: session.modelVersion
        )
    }

    private func makeDiagnostics(
        draft: SleepRecordingRecoveryDraft,
        completedSession: SleepSession,
        metrics: AudioCaptureMetrics
    ) -> DetectorDiagnostics {
        var notes = [
            DetectorDiagnostics.recoveredUnfinishedRecordingNote,
            metrics.coverageDiagnosticsSummary
        ]
        if let stopSummary = metrics.stopDiagnosticsSummary {
            notes.append(stopSummary)
        }
        if let lifecycleNote = draft.lifecycleNote, !lifecycleNote.isEmpty {
            notes.append("lastLifecycleNote=\(lifecycleNote)")
        }

        return DetectorDiagnostics(
            sessionId: completedSession.id,
            startedAt: completedSession.startedAt,
            endedAt: completedSession.endedAt,
            detectorBackend: draft.detectorBackend,
            modelInstalled: draft.modelInstalled,
            audioChunkCount: metrics.receivedChunkCount,
            analyzedChunkCount: metrics.analyzedChunkCount,
            receivedAudioSeconds: metrics.receivedAudioSeconds,
            analyzedAudioSeconds: metrics.analyzedAudioSeconds,
            audioCoverageRatio: metrics.audioCoverageRatio,
            thresholdsSnapshot: draft.thresholdsSnapshot,
            tuningProfile: draft.tuningProfile,
            eventAudioSampleStorageEnabled: draft.eventAudioSampleStorageEnabled,
            notes: notes
        )
    }
}

public protocol SleepRecordingRecoveryStoreProtocol: AnyObject {
    func save(_ draft: SleepRecordingRecoveryDraft)
    func load() -> SleepRecordingRecoveryDraft?
    func clear()
}

public final class InMemorySleepRecordingRecoveryStore: SleepRecordingRecoveryStoreProtocol {
    private var draft: SleepRecordingRecoveryDraft?

    public init(draft: SleepRecordingRecoveryDraft? = nil) {
        self.draft = draft
    }

    public func save(_ draft: SleepRecordingRecoveryDraft) {
        self.draft = draft
    }

    public func load() -> SleepRecordingRecoveryDraft? {
        draft
    }

    public func clear() {
        draft = nil
    }
}

public final class JSONFileSleepRecordingRecoveryStore: SleepRecordingRecoveryStoreProtocol {
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

    public func save(_ draft: SleepRecordingRecoveryDraft) {
        lock.lock()
        defer { lock.unlock() }

        guard let data = try? encoder.encode(draft) else { return }
        try? fileManager.createDirectory(
            at: fileURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try? data.write(to: fileURL, options: [.atomic])
    }

    public func load() -> SleepRecordingRecoveryDraft? {
        lock.lock()
        defer { lock.unlock() }

        guard let data = try? Data(contentsOf: fileURL), !data.isEmpty else {
            return nil
        }

        return try? decoder.decode(SleepRecordingRecoveryDraft.self, from: data)
    }

    public func clear() {
        lock.lock()
        defer { lock.unlock() }

        try? fileManager.removeItem(at: fileURL)
    }

    private static func defaultStoreURL(fileManager: FileManager) -> URL {
        let baseURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? fileManager.temporaryDirectory

        return baseURL
            .appendingPathComponent("NightBreath", isDirectory: true)
            .appendingPathComponent("sleep-recording-draft.json")
    }
}
