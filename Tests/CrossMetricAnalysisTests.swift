import Foundation
import Testing
@testable import SleepSoundCore

@Suite("CrossMetricAnalysis")
struct CrossMetricAnalysisTests {
    @Test
    func dateMatchingUsesNextMorningForBloodPressureAndSameDayForBodyMetrics() throws {
        let analyzer = CrossMetricAnalyzer(calendar: calendar, minimumMatchedSampleCount: 1)
        let reportDate = date(2026, 5, 1, 7, 0)
        let reports = [makeReport(generatedAt: reportDate)]

        let bloodPressurePoints = analyzer.matchedPoints(
            reports: reports,
            samples: [
                sample(.systolicBloodPressure, 119, at: date(2026, 5, 1, 8, 0)),
                sample(.systolicBloodPressure, 123, at: date(2026, 5, 2, 8, 0)),
            ],
            sleepMetric: .snoreTotalSeconds,
            healthMetric: .systolicBloodPressure,
            period: .sevenDays,
            endingAt: date(2026, 5, 3, 12, 0)
        )

        let bodyMassPoints = analyzer.matchedPoints(
            reports: reports,
            samples: [
                sample(.bodyMass, 71.2, at: date(2026, 5, 1, 7, 30)),
                sample(.bodyMass, 71.5, at: date(2026, 5, 2, 7, 30)),
            ],
            sleepMetric: .sleepSoundScore,
            healthMetric: .bodyMass,
            period: .sevenDays,
            endingAt: date(2026, 5, 3, 12, 0)
        )

        #expect(bloodPressurePoints.count == 1)
        #expect(try #require(bloodPressurePoints.first).healthValue == 123)
        #expect(try #require(bloodPressurePoints.first).matchingStrategy == .nextMorning)
        #expect(bodyMassPoints.count == 1)
        #expect(try #require(bodyMassPoints.first).healthValue == 71.2)
        #expect(try #require(bodyMassPoints.first).matchingStrategy == .sameCalendarDay)
    }

    @Test
    func insufficientDataUsesCarefulEmptyStateSummary() {
        let analyzer = CrossMetricAnalyzer(calendar: calendar)
        let reports = [
            makeReport(generatedAt: date(2026, 5, 1, 7, 0)),
            makeReport(generatedAt: date(2026, 5, 2, 7, 0)),
        ]
        let samples = [
            sample(.systolicBloodPressure, 120, at: date(2026, 5, 2, 8, 0)),
            sample(.systolicBloodPressure, 122, at: date(2026, 5, 3, 8, 0)),
        ]

        let summary = analyzer.summary(
            reports: reports,
            samples: samples,
            sleepMetric: .snoreTotalSeconds,
            healthMetric: .systolicBloodPressure,
            period: .sevenDays,
            endingAt: date(2026, 5, 4, 12, 0)
        )

        #expect(summary.dataQuality == .insufficientData)
        #expect(!summary.hasEnoughData)
        #expect(summary.matchedSampleCount == 2)
        #expect(summary.trendDescription == "비교 가능한 데이터가 아직 부족합니다.")
    }

    @Test
    func lowAudioCoverageIsMarkedAndExcludedFromSummary() {
        let analyzer = CrossMetricAnalyzer(calendar: calendar, minimumMatchedSampleCount: 2)
        let reports = [
            makeReport(generatedAt: date(2026, 5, 1, 7, 0), audioCoverageRatio: 0.96),
            makeReport(generatedAt: date(2026, 5, 2, 7, 0), audioCoverageRatio: 0.52),
            makeReport(generatedAt: date(2026, 5, 3, 7, 0), audioCoverageRatio: 0.95),
        ]
        let samples = [
            sample(.bodyMass, 71.0, at: date(2026, 5, 1, 8, 0)),
            sample(.bodyMass, 71.1, at: date(2026, 5, 2, 8, 0)),
            sample(.bodyMass, 70.9, at: date(2026, 5, 3, 8, 0)),
        ]

        let points = analyzer.matchedPoints(
            reports: reports,
            samples: samples,
            sleepMetric: .sleepSoundScore,
            healthMetric: .bodyMass,
            period: .sevenDays,
            endingAt: date(2026, 5, 4, 12, 0)
        )
        let summary = analyzer.summary(
            reports: reports,
            samples: samples,
            sleepMetric: .sleepSoundScore,
            healthMetric: .bodyMass,
            period: .sevenDays,
            endingAt: date(2026, 5, 4, 12, 0)
        )

        #expect(points.count == 3)
        #expect(points.filter(\.isIncludedInSummary).count == 2)
        #expect(points.filter(\.isLowMeasurementQuality).count == 1)
        #expect(summary.totalMatchedSampleCount == 3)
        #expect(summary.matchedSampleCount == 2)
        #expect(summary.lowQualityExcludedCount == 1)
        #expect(summary.dataQuality == .limited)
    }

