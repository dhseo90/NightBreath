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
        let feedback = SleepEventFeedback(
            eventId: eventId,
            selectedFeedback: .soundsLikeBruxism,
            createdAt: Date(timeIntervalSince1970: 1_700_000_000),
            note: "unit test"
        )

        try store.save(feedback)

        #expect(FileManager.default.fileExists(atPath: fileURL.path))
        #expect(store.feedback(for: eventId)?.selectedFeedback == .soundsLikeBruxism)
        #expect(store.fetchAll().count == 1)

        try store.deleteFeedback(for: [eventId])

        #expect(store.feedback(for: eventId) == nil)

        try? FileManager.default.removeItem(at: fileURL.deletingLastPathComponent())
    }

    @Test
    func feedbackSelectionDisplayNamesUseKoreanCopy() {
        #expect(SleepEventFeedbackSelection.soundsLikeBruxism.displayName == "이갈이 소리 같음")
        #expect(SleepEventFeedbackSelection.notBruxism.displayName == "아님")
        #expect(SleepEventFeedbackSelection.unsure.displayName == "모르겠음")
    }
}
