import Foundation
import Testing
@testable import SleepSoundCore

@Suite("TrendAggregator")
struct TrendAggregatorTests {
    @Test
    func sevenDayAggregationIncludesOnlySelectedWindow() {
        let aggregator = TrendAggregator()
        let reports = [
            makeReport(daysAgo: 1, score: 90),
            makeReport(daysAgo: 6, score: 70),
            makeReport(daysAgo: 8, score: 40),
        ]

        let points = aggregator.dataPoints(
            reports: reports,
            metricType: .sleepSoundScore,
            periodDays: 7,
            referenceDate: referenceDate
        )
        let summary = aggregator.summary(
            reports: reports,
            metricType: .sleepSoundScore,
            periodDays: 7,
            referenceDate: referenceDate
        )

        #expect(points.count == 2)
        #expect(summary.dataPointCount == 2)
        #expect(summary.average == 80)
        #expect(summary.latest == 90)
    }

    @Test
    func thirtyDayAggregationUsesThirtyDayWindow() {
        let aggregator = TrendAggregator()
        let reports = [
            makeReport(daysAgo: 3, score: 88),
            makeReport(daysAgo: 29, score: 72),
            makeReport(daysAgo: 31, score: 30),
        ]

        let summary = aggregator.summary(
            reports: reports,
            metricType: .sleepSoundScore,
            periodDays: 30,
            referenceDate: referenceDate
        )

        #expect(summary.dataPointCount == 2)
        #expect(summary.average == 80)
        #expect(summary.min == 72)
        #expect(summary.max == 88)
    }

    @Test
    func lowCoverageReportsAreMarkedAndExcludedFromSummaryAverage() throws {
        let aggregator = TrendAggregator()
        let reports = [
            makeReport(daysAgo: 1, score: 90, audioCoverageRatio: 0.95),
            makeReport(daysAgo: 2, score: 30, audioCoverageRatio: 0.50),
        ]

        let points = aggregator.dataPoints(
            reports: reports,
            metricType: .sleepSoundScore,
            periodDays: 7,
            referenceDate: referenceDate
        )
        let lowQualityPoint = try #require(points.first { $0.value == 30 })
        let summary = aggregator.summary(
            reports: reports,
            metricType: .sleepSoundScore,
            periodDays: 7,
            referenceDate: referenceDate
        )

        #expect(lowQualityPoint.isLowMeasurementQuality)
        #expect(summary.lowQualityDataCount == 1)
        #expect(summary.dataPointCount == 2)
        #expect(summary.includedDataPointCount == 1)
        #expect(summary.average == 90)
    }

    @Test
    func emptyReportListProducesEmptyStateSummary() {
        let aggregator = TrendAggregator()

        let points = aggregator.dataPoints(
            reports: [],
            metricType: .environmentalNoiseCount,
            periodDays: 7,
            referenceDate: referenceDate
        )
        let summary = aggregator.summary(
            reports: [],
            metricType: .environmentalNoiseCount,
            periodDays: 7,
            referenceDate: referenceDate
        )

        #expect(points.isEmpty)
        #expect(!summary.hasData)
        #expect(summary.average == nil)
        #expect(summary.latest == nil)
    }

    @Test
    func singleReportSummaryUsesTheSameValueForLatestAverageMinimumAndMaximum() {
        let aggregator = TrendAggregator()
        let report = makeReport(daysAgo: 1, score: 77, snoreTotalSeconds: 180)

        let summary = aggregator.summary(
            reports: [report],
            metricType: .snoreTotalSeconds,
            periodDays: 7,
            referenceDate: referenceDate
        )

        #expect(summary.dataPointCount == 1)
        #expect(summary.latest == 3)
        #expect(summary.average == 3)
        #expect(summary.min == 3)
        #expect(summary.max == 3)
    }

    @Test
    func summaryCalculatesChangeFromPreviousPeriod() {
        let aggregator = TrendAggregator()
        let reports = [
            makeReport(daysAgo: 1, score: 90),
            makeReport(daysAgo: 2, score: 70),
            makeReport(daysAgo: 9, score: 60),
            makeReport(daysAgo: 10, score: 40),
        ]

        let summary = aggregator.summary(
            reports: reports,
            metricType: .sleepSoundScore,
            periodDays: 7,
            referenceDate: referenceDate
        )

        #expect(summary.average == 80)
        #expect(summary.changeFromPreviousPeriod == 30)
    }

    private var referenceDate: Date {
        Date(timeIntervalSince1970: 1_777_680_000)
    }

    private func makeReport(
        daysAgo: Int,
        score: Int,
        audioCoverageRatio: Double = 0.95,
        snoreTotalSeconds: TimeInterval = 0,
        bruxismLikeCount: Int = 0,
        suspectedPauseCount: Int = 0,
        gaspLikeCount: Int = 0,
        coughLikeCount: Int = 0,
        environmentalNoiseCount: Int = 0,
        awakeningSuspectedCount: Int = 0
    ) -> NightReport {
        NightReport(
            sessionId: UUID(),
            generatedAt: referenceDate.addingTimeInterval(-Double(daysAgo) * 24 * 60 * 60),
            measurementDuration: 7 * 60 * 60,
            estimatedSleepDuration: 6.5 * 60 * 60,
            receivedAudioDuration: audioCoverageRatio * 7 * 60 * 60,
            audioCoverageRatio: audioCoverageRatio,
            sleepSoundScore: score,
            snoreTotalSeconds: snoreTotalSeconds,
            snoreRatio: 0,
            bruxismLikeCount: bruxismLikeCount,
            suspectedPauseCount: suspectedPauseCount,
            gaspLikeCount: gaspLikeCount,
            coughLikeCount: coughLikeCount,
            sleepTalkLikeCount: 0,
            environmentalNoiseCount: environmentalNoiseCount,
            awakeningSuspectedCount: awakeningSuspectedCount,
            longestSuspectedPause: 0,
            mostDisturbedHourRange: nil,
            mainDisturbanceReason: "테스트용 수면 소리 리포트입니다."
        )
    }
}
