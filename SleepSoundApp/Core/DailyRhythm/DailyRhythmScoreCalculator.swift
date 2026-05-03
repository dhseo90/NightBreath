import Foundation

public struct DailyRhythmScoreCalculation: Equatable, Sendable {
    public var score: DailyRhythmScore
    public var dataQuality: DailyDataQuality

    public init(score: DailyRhythmScore, dataQuality: DailyDataQuality) {
        self.score = score
        self.dataQuality = dataQuality
    }
}

public struct DailyRhythmScoreCalculator: Sendable {
    public var calendar: Calendar

    public init(calendar: Calendar = .current) {
        self.calendar = calendar
    }

    public func calculate(
        snapshot: DailyHealthSnapshot,
        nightReport: NightReport? = nil,
        morningCheckIn: MorningCheckIn? = nil,
        eveningCheckIn: EveningCheckIn? = nil,
        healthMetricSamples: [HealthMetricSample] = [],
        computedAt: Date = Date()
    ) -> DailyRhythmScoreCalculation {
        let daySamples = samplesLinkedToSnapshot(snapshot, samples: healthMetricSamples)
        let sleep = sleepComponentScore(from: nightReport)
        let recovery = recoveryComponentScore(
            morningCheckIn: morningCheckIn,
            eveningCheckIn: eveningCheckIn
        )
        let activity = activityComponentScore(from: daySamples)
        let bloodPressure = presenceComponentScore(
            from: daySamples,
            metricTypes: Self.bloodPressureMetrics,
            fullScore: 84,
            partialScore: 68
        )
        let bodyMetric = presenceComponentScore(
            from: daySamples,
            metricTypes: Self.bodyMetricMetrics,
            fullScore: 84,
            partialScore: 64
        )

        let totalScore = weightedTotalScore(
            components: [
                Component(score: sleep.score, weight: 0.30, isAvailable: sleep.isAvailable),
                Component(score: recovery.score, weight: 0.25, isAvailable: recovery.isAvailable),
                Component(score: activity.score, weight: 0.15, isAvailable: activity.isAvailable),
                Component(score: bloodPressure.score, weight: 0.15, isAvailable: bloodPressure.isAvailable),
                Component(score: bodyMetric.score, weight: 0.15, isAvailable: bodyMetric.isAvailable),
            ]
        )
        let dataQuality = DailyDataQuality.quality(for: snapshot.dataCompletenessScore)

        return DailyRhythmScoreCalculation(
            score: DailyRhythmScore(
                totalScore: totalScore,
                sleepComponent: sleep.score,
                recoveryComponent: recovery.score,
                activityComponent: activity.score,
                bloodPressureComponent: bloodPressure.score,
                bodyMetricComponent: bodyMetric.score,
                dataCompleteness: snapshot.dataCompletenessScore,
                computedAt: computedAt
            ),
            dataQuality: dataQuality
        )
    }

    private func samplesLinkedToSnapshot(
        _ snapshot: DailyHealthSnapshot,
        samples: [HealthMetricSample]
    ) -> [HealthMetricSample] {
        let ids = Set(snapshot.healthMetricSampleIds)
        guard !ids.isEmpty else { return [] }

        return samples
            .filter { ids.contains($0.id) }
            .sortedByMeasuredAtAscending()
    }

    private func sleepComponentScore(from report: NightReport?) -> ComponentScore {
        guard let report else {
            return ComponentScore(score: Self.missingComponentScore, isAvailable: false)
        }

        let rawScore = Double(DailyRhythmScore.clampedScore(report.sleepSoundScore))
        let coverage = DailyDataQuality.clampedCompleteness(report.audioCoverageRatio)
        let coverageBlendedScore = Self.neutralScore + ((rawScore - Self.neutralScore) * coverage)

        return ComponentScore(
            score: DailyRhythmScore.clampedScore(Int(coverageBlendedScore.rounded())),
            isAvailable: true
        )
    }

