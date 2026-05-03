import Foundation

public struct DailyHealthCardMetric: Identifiable, Codable, Equatable, Sendable {
    public var id: String { "\(title)-\(value)-\(subtitle)" }

    public var title: String
    public var value: String
    public var subtitle: String
    public var metricType: HealthMetricType?

    public init(
        title: String,
        value: String,
        subtitle: String,
        metricType: HealthMetricType? = nil
    ) {
        self.title = title
        self.value = value
        self.subtitle = subtitle
        self.metricType = metricType
    }
}

public struct DailyHealthCardContent: Codable, Equatable, Sendable {
    public var date: Date
    public var rhythmScore: Int?
    public var dataQuality: DailyDataQuality
    public var keyMetrics: [DailyHealthCardMetric]
    public var summaryText: String
    public var referenceText: String

    public init(
        date: Date,
        rhythmScore: Int? = nil,
        dataQuality: DailyDataQuality = .insufficient,
        keyMetrics: [DailyHealthCardMetric] = [],
        summaryText: String = "사용 가능한 하루 리듬 데이터를 한 장으로 정리했습니다.",
        referenceText: String = "개인 참고용 카드입니다."
    ) {
        self.date = date
        self.rhythmScore = rhythmScore.map(DailyRhythmScore.clampedScore)
        self.dataQuality = dataQuality
        self.keyMetrics = Array(keyMetrics.prefix(5))
        self.summaryText = summaryText
        self.referenceText = referenceText
    }

    public static func make(
        date: Date,
        report: DailyRhythmReport?,
        healthMetricSamples: [HealthMetricSample],
        calendar: Calendar = .current
    ) -> DailyHealthCardContent {
        let samples = healthMetricSamples
            .filter { calendar.isDate($0.measuredAt, inSameDayAs: date) }
            .sortedByMeasuredAtAscending()
        var metrics: [DailyHealthCardMetric] = []

        if let report {
            metrics.append(
                DailyHealthCardMetric(
                    title: "오늘의 리듬 점수",
                    value: "\(report.dailyRhythmScore.totalScore)점",
                    subtitle: "데이터 품질 \(report.dataQuality.displayName)"
                )
            )
        }

        if let bloodPressure = bloodPressureMetric(from: samples, calendar: calendar) {
            metrics.append(bloodPressure)
        }

        for metricType in preferredMetricTypes {
            guard let sample = samples.latestSample(metricType: metricType) else { continue }
            metrics.append(
                DailyHealthCardMetric(
                    title: metricType.displayName,
                    value: formattedValue(sample.value, unit: sample.unit),
                    subtitle: subtitle(for: sample, calendar: calendar),
                    metricType: metricType
                )
            )
        }

        if metrics.isEmpty {
            metrics.append(
                DailyHealthCardMetric(
                    title: "데이터 품질",
                    value: DailyDataQuality.insufficient.displayName,
                    subtitle: "비교 가능한 데이터가 부족합니다."
                )
            )
        }

        let dataQuality = report?.dataQuality ?? DailyDataQuality.quality(
            for: samples.isEmpty ? 0 : min(Double(samples.count) / 12, 1)
        )

        return DailyHealthCardContent(
            date: calendar.startOfDay(for: date),
            rhythmScore: report?.dailyRhythmScore.totalScore,
            dataQuality: dataQuality,
            keyMetrics: metrics,
            summaryText: summaryText(report: report, sampleCount: samples.count),
            referenceText: "개인 패턴을 살펴보기 위한 참고용 카드입니다."
        )
    }

    private static func bloodPressureMetric(
        from samples: [HealthMetricSample],
        calendar: Calendar
    ) -> DailyHealthCardMetric? {
        guard let systolic = samples.latestSample(metricType: .systolicBloodPressure),
              let diastolic = samples.latestSample(metricType: .diastolicBloodPressure) else {
            return nil
        }

        return DailyHealthCardMetric(
            title: "혈압 기록",
            value: "\(Int(systolic.value.rounded()))/\(Int(diastolic.value.rounded())) mmHg",
            subtitle: subtitle(for: systolic, calendar: calendar),
            metricType: .systolicBloodPressure
        )
    }

    private static func summaryText(report: DailyRhythmReport?, sampleCount: Int) -> String {
        if report == nil && sampleCount == 0 {
            return "비교 가능한 데이터가 부족해 일부 항목만 표시됩니다."
        }

        return "수면, 활동, 컨디션, 건강 데이터를 사용 가능한 범위에서 함께 정리했습니다."
    }

    private static func subtitle(
        for sample: HealthMetricSample,
        calendar: Calendar
    ) -> String {
        let components = calendar.dateComponents([.hour, .minute], from: sample.measuredAt)
        let hour = components.hour ?? 0
        let minute = components.minute ?? 0
        return String(format: "%@ · %02d:%02d", sample.sourceName, hour, minute)
    }

    private static func formattedValue(_ value: Double, unit: String) -> String {
        switch unit {
        case "mmHg", "bpm", "kcal":
            return "\(Int(value.rounded())) \(unit)"
        case "걸음":
            return "\(Int(value.rounded()).formatted())걸음"
        case "BMI":
            return String(format: "%.1f", value)
        case "시간":
            return String(format: "%.1f시간", value)
        case "%":
            return String(format: "%.1f%%", value)
        default:
            return String(format: "%.1f %@", value, unit)
        }
    }

    private static let preferredMetricTypes: [HealthMetricType] = [
        .bodyMass,
        .bodyFatPercentage,
        .stepCount,
        .activeEnergy,
        .restingHeartRate,
    ]
}
