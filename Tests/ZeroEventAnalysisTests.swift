import Foundation
import Testing
@testable import SleepSoundCore

@Suite("ZeroEventAnalysis")
struct ZeroEventAnalysisTests {
    @Test
    func returnsNilWhenFinalEventsExist() throws {
        var diagnostics = makeDiagnostics()
        diagnostics.finalEventCountByType = [.snore: 1]

        #expect(ZeroEventAnalysis.make(diagnostics: diagnostics) == nil)
    }

    @Test
    func detectsAudioNotReceivedEnough() throws {
        var diagnostics = makeDiagnostics()
        diagnostics.audioCoverageRatio = 0.30

        let analysis = try #require(ZeroEventAnalysis.make(diagnostics: diagnostics))
        #expect(analysis.probableReason == .audioNotReceivedEnough)
    }

    @Test
    func detectsMostlySilenceWhenFeatureDistributionIsVeryLow() throws {
        let diagnostics = makeDiagnostics(
            rawCandidateCount: 0,
            rejectedCountByReason: [.likelySilence: 120, .belowRmsThreshold: 120],
            rmsValues: [0.001, 0.002, 0.003],
            energyValues: [0.000001, 0.000002]
        )

        let analysis = try #require(ZeroEventAnalysis.make(diagnostics: diagnostics))
        #expect(analysis.probableReason == .featuresMostlySilence)
    }

    @Test
    func detectsDetectorTooConservativeWhenFeaturesAreNearThreshold() throws {
        let configuration = DetectorTuningProfile.balanced.configuration
        let diagnostics = makeDiagnostics(
            rawCandidateCount: 0,
            rejectedCountByReason: [.belowRmsThreshold: 80],
            rmsValues: [0.035, 0.041, 0.045],
            energyValues: [0.0015, 0.0021, 0.0023]
        )

        let analysis = try #require(ZeroEventAnalysis.make(diagnostics: diagnostics, configuration: configuration))
        #expect(analysis.probableReason == .detectorTooConservative)
    }

    @Test
    func detectsConfidenceRejects() throws {
        let diagnostics = makeDiagnostics(
            rawCandidateCount: 8,
            preSmoothingCandidateCount: 8,
            postSmoothingEventCount: 0,
            rejectedCountByReason: [.belowConfidenceThreshold: 8]
        )

        let analysis = try #require(ZeroEventAnalysis.make(diagnostics: diagnostics))
        #expect(analysis.probableReason == .candidatesRejectedByConfidence)
    }

    @Test
    func detectsTooShortRejects() throws {
        let diagnostics = makeDiagnostics(
            rawCandidateCount: 5,
            preSmoothingCandidateCount: 5,
            postSmoothingEventCount: 0,
            rejectedCountByReason: [.tooShort: 5]
        )

        let analysis = try #require(ZeroEventAnalysis.make(diagnostics: diagnostics))
        #expect(analysis.probableReason == .candidatesRejectedByTooShort)
    }

    @Test
    func detectsModelUnavailableFallback() throws {
        let diagnostics = makeDiagnostics(
            rawCandidateCount: 0,
            modelFallbackCount: 3,
            rejectedCountByReason: [.modelUnavailable: 3],
            rmsValues: [0.03, 0.04],
            energyValues: [0.001, 0.002]
        )

        let analysis = try #require(ZeroEventAnalysis.make(diagnostics: diagnostics))
        #expect(analysis.probableReason == .modelUnavailableFallback)
    }

    private func makeDiagnostics(
        rawCandidateCount: Int = 0,
        preSmoothingCandidateCount: Int = 0,
        postSmoothingEventCount: Int = 0,
        modelFallbackCount: Int = 0,
        rejectedCountByReason: [RejectReason: Int] = [:],
        rmsValues: [Double] = [0.02, 0.03],
        energyValues: [Double] = [0.0004, 0.0009]
    ) -> DetectorDiagnostics {
        let sessionId = UUID()
        let startedAt = Date()
        return DetectorDiagnostics(
            sessionId: sessionId,
            startedAt: startedAt,
            endedAt: startedAt.addingTimeInterval(300),
            detectorBackend: SleepDetectionBackend.ruleBased.displayName,
            modelInstalled: false,
            modelFallbackCount: modelFallbackCount,
            analyzedChunkCount: 120,
            receivedAudioSeconds: 300,
            analyzedAudioSeconds: 299,
            audioCoverageRatio: 0.99,
            rawCandidateCount: rawCandidateCount,
            rawCandidateCountByType: rawCandidateCount > 0 ? [.unknown: rawCandidateCount] : [:],
            preSmoothingCandidateCount: preSmoothingCandidateCount,
            postSmoothingEventCount: postSmoothingEventCount,
            finalEventCountByType: [:],
            rejectedCountByReason: rejectedCountByReason,
            confidenceHistogram: [:],
            rmsSummary: SummaryStats.make(values: rmsValues),
            energySummary: SummaryStats.make(values: energyValues),
            zeroCrossingRateSummary: SummaryStats.make(values: [0.1, 0.2]),
            spectralCentroidSummary: SummaryStats.make(values: [800, 1_400]),
            lowBandEnergySummary: SummaryStats.make(values: [0.1, 0.2]),
            midBandEnergySummary: SummaryStats.make(values: [0.1, 0.2]),
            highBandEnergySummary: SummaryStats.make(values: [0.1, 0.2]),
            thresholdsSnapshot: DetectorTuningProfile.balanced.configuration.thresholdSnapshot,
            eventAudioSampleStorageEnabled: false,
            notes: []
        )
    }
}
