import Foundation

public struct MockHealthKitService: HealthKitServiceProtocol {
    public var samples: [HealthMetricSample]

    public var isAvailable: Bool {
        true
    }

    public init(samples: [HealthMetricSample] = Self.makeDefaultSamples()) {
        self.samples = samples.sortedByMeasuredAtAscending()
    }

    public func authorizationStatusDescription() -> String {
        "Mock 데이터로 건강 대시보드를 미리 확인합니다. 실제 건강앱 권한은 요청하지 않습니다."
    }

    public func requestReadPermission() async -> HealthMetricPermissionState {
        .mockDataOnly
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

    public static func makeDefaultSamples(referenceDate: Date = Date()) -> [HealthMetricSample] {
        let omron = ("Omron Connect", "com.omronhealthcare.omronconnect")
        let fitdays = ("Fitdays", "com.fitdays.app")
        let appleHealth = ("Apple Health Mock", "com.apple.Health.mock")
        var samples: [HealthMetricSample] = []

        let systolicValues = [124, 122, 121, 119, 120, 118, 121]
        let diastolicValues = [82, 80, 79, 78, 79, 77, 78]
        let bodyMassValues = [72.4, 72.1, 71.9, 71.8, 71.6, 71.7, 71.5]
        let bodyFatValues = [21.8, 21.7, 21.5, 21.4, 21.2, 21.1, 21.0]
        let bmiValues = [23.4, 23.3, 23.2, 23.2, 23.1, 23.1, 23.0]
        let leanMassValues = [56.6, 56.5, 56.5, 56.4, 56.4, 56.5, 56.5]
        let heartRateValues = [63, 62, 61, 62, 60, 61, 60]
        let sleepDurationValues = [6.7, 7.1, 6.4, 7.3, 6.9, 7.0, 7.2]
        let respiratoryRateValues = [15.1, 15.0, 14.8, 14.9, 15.2, 15.1, 14.9]

        for index in 0..<7 {
            let measuredAt = referenceDate.addingTimeInterval(-Double(6 - index) * 24 * 60 * 60)
            samples.append(sample(.systolicBloodPressure, Double(systolicValues[index]), measuredAt, omron))
            samples.append(sample(.diastolicBloodPressure, Double(diastolicValues[index]), measuredAt, omron))
            samples.append(sample(.bodyMass, bodyMassValues[index], measuredAt.addingTimeInterval(60 * 30), fitdays))
            samples.append(sample(.bodyFatPercentage, bodyFatValues[index], measuredAt.addingTimeInterval(60 * 30), fitdays))
            samples.append(sample(.bodyMassIndex, bmiValues[index], measuredAt.addingTimeInterval(60 * 30), fitdays))
            samples.append(sample(.leanBodyMass, leanMassValues[index], measuredAt.addingTimeInterval(60 * 30), fitdays))
            samples.append(sample(.restingHeartRate, Double(heartRateValues[index]), measuredAt.addingTimeInterval(60 * 60), appleHealth))
            samples.append(sample(.sleepDuration, sleepDurationValues[index], measuredAt.addingTimeInterval(60 * 90), appleHealth))
            samples.append(sample(.respiratoryRate, respiratoryRateValues[index], measuredAt.addingTimeInterval(60 * 90), appleHealth))
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
}
