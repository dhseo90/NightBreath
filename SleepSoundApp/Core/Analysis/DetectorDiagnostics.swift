import Foundation

public enum RejectReason: String, Codable, CaseIterable, Sendable {
    case belowRmsThreshold
    case belowEnergyThreshold
    case belowLowBandRatio
    case belowConfidenceThreshold
    case belowConfidence
    case tooShort
    case tooShortDuration
    case tooLongGap
    case mergedIntoNearbyEvent
    case mergedIntoNoise
    case smoothingDropped
    case likelyEnvironmentalNoise
    case likelySilence
    case inputLevelTooLow
    case insufficientBreathingContext
    case noRecoveryPattern
    case likelySilenceOnly
    case noiseContaminated
    case modelUnavailable
    case unknown

    public var displayName: String {
        switch self {
        case .belowRmsThreshold:
            "RMS 기준 미달"
        case .belowEnergyThreshold:
            "energy 기준 미달"
        case .belowLowBandRatio:
            "저주파 비율 기준 미달"
        case .belowConfidenceThreshold:
            "confidence 낮음"
        case .belowConfidence:
            "confidence 기준 미달"
        case .tooShort:
            "너무 짧음"
        case .tooShortDuration:
            "지속 시간 기준 미달"
        case .tooLongGap:
            "후보 간격이 김"
        case .mergedIntoNearbyEvent:
            "가까운 이벤트로 병합"
        case .mergedIntoNoise:
            "소음 후보에 병합"
        case .smoothingDropped:
            "smoothing 단계 제외"
        case .likelyEnvironmentalNoise:
            "환경 소음 가능성"
        case .likelySilence:
            "무음/저활동 가능성"
        case .inputLevelTooLow:
            "입력 레벨 낮음"
        case .insufficientBreathingContext:
            "이전 호흡 맥락 부족"
        case .noRecoveryPattern:
            "회복 패턴 없음"
        case .likelySilenceOnly:
            "무음만 지속"
        case .noiseContaminated:
            "소음 영향 큼"
        case .modelUnavailable:
            "모델 사용 불가"
        case .unknown:
            "기타"
        }
    }

    public static func inferredForFeatureWithoutOutput(
        _ features: AudioFeatures,
        thresholdsSnapshot: [String: Double]
    ) -> [RejectReason] {
        var reasons: [RejectReason] = []
        let silenceRMS = thresholdsSnapshot["rule.silenceRMS"]
            ?? thresholdsSnapshot["tuning.silenceRmsThreshold"]
            ?? 0.01
        let snoreRMS = thresholdsSnapshot["rule.snoreRMS"]
            ?? thresholdsSnapshot["tuning.snoreRmsThreshold"]
            ?? 0.05
        let snoreEnergy = thresholdsSnapshot["tuning.snoreEnergyThreshold"] ?? snoreRMS * snoreRMS
        let lowLevelSnoreRMS = thresholdsSnapshot["rule.lowLevelSnoreRMS"] ?? max(silenceRMS * 2.2, snoreRMS * 0.55)
        let lowLevelSnoreEnergy = thresholdsSnapshot["rule.lowLevelSnoreEnergy"] ?? lowLevelSnoreRMS * lowLevelSnoreRMS * 0.65
        let lowLevelSnoreLowBandRatio = thresholdsSnapshot["rule.lowLevelSnoreLowBandRatio"] ?? 0.64
        let snoreRelativeEnergyRatio = thresholdsSnapshot["rule.snoreRelativeEnergyRatio"] ?? 1.35
        let relativeEnergy = Self.relativeEnergyRatio(features: features, silenceRMS: silenceRMS)
        let distantLowInputHint = Self.isDistantLowInputSnoreLikeHint(
            features: features,
            silenceRMS: silenceRMS,
            lowLevelSnoreRMS: lowLevelSnoreRMS,
            lowLevelSnoreLowBandRatio: lowLevelSnoreLowBandRatio
        )

        if features.isLikelySilence || features.rms < silenceRMS {
            reasons.append(.likelySilence)
        }
        if distantLowInputHint {
            reasons.append(.inputLevelTooLow)
        }
        if features.rms < snoreRMS {
            reasons.append(.belowRmsThreshold)
        }
        if features.energy < snoreEnergy {
            reasons.append(.belowEnergyThreshold)
        }
        if features.rms >= snoreRMS * 0.80,
           features.lowFrequencyEnergyRatio < 0.45 {
            reasons.append(.belowLowBandRatio)
        }
        if features.rms >= lowLevelSnoreRMS,
           features.rms < snoreRMS {
            if features.energy < lowLevelSnoreEnergy || relativeEnergy < snoreRelativeEnergyRatio {
                reasons.append(.belowEnergyThreshold)
            }
            if features.lowFrequencyEnergyRatio < lowLevelSnoreLowBandRatio {
                reasons.append(.belowLowBandRatio)
            }
            if features.zeroCrossingRate > 0.24 ||
                features.highBandEnergy > 0.18 ||
                features.spectralCentroid > 950 {
                reasons.append(.likelyEnvironmentalNoise)
            }
        }
        if features.rms >= snoreRMS,
           features.rms < 0.05 {
            if features.lowFrequencyEnergyRatio >= 0.45,
               features.lowFrequencyEnergyRatio < 0.58 {
                reasons.append(.belowLowBandRatio)
            }
            if features.zeroCrossingRate > 0.28 ||
                features.highBandEnergy > 0.22 ||
                features.spectralCentroid > 1_200 {
                reasons.append(.likelyEnvironmentalNoise)
            }
        }
        if reasons.isEmpty {
            reasons.append(.unknown)
        }
        return unique(reasons)
    }

    static func isDistantLowInputSnoreLikeHint(
        features: AudioFeatures,
        silenceRMS: Double,
        lowLevelSnoreRMS: Double,
        lowLevelSnoreLowBandRatio: Double
    ) -> Bool {
        let minimumObservableRMS = max(silenceRMS * 0.015, 0.00012)
        return features.rms >= minimumObservableRMS &&
            features.rms < max(silenceRMS, lowLevelSnoreRMS) &&
            features.energy > 0 &&
            features.lowFrequencyEnergyRatio >= max(0.70, lowLevelSnoreLowBandRatio) &&
            features.zeroCrossingRate <= 0.20 &&
            features.highBandEnergy <= 0.22 &&
            features.spectralCentroid <= 1_800
    }

    private static func relativeEnergyRatio(features: AudioFeatures, silenceRMS: Double) -> Double {
        let floor = max(features.estimatedNoiseLevel, silenceRMS * 0.75, 0.0001)
        let floorEnergy = max(floor * floor, 0.000_000_01)
        guard features.energy.isFinite else { return 0 }
        return max(0, features.energy / floorEnergy)
    }

    private static func unique(_ reasons: [RejectReason]) -> [RejectReason] {
        reasons.reduce(into: [RejectReason]()) { result, reason in
            if !result.contains(reason) {
                result.append(reason)
            }
        }
    }
}

public struct SummaryStats: Codable, Equatable, Sendable {
    public var count: Int
    public var min: Double
    public var max: Double
    public var mean: Double
    public var p50: Double
    public var p90: Double
    public var p95: Double
    public var p99: Double

    public init(
        count: Int = 0,
        min: Double = 0,
        max: Double = 0,
        mean: Double = 0,
        p50: Double = 0,
        p90: Double = 0,
        p95: Double = 0,
        p99: Double = 0
    ) {
        self.count = Swift.max(0, count)
        self.min = Self.safe(min)
        self.max = Self.safe(max)
        self.mean = Self.safe(mean)
        self.p50 = Self.safe(p50)
        self.p90 = Self.safe(p90)
        self.p95 = Self.safe(p95)
        self.p99 = Self.safe(p99)
    }

