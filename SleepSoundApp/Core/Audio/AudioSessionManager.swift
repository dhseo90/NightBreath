import AVFoundation
import Foundation

public enum MicrophonePermissionState: Equatable, Sendable {
    case notDetermined
    case granted
    case denied
}

public enum AudioSessionError: Error, Equatable, Sendable {
    case microphonePermissionDenied
    case microphoneUnavailable
    case failedToConfigure(String)

    public var message: String {
        switch self {
        case .microphonePermissionDenied:
            "마이크 권한이 허용되지 않았습니다."
        case .microphoneUnavailable:
            "사용 가능한 마이크 입력을 찾을 수 없습니다."
        case .failedToConfigure(let reason):
            "오디오 세션 설정에 실패했습니다. \(reason)"
        }
    }
}

public protocol AudioSessionManaging: Sendable {
    func microphonePermissionState() -> MicrophonePermissionState
    func requestMicrophonePermission() async -> MicrophonePermissionState
    func prepareForSleepRecording() throws
    func finishSleepRecording()
}

public final class AudioSessionManager: AudioSessionManaging, @unchecked Sendable {
    public init() {}

    public func microphonePermissionState() -> MicrophonePermissionState {
        switch AVCaptureDevice.authorizationStatus(for: .audio) {
        case .authorized:
            .granted
        case .denied, .restricted:
            .denied
        case .notDetermined:
            .notDetermined
        @unknown default:
            .denied
        }
    }

    public func requestMicrophonePermission() async -> MicrophonePermissionState {
        await withCheckedContinuation { continuation in
            AVCaptureDevice.requestAccess(for: .audio) { granted in
                continuation.resume(returning: granted ? .granted : .denied)
            }
        }
    }

    public func prepareForSleepRecording() throws {
        guard microphonePermissionState() == .granted else {
            throw AudioSessionError.microphonePermissionDenied
        }

        // 화면 잠금/백그라운드 QA를 위해 target Info.plist의 UIBackgroundModes에 audio를 설정합니다.
        // 이 설정은 캡처 유지 조건일 뿐이며, 원본 전체 밤 오디오 파일 저장을 의미하지 않습니다.
        #if os(iOS)
        let session = AVAudioSession.sharedInstance()

        do {
            try session.setCategory(.record, mode: .measurement, options: [.allowBluetoothHFP])
            try session.setPreferredSampleRate(16_000)
            try session.setPreferredIOBufferDuration(0.1)
            try session.setActive(true, options: [])
        } catch {
            throw AudioSessionError.failedToConfigure(error.localizedDescription)
        }
        #endif
    }

    public func finishSleepRecording() {
        #if os(iOS)
        try? AVAudioSession.sharedInstance().setActive(false, options: [.notifyOthersOnDeactivation])
        #endif
    }
}

public struct PreviewAudioSessionManager: AudioSessionManaging {
    public init() {}

    public func microphonePermissionState() -> MicrophonePermissionState {
        .notDetermined
    }

    public func requestMicrophonePermission() async -> MicrophonePermissionState {
        .granted
    }

    public func prepareForSleepRecording() throws {}

    public func finishSleepRecording() {}
}

public extension MicrophonePermissionState {
    var displayText: String {
        switch self {
        case .notDetermined:
            "아직 결정되지 않음"
        case .granted:
            "허용됨"
        case .denied:
            "허용되지 않음"
        }
    }
}
