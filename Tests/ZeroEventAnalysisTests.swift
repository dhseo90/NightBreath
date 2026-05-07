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
    func detectsAudioReceivedButNoRawCandidates() throws {
        let diagnostics = makeDiagnostics(
            rawCandidateCount: 0,
            rejectedCountByReason: [.unknown: 12],
            rmsValues: [0.012, 0.018, 0.022],
            energyValues: [0.00014, 0.00032, 0.00048]
        )

        let analysis = try #require(ZeroEventAnalysis.make(diagnostics: diagnostics))
        #expect(analysis.probableReason == .audioReceivedButNoRawCandidates)
    }

    @Test
    func detectsSnoreLikeFeaturesRejectedBeforeRawCandidate() throws {
        let diagnostics = makeDiagnostics(
            rawCandidateCount: 0,
            snoreLikeFeatureCandidateCount: 6,
            snoreLikeFeatureRejectedCount: 6,
            snoreLikeFeatureRejectReasonCounts: [.belowLowBandRatio: 4, .belowRmsThreshold: 2],
            rmsValues: [0.038, 0.043, 0.047],
            energyValues: [0.0016, 0.0020, 0.0023]
        )

        let analysis = try #require(ZeroEventAnalysis.make(diagnostics: diagnostics))
        #expect(analysis.probableReason == .snoreLikeFeaturesRejectedBeforeRaw)
        #expect(analysis.recommendedDebugAction.contains("RMS/energy"))
    }

    @Test
    func detectsGoodCoverageButInputLevelTooLowForPlacement() throws {
        let diagnostics = makeDiagnostics(
            rawCandidateCount: 1,
            rawCandidateCountByType: [.movementLike: 1],
            snoreLikeFeatureCandidateCount: 1,
            snoreLikeFeatureRejectedCount: 1,
            snoreLikeFeatureRejectReasonCounts: [.inputLevelTooLow: 1],
            rmsValues: [0.00015, 0.00037, 0.00084],
            energyValues: [0.00000002, 0.00000014, 0.00000071],
            lowBandValues: [0.64, 0.92, 0.98],
            thresholdsSnapshot: [
                "rule.silenceRMS": 0.008,
                "rule.snoreRMS": 0.040,
                "rule.lowLevelSnoreRMS": 0.022,
                "rule.lowLevelSnoreEnergy": 0.0003146,
                "rule.lowLevelSnoreLowBandRatio": 0.64,
                "tuning.snoreEnergyThreshold": 0.0016,
            ]
        )

        let analysis = try #require(ZeroEventAnalysis.make(diagnostics: diagnostics))

        #expect(diagnostics.inputLevelLooksTooLowForPlacement)
        #expect(diagnostics.summaryTextForZeroEvents?.contains("입력 레벨") == true)
        #expect(analysis.probableReason == .inputLevelTooLowForPlacement)
        #expect(analysis.recommendedDebugAction.contains("iPhone"))
        #expect(analysis.recommendedDebugAction.contains("마이크"))
    }

    @Test
    func detectorTooConservativeAnalysisWorksAcrossDebugProfiles() throws {
        for profile in DetectorTuningProfile.debugSelectableProfiles {
            let configuration = profile.configuration
            let diagnostics = makeDiagnostics(
                rawCandidateCount: 0,
                rejectedCountByReason: [.belowRmsThreshold: 80],
                rmsValues: [
                    configuration.snoreRmsThreshold * 0.81,
                    configuration.snoreRmsThreshold * 0.84,
                    configuration.snoreRmsThreshold * 0.86
                ],
                energyValues: [
                    configuration.snoreEnergyThreshold * 0.81,
                    configuration.snoreEnergyThreshold * 0.84,
                    configuration.snoreEnergyThreshold * 0.86
                ]
            )

            let analysis = try #require(
                ZeroEventAnalysis.make(diagnostics: diagnostics, configuration: configuration)
            )
            #expect(analysis.probableReason == .detectorTooConservative)
        }
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
    func detectsSnoreLikeRawCandidateRejectedByConfidence() throws {
        let diagnostics = makeDiagnostics(
            rawCandidateCount: 3,
            rawCandidateCountByType: [.snore: 3],
            preSmoothingCandidateCount: 3,
            postSmoothingEventCount: 0,
            preSmoothingCandidateCountByType: [.snore: 3],
            postSmoothingEventCountByType: [:],
            rejectedCountByReason: [.belowConfidenceThreshold: 3]
        )

        let analysis = try #require(ZeroEventAnalysis.make(diagnostics: diagnostics))
        #expect(analysis.probableReason == .snoreCandidatesRejectedByConfidence)
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
    func detectsRawCandidatesDroppedBySmoothing() throws {
        let diagnostics = makeDiagnostics(
            rawCandidateCount: 4,
            rawCandidateCountByType: [.coughLike: 4],
            preSmoothingCandidateCount: 4,
            postSmoothingEventCount: 0,
            preSmoothingCandidateCountByType: [.coughLike: 4],
            postSmoothingEventCountByType: [:],
            rejectedCountByReason: [.smoothingDropped: 4]
        )

        let analysis = try #require(ZeroEventAnalysis.make(diagnostics: diagnostics))
        #expect(analysis.probableReason == .smoothingRemovedCandidates)
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

    @Test
    func zeroEventExplanationsUseSafeNonDiagnosticCopy() throws {
        let scenarios = [
            makeDiagnostics(rawCandidateCount: 0, rejectedCountByReason: [.unknown: 3]),
            makeDiagnostics(rawCandidateCount: 5, preSmoothingCandidateCount: 5, postSmoothingEventCount: 0, rejectedCountByReason: [.belowConfidenceThreshold: 5]),
            makeDiagnostics(rawCandidateCount: 0, snoreLikeFeatureCandidateCount: 2, snoreLikeFeatureRejectedCount: 2)
        ]
        let forbiddenPhrases = [
            "정상" + "입니다",
            "코골기가 " + "없었습니다",
            "수면무호흡증 " + "없음",
            "질병 " + "아님",
            "치료 " + "필요"
        ]

        for diagnostics in scenarios {
            let analysis = try #require(ZeroEventAnalysis.make(diagnostics: diagnostics))
            let combinedText = [
                diagnostics.summaryTextForZeroEvents,
                analysis.probableReason.displayName,
                analysis.recommendedDebugAction
            ].compactMap { $0 }.joined(separator: " ")

            for phrase in forbiddenPhrases {
                #expect(!combinedText.contains(phrase))
            }
        }
    }

    private func makeDiagnostics(
        rawCandidateCount: Int = 0,
        rawCandidateCountByType: [SleepEventType: Int]? = nil,
        preSmoothingCandidateCount: Int = 0,
        postSmoothingEventCount: Int = 0,
        preSmoothingCandidateCountByType: [SleepEventType: Int] = [:],
        postSmoothingEventCountByType: [SleepEventType: Int] = [:],
        modelFallbackCount: Int = 0,
        rejectedCountByReason: [RejectReason: Int] = [:],
        snoreLikeFeatureCandidateCount: Int = 0,
        snoreLikeFeatureRejectedCount: Int = 0,
        snoreLikeFeatureRejectReasonCounts: [RejectReason: Int] = [:],
        rmsValues: [Double] = [0.02, 0.03],
        energyValues: [Double] = [0.0004, 0.0009],
        lowBandValues: [Double] = [0.1, 0.2],
        thresholdsSnapshot: [String: Double] = DetectorTuningProfile.balanced.configuration.thresholdSnapshot
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
            audioChunkCount: 120,
            analyzedChunkCount: 120,
            receivedAudioSeconds: 300,
            analyzedAudioSeconds: 299,
            audioCoverageRatio: 0.99,
            rawCandidateCount: rawCandidateCount,
            rawCandidateCountByType: rawCandidateCountByType ?? (rawCandidateCount > 0 ? [.unknown: rawCandidateCount] : [:]),
            preSmoothingCandidateCount: preSmoothingCandidateCount,
            postSmoothingEventCount: postSmoothingEventCount,
            preSmoothingCandidateCountByType: preSmoothingCandidateCountByType,
            postSmoothingEventCountByType: postSmoothingEventCountByType,
            finalEventCountByType: [:],
            rejectedCountByReason: rejectedCountByReason,
            snoreLikeFeatureCandidateCount: snoreLikeFeatureCandidateCount,
            snoreLikeFeatureRejectedCount: snoreLikeFeatureRejectedCount,
            snoreLikeFeatureRejectReasonCounts: snoreLikeFeatureRejectReasonCounts,
            confidenceHistogram: [:],
            rmsSummary: SummaryStats.make(values: rmsValues),
            energySummary: SummaryStats.make(values: energyValues),
            zeroCrossingRateSummary: SummaryStats.make(values: [0.1, 0.2]),
            spectralCentroidSummary: SummaryStats.make(values: [800, 1_400]),
            lowBandEnergySummary: SummaryStats.make(values: lowBandValues),
            midBandEnergySummary: SummaryStats.make(values: [0.1, 0.2]),
            highBandEnergySummary: SummaryStats.make(values: [0.1, 0.2]),
            thresholdsSnapshot: thresholdsSnapshot,
            tuningProfile: DetectorTuningProfile.balanced.displayName,
            eventAudioSampleStorageEnabled: false,
            notes: []
        )
    }
}
