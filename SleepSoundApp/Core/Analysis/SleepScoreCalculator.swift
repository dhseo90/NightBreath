import Foundation

public struct SleepScoreResult: Equatable {
    public var score: Int
    public var mainDisturbanceReason: String

    public init(score: Int, mainDisturbanceReason: String) {
        self.score = min(max(score, 0), 100)
        self.mainDisturbanceReason = mainDisturbanceReason
    }
}

public struct SleepScoreCalculator {
    public init() {}

    public func makeReport(
        session: SleepSession,
        events: [SleepEvent],
        aggregator: SleepEventAggregator = SleepEventAggregator(),
        captureMetrics: AudioCaptureMetrics? = nil
    ) -> NightReport {
        let summary = aggregator.summarize(session: session, events: events)
        let result = calculateScore(summary: summary)
        let metrics = captureMetrics?.snapshot(at: session.endedAt ?? Date())
            ?? AudioCaptureMetrics.fallback(sessionElapsedSeconds: summary.measurementDuration)
        let savedAudioDuration = events.reduce(0) { partialResult, event in
            partialResult + max(0, event.audioSnippetDuration ?? 0)
        }
        let reason = reportReason(
            defaultReason: result.mainDisturbanceReason,
            summary: summary,
            metrics: metrics
        )

        return NightReport(
            sessionId: session.id,
            measurementDuration: summary.measurementDuration,
            estimatedSleepDuration: summary.estimatedSleepDuration,
            detectedEventDuration: summary.detectedEventDuration,
            savedAudioDuration: savedAudioDuration,
            receivedAudioDuration: metrics.receivedAudioSeconds,
            analyzedAudioDuration: metrics.analyzedAudioSeconds,
            audioCoverageRatio: metrics.audioCoverageRatio,
            interruptionCount: metrics.interruptionCount,
            longestAudioGapSeconds: metrics.longestChunkGapSeconds,
            measurementQuality: metrics.measurementQuality,
            sleepSoundScore: result.score,
            snoreTotalSeconds: summary.snoreTotalSeconds,
            snoreRatio: summary.snoreRatio,
            bruxismLikeCount: summary.bruxismLikeCount,
            suspectedPauseCount: summary.suspectedPauseCount,
            gaspLikeCount: summary.gaspLikeCount,
            coughLikeCount: summary.coughLikeCount,
            sleepTalkLikeCount: summary.sleepTalkLikeCount,
            environmentalNoiseCount: summary.environmentalNoiseCount,
            awakeningSuspectedCount: summary.awakeningSuspectedCount,
            longestSuspectedPause: summary.longestSuspectedPause,
            mostDisturbedHourRange: summary.mostDisturbedHourRange,
            mainDisturbanceReason: reason
        )
    }

    public func calculateScore(summary: SleepEventSummary) -> SleepScoreResult {
        let penalties = buildPenalties(summary: summary)
        let score = clamp(100 - penalties.reduce(0) { $0 + $1.points })
        return SleepScoreResult(score: score, mainDisturbanceReason: makeReason(from: penalties))
    }