    @Test
    func sourceAttributionUsesMatchedHealthSamples() {
        let analyzer = CrossMetricAnalyzer(calendar: calendar, minimumMatchedSampleCount: 3)
        let reports = [
            makeReport(generatedAt: date(2026, 5, 1, 7, 0)),
            makeReport(generatedAt: date(2026, 5, 2, 7, 0)),
            makeReport(generatedAt: date(2026, 5, 3, 7, 0)),
        ]
        let samples = [
            sample(.bodyMass, 71.0, at: date(2026, 5, 1, 8, 0), source: ("Fitdays", "com.fitdays")),
            sample(.bodyMass, 71.1, at: date(2026, 5, 2, 8, 0), source: ("Fitdays", "com.fitdays")),
            sample(.bodyMass, 70.9, at: date(2026, 5, 3, 8, 0), source: ("Apple Health", "com.apple.health")),
        ]

        let summary = analyzer.summary(
            reports: reports,
            samples: samples,
            sleepMetric: .sleepSoundScore,
            healthMetric: .bodyMass,
            period: .sevenDays,
            endingAt: date(2026, 5, 4, 12, 0)
        )

        #expect(Set(summary.healthSourceNames) == Set(["Fitdays", "Apple Health"]))
        #expect(summary.sourceSummaries.map(\.sampleCount).reduce(0, +) == 3)
    }

    @Test
    func crossMetricCopyDoesNotContainCausalClaimExamples() throws {
        let repositoryRoot = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        let scannedFiles = [
            "SleepSoundApp/Core/FutureHealth/CrossMetricAnalysis.swift",
            "SleepSoundApp/Features/Dashboard/CrossMetricDashboardView.swift",
            "Docs/CROSS_METRIC_ANALYSIS.md",
        ]
        let restrictedPhrases = [
            "혈압이 " + "높아진 " + "원" + "인은",
            "코골기 " + "때문에",
            "수면무호흡으로 " + "인한",
            "혈압 " + "상승입니다",
            "치료가 " + "필요",
            "질병 " + "판정",
        ]

        for relativePath in scannedFiles {
            let url = repositoryRoot.appendingPathComponent(relativePath)
            let contents = try String(contentsOf: url, encoding: .utf8)
            for phrase in restrictedPhrases {
                #expect(!contents.contains(phrase), "\(relativePath) contains restricted wording: \(phrase)")
            }
        }
    }

    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Seoul") ?? .current
        return calendar
    }

    private func date(
        _ year: Int,
        _ month: Int,
        _ day: Int,
        _ hour: Int,
        _ minute: Int
    ) -> Date {
        calendar.date(
            from: DateComponents(
                timeZone: calendar.timeZone,
                year: year,
                month: month,
                day: day,
                hour: hour,
                minute: minute
            )
        ) ?? Date(timeIntervalSince1970: 0)
    }

    private func makeReport(
        generatedAt: Date,
        audioCoverageRatio: Double = 0.95
    ) -> NightReport {
        NightReport(
            sessionId: UUID(),
            generatedAt: generatedAt,
            measurementDuration: 7 * 60 * 60,
            estimatedSleepDuration: 6.5 * 60 * 60,
            receivedAudioDuration: audioCoverageRatio * 7 * 60 * 60,
            audioCoverageRatio: audioCoverageRatio,
            sleepSoundScore: 82,
            snoreTotalSeconds: 18 * 60,
            snoreRatio: 0.04,
            bruxismLikeCount: 1,
            suspectedPauseCount: 0,
            gaspLikeCount: 0,
            coughLikeCount: 1,
            sleepTalkLikeCount: 0,
            environmentalNoiseCount: 2,
            awakeningSuspectedCount: 0,
            longestSuspectedPause: 0,
            mostDisturbedHourRange: nil,
            mainDisturbanceReason: "테스트용 수면 소리 리포트입니다."
        )
    }

    private func sample(
        _ metricType: HealthMetricType,
        _ value: Double,
        at measuredAt: Date,
        source: (name: String, bundleIdentifier: String) = ("Apple Health", "com.apple.health")
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
