import Foundation

@MainActor
public final class RealMicrophoneAudioSource: AudioSourceProtocol {
  private let captureService: AudioCaptureServiceProtocol

  public init(captureService: AudioCaptureServiceProtocol = AudioCaptureService()) {
    self.captureService = captureService
  }

  public var state: AudioCaptureState {
    captureService.state
  }

  public var metrics: AudioCaptureMetrics {
    captureService.metrics
  }

  public var onChunk: AudioChunkConsumer? {
    get { captureService.onChunk }
    set { captureService.onChunk = newValue }
  }

  public var onStateChange: AudioCaptureStateConsumer? {
    get { captureService.onStateChange }
    set { captureService.onStateChange = newValue }
  }

  public func makeChunkStream() -> AsyncThrowingStream<AudioChunk, Error> {
    let stream = captureService.makeChunkStream()

    return AsyncThrowingStream { continuation in
      let task = Task {
        for await chunk in stream {
          continuation.yield(chunk)
        }
        continuation.finish()
      }

      continuation.onTermination = { _ in
        task.cancel()
      }
    }
  }

  public func start() async throws {
    try captureService.startCapture()
  }

  public func stop() {
    captureService.stopCapture()
  }
}