    public static func make(values: [Double]) -> SummaryStats {
        let finiteValues = values.filter { $0.isFinite }.sorted()
        guard let first = finiteValues.first, let last = finiteValues.last else {
            return SummaryStats()
        }

        let sum = finiteValues.reduce(0, +)
        return SummaryStats(
            count: finiteValues.count,
            min: first,
            max: last,
            mean: sum / Double(finiteValues.count),
            p50: percentile(0.50, values: finiteValues),
            p90: percentile(0.90, values: finiteValues),
            p95: percentile(0.95, values: finiteValues),
            p99: percentile(0.99, values: finiteValues)
        )
    }

    private static func percentile(_ percentile: Double, values: [Double]) -> Double {
        guard !values.isEmpty else { return 0 }
        guard values.count > 1 else { return values[0] }

        let clampedPercentile = Swift.min(Swift.max(percentile, 0), 1)
        let position = clampedPercentile * Double(values.count - 1)
        let lowerIndex = Int(floor(position))
        let upperIndex = Int(ceil(position))
        let fraction = position - Double(lowerIndex)

        if lowerIndex == upperIndex {
            return values[lowerIndex]
        }

        return values[lowerIndex] + (values[upperIndex] - values[lowerIndex]) * fraction
    }

    private static func safe(_ value: Double) -> Double {
        value.isFinite ? value : 0
    }
}

public struct DetectionSmoothingDiagnostics: Codable, Equatable, Sendable {
    public var preSmoothingCandidateCount: Int
    public var postSmoothingEventCount: Int
    public var preSmoothingCandidateCountByType: [SleepEventType: Int]
    public var postSmoothingEventCountByType: [SleepEventType: Int]
    public var rejectedCountByReason: [RejectReason: Int]

    public init(
        preSmoothingCandidateCount: Int = 0,
        postSmoothingEventCount: Int = 0,
        preSmoothingCandidateCountByType: [SleepEventType: Int] = [:],
        postSmoothingEventCountByType: [SleepEventType: Int] = [:],
        rejectedCountByReason: [RejectReason: Int] = [:]
    ) {
        self.preSmoothingCandidateCount = max(0, preSmoothingCandidateCount)
        self.postSmoothingEventCount = max(0, postSmoothingEventCount)
        self.preSmoothingCandidateCountByType = preSmoothingCandidateCountByType
        self.postSmoothingEventCountByType = postSmoothingEventCountByType
        self.rejectedCountByReason = rejectedCountByReason
    }
}

public struct DetectionSmoothingResult: Equatable, Sendable {
    public var outputs: [DetectorOutput]
    public var diagnostics: DetectionSmoothingDiagnostics

    public init(outputs: [DetectorOutput], diagnostics: DetectionSmoothingDiagnostics) {
        self.outputs = outputs
        self.diagnostics = diagnostics
    }
}

public struct DetectorDiagnostics: Codable, Equatable, Sendable {
    public var sessionId: UUID
    public var startedAt: Date
    public var endedAt: Date?
    public var detectorBackend: String
    public var modelInstalled: Bool
    public var modelFallbackCount: Int
    public var audioChunkCount: Int
    public var analyzedChunkCount: Int
    public var receivedAudioSeconds: TimeInterval
    public var analyzedAudioSeconds: TimeInterval
    public var audioCoverageRatio: Double
    public var rawCandidateCount: Int
    public var rawCandidateCountByType: [SleepEventType: Int]
    public var preSmoothingCandidateCount: Int
    public var postSmoothingEventCount: Int
    public var preSmoothingCandidateCountByType: [SleepEventType: Int]
    public var postSmoothingEventCountByType: [SleepEventType: Int]
    public var finalEventCountByType: [SleepEventType: Int]
    public var rejectedCountByReason: [RejectReason: Int]
    public var snoreLikeFeatureCandidateCount: Int
    public var snoreLikeFeatureRejectedCount: Int
    public var snoreLikeFeatureRejectReasonCounts: [RejectReason: Int]
    public var confidenceHistogram: [String: Int]
    public var rmsSummary: SummaryStats
    public var energySummary: SummaryStats
    public var zeroCrossingRateSummary: SummaryStats
    public var spectralCentroidSummary: SummaryStats
    public var lowBandEnergySummary: SummaryStats
    public var midBandEnergySummary: SummaryStats
    public var highBandEnergySummary: SummaryStats
    public var thresholdsSnapshot: [String: Double]
    public var tuningProfile: String?
    public var eventAudioSampleStorageEnabled: Bool
    public var lowActivityObservedCount: Int?
    public var lowActivityDurationTotal: TimeInterval?
    public var lowActivityCandidateCount: Int?
    public var noiseContaminatedLowActivityCount: Int?
    public var recoveryPatternCount: Int?
    public var pauseCandidatesRejectedByNoise: Int?
    public var pauseCandidatesRejectedByDuration: Int?
    public var pauseCandidatesRejectedByNoRecovery: Int?
    public var pauseCandidatesRejectedByInsufficientContext: Int?
    public var pauseCandidatesRejectedByLikelySilence: Int?
    public var pauseCandidatesPromotedByGasp: Int?
    public var latestBreathingActivityScore: Double?
    public var latestLowActivityDurationSeconds: TimeInterval?
    public var latestRecoveryPatternDetected: Bool?
    public var latestPauseCandidateConfidence: Double?
    public var latestPauseCandidateRejectedReason: String?
    public var latestFeatureDebugSummary: String?
    public var latestRawCandidateDebugSummary: String?
    public var notes: [String]

