import Foundation

public protocol UserSettingsProviding: AnyObject {
    var isEventAudioSampleStorageEnabled: Bool { get set }
    var hasCompletedOnboarding: Bool { get set }
    var detectorTuningProfile: DetectorTuningProfile { get set }
    var hasRequestedHealthKitReadAccess: Bool { get set }
}

public final class UserSettings: UserSettingsProviding {
    public static let eventAudioSampleStorageKey = "isEventAudioSampleStorageEnabled"
    public static let hasCompletedOnboardingKey = "hasCompletedOnboarding"
    public static let detectorTuningProfileKey = "detectorTuningProfile"
    public static let hasRequestedHealthKitReadAccessKey = "hasRequestedHealthKitReadAccess"

    private let userDefaults: UserDefaults

    public init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    public var isEventAudioSampleStorageEnabled: Bool {
        get {
            userDefaults.bool(forKey: Self.eventAudioSampleStorageKey)
        }
        set {
            userDefaults.set(newValue, forKey: Self.eventAudioSampleStorageKey)
        }
    }

    public var hasCompletedOnboarding: Bool {
        get {
            userDefaults.bool(forKey: Self.hasCompletedOnboardingKey)
        }
        set {
            userDefaults.set(newValue, forKey: Self.hasCompletedOnboardingKey)
        }
    }

    public var detectorTuningProfile: DetectorTuningProfile {
        get {
            guard let rawValue = userDefaults.string(forKey: Self.detectorTuningProfileKey),
                  let profile = DetectorTuningProfile(rawValue: rawValue)
            else {
                return .releaseDefault
            }
            return DetectorTuningProfile.debugSelectableProfiles.contains(profile) ? profile : .releaseDefault
        }
        set {
            let profile = DetectorTuningProfile.debugSelectableProfiles.contains(newValue) ? newValue : .releaseDefault
            userDefaults.set(profile.rawValue, forKey: Self.detectorTuningProfileKey)
        }
    }

    public var hasRequestedHealthKitReadAccess: Bool {
        get {
            userDefaults.bool(forKey: Self.hasRequestedHealthKitReadAccessKey)
        }
        set {
            userDefaults.set(newValue, forKey: Self.hasRequestedHealthKitReadAccessKey)
        }
    }
}

public enum EventAudioSampleStorageRules {
    public static func shouldAttemptStorage(
        isEnabled: Bool,
        eventType: SleepEventType,
        duration: TimeInterval,
        confidence: Double,
        minimumConfidence: Double = 0.35
    ) -> Bool {
        guard isEnabled else { return false }
        guard eventType != .unknown else { return false }
        guard duration.isFinite, duration > 0 else { return false }
        guard confidence.isFinite, confidence >= minimumConfidence else { return false }
        return true
    }
}
