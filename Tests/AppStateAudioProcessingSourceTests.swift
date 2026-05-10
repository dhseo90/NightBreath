import Foundation
import Testing

@Suite("AppState Audio Processing Source")
struct AppStateAudioProcessingSourceTests {
    @Test
    func audioChunkProcessingRunsOutsideMainActorAndReturnsOnlyForUIUpdate() throws {
        let source = try read("SleepSoundApp/App/AppState.swift")

        #expect(source.contains("audioProcessingTask = Task.detached(priority: .utility)"))
        #expect(source.contains("let snapshot = await processor.process(chunk: chunk)"))
        #expect(source.contains("await MainActor.run { [weak self] in"))
        #expect(source.contains("self?.applyAudioProcessingSnapshot(snapshot, generation: generation)"))
        #expect(!source.contains("audioProcessingTask = Task(priority: .utility) { [weak self] in"))
    }

    @Test
    func audioProcessingSnapshotsPublishToUIAtThrottledCadence() throws {
        let source = try read("SleepSoundApp/App/AppState.swift")

        #expect(source.contains("private var lastAudioProcessingUIUpdateAt: Date?"))
        #expect(source.contains("private let audioProcessingUIRefreshInterval: TimeInterval = 1.0"))
        #expect(source.contains("let shouldRefreshUI = lastAudioProcessingUIUpdateAt == nil"))
        #expect(source.contains("now.timeIntervalSince(lastAudioProcessingUIUpdateAt ?? now) >= audioProcessingUIRefreshInterval"))
        #expect(!source.contains("||\n            snapshot.latestDetectedEventText != nil"))
        #expect(source.contains("guard shouldRefreshUI else { return }"))
        #expect(source.contains("lastAudioProcessingUIUpdateAt = now"))
        #expect(!source.contains("@Published var currentAudioFeatures"))
        #expect(!source.contains("currentAudioFeatures.append"))
    }

    @Test
    func stopFinalizationReplaysRecentAudioForLiveOfflineParityDiagnostics() throws {
        let source = try read("SleepSoundApp/App/AppState.swift")
        let diagnosticsSource = try read("SleepSoundApp/Core/Analysis/DetectorDiagnostics.swift")

        #expect(source.contains("let recentChunksForReplay = recentAudioBuffer.snapshot()"))
        #expect(source.contains("makeReplayDetectionSummary("))
        #expect(source.contains("attachRecentReplaySummary("))
        #expect(source.contains("updateSleepFinalizationMessage(\"남은 오디오 분석을 마무리하는 중입니다.\")"))
        #expect(source.contains("makeDebugAudioPreviewSaveTaskIfAllowed("))
        #expect(source.contains("Task.detached(priority: .utility)"))
        #expect(source.contains("recentAudioReplaySummary"))
        #expect(diagnosticsSource.contains("public var recentAudioReplaySummary: ReplayDetectionSummary?"))
        #expect(diagnosticsSource.contains("recentReplayRawCandidateCountByType"))
        #expect(diagnosticsSource.contains("recentReplayFinalEventCountByType"))
    }

    @Test
    func recordingViewKeepsClockAndDiagnosticsLightweight() throws {
        let source = try read("SleepSoundApp/Features/Sleep/SleepRecordingView.swift")

        #expect(!source.contains("TimelineView(.periodic"))
        #expect(source.contains("@State private var clockDate = Date()"))
        #expect(source.contains("await runRecordingClock()"))
        #expect(source.contains("@State private var showsDetailedDiagnostics = false"))
        #expect(source.contains("if shouldShowDetails"))
        #expect(source.contains("detailedMeasurementRows(metrics: metrics)"))
        #expect(source.contains("finalizationStatus"))
        #expect(source.contains("appState.audioCaptureMessage ?? appState.sleepRecordingPhase.message"))
    }

    @Test
    func debugAudioSampleToolsExposeOrphanAndMissingReferenceCleanup() throws {
        let appStateSource = try read("SleepSoundApp/App/AppState.swift")
        let viewSource = try read("SleepSoundApp/Features/Settings/DebugAudioSamplesView.swift")

        #expect(appStateSource.contains("func cleanupMissingEventAudioReferences()"))
        #expect(appStateSource.contains("eventAudioSnippetStore.snippetExists(fileName: fileName)"))
        #expect(appStateSource.contains("func isEventAudioSnippetLinked(fileName: String) -> Bool"))
        #expect(viewSource.contains("연결되지 않은 샘플 정리"))
        #expect(viewSource.contains("파일 없는 참조 정리"))
        #expect(viewSource.contains("이벤트 연결됨"))
        #expect(viewSource.contains("연결되지 않음"))
    }

    @Test
    func appRootShowsPrivacyCoverForInactiveSnapshots() throws {
        let source = try read("SleepSoundApp/App/SleepSoundApp.swift")

        #expect(source.contains("@Environment(\\.scenePhase) private var scenePhase"))
        #expect(source.contains("if scenePhase != .active"))
        #expect(source.contains("PrivacySnapshotCoverView()"))
        #expect(source.contains("개인 데이터 보호 중"))
        #expect(source.contains(".privacySensitive()"))
    }

    private func read(_ relativePath: String) throws -> String {
        let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        return try String(contentsOf: root.appendingPathComponent(relativePath), encoding: .utf8)
    }
}
