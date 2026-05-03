import Foundation

public enum AudioSourceReplayMode: String, Codable, CaseIterable, Identifiable, Sendable {
  case realTime
  case fastAsPossible

  public var id: String { rawValue }

  public var displayName: String {
    switch self {
    case .realTime:
      return "실시간"
    case .fastAsPossible:
      return "빠른 재생"
    }
  }
}

public enum AudioSourceError: Error, Equatable, Sendable {
  case alreadyRunning
  case fileNotFound(String)
  case unsupportedFileType(String)
  case failedToOpenFile(String)
  case failedToCreateBuffer
  case unsupportedPCMFormat
  case stopped

  public var message: String {
    switch self {
    case .alreadyRunning:
      return "이미 replay가 실행 중입니다."
    case .fileNotFound(let path):
      return "오디오 파일을 찾을 수 없습니다. \(path)"
    case .unsupportedFileType(let pathExtension):
      return "지원하지 않는 오디오 파일 형식입니다. \(pathExtension)"
    case .failedToOpenFile(let reason):
      return "오디오 파일을 열지 못했습니다. \(reason)"
    case .failedToCreateBuffer:
      return "오디오 replay용 버퍼를 만들지 못했습니다."
    case .unsupportedPCMFormat:
      return "지원하지 않는 PCM 형식입니다."
    case .stopped:
      return "오디오 source가 중지되었습니다."
    }
  }
}

@MainActor
public protocol AudioSourceProtocol: AnyObject {
  var state: AudioCaptureState { get }
  var metrics: AudioCaptureMetrics { get }
  var onChunk: AudioChunkConsumer? { get set }
  var onStateChange: AudioCaptureStateConsumer? { get set }

  func makeChunkStream() -> AsyncThrowingStream<AudioChunk, Error>
  func start() async throws
  func stop()
}

extension AudioSourceProtocol {
  public var isRunning: Bool {
    state.isPreparing || state.isCapturing
  }
}
