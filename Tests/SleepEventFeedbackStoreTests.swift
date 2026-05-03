import Foundation
import Testing
@testable import SleepSoundCore

@Suite("SleepEventFeedbackStore")
struct SleepEventFeedbackStoreTests {
    @Test
    func savesLoadsAndDeletesFeedbackLocally() throws {
        let fileURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("NightBreathFeedback-\(UUID().uuidString)")
            .appendingPathComponent("feedback.json")
        let store = SleepEventFeedbackStore(fileURL: fileURL)
        let eventId = UUID()
        let sessionId = UUID()
        let feedback = SleepEventFeedback(
            eventId: eventId,
            sessionId: sessionId,
            eventType: .bruxismLike,
            selectedFeedback: .correct,
            createdAt: Date(timeIntervalSince1970: 1_700_000_000),
            note: "unit test",
            hasAudioSample: true,
            audioSampleId: "event.caf"
        )

        try store.save(feedback)

        #expect(FileManager.default.fileExists(atPath: fileURL.path))
        #expect(store.feedback(for: eventId)?.selectedFeedback == .correct)
        #expect(store.feedback(for: eventId)?.sessionId == sessionId)
        #expect(store.feedback(forSession: sessionId).count == 1)
        #expect(store.fetchAll().count == 1)

        try store.deleteFeedback(for: [eventId])

        #expect(store.feedback(for: eventId) == nil)

        try? FileManager.default.removeItem(at: fileURL.deletingLastPathComponent())
    }

    @Test
    func updatesFeedbackForSameEvent() throws {
        let fileURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("NightBreathFeedback-\(UUID().uuidString)")
            .appendingPathComponent("feedback.json")
        let store = SleepEventFeedbackStore(fileURL: fileURL)
        let eventId = UUID()
        let sessionId = UUID()

        try store.save(
            SleepEventFeedback(
                eventId: eventId,
                sessionId: sessionId,
                eventType: .snore,
                selectedFeedback: .correct
            )
        )
        try store.save(
            SleepEventFeedback(
                eventId: eventId,
                sessionId: sessionId,
                eventType: .snore,
                selectedFeedback: .incorrect,
                correctedLabel: .environmentalNoise
            )
        )

        #expect(store.feedbackCount() == 1)
        #expect(store.feedback(for: eventId)?.selectedFeedback == .incorrect)
        #expect(store.feedback(for: eventId)?.correctedLabel == .environmentalNoise)

        try? FileManager.default.removeItem(at: fileURL.deletingLastPathComponent())
    }

    @Test
    func feedbackExportWritesJSONAndCSV() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("NightBreathFeedbackExport-\(UUID().uuidString)")
        let sessionId = UUID()
        let eventId = UUID()
        let event = SleepEvent(
            id: eventId,
            sessionId: sessionId,
            type: .snore,
            startedAt: Date(timeIntervalSince1970: 1_700_000_000),
            endedAt: Date(timeIntervalSince1970: 1_700_000_003),
            confidence: 0.82,
            intensity: 0.7,
            audioSnippetFileName: "event.caf",
            audioSnippetDuration: 3
        )
        let feedback = SleepEventFeedback(
            eventId: eventId,
            sessionId: sessionId,
            eventType: .snore,
            selectedFeedback: .correct,
            hasAudioSample: true,
            audioSampleId: "event.caf"
        )

        let result = try EventFeedbackManifestExporter().export(
            feedbacks: [feedback],
            events: [event],
            outputDirectory: root,
            snippetsDirectory: root.appendingPathComponent("snippets")
        )

        let manifestData = try Data(contentsOf: result.jsonURL)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let manifest = try decoder.decode(EventFeedbackManifest.self, from: manifestData)

        #expect(result.recordCount == 1)
        #expect(FileManager.default.fileExists(atPath: result.csvURL.path))
        #expect(manifest.records.first?.expectedLabels == [.snore])
        #expect(manifest.records.first?.labelConfidence == 1.0)
        #expect(manifest.records.first?.localFilePath.contains("event.caf") == true)

        try? FileManager.default.removeItem(at: root)
    }

    @Test
    func eventWithNoAudioSampleCanStillExportFeedback() throws {
        let sessionId = UUID()
        let eventId = UUID()
        let event = SleepEvent(
            id: eventId,
            sessionId: sessionId,
            type: .snore,
            startedAt: Date(timeIntervalSince1970: 1_700_000_000),
            endedAt: Date(timeIntervalSince1970: 1_700_000_002),
            confidence: 0.7,
            intensity: 0.6
        )
        let feedback = SleepEventFeedback(
            eventId: eventId,
            sessionId: sessionId,
            eventType: .snore,
            selectedFeedback: .incorrect
        )

        let records = EventFeedbackManifestExporter().makeRecords(feedbacks: [feedback], events: [event])

        #expect(records.count == 1)
        #expect(records[0].hasAudioSample == false)
        #expect(records[0].audioSamplePath == nil)
        #expect(records[0].expectedLabels == [.unknown])
        #expect(records[0].negativeLabels == [.snore])
    }

    @Test
    func deleteAllFeedbackClearsStore() throws {
        let fileURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("NightBreathFeedback-\(UUID().uuidString)")
            .appendingPathComponent("feedback.json")
        let store = SleepEventFeedbackStore(fileURL: fileURL)
        try store.save(
            SleepEventFeedback(
                eventId: UUID(),
                sessionId: UUID(),
                eventType: .snore,
                selectedFeedback: .unsure
            )
        )

        try store.deleteAllFeedback()

        #expect(store.feedbackCount() == 0)

        try? FileManager.default.removeItem(at: fileURL.deletingLastPathComponent())
    }

    @Test
    func feedbackSelectionDisplayNamesUseKoreanCopy() {
        #expect(SleepEventFeedbackSelection.correct.displayName == "맞음")
        #expect(SleepEventFeedbackSelection.incorrect.displayName == "아님")
        #expect(SleepEventFeedbackSelection.unsure.displayName == "모르겠음")
    }
}