    public init(
        sessionId: UUID,
        startedAt: Date,
        endedAt: Date? = nil,
        detectorBackend: String,
        modelInstalled: Bool,
        modelFallbackCount: Int = 0,
        audioChunkCount: Int = 0,
        analyzedChunkCount: Int = 0,
        receivedAudioSeconds: TimeInterval = 0,
        analyzedAudioSeconds: TimeInterval = 0,
        audioCoverageRatio: Double = 0,
        rawCandidateCount: Int = 0,
        rawCandidateCountByType: [SleepEventType: Int] = [:],
        preSmoothingCandidateCount: Int = 0,
        postSmoothingEventCount: Int = 0,
        preSmoothingCandidateCountByType: [SleepEventType: Int] = [:],
        postSmoothingEventCountByType: [SleepEventType: Int] = [:],
        finalEventCountByType: [SleepEventType: Int] = [:],
        rejectedCountByReason: [RejectReason: Int] = [:],
        snoreLikeFeatureCandidateCount: Int = 0,
        snoreLikeFeatureRejectedCount: Int = 0,
        snoreLikeFeatureRejectReasonCounts: [RejectReason: Int] = [:],
        confidenceHistogram: [String: Int] = [:],
        rmsSummary: SummaryStats = SummaryStats(),
        energySummary: SummaryStats = SummaryStats(),
        zeroCrossingRateSummary: SummaryStats = SummaryStats(),
        spectralCentroidSummary: SummaryStats = SummaryStats(),
        lowBandEnergySummary: SummaryStats = SummaryStats(),
        midBandEnergySummary: SummaryStats = SummaryStats(),
        highBandEnergySummary: SummaryStats = SummaryStats(),
        thresholdsSnapshot: [String: Double] = [:],
        tuningProfile: String? = nil,
        eventAudioSampleStorageEnabled: Bool,
        lowActivityObservedCount: Int = 0,
        lowActivityDurationTotal: TimeInterval = 0,
        lowActivityCandidateCount: Int = 0,
        noiseContaminatedLowActivityCount: Int = 0,
        recoveryPatternCount: Int = 0,
        pauseCandidatesRejectedByNoise: Int = 0,
        pauseCandidatesRejectedByDuration: Int = 0,
        pauseCandidatesRejectedByNoRecovery: Int = 0,
        pauseCandidatesRejectedByInsufficientContext: Int = 0,
        pauseCandidatesRejectedByLikelySilence: Int = 0,
        pauseCandidatesPromotedByGasp: Int = 0,
        latestBreathingActivityScore: Double = 0,
        latestLowActivityDurationSeconds: TimeInterval = 0,
        latestRecoveryPatternDetected: Bool = false,
        latestPauseCandidateConfidence: Double = 0,
        latestPauseCandidateRejectedReason: String? = nil,
        latestFeatureDebugSummary: String? = nil,
        latestRawCandidateDebugSummary: String? = nil,
        notes: [String] = []
    ) {
        self.sessionId = sessionId
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.detectorBackend = detectorBackend
        self.modelInstalled = modelInstalled
        self.modelFallbackCount = max(0, modelFallbackCount)
        self.analyzedChunkCount = max(0, analyzedChunkCount)
        self.audioChunkCount = max(0, max(audioChunkCount, self.analyzedChunkCount))
        self.receivedAudioSeconds = max(0, receivedAudioSeconds)
        self.analyzedAudioSeconds = max(0, analyzedAudioSeconds)
        self.audioCoverageRatio = Self.clampedRatio(audioCoverageRatio)
        self.rawCandidateCount = max(0, rawCandidateCount)
        self.rawCandidateCountByType = rawCandidateCountByType
        self.preSmoothingCandidateCount = max(0, preSmoothingCandidateCount)
        self.postSmoothingEventCount = max(0, postSmoothingEventCount)
        self.preSmoothingCandidateCountByType = preSmoothingCandidateCountByType
        self.postSmoothingEventCountByType = postSmoothingEventCountByType
        self.finalEventCountByType = finalEventCountByType
        self.rejectedCountByReason = rejectedCountByReason
        self.snoreLikeFeatureCandidateCount = max(0, snoreLikeFeatureCandidateCount)
        self.snoreLikeFeatureRejectedCount = max(0, snoreLikeFeatureRejectedCount)
        self.snoreLikeFeatureRejectReasonCounts = snoreLikeFeatureRejectReasonCounts
        self.confidenceHistogram = confidenceHistogram
        self.rmsSummary = rmsSummary
        self.energySummary = energySummary
        self.zeroCrossingRateSummary = zeroCrossingRateSummary
        self.spectralCentroidSummary = spectralCentroidSummary
        self.lowBandEnergySummary = lowBandEnergySummary
        self.midBandEnergySummary = midBandEnergySummary
        self.highBandEnergySummary = highBandEnergySummary
        self.thresholdsSnapshot = thresholdsSnapshot.filter { $0.value.isFinite }
        self.tuningProfile = tuningProfile
        self.eventAudioSampleStorageEnabled = eventAudioSampleStorageEnabled
        self.lowActivityObservedCount = max(0, lowActivityObservedCount)
        self.lowActivityDurationTotal = max(0, lowActivityDurationTotal)
        self.lowActivityCandidateCount = max(0, lowActivityCandidateCount)
        self.noiseContaminatedLowActivityCount = max(0, noiseContaminatedLowActivityCount)
        self.recoveryPatternCount = max(0, recoveryPatternCount)
        self.pauseCandidatesRejectedByNoise = max(0, pauseCandidatesRejectedByNoise)
        self.pauseCandidatesRejectedByDuration = max(0, pauseCandidatesRejectedByDuration)
        self.pauseCandidatesRejectedByNoRecovery = max(0, pauseCandidatesRejectedByNoRecovery)
        self.pauseCandidatesRejectedByInsufficientContext = max(0, pauseCandidatesRejectedByInsufficientContext)
        self.pauseCandidatesRejectedByLikelySilence = max(0, pauseCandidatesRejectedByLikelySilence)
        self.pauseCandidatesPromotedByGasp = max(0, pauseCandidatesPromotedByGasp)
        self.latestBreathingActivityScore = Self.clampedRatio(latestBreathingActivityScore)
        self.latestLowActivityDurationSeconds = max(0, latestLowActivityDurationSeconds)
        self.latestRecoveryPatternDetected = latestRecoveryPatternDetected
        self.latestPauseCandidateConfidence = Self.clampedRatio(latestPauseCandidateConfidence)
        self.latestPauseCandidateRejectedReason = latestPauseCandidateRejectedReason
        self.latestFeatureDebugSummary = latestFeatureDebugSummary
        self.latestRawCandidateDebugSummary = latestRawCandidateDebugSummary
        self.notes = notes
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let analyzedChunkCount = try container.decodeIfPresent(Int.self, forKey: .analyzedChunkCount) ?? 0
        let audioChunkCount = try container.decodeIfPresent(Int.self, forKey: .audioChunkCount) ?? analyzedChunkCount

        self.init(
            sessionId: try container.decodeIfPresent(UUID.self, forKey: .sessionId) ?? UUID(),
            startedAt: try container.decodeIfPresent(Date.self, forKey: .startedAt) ?? Date(),
            endedAt: try container.decodeIfPresent(Date.self, forKey: .endedAt),
            detectorBackend: try container.decodeIfPresent(String.self, forKey: .detectorBackend)
                ?? SleepDetectionBackend.ruleBased.displayName,
            modelInstalled: try container.decodeIfPresent(Bool.self, forKey: .modelInstalled) ?? false,
            modelFallbackCount: try container.decodeIfPresent(Int.self, forKey: .modelFallbackCount) ?? 0,
            audioChunkCount: audioChunkCount,
            analyzedChunkCount: analyzedChunkCount,
            receivedAudioSeconds: try container.decodeIfPresent(TimeInterval.self, forKey: .receivedAudioSeconds) ?? 0,
            analyzedAudioSeconds: try container.decodeIfPresent(TimeInterval.self, forKey: .analyzedAudioSeconds) ?? 0,
            audioCoverageRatio: try container.decodeIfPresent(Double.self, forKey: .audioCoverageRatio) ?? 0,
            rawCandidateCount: try container.decodeIfPresent(Int.self, forKey: .rawCandidateCount) ?? 0,
            rawCandidateCountByType: try container.decodeIfPresent([SleepEventType: Int].self, forKey: .rawCandidateCountByType) ?? [:],
            preSmoothingCandidateCount: try container.decodeIfPresent(Int.self, forKey: .preSmoothingCandidateCount) ?? 0,
            postSmoothingEventCount: try container.decodeIfPresent(Int.self, forKey: .postSmoothingEventCount) ?? 0,
            preSmoothingCandidateCountByType: try container.decodeIfPresent([SleepEventType: Int].self, forKey: .preSmoothingCandidateCountByType) ?? [:],
            postSmoothingEventCountByType: try container.decodeIfPresent([SleepEventType: Int].self, forKey: .postSmoothingEventCountByType) ?? [:],
            finalEventCountByType: try container.decodeIfPresent([SleepEventType: Int].self, forKey: .finalEventCountByType) ?? [:],
            rejectedCountByReason: try container.decodeIfPresent([RejectReason: Int].self, forKey: .rejectedCountByReason) ?? [:],
            snoreLikeFeatureCandidateCount: try container.decodeIfPresent(Int.self, forKey: .snoreLikeFeatureCandidateCount) ?? 0,
            snoreLikeFeatureRejectedCount: try container.decodeIfPresent(Int.self, forKey: .snoreLikeFeatureRejectedCount) ?? 0,
            snoreLikeFeatureRejectReasonCounts: try container.decodeIfPresent([RejectReason: Int].self, forKey: .snoreLikeFeatureRejectReasonCounts) ?? [:],
            confidenceHistogram: try container.decodeIfPresent([String: Int].self, forKey: .confidenceHistogram) ?? [:],
            rmsSummary: try container.decodeIfPresent(SummaryStats.self, forKey: .rmsSummary) ?? SummaryStats(),
            energySummary: try container.decodeIfPresent(SummaryStats.self, forKey: .energySummary) ?? SummaryStats(),
            zeroCrossingRateSummary: try container.decodeIfPresent(SummaryStats.self, forKey: .zeroCrossingRateSummary) ?? SummaryStats(),
            spectralCentroidSummary: try container.decodeIfPresent(SummaryStats.self, forKey: .spectralCentroidSummary) ?? SummaryStats(),
            lowBandEnergySummary: try container.decodeIfPresent(SummaryStats.self, forKey: .lowBandEnergySummary) ?? SummaryStats(),
            midBandEnergySummary: try container.decodeIfPresent(SummaryStats.self, forKey: .midBandEnergySummary) ?? SummaryStats(),
            highBandEnergySummary: try container.decodeIfPresent(SummaryStats.self, forKey: .highBandEnergySummary) ?? SummaryStats(),
            thresholdsSnapshot: try container.decodeIfPresent([String: Double].self, forKey: .thresholdsSnapshot) ?? [:],
            tuningProfile: try container.decodeIfPresent(String.self, forKey: .tuningProfile),
            eventAudioSampleStorageEnabled: try container.decodeIfPresent(Bool.self, forKey: .eventAudioSampleStorageEnabled) ?? false,
            lowActivityObservedCount: try container.decodeIfPresent(Int.self, forKey: .lowActivityObservedCount) ?? 0,
            lowActivityDurationTotal: try container.decodeIfPresent(TimeInterval.self, forKey: .lowActivityDurationTotal) ?? 0,
            lowActivityCandidateCount: try container.decodeIfPresent(Int.self, forKey: .lowActivityCandidateCount) ?? 0,
            noiseContaminatedLowActivityCount: try container.decodeIfPresent(Int.self, forKey: .noiseContaminatedLowActivityCount) ?? 0,
            recoveryPatternCount: try container.decodeIfPresent(Int.self, forKey: .recoveryPatternCount) ?? 0,
            pauseCandidatesRejectedByNoise: try container.decodeIfPresent(Int.self, forKey: .pauseCandidatesRejectedByNoise) ?? 0,
            pauseCandidatesRejectedByDuration: try container.decodeIfPresent(Int.self, forKey: .pauseCandidatesRejectedByDuration) ?? 0,
            pauseCandidatesRejectedByNoRecovery: try container.decodeIfPresent(Int.self, forKey: .pauseCandidatesRejectedByNoRecovery) ?? 0,
            pauseCandidatesRejectedByInsufficientContext: try container.decodeIfPresent(Int.self, forKey: .pauseCandidatesRejectedByInsufficientContext) ?? 0,
            pauseCandidatesRejectedByLikelySilence: try container.decodeIfPresent(Int.self, forKey: .pauseCandidatesRejectedByLikelySilence) ?? 0,
            pauseCandidatesPromotedByGasp: try container.decodeIfPresent(Int.self, forKey: .pauseCandidatesPromotedByGasp) ?? 0,
            latestBreathingActivityScore: try container.decodeIfPresent(Double.self, forKey: .latestBreathingActivityScore) ?? 0,
            latestLowActivityDurationSeconds: try container.decodeIfPresent(TimeInterval.self, forKey: .latestLowActivityDurationSeconds) ?? 0,
            latestRecoveryPatternDetected: try container.decodeIfPresent(Bool.self, forKey: .latestRecoveryPatternDetected) ?? false,
            latestPauseCandidateConfidence: try container.decodeIfPresent(Double.self, forKey: .latestPauseCandidateConfidence) ?? 0,
            latestPauseCandidateRejectedReason: try container.decodeIfPresent(String.self, forKey: .latestPauseCandidateRejectedReason),
            latestFeatureDebugSummary: try container.decodeIfPresent(String.self, forKey: .latestFeatureDebugSummary),
            latestRawCandidateDebugSummary: try container.decodeIfPresent(String.self, forKey: .latestRawCandidateDebugSummary),
            notes: try container.decodeIfPresent([String].self, forKey: .notes) ?? []
        )
    }

