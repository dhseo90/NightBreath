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
    func recordingViewKeepsClockAndDiagnosticsLightweight() throws {
        let source = try read("SleepSoundApp/Features/Sleep/SleepRecordingView.swift")

        #expect(!source.contains("TimelineView(.periodic"))
        #expect(source.contains("@State private var clockDate = Date()"))
        #expect(source.contains("await runRecordingClock()"))
        #expect(source.contains("@State private var showsDetailedDiagnostics = false"))
        #expect(source.contains("if shouldShowDetails"))
        #expect(source.contains("detailedMeasurementRows(metrics: metrics)"))
    }

    private func read(_ relativePath: String) throws -> String {
        let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        return try String(contentsOf: root.appendingPathComponent(relativePath), encoding: .utf8)
    }
}
