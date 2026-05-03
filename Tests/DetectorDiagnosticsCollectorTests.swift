import Foundation
import Testing
@testable import SleepSoundCore

@Suite("DetectorDiagnosticsCollector")
struct DetectorDiagnosticsCollectorTests {
    @Test
    func summaryStatsCalculatesPercentiles() {
        let stats = SummaryStats.make(values: [1, 2, 3, 4, 5])

        #expect(stats.count == 5)
        #expect(stats.min == 1)
        #expect(stats.max == 5)
        #expect(stats.mean == 3)
        #expect(stats.p50 == 3)
        #expect(stats.p90 == 4.6)
        #expect(stats.p95 == 4.8)
        #expect(stats.p99 == 4.96)
    }

    @Test
    func collectorRecordsFeatureSummariesAndRejectReasons() throws {
        let collector = makeCollector()
        let quietFeatures = makeFeatures(rms: 0.001, energy: 0.000001, startedAt: Date(timeIntervalSince1970: 10))

        collector.record(features: quietFeatures, outputs: [])
        let diagnostics = try finalized(collector)

        #expect(diagnostics.analyzedChunkCount == 1)
        #expect(diagnostics.rawCandidateCount == 0)
        #expect(diagnostics.rmsSummary.p90 == 0.001)
        #expect(diagnostics.energySummary.p90 == 0.000001)
        #expect(diagnostics.rejectedCountByReason[.likelySilence] == 1)
        #expect(diagnostics.rejectedCountByReason[.belowRmsThreshold] == 1)
        #expect(diagnostics.rejectedCountByReason[.belowEnergyThreshold] == 1)
    }

    @Test
    func collectorRecordsRawCandidatesAndConfidenceHistogram() throws {
        let collector = makeCollector()
        let features = makeFeatures(rms: 0.08, energy: 0.0064, startedAt: Date(timeIntervalSince1970: 20))
        let output = DetectorOutput(
            eventType: .snore,
            startedAt: features.startedAt,
            endedAt: features.endedAt,
            confidence: 0.72,
            intensity: 0.5,
            debugReason: "test"
        )

        collector.record(features: features, outputs: [output])
        let diagnostics = try finalized(collector)

        #expect(diagnostics.rawCandidateCount == 1)
        #expect(diagnostics.rawCandidateCountByType[.snore] == 1)
        #expect(diagnostics.confidenceHistogram["0.6-0.8"] == 1)
    }

    @Test
    func smoothingDiagnosticsCountsBeforeAfterAndReasons() {
        let policy = DetectionSmoothingPolicy(
            minimumEventDuration: 0.5,
            maximumMergeGap: 1.0,
            confidenceThreshold: 0.35
        )
        let start = Date(timeIntervalSince1970: 30)
        let outputs = [
            makeOutput(type: .coughLike, start: start, duration: 0.2, confidence: 0.8),
            makeOutput(type: .snore, start: start.addingTimeInterval(1.0), duration: 0.8, confidence: 0.8),
            makeOutput(type: .snore, start: start.addingTimeInterval(1.5), duration: 0.7, confidence: 0.7),
            makeOutput(type: .coughLike, start: start.addingTimeInterval(4.0), duration: 1.0, confidence: 0.2)
        ]

        let result = policy.applyWithDiagnostics(to: outputs)

        #expect(result.diagnostics.preSmoothingCandidateCount == 4)
        #expect(result.outputs.count == 1)
        #expect(result.diagnostics.postSmoothingEventCount == 1)
        #expect(result.diagnostics.rejectedCountByReason[.tooShort] == 1)
        #expect(result.diagnostics.rejectedCountByReason[.belowConfidenceThreshold] == 1)
        #expect(result.diagnostics.rejectedCountByReason[.mergedIntoNearbyEvent] == 1)
    }

    @Test
    func zeroEventDiagnosticsExplainNoFinalEvents() throws {
        let collector = makeCollector()
        let features = makeFeatures(rms: 0.001, energy: 0.000001, startedAt: Date(timeIntervalSince1970: 40))

        collector.record(features: features, outputs: [])
        collector.record(smoothingDiagnostics: DetectionSmoothingDiagnostics(
            preSmoothingCandidateCount: 0,
            postSmoothingEventCount: 0
        ))
        collector.record(finalEvents: [])

        let diagnostics = try finalized(collector)

        #expect(diagnostics.summaryTextForZeroEvents == "오디오 입력은 수신되었지만 detector 기준을 통과한 raw 후보가 없었습니다.")
    }

    @Test
    func modelFallbackCountIsRecorded() throws {
        let collector = makeCollector(backend: .hybrid, modelInstalled: false)
        let features = makeFeatures(rms: 0.08, energy: 0.0064, startedAt: Date(timeIntervalSince1970: 50))

        collector.recordModelFallbackIfNeeded(backend: .hybrid, modelInstalled: false)
        collector.record(features: features, outputs: [])

        let diagnostics = try finalized(collector)

        #expect(diagnostics.modelFallbackCount == 1)
        #expect(diagnostics.rejectedCountByReason[.modelUnavailable] == 1)
    }

