import Foundation
import Testing
@testable import SleepSoundCore

@Suite("EventAudioSnippetStore")
struct EventAudioSnippetStoreTests {
    @Test
    func savesOnlyShortEventSnippetFromRetainedChunks() throws {
        let root = makeTemporaryDirectory()
        let store = EventAudioSnippetStore(
            snippetsDirectory: root,
            policy: EventAudioSnippetPolicy(
                preEventSeconds: 0.2,
                postEventSeconds: 0.3,
                maxSnippetDuration: 1.0,
                maxSnippetsPerSession: 10,
                maxFolderSizeBytes: 2_000_000,
                maxSnippetAge: 60
            )
        )
        let sessionId = UUID()
        let startedAt = Date(timeIntervalSince1970: 100)
        let chunks = makeChunks(startedAt: startedAt)
        let output = DetectorOutput(
            eventType: .snore,
            startedAt: startedAt.addingTimeInterval(1.1),
            endedAt: startedAt.addingTimeInterval(1.4),
            confidence: 0.8,
            intensity: 0.7,
            debugReason: "test event"
        )

        let snippet = try store.saveSnippet(sessionId: sessionId, output: output, chunks: chunks)

        #expect(snippet.sessionId == sessionId)
        #expect(snippet.eventType == .snore)
        #expect(snippet.duration > 0)
        #expect(snippet.duration <= 1.0)
        #expect(store.snippetExists(fileName: snippet.fileName))
        #expect(store.folderSizeBytes() > 0)

        try? FileManager.default.removeItem(at: root)
    }

    @Test
    func deletesIndividualAndAllSnippets() throws {
        let root = makeTemporaryDirectory()
        let store = EventAudioSnippetStore(snippetsDirectory: root)
        let snippet = try store.saveSnippet(
            sessionId: UUID(),
            output: makeOutput(startedAt: Date(timeIntervalSince1970: 200)),
            chunks: makeChunks(startedAt: Date(timeIntervalSince1970: 199))
        )

        #expect(store.snippetExists(fileName: snippet.fileName))

        try store.deleteSnippet(fileName: snippet.fileName)
        #expect(!store.snippetExists(fileName: snippet.fileName))

        let secondSnippet = try store.saveSnippet(
            sessionId: UUID(),
            output: makeOutput(startedAt: Date(timeIntervalSince1970: 210)),
            chunks: makeChunks(startedAt: Date(timeIntervalSince1970: 209))
        )
        #expect(store.snippetExists(fileName: secondSnippet.fileName))

        try store.deleteAllSnippets()
        #expect(!store.snippetExists(fileName: secondSnippet.fileName))
        #expect(store.folderSizeBytes() == 0)

        try? FileManager.default.removeItem(at: root)
    }

    @Test
    func rejectsWhenSessionSnippetLimitIsReached() throws {
        let root = makeTemporaryDirectory()
        let store = EventAudioSnippetStore(
            snippetsDirectory: root,
            policy: EventAudioSnippetPolicy(
                maxSnippetsPerSession: 1,
                maxFolderSizeBytes: 2_000_000
            )
        )
        let sessionId = UUID()

        _ = try store.saveSnippet(
            sessionId: sessionId,
            output: makeOutput(startedAt: Date(timeIntervalSince1970: 300)),
            chunks: makeChunks(startedAt: Date(timeIntervalSince1970: 299))
        )

        #expect(throws: EventAudioSnippetStoreError.snippetLimitReached) {
            try store.saveSnippet(
                sessionId: sessionId,
                output: makeOutput(startedAt: Date(timeIntervalSince1970: 305)),
                chunks: makeChunks(startedAt: Date(timeIntervalSince1970: 304))
            )
        }

        try? FileManager.default.removeItem(at: root)
    }

    private func makeOutput(startedAt: Date) -> DetectorOutput {
        DetectorOutput(
            eventType: .coughLike,
            startedAt: startedAt.addingTimeInterval(1.0),
            endedAt: startedAt.addingTimeInterval(1.2),
            confidence: 0.7,
            intensity: 0.8,
            debugReason: "test event"
        )
    }

    private func makeChunks(startedAt: Date) -> [AudioChunk] {
        let sampleRate = 8_000.0
        let duration = 0.5
        let sampleCount = Int(sampleRate * duration)

        return (0..<6).map { index in
            let timestamp = startedAt.addingTimeInterval(Double(index) * duration)
            let samples = (0..<sampleCount).map { sampleIndex in
                Float(sin(Double(sampleIndex) * 0.08)) * 0.25
            }
            return AudioChunk(samples: samples, sampleRate: sampleRate, startedAt: timestamp, duration: duration)
        }
    }

    private func makeTemporaryDirectory() -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent("NightBreathEventAudioSnippetTests-\(UUID().uuidString)", isDirectory: true)
    }
}
