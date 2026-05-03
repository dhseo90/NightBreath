import Foundation
import Testing
@testable import SleepSoundCore

@Suite("DailyDataQuality")
struct DailyDataQualityTests {
    @Test
    func qualityBandsUseCompletenessScore() {
        #expect(DailyDataQuality.quality(for: 0.95) == .excellent)
        #expect(DailyDataQuality.quality(for: 0.75) == .good)
        #expect(DailyDataQuality.quality(for: 0.55) == .limited)
        #expect(DailyDataQuality.quality(for: 0.3) == .poor)
        #expect(DailyDataQuality.quality(for: 0.1) == .insufficient)
    }

    @Test
    func completenessIsClampedToRatioRange() {
        #expect(DailyDataQuality.clampedCompleteness(-1) == 0)
        #expect(DailyDataQuality.clampedCompleteness(1.4) == 1)
        #expect(DailyDataQuality.clampedCompleteness(.nan) == 0)
    }

    @Test
    func casesAreCodableAndIdentifiable() throws {
        let encoded = try JSONEncoder().encode(DailyDataQuality.allCases)
        let decoded = try JSONDecoder().decode([DailyDataQuality].self, from: encoded)

        #expect(decoded == DailyDataQuality.allCases)
        #expect(DailyDataQuality.good.id == DailyDataQuality.good.rawValue)
        #expect(!DailyDataQuality.excellent.displayName.isEmpty)
    }
}
