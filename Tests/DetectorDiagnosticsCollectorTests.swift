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

        #expect(diagnostics.audioChunkCount == 60)
        #expect(diagnostics.analyzedChunkCount == 1)
        #expect(diagnostics.rawCandidateCount == 0)
        #expect(diagnostics.rmsSummary.p90 == 0.001)
        #expect(diagnostics.energySummary.p90 == 0.000001)
        #expect(diagnostics.rmsMin == 0.001)
        #expect(diagnostics.energyMax == 0.000001)
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
        #expect(diagnostics.snoreRawCandidateCount == 1)
        #expect(diagnostics.snoreLikeFeatureCandidateCount == 1)
        #expect(diagnostics.snoreLikeFeatureRejectedCount == 0)
        #expect(diagnostics.confidenceHistogram["0.6-0.8"] == 1)
        #expect(diagnostics.latestRawCandidateDebugSummary?.contains("snore") == true)
    }

    @Test
    func collectorRecordsSnoreLikeFeatureNearMissBeforeRawCandidate() throws {
        let collector = makeCollector()
        let features = makeFeatures(
            rms: 0.045,
            energy: 0.0021,
            startedAt: Date(timeIntervalSince1970: 25),
            lowBandEnergy: 0.32
        )

        collector.record(features: features, outputs: [])
        collector.record(smoothingDiagnostics: DetectionSmoothingDiagnostics(
            preSmoothingCandidateCount: 0,
            postSmoothingEventCount: 0
        ))
        collector.record(finalEvents: [])

        let diagnostics = try finalized(collector)

        #expect(diagnostics.rawCandidateCount == 0)
        #expect(diagnostics.snoreLikeFeatureCandidateCount == 1)
        #expect(diagnostics.snoreLikeFeatureRejectedCount == 1)
        #expect(diagnostics.snoreLikeFeatureRejectReasonCounts[.belowRmsThreshold] == 1)
        #expect(diagnostics.snoreLikeFeatureRejectReasonCounts[.belowEnergyThreshold] == 1)
        #expect(diagnostics.snoreLikeFeatureRejectReasonCounts[.belowLowBandRatio] == 1)
        #expect(diagnostics.summaryTextForZeroEvents == "코골기처럼 보이는 feature 후보는 있었지만 raw 코골기 후보로 올라오지 않았습니다.")
        #expect(diagnostics.latestFeatureDebugSummary?.contains("rms") == true)
    }

    @Test
    func collectorKeepsDistantLowLevelSnoreNearMissVisibleBeforeRawCandidate() throws {
        let collector = makeCollector()
        let features = makeFeatures(
            rms: 0.029,
            energy: 0.00084,
            startedAt: Date(timeIntervalSince1970: 26),
            lowBandEnergy: 0.72,
            midBandEnergy: 0.20,
            highBandEnergy: 0.08,
            zeroCrossingRate: 0.08,
            spectralCentroid: 300,
            estimatedNoiseLevel: 0.029
        )

        collector.record(features: features, outputs: [])
        let diagnostics = try finalized(collector)

        #expect(diagnostics.rawCandidateCount == 0)
        #expect(diagnostics.snoreLikeFeatureCandidateCount == 1)
        #expect(diagnostics.snoreLikeFeatureRejectedCount == 1)
        #expect(diagnostics.snoreLikeFeatureRejectReasonCounts[.belowRmsThreshold] == 1)
        #expect(diagnostics.snoreLikeFeatureRejectReasonCounts[.belowEnergyThreshold] == 1)
        #expect(diagnostics.snoreLikeFeatureRejectReasonCounts[.belowLowBandRatio] == nil)
        #expect(diagnostics.snoreRejectReasonTop == .belowEnergyThreshold)
    }

    @Test
    func collectorDoesNotTreatBroadbandLowLevelNoiseAsSnoreNearMiss() throws {
        let collector = makeCollector()
        let features = makeFeatures(
            rms: 0.032,
            energy: 0.0010,
            startedAt: Date(timeIntervalSince1970: 27),
            lowBandEnergy: 0.35,
            midBandEnergy: 0.34,
            highBandEnergy: 0.31,
            zeroCrossingRate: 0.48,
            spectralCentroid: 2_400,
            estimatedNoiseLevel: 0.016
        )

        collector.record(features: features, outputs: [])
        let diagnostics = try finalized(collector)

        #expect(diagnostics.rawCandidateCount == 0)
        #expect(diagnostics.snoreLikeFeatureCandidateCount == 1)
        #expect(diagnostics.snoreLikeFeatureRejectReasonCounts[.likelyEnvironmentalNoise] == 1)
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
        #expect(result.diagnostics.preSmoothingCandidateCountByType[.snore] == 2)
        #expect(result.diagnostics.postSmoothingEventCountByType[.snore] == 1)
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

        #expect(diagnostics.summaryTextForZeroEvents == "오디오 입력은 수신되었지만 detector 기준을 통과한 raw 후보가 만들어지지 않았습니다.")
    }

    @Test
    func collectorPersistsTypeCountsSnoreRejectAndTuningProfile() throws {
        let collector = makeCollector()
        let start = Date(timeIntervalSince1970: 80)
        let snoreOutput = makeOutput(type: .snore, start: start, duration: 0.1, confidence: 0.20)

        collector.record(features: makeFeatures(rms: 0.06, energy: 0.0036, startedAt: start), outputs: [snoreOutput])
        collector.record(smoothingDiagnostics: DetectionSmoothingDiagnostics(
            preSmoothingCandidateCount: 1,
            postSmoothingEventCount: 0,
            preSmoothingCandidateCountByType: [.snore: 1],
            postSmoothingEventCountByType: [:],
            rejectedCountByReason: [.belowConfidenceThreshold: 1]
        ))
        collector.record(finalEvents: [])

        let diagnostics = try finalized(collector)
        let encoded = try JSONEncoder().encode(diagnostics)
        let decoded = try JSONDecoder().decode(DetectorDiagnostics.self, from: encoded)

        #expect(decoded.tuningProfile == DetectorTuningProfile.balanced.displayName)
        #expect(decoded.preSmoothingCandidateCountByType[.snore] == 1)
        #expect(decoded.postSmoothingEventCountByType[.snore] == nil)
        #expect(decoded.snoreRejectedCount == 1)
        #expect(decoded.snoreRejectReasonTop == .belowConfidenceThreshold)
        #expect(decoded.rejectedCountByReason[.smoothingDropped] == 1)
        #expect(decoded.rejectReasonCounts[.belowConfidenceThreshold] == 1)
    }

    @Test
    func legacyDiagnosticsDecodeDefaultsNewObservabilityFields() throws {
        let legacyJSON = """
        {
          "sessionId": "00000000-0000-0000-0000-000000000101",
          "startedAt": 0,
          "detectorBackend": "Rule-based",
          "modelInstalled": false,
          "analyzedChunkCount": 12,
          "receivedAudioSeconds": 12,
          "analyzedAudioSeconds": 12,
          "audioCoverageRatio": 1,
          "rawCandidateCount": 1,
          "rawCandidateCountByType": ["snore", 1],
          "preSmoothingCandidateCount": 1,
          "postSmoothingEventCount": 0,
          "finalEventCountByType": [],
          "rejectedCountByReason": ["belowConfidenceThreshold", 1],
          "confidenceHistogram": {},
          "eventAudioSampleStorageEnabled": false
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
        let diagnostics = try decoder.decode(DetectorDiagnostics.self, from: legacyJSON)

        #expect(diagnostics.audioChunkCount == 12)
        #expect(diagnostics.preSmoothingCandidateCountByType.isEmpty)
        #expect(diagnostics.postSmoothingEventCountByType.isEmpty)
        #expect(diagnostics.tuningProfile == nil)
        #expect(diagnostics.snoreRawCandidateCount == 1)
        #expect(diagnostics.snoreRejectedCount == 1)
        #expect(diagnostics.snoreLikeFeatureCandidateCount == 0)
        #expect(diagnostics.snoreLikeFeatureRejectedCount == 0)
        #expect(diagnostics.latestFeatureDebugSummary == nil)
    }

    @Test
    func inferredRejectReasonsIncludeLowBandForSnoreLikeScaleMismatch() {
        let features = makeFeatures(
            rms: 0.045,
            energy: 0.0021,
            startedAt: Date(timeIntervalSince1970: 90)
        )
        let reasons = RejectReason.inferredForFeatureWithoutOutput(
            features,
            thresholdsSnapshot: [
                "rule.silenceRMS": 0.01,
                "rule.snoreRMS": 0.05,
                "tuning.snoreEnergyThreshold": 0.0025
            ]
        )

        #expect(reasons.contains(.belowRmsThreshold))
        #expect(reasons.contains(.belowEnergyThreshold))
        #expect(reasons.contains(.belowLowBandRatio))
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
                "rule.lowLevelSnoreRMS": 0.0275,
                "rule.lowLevelSnoreEnergy": 0.00049,
                "rule.lowLevelSnoreLowBandRatio": 0.64,
                "rule.snoreRelativeEnergyRatio": 1.35,
                "tuning.snoreEnergyThreshold": 0.0025,
                "smoothing.confidenceThreshold": 0.35
            ],
            tuningProfile: DetectorTuningProfile.balanced.displayName,
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
        startedAt: Date,
        lowBandEnergy: Double = 0.4,
        midBandEnergy: Double = 0.4,
        highBandEnergy: Double = 0.2,
        zeroCrossingRate: Double = 0.2,
        spectralCentroid: Double = 1_000,
        estimatedNoiseLevel: Double? = nil
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
            zeroCrossingRate: zeroCrossingRate,
            lowFrequencyEnergyRatio: lowBandEnergy,
            spectralCentroid: spectralCentroid,
            lowBandEnergy: lowBandEnergy,
            midBandEnergy: midBandEnergy,
            highBandEnergy: highBandEnergy,
            estimatedNoiseLevel: estimatedNoiseLevel ?? rms,
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
