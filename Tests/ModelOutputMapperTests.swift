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
            ("1", .snore),
            ("non_snore", .unknown),
            ("0", .unknown),
            ("silence", .unknown),
            ("bruxism_like", .bruxismLike),
            ("breathing_pause_suspected", .breathingPauseSuspected),
            ("gasp_like", .gaspLike),
            ("cough_like", .coughLike),
            ("sleep_talk_like", .sleepTalkLike),
            ("movement_like", .movementLike),
            ("environmental_noise", .environmentalNoise),
            ("noise", .environmentalNoise),
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
    func labelsAreNormalizedBeforeMapping() {
        let mapper = ModelOutputMapper()

        #expect(mapper.eventType(for: " SNORE ") == .snore)
        #expect(mapper.eventType(for: "non-snore") == .unknown)
        #expect(mapper.eventType(for: "environmental noise") == .environmentalNoise)
        #expect(mapper.eventType(for: "coughLike") == .coughLike)
        #expect(mapper.eventType(for: "cough") == .coughLike)
        #expect(mapper.eventType(for: "gaspLike") == .gaspLike)
        #expect(mapper.eventType(for: "gasp") == .gaspLike)
        #expect(mapper.eventType(for: "environmentalNoise") == .environmentalNoise)
        #expect(mapper.eventType(for: "bruxismLike") == .bruxismLike)
        #expect(mapper.eventType(for: "bruxism") == .bruxismLike)
        #expect(mapper.eventType(for: "sleepTalk") == .sleepTalkLike)
        #expect(mapper.eventType(for: "movement") == .movementLike)
    }

    @Test
    func multiclassLabelsAreDocumentedForCoreMLConfig() {
        #expect(ModelOutputMapper.multiclassEventLabels == [
            "snore",
            "bruxismLike",
            "gaspLike",
            "coughLike",
            "movementLike",
            "environmentalNoise",
            "sleepTalkLike",
            "unknown",
            "silence"
        ])
        #expect(CoreMLDetectorConfiguration.multiclassDefault.modelName == "SleepEventClassifier")
        #expect(CoreMLDetectorConfiguration.multiclassDefault.labels == ModelOutputMapper.multiclassEventLabels)
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
