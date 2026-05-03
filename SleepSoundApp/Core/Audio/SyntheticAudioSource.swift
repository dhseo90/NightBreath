import Foundation

public enum SyntheticAudioPattern: String, Codable, CaseIterable, Identifiable, Sendable {
  case silence
  case lowEnergyNoise
  case highEnergyNoise
  case snoreLikeBurst
  case coughLikeBurst
  case gaspLikeBurst
  case movementLikeNoise
  case breathingPauseLikeLowActivity

  public var id: String { rawValue }

  public var displayName: String {
    switch self {
    case .silence:
      return "무음"
    case .lowEnergyNoise:
      return "낮은 에너지 소음"
    case .highEnergyNoise:
      return "큰 환경 소음"
    case .snoreLikeBurst:
      return "코골기 유사 burst"
    case .coughLikeBurst:
      return "기침 의심 burst"
    case .gaspLikeBurst:
      return "gasp-like 회복 호흡 burst"
    case .movementLikeNoise:
      return "움직임 의심 소리"
    case .breathingPauseLikeLowActivity:
      return "호흡정지 의심 저활동 구간"
    }
  }

  public var defaultDuration: TimeInterval {
    switch self {
    case .breathingPauseLikeLowActivity:
      return 12
    default:
      return 8
    }
  }
}

@MainActor
public final class SyntheticAudioSource: AudioSourceProtocol {
  public private(set) var state: AudioCaptureState = .idle {
    didSet { onStateChange?(state) }
  }
  public private(set) var metrics = AudioCaptureMetrics()
  public var onChunk: AudioChunkConsumer?
  public var onStateChange: AudioCaptureStateConsumer?

  private let pattern: SyntheticAudioPattern
  private let replayMode: AudioSourceReplayMode
  private let duration: TimeInterval
  private let sampleRate: Double
  private let chunkDuration: TimeInterval
  private var continuations: [UUID: AsyncThrowingStream<AudioChunk, Error>.Continuation] = [:]
  private var replayTask: Task<Void, Never>?

  public init(
    pattern: SyntheticAudioPattern,
    replayMode: AudioSourceReplayMode = .fastAsPossible,
    duration: TimeInterval? = nil,
    sampleRate: Double = 16_000,
    chunkDuration: TimeInterval = 1
  ) {
    self.pattern = pattern
    self.replayMode = replayMode
    self.duration = max(0.1, duration ?? pattern.defaultDuration)
    self.sampleRate = max(1, sampleRate)
    self.chunkDuration = max(0.05, chunkDuration)
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
    let chunks = Self.makeChunks(
      pattern: pattern,
      duration: duration,
      sampleRate: sampleRate,
      chunkDuration: chunkDuration,
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
  }

  public func stop() {
    replayTask?.cancel()
    finishReplay(error: AudioSourceError.stopped)
  }

  nonisolated public static func makeChunks(
    pattern: SyntheticAudioPattern,
    duration: TimeInterval? = nil,
    sampleRate: Double = 16_000,
    chunkDuration: TimeInterval = 1,
    startedAt: Date = Date()
  ) -> [AudioChunk] {
    let totalDuration = max(0.1, duration ?? pattern.defaultDuration)
    let safeSampleRate = max(1, sampleRate)
    let baseChunkDuration =
      pattern == .breathingPauseLikeLowActivity
      ? min(max(totalDuration, 10), totalDuration)
      : max(0.05, chunkDuration)
    var chunks: [AudioChunk] = []
    var elapsed: TimeInterval = 0
    var chunkIndex = 0

    while elapsed < totalDuration {
      let currentDuration = min(baseChunkDuration, totalDuration - elapsed)
      let samples = makeSamples(
        pattern: pattern,
        sampleRate: safeSampleRate,
        duration: currentDuration,
        seed: chunkIndex
      )
      let chunkStartedAt = startedAt.addingTimeInterval(elapsed)
      chunks.append(
        AudioChunk(
          samples: samples,
          sampleRate: safeSampleRate,
          startedAt: chunkStartedAt,
          duration: currentDuration
        )
      )
      elapsed += currentDuration
      chunkIndex += 1
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
    state = .stopped
    replayTask = nil

    for continuation in continuations.values {
      if let error {
        continuation.finish(throwing: error)
      } else {
        continuation.finish()
      }
    }
    continuations.removeAll(keepingCapacity: true)
  }

  nonisolated private static func makeSamples(
    pattern: SyntheticAudioPattern,
    sampleRate: Double,
    duration: TimeInterval,
    seed: Int
  ) -> [Float] {
    let frameCount = max(1, Int((duration * sampleRate).rounded()))
    return (0..<frameCount).map { frame in
      let t = Double(frame) / sampleRate
      let sample: Double

      switch pattern {
      case .silence, .breathingPauseLikeLowActivity:
        sample = 0
      case .lowEnergyNoise:
        sample = pseudoNoise(frame, seed: seed) * 0.006
      case .highEnergyNoise:
        sample = pseudoNoise(frame, seed: seed) * 0.38
      case .snoreLikeBurst:
        let envelope = 0.72 + 0.28 * sin(2 * .pi * 3 * t)
        sample = sin(2 * .pi * 120 * t) * 0.13 * envelope
      case .coughLikeBurst:
        let burstStart = duration * 0.22
        let burstEnd = min(duration * 0.62, burstStart + 0.45)
        if t >= burstStart, t <= burstEnd {
          let envelope = sin(.pi * (t - burstStart) / max(0.001, burstEnd - burstStart))
          sample = pseudoNoise(frame, seed: seed + 11) * 0.34 * envelope
        } else {
          sample = 0
        }
      case .gaspLikeBurst:
        let envelope = min(1, t / 0.18) * max(0, 1 - t / max(duration, 0.2))
        sample = sin(2 * .pi * 720 * t) * 0.18 * envelope
      case .movementLikeNoise:
        if frame % max(1, Int(sampleRate * 0.11)) < Int(sampleRate * 0.018) {
          sample = pseudoNoise(frame, seed: seed + 23) * 0.18
        } else {
          sample = pseudoNoise(frame, seed: seed + 29) * 0.012
        }
      }

      return Float(max(-1, min(1, sample)))
    }
  }

  nonisolated private static func pseudoNoise(_ index: Int, seed: Int) -> Double {
    let raw = sin(Double(index + seed * 9_973) * 12.9898) * 43_758.5453
    return (raw - floor(raw)) * 2 - 1
  }
}
