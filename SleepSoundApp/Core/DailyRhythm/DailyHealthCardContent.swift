import Foundation

public struct DailyHealthCardMetric: Identifiable, Codable, Equatable, Sendable {
    public var id: String { "\(title)-\(value)-\(subtitle)" }

    public var title: String
    public var value: String
    public var subtitle: String
    public var metricType: HealthMetricType?
    public var sensitivity: DailyHealthCardMetricSensitivity

    public init(
        title: String,
        value: String,
        subtitle: String,
        metricType: HealthMetricType? = nil,
        sensitivity: DailyHealthCardMetricSensitivity = .general
    ) {
        self.title = title
        self.value = value
        self.subtitle = subtitle
        self.metricType = metricType
        self.sensitivity = sensitivity
    }
}

public struct DailyHealthCardContent: Codable, Equatable, Sendable {
    public var date: Date
    public var template: DailyHealthCardTemplate
    public var privacyLevel: DailyHealthCardPrivacyLevel
    public var rhythmScore: Int?
    public var dataQuality: DailyDataQuality
    public var keyMetrics: [DailyHealthCardMetric]
    public var summaryText: String
    public var referenceText: String

    public var containsSensitiveHealthValues: Bool {
        privacyLevel.includesSensitiveValues && keyMetrics.contains { $0.sensitivity == .sensitiveHealth }
    }

    public var requiresSensitiveExportConfirmation: Bool {
        containsSensitiveHealthValues
    }

    public var exportPrivacyNoticeMessages: [String] {
        var messages = [
            "이미지는 사용자가 선택한 경우에만 생성됩니다.",
            "자동 공유와 서버 업로드는 없습니다.",
        ]

        if containsSensitiveHealthValues {
            messages.insert("이 카드에는 건강 관련 수치가 포함됩니다. 공유 전 표시 항목을 확인해 주세요.", at: 0)
        } else {
            messages.insert("현재 표시 수준에서는 민감 건강 수치를 줄여 보여줍니다.", at: 0)
        }

        if privacyLevel.includesSourceDetails {
            messages.append("상세 표시 수준은 데이터 출처와 기록 시간을 함께 보여줄 수 있습니다.")
        }

        return messages
    }

    public init(
        date: Date,
        template: DailyHealthCardTemplate = .healthSummary,
        privacyLevel: DailyHealthCardPrivacyLevel = .standard,
        rhythmScore: Int? = nil,
        dataQuality: DailyDataQuality = .insufficient,
        keyMetrics: [DailyHealthCardMetric] = [],
        summaryText: String = "사용 가능한 하루 리듬 데이터를 한 장으로 정리했습니다.",
        referenceText: String = "개인 참고용 카드입니다."
    ) {
        self.date = date
        self.template = template
        self.privacyLevel = template.effectivePrivacyLevel ?? privacyLevel
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
        make(
            date: date,
            report: report,
            nightReport: nil,
            healthMetricSamples: healthMetricSamples,
            template: .healthSummary,
            privacyLevel: .standard,
            calendar: calendar
        )
    }