    private enum CodingKeys: String, CodingKey {
        case sessionId
        case startedAt
        case endedAt
        case detectorBackend
        case modelInstalled
        case modelFallbackCount
        case audioChunkCount
        case analyzedChunkCount
        case receivedAudioSeconds
        case analyzedAudioSeconds
        case audioCoverageRatio
        case rawCandidateCount
        case rawCandidateCountByType
        case preSmoothingCandidateCount
        case postSmoothingEventCount
        case preSmoothingCandidateCountByType
        case postSmoothingEventCountByType
        case finalEventCountByType
        case rejectedCountByReason
        case snoreLikeFeatureCandidateCount
        case snoreLikeFeatureRejectedCount
        case snoreLikeFeatureRejectReasonCounts
        case confidenceHistogram
        case rmsSummary
        case energySummary
        case zeroCrossingRateSummary
        case spectralCentroidSummary
        case lowBandEnergySummary
        case midBandEnergySummary
        case highBandEnergySummary
        case thresholdsSnapshot
        case tuningProfile
        case eventAudioSampleStorageEnabled
        case lowActivityObservedCount
        case lowActivityDurationTotal
        case lowActivityCandidateCount
        case noiseContaminatedLowActivityCount
        case recoveryPatternCount
        case pauseCandidatesRejectedByNoise
        case pauseCandidatesRejectedByDuration
        case pauseCandidatesRejectedByNoRecovery
        case pauseCandidatesRejectedByInsufficientContext
        case pauseCandidatesRejectedByLikelySilence
        case pauseCandidatesPromotedByGasp
        case latestBreathingActivityScore
        case latestLowActivityDurationSeconds
        case latestRecoveryPatternDetected
        case latestPauseCandidateConfidence
        case latestPauseCandidateRejectedReason
        case latestFeatureDebugSummary
        case latestRawCandidateDebugSummary
        case notes
    }

    public var topRejectReasons: [(RejectReason, Int)] {
        rejectedCountByReason.sorted { lhs, rhs in
            if lhs.value == rhs.value {
                return lhs.key.rawValue < rhs.key.rawValue
            }
            return lhs.value > rhs.value
        }
    }

    public var activeDetectorBackend: String { detectorBackend }

    public var fallbackUsed: Bool { modelFallbackCount > 0 }

    public var rejectReasonCounts: [RejectReason: Int] { rejectedCountByReason }

    public var snoreRawCandidateCount: Int { rawCandidateCountByType[.snore] ?? 0 }

    public var snoreFinalEventCount: Int { finalEventCountByType[.snore] ?? 0 }

    public var snorePostSmoothingEventCount: Int { postSmoothingEventCountByType[.snore] ?? snoreFinalEventCount }

    public var snoreRejectedCount: Int {
        max(0, snoreRawCandidateCount - snorePostSmoothingEventCount)
    }

    public var snoreRejectReasonTop: RejectReason? {
        if rejectedCountByReason[.belowConfidenceThreshold, default: 0] > 0 ||
            rejectedCountByReason[.belowConfidence, default: 0] > 0 {
            return .belowConfidenceThreshold
        }
        if snoreRawCandidateCount == 0, !snoreLikeFeatureRejectReasonCounts.isEmpty {
            return snoreLikeFeatureRejectReasonCounts.sorted { lhs, rhs in
                if lhs.value == rhs.value { return lhs.key.rawValue < rhs.key.rawValue }
                return lhs.value > rhs.value
            }.first?.key
        }
        return topRejectReasons.first?.0
    }

    public var rmsMin: Double { rmsSummary.min }
    public var rmsP50: Double { rmsSummary.p50 }
    public var rmsP90: Double { rmsSummary.p90 }
    public var rmsMax: Double { rmsSummary.max }
    public var energyMin: Double { energySummary.min }
    public var energyP50: Double { energySummary.p50 }
    public var energyP90: Double { energySummary.p90 }
    public var energyMax: Double { energySummary.max }
    public var lowBandEnergyP50: Double { lowBandEnergySummary.p50 }
    public var lowBandEnergyP90: Double { lowBandEnergySummary.p90 }
    public var midBandEnergyP50: Double { midBandEnergySummary.p50 }
    public var highBandEnergyP50: Double { highBandEnergySummary.p50 }
    public var zeroCrossingRateP50: Double { zeroCrossingRateSummary.p50 }
    public var spectralCentroidP50: Double { spectralCentroidSummary.p50 }
    public var thresholdSnapshot: [String: Double] { thresholdsSnapshot }

