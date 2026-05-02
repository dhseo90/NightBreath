import Foundation
import Testing
@testable import SleepSoundCore

@Suite("RuleBasedSleepEventDetector")
struct RuleBasedSleepEventDetectorTests {
    @Test
    func detectsSnoreLikeLowFrequencyCandidate() {
        let output = RuleBasedSleepEventDetector().detect(
            features: makeFeatures(
                rms: 0.08,
                peak: 0.18,
                zeroCrossingRate: 0.08,
                lowFrequencyEnergyRatio: 0.82
            )
        )

        #expect(output.map(\.eventType).contains(.snore))
        #expect(output.allSatisfy { $0.confidence >= 0 && $0.confidence <= 1 })
    }

    @Test
    func detectsLongSilenceAsSuspectedBreathingPauseCandidate() {
        let output = RuleBasedSleepEventDetector().detect(
            features: makeFeatures(
                duration: 12,
                rms: 0.002,
                peak: 0.004,
                zeroCrossingRate: 0,
                lowFrequencyEnergyRatio: 0,
                isLikelySilence: true
            )
        )

        #expect(output.count == 1)
        #expect(output.first?.eventType == .breathingPauseSuspected)
        #expect(output.first?.debugReason?.contains("placeholder") == true)
    }

    @Test
    func ignoresShortSilenceCandidate() {
        let output = RuleBasedSleepEventDetector().detect(
            features: makeFeatures(
                duration: 1,
                rms: 0.002,
                peak: 0.004,
                zeroCrossingRate: 0,
                lowFrequencyEnergyRatio: 0,
                isLikelySilence: true
            )
        )

        #expect(output.isEmpty)
    }

    @Test
    func detectsEnvironmentalNoiseAndPossibleAwakeningCandidate() {
        let output = RuleBasedSleepEventDetector().detect(
            features: makeFeatures(
                rms: 0.38,
                peak: 0.95,
                zeroCrossingRate: 0.45,
                lowFrequencyEnergyRatio: 0.2
            )
        )

        #expect(output.map(\.eventType).contains(.environmentalNoise))
        #expect(output.map(\.eventType).contains(.awakeningSuspected))
    }

    @Test
    func detectsBruxismLikePlaceholderCandidate() {
        let output = RuleBasedSleepEventDetector().detect(
            features: makeFeatures(
                rms: 0.06,
                peak: 0.28,
                zeroCrossingRate: 0.62,
                lowFrequencyEnergyRatio: 0.25
            )
        )

        #expect(output.map(\.eventType).contains(.bruxismLike))
    }

    @Test
    func adjustableNoiseThresholdAffectsDetectorOutput() {
        let features = makeFeatures(
            rms: 0.20,
            peak: 0.22,
            zeroCrossingRate: 0.10,
            lowFrequencyEnergyRatio: 0.20
        )

        let defaultOutput = RuleBasedSleepEventDetector().detect(features: features)
        let tunedOutput = RuleBasedSleepEventDetector(
            thresholds: RuleBasedDetectionThresholds(noiseRMS: 0.15)
        ).detect(features: features)

        #expect(!defaultOutput.map(\.eventType).contains(.environmentalNoise))
        #expect(tunedOutput.map(\.eventType).contains(.environmentalNoise))
    }

    private func makeFeatures(
        duration: TimeInterval = 1,
        rms: Double,
        peak: Double,
        zeroCrossingRate: Double,
        lowFrequencyEnergyRatio: Double,
        isLikelySilence: Bool? = nil
    ) -> AudioFeatures {
        AudioFeatures(
            startedAt: Date(timeIntervalSince1970: 100),
            duration: duration,
            rms: rms,
            peak: peak,
            zeroCrossingRate: zeroCrossingRate,
            lowFrequencyEnergyRatio: lowFrequencyEnergyRatio,
            isLikelySilence: isLikelySilence
        )
    }
}
