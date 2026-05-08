import Testing
@testable import SleepSoundCore

@Suite("DetectorThresholdConfiguration")
struct DetectorThresholdConfigurationTests {
    @Test
    func releaseDefaultAndDebugProfilesStayStable() {
        #expect(DetectorTuningProfile.releaseDefault == .balanced)
        #expect(DetectorTuningProfile.debugSelectableProfiles == [
            .verySensitive,
            .sensitive,
            .balanced,
            .conservative,
            .veryConservative
        ])
    }

    @Test
    func sensitiveProfilesAreLabeledAsDebugComparisonOnly() {
        #expect(DetectorTuningProfile.verySensitive.isDebugComparisonOnly)
        #expect(DetectorTuningProfile.sensitive.isDebugComparisonOnly)
        #expect(!DetectorTuningProfile.balanced.isDebugComparisonOnly)
        #expect(DetectorTuningProfile.verySensitive.debugSelectionDisplayName.contains("DEBUG 비교"))
        #expect(DetectorTuningProfile.sensitive.debugSelectionDisplayName.contains("DEBUG 비교"))
        #expect(DetectorTuningProfile.balanced.debugSelectionDisplayName == "보통")
    }

    @Test
    func profileThresholdsStayOrderedBySensitivity() {
        let verySensitive = DetectorTuningProfile.verySensitive.configuration
        let sensitive = DetectorTuningProfile.sensitive.configuration
        let balanced = DetectorTuningProfile.balanced.configuration
        let conservative = DetectorTuningProfile.conservative.configuration
        let veryConservative = DetectorTuningProfile.veryConservative.configuration

        #expect(veryConservative.snoreRmsThreshold > conservative.snoreRmsThreshold)
        #expect(conservative.snoreRmsThreshold > balanced.snoreRmsThreshold)
        #expect(balanced.snoreRmsThreshold > sensitive.snoreRmsThreshold)
        #expect(sensitive.snoreRmsThreshold > verySensitive.snoreRmsThreshold)
        #expect(veryConservative.snoreEnergyThreshold > conservative.snoreEnergyThreshold)
        #expect(conservative.snoreEnergyThreshold > balanced.snoreEnergyThreshold)
        #expect(balanced.snoreEnergyThreshold > sensitive.snoreEnergyThreshold)
        #expect(sensitive.snoreEnergyThreshold > verySensitive.snoreEnergyThreshold)
        #expect(veryConservative.minimumConfidence > conservative.minimumConfidence)
        #expect(conservative.minimumConfidence > balanced.minimumConfidence)
        #expect(balanced.minimumConfidence > sensitive.minimumConfidence)
        #expect(sensitive.minimumConfidence > verySensitive.minimumConfidence)
        #expect(veryConservative.minimumEventDuration > conservative.minimumEventDuration)
        #expect(conservative.minimumEventDuration > balanced.minimumEventDuration)
        #expect(balanced.minimumEventDuration > sensitive.minimumEventDuration)
        #expect(sensitive.minimumEventDuration > verySensitive.minimumEventDuration)
    }

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
    func customDebugCurrentlyMirrorsBalancedValues() {
        var balanced = DetectorTuningProfile.balanced.configuration
        balanced.profile = .customDebug

        #expect(DetectorTuningProfile.customDebug.configuration == balanced)
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

        #expect(snapshot.keys.count == 12)
        #expect(snapshot["tuning.profileIndex"] == DetectorTuningProfile.sensitive.snapshotIndex)
        #expect(snapshot["tuning.snoreRmsThreshold"] == DetectorTuningProfile.sensitive.configuration.snoreRmsThreshold)
        #expect(snapshot["tuning.snoreEnergyThreshold"] == DetectorTuningProfile.sensitive.configuration.snoreEnergyThreshold)
        #expect(snapshot["tuning.minimumConfidence"] == DetectorTuningProfile.sensitive.configuration.minimumConfidence)
        #expect(snapshot["tuning.minimumEventDuration"] == DetectorTuningProfile.sensitive.configuration.minimumEventDuration)
        #expect(snapshot["tuning.mergeGapSeconds"] == DetectorTuningProfile.sensitive.configuration.mergeGapSeconds)
    }

    @Test
    func profileSmoothingPoliciesRespectConfiguredDurationsAndConfidence() {
        for profile in DetectorTuningProfile.debugSelectableProfiles {
            let configuration = profile.configuration
            let smoothing = configuration.smoothingPolicy

            #expect(smoothing.confidenceThreshold == configuration.minimumConfidence)
            #expect(smoothing.minimumEventDuration == configuration.minimumEventDuration)
            #expect(smoothing.maximumMergeGap == configuration.mergeGapSeconds)
            #expect(smoothing.minimumEventDuration >= 0.05)
            #expect((0...1).contains(smoothing.confidenceThreshold))
        }
    }

    @Test
    func analyzerBuiltFromProfileExposesThresholdSnapshot() {
        let configuration = DetectorTuningProfile.sensitive.configuration
        let analyzer = configuration.makeSleepAnalyzer()

        #expect(analyzer.detectorBackend == .hybrid)
        #expect(analyzer.thresholdsSnapshot["rule.snoreRMS"] == configuration.snoreRmsThreshold)
        #expect(analyzer.thresholdsSnapshot["rule.lowLevelSnoreRMS"] == configuration.ruleBasedThresholds.lowLevelSnoreRMS)
        #expect(analyzer.thresholdsSnapshot["rule.lowLevelSnoreLowBandRatio"] == configuration.ruleBasedThresholds.lowLevelSnoreLowBandRatio)
        #expect(analyzer.thresholdsSnapshot["rule.snoreRelativeEnergyRatio"] == configuration.ruleBasedThresholds.snoreRelativeEnergyRatio)
        #expect(analyzer.thresholdsSnapshot["smoothing.confidenceThreshold"] == configuration.minimumConfidence)
        #expect(analyzer.thresholdsSnapshot["coreML.confidenceThreshold"] == CoreMLDetectorConfiguration.default.confidenceThreshold)
    }

    @Test
    func explicitRuleBasedAnalyzerCanStillBeBuiltForComparisons() {
        let analyzer = DetectorTuningProfile.balanced.configuration.makeSleepAnalyzer(backend: .ruleBased)

        #expect(analyzer.detectorBackend == .ruleBased)
        #expect(analyzer.isModelInstalled == false)
    }
}