    public var inputLevelLooksTooLowForPlacement: Bool {
        guard finalEventCountByType.values.reduce(0, +) == 0,
              analyzedAudioSeconds >= 60,
              audioCoverageRatio >= 0.75,
              rmsSummary.count > 0,
              energySummary.count > 0 else {
            return false
        }

        let silenceRMS = thresholdsSnapshot["rule.silenceRMS"]
            ?? thresholdsSnapshot["tuning.silenceRmsThreshold"]
            ?? 0.01
        let snoreRMS = thresholdsSnapshot["rule.snoreRMS"]
            ?? thresholdsSnapshot["tuning.snoreRmsThreshold"]
            ?? 0.05
        let lowLevelSnoreRMS = thresholdsSnapshot["rule.lowLevelSnoreRMS"]
            ?? max(silenceRMS * 2.2, snoreRMS * 0.55)
        let lowLevelSnoreEnergy = thresholdsSnapshot["rule.lowLevelSnoreEnergy"]
            ?? lowLevelSnoreRMS * lowLevelSnoreRMS * 0.65
        let lowLevelSnoreLowBandRatio = thresholdsSnapshot["rule.lowLevelSnoreLowBandRatio"] ?? 0.64
        let p99FarBelowLowLevelRMS = rmsSummary.p99 > 0 &&
            rmsSummary.p99 < lowLevelSnoreRMS * 0.25
        let p90NearNoiseFloor = rmsSummary.p90 > 0 &&
            rmsSummary.p90 < max(silenceRMS * 0.12, lowLevelSnoreRMS * 0.05)
        let p99FarBelowLowLevelEnergy = energySummary.p99 > 0 &&
            energySummary.p99 < lowLevelSnoreEnergy * 0.05
        let hasSnoreTextureHint =
            snoreLikeFeatureCandidateCount > 0 ||
            snoreLikeFeatureRejectReasonCounts[.inputLevelTooLow, default: 0] > 0 ||
            lowBandEnergySummary.p90 >= max(0.60, lowLevelSnoreLowBandRatio * 0.90)

        return p99FarBelowLowLevelRMS &&
            p90NearNoiseFloor &&
            p99FarBelowLowLevelEnergy &&
            hasSnoreTextureHint
    }

    public var inputLevelAssessment: String {
        inputLevelLooksTooLowForPlacement
            ? "goodCoverageLowInputLevel"
            : "notFlagged"
    }

    public var inputLevelAssessmentDisplayText: String {
        inputLevelLooksTooLowForPlacement
            ? "오디오 수신 충분, 입력 레벨 낮음"
            : "특이 사항 없음"
    }

    public var summaryTextForZeroEvents: String? {
        guard finalEventCountByType.values.reduce(0, +) == 0 else { return nil }
        guard audioChunkCount > 0 || analyzedChunkCount > 0 else {
            return "실제 오디오 수신이 거의 없어 detector 요약을 만들 수 없습니다."
        }
        guard analyzedChunkCount > 0, analyzedAudioSeconds > 0 else {
            return "오디오 입력은 일부 수신되었지만 분석된 chunk가 부족해 detector 판단 경로를 제한적으로만 볼 수 있습니다."
        }
        if inputLevelLooksTooLowForPlacement {
            return "오디오는 충분히 수신됐지만 입력 레벨이 낮아 코골기 후보 기준까지 올라오지 않았습니다. iPhone 배치나 마이크 방향 영향을 확인하세요."
        }
        if snoreRawCandidateCount > 0, snorePostSmoothingEventCount == 0 {
            return "코골기 raw 후보는 있었지만 confidence, 지속 시간 또는 smoothing 기준을 통과한 최종 이벤트가 없었습니다."
        }
        if snoreLikeFeatureCandidateCount > 0, snoreRawCandidateCount == 0 {
            return "코골기처럼 보이는 feature 후보는 있었지만 raw 코골기 후보로 올라오지 않았습니다."
        }
        if rawCandidateCount == 0 {
            return "오디오 입력은 수신되었지만 detector 기준을 통과한 raw 후보가 만들어지지 않았습니다."
        }
        if preSmoothingCandidateCount > 0, postSmoothingEventCount == 0 {
            return "raw 후보는 있었지만 smoothing 단계 이후 최종 이벤트가 남지 않았습니다."
        }
        return "raw 후보는 있었지만 최종 리포트 이벤트로 남은 항목이 없었습니다."
    }

    private static func clampedRatio(_ value: Double) -> Double {
        guard value.isFinite else { return 0 }
        return min(max(value, 0), 1)
    }
}

public struct DetectorDiagnosticsQAReadout: Sendable {
    public static func makeMarkdown(
        diagnostics: DetectorDiagnostics,
        report: NightReport? = nil
    ) -> String {
        let rows = makeRows(diagnostics: diagnostics, report: report)
        var lines: [String] = [
            "# Detector Diagnostics QA Readout",
            "",
            "DEBUG/local QA용 detector 요약입니다. 원본 오디오, 이벤트 오디오 샘플 파일 경로, 개인 오디오 파일 경로는 포함하지 않습니다.",
            "",
            "## Session",
            "",
            "- sessionId: \(diagnostics.sessionId.uuidString)",
            "- startedAt: \(dateText(diagnostics.startedAt))",
            "- endedAt: \(diagnostics.endedAt.map(dateText) ?? "")",
            "- detectorBackend: \(diagnostics.activeDetectorBackend)",
            "- tuningProfile: \(diagnostics.tuningProfile ?? "")",
            "- modelInstalled: \(diagnostics.modelInstalled)",
            "- fallbackUsed: \(diagnostics.fallbackUsed)",
            "",
            "## Capture / Analysis",
            "",
            "| Metric | Value |",
            "| --- | ---: |",
        ]

        for key in [
            "audioChunkCount",
            "analyzedChunkCount",
            "receivedAudioSeconds",
            "analyzedAudioSeconds",
            "audioCoverageRatio",
            "reportFinalEventCount",
        ] {
            lines.append("| \(key) | \(rows[key] ?? "") |")
        }

        lines.append(contentsOf: [
            "",
            "## Detector Path",
            "",
            "| Metric | Value |",
            "| --- | --- |",
        ])
        for key in [
            "rawCandidateCountByType",
            "preSmoothingCandidateCountByType",
            "postSmoothingEventCountByType",
            "finalEventCountByType",
            "snoreLikeFeatureCandidateCount",
            "snoreRawCandidateCount",
            "snoreRejectedCount",
            "snoreRejectReasonTop",
            "rejectReasonTop",
            "inputLevelAssessment",
            "zeroEventSummary",
        ] {
            lines.append("| \(key) | \(rows[key] ?? "") |")
        }

        lines.append(contentsOf: [
            "",
            "## Feature Distribution",
            "",
            "| Metric | p50 | p90 |",
            "| --- | ---: | ---: |",
            "| RMS | \(number(diagnostics.rmsP50)) | \(number(diagnostics.rmsP90)) |",
            "| Energy | \(number(diagnostics.energyP50)) | \(number(diagnostics.energyP90)) |",
            "| Low band | \(number(diagnostics.lowBandEnergyP50)) | \(number(diagnostics.lowBandEnergyP90)) |",
            "| Zero crossing | \(number(diagnostics.zeroCrossingRateP50)) |  |",
            "| Spectral centroid | \(number(diagnostics.spectralCentroidP50)) |  |",
            "",
            "## Threshold Snapshot",
            "",
            thresholdText(diagnostics.thresholdsSnapshot),
            "",
            "## Notes",
            "",
        ])
        if diagnostics.notes.isEmpty {
            lines.append("- none")
        } else {
            lines.append(contentsOf: diagnostics.notes.map { "- \($0)" })
        }
        lines.append("")
        return lines.joined(separator: "\n")
    }

    public static func makeCSV(
        diagnostics: DetectorDiagnostics,
        report: NightReport? = nil
    ) -> String {
        let rows = makeRows(diagnostics: diagnostics, report: report)
        let columns = csvColumns
        let header = columns.joined(separator: ",")
        let values = columns.map { csvEscape(rows[$0] ?? "") }.joined(separator: ",")
        return "\(header)\n\(values)\n"
    }

