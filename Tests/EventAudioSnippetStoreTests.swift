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

    @Test
    func snippetLimitIsAppliedPerSessionNotWholeFolder() throws {
        let root = makeTemporaryDirectory()
        let store = EventAudioSnippetStore(
            snippetsDirectory: root,
            policy: EventAudioSnippetPolicy(
                maxSnippetsPerSession: 1,
                maxFolderSizeBytes: 2_000_000
            )
        )
        let firstSessionId = UUID()
        let secondSessionId = UUID()

        let first = try store.saveSnippet(
            sessionId: firstSessionId,
            output: makeOutput(startedAt: Date(timeIntervalSince1970: 320)),
            chunks: makeChunks(startedAt: Date(timeIntervalSince1970: 319))
        )
        let second = try store.saveSnippet(
            sessionId: secondSessionId,
            output: makeOutput(startedAt: Date(timeIntervalSince1970: 330)),
            chunks: makeChunks(startedAt: Date(timeIntervalSince1970: 329))
        )

        #expect(store.snippetExists(fileName: first.fileName))
        #expect(store.snippetExists(fileName: second.fileName))
        #expect(store.storageStats(linkedFileNames: [first.fileName, second.fileName]).sampleCount == 2)
        #expect(throws: EventAudioSnippetStoreError.snippetLimitReached) {
            try store.saveSnippet(
                sessionId: firstSessionId,
                output: makeOutput(startedAt: Date(timeIntervalSince1970: 340)),
                chunks: makeChunks(startedAt: Date(timeIntervalSince1970: 339))
            )
        }

        try? FileManager.default.removeItem(at: root)
    }

    @Test
    func removesNewSnippetIfProjectedFolderSizeWouldExceedPolicy() throws {
        let root = makeTemporaryDirectory()
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        let existingSample = root.appendingPathComponent("existing_near_limit.caf")
        try Data(repeating: 7, count: 1_048_000).write(to: existingSample)
        let store = EventAudioSnippetStore(
            snippetsDirectory: root,
            policy: EventAudioSnippetPolicy(
                maxSnippetsPerSession: 10,
                maxFolderSizeBytes: 1_048_576
            )
        )
        let beforeFiles = try FileManager.default.contentsOfDirectory(atPath: root.path)

        #expect(throws: EventAudioSnippetStoreError.folderSizeLimitExceeded) {
            try store.saveSnippet(
                sessionId: UUID(),
                output: makeOutput(startedAt: Date(timeIntervalSince1970: 350)),
                chunks: makeChunks(startedAt: Date(timeIntervalSince1970: 349))
            )
        }

        let afterFiles = try FileManager.default.contentsOfDirectory(atPath: root.path)
        #expect(beforeFiles == afterFiles)
        #expect(FileManager.default.fileExists(atPath: existingSample.path))
        #expect(store.folderSizeBytes() == 1_048_000)

        try? FileManager.default.removeItem(at: root)
    }

    @Test
    func savingSnippetDoesNotAutomaticallyDeleteExistingSamples() throws {
        let root = makeTemporaryDirectory()
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        let existingSample = root.appendingPathComponent("existing_event_sample.caf")
        try Data([0, 1, 2, 3]).write(to: existingSample)
        try FileManager.default.setAttributes(
            [.modificationDate: Date(timeIntervalSince1970: 0)],
            ofItemAtPath: existingSample.path
        )

        let store = EventAudioSnippetStore(
            snippetsDirectory: root,
            policy: EventAudioSnippetPolicy(
                maxSnippetsPerSession: 10,
                maxFolderSizeBytes: 2_000_000,
                maxSnippetAge: 60
            )
        )

        _ = try store.saveSnippet(
            sessionId: UUID(),
            output: makeOutput(startedAt: Date(timeIntervalSince1970: 400)),
            chunks: makeChunks(startedAt: Date(timeIntervalSince1970: 399))
        )

        #expect(FileManager.default.fileExists(atPath: existingSample.path))

        try? FileManager.default.removeItem(at: root)
    }

    @Test
    func storageStatsSeparatesLinkedAndOrphanSamples() throws {
        let root = makeTemporaryDirectory()
        let store = EventAudioSnippetStore(
            snippetsDirectory: root,
            policy: EventAudioSnippetPolicy(maxSnippetsPerSession: 10, maxFolderSizeBytes: 2_000_000)
        )

        let linkedSnippet = try store.saveSnippet(
            sessionId: UUID(),
            output: makeOutput(startedAt: Date(timeIntervalSince1970: 500)),
            chunks: makeChunks(startedAt: Date(timeIntervalSince1970: 499))
        )
        _ = try store.saveSnippet(
            sessionId: UUID(),
            output: makeOutput(startedAt: Date(timeIntervalSince1970: 510)),
            chunks: makeChunks(startedAt: Date(timeIntervalSince1970: 509))
        )

        let stats = store.storageStats(linkedFileNames: [linkedSnippet.fileName])

        #expect(stats.sampleCount == 2)
        #expect(stats.linkedSampleCount == 1)
        #expect(stats.orphanSampleCount == 1)
        #expect(stats.totalBytes > 0)
        #expect(stats.linkedBytes > 0)
        #expect(stats.orphanBytes > 0)
        #expect(stats.totalDurationSeconds > 0)
        #expect(!stats.formattedTotalSize.isEmpty)
        #expect(stats.latestSampleCreatedAt != nil)

        try? FileManager.default.removeItem(at: root)
    }

    @Test
    func cleanupOrphanSnippetsDeletesOnlyUnlinkedSamples() throws {
        let root = makeTemporaryDirectory()
        let store = EventAudioSnippetStore(
            snippetsDirectory: root,
            policy: EventAudioSnippetPolicy(maxSnippetsPerSession: 10, maxFolderSizeBytes: 2_000_000)
        )

        let linkedSnippet = try store.saveSnippet(
            sessionId: UUID(),
            output: makeOutput(startedAt: Date(timeIntervalSince1970: 600)),
            chunks: makeChunks(startedAt: Date(timeIntervalSince1970: 599))
        )
        let orphanSnippet = try store.saveSnippet(
            sessionId: UUID(),
            output: makeOutput(startedAt: Date(timeIntervalSince1970: 610)),
            chunks: makeChunks(startedAt: Date(timeIntervalSince1970: 609))
        )

        let cleanupResult = store.cleanupOrphanSnippets(linkedFileNames: [linkedSnippet.fileName])
        let statsAfterCleanup = store.storageStats(linkedFileNames: [linkedSnippet.fileName])

        #expect(cleanupResult.deletedFileCount == 1)
        #expect(cleanupResult.deletedBytes > 0)
        #expect(cleanupResult.failedFileCount == 0)
        #expect(store.snippetExists(fileName: linkedSnippet.fileName))
        #expect(!store.snippetExists(fileName: orphanSnippet.fileName))
        #expect(statsAfterCleanup.sampleCount == 1)
        #expect(statsAfterCleanup.orphanSampleCount == 0)

        try? FileManager.default.removeItem(at: root)
    }

    @Test
    func statsAndCleanupIgnoreMissingOrMalformedFilesWithoutCrashing() throws {
        let root = makeTemporaryDirectory()
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        let malformedFile = root.appendingPathComponent("malformed_orphan.caf")
        try Data([0, 1, 2, 3]).write(to: malformedFile)
        let store = EventAudioSnippetStore(snippetsDirectory: root)

        let stats = store.storageStats(linkedFileNames: ["missing-linked-sample.caf"])
        let cleanupResult = store.cleanupOrphanSnippets(linkedFileNames: ["missing-linked-sample.caf"])

        #expect(stats.sampleCount == 1)
        #expect(stats.totalBytes == 4)
        #expect(stats.totalDurationSeconds == 0)
        #expect(cleanupResult.deletedFileCount == 1)
        #expect(cleanupResult.failedFileCount == 0)
        #expect(!FileManager.default.fileExists(atPath: malformedFile.path))

        try? FileManager.default.removeItem(at: root)
    }

    #if DEBUG
    @Test
    func debugPreviewStoresShortSessionSampleWithoutEvent() throws {
        let root = makeTemporaryDirectory()
        let store = EventAudioSnippetStore(
            snippetsDirectory: root,
            policy: EventAudioSnippetPolicy(maxSnippetDuration: 1.0, maxFolderSizeBytes: 2_000_000)
        )
        let sessionId = UUID()

        let preview = try store.saveDebugPreview(
            sessionId: sessionId,
            chunks: makeChunks(startedAt: Date(timeIntervalSince1970: 700)),
            createdAt: Date(timeIntervalSince1970: 710)
        )
        let records = store.debugPreviewRecords(sessionId: sessionId)
        let playableRecords = store.debugPlayableRecords(sessionId: sessionId)

        #expect(preview.eventType == .unknown)
        #expect(preview.duration > 0)
        #expect(preview.duration <= 1.0)
        #expect(preview.fileName.hasPrefix("debug-preview_"))
        #expect(store.snippetExists(fileName: preview.fileName))
        #expect(records.count == 1)
        #expect(records[0].fileName == preview.fileName)
        #expect(records[0].belongsToSession(id: sessionId))
        #expect(playableRecords.map(\.fileName).contains(preview.fileName))

        try? FileManager.default.removeItem(at: root)
    }

    @Test
    func debugPlayableRecordsCanListAllLocalSamplesWithoutReportSession() throws {
        let root = makeTemporaryDirectory()
        let store = EventAudioSnippetStore(
            snippetsDirectory: root,
            policy: EventAudioSnippetPolicy(maxSnippetsPerSession: 10, maxFolderSizeBytes: 2_000_000)
        )
        let eventSessionId = UUID()
        let debugSessionId = UUID()

        let eventSnippet = try store.saveSnippet(
            sessionId: eventSessionId,
            output: makeOutput(startedAt: Date(timeIntervalSince1970: 740)),
            chunks: makeChunks(startedAt: Date(timeIntervalSince1970: 739))
        )
        let debugPreview = try store.saveDebugPreview(
            sessionId: debugSessionId,
            chunks: makeChunks(startedAt: Date(timeIntervalSince1970: 750)),
            createdAt: Date(timeIntervalSince1970: 760)
        )

        let allRecords = store.debugPlayableRecords()
        let eventSessionRecords = store.debugPlayableRecords(sessionId: eventSessionId)
        let debugPreviewRecords = store.debugPreviewRecords()

        #expect(Set(allRecords.map(\.fileName)) == Set([eventSnippet.fileName, debugPreview.fileName]))
        #expect(eventSessionRecords.map(\.fileName) == [eventSnippet.fileName])
        #expect(debugPreviewRecords.map(\.fileName).contains(debugPreview.fileName))

        try? FileManager.default.removeItem(at: root)
    }

    @Test
    func debugPreviewRespectsSnippetLimit() throws {
        let root = makeTemporaryDirectory()
        let store = EventAudioSnippetStore(
            snippetsDirectory: root,
            policy: EventAudioSnippetPolicy(maxSnippetsPerSession: 1, maxFolderSizeBytes: 2_000_000)
        )
        let sessionId = UUID()

        _ = try store.saveDebugPreview(
            sessionId: sessionId,
            chunks: makeChunks(startedAt: Date(timeIntervalSince1970: 720))
        )

        #expect(throws: EventAudioSnippetStoreError.snippetLimitReached) {
            try store.saveDebugPreview(
                sessionId: sessionId,
                chunks: makeChunks(startedAt: Date(timeIntervalSince1970: 730))
            )
        }

        try? FileManager.default.removeItem(at: root)
    }
    #endif

    @Test
    func formatsStorageByteCountsForDisplay() {
        #expect(EventAudioStorageStats.formatBytes(0) == "0B")
        #expect(EventAudioStorageStats.formatBytes(845 * 1_024) == "845KB")
        #expect(EventAudioStorageStats.formatBytes(2_579_988) == "2.46MB")
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
