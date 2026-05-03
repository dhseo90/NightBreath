import Foundation

public struct DailyHealthSnapshotBuilder: Sendable {
    public var calendar: Calendar

    public init(calendar: Calendar = .current) {
        self.calendar = calendar
    }

    public func build(
        id: UUID = UUID(),
        date: Date,
        sleepReport: NightReport? = nil,
        morningCheckIn: MorningCheckIn? = nil,
        eveningCheckIn: EveningCheckIn? = nil,
        healthMetricSamples: [HealthMetricSample] = [],
        lifestyleTags: [LifestyleTag] = [],
        createdAt: Date = Date(),
        updatedAt: Date? = nil
    ) -> DailyHealthSnapshot {
        let dayStart = calendar.startOfDay(for: date)
        let daySamples = samplesForDay(healthMetricSamples, date: date)
        let mergedTags = lifestyleTags + (eveningCheckIn?.lifestyleTags ?? [])

        return DailyHealthSnapshot(
            id: id,
            date: dayStart,
            sleepReportId: sleepReport?.id,
            morningCheckInId: morningCheckIn?.id,
            eveningCheckInId: eveningCheckIn?.id,
            healthMetricSampleIds: daySamples.map(\.id),
            lifestyleTags: mergedTags,
            dataCompletenessScore: dataCompletenessScore(
                sleepReport: sleepReport,
                morningCheckIn: morningCheckIn,
                eveningCheckIn: eveningCheckIn,
                healthMetricSamples: daySamples
            ),
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }

    private func samplesForDay(
        _ samples: [HealthMetricSample],
        date: Date
    ) -> [HealthMetricSample] {
        samples
            .filter { calendar.isDate($0.measuredAt, inSameDayAs: date) }
            .sortedByMeasuredAtAscending()
    }

    private func dataCompletenessScore(
        sleepReport: NightReport?,
        morningCheckIn: MorningCheckIn?,
        eveningCheckIn: EveningCheckIn?,
        healthMetricSamples: [HealthMetricSample]
    ) -> Double {
        let completedComponents = [
            sleepReport != nil,
            morningCheckIn != nil,
            eveningCheckIn != nil,
            hasSample(in: healthMetricSamples, matching: Self.bloodPressureMetrics),
            hasSample(in: healthMetricSamples, matching: Self.bodyMetricMetrics),
            hasSample(in: healthMetricSamples, matching: Self.activityAndRecoveryMetrics),
        ].filter { $0 }.count

        return DailyDataQuality.clampedCompleteness(Double(completedComponents) / 6)
    }

    private func hasSample(
        in samples: [HealthMetricSample],
        matching metricTypes: Set<HealthMetricType>
    ) -> Bool {
        samples.contains { metricTypes.contains($0.metricType) }
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

    private static let activityAndRecoveryMetrics: Set<HealthMetricType> = [
        .stepCount,
        .activeEnergy,
        .heartRate,
        .restingHeartRate,
        .sleepDuration,
        .respiratoryRate,
    ]
}
