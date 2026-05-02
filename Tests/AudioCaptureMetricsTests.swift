import Foundation
import Testing
@testable import SleepSoundCore

@Suite("AudioCaptureMetrics")
struct AudioCaptureMetricsTests {
    @Test
    func receivedAudioSecondsUsesFrameCountAndSampleRate() {
        let startedAt = Date(timeIntervalSince1970: 100)
        var metrics = AudioCaptureMetrics()
        metrics.start(at: startedAt)

        metrics.recordReceived(
            chunk: makeChunk(frameCount: 4_800, sampleRate: 48_000, duration: 9),
            at: startedAt.addingTimeInterval(1)
        )

        #expect(metrics.receivedChunkCount == 1)
        #expect(metrics.totalReceivedFrameCount == 4_800)
        #expect(abs(metrics.receivedAudioSeconds - 0.1) < 0.0001)
        #expect(metrics.sampleRate == 48_000)
    }

    @Test
    func audioCoverageRatioIsClampedToValidRange() {
        let startedAt = Date(timeIntervalSince1970: 100)
        var metrics = AudioCaptureMetrics()
        metrics.start(at: startedAt)

        metrics.recordReceived(
            chunk: makeChunk(frameCount: 48_000, sampleRate: 48_000, duration: 1),
            at: startedAt.addingTimeInterval(0.5)
        )

        let snapshot = metrics.snapshot(at: startedAt.addingTimeInterval(0.5))

        #expect(snapshot.audioCoverageRatio == 1)
        #expect(snapshot.measurementQuality == .excellent)
    }

    @Test
    func chunkGapTracksLongestInputGap() {
        let startedAt = Date(timeIntervalSince1970: 100)
        var metrics = AudioCaptureMetrics()
        metrics.start(at: startedAt)

        metrics.recordReceived(
            chunk: makeChunk(frameCount: 4_800, sampleRate: 48_000),
            at: startedAt
        )
        metrics.recordReceived(
            chunk: makeChunk(frameCount: 4_800, sampleRate: 48_000),
            at: startedAt.addingTimeInterval(1.1)
        )

        #expect(abs(metrics.longestChunkGapSeconds - 1.0) < 0.0001)
    }

    @Test
    func analyzedMetricsAreTrackedSeparatelyFromReceivedMetrics() {
        let startedAt = Date(timeIntervalSince1970: 100)
        var metrics = AudioCaptureMetrics()
        metrics.start(at: startedAt)

        let chunk = makeChunk(frameCount: 2_400, sampleRate: 48_000)
        metrics.recordReceived(chunk: chunk, at: startedAt.addingTimeInterval(1))
        metrics.recordAnalyzed(chunk: chunk, at: startedAt.addingTimeInterval(1.1))

        #expect(metrics.receivedChunkCount == 1)
        #expect(metrics.analyzedChunkCount == 1)
        #expect(abs(metrics.receivedAudioSeconds - 0.05) < 0.0001)
        #expect(abs(metrics.analyzedAudioSeconds - 0.05) < 0.0001)
        #expect(metrics.lastChunkAnalyzedAt != nil)
    }

    @Test(arguments: [
        (0.97, MeasurementQuality.excellent),
        (0.90, MeasurementQuality.good),
        (0.70, MeasurementQuality.limited),
        (0.30, MeasurementQuality.poor)
    ])
    func measurementQualityUsesCoverageBands(
        ratio: Double,
        expectedQuality: MeasurementQuality
    ) {
        #expect(MeasurementQuality.quality(for: ratio) == expectedQuality)
    }

    private func makeChunk(
        frameCount: Int,
        sampleRate: Double,
        duration: TimeInterval? = nil
    ) -> AudioChunk {
        AudioChunk(
            sampleRate: sampleRate,
            channelCount: 1,
            frameCount: frameCount,
            duration: duration ?? Double(frameCount) / sampleRate,
            rms: 0.2
        )
    }
}
