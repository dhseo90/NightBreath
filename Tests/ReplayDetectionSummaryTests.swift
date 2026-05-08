import Foundation
import Testing

@testable import SleepSoundCore

@Suite("ReplayDetectionSummary")
struct ReplayDetectionSummaryTests {
    @Test
    func replaySummaryUsesSameAnalyzerPathForRecentSnoreAudio() {
        let chunks = SyntheticAudioSource.makeChunks(
            pattern: .snoreLikeBurst,
            duration: 4,
            sampleRate: 16_000,
            chunkDuration: 1,
            startedAt: Date(timeIntervalSince1970: 42_000)
        )
        let analyzer = DetectorTuningProfile.balanced.configuration.makeSleepAnalyzer()

        let summary = analyzer.makeReplayDetectionSummary(
            label: "recent-audio-debug-preview",
            chunks: chunks,
            thresholdsSnapshot: DetectorTuningProfile.balanced.configuration.thresholdSnapshot
        )

        #expect(summary.chunkCount == chunks.count)
        #expect(summary.audioSeconds == 4)
        #expect(summary.rawSnoreCandidateCount > 0)
        #expect(summary.finalSnoreEventCount > 0)
        #expect(summary.rmsSummary.count == chunks.count)
        #expect(summary.energySummary.count == chunks.count)
        #expect(summary.briefText.contains("snore"))
    }

    @Test
    func replaySummaryKeepsQuietInputAsRejectDiagnosticsWithoutAudioPersistence() {
        let chunks = SyntheticAudioSource.makeChunks(
            pattern: .silence,
            duration: 3,
            sampleRate: 16_000,
            chunkDuration: 1,
            startedAt: Date(timeIntervalSince1970: 43_000)
        )
        let analyzer = DetectorTuningProfile.balanced.configuration.makeSleepAnalyzer()

        let summary = analyzer.makeReplayDetectionSummary(
            label: "recent-audio-debug-preview",
            chunks: chunks,
            thresholdsSnapshot: DetectorTuningProfile.balanced.configuration.thresholdSnapshot
        )

        #expect(summary.chunkCount == chunks.count)
        #expect(summary.rawCandidateCount == 0)
        #expect(summary.finalEventCount == 0)
        #expect(summary.rejectedCountByReason[.likelySilence, default: 0] > 0)
        #expect(summary.rejectedCountByReason[.belowRmsThreshold, default: 0] > 0)
        #expect(summary.rejectedCountByReason[.belowEnergyThreshold, default: 0] > 0)
    }
}
