import Foundation

public struct DetectionSmoothingPolicy: Equatable, Sendable {
    public var minimumEventDuration: TimeInterval
    public var maximumMergeGap: TimeInterval
    public var confidenceThreshold: Double
    public var mergeSameTypeEvents: Bool
    public var bruxismLikeMinimumEventDuration: TimeInterval
    public var bruxismLikeMaximumMergeGap: TimeInterval
    public var bruxismLikeConfidenceThreshold: Double
    public var bruxismLikeEnvironmentalOverlapPenalty: Double

    public init(
        minimumEventDuration: TimeInterval = 0.2,
        maximumMergeGap: TimeInterval = 1.0,
        confidenceThreshold: Double = 0.35,
        mergeSameTypeEvents: Bool = true,
        bruxismLikeMinimumEventDuration: TimeInterval = 0.12,
        bruxismLikeMaximumMergeGap: TimeInterval = 1.6,
        bruxismLikeConfidenceThreshold: Double = 0.45,
        bruxismLikeEnvironmentalOverlapPenalty: Double = 0.20
    ) {
        self.minimumEventDuration = max(0, minimumEventDuration)
        self.maximumMergeGap = max(0, maximumMergeGap)
        self.confidenceThreshold = min(max(confidenceThreshold, 0), 1)
        self.mergeSameTypeEvents = mergeSameTypeEvents
        self.bruxismLikeMinimumEventDuration = max(0, bruxismLikeMinimumEventDuration)
        self.bruxismLikeMaximumMergeGap = max(0, bruxismLikeMaximumMergeGap)
        self.bruxismLikeConfidenceThreshold = min(max(bruxismLikeConfidenceThreshold, 0), 1)
        self.bruxismLikeEnvironmentalOverlapPenalty = min(max(bruxismLikeEnvironmentalOverlapPenalty, 0), 1)
    }

    public func apply(to outputs: [DetectorOutput]) -> [DetectorOutput] {
        let environmentalNoiseOutputs = outputs.filter { $0.eventType == .environmentalNoise }
        let eligibleOutputs = outputs
            .compactMap { output in
                adjustedOutput(output, environmentalNoiseOutputs: environmentalNoiseOutputs)
            }
            .filter { output in
                output.confidence >= confidenceThreshold(for: output.eventType) &&
                    output.duration.isFinite &&
                    output.duration > 0
            }
            .sorted { lhs, rhs in
                if lhs.startedAt == rhs.startedAt {
                    return lhs.eventType.rawValue < rhs.eventType.rawValue
                }
                return lhs.startedAt < rhs.startedAt
            }

        let mergedOutputs: [DetectorOutput]
        if mergeSameTypeEvents {
            mergedOutputs = eligibleOutputs.reduce(into: [DetectorOutput]()) { partialResult, output in
                guard let lastOutput = partialResult.last,
                      lastOutput.eventType == output.eventType,
                      output.startedAt.timeIntervalSince(lastOutput.endedAt) <= maximumMergeGap(for: output.eventType) else {
                    partialResult.append(output)
                    return
                }

                partialResult[partialResult.count - 1] = merge(lastOutput, output)
            }
        } else {
            mergedOutputs = eligibleOutputs
        }

        return mergedOutputs.filter { output in
            output.duration >= minimumEventDuration(for: output.eventType)
        }
    }

    private func adjustedOutput(
        _ output: DetectorOutput,
        environmentalNoiseOutputs: [DetectorOutput]
    ) -> DetectorOutput? {
        guard output.eventType == .bruxismLike,
              environmentalNoiseOutputs.contains(where: { overlaps(output, $0) }) else {
            return output
        }

        let adjustedConfidence = output.confidence - bruxismLikeEnvironmentalOverlapPenalty
        let reason = [
            output.debugReason,
            "환경 소음과 겹쳐 이갈이 의심 소리 confidence를 낮췄습니다. 사용자 확인이 필요합니다."
        ].compactMap { $0 }.joined(separator: " / ")

        guard adjustedConfidence >= bruxismLikeConfidenceThreshold else {
            return nil
        }

        return DetectorOutput(
            eventType: .unknown,
            startedAt: output.startedAt,
            endedAt: output.endedAt,
            confidence: adjustedConfidence,
            intensity: output.intensity,
            debugReason: reason
        )
    }

    private func confidenceThreshold(for type: SleepEventType) -> Double {
        switch type {
        case .bruxismLike:
            max(confidenceThreshold, bruxismLikeConfidenceThreshold)
        default:
            confidenceThreshold
        }
    }

    private func minimumEventDuration(for type: SleepEventType) -> TimeInterval {
        switch type {
        case .bruxismLike:
            max(minimumEventDuration, bruxismLikeMinimumEventDuration)
        default:
            minimumEventDuration
        }
    }

    private func maximumMergeGap(for type: SleepEventType) -> TimeInterval {
        switch type {
        case .bruxismLike:
            max(maximumMergeGap, bruxismLikeMaximumMergeGap)
        default:
            maximumMergeGap
        }
    }

    private func overlaps(_ lhs: DetectorOutput, _ rhs: DetectorOutput) -> Bool {
        lhs.startedAt < rhs.endedAt && rhs.startedAt < lhs.endedAt
    }

    private func merge(_ lhs: DetectorOutput, _ rhs: DetectorOutput) -> DetectorOutput {
        let startedAt = min(lhs.startedAt, rhs.startedAt)
        let endedAt = max(lhs.endedAt, rhs.endedAt)
        let confidence = max(lhs.confidence, rhs.confidence)
        let intensity = max(lhs.intensity, rhs.intensity)
        let reasons: [String] = [lhs.debugReason, rhs.debugReason].compactMap { reason -> String? in
            guard let reason, !reason.isEmpty else { return nil }
            return reason
        }

        return DetectorOutput(
            eventType: lhs.eventType,
            startedAt: startedAt,
            endedAt: endedAt,
            confidence: confidence,
            intensity: intensity,
            debugReason: reasons.isEmpty ? nil : reasons.joined(separator: " / ")
        )
    }
}