    private func recoveryComponentScore(
        morningCheckIn: MorningCheckIn?,
        eveningCheckIn: EveningCheckIn?
    ) -> ComponentScore {
        var scores: [Int] = []

        if let morningCheckIn {
            scores.append(scoreFromFivePointScale(morningCheckIn.refreshScore))
            scores.append(scoreFromFivePointScale(morningCheckIn.fatigueScore, inverted: true))
        }

        if let eveningCheckIn {
            scores.append(scoreFromFivePointScale(eveningCheckIn.fatigueScore, inverted: true))
            scores.append(scoreFromFivePointScale(eveningCheckIn.stressScore, inverted: true))
            if let moodScore = eveningCheckIn.moodScore {
                scores.append(scoreFromFivePointScale(moodScore))
            }
        }

        return averageComponentScore(scores)
    }

    private func activityComponentScore(from samples: [HealthMetricSample]) -> ComponentScore {
        var scores: [Int] = []

        if let stepCount = latestValue(for: .stepCount, in: samples) {
            scores.append(scaledScore(value: stepCount, target: 8_000, floor: 35))
        }

        if let activeEnergy = latestValue(for: .activeEnergy, in: samples) {
            scores.append(scaledScore(value: activeEnergy, target: 400, floor: 35))
        }

        return averageComponentScore(scores)
    }

    private func presenceComponentScore(
        from samples: [HealthMetricSample],
        metricTypes: Set<HealthMetricType>,
        fullScore: Int,
        partialScore: Int
    ) -> ComponentScore {
        let representedTypes = Set(samples.map(\.metricType)).intersection(metricTypes)
        guard !representedTypes.isEmpty else {
            return ComponentScore(score: Self.missingComponentScore, isAvailable: false)
        }

        if representedTypes.count == metricTypes.count {
            return ComponentScore(score: fullScore, isAvailable: true)
        }

        let ratio = Double(representedTypes.count) / Double(metricTypes.count)
        let score = Double(partialScore) + (Double(fullScore - partialScore) * ratio)
        return ComponentScore(
            score: DailyRhythmScore.clampedScore(Int(score.rounded())),
            isAvailable: true
        )
    }

    private func weightedTotalScore(components: [Component]) -> Int {
        let availableComponents = components.filter(\.isAvailable)
        guard !availableComponents.isEmpty else {
            return Self.missingComponentScore
        }

        let weightSum = availableComponents.map(\.weight).reduce(0, +)
        guard weightSum > 0 else {
            return Self.missingComponentScore
        }

        let weightedSum = availableComponents.reduce(0) { result, component in
            result + (Double(component.score) * component.weight)
        }

        return DailyRhythmScore.clampedScore(Int((weightedSum / weightSum).rounded()))
    }

    private func averageComponentScore(_ scores: [Int]) -> ComponentScore {
        guard !scores.isEmpty else {
            return ComponentScore(score: Self.missingComponentScore, isAvailable: false)
        }

        let average = scores.reduce(0, +) / scores.count
        return ComponentScore(score: DailyRhythmScore.clampedScore(average), isAvailable: true)
    }

    private func scoreFromFivePointScale(_ value: Int, inverted: Bool = false) -> Int {
        let clampedValue = min(max(value, 1), 5)
        let effectiveValue = inverted ? 6 - clampedValue : clampedValue
        return DailyRhythmScore.clampedScore(effectiveValue * 20)
    }

    private func scaledScore(value: Double, target: Double, floor: Int) -> Int {
        guard value.isFinite, target > 0 else {
            return floor
        }

        let ratio = min(max(value / target, 0), 1)
        let score = Double(floor) + ((100 - Double(floor)) * ratio)
        return DailyRhythmScore.clampedScore(Int(score.rounded()))
    }

    private func latestValue(
        for metricType: HealthMetricType,
        in samples: [HealthMetricSample]
    ) -> Double? {
        samples.latestSample(metricType: metricType)?.value
    }

    private struct ComponentScore: Equatable {
        var score: Int
        var isAvailable: Bool
    }

    private struct Component: Equatable {
        var score: Int
        var weight: Double
        var isAvailable: Bool
    }

    private static let neutralScore = 50.0
    private static let missingComponentScore = 50

    private static let bloodPressureMetrics: Set<HealthMetricType> = [
        .systolicBloodPressure,
        .diastolicBloodPressure,
    ]

    private static let bodyMetricMetrics: Set<HealthMetricType> = [
        .bodyMass,
        .bodyFatPercentage,
        .bodyMassIndex,
        .leanBodyMass,
    ]
}
