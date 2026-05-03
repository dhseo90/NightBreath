import Foundation

public struct SuspectedBreathingPauseSequenceSummary: Codable, Equatable, Sendable {
    public var lowActivityCandidateCount: Int
    public var noiseContaminatedLowActivityCount: Int
    public var recoveryPatternCount: Int
    public var pauseCandidatesRejectedByNoise: Int
    public var pauseCandidatesRejectedByDuration: Int
    public var pauseCandidatesPromotedByGasp: Int
    public var latestBreathingActivityScore: Double
    public var latestLowActivityDurationSeconds: TimeInterval
    public var latestRecoveryPatternDetected: Bool
    public var latestPauseCandidateConfidence: Double
    public var latestPauseCandidateRejectedReason: String?

    public init(
        lowActivityCandidateCount: Int = 0,
        noiseContaminatedLowActivityCount: Int = 0,
        recoveryPatternCount: Int = 0,
        pauseCandidatesRejectedByNoise: Int = 0,
        pauseCandidatesRejectedByDuration: Int = 0,
        pauseCandidatesPromotedByGasp: Int = 0,
        latestBreathingActivityScore: Double = 0,
        latestLowActivityDurationSeconds: TimeInterval = 0,
        latestRecoveryPatternDetected: Bool = false,
        latestPauseCandidateConfidence: Double = 0,
        latestPauseCandidateRejectedReason: String? = nil
    ) {
        self.lowActivityCandidateCount = max(0, lowActivityCandidateCount)
        self.noiseContaminatedLowActivityCount = max(0, noiseContaminatedLowActivityCount)
        self.recoveryPatternCount = max(0, recoveryPatternCount)
        self.pauseCandidatesRejectedByNoise = max(0, pauseCandidatesRejectedByNoise)
        self.pauseCandidatesRejectedByDuration = max(0, pauseCandidatesRejectedByDuration)
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
    public var maximumLowActivityGapSeconds: TimeInterval
    public var minimumOutputConfidence: Double

    public init(
        estimator: BreathingActivityEstimator = BreathingActivityEstimator(),
        minimumLowActivityDuration: TimeInterval = 10,
        recoveryWindowSeconds: TimeInterval = 8,
        maximumLowActivityGapSeconds: TimeInterval = 1.5,
        minimumOutputConfidence: Double = 0.30
    ) {
        self.estimator = estimator
        self.minimumLowActivityDuration = max(1, minimumLowActivityDuration)
        self.recoveryWindowSeconds = max(0, recoveryWindowSeconds)
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

        for run in lowActivityRuns {
            summary.latestBreathingActivityScore = run.averageActivityScore
            summary.latestLowActivityDurationSeconds = run.duration

            guard run.duration >= minimumLowActivityDuration else {
                summary.pauseCandidatesRejectedByDuration += 1
                summary.latestPauseCandidateRejectedReason = "저활동 지속 시간이 \(Int(minimumLowActivityDuration))초보다 짧음"
                continue
            }

            summary.lowActivityCandidateCount += 1
            if run.isNoiseContaminated {
                summary.noiseContaminatedLowActivityCount += 1
            }

            let recovery = recoveryPattern(after: run, contextOutputs: contextOutputs)
            if recovery.detected {
                summary.recoveryPatternCount += 1
            }
            if recovery.hasGaspLike {
                summary.pauseCandidatesPromotedByGasp += 1
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

            if recovery.hasGaspLike {
                confidence += 0.22
            }
            if recovery.hasSnoreResume {
                confidence += 0.10
            }
            if run.isNoiseContaminated || environmentalOverlap != nil {
                confidence -= 0.14
            }
            if let movementOverlap {
                confidence -= movementOverlap.confidence >= 0.55 || movementOverlap.intensity >= 0.55 ? 0.20 : 0.12
            }

            confidence = Self.clamp(confidence)
            summary.latestRecoveryPatternDetected = recovery.detected
            summary.latestPauseCandidateConfidence = confidence

            if run.isStronglyNoiseContaminated && !recovery.detected && confidence < minimumOutputConfidence {
                summary.pauseCandidatesRejectedByNoise += 1
                summary.latestPauseCandidateRejectedReason = "환경 소음 영향이 커 후보에서 제외"
                continue
            }

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

    private func recoveryPattern(
        after run: LowActivityRun,
        contextOutputs: [DetectorOutput]
    ) -> RecoveryPattern {
        let recoveryStart = run.endedAt
        let recoveryEnd = run.endedAt.addingTimeInterval(recoveryWindowSeconds)
        let candidates = contextOutputs.filter { output in
            output.startedAt >= recoveryStart && output.startedAt <= recoveryEnd
        }

        let hasGaspLike = candidates.contains { $0.eventType == .gaspLike }
        let hasSnoreResume = candidates.contains { $0.eventType == .snore }
        return RecoveryPattern(hasGaspLike: hasGaspLike, hasSnoreResume: hasSnoreResume)
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
        if movementOverlap != nil {
            reasons.append("움직임 의심 소리와 겹쳐 confidence 하향")
        }
        reasons.append("오디오 기반 의심 패턴이며 진단 목적 아님")

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
    var estimates: [BreathingActivityEstimate]

    init(firstEstimate: BreathingActivityEstimate) {
        estimates = [firstEstimate]
    }

    var startedAt: Date {
        estimates.first?.startedAt ?? Date(timeIntervalSinceReferenceDate: 0)
    }

    var endedAt: Date {
        estimates.map(\.endedAt).max() ?? startedAt
    }

    var duration: TimeInterval {
        max(0, endedAt.timeIntervalSince(startedAt))
    }

    var interval: DateInterval {
        DateInterval(start: startedAt, end: endedAt)
    }

    var averageActivityScore: Double {
        guard !estimates.isEmpty else { return 0 }
        let sum = estimates.reduce(0) { $0 + $1.breathingActivityScore }
        return sum / Double(estimates.count)
    }

    var isNoiseContaminated: Bool {
        estimates.contains { $0.isNoiseContaminated }
    }

    var isStronglyNoiseContaminated: Bool {
        guard !estimates.isEmpty else { return false }
        let contaminatedCount = estimates.filter(\.isNoiseContaminated).count
        return Double(contaminatedCount) / Double(estimates.count) >= 0.70
    }

    mutating func append(_ estimate: BreathingActivityEstimate) {
        estimates.append(estimate)
    }
}

private struct RecoveryPattern: Equatable {
    var hasGaspLike: Bool
    var hasSnoreResume: Bool

    var detected: Bool {
        hasGaspLike || hasSnoreResume
    }
}
