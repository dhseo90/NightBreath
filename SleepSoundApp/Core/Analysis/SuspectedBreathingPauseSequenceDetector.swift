import Foundation

public struct SuspectedBreathingPauseSequenceSummary: Codable, Equatable, Sendable {
    public var lowActivityObservedCount: Int
    public var lowActivityDurationTotal: TimeInterval
    public var lowActivityCandidateCount: Int
    public var noiseContaminatedLowActivityCount: Int
    public var recoveryPatternCount: Int
    public var pauseCandidatesRejectedByNoise: Int
    public var pauseCandidatesRejectedByDuration: Int
    public var pauseCandidatesRejectedByNoRecovery: Int
    public var pauseCandidatesRejectedByInsufficientContext: Int
    public var pauseCandidatesRejectedByLikelySilence: Int
    public var pauseCandidatesPromotedByGasp: Int
    public var latestBreathingActivityScore: Double
    public var latestLowActivityDurationSeconds: TimeInterval
    public var latestRecoveryPatternDetected: Bool
    public var latestPauseCandidateConfidence: Double
    public var latestPauseCandidateRejectedReason: String?

    public init(
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
        latestPauseCandidateRejectedReason: String? = nil
    ) {
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
        self.latestBreathingActivityScore = Self.clamp(latestBreathingActivityScore)
        self.latestLowActivityDurationSeconds = max(0, latestLowActivityDurationSeconds)
        self.latestRecoveryPatternDetected = latestRecoveryPatternDetected
        self.latestPauseCandidateConfidence = Self.clamp(latestPauseCandidateConfidence)
        self.latestPauseCandidateRejectedReason = latestPauseCandidateRejectedReason
    }

    private static func clamp(_ value: Double) -> Double {
        guard value.isFinite else { return 0 }
        return min(max(value, 0), 1)
    }
}

public struct SuspectedBreathingPauseSequenceResult: Equatable, Sendable {
    public var outputs: [DetectorOutput]
    public var summary: SuspectedBreathingPauseSequenceSummary

    public init(
        outputs: [DetectorOutput] = [],
        summary: SuspectedBreathingPauseSequenceSummary = SuspectedBreathingPauseSequenceSummary()
    ) {
        self.outputs = outputs
        self.summary = summary
    }
}

public struct SuspectedBreathingPauseSequenceDetector: Equatable, Sendable {
    public var estimator: BreathingActivityEstimator
    public var minimumLowActivityDuration: TimeInterval
    public var recoveryWindowSeconds: TimeInterval
    public var priorContextWindowSeconds: TimeInterval
    public var maximumLowActivityGapSeconds: TimeInterval
    public var minimumOutputConfidence: Double

    public init(
        estimator: BreathingActivityEstimator = BreathingActivityEstimator(),
        minimumLowActivityDuration: TimeInterval = 10,
        recoveryWindowSeconds: TimeInterval = 8,
        priorContextWindowSeconds: TimeInterval = 12,
        maximumLowActivityGapSeconds: TimeInterval = 1.5,
        minimumOutputConfidence: Double = 0.30
    ) {
        self.estimator = estimator
        self.minimumLowActivityDuration = max(1, minimumLowActivityDuration)
        self.recoveryWindowSeconds = max(0, recoveryWindowSeconds)
        self.priorContextWindowSeconds = max(0, priorContextWindowSeconds)
        self.maximumLowActivityGapSeconds = max(0, maximumLowActivityGapSeconds)
        self.minimumOutputConfidence = Self.clamp(minimumOutputConfidence)
    }

