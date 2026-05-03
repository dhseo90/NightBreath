import Foundation
import Testing
@testable import SleepSoundCore

@Suite("DailyRhythmReport")
struct DailyRhythmReportTests {
    @Test
    func scoreAndReportClampComponentValues() {
        let score = DailyRhythmScore(
            totalScore: 140,
            sleepComponent: 90,
            recoveryComponent: -20,
            activityComponent: 70,
            bloodPressureComponent: 60,
            bodyMetricComponent: 50,
            dataCompleteness: 1.5,
            computedAt: referenceDate
        )
        let report = DailyRhythmReport(
            date: referenceDate,
            dailyRhythmScore: score,
            sleepComponentScore: 101,
            recoveryComponentScore: -1
        )

        #expect(score.totalScore == 100)
        #expect(score.recoveryComponent == 0)
        #expect(score.dataCompleteness == 1)
        #expect(report.sleepComponentScore == 100)
        #expect(report.recoveryComponentScore == 0)
        #expect(report.activityComponentScore == 70)
        #expect(report.dataQuality == .excellent)
    }

    @Test
    func reportUsesDefaultWellnessCautionText() {
        let report = DailyRhythmReport(date: referenceDate, dailyRhythmScore: makeScore())

        #expect(report.isMedicalDisclaimerRequired)
        #expect(report.cautionText.contains("참고용"))
        #expect(report.cautionText.contains("진단 목적의 의료기기가 아닙니다"))
    }

    @Test
    func reportAndInsightsRoundTripThroughJSON() throws {
        let report = MockDailyRhythmData.sampleReport

        let encoded = try JSONEncoder().encode(report)
        let decoded = try JSONDecoder().decode(DailyRhythmReport.self, from: encoded)

        #expect(decoded == report)
        #expect(decoded.insights.count == 3)
        #expect(decoded.dailyRhythmScore.totalScore == 84)
    }

    @Test
    func mockReportCopyAvoidsRestrictedClaims() {
        let combinedCopy = ([MockDailyRhythmData.sampleReport.cautionText] +
            MockDailyRhythmData.sampleReport.insights.flatMap { [$0.title, $0.message] })
            .joined(separator: " ")

        let restrictedTerms = [
            "수면" + "무호흡증",
            "고혈압" + "판정",
            "질병" + "예측",
            "치료" + "필요",
            "건강" + "진단" + "점수",
            "의학적" + "판정",
        ]

        #expect(restrictedTerms.allSatisfy { !combinedCopy.contains($0) })
    }

    private var referenceDate: Date {
        Date(timeIntervalSince1970: 1_777_680_000)
    }

    private func makeScore() -> DailyRhythmScore {
        DailyRhythmScore(
            totalScore: 82,
            sleepComponent: 84,
            recoveryComponent: 78,
            activityComponent: 80,
            bloodPressureComponent: 82,
            bodyMetricComponent: 85,
            dataCompleteness: 0.76,
            computedAt: referenceDate
        )
    }
}