    private func buildPenalties(summary: SleepEventSummary) -> [ScorePenalty] {
        var penalties: [ScorePenalty] = []

        if summary.measurementDuration < 4 * 60 * 60 {
            penalties.append(ScorePenalty(points: 14, category: .shortMeasurement, reason: "측정 시간이 짧았습니다."))
        } else if summary.measurementDuration < 6 * 60 * 60 {
            penalties.append(ScorePenalty(points: 7, category: .shortMeasurement, reason: "측정 시간이 다소 짧았습니다."))
        }

        let snorePenalty = min(22, Int((summary.snoreRatio * 45).rounded(.up)))
        if snorePenalty > 0 {
            let reason = summary.snoreRatio >= 0.18 ? "코골기 시간이 길었습니다." : "코골기가 일부 감지되었습니다."
            penalties.append(ScorePenalty(points: snorePenalty, category: .snore, reason: reason))
        }

        addCountPenalty(
            count: summary.bruxismLikeCount,
            unitPenalty: 1,
            cap: 10,
            category: .bruxismLike,
            reason: "이갈이 의심 소리가 반복적으로 감지되었습니다.",
            to: &penalties
        )
        addCountPenalty(
            count: summary.suspectedPauseCount,
            unitPenalty: 2,
            cap: 22,
            category: .suspectedPause,
            reason: "호흡정지 의심 구간이 반복적으로 감지되었습니다.",
            to: &penalties
        )
        addCountPenalty(
            count: summary.gaspLikeCount,
            unitPenalty: 3,
            cap: 15,
            category: .gaspLike,
            reason: "gasp-like 회복 호흡이 감지되었습니다.",
            to: &penalties
        )

        let coughPenalty = min(8, (summary.coughLikeCount + 5) / 6)
        if coughPenalty > 0 {
            penalties.append(ScorePenalty(points: coughPenalty, category: .coughLike, reason: "기침 의심 소리가 여러 번 감지되었습니다."))
        }

        let noisePenalty = min(12, (summary.environmentalNoiseCount + 2) / 3)
        if noisePenalty > 0 {
            penalties.append(ScorePenalty(points: noisePenalty, category: .environmentalNoise, reason: "큰 환경 소음이 여러 차례 감지되었습니다."))
        }

        let awakeningPenalty = min(14, summary.awakeningSuspectedCount * 2)
        if awakeningPenalty > 0 {
            penalties.append(ScorePenalty(points: awakeningPenalty, category: .awakeningSuspected, reason: "각성 의심 구간이 여러 차례 감지되었습니다."))
        }

        let movementPenalty = min(8, (summary.movementLikeCount + 1) / 2)
        if movementPenalty > 0 {
            penalties.append(ScorePenalty(points: movementPenalty, category: .movementLike, reason: "움직임 의심 소리가 함께 감지되었습니다."))
        }

        let sleepTalkPenalty = min(4, summary.sleepTalkLikeCount / 2)
        if sleepTalkPenalty > 0 {
            penalties.append(ScorePenalty(points: sleepTalkPenalty, category: .sleepTalkLike, reason: "잠꼬대/말소리 의심 이벤트가 일부 감지되었습니다."))
        }

        return penalties.sorted { $0.points > $1.points }
    }

    private func addCountPenalty(
        count: Int,
        unitPenalty: Int,
        cap: Int,
        category: PenaltyCategory,
        reason: String,
        to penalties: inout [ScorePenalty]
    ) {
        let points = min(cap, count * unitPenalty)
        if points > 0 {
            penalties.append(ScorePenalty(points: points, category: category, reason: reason))
        }
    }

    private func makeReason(from penalties: [ScorePenalty]) -> String {
        guard !penalties.isEmpty else {
            return "어젯밤은 비교적 조용하고 안정적인 수면 소리 패턴을 보였습니다."
        }

        let categories = Set(penalties.map(\.category))

        if categories.contains(.suspectedPause), categories.contains(.gaspLike) {
            return "어젯밤은 호흡정지 의심 구간과 gasp-like 회복 호흡이 반복적으로 감지되었습니다."
        }

        if categories.contains(.environmentalNoise), categories.contains(.awakeningSuspected) {
            return "어젯밤은 큰 환경 소음과 각성 의심 구간이 여러 차례 감지되었습니다."
        }

        if let topPenalty = penalties.first {
            switch topPenalty.category {
            case .snore:
                return "어젯밤 수면 소리 점수가 낮아진 주된 이유는 코골기 시간이 길었기 때문입니다."
            case .bruxismLike:
                return "어젯밤은 이갈이 의심 소리가 반복적으로 감지되었습니다."
            case .shortMeasurement:
                return "어젯밤은 측정 시간이 짧아 수면 소리 점수에 제한이 있었습니다."
            default:
                return topPenalty.reason
            }
        }

        return "어젯밤은 감지된 소리 이벤트가 수면 소리 점수에 영향을 주었습니다."
    }

    private func reportReason(
        defaultReason: String,
        summary: SleepEventSummary,
        metrics: AudioCaptureMetrics
    ) -> String {
        guard summary.detectedEventDuration == 0 else {
            return defaultReason
        }

        if metrics.measurementQuality == .poor {
            return "오디오 커버리지가 낮아 오늘 리포트의 참고 범위가 제한적입니다. 수신 시간과 입력 공백을 함께 확인해 주세요."
        }

        if metrics.measurementQuality == .limited || metrics.interruptionCount > 0 {
            return "오디오 수신이 제한적이거나 중단 기록이 있어, 최종 이벤트가 없더라도 측정 환경과 커버리지를 함께 확인해 주세요."
        }

        return defaultReason
    }

    private func clamp(_ score: Int) -> Int {
        min(max(score, 0), 100)
    }
}

private struct ScorePenalty {
    var points: Int
    var category: PenaltyCategory
    var reason: String
}

private enum PenaltyCategory: Hashable {
    case shortMeasurement
    case snore
    case bruxismLike
    case suspectedPause
    case gaspLike
    case coughLike
    case environmentalNoise
    case awakeningSuspected
    case movementLike
    case sleepTalkLike
}
