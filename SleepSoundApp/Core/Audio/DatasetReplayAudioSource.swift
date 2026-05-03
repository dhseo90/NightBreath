import AVFoundation
import Foundation

@MainActor
public final class DatasetReplayAudioSource: AudioSourceProtocol {
  public private(set) var state: AudioCaptureState = .idle {
    didSet { onStateChange?(state) }
  }
  public private(set) var metrics = AudioCaptureMetrics()
  public var onChunk: AudioChunkConsumer?
  public var onStateChange: AudioCaptureStateConsumer?

  private let fileURL: URL
  private let replayMode: AudioSourceReplayMode
  private let chunkDuration: TimeInterval
  private let segmentStartSeconds: TimeInterval
  private let segmentDurationSeconds: TimeInterval?
  private var continuations: [UUID: AsyncThrowingStream<AudioChunk, Error>.Continuation] = [:]
  private var replayTask: Task<Void, Never>?

  public init(
    fileURL: URL,
    replayMode: AudioSourceReplayMode = .fastAsPossible,
    chunkDuration: TimeInterval = 1,
    segmentStartSeconds: TimeInterval = 0,
    segmentDurationSeconds: TimeInterval? = nil
  ) {
    self.fileURL = fileURL
    self.replayMode = replayMode
    self.chunkDuration = max(0.05, chunkDuration)
    self.segmentStartSeconds = max(0, segmentStartSeconds)
    if let segmentDurationSeconds, segmentDurationSeconds.isFinite, segmentDurationSeconds > 0 {
      self.segmentDurationSeconds = segmentDurationSeconds
    } else {
      self.segmentDurationSeconds = nil
    }
  }

  public func makeChunkStream() -> AsyncThrowingStream<AudioChunk, Error> {
    let id = UUID()

    return AsyncThrowingStream { continuation in
      continuations[id] = continuation
      continuation.onTermination = { [weak self] _ in
        Task { @MainActor [weak self] in
          self?.continuations.removeValue(forKey: id)
        }
      }
    }
  }

  public func start() async throws {
    guard replayTask == nil else {
      throw AudioSourceError.alreadyRunning
    }

    let startedAt = Date()
    state = .ready

    do {
      let chunks = try Self.loadChunks(
        fileURL: fileURL,
        chunkDuration: chunkDuration,
        segmentStartSeconds: segmentStartSeconds,
        segmentDurationSeconds: segmentDurationSeconds,
        startedAt: startedAt
      )

      metrics.start(at: startedAt)
      state = .capturing(startedAt: startedAt)
      replayTask = Task { [weak self, replayMode] in
        for chunk in chunks {
          if Task.isCancelled { break }
          self?.emit(chunk)

          if replayMode == .realTime {
            try? await Task.sleep(nanoseconds: UInt64(max(0, chunk.duration) * 1_000_000_000))
          }
        }

        await MainActor.run { [weak self] in
          self?.finishReplay()
        }
      }
    } catch {
      metrics.recordCaptureError(at: startedAt)
      state = .failed(message: Self.message(for: error))
      finishContinuations(error: error)
      throw error
    }
  }

  public func stop() {
    replayTask?.cancel()
    finishReplay(error: AudioSourceError.stopped)
  }

