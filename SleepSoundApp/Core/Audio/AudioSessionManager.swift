import Foundation

public enum MicrophonePermissionState: Equatable {
    case notDetermined
    case granted
    case denied
}

public protocol AudioSessionManaging {
    func microphonePermissionState() -> MicrophonePermissionState
    func prepareForSleepRecording() throws
}

public struct PreviewAudioSessionManager: AudioSessionManaging {
    public init() {}

    public func microphonePermissionState() -> MicrophonePermissionState {
        .notDetermined
    }

    public func prepareForSleepRecording() throws {
        // Phase 1 keeps this as a no-op. Real audio session setup lands in Phase 2.
    }
}
