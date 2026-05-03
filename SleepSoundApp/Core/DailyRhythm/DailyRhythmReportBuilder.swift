import Foundation

public struct DailyRhythmReportBuilder: Sendable {
    public var scoreCalculator: DailyRhythmScoreCalculator
    public var insightGenerator: DailyInsightGenerator

    public init(calendar: Calendar = .current) {
        self.scoreCalculator = DailyRhythmScoreCalculator(calendar: calendar)
        self.insightGenerator = DailyInsightGenerator(calendar: calendar)
    }

    public init(
        scoreCalculator: DailyRhythmScoreCalculator,
        insightGenerator: DailyInsightGenerator
    ) {
        self.scoreCalculator = scoreCalculator
        self.insightGenerator = insightGenerator
    }

    public func build(
        id: UUID = UUID(),
        snapshot: DailyHealthSnapshot,
        nightReport: NightReport? = nil,
        morningCheckIn: MorningCheckIn? = nil,
        eveningCheckIn: EveningCheckIn? = nil,
        healthMetricSamples: [HealthMetricSample] = [],
        createdAt: Date = Date()
    ) -> DailyRhythmReport {
        let calculation = scoreCalculator.calculate(
            snapshot: snapshot,
            nightReport: nightReport,
            morningCheckIn: morningCheckIn,
            eveningCheckIn: eveningCheckIn,
            healthMetricSamples: healthMetricSamples,
            computedAt: createdAt
        )
        let insights = insightGenerator.generate(
            snapshot: snapshot,
            scoreCalculation: calculation,
            nightReport: nightReport,
            morningCheckIn: morningCheckIn,
            eveningCheckIn: eveningCheckIn,
            healthMetricSamples: healthMetricSamples,
            createdAt: createdAt
        )

        return DailyRhythmReport(
            id: id,
            date: snapshot.date,
            dailyRhythmScore: calculation.score,
            dataQuality: calculation.dataQuality,
            insights: insights
        )
    }
}