  nonisolated public static func loadChunks(
    fileURL: URL,
    chunkDuration: TimeInterval = 1,
    segmentStartSeconds: TimeInterval = 0,
    segmentDurationSeconds: TimeInterval? = nil,
    startedAt: Date = Date()
  ) throws -> [AudioChunk] {
    let extensionName = fileURL.pathExtension.lowercased()
    guard ["wav", "caf", "m4a"].contains(extensionName) else {
      throw AudioSourceError.unsupportedFileType(extensionName.isEmpty ? "(none)" : extensionName)
    }

    let didStartAccessing = fileURL.startAccessingSecurityScopedResource()
    defer {
      if didStartAccessing {
        fileURL.stopAccessingSecurityScopedResource()
      }
    }

    guard FileManager.default.fileExists(atPath: fileURL.path) else {
      throw AudioSourceError.fileNotFound(fileURL.path)
    }

    let file: AVAudioFile
    do {
      file = try AVAudioFile(forReading: fileURL)
    } catch {
      throw AudioSourceError.failedToOpenFile(error.localizedDescription)
    }

    let format = file.processingFormat
    let sampleRate = max(1, format.sampleRate)
    let channelCount = max(1, Int(format.channelCount))
    let safeChunkDuration = max(0.05, chunkDuration)
    let framesPerChunk = max(1, AVAudioFrameCount((safeChunkDuration * sampleRate).rounded()))
    let startFrame = max(
      0, AVAudioFramePosition((max(0, segmentStartSeconds) * sampleRate).rounded()))
    let availableFrames = max(0, file.length - startFrame)
    let requestedFrames: AVAudioFramePosition

    if let segmentDurationSeconds, segmentDurationSeconds.isFinite, segmentDurationSeconds > 0 {
      requestedFrames = min(
        availableFrames,
        max(0, AVAudioFramePosition((segmentDurationSeconds * sampleRate).rounded()))
      )
    } else {
      requestedFrames = availableFrames
    }

    guard requestedFrames > 0 else { return [] }

    file.framePosition = startFrame
    var remainingFrames = requestedFrames
    var elapsed = TimeInterval(startFrame) / sampleRate
    var chunks: [AudioChunk] = []

    while remainingFrames > 0 {
      let framesToRead = AVAudioFrameCount(
        min(AVAudioFramePosition(framesPerChunk), remainingFrames))
      guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: framesToRead) else {
        throw AudioSourceError.failedToCreateBuffer
      }

      do {
        try file.read(into: buffer, frameCount: framesToRead)
      } catch {
        throw AudioSourceError.failedToOpenFile(error.localizedDescription)
      }

      let actualFrames = Int(buffer.frameLength)
      if actualFrames <= 0 { break }

      let samples = try makeMonoSamples(
        from: buffer, frameCount: actualFrames, channelCount: channelCount)
      let actualDuration = Double(actualFrames) / sampleRate
      chunks.append(
        AudioChunk(
          timestamp: startedAt.addingTimeInterval(elapsed - TimeInterval(startFrame) / sampleRate),
          sampleRate: sampleRate,
          channelCount: channelCount,
          frameCount: actualFrames,
          duration: actualDuration,
          rms: AudioChunk.calculateRMS(samples),
          samples: samples
        )
      )

      remainingFrames -= AVAudioFramePosition(actualFrames)
      elapsed += actualDuration
    }

    return chunks
  }

  private func emit(_ chunk: AudioChunk) {
    metrics.recordReceived(chunk: chunk, at: chunk.startedAt)
    onChunk?(chunk)

    for continuation in continuations.values {
      continuation.yield(chunk)
    }
  }

  private func finishReplay(error: Error? = nil) {
    guard replayTask != nil || state.isCapturing || state.isPreparing else { return }

    metrics.stop(at: metrics.lastChunkReceivedAt ?? Date())
    replayTask = nil
    if error == nil {
      state = .stopped
    } else {
      state = .failed(message: Self.message(for: error ?? AudioSourceError.stopped))
    }
    finishContinuations(error: error)
  }

  private func finishContinuations(error: Error? = nil) {
    for continuation in continuations.values {
      if let error {
        continuation.finish(throwing: error)
      } else {
        continuation.finish()
      }
    }
    continuations.removeAll(keepingCapacity: true)
  }

  nonisolated private static func makeMonoSamples(
    from buffer: AVAudioPCMBuffer,
    frameCount: Int,
    channelCount: Int
  ) throws -> [Float] {
    guard frameCount > 0 else { return [] }

    if let floatChannelData = buffer.floatChannelData {
      var samples: [Float] = []
      samples.reserveCapacity(frameCount)

      for frame in 0..<frameCount {
        var sum: Float = 0
        for channel in 0..<channelCount {
          sum += floatChannelData[channel][frame]
        }
        samples.append(sum / Float(channelCount))
      }

      return samples
    }

    throw AudioSourceError.unsupportedPCMFormat
  }

  nonisolated private static func message(for error: Error) -> String {
    if let sourceError = error as? AudioSourceError {
      return sourceError.message
    }
    return error.localizedDescription
  }
}
