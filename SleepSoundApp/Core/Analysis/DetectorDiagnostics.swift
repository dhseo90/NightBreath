import Foundation

public enum RejectReason: String, Codable, CaseIterable, Sendable {
    case belowRmsThreshold
    case belowEnergyThreshold
    case belowConfidenceThreshold
    case tooShort
    case mergedIntoNearbyEvent
    case likelyEnvironmentalNoise
    case likelySilence
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
        case .belowConfidenceThreshold:
            "confidence 낮음"
        case .tooShort:
            "너무 짧음"
        case .mergedIntoNearbyEvent:
            "가까운 이벤트로 병합"
        case .likelyEnvironmentalNoise:
            "환경 소음 가능성"
        case .likelySilence:
            "무음/저활동 가능성"
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
    public var rejectedCountByReason: [RejectReason: Int]

    public init(
        preSmoothingCandidateCount: Int = 0,
        postSmoothingEventCount: Int = 0,
        rejectedCountByReason: [RejectReason: Int] = [:]
    ) {
        self.preSmoothingCandidateCount = max(0, preSmoothingCandidateCount)
        self.postSmoothingEventCount = max(0, postSmoothingEventCount)
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
    public var analyzedChunkCount: Int
    public var receivedAudioSeconds: TimeInterval
    public var analyzedAudioSeconds: TimeInterval
    public var audioCoverageRatio: Double
    public var rawCandidateCount: Int
    public var rawCandidateCountByType: [SleepEventType: Int]
    public var preSmoothingCandidateCount: Int
    public var postSmoothingEventCount: Int
    public var finalEventCountByType: [SleepEventType: Int]
    public var rejectedCountByReason: [RejectReason: Int]
    public var confidenceHistogram: [String: Int]
    public var rmsSummary: SummaryStats
    public var energySummary: SummaryStats
    public var zeroCrossingRateSummary: SummaryStats
    public var spectralCentroidSummary: SummaryStats
    public var lowBandEnergySummary: SummaryStats
    public var midBandEnergySummary: SummaryStats
    public var highBandEnergySummary: SummaryStats
    public var thresholdsSnapshot: [String: Double]
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
    public var notes: [String]

    public init(
        sessionId: UUID,
        startedAt: Date,
        endedAt: Date? = nil,
        detectorBackend: String,
        modelInstalled: Bool,
        modelFallbackCount: Int = 0,
        analyzedChunkCount: Int = 0,
        receivedAudioSeconds: TimeInterval = 0,
        analyzedAudioSeconds: TimeInterval = 0,
        audioCoverageRatio: Double = 0,
        rawCandidateCount: Int = 0,
        rawCandidateCountByType: [SleepEventType: Int] = [:],
        preSmoothingCandidateCount: Int = 0,
        postSmoothingEventCount: Int = 0,
        finalEventCountByType: [SleepEventType: Int] = [:],
        rejectedCountByReason: [RejectReason: Int] = [:],
        confidenceHistogram: [String: Int] = [:],
        rmsSummary: SummaryStats = SummaryStats(),
        energySummary: SummaryStats = SummaryStats(),
        zeroCrossingRateSummary: SummaryStats = SummaryStats(),
        spectralCentroidSummary: SummaryStats = SummaryStats(),
        lowBandEnergySummary: SummaryStats = SummaryStats(),
        midBandEnergySummary: SummaryStats = SummaryStats(),
        highBandEnergySummary: SummaryStats = SummaryStats(),
        thresholdsSnapshot: [String: Double] = [:],
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
        notes: [String] = []
    ) {
        self.sessionId = sessionId
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.detectorBackend = detectorBackend
        self.modelInstalled = modelInstalled
        self.modelFallbackCount = max(0, modelFallbackCount)
        self.analyzedChunkCount = max(0, analyzedChunkCount)
        self.receivedAudioSeconds = max(0, receivedAudioSeconds)
        self.analyzedAudioSeconds = max(0, analyzedAudioSeconds)
        self.audioCoverageRatio = Self.clampedRatio(audioCoverageRatio)
        self.rawCandidateCount = max(0, rawCandidateCount)
        self.rawCandidateCountByType = rawCandidateCountByType
        self.preSmoothingCandidateCount = max(0, preSmoothingCandidateCount)
        self.postSmoothingEventCount = max(0, postSmoothingEventCount)
        self.finalEventCountByType = finalEventCountByType
        self.rejectedCountByReason = rejectedCountByReason
        self.confidenceHistogram = confidenceHistogram
        self.rmsSummary = rmsSummary
        self.energySummary = energySummary
        self.zeroCrossingRateSummary = zeroCrossingRateSummary
        self.spectralCentroidSummary = spectralCentroidSummary
        self.lowBandEnergySummary = lowBandEnergySummary
        self.midBandEnergySummary = midBandEnergySummary
        self.highBandEnergySummary = highBandEnergySummary
        self.thresholdsSnapshot = thresholdsSnapshot.filter { $0.value.isFinite }
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
        self.notes = notes
    }

    public var topRejectReasons: [(RejectReason, Int)] {
        rejectedCountByReason.sorted { lhs, rhs in
            if lhs.value == rhs.value {
                return lhs.key.rawValue < rhs.key.rawValue
            }
            return lhs.value > rhs.value
        }
    }

    public var summaryTextForZeroEvents: String? {
        guard finalEventCountByType.values.reduce(0, +) == 0 else { return nil }
        guard analyzedChunkCount > 0 else {
            return "분석된 오디오 chunk가 없어 detector 요약을 만들 수 없습니다."
        }
        if rawCandidateCount == 0 {
            return "오디오 입력은 수신되었지만 detector 기준을 통과한 raw 후보가 없었습니다."
        }
        return "raw 후보는 있었지만 smoothing 또는 최종 이벤트 기준을 통과한 이벤트가 없었습니다."
    }

    private static func clampedRatio(_ value: Double) -> Double {
        guard value.isFinite else { return 0 }
        return min(max(value, 0), 1)
    }
}

public final class DetectorDiagnosticsCollector {
    private var sessionId: UUID?
    private var startedAt: Date?
    private var detectorBackend: String = SleepDetectionBackend.ruleBased.displayName
    private var modelInstalled = false
    private var thresholdsSnapshot: [String: Double] = [:]
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
    private var finalEventCountByType: [SleepEventType: Int] = [:]
    private var sequenceSummary = SuspectedBreathingPauseSequenceSummary()
    private var notes: [String] = []