    private static func makeRows(
        diagnostics: DetectorDiagnostics,
        report: NightReport?
    ) -> [String: String] {
        [
            "sessionId": diagnostics.sessionId.uuidString,
            "startedAt": dateText(diagnostics.startedAt),
            "endedAt": diagnostics.endedAt.map(dateText) ?? "",
            "detectorBackend": diagnostics.activeDetectorBackend,
            "tuningProfile": diagnostics.tuningProfile ?? "",
            "modelInstalled": "\(diagnostics.modelInstalled)",
            "fallbackUsed": "\(diagnostics.fallbackUsed)",
            "audioChunkCount": "\(diagnostics.audioChunkCount)",
            "analyzedChunkCount": "\(diagnostics.analyzedChunkCount)",
            "receivedAudioSeconds": number(diagnostics.receivedAudioSeconds),
            "analyzedAudioSeconds": number(diagnostics.analyzedAudioSeconds),
            "audioCoverageRatio": number(diagnostics.audioCoverageRatio),
            "reportFinalEventCount": "\(report?.detectorDiagnostics?.finalEventCountByType.values.reduce(0, +) ?? diagnostics.finalEventCountByType.values.reduce(0, +))",
            "rawCandidateCount": "\(diagnostics.rawCandidateCount)",
            "rawCandidateCountByType": eventCountText(diagnostics.rawCandidateCountByType),
            "preSmoothingCandidateCountByType": eventCountText(diagnostics.preSmoothingCandidateCountByType),
            "postSmoothingEventCountByType": eventCountText(diagnostics.postSmoothingEventCountByType),
            "finalEventCountByType": eventCountText(diagnostics.finalEventCountByType),
            "snoreLikeFeatureCandidateCount": "\(diagnostics.snoreLikeFeatureCandidateCount)",
            "snoreRawCandidateCount": "\(diagnostics.snoreRawCandidateCount)",
            "snoreRejectedCount": "\(diagnostics.snoreRejectedCount + diagnostics.snoreLikeFeatureRejectedCount)",
            "snoreRejectReasonTop": diagnostics.snoreRejectReasonTop?.rawValue ?? "",
            "rejectReasonTop": diagnostics.topRejectReasons.prefix(5).map { "\($0.0.rawValue):\($0.1)" }.joined(separator: ";"),
            "inputLevelAssessment": diagnostics.inputLevelAssessment,
            "rmsP50": number(diagnostics.rmsP50),
            "rmsP90": number(diagnostics.rmsP90),
            "energyP50": number(diagnostics.energyP50),
            "energyP90": number(diagnostics.energyP90),
            "lowBandEnergyP50": number(diagnostics.lowBandEnergyP50),
            "lowBandEnergyP90": number(diagnostics.lowBandEnergyP90),
            "zeroCrossingRateP50": number(diagnostics.zeroCrossingRateP50),
            "spectralCentroidP50": number(diagnostics.spectralCentroidP50),
            "thresholdSnapshot": thresholdText(diagnostics.thresholdsSnapshot),
            "zeroEventSummary": diagnostics.summaryTextForZeroEvents ?? "",
            "notes": diagnostics.notes.joined(separator: ";"),
        ]
    }

    private static var csvColumns: [String] {
        [
            "sessionId",
            "startedAt",
            "endedAt",
            "detectorBackend",
            "tuningProfile",
            "modelInstalled",
            "fallbackUsed",
            "audioChunkCount",
            "analyzedChunkCount",
            "receivedAudioSeconds",
            "analyzedAudioSeconds",
            "audioCoverageRatio",
            "reportFinalEventCount",
            "rawCandidateCount",
            "rawCandidateCountByType",
            "preSmoothingCandidateCountByType",
            "postSmoothingEventCountByType",
            "finalEventCountByType",
            "snoreLikeFeatureCandidateCount",
            "snoreRawCandidateCount",
            "snoreRejectedCount",
            "snoreRejectReasonTop",
            "rejectReasonTop",
            "inputLevelAssessment",
            "rmsP50",
            "rmsP90",
            "energyP50",
            "energyP90",
            "lowBandEnergyP50",
            "lowBandEnergyP90",
            "zeroCrossingRateP50",
            "spectralCentroidP50",
            "thresholdSnapshot",
            "zeroEventSummary",
            "notes",
        ]
    }

    private static func eventCountText(_ counts: [SleepEventType: Int]) -> String {
        counts
            .sorted { lhs, rhs in lhs.key.rawValue < rhs.key.rawValue }
            .map { "\($0.key.rawValue):\($0.value)" }
            .joined(separator: ";")
    }

    private static func thresholdText(_ snapshot: [String: Double]) -> String {
        snapshot
            .sorted { lhs, rhs in lhs.key < rhs.key }
            .map { "\($0.key)=\(number($0.value))" }
            .joined(separator: ";")
    }

    private static func dateText(_ date: Date) -> String {
        ISO8601DateFormatter().string(from: date)
    }

    private static func number(_ value: Double) -> String {
        guard value.isFinite else { return "0.000000" }
        return String(format: "%.6f", value)
    }

    private static func csvEscape(_ value: String) -> String {
        if value.contains(",") || value.contains("\"") || value.contains("\n") {
            return "\"\(value.replacingOccurrences(of: "\"", with: "\"\""))\""
        }
        return value
    }
}

public final class DetectorDiagnosticsCollector {
    private var sessionId: UUID?
    private var startedAt: Date?
    private var detectorBackend: String = SleepDetectionBackend.ruleBased.displayName
    private var modelInstalled = false
    private var thresholdsSnapshot: [String: Double] = [:]
    private var tuningProfile: String?
    private var eventAudioSampleStorageEnabled = false
    private var rawCandidateCountByType: [SleepEventType: Int] = [:]
    private var rejectedCountByReason: [RejectReason: Int] = [:]
    private var confidenceHistogram: [String: Int] = [:]
    private var modelFallbackCount = 0
    private var analyzedChunkCount = 0
    private var rmsValues: [Double] = []
    private var energyValues: [Double] = []
    private var zeroCrossingRateValues: [Double] = []
    private var spectralCentroidValues: [Double] = []
    private var lowBandEnergyValues: [Double] = []
    private var midBandEnergyValues: [Double] = []
    private var highBandEnergyValues: [Double] = []
    private var preSmoothingCandidateCount = 0
    private var postSmoothingEventCount = 0
    private var preSmoothingCandidateCountByType: [SleepEventType: Int] = [:]
    private var postSmoothingEventCountByType: [SleepEventType: Int] = [:]
    private var finalEventCountByType: [SleepEventType: Int] = [:]
    private var sequenceSummary = SuspectedBreathingPauseSequenceSummary()
    private var snoreLikeFeatureCandidateCount = 0
    private var snoreLikeFeatureRejectedCount = 0
    private var snoreLikeFeatureRejectReasonCounts: [RejectReason: Int] = [:]
    private var latestFeatureDebugSummary: String?
    private var latestRawCandidateDebugSummary: String?
    private var notes: [String] = []

    public init() {}

    public func reset(
        sessionId: UUID,
        startedAt: Date,
        detectorBackend: String,
        modelInstalled: Bool,
        thresholdsSnapshot: [String: Double],
        tuningProfile: String? = nil,
        eventAudioSampleStorageEnabled: Bool
    ) {
        self.sessionId = sessionId
        self.startedAt = startedAt
        self.detectorBackend = detectorBackend
        self.modelInstalled = modelInstalled
        self.thresholdsSnapshot = thresholdsSnapshot.filter { $0.value.isFinite }
        self.tuningProfile = tuningProfile
        self.eventAudioSampleStorageEnabled = eventAudioSampleStorageEnabled
        rawCandidateCountByType.removeAll(keepingCapacity: true)
        rejectedCountByReason.removeAll(keepingCapacity: true)
        confidenceHistogram.removeAll(keepingCapacity: true)
        modelFallbackCount = 0
        analyzedChunkCount = 0
        rmsValues.removeAll(keepingCapacity: true)
        energyValues.removeAll(keepingCapacity: true)
        zeroCrossingRateValues.removeAll(keepingCapacity: true)
        spectralCentroidValues.removeAll(keepingCapacity: true)
        lowBandEnergyValues.removeAll(keepingCapacity: true)
        midBandEnergyValues.removeAll(keepingCapacity: true)
        highBandEnergyValues.removeAll(keepingCapacity: true)
        preSmoothingCandidateCount = 0
        postSmoothingEventCount = 0
        preSmoothingCandidateCountByType.removeAll(keepingCapacity: true)
        postSmoothingEventCountByType.removeAll(keepingCapacity: true)
        finalEventCountByType.removeAll(keepingCapacity: true)
        sequenceSummary = SuspectedBreathingPauseSequenceSummary()
        snoreLikeFeatureCandidateCount = 0
        snoreLikeFeatureRejectedCount = 0
        snoreLikeFeatureRejectReasonCounts.removeAll(keepingCapacity: true)
        latestFeatureDebugSummary = nil
        latestRawCandidateDebugSummary = nil
        notes.removeAll(keepingCapacity: true)
    }

