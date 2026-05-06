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
    func detectsRealisticLowLevelSnoreLikeCandidateWithBalancedThreshold() {
        let detector = RuleBasedSleepEventDetector(
            thresholds: DetectorTuningProfile.balanced.configuration.ruleBasedThresholds
        )

        let output = detector.detect(
            features: makeFeatures(
                rms: 0.046,
                peak: 0.11,
                zeroCrossingRate: 0.08,
                lowFrequencyEnergyRatio: 0.72,
                midBandEnergy: 0.20,
                highBandEnergy: 0.08,
                spectralCentroid: 260
            )
        )

        #expect(output.map(\.eventType).contains(.snore))
    }

    @Test
    func detectsDistantLowLevelSnoreLikeCandidateUsingRelativeEnergyAndLowBandGuard() {
        let detector = RuleBasedSleepEventDetector(
            thresholds: DetectorTuningProfile.balanced.configuration.ruleBasedThresholds
        )

        let output = detector.detect(
            features: makeFeatures(
                rms: 0.030,
                energy: 0.0009,
                peak: 0.050,
                zeroCrossingRate: 0.08,
                lowFrequencyEnergyRatio: 0.76,
                midBandEnergy: 0.18,
                highBandEnergy: 0.06,
                spectralCentroid: 280,
                estimatedNoiseLevel: 0.018
            )
        )

        let snoreOutput = output.first { $0.eventType == .snore }
        #expect(snoreOutput != nil)
        #expect(snoreOutput?.confidence ?? 0 >= DetectorTuningProfile.balanced.configuration.minimumConfidence)
        #expect(snoreOutput?.debugReason?.contains("저진폭") == true)
    }

    @Test
    func lowFrequencyRoomHumAtNoiseFloorDoesNotBecomeSnore() {
        let detector = RuleBasedSleepEventDetector(
            thresholds: DetectorTuningProfile.balanced.configuration.ruleBasedThresholds
        )

        let output = detector.detect(
            features: makeFeatures(
                rms: 0.030,
                energy: 0.0009,
                peak: 0.045,
                zeroCrossingRate: 0.07,
                lowFrequencyEnergyRatio: 0.78,
                midBandEnergy: 0.16,
                highBandEnergy: 0.06,
                spectralCentroid: 240,
                estimatedNoiseLevel: 0.030
            )
        )

        #expect(!output.map(\.eventType).contains(.snore))
    }

    @Test
    func quietLowLevelNoiseDoesNotBecomeSnore() {
        let detector = RuleBasedSleepEventDetector(
            thresholds: DetectorTuningProfile.balanced.configuration.ruleBasedThresholds
        )

        let output = detector.detect(
            features: makeFeatures(
                rms: 0.046,
                peak: 0.08,
                zeroCrossingRate: 0.36,
                lowFrequencyEnergyRatio: 0.40,
                midBandEnergy: 0.42,
                highBandEnergy: 0.18,
                spectralCentroid: 1_100
            )
        )

        #expect(!output.map(\.eventType).contains(.snore))
    }

    @Test
    func lowLevelBroadbandNoiseDoesNotBecomeSnore() {
        let detector = RuleBasedSleepEventDetector(
            thresholds: DetectorTuningProfile.balanced.configuration.ruleBasedThresholds
        )

        let output = detector.detect(
            features: makeFeatures(
                rms: 0.046,
                peak: 0.12,
                zeroCrossingRate: 0.38,
                lowFrequencyEnergyRatio: 0.62,
                midBandEnergy: 0.10,
                highBandEnergy: 0.28,
                spectralCentroid: 2_000
            )
        )

        #expect(!output.map(\.eventType).contains(.snore))
    }

    @Test
    func longSilenceDoesNotBecomeSuspectedBreathingPauseCandidate() {
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

        #expect(output.isEmpty)
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
                lowFrequencyEnergyRatio: 0.2,
                midBandEnergy: 0.35,
                highBandEnergy: 0.45,
                spectralCentroid: 3_000
            )
        )

        #expect(output.map(\.eventType).contains(.environmentalNoise))
        #expect(output.map(\.eventType).contains(.awakeningSuspected))
    }

    @Test
    func detectsCoughLikeShortBurstCandidate() {
        let output = RuleBasedSleepEventDetector().detect(
            features: makeFeatures(
                duration: 0.7,
                rms: 0.09,
                peak: 0.44,
                zeroCrossingRate: 0.18,
                lowFrequencyEnergyRatio: 0.24,
                midBandEnergy: 0.48,
                highBandEnergy: 0.28,
                spectralCentroid: 1_800
            )
        )

        #expect(output.map(\.eventType).contains(.coughLike))
        #expect(output.first { $0.eventType == .coughLike }?.debugReason?.contains("placeholder") == true)
    }

    @Test
    func detectsGaspLikeRecoveryBreathCandidate() {
        let output = RuleBasedSleepEventDetector().detect(
            features: makeFeatures(
                duration: 0.9,
                rms: 0.045,
                peak: 0.20,
                zeroCrossingRate: 0.13,
                lowFrequencyEnergyRatio: 0.30,
                midBandEnergy: 0.52,
                highBandEnergy: 0.18,
                spectralCentroid: 1_200
            )
        )

        #expect(output.map(\.eventType).contains(.gaspLike))
        #expect(output.first { $0.eventType == .gaspLike }?.debugReason?.contains("회복 호흡") == true)
    }

    @Test
    func detectsBruxismLikePlaceholderCandidate() {
        let output = RuleBasedSleepEventDetector().detect(
            features: makeFeatures(
                duration: 0.8,
                rms: 0.055,
                peak: 0.24,
                zeroCrossingRate: 0.58,
                lowFrequencyEnergyRatio: 0.22,
                midBandEnergy: 0.18,
                highBandEnergy: 0.54,
                spectralCentroid: 2_200
            )
        )

        #expect(output.map(\.eventType).contains(.bruxismLike))
        #expect(output.first { $0.eventType == .bruxismLike }?.debugReason?.contains("사용자 확인") == true)
        #expect(output.first { $0.eventType == .bruxismLike }?.debugReason?.contains("임시 rule-based") == true)
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
        energy: Double? = nil,
        peak: Double,
        zeroCrossingRate: Double,
        lowFrequencyEnergyRatio: Double,
        midBandEnergy: Double? = nil,
        highBandEnergy: Double? = nil,
        spectralCentroid: Double? = nil,
        estimatedNoiseLevel: Double? = nil,
        isLikelySilence: Bool? = nil
    ) -> AudioFeatures {
        AudioFeatures(
            startedAt: Date(timeIntervalSince1970: 100),
            duration: duration,
            rms: rms,
            energy: energy,
            peak: peak,
            zeroCrossingRate: zeroCrossingRate,
            lowFrequencyEnergyRatio: lowFrequencyEnergyRatio,
            spectralCentroid: spectralCentroid,
            midBandEnergy: midBandEnergy,
            highBandEnergy: highBandEnergy,
            estimatedNoiseLevel: estimatedNoiseLevel,
            isLikelySilence: isLikelySilence
        )
    }
}