    public func detect(
        features: [AudioFeatures],
        contextOutputs: [DetectorOutput]
    ) -> SuspectedBreathingPauseSequenceResult {
        let sortedFeatures = features.sorted { lhs, rhs in
            if lhs.startedAt == rhs.startedAt {
                return lhs.endedAt < rhs.endedAt
            }
            return lhs.startedAt < rhs.startedAt
        }
        let estimates = sortedFeatures.map { estimator.estimate(features: $0) }
        let lowActivityRuns = makeLowActivityRuns(from: estimates)

        var outputs: [DetectorOutput] = []
        var summary = SuspectedBreathingPauseSequenceSummary()
        summary.lowActivityObservedCount = lowActivityRuns.count
        summary.lowActivityDurationTotal = lowActivityRuns.reduce(0) { $0 + $1.duration }

        for run in lowActivityRuns {
            summary.latestBreathingActivityScore = run.averageActivityScore
            summary.latestLowActivityDurationSeconds = run.duration

            guard run.duration >= minimumLowActivityDuration else {
                summary.pauseCandidatesRejectedByDuration += 1
                summary.latestPauseCandidateRejectedReason = "저활동 지속 시간이 \(Int(minimumLowActivityDuration))초보다 짧음"
                continue
            }

            let priorContext = priorBreathingContext(
                before: run,
                estimates: estimates,
                contextOutputs: contextOutputs
            )
            let recovery = recoveryPattern(
                after: run,
                estimates: estimates,
                contextOutputs: contextOutputs
            )
            if recovery.detected {
                summary.recoveryPatternCount += 1
            }
            if recovery.hasGaspLike {
                summary.pauseCandidatesPromotedByGasp += 1
            }
            summary.latestRecoveryPatternDetected = recovery.detected

            guard priorContext.detected else {
                summary.pauseCandidatesRejectedByInsufficientContext += 1
                if run.isLikelySilenceOnly {
                    summary.pauseCandidatesRejectedByLikelySilence += 1
                }
                summary.latestPauseCandidateRejectedReason =
                    run.isLikelySilenceOnly
                    ? "likelySilenceOnly: 이전 호흡/코골기 맥락 없이 저활동만 지속"
                    : "insufficientBreathingContext: 이전 호흡/코골기 맥락 부족"
                continue
            }

            guard recovery.detected else {
                summary.pauseCandidatesRejectedByNoRecovery += 1
                summary.latestPauseCandidateRejectedReason = "noRecoveryPattern: 이후 회복 패턴 없음"
                continue
            }

            if run.isStronglyNoiseContaminated {
                summary.pauseCandidatesRejectedByNoise += 1
                summary.latestPauseCandidateRejectedReason = "noiseContaminated: 환경 소음 영향이 커 후보에서 제외"
                continue
            }

            summary.lowActivityCandidateCount += 1
            if run.isNoiseContaminated {
                summary.noiseContaminatedLowActivityCount += 1
            }

            let movementOverlap = strongestOverlap(
                for: .movementLike,
                in: contextOutputs,
                interval: run.interval
            )
            let environmentalOverlap = strongestOverlap(
                for: .environmentalNoise,
                in: contextOutputs,
                interval: run.interval
            )

            var confidence =
                0.42 +
                min((run.duration - minimumLowActivityDuration) / 80, 0.14) +
                (1 - run.averageActivityScore) * 0.16
            if priorContext.hasSnoreContext {
                confidence += 0.08
            }
            if priorContext.hasBreathingActivity {
                confidence += 0.04
            }

            if recovery.hasGaspLike {
                confidence += 0.22
            }
            if recovery.hasSnoreResume {
                confidence += 0.10
            }
            if recovery.hasBreathingActivityResume {
                confidence += 0.06
            }
            if run.isNoiseContaminated || environmentalOverlap != nil {
                confidence -= 0.14
            }
            if let movementOverlap {
                confidence -= movementOverlap.confidence >= 0.55 || movementOverlap.intensity >= 0.55 ? 0.20 : 0.12
            }

            confidence = Self.clamp(confidence)
            summary.latestPauseCandidateConfidence = confidence

            guard confidence >= minimumOutputConfidence else {
                summary.latestPauseCandidateRejectedReason = "confidence 기준 미달"
                continue
            }

            summary.latestPauseCandidateRejectedReason = nil
            outputs.append(makeOutput(run: run, recovery: recovery, movementOverlap: movementOverlap, confidence: confidence))
        }

        return SuspectedBreathingPauseSequenceResult(outputs: outputs, summary: summary)
    }

    private func makeLowActivityRuns(
        from estimates: [BreathingActivityEstimate]
    ) -> [LowActivityRun] {
        var runs: [LowActivityRun] = []
        var current: LowActivityRun?

        for estimate in estimates {
            guard estimate.isLowActivity else {
                if let run = current {
                    runs.append(run)
                    current = nil
                }
                continue
            }

            if var run = current,
               estimate.startedAt.timeIntervalSince(run.endedAt) <= maximumLowActivityGapSeconds {
                run.append(estimate)
                current = run
            } else {
                if let run = current {
                    runs.append(run)
                }
                current = LowActivityRun(firstEstimate: estimate)
            }
        }

        if let current {
            runs.append(current)
        }

        return runs
    }

    private func priorBreathingContext(
        before run: LowActivityRun,
        estimates: [BreathingActivityEstimate],
        contextOutputs: [DetectorOutput]
    ) -> BreathingContext {
        let contextStart = run.startedAt.addingTimeInterval(-priorContextWindowSeconds)
        let hasSnoreContext = contextOutputs.contains { output in
            output.eventType == .snore &&
                output.endedAt <= run.startedAt &&
                output.endedAt >= contextStart
        }
        let hasBreathingActivity = estimates.contains { estimate in
            estimate.endedAt <= run.startedAt &&
                estimate.endedAt >= contextStart &&
                !estimate.isLowActivity &&
                !estimate.isNoiseContaminated &&
                estimate.breathingActivityScore >= estimator.lowActivityScoreThreshold + 0.08
        }
        return BreathingContext(
            hasSnoreContext: hasSnoreContext,
            hasBreathingActivity: hasBreathingActivity
        )
    }

