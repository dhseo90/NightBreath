import Foundation

public struct MockHealthDataService: HealthDataServiceProtocol {
    public static let omronConnectSource = (
        name: "Omron Connect",
        bundleIdentifier: "com.omronhealthcare.omronconnect"
    )
    public static let fitdaysSource = (
        name: "Fitdays",
        bundleIdentifier: "com.fitdays.app"
    )
    public static let appleHealthMockSource = (
        name: "Apple 건강앱 예시",
        bundleIdentifier: "com.apple.Health.mock"
    )

    public var samples: [HealthMetricSample]

    public init(samples: [HealthMetricSample] = Self.makeDefaultSamples()) {
        self.samples = samples.sortedByMeasuredAtAscending()
    }

    public func fetchSamples(
        metricType: HealthMetricType,
        dateRange: HealthMetricDateRange
    ) async -> [HealthMetricSample] {
        samples.filtered(metricType: metricType, dateRange: dateRange)
    }

    public func fetchLatestSample(metricType: HealthMetricType) async -> HealthMetricSample? {
        samples.latestSample(metricType: metricType)
    }

    public func fetchSamplesForDay(
        _ date: Date,
        calendar: Calendar = .current
    ) async -> [HealthMetricSample] {
        let range = Self.dayRange(for: date, calendar: calendar)
        return HealthMetricType.dailyRhythmMockMetrics
            .flatMap { metricType in samples.filtered(metricType: metricType, dateRange: range) }
            .sortedByMeasuredAtAscending()
    }

    public func fetchDailySummary(
        date: Date,
        calendar: Calendar = .current
    ) async -> HealthDailySummary {
        let daySamples = await fetchSamplesForDay(date, calendar: calendar)
        return HealthDailySummary(date: calendar.startOfDay(for: date), samples: daySamples)
    }

    public static func makeDefaultSamples(
        referenceDate: Date = Date(),
        calendar: Calendar = .current
    ) -> [HealthMetricSample] {
        var samples: [HealthMetricSample] = []
        let referenceDayStart = calendar.startOfDay(for: referenceDate)

        let systolicValues = [122, 121, 119, 120, 118, 121, 120]
        let diastolicValues = [80, 79, 78, 79, 77, 78, 77]
        let bodyMassValues = [72.4, 72.1, 71.9, 71.8, 71.6, 71.7, 71.5]
        let bodyFatValues = [21.8, 21.7, 21.5, 21.4, 21.2, 21.1, 21.0]
        let bmiValues = [23.4, 23.3, 23.2, 23.2, 23.1, 23.1, 23.0]
        let leanMassValues = [56.6, 56.5, 56.5, 56.4, 56.4, 56.5, 56.5]
        let stepValues = [6_400, 7_200, 5_800, 8_100, 6_900, 7_500, 7_000]
        let activeEnergyValues = [310, 360, 290, 410, 340, 380, 355]
        let heartRateValues = [74, 72, 73, 71, 70, 72, 71]
        let restingHeartRateValues = [62, 61, 62, 60, 61, 60, 60]
        let sleepDurationValues = [6.7, 7.1, 6.4, 7.3, 6.9, 7.0, 7.2]
        let respiratoryRateValues = [15.1, 15.0, 14.8, 14.9, 15.2, 15.1, 14.9]

        for index in 0..<7 {
            let dayStart = calendar.date(
                byAdding: .day,
                value: -(6 - index),
                to: referenceDayStart
            ) ?? referenceDayStart.addingTimeInterval(-Double(6 - index) * 24 * 60 * 60)
            samples.append(sample(.systolicBloodPressure, Double(systolicValues[index]), dayStart.addingTimeInterval(8 * 60 * 60), omronConnectSource))
            samples.append(sample(.diastolicBloodPressure, Double(diastolicValues[index]), dayStart.addingTimeInterval(8 * 60 * 60 + 60), omronConnectSource))
            samples.append(sample(.bodyMass, bodyMassValues[index], dayStart.addingTimeInterval(7 * 60 * 60), fitdaysSource))
            samples.append(sample(.bodyFatPercentage, bodyFatValues[index], dayStart.addingTimeInterval(7 * 60 * 60 + 60), fitdaysSource))
            samples.append(sample(.bodyMassIndex, bmiValues[index], dayStart.addingTimeInterval(7 * 60 * 60 + 120), fitdaysSource))
            samples.append(sample(.leanBodyMass, leanMassValues[index], dayStart.addingTimeInterval(7 * 60 * 60 + 180), fitdaysSource))
            samples.append(sample(.stepCount, Double(stepValues[index]), dayStart.addingTimeInterval(21 * 60 * 60), appleHealthMockSource))
            samples.append(sample(.activeEnergy, Double(activeEnergyValues[index]), dayStart.addingTimeInterval(21 * 60 * 60 + 60), appleHealthMockSource))
            samples.append(sample(.heartRate, Double(heartRateValues[index]), dayStart.addingTimeInterval(15 * 60 * 60), appleHealthMockSource))
            samples.append(sample(.restingHeartRate, Double(restingHeartRateValues[index]), dayStart.addingTimeInterval(6 * 60 * 60), appleHealthMockSource))
            samples.append(sample(.sleepDuration, sleepDurationValues[index], dayStart.addingTimeInterval(6 * 60 * 60 + 60), appleHealthMockSource))
            samples.append(sample(.respiratoryRate, respiratoryRateValues[index], dayStart.addingTimeInterval(6 * 60 * 60 + 120), appleHealthMockSource))
        }

        return samples
    }

    private static func sample(
        _ metricType: HealthMetricType,
        _ value: Double,
        _ measuredAt: Date,
        _ source: (name: String, bundleIdentifier: String)
    ) -> HealthMetricSample {
        HealthMetricSample(
            metricType: metricType,
            value: value,
            unit: metricType.unitLabel,
            measuredAt: measuredAt,
            sourceName: source.name,
            sourceBundleIdentifier: source.bundleIdentifier
        )
    }

    private static func dayRange(for date: Date, calendar: Calendar) -> HealthMetricDateRange {
        let start = calendar.startOfDay(for: date)
        let nextDay = calendar.date(byAdding: .day, value: 1, to: start) ?? start.addingTimeInterval(24 * 60 * 60)
        return HealthMetricDateRange(start: start, end: nextDay.addingTimeInterval(-0.001))
    }
}
