import Foundation

public protocol AudioCaptureServiceProtocol {
    var isCapturing: Bool { get }
    func startCapture() throws
    func stopCapture()
}

public enum AudioCaptureError: Error, Equatable {
    case microphoneUnavailable
    case permissionDenied
}

public final class MockAudioCaptureService: AudioCaptureServiceProtocol {
    public private(set) var isCapturing: Bool = false

    public init() {}

    public func startCapture() throws {
        isCapturing = true
    }

    public func stopCapture() {
        isCapturing = false
    }
}
