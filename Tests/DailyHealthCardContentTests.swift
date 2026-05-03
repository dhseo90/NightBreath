import Foundation
import Testing
@testable import SleepSoundCore

@Suite("DailyHealthCardContent")
struct DailyHealthCardContentTests {
    @Test
    func contentBuildsCardReadyMetricsFromReportAndSamples() {
        let samples = MockHealthDataService.makeDefaultSamples(
            referenceDate: referenceDate,
            calendar: calendar
        )
        let content = DailyHealthCardContent.make(
            date: referenceDate,
            report: MockDailyRhythmData.sampleReport,
            healthMetricSamples: samples,
            calendar: calendar
        )

        #expect(content.rhythmScore == MockDailyRhythmData.sampleReport.dailyRhythmScore.totalScore)
        #expect(content.keyMetrics.count >= 3)
        #expect(content.keyMetrics.count <= 5)
        #expect(content.keyMetrics.contains { $0.title == "오늘의 리듬 점수" })
        #expect(content.keyMetrics.contains { $0.title == "혈압 기록" })
        #expect(content.referenceText.contains("개인 패턴"))
    }

    @Test
    func emptyContentUsesLimitedDataCopyInsteadOfLoweringIntoHealthJudgment() {
        let content = DailyHealthCardContent.make(
            date: referenceDate,
            report: nil,
            healthMetricSamples: [],
            calendar: calendar
        )

        #expect(content.rhythmScore == nil)
        #expect(content.dataQuality == .insufficient)
        #expect(content.keyMetrics.count == 1)
        #expect(content.summaryText == "비교 가능한 데이터가 부족해 일부 항목만 표시됩니다.")
    }

    @Test
    func cardCopyAvoidsDiagnosisAndCausalityClaims() {
        let samples = MockHealthDataService.makeDefaultSamples(
            referenceDate: referenceDate,
            calendar: calendar
        )
        let content = DailyHealthCardContent.make(
            date: referenceDate,
            report: MockDailyRhythmData.sampleReport,
            healthMetricSamples: samples,
            calendar: calendar
        )
        let combinedCopy = ([content.summaryText, content.referenceText] + content.keyMetrics.flatMap {
            [$0.title, $0.value, $0.subtitle]
        }).joined(separator: " ")
        let restrictedTerms = [
            "고혈압" + "입니다",
            "비만" + "입니다",
            "수면" + "무호흡증 가능성이 높습니다",
            "치료" + "가 필요합니다",
            "코골기" + " 때문에 혈압",
            "건강" + "진단" + "점수",
            "의학적" + "판정",
            "원인",
            "유발",
            "정상",
            "비정상",
        ]

        #expect(restrictedTerms.allSatisfy { !combinedCopy.contains($0) })
    }

    private var referenceDate: Date {
        Date(timeIntervalSince1970: 1_777_680_000)
    }

    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }
}