    public init() {}

    public func reset(
        sessionId: UUID,
        startedAt: Date,
        detectorBackend: String,
        modelInstalled: Bool,
        thresholdsSnapshot: [String: Double],
        eventAudioSampleStorageEnabled: Bool
    ) {
        self.sessionId = sessionId
        self.startedAt = startedAt
        self.detectorBackend = detectorBackend
        self.modelInstalled = modelInstalled
        self.thresholdsSnapshot = thresholdsSnapshot.filter { $0.value.isFinite }
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
        finalEventCountByType.removeAll(keepingCapacity: true)
        sequenceSummary = SuspectedBreathingPauseSequenceSummary()
        notes.removeAll(keepingCapacity: true)
    }

    public func record(features: AudioFeatures, outputs: [DetectorOutput]) {
        analyzedChunkCount += 1
        appendFinite(features.rms, to: &rmsValues)
        appendFinite(features.energy, to: &energyValues)
        appendFinite(features.zeroCrossingRate, to: &zeroCrossingRateValues)
        appendFinite(features.spectralCentroid, to: &spectralCentroidValues)
        appendFinite(features.lowBandEnergy, to: &lowBandEnergyValues)
        appendFinite(features.midBandEnergy, to: &midBandEnergyValues)
        appendFinite(features.highBandEnergy, to: &highBandEnergyValues)

        if outputs.isEmpty {
            for reason in inferredRejectReasons(for: features) {
                incrementReject(reason)
            }
            return
        }

        for output in outputs {
            rawCandidateCountByType[output.eventType, default: 0] += 1
            confidenceHistogram[Self.confidenceBucket(for: output.confidence), default: 0] += 1
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
        for (reason, count) in smoothingDiagnostics.rejectedCountByReason {
            rejectedCountByReason[reason, default: 0] += count
        }
    }

    public func record(sequenceResult: SuspectedBreathingPauseSequenceResult) {
        sequenceSummary = sequenceResult.summary

        for output in sequenceResult.outputs {
            rawCandidateCountByType[output.eventType, default: 0] += 1
            confidenceHistogram[Self.confidenceBucket(for: output.confidence), default: 0] += 1
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
            analyzedChunkCount: analyzedChunkCount,
            receivedAudioSeconds: metrics.receivedAudioSeconds,
            analyzedAudioSeconds: metrics.analyzedAudioSeconds,
            audioCoverageRatio: metrics.audioCoverageRatio,
            rawCandidateCount: rawCandidateCountByType.values.reduce(0, +),
            rawCandidateCountByType: rawCandidateCountByType,
            preSmoothingCandidateCount: preSmoothingCandidateCount,
            postSmoothingEventCount: postSmoothingEventCount,
            finalEventCountByType: finalEventCountByType,
            rejectedCountByReason: rejectedCountByReason,
            confidenceHistogram: confidenceHistogram,
            rmsSummary: SummaryStats.make(values: rmsValues),
            energySummary: SummaryStats.make(values: energyValues),
            zeroCrossingRateSummary: SummaryStats.make(values: zeroCrossingRateValues),
            spectralCentroidSummary: SummaryStats.make(values: spectralCentroidValues),
            lowBandEnergySummary: SummaryStats.make(values: lowBandEnergyValues),
            midBandEnergySummary: SummaryStats.make(values: midBandEnergyValues),
            highBandEnergySummary: SummaryStats.make(values: highBandEnergyValues),
            thresholdsSnapshot: thresholdsSnapshot,
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
            notes: notes
        )
    }

    private func inferredRejectReasons(for features: AudioFeatures) -> [RejectReason] {
        var reasons: [RejectReason] = []
        let silenceRMS = thresholdsSnapshot["rule.silenceRMS"] ?? 0.01
        let snoreRMS = thresholdsSnapshot["rule.snoreRMS"] ?? 0.05

        if features.isLikelySilence || features.rms < silenceRMS {
            reasons.append(.likelySilence)
        }
        if features.rms < snoreRMS {
            reasons.append(.belowRmsThreshold)
        }
        if features.energy < snoreRMS * snoreRMS {
            reasons.append(.belowEnergyThreshold)
        }
        if reasons.isEmpty {
            reasons.append(.unknown)
        }
        return reasons
    }

    private func incrementReject(_ reason: RejectReason) {
        rejectedCountByReason[reason, default: 0] += 1
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
}
