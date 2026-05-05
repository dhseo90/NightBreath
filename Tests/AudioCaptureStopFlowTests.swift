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
        #expect(service.metrics.captureStoppedAt! >= firstStoppedAt!)
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
}