    public func record(features: AudioFeatures, outputs: [DetectorOutput]) {
        analyzedChunkCount += 1
        latestFeatureDebugSummary = features.debugSummary
        appendFinite(features.rms, to: &rmsValues)
        appendFinite(features.energy, to: &energyValues)
        appendFinite(features.zeroCrossingRate, to: &zeroCrossingRateValues)
        appendFinite(features.spectralCentroid, to: &spectralCentroidValues)
        appendFinite(features.lowBandEnergy, to: &lowBandEnergyValues)
        appendFinite(features.midBandEnergy, to: &midBandEnergyValues)
        appendFinite(features.highBandEnergy, to: &highBandEnergyValues)

        let snoreObservation = snoreLikeFeatureObservation(for: features)
        if snoreObservation.isCandidate {
            snoreLikeFeatureCandidateCount += 1
            if !outputs.contains(where: { $0.eventType == .snore }) {
                snoreLikeFeatureRejectedCount += 1
                for reason in snoreObservation.rejectReasons {
                    snoreLikeFeatureRejectReasonCounts[reason, default: 0] += 1
                }
            }
        }

        if outputs.isEmpty {
            for reason in RejectReason.inferredForFeatureWithoutOutput(
                features,
                thresholdsSnapshot: thresholdsSnapshot
            ) {
                incrementReject(reason)
            }
            return
        }

        for output in outputs {
            rawCandidateCountByType[output.eventType, default: 0] += 1
            confidenceHistogram[Self.confidenceBucket(for: output.confidence), default: 0] += 1
            latestRawCandidateDebugSummary = Self.outputDebugSummary(output)
            if output.debugReason?.localizedCaseInsensitiveContains("fallback") == true {
                modelFallbackCount += 1
            }
        }
    }

    public func recordModelFallbackIfNeeded(backend: SleepDetectionBackend, modelInstalled: Bool) {
        guard backend != .ruleBased, !modelInstalled else { return }
        modelFallbackCount += 1
        incrementReject(.modelUnavailable)
    }

    public func record(smoothingDiagnostics: DetectionSmoothingDiagnostics) {
        preSmoothingCandidateCount = smoothingDiagnostics.preSmoothingCandidateCount
        postSmoothingEventCount = smoothingDiagnostics.postSmoothingEventCount
        preSmoothingCandidateCountByType = smoothingDiagnostics.preSmoothingCandidateCountByType
        postSmoothingEventCountByType = smoothingDiagnostics.postSmoothingEventCountByType
        let smoothingDropCount = max(0, preSmoothingCandidateCount - postSmoothingEventCount)
        if smoothingDropCount > 0 {
            rejectedCountByReason[.smoothingDropped, default: 0] += smoothingDropCount
        }
        for (reason, count) in smoothingDiagnostics.rejectedCountByReason {
            rejectedCountByReason[reason, default: 0] += count
        }
    }

    public func record(sequenceResult: SuspectedBreathingPauseSequenceResult) {
        sequenceSummary = sequenceResult.summary

        for output in sequenceResult.outputs {
            rawCandidateCountByType[output.eventType, default: 0] += 1
            confidenceHistogram[Self.confidenceBucket(for: output.confidence), default: 0] += 1
            latestRawCandidateDebugSummary = Self.outputDebugSummary(output)
        }

        if sequenceResult.summary.pauseCandidatesRejectedByDuration > 0 {
            rejectedCountByReason[.tooShort, default: 0] += sequenceResult.summary.pauseCandidatesRejectedByDuration
        }
        if sequenceResult.summary.pauseCandidatesRejectedByNoise > 0 {
            rejectedCountByReason[.likelyEnvironmentalNoise, default: 0] += sequenceResult.summary.pauseCandidatesRejectedByNoise
            rejectedCountByReason[.noiseContaminated, default: 0] += sequenceResult.summary.pauseCandidatesRejectedByNoise
        }
        if sequenceResult.summary.pauseCandidatesRejectedByNoRecovery > 0 {
            rejectedCountByReason[.noRecoveryPattern, default: 0] += sequenceResult.summary.pauseCandidatesRejectedByNoRecovery
        }
        if sequenceResult.summary.pauseCandidatesRejectedByInsufficientContext > 0 {
            rejectedCountByReason[.insufficientBreathingContext, default: 0] += sequenceResult.summary.pauseCandidatesRejectedByInsufficientContext
        }
        if sequenceResult.summary.pauseCandidatesRejectedByLikelySilence > 0 {
            rejectedCountByReason[.likelySilenceOnly, default: 0] += sequenceResult.summary.pauseCandidatesRejectedByLikelySilence
        }
    }

    public func record(finalEvents: [SleepEvent]) {
        finalEventCountByType = finalEvents.reduce(into: [SleepEventType: Int]()) { result, event in
            result[event.type, default: 0] += 1
        }
    }

    public func addNote(_ note: String) {
        let trimmedNote = note.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedNote.isEmpty else { return }
        notes.append(trimmedNote)
    }

    public func finalize(
        endedAt: Date,
        metrics: AudioCaptureMetrics
    ) -> DetectorDiagnostics? {
        guard let sessionId, let startedAt else { return nil }

        return DetectorDiagnostics(
            sessionId: sessionId,
            startedAt: startedAt,
            endedAt: endedAt,
            detectorBackend: detectorBackend,
            modelInstalled: modelInstalled,
            modelFallbackCount: modelFallbackCount,
            audioChunkCount: max(metrics.receivedChunkCount, analyzedChunkCount),
            analyzedChunkCount: analyzedChunkCount,
            receivedAudioSeconds: metrics.receivedAudioSeconds,
            analyzedAudioSeconds: metrics.analyzedAudioSeconds,
            audioCoverageRatio: metrics.audioCoverageRatio,
            rawCandidateCount: rawCandidateCountByType.values.reduce(0, +),
            rawCandidateCountByType: rawCandidateCountByType,
            preSmoothingCandidateCount: preSmoothingCandidateCount,
            postSmoothingEventCount: postSmoothingEventCount,
            preSmoothingCandidateCountByType: preSmoothingCandidateCountByType,
            postSmoothingEventCountByType: postSmoothingEventCountByType,
            finalEventCountByType: finalEventCountByType,
            rejectedCountByReason: rejectedCountByReason,
            snoreLikeFeatureCandidateCount: snoreLikeFeatureCandidateCount,
            snoreLikeFeatureRejectedCount: snoreLikeFeatureRejectedCount,
            snoreLikeFeatureRejectReasonCounts: snoreLikeFeatureRejectReasonCounts,
            confidenceHistogram: confidenceHistogram,
            rmsSummary: SummaryStats.make(values: rmsValues),
            energySummary: SummaryStats.make(values: energyValues),
            zeroCrossingRateSummary: SummaryStats.make(values: zeroCrossingRateValues),
            spectralCentroidSummary: SummaryStats.make(values: spectralCentroidValues),
            lowBandEnergySummary: SummaryStats.make(values: lowBandEnergyValues),
            midBandEnergySummary: SummaryStats.make(values: midBandEnergyValues),
            highBandEnergySummary: SummaryStats.make(values: highBandEnergyValues),
            thresholdsSnapshot: thresholdsSnapshot,
            tuningProfile: tuningProfile,
            eventAudioSampleStorageEnabled: eventAudioSampleStorageEnabled,
            lowActivityObservedCount: sequenceSummary.lowActivityObservedCount,
            lowActivityDurationTotal: sequenceSummary.lowActivityDurationTotal,
            lowActivityCandidateCount: sequenceSummary.lowActivityCandidateCount,
            noiseContaminatedLowActivityCount: sequenceSummary.noiseContaminatedLowActivityCount,
            recoveryPatternCount: sequenceSummary.recoveryPatternCount,
            pauseCandidatesRejectedByNoise: sequenceSummary.pauseCandidatesRejectedByNoise,
            pauseCandidatesRejectedByDuration: sequenceSummary.pauseCandidatesRejectedByDuration,
            pauseCandidatesRejectedByNoRecovery: sequenceSummary.pauseCandidatesRejectedByNoRecovery,
            pauseCandidatesRejectedByInsufficientContext: sequenceSummary.pauseCandidatesRejectedByInsufficientContext,
            pauseCandidatesRejectedByLikelySilence: sequenceSummary.pauseCandidatesRejectedByLikelySilence,
            pauseCandidatesPromotedByGasp: sequenceSummary.pauseCandidatesPromotedByGasp,
            latestBreathingActivityScore: sequenceSummary.latestBreathingActivityScore,
            latestLowActivityDurationSeconds: sequenceSummary.latestLowActivityDurationSeconds,
            latestRecoveryPatternDetected: sequenceSummary.latestRecoveryPatternDetected,
            latestPauseCandidateConfidence: sequenceSummary.latestPauseCandidateConfidence,
            latestPauseCandidateRejectedReason: sequenceSummary.latestPauseCandidateRejectedReason,
            latestFeatureDebugSummary: latestFeatureDebugSummary,
            latestRawCandidateDebugSummary: latestRawCandidateDebugSummary,
            notes: notes
        )
    }

