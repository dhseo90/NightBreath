import Foundation
import Testing
@testable import SleepSoundCore

@Suite("Sleep Recording Recovery Store")
struct SleepRecordingRecoveryStoreTests {
    @Test
    func recoveryPolicyOnlyRecoversUnfinishedDraftWithoutExistingReport() {
        let unfinishedDraft = makeDraft(
            session: SleepSession(startedAt: Date(timeIntervalSince1970: 1_000))
        )
        var completedSession = SleepSession(startedAt: Date(timeIntervalSince1970: 1_000))
        completedSession.endedAt = Date(timeIntervalSince1970: 2_000)
        let completedDraft = makeDraft(session: completedSession)

        #expect(SleepRecordingRecoveryPolicy.shouldRecover(unfinishedDraft, hasExistingReport: false))
        #expect(!SleepRecordingRecoveryPolicy.shouldRecover(unfinishedDraft, hasExistingReport: true))
        #expect(!SleepRecordingRecoveryPolicy.shouldRecover(completedDraft, hasExistingReport: false))
    }

    @Test
    func recoveryBuilderCreatesSafeLocalOnlyInterruptedReport() throws {
        let startedAt = Date(timeIntervalSince1970: 2_000)
        let recoveredAt = startedAt.addingTimeInterval(20 * 60)
        let session = SleepSession(
            startedAt: startedAt,
            measurementDuration: 12 * 60,
            devicePlacement: .bedside,
            modelVersion: "rule-test"
        )
        var metrics = AudioCaptureMetrics(captureStartedAt: startedAt)
        metrics.recordReceived(chunk: makeChunk(), at: startedAt.addingTimeInterval(30))
        metrics.recordAnalyzed(chunk: makeChunk(), at: startedAt.addingTimeInterval(31))
        metrics.recordInterruption(at: startedAt.addingTimeInterval(10 * 60))
        metrics.recordCaptureError(at: startedAt.addingTimeInterval(10 * 60))
        let draft = SleepRecordingRecoveryDraft(
            session: session,
            metrics: metrics,
            detectorBackend: "Rule-based",
            modelInstalled: false,
            thresholdsSnapshot: ["rule.snoreRMS": 0.05],
            tuningProfile: "보통",
            eventAudioSampleStorageEnabled: false,
            lastUpdatedAt: recoveredAt,
            lifecycleNote: AudioCaptureError.captureInterrupted.message
        )

        let bundle = SleepRecordingRecoveryReportBuilder().makeBundle(from: draft)
        let diagnostics = try #require(bundle.report.detectorDiagnostics)

        #expect(bundle.session.id == session.id)
        #expect(bundle.session.endedAt == recoveredAt)
        #expect(bundle.session.measurementDuration == 20 * 60)
        #expect(bundle.metrics.captureStoppedAt == recoveredAt)
        #expect(bundle.metrics.interruptionCount == 1)
        #expect(bundle.metrics.captureErrorCount == 1)
        #expect(bundle.report.interruptionCount == 1)
        #expect(bundle.report.receivedAudioDuration == 0.1)
        #expect(bundle.report.analyzedAudioDuration == 0.1)
        #expect(bundle.report.audioCoverageRatio < 0.01)
        #expect(bundle.report.measurementQuality == .poor)
        #expect(bundle.report.mainDisturbanceReason.contains("참고용"))
        #expect(diagnostics.detectorBackend == "Rule-based")
        #expect(!diagnostics.eventAudioSampleStorageEnabled)
        #expect(diagnostics.notes.contains { $0.contains("Recovered unfinished local sleep recording") })
        #expect(diagnostics.notes.contains { $0.contains("interruptions=1") })
        #expect(diagnostics.notes.contains { $0.contains("captureErrors=1") })
        #expect(diagnostics.notes.contains { $0.contains(AudioCaptureError.captureInterrupted.message) })
    }

