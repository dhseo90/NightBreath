import Foundation
import Testing

@testable import SleepSoundCore

@Suite("SyntheticAudioSource")
struct SyntheticAudioSourceTests {
  @Test
  func silenceDoesNotCreateExcessiveEvents() {
    let chunks = SyntheticAudioSource.makeChunks(
      pattern: .silence,
      duration: 5,
      sampleRate: 16_000,
      chunkDuration: 1,
      startedAt: Date(timeIntervalSince1970: 100)
    )

    let outputs = SleepAnalyzer().analyze(chunks: chunks)

    #expect(outputs.isEmpty)
  }

  @Test
  func snoreLikeBurstCreatesSnoreCandidate() {
    let chunks = SyntheticAudioSource.makeChunks(
      pattern: .snoreLikeBurst,
      duration: 3,
      sampleRate: 16_000,
      chunkDuration: 1,
      startedAt: Date(timeIntervalSince1970: 100)
    )

    let outputs = SleepAnalyzer(
      smoothingPolicy: DetectionSmoothingPolicy(
        minimumEventDuration: 0.2,
        maximumMergeGap: 1,
        confidenceThreshold: 0.2
      )
    ).analyze(chunks: chunks)

    #expect(outputs.contains { $0.eventType == .snore })
  }

  @Test
  @MainActor
  func sourceEmitsChunksAndTracksReceivedAudioSeconds() async throws {
    let source: any AudioSourceProtocol = SyntheticAudioSource(
      pattern: .lowEnergyNoise,
      replayMode: .fastAsPossible,
      duration: 2,
      sampleRate: 16_000,
      chunkDuration: 1
    )
    let stream = source.makeChunkStream()
    try await source.start()

    var chunks: [AudioChunk] = []
    for try await chunk in stream {
      chunks.append(chunk)
    }

    #expect(chunks.count == 2)
    #expect(source.metrics.receivedChunkCount == 2)
    #expect(abs(source.metrics.receivedAudioSeconds - 2) < 0.0001)
  }

  @Test
  @MainActor
  func stopRequestCancelsRealTimeReplayWithoutMoreChunks() async throws {
    let source = SyntheticAudioSource(
      pattern: .lowEnergyNoise,
      replayMode: .realTime,
      duration: 3,
      sampleRate: 16_000,
      chunkDuration: 0.05
    )
    var receivedChunkCount = 0
    source.onChunk = { _ in
      receivedChunkCount += 1
    }

    try await source.start()
    try await Task.sleep(nanoseconds: 160_000_000)
    source.stop()
    let countAtStop = receivedChunkCount
    try await Task.sleep(nanoseconds: 240_000_000)

    #expect(source.state == .stopped)
    #expect(receivedChunkCount == countAtStop)
  }
}
