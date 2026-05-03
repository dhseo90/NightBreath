import Foundation

public struct DailyInsightGenerator: Sendable {
    public var calendar: Calendar

    public init(calendar: Calendar = .current) {
        self.calendar = calendar
    }

    public func generate(
        snapshot: DailyHealthSnapshot,
        scoreCalculation: DailyRhythmScoreCalculation,
        nightReport: NightReport? = nil,
        morningCheckIn: MorningCheckIn? = nil,
        eveningCheckIn: EveningCheckIn? = nil,
        healthMetricSamples: [HealthMetricSample] = [],
        createdAt: Date = Date()
    ) -> [DailyInsight] {
        let daySamples = samplesLinkedToSnapshot(snapshot, samples: healthMetricSamples)
        var insights: [DailyInsight] = []

        if let dataQualityInsight = makeDataQualityInsight(
            dataQuality: scoreCalculation.dataQuality,
            createdAt: createdAt
        ) {
            insights.append(dataQualityInsight)
        }

        insights.append(
            makeSleepInsight(
                report: nightReport,
                createdAt: createdAt
            )
        )

        if let recoveryInsight = makeRecoveryInsight(
            morningCheckIn: morningCheckIn,
            eveningCheckIn: eveningCheckIn,
            createdAt: createdAt
        ) {
            insights.append(recoveryInsight)
        }

        if let healthInsight = makeHealthInsight(
            samples: daySamples,
            createdAt: createdAt
        ) {
            insights.append(healthInsight)
        }

        if let activityInsight = makeActivityInsight(
            samples: daySamples,
            createdAt: createdAt
        ) {
            insights.append(activityInsight)
        }

        if let lifestyleInsight = makeLifestyleInsight(
            tags: snapshot.lifestyleTags,
            createdAt: createdAt
        ) {
            insights.append(lifestyleInsight)
        }

        return insights
    }

    private func makeDataQualityInsight(
        dataQuality: DailyDataQuality,
        createdAt: Date
    ) -> DailyInsight? {
        switch dataQuality {
        case .excellent, .good:
            return DailyInsight(
                type: .dataQuality,
                severity: .neutral,
                title: "데이터 품질",
                message: "수면 소리 지표와 건강 데이터를 함께 살펴볼 수 있습니다.",
                createdAt: createdAt
            )
        case .limited, .poor, .insufficient:
            return DailyInsight(
                type: .dataQuality,
                severity: .caution,
                title: "데이터 품질",
                message: "비교 가능한 데이터가 부족해 일부 리포트가 제한됩니다.",
                createdAt: createdAt
            )
        }
    }

    private func makeSleepInsight(
        report: NightReport?,
        createdAt: Date
    ) -> DailyInsight {
        guard let report else {
            return DailyInsight(
                type: .sleep,
                severity: .caution,
                title: "수면 소리 기록",
                message: "수면 소리 리포트가 아직 없어 수면 항목은 제한적으로 표시됩니다.",
                createdAt: createdAt
            )
        }

        if report.audioCoverageRatio < 0.85 {
            return DailyInsight(
                type: .sleep,
                severity: .caution,
                title: "수면 소리 기록",
                message: "수면 소리 측정 범위가 짧아 수면 항목은 참고 범위가 제한됩니다.",
                createdAt: createdAt
            )
        }

        if report.snoreTotalSeconds >= 15 * 60 {
            return DailyInsight(
                type: .sleep,
                severity: .neutral,
                title: "코골기 기록",
                message: "어젯밤 코골기 시간이 비교적 길게 기록되었습니다.",
                createdAt: createdAt
            )
        }

        return DailyInsight(
            type: .sleep,
            severity: .neutral,
            title: "수면 소리 기록",
            message: "어젯밤 수면 소리 지표가 오늘의 리듬 점수에 함께 반영되었습니다.",
            createdAt: createdAt
        )
    }

