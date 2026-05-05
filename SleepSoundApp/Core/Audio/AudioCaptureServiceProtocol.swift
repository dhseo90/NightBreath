import Foundation

public typealias AudioChunkConsumer = (AudioChunk) -> Void
public typealias AudioCaptureStateConsumer = (AudioCaptureState) -> Void

public enum AudioCaptureError: Error, Equatable, Sendable {
    case microphonePermissionNotDetermined
    case microphonePermissionDenied
    case microphoneUnavailable
    case unsupportedPCMFormat
    case engineStartFailed(String)
    case captureInterrupted

    public var message: String {
        switch self {
        case .microphonePermissionNotDetermined:
            "마이크 권한이 아직 결정되지 않았습니다."
        case .microphonePermissionDenied:
            "마이크 권한이 허용되지 않았습니다."
        case .microphoneUnavailable:
            "사용 가능한 마이크 입력을 찾을 수 없습니다."
        case .unsupportedPCMFormat:
            "지원하지 않는 오디오 버퍼 형식입니다."
        case .engineStartFailed(let reason):
            "오디오 엔진을 시작하지 못했습니다. \(reason)"
        case .captureInterrupted:
            "오디오 캡처가 중단되었습니다. 수면 종료 후 리포트를 확인해 주세요."
        }
    }
}

@MainActor
public protocol AudioCaptureServiceProtocol: AnyObject {
    var state: AudioCaptureState { get }
    var metrics: AudioCaptureMetrics { get }
    var isCapturing: Bool { get }
    var onChunk: AudioChunkConsumer? { get set }
    var onStateChange: AudioCaptureStateConsumer? { get set }

    func makeChunkStream() -> AsyncStream<AudioChunk>
    func startCapture() throws
    func stopCapture()
    func forceStopCapture(reason: String)
}
