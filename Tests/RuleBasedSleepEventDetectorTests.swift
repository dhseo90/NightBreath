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
    func detectsCloseLowMidSnoreLikeImitationWithoutLoweringGlobalThreshold() {
        let configuration = DetectorTuningProfile.balanced.configuration
        let detector = RuleBasedSleepEventDetector(thresholds: configuration.ruleBasedThresholds)

        let rawOutputs = detector.detect(
            features: makeFeatures(
                rms: 0.039,
                energy: 0.00152,
                peak: 0.075,
                zeroCrossingRate: 0.17,
                lowFrequencyEnergyRatio: 0.42,
                midBandEnergy: 0.43,
                highBandEnergy: 0.15,
                spectralCentroid: 1_050,
                estimatedNoiseLevel: 0.030
            )
        )
        let finalOutputs = configuration.smoothingPolicy.apply(to: rawOutputs)

        #expect(rawOutputs.map(\.eventType).contains(.snore))
        #expect(finalOutputs.map(\.eventType).contains(.snore))
    }

    @Test
    func closeLowMidSnoreGuardDoesNotPromoteVoiceLikeMidBandOnlyInput() {
        let configuration = DetectorTuningProfile.balanced.configuration
        let detector = RuleBasedSleepEventDetector(thresholds: configuration.ruleBasedThresholds)

        let output = detector.detect(
            features: makeFeatures(
                rms: 0.039,
                energy: 0.00152,
                peak: 0.075,
                zeroCrossingRate: 0.17,
                lowFrequencyEnergyRatio: 0.30,
                midBandEnergy: 0.55,
                highBandEnergy: 0.15,
                spectralCentroid: 1_250,
                estimatedNoiseLevel: 0.030
            )
        )

        #expect(!output.map(\.eventType).contains(.snore))
    }

    @Test
    func closeLowMidSnoreGuardDoesNotPromoteSteadyRoomHumAtSimilarLevel() {
        let configuration = DetectorTuningProfile.balanced.configuration
        let detector = RuleBasedSleepEventDetector(thresholds: configuration.ruleBasedThresholds)

        let output = detector.detect(
            features: makeFeatures(
                rms: 0.039,
                energy: 0.00152,
                peak: 0.048,
                zeroCrossingRate: 0.08,
                lowFrequencyEnergyRatio: 0.52,
                midBandEnergy: 0.34,
                highBandEnergy: 0.14,
                spectralCentroid: 650,
                estimatedNoiseLevel: 0.039
            )
        )

        #expect(!output.map(\.eventType).contains(.snore))
    }

    @Test
    func sensitiveProfilesKeepDistantSnoreLikeCandidateAfterSmoothing() {
        let profiles: [DetectorTuningProfile] = [.verySensitive, .sensitive, .balanced]
        let features = makeFeatures(
            rms: 0.034,
            energy: 0.00116,
            peak: 0.070,
            zeroCrossingRate: 0.075,
            lowFrequencyEnergyRatio: 0.76,
            midBandEnergy: 0.18,
            highBandEnergy: 0.06,
            spectralCentroid: 280,
            estimatedNoiseLevel: 0.018
        )

        for profile in profiles {
            let configuration = profile.configuration
            let rawOutputs = RuleBasedSleepEventDetector(
                thresholds: configuration.ruleBasedThresholds
            ).detect(features: features)
            let finalOutputs = configuration.smoothingPolicy.apply(to: rawOutputs)

            #expect(rawOutputs.map(\.eventType).contains(.snore), "\(profile.rawValue) should keep distant snore-like raw candidates.")
            #expect(finalOutputs.map(\.eventType).contains(.snore), "\(profile.rawValue) should keep distant snore-like events after smoothing.")
        }
    }

    @Test
    func conservativeProfilesDoNotOverReportVeryFaintDistantSnoreLikeInput() {
        let profiles: [DetectorTuningProfile] = [.conservative, .veryConservative]
        let features = makeFeatures(
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

        for profile in profiles {
            let configuration = profile.configuration
            let rawOutputs = RuleBasedSleepEventDetector(
                thresholds: configuration.ruleBasedThresholds
            ).detect(features: features)
            let finalOutputs = configuration.smoothingPolicy.apply(to: rawOutputs)

            #expect(!rawOutputs.map(\.eventType).contains(.snore), "\(profile.rawValue) should require a stronger snore-like signal.")
            #expect(!finalOutputs.map(\.eventType).contains(.snore), "\(profile.rawValue) should not smooth a very faint signal into snore.")
        }
    }

    @Test
    func balancedProfileKeepsDistantLowInputSnoreLikeNearMissAsRawOnly() {
        let configuration = DetectorTuningProfile.balanced.configuration
        let detector = RuleBasedSleepEventDetector(thresholds: configuration.ruleBasedThresholds)

        let rawOutputs = detector.detect(
            features: makeFeatures(
                rms: 0.020,
                energy: 0.00040,
                peak: 0.042,
                zeroCrossingRate: 0.06,
                lowFrequencyEnergyRatio: 0.78,
                midBandEnergy: 0.14,
                highBandEnergy: 0.05,
                spectralCentroid: 260,
                estimatedNoiseLevel: 0.014
            )
        )
        let finalOutputs = configuration.smoothingPolicy.apply(to: rawOutputs)
        let snoreOutput = rawOutputs.first { $0.eventType == .snore }

        #expect(snoreOutput != nil)
        #expect(snoreOutput?.confidence ?? 1 < configuration.minimumConfidence)
        #expect(snoreOutput?.debugReason?.contains("raw near-miss") == true)
        #expect(!finalOutputs.map(\.eventType).contains(.snore))
    }

    @Test
    func nearMissGuardDoesNotPromoteSteadyLowFrequencyRoomTone() {
        let configuration = DetectorTuningProfile.balanced.configuration
        let detector = RuleBasedSleepEventDetector(thresholds: configuration.ruleBasedThresholds)

        let output = detector.detect(
            features: makeFeatures(
                rms: 0.020,
                energy: 0.00040,
                peak: 0.028,
                zeroCrossingRate: 0.06,
                lowFrequencyEnergyRatio: 0.78,
                midBandEnergy: 0.14,
                highBandEnergy: 0.05,
                spectralCentroid: 260,
                estimatedNoiseLevel: 0.020
            )
        )

        #expect(!output.map(\.eventType).contains(.snore))
    }

    @Test
    func steadyMechanicalLowBandNoiseDoesNotBecomeSnoreRawCandidate() {
        let configuration = DetectorTuningProfile.balanced.configuration
        let detector = RuleBasedSleepEventDetector(thresholds: configuration.ruleBasedThresholds)

        let output = detector.detect(
            features: makeFeatures(
                rms: 0.070,
                energy: 0.00490,
                peak: 0.085,
                zeroCrossingRate: 0.07,
                lowFrequencyEnergyRatio: 0.78,
                midBandEnergy: 0.14,
                highBandEnergy: 0.08,
                spectralCentroid: 320,
                estimatedNoiseLevel: 0.068
            )
        )

        #expect(!output.map(\.eventType).contains(.snore))
    }

    @Test
    func snoreLikePeakShapeStillBecomesSnoreWhenLowBandDominant() {
        let configuration = DetectorTuningProfile.balanced.configuration
        let detector = RuleBasedSleepEventDetector(thresholds: configuration.ruleBasedThresholds)

        let output = detector.detect(
            features: makeFeatures(
                rms: 0.070,
                energy: 0.00490,
                peak: 0.160,
                zeroCrossingRate: 0.07,
                lowFrequencyEnergyRatio: 0.78,
                midBandEnergy: 0.14,
                highBandEnergy: 0.08,
                spectralCentroid: 320,
                estimatedNoiseLevel: 0.068
            )
        )

        #expect(output.map(\.eventType).contains(.snore))
    }

    @Test
    func allSelectableProfilesKeepCommonNegativeSignalsOutOfSnore() {
        let negativeFixtures = [
            makeFeatures(
                rms: 0.012,
                energy: 0.00014,
                peak: 0.018,
                zeroCrossingRate: 0.05,
                lowFrequencyEnergyRatio: 0.65,
                midBandEnergy: 0.16,
                highBandEnergy: 0.05,
                spectralCentroid: 230,
                estimatedNoiseLevel: 0.011
            ),
            makeFeatures(
                rms: 0.028,
                energy: 0.00078,
                peak: 0.036,
                zeroCrossingRate: 0.05,
                lowFrequencyEnergyRatio: 0.82,
                midBandEnergy: 0.12,
                highBandEnergy: 0.04,
                spectralCentroid: 220,
                estimatedNoiseLevel: 0.028
            ),
            makeFeatures(
                rms: 0.040,
                energy: 0.0016,
                peak: 0.150,
                zeroCrossingRate: 0.52,
                lowFrequencyEnergyRatio: 0.22,
                midBandEnergy: 0.20,
                highBandEnergy: 0.46,
                spectralCentroid: 2_200,
                estimatedNoiseLevel: 0.018
            ),
            makeFeatures(
                rms: 0.050,
                energy: 0.0025,
                peak: 0.100,
                zeroCrossingRate: 0.44,
                lowFrequencyEnergyRatio: 0.44,
                midBandEnergy: 0.30,
                highBandEnergy: 0.26,
                spectralCentroid: 1_800,
                estimatedNoiseLevel: 0.040
            )
        ]

        for profile in DetectorTuningProfile.debugSelectableProfiles {
            let configuration = profile.configuration
            let detector = RuleBasedSleepEventDetector(thresholds: configuration.ruleBasedThresholds)

            for features in negativeFixtures {
                let rawOutputs = detector.detect(features: features)
                let finalOutputs = configuration.smoothingPolicy.apply(to: rawOutputs)

                #expect(!rawOutputs.map(\.eventType).contains(.snore), "\(profile.rawValue) should not create raw snore from common negative signals.")
                #expect(!finalOutputs.map(\.eventType).contains(.snore), "\(profile.rawValue) should not create final snore from common negative signals.")
            }
        }
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
