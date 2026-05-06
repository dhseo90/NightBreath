import Foundation
import Testing
@testable import SleepSoundCore

@Suite("UserSettings")
struct UserSettingsTests {
    @Test
    func eventAudioSampleStorageDefaultIsOff() throws {
        let userDefaults = try makeIsolatedUserDefaults()
        let settings = UserSettings(userDefaults: userDefaults)

        #expect(settings.isEventAudioSampleStorageEnabled == false)
    }

    @Test
    func onboardingCompletionDefaultIsOffAndPersists() throws {
        let userDefaults = try makeIsolatedUserDefaults()
        let settings = UserSettings(userDefaults: userDefaults)

        #expect(settings.hasCompletedOnboarding == false)

        settings.hasCompletedOnboarding = true
        let reloadedSettings = UserSettings(userDefaults: userDefaults)

        #expect(reloadedSettings.hasCompletedOnboarding)
    }

    @Test
    func eventAudioSampleStoragePreferencePersists() throws {
        let userDefaults = try makeIsolatedUserDefaults()
        let settings = UserSettings(userDefaults: userDefaults)

        settings.isEventAudioSampleStorageEnabled = true
        #expect(settings.isEventAudioSampleStorageEnabled)

        let reloadedSettings = UserSettings(userDefaults: userDefaults)
        #expect(reloadedSettings.isEventAudioSampleStorageEnabled)

        reloadedSettings.isEventAudioSampleStorageEnabled = false
        #expect(settings.isEventAudioSampleStorageEnabled == false)
    }

    @Test
    func detectorTuningProfileDefaultsToBalancedAndPersistsSelectableLevel() throws {
        let userDefaults = try makeIsolatedUserDefaults()
        let settings = UserSettings(userDefaults: userDefaults)

        #expect(settings.detectorTuningProfile == .releaseDefault)

        settings.detectorTuningProfile = .verySensitive
        let reloadedSettings = UserSettings(userDefaults: userDefaults)

        #expect(reloadedSettings.detectorTuningProfile == .verySensitive)
    }

    @Test
    func detectorTuningProfileRejectsHiddenCustomDebugPersistence() throws {
        let userDefaults = try makeIsolatedUserDefaults()
        let settings = UserSettings(userDefaults: userDefaults)

        settings.detectorTuningProfile = .customDebug

        #expect(settings.detectorTuningProfile == .releaseDefault)
    }

    @Test
    func storageRulesBlockEventSamplesWhenSettingIsOff() {
        let shouldStore = EventAudioSampleStorageRules.shouldAttemptStorage(
            isEnabled: false,
            eventType: .snore,
            duration: 1.2,
            confidence: 0.8
        )

        #expect(shouldStore == false)
    }

    @Test
    func storageRulesAllowValidEventSamplesWhenSettingIsOn() {
        let shouldStore = EventAudioSampleStorageRules.shouldAttemptStorage(
            isEnabled: true,
            eventType: .snore,
            duration: 1.2,
            confidence: 0.8
        )

        #expect(shouldStore)
    }

    @Test
    func storageRulesRejectUnknownAndLowConfidenceEvents() {
        let unknown = EventAudioSampleStorageRules.shouldAttemptStorage(
            isEnabled: true,
            eventType: .unknown,
            duration: 1.2,
            confidence: 0.8
        )
        let lowConfidence = EventAudioSampleStorageRules.shouldAttemptStorage(
            isEnabled: true,
            eventType: .environmentalNoise,
            duration: 1.2,
            confidence: 0.2
        )

        #expect(unknown == false)
        #expect(lowConfidence == false)
    }

    private func makeIsolatedUserDefaults() throws -> UserDefaults {
        let suiteName = "NightBreathUserSettingsTests-\(UUID().uuidString)"
        let userDefaults = try #require(UserDefaults(suiteName: suiteName))
        userDefaults.removePersistentDomain(forName: suiteName)
        return userDefaults
    }
}
