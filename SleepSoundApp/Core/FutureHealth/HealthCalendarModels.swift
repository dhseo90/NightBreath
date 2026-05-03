import Foundation

public struct CalendarDaySummary: Identifiable, Equatable, Sendable {
    public var id: Date { date }
    public var date: Date
    public var hasSleepReport: Bool
    public var hasBloodPressure: Bool
    public var hasBodyComposition: Bool
    public var hasActivity: Bool
    public var hasMorningCheckIn: Bool
    public var hasEveningCheckIn: Bool
    public var sampleCount: Int
    public var sourceTypes: [HealthMetricSourceType]
    public var dataQuality: DailyDataQuality

    public var hasAnyData: Bool {
        hasSleepReport
            || hasBloodPressure
            || hasBodyComposition
            || hasActivity
            || hasMorningCheckIn
            || hasEveningCheckIn
            || sampleCount > 0
    }

    public init(
        date: Date,
        hasSleepReport: Bool = false,
        hasBloodPressure: Bool = false,
        hasBodyComposition: Bool = false,
        hasActivity: Bool = false,
        hasMorningCheckIn: Bool = false,
        hasEveningCheckIn: Bool = false,
        sampleCount: Int = 0,
        sourceTypes: [HealthMetricSourceType] = [],
        dataQuality: DailyDataQuality = .insufficient
    ) {
        self.date = date
        self.hasSleepReport = hasSleepReport
        self.hasBloodPressure = hasBloodPressure
        self.hasBodyComposition = hasBodyComposition
        self.hasActivity = hasActivity
        self.hasMorningCheckIn = hasMorningCheckIn
        self.hasEveningCheckIn = hasEveningCheckIn
        self.sampleCount = max(0, sampleCount)
        self.sourceTypes = sourceTypes
        self.dataQuality = dataQuality
    }
}

public struct DailyMeasurementDetailData: Equatable {
    public var date: Date
    public var summary: CalendarDaySummary
    public var sleepReports: [NightReport]
    public var morningCheckIns: [MorningCheckIn]
    public var eveningCheckIns: [EveningCheckIn]
    public var samples: [UnifiedHealthMetricSample]

    public init(
        date: Date,
        summary: CalendarDaySummary,
        sleepReports: [NightReport],
        morningCheckIns: [MorningCheckIn],
        eveningCheckIns: [EveningCheckIn],
        samples: [UnifiedHealthMetricSample]
    ) {
        self.date = date
        self.summary = summary
        self.sleepReports = sleepReports.sorted { $0.generatedAt < $1.generatedAt }
        self.morningCheckIns = morningCheckIns.sorted { $0.createdAt < $1.createdAt }
        self.eveningCheckIns = eveningCheckIns.sorted { $0.date < $1.date }
        self.samples = samples.sortedByMeasuredAtAscending()
    }

    public func samples(for metricIDs: [UnifiedHealthMetricID]) -> [UnifiedHealthMetricSample] {
        let metricSet = Set(metricIDs)
        return samples
            .filter { metricSet.contains($0.metricID) }
            .sortedByMeasuredAtAscending()
    }

    public var bloodPressureSamples: [UnifiedHealthMetricSample] {
        samples(for: HealthCalendarDataGrouping.bloodPressureMetricIDs)
    }

    public var bodyCompositionSamples: [UnifiedHealthMetricSample] {
        samples(for: HealthCalendarDataGrouping.standardBodyCompositionMetricIDs)
    }

    public var fitdaysExtendedSamples: [UnifiedHealthMetricSample] {
        samples(for: HealthCalendarDataGrouping.fitdaysExtendedMetricIDs)
    }

    public var activitySamples: [UnifiedHealthMetricSample] {
        samples(for: HealthCalendarDataGrouping.activityMetricIDs)
    }

    public var appComputedSamples: [UnifiedHealthMetricSample] {
        samples(for: HealthCalendarDataGrouping.appComputedMetricIDs)
    }
}

public enum HealthCalendarDataGrouping {
    public static let bloodPressureMetricIDs: [UnifiedHealthMetricID] = [
        .systolicBloodPressure,
        .diastolicBloodPressure,
    ]

