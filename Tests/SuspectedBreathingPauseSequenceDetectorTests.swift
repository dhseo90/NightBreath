import Foundation
import Testing
@testable import SleepSoundCore

@Suite("SuspectedBreathingPauseSequenceDetector")
struct SuspectedBreathingPauseSequenceDetectorTests {
    @Test
    func lowActivityShorterThanMinimumDoesNotCreateEvent() {
        let detector = SuspectedBreathingPauseSequenceDetector(minimumLowActivityDuration: 10)
        let result = detector.detect(
            features: lowActivityFeatures(duration: 9),
            contextOutputs: []
        )

        #expect(result.outputs.isEmpty)
        #expect(result.summary.lowActivityObservedCount == 1)
        #expect(result.summary.lowActivityCandidateCount == 0)
        #expect(result.summary.pauseCandidatesRejectedByDuration == 1)
    }

    @Test
    func pureSilenceLowActivityDoesNotCreateCandidate() {
        let detector = SuspectedBreathingPauseSequenceDetector(minimumLowActivityDuration: 10)
        let result = detector.detect(
            features: lowActivityFeatures(duration: 12),
            contextOutputs: []
        )

        #expect(result.outputs.isEmpty)
        #expect(result.summary.lowActivityObservedCount == 1)
        #expect(result.summary.lowActivityCandidateCount == 0)
        #expect(result.summary.pauseCandidatesRejectedByInsufficientContext == 1)
        #expect(result.summary.pauseCandidatesRejectedByLikelySilence == 1)
        #expect(result.summary.latestPauseCandidateRejectedReason?.contains("likelySilenceOnly") == true)
    }

    @Test
    func fiveHourContinuousLowActivityFinalizesQuickly() {
        let detector = SuspectedBreathingPauseSequenceDetector(minimumLowActivityDuration: 10)
        let features = lowActivityFeatures(duration: 18_000)
        let startedAt = Date()

        let result = detector.detect(features: features, contextOutputs: [])
        let elapsed = Date().timeIntervalSince(startedAt)

        #expect(result.outputs.isEmpty)
        #expect(result.summary.lowActivityObservedCount == 1)
        #expect(result.summary.lowActivityDurationTotal == 18_000)
        #expect(result.summary.pauseCandidatesRejectedByInsufficientContext == 1)
        #expect(elapsed < 1.5)
    }

    @Test
    func priorContextLowActivityAndRecoveryCreatesCandidate() throws {
        let detector = SuspectedBreathingPauseSequenceDetector(minimumLowActivityDuration: 10)
        let result = detector.detect(
            features: sequenceFeatures(includeRecoveryActivity: true),
            contextOutputs: [
                makeOutput(.snore, start: baseDate.addingTimeInterval(0.4), duration: 1.2, confidence: 0.72),
                makeOutput(.gaspLike, start: baseDate.addingTimeInterval(15.4), duration: 1, confidence: 0.70)
            ]
        )
        let output = try #require(result.outputs.first)

        #expect(output.eventType == .breathingPauseSuspected)
        #expect(output.duration == 12)
        #expect(output.confidence >= 0.35)
        #expect(output.debugReason?.contains("gasp-like 회복 호흡") == true)
        #expect(result.summary.lowActivityObservedCount == 1)
        #expect(result.summary.lowActivityCandidateCount == 1)
        #expect(result.summary.recoveryPatternCount == 1)
    }