    private func recoveryPattern(
        after run: LowActivityRun,
        estimates: [BreathingActivityEstimate],
        contextOutputs: [DetectorOutput]
    ) -> RecoveryPattern {
        let recoveryStart = run.endedAt
        let recoveryEnd = run.endedAt.addingTimeInterval(recoveryWindowSeconds)
        let candidates = contextOutputs.filter { output in
            output.startedAt >= recoveryStart && output.startedAt <= recoveryEnd
        }

        let hasGaspLike = candidates.contains { $0.eventType == .gaspLike }
        let hasSnoreResume = candidates.contains { $0.eventType == .snore }
        let hasBreathingActivityResume = estimates.contains { estimate in
            estimate.startedAt >= recoveryStart &&
                estimate.startedAt <= recoveryEnd &&
                !estimate.isLowActivity &&
                !estimate.isNoiseContaminated &&
                estimate.breathingActivityScore >= estimator.lowActivityScoreThreshold + 0.08
        }
        return RecoveryPattern(
            hasGaspLike: hasGaspLike,
            hasSnoreResume: hasSnoreResume,
            hasBreathingActivityResume: hasBreathingActivityResume
        )
    }

    private func strongestOverlap(
        for type: SleepEventType,
        in outputs: [DetectorOutput],
        interval: DateInterval
    ) -> DetectorOutput? {
        outputs
            .filter { output in
                output.eventType == type &&
                    output.startedAt < interval.end &&
                    interval.start < output.endedAt
            }
            .max { lhs, rhs in
                max(lhs.confidence, lhs.intensity) < max(rhs.confidence, rhs.intensity)
            }
    }

    private func makeOutput(
        run: LowActivityRun,
        recovery: RecoveryPattern,
        movementOverlap: DetectorOutput?,
        confidence: Double
    ) -> DetectorOutput {
        var reasons = [
            "sequence 기반 저활동 \(Int(run.duration))초",
            String(format: "activityScore=%.3f", run.averageActivityScore)
        ]

        if run.isNoiseContaminated {
            reasons.append("환경 소음 영향으로 confidence 하향")
        }
        if recovery.hasGaspLike {
            reasons.append("이후 gasp-like 회복 호흡 후보로 confidence 상승")
        }
        if recovery.hasSnoreResume {
            reasons.append("이후 코골기 재개 후보로 confidence 상승")
        }
        if recovery.hasBreathingActivityResume {
            reasons.append("이후 호흡 활동 재개로 confidence 상승")
        }
        if movementOverlap != nil {
            reasons.append("움직임 의심 소리와 겹쳐 confidence 하향")
        }
        reasons.append("오디오 기반 의심 패턴이며 개인 참고용")

        return DetectorOutput(
            eventType: .breathingPauseSuspected,
            startedAt: run.startedAt,
            endedAt: run.endedAt,
            confidence: confidence,
            intensity: max(0.10, min(0.45, 1 - run.averageActivityScore)),
            debugReason: reasons.joined(separator: " / ")
        )
    }

    private static func clamp(_ value: Double) -> Double {
        guard value.isFinite else { return 0 }
        return min(max(value, 0), 1)
    }
}

private struct LowActivityRun: Equatable {
    private var estimateCount: Int
    private var activityScoreSum: Double
    private var noiseContaminatedCount: Int
    private var likelySilenceCount: Int
    private var start: Date
    private var end: Date

    init(firstEstimate: BreathingActivityEstimate) {
        estimateCount = 1
        activityScoreSum = firstEstimate.breathingActivityScore
        noiseContaminatedCount = firstEstimate.isNoiseContaminated ? 1 : 0
        likelySilenceCount = firstEstimate.isLikelySilence ? 1 : 0
        start = firstEstimate.startedAt
        end = firstEstimate.endedAt
    }

    var startedAt: Date {
        start
    }

    var endedAt: Date {
        end
    }

    var duration: TimeInterval {
        max(0, endedAt.timeIntervalSince(startedAt))
    }

    var interval: DateInterval {
        DateInterval(start: startedAt, end: endedAt)
    }

    var averageActivityScore: Double {
        guard estimateCount > 0 else { return 0 }
        return activityScoreSum / Double(estimateCount)
    }

    var isNoiseContaminated: Bool {
        noiseContaminatedCount > 0
    }

    var isStronglyNoiseContaminated: Bool {
        guard estimateCount > 0 else { return false }
        return Double(noiseContaminatedCount) / Double(estimateCount) >= 0.70
    }

    var isLikelySilenceOnly: Bool {
        estimateCount > 0 && likelySilenceCount == estimateCount && noiseContaminatedCount == 0
    }

    mutating func append(_ estimate: BreathingActivityEstimate) {
        estimateCount += 1
        activityScoreSum += estimate.breathingActivityScore
        if estimate.isNoiseContaminated {
            noiseContaminatedCount += 1
        }
        if estimate.isLikelySilence {
            likelySilenceCount += 1
        }
        end = max(end, estimate.endedAt)
    }
}

private struct BreathingContext: Equatable {
    var hasSnoreContext: Bool
    var hasBreathingActivity: Bool

    var detected: Bool {
        hasSnoreContext || hasBreathingActivity
    }
}

private struct RecoveryPattern: Equatable {
    var hasGaspLike: Bool
    var hasSnoreResume: Bool
    var hasBreathingActivityResume: Bool

    var detected: Bool {
        hasGaspLike || hasSnoreResume || hasBreathingActivityResume
    }
}