    @Test
    func recoveryBuilderFallsBackToPoorCoverageWhenMetricsWereNotStarted() throws {
        let startedAt = Date(timeIntervalSince1970: 3_000)
        let recoveredAt = startedAt.addingTimeInterval(5 * 60)
        let session = SleepSession(startedAt: startedAt)
        let draft = makeDraft(
            session: session,
            metrics: AudioCaptureMetrics(),
            lastUpdatedAt: recoveredAt
        )

        let bundle = SleepRecordingRecoveryReportBuilder().makeBundle(from: draft)
        let diagnostics = try #require(bundle.report.detectorDiagnostics)

        #expect(bundle.metrics.captureStartedAt == startedAt)
        #expect(bundle.metrics.captureStoppedAt == recoveredAt)
        #expect(bundle.metrics.receivedAudioSeconds == 0)
        #expect(bundle.report.audioCoverageRatio == 0)
        #expect(bundle.report.measurementQuality == .poor)
        #expect(diagnostics.notes.contains { $0.contains("coverage=0.0%") })
    }

    @Test
    func jsonStoreSavesLoadsAndClearsLocalDraftMetadata() throws {
        let directoryURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("nightbreath-recovery-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        let fileURL = directoryURL.appendingPathComponent("draft.json")
        let store = JSONFileSleepRecordingRecoveryStore(fileURL: fileURL)

        let startedAt = Date(timeIntervalSince1970: 1_000)
        let session = SleepSession(
            id: UUID(uuidString: "11111111-1111-1111-1111-111111111111")!,
            startedAt: startedAt,
            devicePlacement: .bedside,
            appVersion: "1.1-test",
            modelVersion: "rule-test"
        )
        var metrics = AudioCaptureMetrics(captureStartedAt: startedAt)
        metrics.recordReceived(chunk: makeChunk(), at: startedAt.addingTimeInterval(10))
        metrics.recordAnalyzed(chunk: makeChunk(), at: startedAt.addingTimeInterval(11))

        let draft = SleepRecordingRecoveryDraft(
            session: session,
            metrics: metrics,
            detectorBackend: "Rule-based",
            modelInstalled: false,
            thresholdsSnapshot: ["rule.snoreRMS": 0.05, "invalid": .infinity],
            tuningProfile: "보통",
            eventAudioSampleStorageEnabled: false,
            lastUpdatedAt: startedAt.addingTimeInterval(12),
            lifecycleNote: " capture started "
        )

        store.save(draft)

        let loaded = try #require(store.load())
        #expect(loaded.session == session)
        #expect(loaded.metrics.receivedChunkCount == 1)
        #expect(loaded.metrics.analyzedChunkCount == 1)
        #expect(loaded.detectorBackend == "Rule-based")
        #expect(!loaded.modelInstalled)
        #expect(loaded.thresholdsSnapshot == ["rule.snoreRMS": 0.05])
        #expect(loaded.tuningProfile == "보통")
        #expect(!loaded.eventAudioSampleStorageEnabled)
        #expect(loaded.lifecycleNote == "capture started")

        let encoded = try String(contentsOf: fileURL, encoding: .utf8)
        #expect(encoded.contains("receivedAudioSeconds"))
        #expect(!encoded.contains("samples"))

        store.clear()
        #expect(store.load() == nil)
    }

    @Test
    func jsonRecoveryLifecycleSmokePersistsReportAndClearsDraft() throws {
        let directoryURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("nightbreath-recovery-smoke-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directoryURL) }

        let draftURL = directoryURL.appendingPathComponent("sleep-recording-draft.json")
        let repositoryURL = directoryURL.appendingPathComponent("sleep-data.json")
        let recoveryStore = JSONFileSleepRecordingRecoveryStore(fileURL: draftURL)
        let repository = JSONFileSleepRepository(fileURL: repositoryURL)
        let startedAt = Date(timeIntervalSince1970: 1_800_000_000)
        let recoveredAt = startedAt.addingTimeInterval(32 * 60)
        let session = SleepSession(
            startedAt: startedAt,
            devicePlacement: .bedside,
            appVersion: "1.1-test",
            modelVersion: "rule-test"
        )
        let metrics = AudioCaptureMetrics(
            captureStartedAt: startedAt,
            receivedAudioSeconds: 24 * 60,
            analyzedAudioSeconds: 23 * 60,
            receivedChunkCount: 240,
            analyzedChunkCount: 230
        )
        let draft = SleepRecordingRecoveryDraft(
            session: session,
            metrics: metrics,
            detectorBackend: "Rule-based",
            modelInstalled: false,
            thresholdsSnapshot: ["rule.snoreRMS": 0.045],
            tuningProfile: "보통",
            eventAudioSampleStorageEnabled: false,
            lastUpdatedAt: recoveredAt,
            lifecycleNote: "capture started"
        )

        recoveryStore.save(draft)

        let loadedDraft = try #require(JSONFileSleepRecordingRecoveryStore(fileURL: draftURL).load())
        #expect(SleepRecordingRecoveryPolicy.shouldRecover(loadedDraft, hasExistingReport: false))

        let bundle = SleepRecordingRecoveryReportBuilder().makeBundle(from: loadedDraft)
        repository.save(session: bundle.session, events: [], report: bundle.report)
        recoveryStore.clear()

        let reloadedRepository = JSONFileSleepRepository(fileURL: repositoryURL)
        let storedSession = try #require(reloadedRepository.session(for: session.id))
        let storedReport = try #require(reloadedRepository.report(for: session.id))

        #expect(storedSession.endedAt == recoveredAt)
        #expect(storedReport.isRecoveredUnfinishedRecording)
        #expect(storedReport.detectorDiagnostics?.isRecoveredUnfinishedRecording == true)
        #expect(storedReport.mainDisturbanceReason.contains("로컬 측정 정보"))
        #expect(reloadedRepository.events(for: session.id).isEmpty)
        #expect(JSONFileSleepRecordingRecoveryStore(fileURL: draftURL).load() == nil)
    }

    @Test
    func inMemoryStoreReplacesAndClearsDraft() {
        let store = InMemorySleepRecordingRecoveryStore()
        let firstSession = SleepSession(startedAt: Date(timeIntervalSince1970: 1_000))
        let secondSession = SleepSession(startedAt: Date(timeIntervalSince1970: 2_000))

        store.save(
            SleepRecordingRecoveryDraft(
                session: firstSession,
                metrics: AudioCaptureMetrics(captureStartedAt: firstSession.startedAt),
                detectorBackend: "Rule-based",
                modelInstalled: false,
                eventAudioSampleStorageEnabled: false
            )
        )
        store.save(
            SleepRecordingRecoveryDraft(
                session: secondSession,
                metrics: AudioCaptureMetrics(captureStartedAt: secondSession.startedAt),
                detectorBackend: "Rule-based",
                modelInstalled: false,
                eventAudioSampleStorageEnabled: false
            )
        )

        #expect(store.load()?.session.id == secondSession.id)

        store.clear()
        #expect(store.load() == nil)
    }

    private func makeChunk() -> AudioChunk {
        AudioChunk(
            timestamp: Date(timeIntervalSince1970: 1_000),
            sampleRate: 16_000,
            channelCount: 1,
            frameCount: 1_600,
            duration: 0.1,
            rms: 0.2,
            samples: [0.1, 0.2, 0.1]
        )
    }

    private func makeDraft(
        session: SleepSession,
        metrics: AudioCaptureMetrics? = nil,
        lastUpdatedAt: Date? = nil
    ) -> SleepRecordingRecoveryDraft {
        SleepRecordingRecoveryDraft(
            session: session,
            metrics: metrics ?? AudioCaptureMetrics(captureStartedAt: session.startedAt),
            detectorBackend: "Rule-based",
            modelInstalled: false,
            eventAudioSampleStorageEnabled: false,
            lastUpdatedAt: lastUpdatedAt ?? session.startedAt
        )
    }
}
