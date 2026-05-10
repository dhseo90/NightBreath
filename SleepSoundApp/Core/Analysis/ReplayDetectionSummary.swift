import Foundation

public struct ReplayDetectionSummary: Codable, Equatable, Sendable {
    public var label: String
    public var chunkCount: Int
    public var audioSeconds: TimeInterval
    public var rawCandidateCount: Int
    public var finalEventCount: Int
    public var rawCandidateCountByType: [SleepEventType: Int]
    public var finalEventCountByType: [SleepEventType: Int]
    public var rejectedCountByReason: [RejectReason: Int]
    public var rmsSummary: SummaryStats
    public var energySummary: SummaryStats

    public init(
        label: String,
        chunkCount: Int,
        audioSeconds: TimeInterval,
        rawCandidateCount: Int,
        finalEventCount: Int,
        rawCandidateCountByType: [SleepEventType: Int],
        finalEventCountByType: [SleepEventType: Int],
        rejectedCountByReason: [RejectReason: Int],
        rmsSummary: SummaryStats,
        energySummary: SummaryStats
    ) {
        self.label = label
        self.chunkCount = max(0, chunkCount)
        self.audioSeconds = max(0, audioSeconds)
        self.rawCandidateCount = max(0, rawCandidateCount)
        self.finalEventCount = max(0, finalEventCount)
        self.rawCandidateCountByType = rawCandidateCountByType
        self.finalEventCountByType = finalEventCountByType
        self.rejectedCountByReason = rejectedCountByReason
        self.rmsSummary = rmsSummary
        self.energySummary = energySummary
    }

    public var rawSnoreCandidateCount: Int {
        rawCandidateCountByType[.snore] ?? 0
    }

    public var finalSnoreEventCount: Int {
        finalEventCountByType[.snore] ?? 0
    }

    public var briefText: String {
        let rawText = Self.countText(rawCandidateCountByType)
        let finalText = Self.countText(finalEventCountByType)
        return "\(label): chunks=\(chunkCount), audio=\(String(format: "%.1f", audioSeconds))s, raw=[\(rawText)], final=[\(finalText)]"
    }

    private static func countText(_ counts: [SleepEventType: Int]) -> String {
        guard !counts.isEmpty else { return "none" }
        return counts
            .sorted { lhs, rhs in lhs.key.rawValue < rhs.key.rawValue }
            .map { "\($0.key.rawValue):\($0.value)" }
            .joined(separator: ";")
    }
}

public extension SleepAnalyzer {
    func makeReplayDetectionSummary(
        label: String,
        chunks: [AudioChunk],
        thresholdsSnapshot: [String: Double]
    ) -> ReplayDetectionSummary {
        var metrics = AudioCaptureMetrics()
        var features: [AudioFeatures] = []
        var rawOutputs: [DetectorOutput] = []
        var rejectedCountByReason: [RejectReason: Int] = [:]
        if let firstChunk = chunks.first {
            metrics.start(at: firstChunk.startedAt)
        }

        for chunk in chunks {
            metrics.recordReceived(chunk: chunk, at: chunk.startedAt)
            let detection = detectOutputsWithFeatures(from: chunk, updating: &metrics)
            features.append(detection.features)
            rawOutputs.append(contentsOf: detection.outputs)

            if detection.outputs.isEmpty {
                for reason in RejectReason.inferredForFeatureWithoutOutput(
                    detection.features,
                    thresholdsSnapshot: thresholdsSnapshot
                ) {
                    rejectedCountByReason[reason, default: 0] += 1
                }
            }
        }

        let sequenceResult = detectSuspectedBreathingPauseSequence(
            features: features,
            contextOutputs: rawOutputs
        )
        rawOutputs.append(contentsOf: sequenceResult.outputs)

        let smoothingResult = smoothWithDiagnostics(outputs: rawOutputs)
        for (reason, count) in smoothingResult.diagnostics.rejectedCountByReason {
            rejectedCountByReason[reason, default: 0] += count
        }

        let rawCandidateCountByType = rawOutputs.reduce(into: [SleepEventType: Int]()) { result, output in
            result[output.eventType, default: 0] += 1
        }
        let finalEventCountByType = smoothingResult.outputs.reduce(into: [SleepEventType: Int]()) { result, output in
            result[output.eventType, default: 0] += 1
        }

        return ReplayDetectionSummary(
            label: label,
            chunkCount: chunks.count,
            audioSeconds: chunks.reduce(0) { $0 + max(0, $1.duration) },
            rawCandidateCount: rawOutputs.count,
            finalEventCount: smoothingResult.outputs.count,
            rawCandidateCountByType: rawCandidateCountByType,
            finalEventCountByType: finalEventCountByType,
            rejectedCountByReason: rejectedCountByReason,
            rmsSummary: SummaryStats.make(values: features.map(\.rms), totalCount: features.count),
            energySummary: SummaryStats.make(values: features.map(\.energy), totalCount: features.count)
        )
    }
}
