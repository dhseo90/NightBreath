import Foundation
import Testing
@testable import SleepSoundCore

@Suite("DailyHealthSnapshot")
struct DailyHealthSnapshotTests {
    @Test
    func snapshotStoresLinkedDailyRhythmIDsAndClampsCompleteness() {
        let sampleID = UUID(uuidString: "30000000-0000-0000-0000-000000000001")!
        let duplicateID = sampleID
        let snapshot = DailyHealthSnapshot(
            date: referenceDate,
            sleepReportId: UUID(uuidString: "30000000-0000-0000-0000-000000000002")!,
            morningCheckInId: UUID(uuidString: "30000000-0000-0000-0000-000000000003")!,
            eveningCheckInId: UUID(uuidString: "30000000-0000-0000-0000-000000000004")!,
            healthMetricSampleIds: [sampleID, duplicateID],
            lifestyleTags: [.caffeine, .exercise, .caffeine],
            dataCompletenessScore: 1.2,
            createdAt: referenceDate
        )

        #expect(snapshot.healthMetricSampleIds == [sampleID])
        #expect(snapshot.lifestyleTags == [.caffeine, .exercise])
        #expect(snapshot.dataCompletenessScore == 1)
        #expect(snapshot.dataQuality == .excellent)
        #expect(snapshot.updatedAt == referenceDate)
    }

    @Test
    func snapshotRoundTripsThroughJSON() throws {
        let snapshot = MockDailyRhythmData.sampleSnapshot

        let encoded = try JSONEncoder().encode(snapshot)
        let decoded = try JSONDecoder().decode(DailyHealthSnapshot.self, from: encoded)

        #expect(decoded == snapshot)
    }

    @Test
    func mockSnapshotCombinesSleepCheckInHealthMetricsAndLifestyleTags() {
        let snapshot = MockDailyRhythmData.sampleSnapshot

        #expect(snapshot.sleepReportId != nil)
        #expect(snapshot.morningCheckInId != nil)
        #expect(snapshot.eveningCheckInId != nil)
        #expect(snapshot.healthMetricSampleIds.count == 3)
        #expect(snapshot.lifestyleTags.contains(.caffeine))
        #expect(snapshot.lifestyleTags.contains(.exercise))
        #expect(snapshot.dataQuality == .good)
    }

    private var referenceDate: Date {
        Date(timeIntervalSince1970: 1_777_680_000)
    }
}
