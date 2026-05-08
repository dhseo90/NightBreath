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
        #expect(source.contains("let shouldRefreshUI = lastAudioProcessingUIUpdateAt == nil"))
        #expect(source.contains("now.timeIntervalSince(lastAudioProcessingUIUpdateAt ?? now) >= 0.75"))
        #expect(source.contains("snapshot.latestDetectedEventText != nil"))
        #expect(source.contains("guard shouldRefreshUI else { return }"))
        #expect(source.contains("lastAudioProcessingUIUpdateAt = now"))
        #expect(!source.contains("@Published var currentAudioFeatures"))
        #expect(!source.contains("currentAudioFeatures.append"))
    }

    private func read(_ relativePath: String) throws -> String {
        let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        return try String(contentsOf: root.appendingPathComponent(relativePath), encoding: .utf8)
    }
}
