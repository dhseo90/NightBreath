import Foundation
import Testing
@testable import SleepSoundCore

@Suite("HealthCalendar")
struct HealthCalendarTests {
    private let builder = HealthCalendarBuilder()

    @Test
    func monthSummariesGroupSamplesByDayAndKeepMixedSources() throws {
        let targetDate = date(2026, 5, 3)
        let otherDate = date(2026, 5, 4)
        let samples = [
            sample(.systolicBloodPressure, 118, targetDate, sourceType: .healthKit, sourceName: "Apple 건강앱"),
            sample(.bodyWaterPercentage, 56.8, targetDate, sourceType: .fitdaysCSV, sourceName: "Fitdays CSV Import"),
            sample(.sleepSoundScore, 82, targetDate, sourceType: .appComputed, sourceName: "밤숨 앱"),
            sample(.bodyMass, 71.4, otherDate, sourceType: .healthKit, sourceName: "Apple 건강앱"),
        ]

        let summaries = builder.summaries(
            forMonthContaining: targetDate,
            samples: samples,
            sleepReports: [],
            calendar: calendar
        )
        let summary = try #require(summaries.first { calendar.isDate($0.date, inSameDayAs: targetDate) })

        #expect(summary.sampleCount == 3)
        #expect(summary.hasBloodPressure)
        #expect(summary.hasBodyComposition)
        #expect(!summary.hasActivity)
        #expect(summary.sourceTypes == [.healthKit, .fitdaysCSV, .appComputed])
        #expect(summary.dataQuality == .limited)
    }

    @Test
    func emptyMonthCellsRemainExplicitlyEmpty() throws {
        let targetDate = date(2026, 5, 11)
        let summaries = builder.summaries(
            forMonthContaining: targetDate,
            samples: [],
            sleepReports: [],
            calendar: calendar
        )
        let summary = try #require(summaries.first { calendar.isDate($0.date, inSameDayAs: targetDate) })

        #expect(!summary.hasAnyData)
        #expect(summary.sampleCount == 0)
        #expect(summary.sourceTypes.isEmpty)
        #expect(summary.dataQuality == .insufficient)
    }

    @Test
    func calendarViewCopyAvoidsDiagnosisAndCausalityWording() throws {
        let contents = try sourceContents("SleepSoundApp/Features/Dashboard/HealthCalendarView.swift")
        let restrictedPhrases = [
            "고혈압 " + "판정",
            "비만 " + "판정",
            "질병 " + "예측",
            "치료 " + "필요",
            "건강 " + "진단 " + "점수",
            "정상/" + "비정상",
            "코골기 때문에 " + "혈압이 올랐습니다",
        ]

        for phrase in restrictedPhrases {
            #expect(!contents.contains(phrase), "Health calendar copy contains restricted wording: \(phrase)")
        }
        #expect(contents.contains("인과관계를 의미하지 않습니다."))
        #expect(contents.contains("개인 참고용"))
    }

    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        calendar.firstWeekday = 1
        return calendar
    }

    private func date(_ year: Int, _ month: Int, _ day: Int, hour: Int = 8) -> Date {
        DateComponents(
            calendar: calendar,
            timeZone: TimeZone(secondsFromGMT: 0),
            year: year,
            month: month,
            day: day,
            hour: hour
        ).date!
    }

    private func sample(
        _ metricID: UnifiedHealthMetricID,
        _ value: Double,
        _ measuredAt: Date,
        sourceType: HealthMetricSourceType,
        sourceName: String
    ) -> UnifiedHealthMetricSample {
        UnifiedHealthMetricSample(
            metricID: metricID,
            value: value,
            unit: MetricCatalog.default.metadata(for: metricID)?.unit ?? "",
            measuredAt: measuredAt,
            sourceType: sourceType,
            sourceName: sourceName,
            createdAt: measuredAt
        )
    }

    private func sourceContents(_ relativePath: String) throws -> String {
        let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        return try String(contentsOf: root.appendingPathComponent(relativePath), encoding: .utf8)
    }
}
