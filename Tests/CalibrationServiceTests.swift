import Foundation
import Testing
@testable import SleepSoundCore

@Suite("CalibrationService")
struct CalibrationServiceTests {
    @Test
    func goodCalibrationCalculatesBaselineAndCoverage() {
        let service = CalibrationService(targetDuration: 30)
        let chunks = makeChunks(count: 30, rms: 0.010)

        let result = service.evaluate(chunks: chunks)

        #expect(result.inputReceived)
        #expect(result.receivedAudioSeconds == 30)
        #expect(result.audioCoverageRatio == 1)
        #expect(result.ambientNoiseBaseline == 0.010)
        #expect(result.calibrationQuality == .good)
    }

    @Test
    func lowInputCalibrationReturnsWeakInput() {
        let service = CalibrationService(targetDuration: 30)
        let chunks = makeChunks(count: 30, rms: 0.0025)

        let result = service.evaluate(chunks: chunks)

        #expect(result.calibrationQuality == .weakInput)
        #expect(result.recommendedPlacementMessage.contains("가까이"))
    }

    @Test
    func highNoiseCalibrationReturnsHighNoise() {
        let service = CalibrationService(targetDuration: 30)
        let chunks = makeChunks(count: 30, rms: 0.25)

        let result = service.evaluate(chunks: chunks)

        #expect(result.calibrationQuality == .highNoise)
        #expect(result.recommendedPlacementMessage.contains("소음원"))
    }

    @Test
    func blockedMicrophoneLikeCalibrationReturnsBlockedWarning() {
        let service = CalibrationService(targetDuration: 30)
        let chunks = makeChunks(count: 30, rms: 0.0005)

        let result = service.evaluate(chunks: chunks)

        #expect(result.calibrationQuality == .microphonePossiblyBlocked)
        #expect(result.recommendedPlacementMessage.contains("마이크"))
    }

    @Test
    func missingAudioReturnsRetryRecommended() {
        let service = CalibrationService(targetDuration: 30)

        let result = service.evaluate(chunks: [])

        #expect(result.inputReceived == false)
        #expect(result.calibrationQuality == .retryRecommended)
    }

    @Test
    func simulatorMockCalibrationUsesSyntheticAudioAndCompletes() {
        let chunks = CalibrationService.simulatorMockChunks(duration: 30)
        let result = CalibrationService.simulatorMockResult(duration: 30)

        #expect(chunks.count == 30)
        #expect(result.inputReceived)
        #expect(result.audioCoverageRatio == 1)
        #expect(result.calibrationQuality == .good)
    }

    private func makeChunks(count: Int, rms: Double, duration: TimeInterval = 1) -> [AudioChunk] {
        (0..<count).map { index in
            AudioChunk(
                timestamp: Date(timeIntervalSince1970: TimeInterval(index)),
                sampleRate: 16_000,
                channelCount: 1,
                frameCount: Int(16_000 * duration),
                duration: duration,
                rms: rms
            )
        }
    }
}
