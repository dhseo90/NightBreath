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
        aggregator: SleepEventAggregator = SleepEventAggregator()
    ) -> NightReport {
        let summary = aggregator.summarize(session: session, events: events)
        let result = calculateScore(summary: summary)

        return NightReport(
            sessionId: session.id,
            measurementDuration: summary.measurementDuration,
            estimatedSleepDuration: summary.estimatedSleepDuration,
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
            mainDisturbanceReason: result.mainDisturbanceReason
        )
    }

    public func calculateScore(summary: SleepEventSummary) -> SleepScoreResult {
        let penalties = buildPenalties(summary: summary)
        let score = min(max(100 - penalties.reduce(0) { $0 + $1.points }, 0), 100)
        return SleepScoreResult(score: score, mainDisturbanceReason: makeReason(from: penalties))
    }

    private func buildPenalties(summary: SleepEventSummary) -> [ScorePenalty] {
        var penalties: [ScorePenalty] = []

        if summary.measurementDuration < 4 * 60 * 60 {
            penalties.append(ScorePenalty(points: 12, reason: "측정 시간이 짧았고"))
        } else if summary.measurementDuration < 6 * 60 * 60 {
            penalties.append(ScorePenalty(points: 6, reason: "측정 시간이 다소 짧았고"))
        }

        let snorePenalty = min(18, Int((summary.snoreRatio * 40).rounded(.up)))
        if snorePenalty > 0 {
            let reason = summary.snoreRatio >= 0.12 ? "코골기 시간이 길었고" : "코골기가 일부 감지되었고"
            penalties.append(ScorePenalty(points: snorePenalty, reason: reason))
        }

        addCountPenalty(
            count: summary.bruxismLikeCount,
            unitPenalty: 1,
            cap: 10,
            reason: "이갈이 의심 소리가 반복되었고",
            to: &penalties
        )
        addCountPenalty(
            count: summary.suspectedPauseCount,
            unitPenalty: 1,
            cap: 18,
            reason: "호흡정지 의심 구간이 반복되었고",
            to: &penalties
        )
        addCountPenalty(
            count: summary.gaspLikeCount,
            unitPenalty: 1,
            cap: 10,
            reason: "gasp-like 회복 호흡이 감지되었고",
            to: &penalties
        )

        let coughPenalty = min(8, (summary.coughLikeCount + 5) / 6)
        if coughPenalty > 0 {
            penalties.append(ScorePenalty(points: coughPenalty, reason: "기침 의심 소리가 여러 번 감지되었고"))
        }

        let noisePenalty = min(6, (summary.environmentalNoiseCount + 7) / 8)
        if noisePenalty > 0 {
            penalties.append(ScorePenalty(points: noisePenalty, reason: "환경 소음이 수면 흐름을 방해했을 수 있고"))
        }

        let awakeningPenalty = min(12, (summary.awakeningSuspectedCount + 1) / 2)
        if awakeningPenalty > 0 {
            penalties.append(ScorePenalty(points: awakeningPenalty, reason: "각성 의심 구간이 나타났기 때문입니다"))
        }

        let movementPenalty = min(8, (summary.movementLikeCount + 1) / 2)
        if movementPenalty > 0 {
            penalties.append(ScorePenalty(points: movementPenalty, reason: "움직임 의심 소리가 함께 감지되었기 때문입니다"))
        }

        let sleepTalkPenalty = min(4, summary.sleepTalkLikeCount / 2)
        if sleepTalkPenalty > 0 {
            penalties.append(ScorePenalty(points: sleepTalkPenalty, reason: "잠꼬대/말소리 의심 이벤트가 일부 있었기 때문입니다"))
        }

        return penalties.sorted { $0.points > $1.points }
    }

    private func addCountPenalty(
        count: Int,
        unitPenalty: Int,
        cap: Int,
        reason: String,
        to penalties: inout [ScorePenalty]
    ) {
        let points = min(cap, count * unitPenalty)
        if points > 0 {
            penalties.append(ScorePenalty(points: points, reason: reason))
        }
    }

    private func makeReason(from penalties: [ScorePenalty]) -> String {
        guard !penalties.isEmpty else {
            return "감지된 방해 소리가 많지 않아 수면 중 소리 흐름이 비교적 안정적으로 보였습니다."
        }

        let topReasons = penalties.prefix(3).map(\.reason)
        let joined = topReasons.joined(separator: " ")
        return "어젯밤 수면 소리 점수가 낮아진 주된 이유는 \(joined)"
    }
}

private struct ScorePenalty {
    var points: Int
    var reason: String
}