    @Test
    func gaspLikeRecoveryRaisesConfidence() throws {
        let detector = SuspectedBreathingPauseSequenceDetector(minimumLowActivityDuration: 10)
        let features = sequenceFeatures(includeRecoveryActivity: true)
        let noRecovery = try #require(detector.detect(
            features: features,
            contextOutputs: [
                makeOutput(.snore, start: baseDate.addingTimeInterval(0.4), duration: 1.2, confidence: 0.72)
            ]
        ).outputs.first)
        let gaspOutput = makeOutput(
            .gaspLike,
            start: baseDate.addingTimeInterval(15.5),
            duration: 1,
            confidence: 0.70
        )
        let withRecoveryResult = detector.detect(
            features: features,
            contextOutputs: [
                makeOutput(.snore, start: baseDate.addingTimeInterval(0.4), duration: 1.2, confidence: 0.72),
                gaspOutput
            ]
        )
        let withRecovery = try #require(withRecoveryResult.outputs.first)

        #expect(withRecovery.confidence > noRecovery.confidence)
        #expect(withRecoveryResult.summary.recoveryPatternCount == 1)
        #expect(withRecoveryResult.summary.pauseCandidatesPromotedByGasp == 1)
    }

    @Test
    func environmentalNoiseLowersCandidateConfidence() throws {
        let detector = SuspectedBreathingPauseSequenceDetector(minimumLowActivityDuration: 10)
        let clean = try #require(detector.detect(
            features: sequenceFeatures(includeRecoveryActivity: true),
            contextOutputs: [
                makeOutput(.snore, start: baseDate.addingTimeInterval(0.4), duration: 1.2, confidence: 0.72)
            ]
        ).outputs.first)
        let noisyResult = detector.detect(
            features: sequenceFeatures(includeRecoveryActivity: true),
            contextOutputs: [
                makeOutput(.snore, start: baseDate.addingTimeInterval(0.4), duration: 1.2, confidence: 0.72),
                makeOutput(.environmentalNoise, start: baseDate.addingTimeInterval(1), duration: 5, confidence: 0.80)
            ]
        )
        let noisy = try #require(noisyResult.outputs.first)

        #expect(noisy.confidence < clean.confidence)
        #expect(noisyResult.summary.lowActivityCandidateCount == 1)
    }

    @Test
    func movementOverlapLowersCandidateConfidence() throws {
        let detector = SuspectedBreathingPauseSequenceDetector(minimumLowActivityDuration: 10)
        let clean = try #require(detector.detect(
            features: sequenceFeatures(includeRecoveryActivity: true),
            contextOutputs: [
                makeOutput(.snore, start: baseDate.addingTimeInterval(0.4), duration: 1.2, confidence: 0.72)
            ]
        ).outputs.first)
        let withMovement = try #require(detector.detect(
            features: sequenceFeatures(includeRecoveryActivity: true),
            contextOutputs: [
                makeOutput(.snore, start: baseDate.addingTimeInterval(0.4), duration: 1.2, confidence: 0.72),
                makeOutput(.movementLike, start: baseDate.addingTimeInterval(4), duration: 3, confidence: 0.75, intensity: 0.70)
            ]
        ).outputs.first)

        #expect(withMovement.confidence < clean.confidence)
        #expect(withMovement.debugReason?.contains("움직임 의심 소리") == true)
    }

    @Test
    func priorContextWithoutRecoveryDoesNotCreateCandidate() {
        let detector = SuspectedBreathingPauseSequenceDetector(minimumLowActivityDuration: 10)
        let result = detector.detect(
            features: sequenceFeatures(includeRecoveryActivity: false),
            contextOutputs: [
                makeOutput(.snore, start: baseDate.addingTimeInterval(0.4), duration: 1.2, confidence: 0.72)
            ]
        )

        #expect(result.outputs.isEmpty)
        #expect(result.summary.lowActivityObservedCount == 1)
        #expect(result.summary.lowActivityCandidateCount == 0)
        #expect(result.summary.pauseCandidatesRejectedByNoRecovery == 1)
        #expect(result.summary.latestPauseCandidateRejectedReason?.contains("noRecoveryPattern") == true)
    }

    @Test
    func newSequenceFilesAvoidClinicalMetricAbbreviation() throws {
        let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        let paths = [
            "SleepSoundApp/Core/Analysis/BreathingActivityEstimator.swift",
            "SleepSoundApp/Core/Analysis/SuspectedBreathingPauseSequenceDetector.swift",
            "SleepSoundApp/Features/Sleep/SleepReportView.swift",
            "SleepSoundApp/Features/Settings/DetectorTuningView.swift",
            "Docs/SUSPECTED_BREATHING_PAUSE.md"
        ]
        let forbidden = "A" + "HI"

        for path in paths {
            let url = root.appendingPathComponent(path)
            guard FileManager.default.fileExists(atPath: url.path) else { continue }
            let contents = try String(contentsOf: url, encoding: .utf8)
            #expect(!contents.contains(forbidden))
        }
    }

    private var baseDate: Date {
        Date(timeIntervalSince1970: 1_772_000_000)
    }

    private func lowActivityFeatures(
        duration: Int,
        estimatedNoiseLevel: Double = 0.002,
        startOffset: Int = 0
    ) -> [AudioFeatures] {
        (0..<duration).map { offset in
            AudioFeatures(
                startedAt: baseDate.addingTimeInterval(TimeInterval(startOffset + offset)),
                duration: 1,
                rms: 0.002,
                peak: 0.004,
                zeroCrossingRate: 0.02,
                lowFrequencyEnergyRatio: 0.05,
                spectralCentroid: 120,
                lowBandEnergy: 0.05,
                midBandEnergy: 0.03,
                highBandEnergy: 0.02,
                estimatedNoiseLevel: estimatedNoiseLevel,
                isLikelySilence: true
            )
        }
    }

    private func breathingActivityFeatures(
        startOffset: Int,
        duration: Int
    ) -> [AudioFeatures] {
        (0..<duration).map { offset in
            AudioFeatures(
                startedAt: baseDate.addingTimeInterval(TimeInterval(startOffset + offset)),
                duration: 1,
                rms: 0.045,
                peak: 0.090,
                zeroCrossingRate: 0.08,
                lowFrequencyEnergyRatio: 0.48,
                spectralCentroid: 180,
                lowBandEnergy: 0.48,
                midBandEnergy: 0.32,
                highBandEnergy: 0.12,
                estimatedNoiseLevel: 0.010,
                isLikelySilence: false
            )
        }
    }

    private func sequenceFeatures(includeRecoveryActivity: Bool) -> [AudioFeatures] {
        breathingActivityFeatures(startOffset: 0, duration: 3) +
            lowActivityFeatures(duration: 12, startOffset: 3) +
            (includeRecoveryActivity ? breathingActivityFeatures(startOffset: 15, duration: 2) : [])
    }

    private func makeOutput(
        _ type: SleepEventType,
        start: Date,
        duration: TimeInterval,
        confidence: Double,
        intensity: Double = 0.50
    ) -> DetectorOutput {
        DetectorOutput(
            eventType: type,
            startedAt: start,
            endedAt: start.addingTimeInterval(duration),
            confidence: confidence,
            intensity: intensity,
            debugReason: "test"
        )
    }
}
