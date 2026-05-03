import Foundation

public protocol UserSettingsProviding: AnyObject {
    var isEventAudioSampleStorageEnabled: Bool { get set }
}

public final class UserSettings: UserSettingsProviding {
    public static let eventAudioSampleStorageKey = "isEventAudioSampleStorageEnabled"

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