    public static func make(
        date: Date,
        report: DailyRhythmReport?,
        nightReport: NightReport? = nil,
        healthMetricSamples: [HealthMetricSample],
        template: DailyHealthCardTemplate,
        privacyLevel: DailyHealthCardPrivacyLevel,
        calendar: Calendar = .current
    ) -> DailyHealthCardContent {
        let effectivePrivacyLevel = template.effectivePrivacyLevel ?? privacyLevel
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

        guard effectivePrivacyLevel.includesSensitiveValues else {
            return content(
                date: date,
                template: template,
                privacyLevel: effectivePrivacyLevel,
                report: report,
                samples: samples,
                metrics: metrics,
                calendar: calendar
            )
        }

        if shouldIncludeSleepMetrics(template), let nightReport {
            metrics.append(contentsOf: sleepMetrics(from: nightReport, privacyLevel: effectivePrivacyLevel))
        }

        if shouldIncludeHealthMetrics(template) {
            if let bloodPressure = bloodPressureMetric(
                from: samples,
                privacyLevel: effectivePrivacyLevel,
                calendar: calendar
            ) {
                metrics.append(bloodPressure)
            }

            for metricType in preferredMetricTypes(for: template) {
                guard let sample = samples.latestSample(metricType: metricType) else { continue }
                metrics.append(
                    DailyHealthCardMetric(
                        title: metricType.displayName,
                        value: formattedValue(sample.value, unit: sample.unit),
                        subtitle: subtitle(for: sample, privacyLevel: effectivePrivacyLevel, calendar: calendar),
                        metricType: metricType,
                        sensitivity: sensitivity(for: metricType)
                    )
                )
            }
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

        return content(
            date: date,
            template: template,
            privacyLevel: effectivePrivacyLevel,
            report: report,
            samples: samples,
            metrics: metrics,
            calendar: calendar
        )
    }

    private static func content(
        date: Date,
        template: DailyHealthCardTemplate,
        privacyLevel: DailyHealthCardPrivacyLevel,
        report: DailyRhythmReport?,
        samples: [HealthMetricSample],
        metrics: [DailyHealthCardMetric],
        calendar: Calendar
    ) -> DailyHealthCardContent {
        let dataQuality = report?.dataQuality ?? DailyDataQuality.quality(
            for: samples.isEmpty ? 0 : min(Double(samples.count) / 12, 1)
        )

        return DailyHealthCardContent(
            date: calendar.startOfDay(for: date),
            template: template,
            privacyLevel: privacyLevel,
            rhythmScore: report?.dailyRhythmScore.totalScore,
            dataQuality: dataQuality,
            keyMetrics: metrics,
            summaryText: summaryText(template: template, privacyLevel: privacyLevel, report: report, sampleCount: samples.count),
            referenceText: "개인 패턴을 살펴보기 위한 참고용 카드입니다."
        )
    }

    private static func bloodPressureMetric(
        from samples: [HealthMetricSample],
        privacyLevel: DailyHealthCardPrivacyLevel,
        calendar: Calendar
    ) -> DailyHealthCardMetric? {
        guard let systolic = samples.latestSample(metricType: .systolicBloodPressure),
              let diastolic = samples.latestSample(metricType: .diastolicBloodPressure) else {
            return nil
        }

        return DailyHealthCardMetric(
            title: "아침 혈압",
            value: "\(Int(systolic.value.rounded()))/\(Int(diastolic.value.rounded())) mmHg",
            subtitle: subtitle(for: systolic, privacyLevel: privacyLevel, calendar: calendar),
            metricType: .systolicBloodPressure,
            sensitivity: .sensitiveHealth
        )
    }

    private static func sleepMetrics(
        from report: NightReport,
        privacyLevel: DailyHealthCardPrivacyLevel
    ) -> [DailyHealthCardMetric] {
        [
            DailyHealthCardMetric(
                title: "수면 소리 점수",
                value: "\(report.sleepSoundScore)점",
                subtitle: privacyLevel.includesSourceDetails
                    ? "오디오 커버리지 \(percentString(report.audioCoverageRatio))"
                    : "수면 중 소리 기반 점수",
                sensitivity: .sleep
            ),
            DailyHealthCardMetric(
                title: "측정 품질",
                value: report.measurementQuality.displayName,
                subtitle: privacyLevel.includesSourceDetails
                    ? "분석 범위 \(percentString(report.audioCoverageRatio))"
                    : "수면 소리 측정 품질",
                sensitivity: .sleep
            ),
        ]
    }

    private static func summaryText(
        template: DailyHealthCardTemplate,
        privacyLevel: DailyHealthCardPrivacyLevel,
        report: DailyRhythmReport?,
        sampleCount: Int
    ) -> String {
        if privacyLevel == .minimal {
            return "오늘의 리듬 점수와 한 줄 요약만 표시합니다."
        }

        if report == nil && sampleCount == 0 {
            return "비교 가능한 데이터가 부족해 일부 항목만 표시됩니다."
        }

        return template.summaryText
    }

    private static func subtitle(
        for sample: HealthMetricSample,
        privacyLevel: DailyHealthCardPrivacyLevel,
        calendar: Calendar
    ) -> String {
        guard privacyLevel.includesSourceDetails else {
            return "\(sample.metricType.dashboardSectionName) 기록"
        }

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

    private static func percentString(_ ratio: Double) -> String {
        String(format: "%.0f%%", min(max(ratio, 0), 1) * 100)
    }

    private static func shouldIncludeSleepMetrics(_ template: DailyHealthCardTemplate) -> Bool {
        switch template {
        case .simple, .sleepFocused:
            true
        case .healthSummary, .privacyMinimal:
            false
        }
    }

    private static func shouldIncludeHealthMetrics(_ template: DailyHealthCardTemplate) -> Bool {
        switch template {
        case .simple:
            true
        case .sleepFocused, .privacyMinimal:
            false
        case .healthSummary:
            true
        }
    }

    private static func preferredMetricTypes(for template: DailyHealthCardTemplate) -> [HealthMetricType] {
        switch template {
        case .simple:
            [.stepCount]
        case .sleepFocused, .privacyMinimal:
            []
        case .healthSummary:
            [.bodyMass, .bodyFatPercentage, .stepCount]
        }
    }

    private static func sensitivity(for metricType: HealthMetricType) -> DailyHealthCardMetricSensitivity {
        switch metricType {
        case .systolicBloodPressure, .diastolicBloodPressure, .bodyMass, .bodyFatPercentage, .bodyMassIndex, .leanBodyMass:
            .sensitiveHealth
        case .sleepDuration, .respiratoryRate:
            .sleep
        case .stepCount, .activeEnergy, .heartRate, .restingHeartRate:
            .general
        }
    }
}