    private func incrementReject(_ reason: RejectReason) {
        rejectedCountByReason[reason, default: 0] += 1
    }

    private func snoreLikeFeatureObservation(
        for features: AudioFeatures
    ) -> (isCandidate: Bool, rejectReasons: [RejectReason]) {
        let silenceRMS = thresholdsSnapshot["rule.silenceRMS"]
            ?? thresholdsSnapshot["tuning.silenceRmsThreshold"]
            ?? 0.01
        let snoreRMS = thresholdsSnapshot["rule.snoreRMS"]
            ?? thresholdsSnapshot["tuning.snoreRmsThreshold"]
            ?? 0.05
        let snoreEnergy = thresholdsSnapshot["tuning.snoreEnergyThreshold"] ?? snoreRMS * snoreRMS
        let lowLevelSnoreRMS = thresholdsSnapshot["rule.lowLevelSnoreRMS"] ?? max(silenceRMS * 2.2, snoreRMS * 0.55)
        let lowLevelSnoreEnergy = thresholdsSnapshot["rule.lowLevelSnoreEnergy"] ?? lowLevelSnoreRMS * lowLevelSnoreRMS * 0.65
        let lowLevelSnoreLowBandRatio = thresholdsSnapshot["rule.lowLevelSnoreLowBandRatio"] ?? 0.64
        let snoreRelativeEnergyRatio = thresholdsSnapshot["rule.snoreRelativeEnergyRatio"] ?? 1.35
        let relativeEnergy = relativeEnergyRatio(features: features, silenceRMS: silenceRMS)
        let nearRMS = features.rms >= lowLevelSnoreRMS
        let nearEnergy = features.energy >= min(snoreEnergy * 0.55, lowLevelSnoreEnergy)
        let hasLowBandHint = features.lowFrequencyEnergyRatio >= 0.30
        let hasStrongDistanceLowBandHint = features.lowFrequencyEnergyRatio >= lowLevelSnoreLowBandRatio
        let hasSnoreLikeCadence = features.zeroCrossingRate <= 0.60
        let distantLowInputHint = RejectReason.isDistantLowInputSnoreLikeHint(
            features: features,
            silenceRMS: silenceRMS,
            lowLevelSnoreRMS: lowLevelSnoreRMS,
            lowLevelSnoreLowBandRatio: lowLevelSnoreLowBandRatio
        )
        let isCandidate = distantLowInputHint || (!features.isLikelySilence
            && features.rms >= silenceRMS
            && (nearRMS || nearEnergy)
            && (hasLowBandHint || hasStrongDistanceLowBandHint || hasSnoreLikeCadence))

        guard isCandidate else { return (false, []) }

        var reasons: [RejectReason] = []
        if distantLowInputHint {
            reasons.append(.inputLevelTooLow)
        }
        if features.rms < snoreRMS {
            reasons.append(.belowRmsThreshold)
        }
        if features.energy < snoreEnergy {
            reasons.append(.belowEnergyThreshold)
        }
        if features.rms >= lowLevelSnoreRMS,
           features.rms < snoreRMS {
            if features.energy < lowLevelSnoreEnergy || relativeEnergy < snoreRelativeEnergyRatio {
                reasons.append(.belowEnergyThreshold)
            }
        }
        if features.lowFrequencyEnergyRatio < 0.45 {
            reasons.append(.belowLowBandRatio)
        }
        if features.rms >= lowLevelSnoreRMS,
           features.rms < snoreRMS,
           features.lowFrequencyEnergyRatio < lowLevelSnoreLowBandRatio {
            reasons.append(.belowLowBandRatio)
        }
        if features.rms >= lowLevelSnoreRMS,
           features.rms < snoreRMS {
            if features.zeroCrossingRate > 0.24 ||
                features.highBandEnergy > 0.18 ||
                features.spectralCentroid > 950 {
                reasons.append(.likelyEnvironmentalNoise)
            }
        }
        if features.rms >= snoreRMS,
           features.rms < 0.05 {
            if features.lowFrequencyEnergyRatio >= 0.45,
               features.lowFrequencyEnergyRatio < 0.58 {
                reasons.append(.belowLowBandRatio)
            }
            if features.zeroCrossingRate > 0.28 ||
                features.highBandEnergy > 0.22 ||
                features.spectralCentroid > 1_200 {
                reasons.append(.likelyEnvironmentalNoise)
            }
        }
        if features.zeroCrossingRate > 0.45 ||
            features.spectralCentroid >= 2_200 ||
            features.highBandEnergy >= 0.30 {
            reasons.append(.likelyEnvironmentalNoise)
        }
        if features.isLikelySilence {
            reasons.append(.likelySilence)
        }

        return (true, uniqueRejectReasons(reasons.isEmpty ? [.unknown] : reasons))
    }

    private func relativeEnergyRatio(features: AudioFeatures, silenceRMS: Double) -> Double {
        let floor = max(features.estimatedNoiseLevel, silenceRMS * 0.75, 0.0001)
        let floorEnergy = max(floor * floor, 0.000_000_01)
        guard features.energy.isFinite else { return 0 }
        return max(0, features.energy / floorEnergy)
    }

    private func uniqueRejectReasons(_ reasons: [RejectReason]) -> [RejectReason] {
        reasons.reduce(into: [RejectReason]()) { result, reason in
            if !result.contains(reason) {
                result.append(reason)
            }
        }
    }

    private func appendFinite(_ value: Double, to values: inout [Double]) {
        guard value.isFinite else { return }
        values.append(value)
    }

    private static func confidenceBucket(for confidence: Double) -> String {
        let clamped = min(max(confidence.isFinite ? confidence : 0, 0), 1)
        switch clamped {
        case 0..<0.2:
            return "0.0-0.2"
        case 0.2..<0.4:
            return "0.2-0.4"
        case 0.4..<0.6:
            return "0.4-0.6"
        case 0.6..<0.8:
            return "0.6-0.8"
        default:
            return "0.8-1.0"
        }
    }

    private static func outputDebugSummary(_ output: DetectorOutput) -> String {
        let reason = output.debugReason.map { " reason=\($0)" } ?? ""
        return String(
            format: "%@ confidence=%.3f duration=%.2fs%@",
            output.eventType.rawValue,
            output.confidence,
            output.duration,
            reason
        )
    }
}
