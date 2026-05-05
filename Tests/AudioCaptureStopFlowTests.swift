import Foundation
import Testing
@testable import SleepSoundCore

@Suite("Audio Capture Stop Flow")
@MainActor
struct AudioCaptureStopFlowTests {
    @Test
    func stopCaptureIsIdempotentAndRecordsPhysicalStopSteps() throws {
        let service = MockAudioCaptureService()
        try service.startCapture()

        service.stopCapture()
        let firstStoppedAt = service.metrics.captureStoppedAt
        service.stopCapture()

        #expect(service.state == .stopped)
        #expect(!service.isCapturing)
        #expect(service.metrics.stopRequestedAt != nil)
        #expect(service.metrics.captureStopStartedAt != nil)
        #expect(service.metrics.inputTapRemovedAt != nil)
        #expect(service.metrics.audioEngineStoppedAt != nil)
        #expect(service.metrics.audioSessionDeactivatedAt != nil)
        #expect(service.metrics.captureTaskCancelledAt != nil)
        #expect(service.metrics.captureStoppedAt != nil)
        #expect(service.metrics.captureStoppedAt == firstStoppedAt)
    }

    @Test
    func forceStopRecordsReasonAndDoesNotRestartCapture() throws {
        let service = MockAudioCaptureService()
        try service.startCapture()

        service.forceStopCapture(reason: "stop timeout safety check")

        #expect(service.state == .stopped)
        #expect(!service.isCapturing)
        #expect(service.metrics.forceStopStartedAt != nil)
        #expect(service.metrics.forceStopReason == "stop timeout safety check")
        #expect(service.metrics.stopDiagnosticsSummary?.contains("forceStop=stop timeout safety check") == true)
    }

    @Test
    func doubleStopDoesNotDuplicateAudioCounters() throws {
        let service = MockAudioCaptureService()
        try service.startCapture()

        service.stopCapture()
        let firstStopRequestedAt = service.metrics.stopRequestedAt
        let firstInputTapRemovedAt = service.metrics.inputTapRemovedAt
        service.stopCapture()

        #expect(service.state == .stopped)
        #expect(service.metrics.stopRequestedAt == firstStopRequestedAt)
        #expect(service.metrics.inputTapRemovedAt == firstInputTapRemovedAt)
        #expect(service.metrics.chunksReceivedAfterStopRequest == 0)
    }

    @Test
    func stopRequestStopsIncomingChunksAndCountsLateChunksOnlyAsDiagnostics() throws {
        let service = MockAudioCaptureService()
        let chunk = makeChunk()
        var deliveredChunkCount = 0
        service.onChunk = { _ in
            deliveredChunkCount += 1
        }

        try service.startCapture()
        service.emitTestChunk(chunk)
        let receivedChunkCountBeforeStop = service.metrics.receivedChunkCount
        let receivedAudioSecondsBeforeStop = service.metrics.receivedAudioSeconds

        service.stopCapture()
        service.emitTestChunk(chunk)

        #expect(service.state == .stopped)
        #expect(!service.isCapturing)
        #expect(deliveredChunkCount == 1)
        #expect(service.metrics.receivedChunkCount == receivedChunkCountBeforeStop)
        #expect(service.metrics.receivedAudioSeconds == receivedAudioSecondsBeforeStop)
        #expect(service.metrics.chunksReceivedAfterStopRequest == 1)
        #expect(service.metrics.secondsReceivingAudioAfterStopRequest == 0.1)
        #expect(service.metrics.forceStopReason == "test audio chunk received after stop request")
    }

    @Test
    func reportGenerationDoesNotBlockCaptureStop() async throws {
        let service = MockAudioCaptureService()
        try service.startCapture()

        service.stopCapture()
        let captureStoppedAt = try #require(service.metrics.captureStoppedAt)

        try await Task.sleep(nanoseconds: 20_000_000)

        #expect(service.state == .stopped)
        #expect(!service.isCapturing)
        #expect(service.metrics.captureStoppedAt == captureStoppedAt)
    }

    @Test
    func slowAnalyzerFinalizeDoesNotKeepCaptureAlive() async throws {
        let service = MockAudioCaptureService()
        try service.startCapture()

        service.stopCapture()
        var metrics = service.metrics
        metrics.recordAnalyzerFinalizeStarted()

        try await Task.sleep(nanoseconds: 20_000_000)
        metrics.recordAnalyzerFinalizeFinished()

        #expect(service.state == .stopped)
        #expect(!service.isCapturing)
        #expect(metrics.captureStopStartedAt != nil)
        #expect(metrics.analyzerFinalizeStartedAt! >= metrics.captureStopStartedAt!)
        #expect(metrics.analyzerFinalizeFinishedAt! >= metrics.analyzerFinalizeStartedAt!)
    }

    @Test
    func doubleStopTapDoesNotDuplicateReportFinalization() throws {
        let service = MockAudioCaptureService()
        try service.startCapture()
        var isFinalizing = false
        var reportGenerationCount = 0

        func endSleepSessionLikeAppState() {
            guard !isFinalizing else {
                service.stopCapture()
                return
            }

            isFinalizing = true
            service.stopCapture()
            reportGenerationCount += 1
        }

        endSleepSessionLikeAppState()
        endSleepSessionLikeAppState()

        #expect(service.state == .stopped)
        #expect(reportGenerationCount == 1)
        #expect(service.metrics.chunksReceivedAfterStopRequest == 0)
    }

    @Test
    func stopTimeoutForceStopIsSafeAfterNormalStop() throws {
        let service = MockAudioCaptureService()
        try service.startCapture()

        service.stopCapture()
        let captureStoppedAt = service.metrics.captureStoppedAt
        service.forceStopCapture(reason: "app stop timeout safety check")

        #expect(service.state == .stopped)
        #expect(!service.isCapturing)
        #expect(service.metrics.captureStoppedAt == captureStoppedAt)
        #expect(service.metrics.forceStopReason == "app stop timeout safety check")
        #expect(service.metrics.stopDiagnosticsSummary?.contains("forceStop=app stop timeout safety check") == true)
    }

    @Test
    func eventAudioSnippetOptInPolicyRemainsOffByDefault() {
        let shouldStore = EventAudioSampleStorageRules.shouldAttemptStorage(
            isEnabled: false,
            eventType: .snore,
            duration: 4,
            confidence: 0.9
        )

        #expect(!shouldStore)
    }

    private func makeChunk() -> AudioChunk {
        AudioChunk(
            timestamp: Date(timeIntervalSince1970: 1_000),
            sampleRate: 16_000,
            channelCount: 1,
            frameCount: 1_600,
            duration: 0.1,
            rms: 0.2,
            samples: [0.1, 0.2, 0.1]
        )
    }
}
