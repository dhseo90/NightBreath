import Foundation
import Testing

@testable import SleepSoundCore

@Suite("AudioSourceProtocol")
struct AudioSourceProtocolTests {
  @Test
  @MainActor
  func sleepAnalyzerCanConsumeAudioSourceStream() async throws {
    let startedAt = Date(timeIntervalSince1970: 300)
    let source: any AudioSourceProtocol = SyntheticAudioSource(
      pattern: .snoreLikeBurst,
      replayMode: .fastAsPossible,
      duration: 3,
      sampleRate: 16_000,
      chunkDuration: 1
    )
    let session = SleepSession(
      startedAt: startedAt,
      endedAt: startedAt.addingTimeInterval(3),
      measurementDuration: 3,
      estimatedSleepDuration: 3
    )
    let analyzer = SleepAnalyzer(
      smoothingPolicy: DetectionSmoothingPolicy(
        minimumEventDuration: 0.2,
        maximumMergeGap: 1,
        confidenceThreshold: 0.2
      )
    )

    let events = try await analyzer.analyze(session: session, audioSource: source)

    #expect(!events.isEmpty)
    #expect(events.contains { $0.type == .snore })
  }
}
