import Testing
@testable import SleepSoundCore

@Suite("DetectorTuningProfile")
struct DetectorTuningProfileTests {
    @Test
    func releaseDefaultUsesBalancedProfile() {
        #expect(DetectorTuningProfile.releaseDefault == .balanced)
        #expect(DetectorTuningProfile.releaseDefault.configuration.profile == .balanced)
    }

    @Test
    func debugSelectableProfilesDoNotExposeCustomDebugByDefault() {
        #expect(DetectorTuningProfile.debugSelectableProfiles == [
            .verySensitive,
            .sensitive,
            .balanced,
            .conservative,
            .veryConservative
        ])
        #expect(!DetectorTuningProfile.debugSelectableProfiles.contains(.customDebug))
    }

    @Test
    func displayNamesUseUserFacingSensitivityLevels() {
        #expect(DetectorTuningProfile.debugSelectableProfiles.map(\.displayName) == [
            "많이 민감",
            "민감",
            "보통",
            "둔감",
            "많이 둔감"
        ])
    }

    @Test
    func sensitiveProfilesAreOnlyModeratelyMorePermissiveThanBalanced() {
        let verySensitive = DetectorTuningProfile.verySensitive.configuration
        let balanced = DetectorTuningProfile.balanced.configuration
        let sensitive = DetectorTuningProfile.sensitive.configuration

        #expect(sensitive.snoreRmsThreshold < balanced.snoreRmsThreshold)
        #expect(sensitive.minimumConfidence < balanced.minimumConfidence)
        #expect(verySensitive.snoreRmsThreshold < sensitive.snoreRmsThreshold)
        #expect(verySensitive.minimumConfidence < sensitive.minimumConfidence)
        #expect(verySensitive.snoreRmsThreshold >= 0.035)
        #expect(verySensitive.minimumConfidence >= 0.30)
        #expect(verySensitive.minimumEventDuration >= 0.10)
        #expect(sensitive.snoreRmsThreshold >= 0.035)
        #expect(sensitive.minimumConfidence >= 0.30)
        #expect(sensitive.minimumEventDuration >= 0.10)
    }

    @Test
    func conservativeProfilesAreMoreRestrictiveThanBalanced() {
        let balanced = DetectorTuningProfile.balanced.configuration
        let conservative = DetectorTuningProfile.conservative.configuration
        let veryConservative = DetectorTuningProfile.veryConservative.configuration

        #expect(conservative.snoreRmsThreshold > balanced.snoreRmsThreshold)
        #expect(veryConservative.snoreRmsThreshold > conservative.snoreRmsThreshold)
        #expect(conservative.minimumConfidence > balanced.minimumConfidence)
        #expect(veryConservative.minimumConfidence > conservative.minimumConfidence)
    }
}
