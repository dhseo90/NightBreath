import Testing
@testable import SleepSoundCore

@Suite("DetectorThresholdConfiguration")
struct DetectorThresholdConfigurationTests {
    @Test
    func balancedProfileMatchesCurrentRuleBasedDefaults() {
        let configuration = DetectorTuningProfile.balanced.configuration

        #expect(configuration.silenceRmsThreshold == RuleBasedDetectionThresholds.default.silenceRMS)
        #expect(configuration.snoreRmsThreshold == RuleBasedDetectionThresholds.default.snoreRMS)
        #expect(configuration.environmentalNoiseThreshold == RuleBasedDetectionThresholds.default.noiseRMS)
        #expect(configuration.minimumConfidence == DetectionSmoothingPolicy().confidenceThreshold)
        #expect(configuration.minimumEventDuration == DetectionSmoothingPolicy().minimumEventDuration)
    }

    @Test
    func valuesAreClampedToSafeRanges() {
        let configuration = DetectorThresholdConfiguration(
            profile: .customDebug,
            silenceRmsThreshold: -1,
            snoreRmsThreshold: 2,
            snoreEnergyThreshold: .infinity,
            coughEnergyThreshold: .nan,
            gaspEnergyThreshold: -0.5,
            bruxismHighBandThreshold: 1.5,
            environmentalNoiseThreshold: -0.2,
            suspectedPauseMinimumDuration: -10,
            minimumConfidence: 3,
            minimumEventDuration: -1,
            mergeGapSeconds: -4
        )

        #expect(configuration.silenceRmsThreshold == 0)
        #expect(configuration.snoreRmsThreshold == 1)
        #expect(configuration.snoreEnergyThreshold == 0)
        #expect(configuration.coughEnergyThreshold == 0)
        #expect(configuration.gaspEnergyThreshold == 0)
        #expect(configuration.bruxismHighBandThreshold == 1)
        #expect(configuration.environmentalNoiseThreshold == 0)
        #expect(configuration.suspectedPauseMinimumDuration == 1)
        #expect(configuration.minimumConfidence == 1)
        #expect(configuration.minimumEventDuration == 0.05)
        #expect(configuration.mergeGapSeconds == 0)
    }

    @Test
    func mapsToRuleBasedAndSmoothingPolicies() {
        let configuration = DetectorTuningProfile.conservative.configuration
        let ruleThresholds = configuration.ruleBasedThresholds
        let smoothingPolicy = configuration.smoothingPolicy

        #expect(ruleThresholds.snoreRMS == configuration.snoreRmsThreshold)
        #expect(ruleThresholds.noiseRMS == configuration.environmentalNoiseThreshold)
        #expect(ruleThresholds.suspectedPauseMinimumDuration == configuration.suspectedPauseMinimumDuration)
        #expect(smoothingPolicy.confidenceThreshold == configuration.minimumConfidence)
        #expect(smoothingPolicy.minimumEventDuration == configuration.minimumEventDuration)
        #expect(smoothingPolicy.maximumMergeGap == configuration.mergeGapSeconds)
    }

    @Test
    func thresholdSnapshotIncludesTuningFields() {
        let snapshot = DetectorTuningProfile.sensitive.configuration.thresholdSnapshot

        #expect(snapshot["tuning.profileIndex"] == DetectorTuningProfile.sensitive.snapshotIndex)
        #expect(snapshot["tuning.snoreRmsThreshold"] == DetectorTuningProfile.sensitive.configuration.snoreRmsThreshold)
        #expect(snapshot["tuning.snoreEnergyThreshold"] == DetectorTuningProfile.sensitive.configuration.snoreEnergyThreshold)
        #expect(snapshot["tuning.minimumConfidence"] == DetectorTuningProfile.sensitive.configuration.minimumConfidence)
        #expect(snapshot["tuning.mergeGapSeconds"] == DetectorTuningProfile.sensitive.configuration.mergeGapSeconds)
    }

    @Test
    func analyzerBuiltFromProfileExposesThresholdSnapshot() {
        let configuration = DetectorTuningProfile.sensitive.configuration
        let analyzer = configuration.makeSleepAnalyzer()

        #expect(analyzer.detectorBackend == .ruleBased)
        #expect(analyzer.thresholdsSnapshot["rule.snoreRMS"] == configuration.snoreRmsThreshold)
        #expect(analyzer.thresholdsSnapshot["smoothing.confidenceThreshold"] == configuration.minimumConfidence)
    }
}