    private func makeRecoveryInsight(
        morningCheckIn: MorningCheckIn?,
        eveningCheckIn: EveningCheckIn?,
        createdAt: Date
    ) -> DailyInsight? {
        if let morningCheckIn {
            return DailyInsight(
                type: .recovery,
                severity: .neutral,
                title: "아침 컨디션",
                message: "아침 컨디션은 \(conditionDescription(refreshScore: morningCheckIn.refreshScore, fatigueScore: morningCheckIn.fatigueScore))으로 기록되었습니다.",
                createdAt: createdAt
            )
        }

        if eveningCheckIn != nil {
            return DailyInsight(
                type: .recovery,
                severity: .neutral,
                title: "저녁 체크인",
                message: "저녁 컨디션 기록을 회복 리듬 항목에 참고용으로 표시합니다.",
                createdAt: createdAt
            )
        }

        return nil
    }

    private func makeHealthInsight(
        samples: [HealthMetricSample],
        createdAt: Date
    ) -> DailyInsight? {
        let bloodPressureSamples = metricSamples(for: Self.bloodPressureMetrics, in: samples)
        let bodyMetricSamples = metricSamples(for: Self.bodyMetricMetrics, in: samples)

        if !bloodPressureSamples.isEmpty && !bodyMetricSamples.isEmpty {
            return DailyInsight(
                type: .bloodPressure,
                severity: .neutral,
                title: "건강 데이터 기록",
                message: "오늘 혈압과 체중 데이터가 함께 기록되었습니다.",
                relatedHealthMetricSampleIds: (bloodPressureSamples + bodyMetricSamples).map(\.id),
                createdAt: createdAt
            )
        }

        if !bloodPressureSamples.isEmpty {
            return DailyInsight(
                type: .bloodPressure,
                severity: .neutral,
                title: "혈압 데이터",
                message: "오늘 혈압 데이터가 기록되었습니다.",
                relatedHealthMetricSampleIds: bloodPressureSamples.map(\.id),
                createdAt: createdAt
            )
        }

        if !bodyMetricSamples.isEmpty {
            return DailyInsight(
                type: .bodyComposition,
                severity: .neutral,
                title: "체성분 데이터",
                message: "오늘 체중/체성분 데이터가 기록되었습니다.",
                relatedHealthMetricSampleIds: bodyMetricSamples.map(\.id),
                createdAt: createdAt
            )
        }

        return DailyInsight(
            type: .dataQuality,
            severity: .caution,
            title: "건강 데이터",
            message: "혈압과 체성분 데이터가 없어 해당 항목은 제한적으로 표시됩니다.",
            createdAt: createdAt
        )
    }

    private func makeActivityInsight(
        samples: [HealthMetricSample],
        createdAt: Date
    ) -> DailyInsight? {
        let activitySamples = metricSamples(for: Self.activityMetrics, in: samples)
        guard !activitySamples.isEmpty else { return nil }

        return DailyInsight(
            type: .activity,
            severity: .neutral,
            title: "활동 데이터",
            message: "오늘 활동 데이터가 기록되어 하루 리듬 카드에서 함께 볼 수 있습니다.",
            relatedHealthMetricSampleIds: activitySamples.map(\.id),
            createdAt: createdAt
        )
    }

    private func makeLifestyleInsight(
        tags: [LifestyleTag],
        createdAt: Date
    ) -> DailyInsight? {
        guard !tags.isEmpty else { return nil }

        let tagNames = tags.prefix(3).map(\.displayName).joined(separator: ", ")
        return DailyInsight(
            type: .lifestyle,
            severity: .neutral,
            title: "생활 태그",
            message: "\(tagNames) 기록을 하루 리듬 카드에 참고용으로 표시합니다.",
            relatedLifestyleTags: Array(tags.prefix(3)),
            createdAt: createdAt
        )
    }

    private func conditionDescription(refreshScore: Int, fatigueScore: Int) -> String {
        let combined = (min(max(refreshScore, 1), 5) + (6 - min(max(fatigueScore, 1), 5))) / 2

        switch combined {
        case 4...5:
            return "좋은 편"
        case 3:
            return "보통"
        default:
            return "낮은 편"
        }
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

    private func metricSamples(
        for metricTypes: Set<HealthMetricType>,
        in samples: [HealthMetricSample]
    ) -> [HealthMetricSample] {
        samples.filter { metricTypes.contains($0.metricType) }
    }

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

    private static let activityMetrics: Set<HealthMetricType> = [
        .stepCount,
        .activeEnergy,
    ]
}