    public static let standardBodyCompositionMetricIDs: [UnifiedHealthMetricID] = [
        .bodyMass,
        .bodyMassIndex,
        .bodyFatPercentage,
        .leanBodyMass,
    ]

    public static let fitdaysExtendedMetricIDs: [UnifiedHealthMetricID] = [
        .bodyWaterPercentage,
        .visceralFatPercentage,
        .visceralFatLevel,
        .skeletalMuscleMass,
        .mineralMass,
        .boneMass,
        .basalMetabolicRate,
        .proteinPercentage,
        .muscleMass,
        .subcutaneousFatPercentage,
        .metabolicAge,
        .bodyScore,
        .obesityLevel,
    ]

    public static let activityMetricIDs: [UnifiedHealthMetricID] = [
        .stepCount,
        .activeEnergy,
        .heartRate,
        .restingHeartRate,
    ]

    public static let appComputedMetricIDs: [UnifiedHealthMetricID] = [
        .sleepSoundScore,
        .dailyRhythmScore,
        .audioCoverageRatio,
    ]
}

public struct HealthCalendarBuilder: Equatable, Sendable {
    public init() {}

    public func monthGrid(
        containing monthDate: Date,
        calendar: Calendar = .current
    ) -> [Date] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: monthDate) else {
            return []
        }

        let firstOfMonth = monthInterval.start
        let weekday = calendar.component(.weekday, from: firstOfMonth)
        let leadingDayCount = (weekday - calendar.firstWeekday + 7) % 7
        let gridStart = calendar.date(byAdding: .day, value: -leadingDayCount, to: firstOfMonth) ?? firstOfMonth

        return (0..<42).compactMap { dayOffset in
            calendar.date(byAdding: .day, value: dayOffset, to: gridStart)
        }
    }

    public func summary(
        for date: Date,
        samples: [UnifiedHealthMetricSample],
        sleepReports: [NightReport],
        morningCheckIns: [MorningCheckIn] = [],
        eveningCheckIns: [EveningCheckIn] = [],
        calendar: Calendar = .current
    ) -> CalendarDaySummary {
        let dayStart = calendar.startOfDay(for: date)
        let daySamples = samplesForDay(samples, date: dayStart, calendar: calendar)
        let dayReports = reportsForDay(sleepReports, date: dayStart, calendar: calendar)
        let reportSessionIDs = Set(dayReports.map(\.sessionId))
        let dayMorningCheckIns = morningCheckInsForDay(
            morningCheckIns,
            reportSessionIDs: reportSessionIDs,
            date: dayStart,
            calendar: calendar
        )
        let dayEveningCheckIns = eveningCheckInsForDay(eveningCheckIns, date: dayStart, calendar: calendar)

        let metricIDs = Set(daySamples.map(\.metricID))
        let hasBloodPressure = metricIDs.intersects(HealthCalendarDataGrouping.bloodPressureMetricIDs)
        let hasStandardBodyComposition = metricIDs.intersects(HealthCalendarDataGrouping.standardBodyCompositionMetricIDs)
        let hasFitdaysExtended = metricIDs.intersects(HealthCalendarDataGrouping.fitdaysExtendedMetricIDs)
        let hasActivity = metricIDs.intersects(HealthCalendarDataGrouping.activityMetricIDs)
        let sourceTypes = sortedSourceTypes(from: daySamples)
        let categoryCount = [
            !dayReports.isEmpty,
            hasBloodPressure,
            hasStandardBodyComposition || hasFitdaysExtended,
            hasActivity,
            !dayMorningCheckIns.isEmpty || !dayEveningCheckIns.isEmpty,
        ].filter { $0 }.count

        return CalendarDaySummary(
            date: dayStart,
            hasSleepReport: !dayReports.isEmpty,
            hasBloodPressure: hasBloodPressure,
            hasBodyComposition: hasStandardBodyComposition || hasFitdaysExtended,
            hasActivity: hasActivity,
            hasMorningCheckIn: !dayMorningCheckIns.isEmpty,
            hasEveningCheckIn: !dayEveningCheckIns.isEmpty,
            sampleCount: daySamples.count,
            sourceTypes: sourceTypes,
            dataQuality: dataQuality(categoryCount: categoryCount, sampleCount: daySamples.count)
        )
    }

    public func summaries(
        forMonthContaining monthDate: Date,
        samples: [UnifiedHealthMetricSample],
        sleepReports: [NightReport],
        morningCheckIns: [MorningCheckIn] = [],
        eveningCheckIns: [EveningCheckIn] = [],
        calendar: Calendar = .current
    ) -> [CalendarDaySummary] {
        monthGrid(containing: monthDate, calendar: calendar).map { date in
            summary(
                for: date,
                samples: samples,
                sleepReports: sleepReports,
                morningCheckIns: morningCheckIns,
                eveningCheckIns: eveningCheckIns,
                calendar: calendar
            )
        }
    }

    public func detailData(
        for date: Date,
        samples: [UnifiedHealthMetricSample],
        sleepReports: [NightReport],
        morningCheckIns: [MorningCheckIn] = [],
        eveningCheckIns: [EveningCheckIn] = [],
        calendar: Calendar = .current
    ) -> DailyMeasurementDetailData {
        let dayStart = calendar.startOfDay(for: date)
        let dayReports = reportsForDay(sleepReports, date: dayStart, calendar: calendar)
        let reportSessionIDs = Set(dayReports.map(\.sessionId))
        let summary = summary(
            for: dayStart,
            samples: samples,
            sleepReports: sleepReports,
            morningCheckIns: morningCheckIns,
            eveningCheckIns: eveningCheckIns,
            calendar: calendar
        )

        return DailyMeasurementDetailData(
            date: dayStart,
            summary: summary,
            sleepReports: dayReports,
            morningCheckIns: morningCheckInsForDay(
                morningCheckIns,
                reportSessionIDs: reportSessionIDs,
                date: dayStart,
                calendar: calendar
            ),
            eveningCheckIns: eveningCheckInsForDay(eveningCheckIns, date: dayStart, calendar: calendar),
            samples: samplesForDay(samples, date: dayStart, calendar: calendar)
        )
    }

    private func samplesForDay(
        _ samples: [UnifiedHealthMetricSample],
        date: Date,
        calendar: Calendar
    ) -> [UnifiedHealthMetricSample] {
        samples
            .filter { calendar.isDate($0.measuredAt, inSameDayAs: date) }
            .sortedByMeasuredAtAscending()
    }

    private func reportsForDay(
        _ reports: [NightReport],
        date: Date,
        calendar: Calendar
    ) -> [NightReport] {
        reports
            .filter { calendar.isDate($0.generatedAt, inSameDayAs: date) }
            .sorted { $0.generatedAt < $1.generatedAt }
    }

    private func morningCheckInsForDay(
        _ checkIns: [MorningCheckIn],
        reportSessionIDs: Set<UUID>,
        date: Date,
        calendar: Calendar
    ) -> [MorningCheckIn] {
        checkIns
            .filter { checkIn in
                reportSessionIDs.contains(checkIn.sessionId)
                    || calendar.isDate(checkIn.createdAt, inSameDayAs: date)
            }
            .sorted { $0.createdAt < $1.createdAt }
    }

    private func eveningCheckInsForDay(
        _ checkIns: [EveningCheckIn],
        date: Date,
        calendar: Calendar
    ) -> [EveningCheckIn] {
        checkIns
            .filter { calendar.isDate($0.date, inSameDayAs: date) }
            .sorted { $0.date < $1.date }
    }

    private func sortedSourceTypes(from samples: [UnifiedHealthMetricSample]) -> [HealthMetricSourceType] {
        let sourceTypes = Set(samples.map(\.sourceType))
        return HealthMetricSourceType.allCases.filter { sourceTypes.contains($0) }
    }

    private func dataQuality(categoryCount: Int, sampleCount: Int) -> DailyDataQuality {
        guard categoryCount > 0 || sampleCount > 0 else {
            return .insufficient
        }
        if categoryCount >= 5 && sampleCount >= 8 {
            return .excellent
        }
        if categoryCount >= 3 {
            return .good
        }
        if categoryCount >= 2 || sampleCount >= 3 {
            return .limited
        }
        return .poor
    }
}

private extension Set where Element == UnifiedHealthMetricID {
    func intersects(_ metricIDs: [UnifiedHealthMetricID]) -> Bool {
        metricIDs.contains { metricID in self.contains(metricID) }
    }
}
