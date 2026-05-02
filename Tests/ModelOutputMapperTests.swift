import Foundation
import Testing
@testable import SleepSoundCore

@Suite("ModelOutputMapper")
struct ModelOutputMapperTests {
    @Test
    func knownLabelsMapToSleepEventTypes() {
        let mapper = ModelOutputMapper()
        let expectations: [(String, SleepEventType)] = [
            ("snore", .snore),
            ("bruxism_like", .bruxismLike),
            ("breathing_pause_suspected", .breathingPauseSuspected),
            ("gasp_like", .gaspLike),
            ("cough_like", .coughLike),
            ("sleep_talk_like", .sleepTalkLike),
            ("movement_like", .movementLike),
            ("environmental_noise", .environmentalNoise),
            ("awakening_suspected", .awakeningSuspected),
            ("unknown", .unknown)
        ]

        for (label, eventType) in expectations {
            #expect(mapper.eventType(for: label) == eventType)
        }
    }

    @Test
    func unknownLabelMapsToUnknown() {
        #expect(ModelOutputMapper().eventType(for: "unexpected_label") == .unknown)
    }

    @Test
    func confidenceIsClampedWhenMakingDetectorOutput() {
        let mapper = ModelOutputMapper()
        let features = makeFeatures()

        let highConfidence = mapper.makeOutput(
            label: "snore",
            confidence: 2,
            features: features
        )
        let lowConfidence = mapper.makeOutput(
            label: "snore",
            confidence: -1,
            features: features
        )

        #expect(highConfidence.confidence == 1)
        #expect(lowConfidence.confidence == 0)
    }

    private func makeFeatures() -> AudioFeatures {
        AudioFeatures(
            startedAt: Date(timeIntervalSince1970: 10),
            duration: 1,
            rms: 0.1,
            peak: 0.2,
            zeroCrossingRate: 0.1,
            lowFrequencyEnergyRatio: 0.5
        )
    }
}
