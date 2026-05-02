import Foundation

public enum AudioCaptureState: Equatable, Sendable {
    case idle
    case requestingPermission
    case ready
    case capturing(startedAt: Date)
    case stopping
    case stopped
    case failed(message: String)

    public var isCapturing: Bool {
        if case .capturing = self {
            return true
        }
        return false
    }

    public var isPreparing: Bool {
        switch self {
        case .requestingPermission, .ready, .stopping:
            true
        case .idle, .capturing, .stopped, .failed:
            false
        }
    }

    public var captureStartedAt: Date? {
        if case .capturing(let startedAt) = self {
            return startedAt
        }
        return nil
    }

    public var displayText: String {
        switch self {
        case .idle:
            "대기 중"
        case .requestingPermission:
            "마이크 권한 확인 중"
        case .ready:
            "녹음 준비 완료"
        case .capturing:
            "오디오 캡처 중"
        case .stopping:
            "캡처 종료 중"
        case .stopped:
            "캡처 종료됨"
        case .failed(let message):
            "캡처 오류: \(message)"
        }
    }
}
