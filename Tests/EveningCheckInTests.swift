import Foundation
import Testing
@testable import SleepSoundCore

@Suite("EveningCheckIn")
struct EveningCheckInTests {
    @Test
    func scoresAreClampedAndUpdatedAtDefaultsToCreatedAt() {
        let createdAt = Date(timeIntervalSince1970: 1_777_680_000)
        let checkIn = EveningCheckIn(
            date: createdAt,
            fatigueScore: 8,
            stressScore: -2,
            moodScore: 9,
            createdAt: createdAt
        )

        #expect(checkIn.fatigueScore == 5)
        #expect(checkIn.stressScore == 1)
        #expect(checkIn.moodScore == 5)
        #expect(checkIn.updatedAt == createdAt)
    }

    @Test
    func lifestyleTagsReflectBooleanFields() {
        let checkIn = EveningCheckIn(
            date: Date(timeIntervalSince1970: 1_777_680_000),
            caffeine: true,
            alcohol: true,
            lateMeal: false,
            exercise: true,
            nap: true
        )

        #expect(checkIn.lifestyleTags == [.caffeine, .alcohol, .exercise, .nap])
    }

    @Test
    func eveningCheckInRoundTripsThroughJSON() throws {
        let checkIn = EveningCheckIn(
            id: UUID(uuidString: "20000000-0000-0000-0000-000000000001")!,
            date: Date(timeIntervalSince1970: 1_777_680_000),
            fatigueScore: 2,
            stressScore: 4,
            moodScore: nil,
            caffeine: false,
            alcohol: false,
            lateMeal: true,
            exercise: false,
            nap: false,
            memo: "차분한 저녁",
            createdAt: Date(timeIntervalSince1970: 1_777_680_100),
            updatedAt: Date(timeIntervalSince1970: 1_777_680_200)
        )

        let encoded = try JSONEncoder().encode(checkIn)
        let decoded = try JSONDecoder().decode(EveningCheckIn.self, from: encoded)

        #expect(decoded == checkIn)
    }
}