    @Test
    func collectorRecordsBreathingPauseSequenceSummary() throws {
        let collector = makeCollector()
        let start = Date(timeIntervalSince1970: 70)
        let output = DetectorOutput(
            eventType: .breathingPauseSuspected,
            startedAt: start,
            endedAt: start.addingTimeInterval(12),
            confidence: 0.62,
            intensity: 0.20,
            debugReason: "sequence test"
        )
        let summary = SuspectedBreathingPauseSequenceSummary(
            lowActivityObservedCount: 4,
            lowActivityDurationTotal: 31,
            lowActivityCandidateCount: 2,
            noiseContaminatedLowActivityCount: 1,
            recoveryPatternCount: 1,
            pauseCandidatesRejectedByNoise: 1,
            pauseCandidatesRejectedByDuration: 3,
            pauseCandidatesRejectedByNoRecovery: 2,
            pauseCandidatesRejectedByInsufficientContext: 1,
            pauseCandidatesRejectedByLikelySilence: 1,
            pauseCandidatesPromotedByGasp: 1,
            latestBreathingActivityScore: 0.10,
            latestLowActivityDurationSeconds: 12,
            latestRecoveryPatternDetected: true,
            latestPauseCandidateConfidence: 0.62,
            latestPauseCandidateRejectedReason: nil
        )

        collector.record(sequenceResult: SuspectedBreathingPauseSequenceResult(
            outputs: [output],
            summary: summary
        ))
        let diagnostics = try finalized(collector)

        #expect(diagnostics.rawCandidateCountByType[.breathingPauseSuspected] == 1)
        #expect(diagnostics.lowActivityObservedCount == 4)
        #expect(diagnostics.lowActivityDurationTotal == 31)
        #expect(diagnostics.lowActivityCandidateCount == 2)
        #expect(diagnostics.noiseContaminatedLowActivityCount == 1)
        #expect(diagnostics.recoveryPatternCount == 1)
        #expect(diagnostics.pauseCandidatesRejectedByNoise == 1)
        #expect(diagnostics.pauseCandidatesRejectedByDuration == 3)
        #expect(diagnostics.pauseCandidatesRejectedByNoRecovery == 2)
        #expect(diagnostics.pauseCandidatesRejectedByInsufficientContext == 1)
        #expect(diagnostics.pauseCandidatesRejectedByLikelySilence == 1)
        #expect(diagnostics.pauseCandidatesPromotedByGasp == 1)
        #expect(diagnostics.latestRecoveryPatternDetected == true)
        #expect(diagnostics.latestPauseCandidateConfidence == 0.62)
        #expect(diagnostics.rejectedCountByReason[.tooShort] == 3)
        #expect(diagnostics.rejectedCountByReason[.likelyEnvironmentalNoise] == 1)
        #expect(diagnostics.rejectedCountByReason[.noiseContaminated] == 1)
        #expect(diagnostics.rejectedCountByReason[.noRecoveryPattern] == 2)
        #expect(diagnostics.rejectedCountByReason[.insufficientBreathingContext] == 1)
        #expect(diagnostics.rejectedCountByReason[.likelySilenceOnly] == 1)
    }

    private func makeCollector(
        backend: SleepDetectionBackend = .ruleBased,
        modelInstalled: Bool = false
    ) -> DetectorDiagnosticsCollector {
        let collector = DetectorDiagnosticsCollector()
        collector.reset(
            sessionId: UUID(),
            startedAt: Date(timeIntervalSince1970: 0),
            detectorBackend: backend.displayName,
            modelInstalled: modelInstalled,
            thresholdsSnapshot: [
                "rule.silenceRMS": 0.01,
                "rule.snoreRMS": 0.05,
                "smoothing.confidenceThreshold": 0.35
            ],
            eventAudioSampleStorageEnabled: false
        )
        return collector
    }

    private func finalized(_ collector: DetectorDiagnosticsCollector) throws -> DetectorDiagnostics {
        try #require(collector.finalize(
            endedAt: Date(timeIntervalSince1970: 60),
            metrics: AudioCaptureMetrics(
                captureStartedAt: Date(timeIntervalSince1970: 0),
                captureStoppedAt: Date(timeIntervalSince1970: 60),
                receivedAudioSeconds: 60,
                analyzedAudioSeconds: 60,
                receivedChunkCount: 60,
                analyzedChunkCount: 60
            )
        ))
    }

    private func makeFeatures(
        rms: Double,
        energy: Double,
        startedAt: Date
    ) -> AudioFeatures {
        AudioFeatures(
            startedAt: startedAt,
            duration: 1.0,
            sampleRate: 16_000,
            channelCount: 1,
            frameCount: 16_000,
            rms: rms,
            energy: energy,
            peak: max(rms * 2, rms),
            zeroCrossingRate: 0.2,
            lowFrequencyEnergyRatio: 0.4,
            spectralCentroid: 1_000,
            lowBandEnergy: 0.4,
            midBandEnergy: 0.4,
            highBandEnergy: 0.2,
            estimatedNoiseLevel: rms,
            isLikelySilence: rms < 0.01
        )
    }

    private func makeOutput(
        type: SleepEventType,
        start: Date,
        duration: TimeInterval,
        confidence: Double
    ) -> DetectorOutput {
        DetectorOutput(
            eventType: type,
            startedAt: start,
            endedAt: start.addingTimeInterval(duration),
            confidence: confidence,
            intensity: 0.5,
            debugReason: "test"
        )
    }
}
