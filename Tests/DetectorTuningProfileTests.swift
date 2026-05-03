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
        #expect(DetectorTuningProfile.debugSelectableProfiles == [.conservative, .balanced, .sensitive])
        #expect(!DetectorTuningProfile.debugSelectableProfiles.contains(.customDebug))
    }

    @Test
    func sensitiveProfileIsOnlyModeratelyMorePermissiveThanBalanced() {
        let balanced = DetectorTuningProfile.balanced.configuration
        let sensitive = DetectorTuningProfile.sensitive.configuration

        #expect(sensitive.snoreRmsThreshold < balanced.snoreRmsThreshold)
        #expect(sensitive.minimumConfidence < balanced.minimumConfidence)
        #expect(sensitive.snoreRmsThreshold >= 0.035)
        #expect(sensitive.minimumConfidence >= 0.30)
        #expect(sensitive.minimumEventDuration >= 0.10)
    }
}
