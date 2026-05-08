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

    private func read(_ relativePath: String) throws -> String {
        let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        return try String(contentsOf: root.appendingPathComponent(relativePath), encoding: .utf8)
    }
}
