import Foundation
import Testing

@testable import SleepSoundCore

@Suite("Event Audio Storage Regression")
struct EventAudioStorageRegressionTests {
  @Test
  func eventAudioSampleStorageDefaultsToOff() {
    let suiteName = "NightBreath.EventAudioStorageRegression.\(UUID().uuidString)"
    let defaults = try! #require(UserDefaults(suiteName: suiteName))
    defer { defaults.removePersistentDomain(forName: suiteName) }

    let settings = UserSettings(userDefaults: defaults)

    #expect(settings.isEventAudioSampleStorageEnabled == false)
  }

  @Test
  func optInRulesPreventSampleStorageWhenOff() throws {
    let root = makeTemporaryDirectory()
    let store = EventAudioSnippetStore(snippetsDirectory: root)
    let output = makeOutput(startedAt: Date(timeIntervalSince1970: 1_000))

    let shouldStore = EventAudioSampleStorageRules.shouldAttemptStorage(
      isEnabled: false,
      eventType: output.eventType,
      duration: output.duration,
      confidence: output.confidence
    )

    if shouldStore {
      _ = try store.saveSnippet(
        sessionId: UUID(),
        output: output,
        chunks: makeChunks(startedAt: output.startedAt.addingTimeInterval(-1))
      )
    }

    #expect(!shouldStore)
    #expect(store.storageStats(linkedFileNames: []).sampleCount == 0)
    #expect(store.folderSizeBytes() == 0)

    try? FileManager.default.removeItem(at: root)
  }

  @Test
  func optInRulesAllowShortEventSampleWhenOn() throws {
    let root = makeTemporaryDirectory()
    let store = EventAudioSnippetStore(
      snippetsDirectory: root,
      policy: EventAudioSnippetPolicy(
        preEventSeconds: 0.2,
        postEventSeconds: 0.2,
        maxSnippetDuration: 1,
        maxSnippetsPerSession: 10,
        maxFolderSizeBytes: 2_000_000,
        maxSnippetAge: 60
      )
    )
    let output = makeOutput(startedAt: Date(timeIntervalSince1970: 2_000))

    let shouldStore = EventAudioSampleStorageRules.shouldAttemptStorage(
      isEnabled: true,
      eventType: output.eventType,
      duration: output.duration,
      confidence: output.confidence
    )
    let snippet = try store.saveSnippet(
      sessionId: UUID(),
      output: output,
      chunks: makeChunks(startedAt: output.startedAt.addingTimeInterval(-1))
    )

    #expect(shouldStore)
    #expect(snippet.duration <= 1)
    #expect(store.snippetExists(fileName: snippet.fileName))
    #expect(store.storageStats(linkedFileNames: [snippet.fileName]).sampleCount == 1)

    try store.deleteAllSnippets()
    #expect(store.storageStats(linkedFileNames: [snippet.fileName]).sampleCount == 0)
    #expect(store.folderSizeBytes() == 0)

    try? FileManager.default.removeItem(at: root)
  }

  @Test
  func orphanCleanupKeepsLinkedSamplesAndToleratesMissingDeletes() throws {
    let root = makeTemporaryDirectory()
    let store = EventAudioSnippetStore(
      snippetsDirectory: root,
      policy: EventAudioSnippetPolicy(maxSnippetsPerSession: 10, maxFolderSizeBytes: 2_000_000)
    )
    let linked = try store.saveSnippet(
      sessionId: UUID(),
      output: makeOutput(startedAt: Date(timeIntervalSince1970: 3_000)),
      chunks: makeChunks(startedAt: Date(timeIntervalSince1970: 2_999))
    )
    let orphan = try store.saveSnippet(
      sessionId: UUID(),
      output: makeOutput(startedAt: Date(timeIntervalSince1970: 3_010)),
      chunks: makeChunks(startedAt: Date(timeIntervalSince1970: 3_009))
    )

    let before = store.storageStats(linkedFileNames: [linked.fileName])
    let cleanup = store.cleanupOrphanSnippets(linkedFileNames: [linked.fileName])
    try store.deleteSnippet(fileName: "already-missing.caf")
    let after = store.storageStats(linkedFileNames: [linked.fileName])

    #expect(before.sampleCount == 2)
    #expect(before.orphanSampleCount == 1)
    #expect(cleanup.deletedFileCount == 1)
    #expect(cleanup.deletedBytes > 0)
    #expect(cleanup.failedFileCount == 0)
    #expect(store.snippetExists(fileName: linked.fileName))
    #expect(!store.snippetExists(fileName: orphan.fileName))
    #expect(after.sampleCount == 1)
    #expect(after.orphanSampleCount == 0)

    try? FileManager.default.removeItem(at: root)
  }

  @Test
  func reportCanBeGeneratedWithoutAnyAudioSnippetFiles() {
    let startedAt = Date(timeIntervalSince1970: 4_000)
    let session = SleepSession(
      startedAt: startedAt,
      endedAt: startedAt.addingTimeInterval(600),
      measurementDuration: 600,
      estimatedSleepDuration: 580
    )
    let event = SleepEvent(
      sessionId: session.id,
      type: .snore,
      startedAt: startedAt.addingTimeInterval(30),
      endedAt: startedAt.addingTimeInterval(60),
      confidence: 0.8,
      intensity: 0.6,
      audioSnippetFileName: nil,
      audioSnippetDuration: nil
    )

    let report = SleepScoreCalculator().makeReport(session: session, events: [event])

    #expect(report.snoreTotalSeconds == 30)
    #expect(report.savedAudioDuration == 0)
    #expect(report.sleepSoundScore >= 0)
    #expect(report.sleepSoundScore <= 100)
  }

  private func makeOutput(startedAt: Date) -> DetectorOutput {
    DetectorOutput(
      eventType: .coughLike,
      startedAt: startedAt,
      endedAt: startedAt.addingTimeInterval(0.4),
      confidence: 0.75,
      intensity: 0.8,
      debugReason: "regression event"
    )
  }

  private func makeChunks(startedAt: Date) -> [AudioChunk] {
    SyntheticAudioSource.makeChunks(
      pattern: .coughLikeBurst,
      duration: 3,
      sampleRate: 16_000,
      chunkDuration: 0.5,
      startedAt: startedAt
    )
  }

  private func makeTemporaryDirectory() -> URL {
    FileManager.default.temporaryDirectory
      .appendingPathComponent("NightBreathEventAudioStorageRegression-\(UUID().uuidString)", isDirectory: true)
  }
}
