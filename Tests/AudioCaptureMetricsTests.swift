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
    func firstInputDelayContributesToCoverageDiagnostics() {
        let startedAt = Date(timeIntervalSince1970: 100)
        var metrics = AudioCaptureMetrics()
        metrics.start(at: startedAt)

        metrics.recordReceived(
            chunk: makeChunk(frameCount: 4_800, sampleRate: 48_000),
            at: startedAt.addingTimeInterval(5.1)
        )
        let snapshot = metrics.snapshot(at: startedAt.addingTimeInterval(10))

        #expect(abs(metrics.firstAudioInputDelaySeconds - 5.0) < 0.0001)
        #expect(snapshot.missingAudioSeconds > 9)
        #expect(snapshot.coverageDiagnosticsSummary.contains("firstInputDelay=5.00s"))
        #expect(snapshot.coverageDiagnosticsSummary.contains("missing="))
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

    @Test
    func stopLifecycleDiagnosticsCaptureTeardownAndFinalizationOrder() {
        let startedAt = Date(timeIntervalSince1970: 100)
        var metrics = AudioCaptureMetrics()
        metrics.start(at: startedAt)

        metrics.recordStopButtonTapped(at: startedAt.addingTimeInterval(10.0))
        metrics.recordCaptureStopStarted(at: startedAt.addingTimeInterval(10.1))
        metrics.recordInputTapRemoved(at: startedAt.addingTimeInterval(10.2))
        metrics.recordAudioEngineStopped(at: startedAt.addingTimeInterval(10.3))
        metrics.recordAudioSessionDeactivated(at: startedAt.addingTimeInterval(10.4))
        metrics.recordCaptureTaskCancelled(at: startedAt.addingTimeInterval(10.5))
        metrics.stop(at: startedAt.addingTimeInterval(10.6))
        metrics.recordAnalyzerFinalizeStarted(at: startedAt.addingTimeInterval(10.7))
        metrics.recordAnalyzerFinalizeFinished(at: startedAt.addingTimeInterval(12.0))
        metrics.recordReportGenerationStarted(at: startedAt.addingTimeInterval(12.1))
        metrics.recordReportGenerationFinished(at: startedAt.addingTimeInterval(12.2))

        #expect(metrics.stopButtonTappedAt == startedAt.addingTimeInterval(10.0))
        #expect(metrics.stopRequestedAt == startedAt.addingTimeInterval(10.0))
        #expect(metrics.inputTapRemovedAt != nil)
        #expect(metrics.audioEngineStoppedAt != nil)
        #expect(metrics.audioSessionDeactivatedAt != nil)
        #expect(metrics.captureTaskCancelledAt != nil)
        #expect(metrics.analyzerFinalizeStartedAt != nil)
        #expect(metrics.analyzerFinalizeFinishedAt != nil)
        #expect(metrics.reportGenerationStartedAt != nil)
        #expect(metrics.reportGenerationFinishedAt != nil)
        #expect(metrics.stopDiagnosticsSummary?.contains("postStopChunks=0") == true)
    }

    @Test
    func postStopAudioIsCountedSeparatelyFromReceivedAudio() {
        let startedAt = Date(timeIntervalSince1970: 100)
        var metrics = AudioCaptureMetrics()
        metrics.start(at: startedAt)
        metrics.recordReceived(
            chunk: makeChunk(frameCount: 4_800, sampleRate: 48_000),
            at: startedAt.addingTimeInterval(1)
        )
        metrics.recordStopRequested(at: startedAt.addingTimeInterval(2))

        metrics.recordReceivedAfterStopRequest(
            chunk: makeChunk(frameCount: 9_600, sampleRate: 48_000),
            at: startedAt.addingTimeInterval(3)
        )

        #expect(metrics.receivedChunkCount == 1)
        #expect(abs(metrics.receivedAudioSeconds - 0.1) < 0.0001)
        #expect(metrics.chunksReceivedAfterStopRequest == 1)
        #expect(abs(metrics.secondsReceivingAudioAfterStopRequest - 0.2) < 0.0001)
        #expect(metrics.lastChunkReceivedAt == startedAt.addingTimeInterval(3))
    }

    @Test
    func mergeStopDiagnosticsPreservesAnalysisCounters() {
        let startedAt = Date(timeIntervalSince1970: 100)
        var appMetrics = AudioCaptureMetrics()
        appMetrics.start(at: startedAt)
        let chunk = makeChunk(frameCount: 4_800, sampleRate: 48_000)
        appMetrics.recordReceived(chunk: chunk, at: startedAt.addingTimeInterval(1))
        appMetrics.recordAnalyzed(chunk: chunk, at: startedAt.addingTimeInterval(1.1))

        var serviceMetrics = AudioCaptureMetrics()
        serviceMetrics.start(at: startedAt)
        serviceMetrics.recordStopRequested(at: startedAt.addingTimeInterval(2))
        serviceMetrics.recordInputTapRemoved(at: startedAt.addingTimeInterval(2.1))
        serviceMetrics.recordAudioEngineStopped(at: startedAt.addingTimeInterval(2.2))
        serviceMetrics.recordReceivedAfterStopRequest(
            chunk: makeChunk(frameCount: 2_400, sampleRate: 48_000),
            at: startedAt.addingTimeInterval(2.3)
        )
        serviceMetrics.recordForceStop(reason: "timeout", at: startedAt.addingTimeInterval(2.4))

        appMetrics.mergeStopDiagnostics(from: serviceMetrics)

        #expect(appMetrics.receivedChunkCount == 1)
        #expect(appMetrics.analyzedChunkCount == 1)
        #expect(appMetrics.inputTapRemovedAt == startedAt.addingTimeInterval(2.1))
        #expect(appMetrics.audioEngineStoppedAt == startedAt.addingTimeInterval(2.2))
        #expect(appMetrics.chunksReceivedAfterStopRequest == 1)
        #expect(appMetrics.forceStopReason == "timeout")
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
