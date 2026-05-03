import Foundation
import Testing
@testable import SleepSoundCore

@Suite("LifestyleTag")
struct LifestyleTagTests {
    @Test
    func includesExpectedDailyRhythmTags() {
        let expected: Set<LifestyleTag> = [
            .caffeine,
            .alcohol,
            .lateMeal,
            .stress,
            .nap,
            .exercise,
            .illness,
            .travel,
            .lateScreenUse,
        ]

        #expect(Set(LifestyleTag.allCases) == expected)
    }

    @Test
    func tagsAreCodableAndHaveDisplayNames() throws {
        let tags: [LifestyleTag] = [.caffeine, .exercise, .lateScreenUse]

        let encoded = try JSONEncoder().encode(tags)
        let decoded = try JSONDecoder().decode([LifestyleTag].self, from: encoded)

        #expect(decoded == tags)
        #expect(tags.allSatisfy { !$0.displayName.isEmpty })
        #expect(LifestyleTag.exercise.id == "exercise")
    }
}
