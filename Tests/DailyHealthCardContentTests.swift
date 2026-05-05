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
        #expect(content.keyMetrics.contains { $0.title == "아침 혈압" })
        #expect(content.referenceText.contains("개인 패턴"))
    }

    @Test
    func sleepFocusedTemplateShowsSleepMetricsWithoutHealthValues() {
        let fixture = makeFixture()
        let content = DailyHealthCardContent.make(
            date: referenceDate,
            report: MockDailyRhythmData.sampleReport,
            nightReport: fixture.nightReport,
            healthMetricSamples: fixture.samples,
            template: .sleepFocused,
            privacyLevel: .standard,
            calendar: calendar
        )
        let titles = content.keyMetrics.map(\.title)

        #expect(titles.contains("오늘의 리듬 점수"))
        #expect(titles.contains("수면 소리 점수"))
        #expect(titles.contains("측정 품질"))
        #expect(!titles.contains("아침 혈압"))
        #expect(!titles.contains("체중"))
    }

    @Test
    func healthSummaryTemplateShowsHealthMetrics() {
        let fixture = makeFixture()
        let content = DailyHealthCardContent.make(
            date: referenceDate,
            report: MockDailyRhythmData.sampleReport,
            nightReport: fixture.nightReport,
            healthMetricSamples: fixture.samples,
            template: .healthSummary,
            privacyLevel: .standard,
            calendar: calendar
        )
        let titles = content.keyMetrics.map(\.title)

        #expect(titles.contains("아침 혈압"))
        #expect(titles.contains("체중"))
        #expect(titles.contains("체지방률"))
        #expect(titles.contains("걸음 수"))
        #expect(!titles.contains("수면 소리 점수"))
    }

    @Test
    func minimalPrivacyHidesSensitiveHealthValues() {
        let fixture = makeFixture()
        let content = DailyHealthCardContent.make(
            date: referenceDate,
            report: MockDailyRhythmData.sampleReport,
            nightReport: fixture.nightReport,
            healthMetricSamples: fixture.samples,
            template: .healthSummary,
            privacyLevel: .minimal,
            calendar: calendar
        )
        let combinedMetrics = content.keyMetrics.flatMap { [$0.title, $0.value, $0.subtitle] }.joined(separator: " ")

        #expect(content.privacyLevel == .minimal)
        #expect(content.keyMetrics.map(\.title) == ["오늘의 리듬 점수"])
        #expect(!combinedMetrics.contains("mmHg"))
        #expect(!combinedMetrics.contains("kg"))
        #expect(!combinedMetrics.contains("%"))
        #expect(!combinedMetrics.contains("걸음"))
    }

    @Test
    func privacyMinimalTemplateForcesMinimalPrivacy() {
        let fixture = makeFixture()
        let content = DailyHealthCardContent.make(
            date: referenceDate,
            report: MockDailyRhythmData.sampleReport,
            nightReport: fixture.nightReport,
            healthMetricSamples: fixture.samples,
            template: .privacyMinimal,
            privacyLevel: .detailed,
            calendar: calendar
        )

        #expect(content.template == .privacyMinimal)
        #expect(content.privacyLevel == .minimal)
        #expect(content.keyMetrics.map(\.title) == ["오늘의 리듬 점수"])
    }

    @Test
    func detailedPrivacyAddsMockSourceDetails() {
        let fixture = makeFixture()
        let standard = DailyHealthCardContent.make(
            date: referenceDate,
            report: MockDailyRhythmData.sampleReport,
            nightReport: fixture.nightReport,
            healthMetricSamples: fixture.samples,
            template: .healthSummary,
            privacyLevel: .standard,
            calendar: calendar
        )
        let detailed = DailyHealthCardContent.make(
            date: referenceDate,
            report: MockDailyRhythmData.sampleReport,
            nightReport: fixture.nightReport,
            healthMetricSamples: fixture.samples,
            template: .healthSummary,
            privacyLevel: .detailed,
            calendar: calendar
        )
        let standardCopy = standard.keyMetrics.flatMap { [$0.subtitle] }.joined(separator: " ")
        let detailedCopy = detailed.keyMetrics.flatMap { [$0.subtitle] }.joined(separator: " ")

        #expect(!standardCopy.contains("Omron Connect"))
        #expect(!standardCopy.contains("Fitdays"))
        #expect(detailedCopy.contains("Omron Connect"))
        #expect(detailedCopy.contains("Fitdays"))
    }

    @Test
    func sensitiveHealthValuesRequireExportConfirmation() {
        let fixture = makeFixture()
        let content = DailyHealthCardContent.make(
            date: referenceDate,
            report: MockDailyRhythmData.sampleReport,
            nightReport: fixture.nightReport,
            healthMetricSamples: fixture.samples,
            template: .healthSummary,
            privacyLevel: .standard,
            calendar: calendar
        )

        #expect(content.containsSensitiveHealthValues)
        #expect(content.requiresSensitiveExportConfirmation)
        #expect(content.exportPrivacyNoticeMessages.contains {
            $0.contains("건강 관련 수치") && $0.contains("공유 전")
        })
        #expect(content.exportPrivacyNoticeMessages.contains("자동 공유와 서버 업로드는 없습니다."))
    }

    @Test
    func minimalPrivacyExportDoesNotRequireSensitiveConfirmation() {
        let fixture = makeFixture()
        let content = DailyHealthCardContent.make(
            date: referenceDate,
            report: MockDailyRhythmData.sampleReport,
            nightReport: fixture.nightReport,
            healthMetricSamples: fixture.samples,
            template: .privacyMinimal,
            privacyLevel: .detailed,
            calendar: calendar
        )

        #expect(!content.containsSensitiveHealthValues)
        #expect(!content.requiresSensitiveExportConfirmation)
        #expect(content.exportPrivacyNoticeMessages.contains {
            $0.contains("민감 건강 수치를 줄여")
        })
    }

    @Test
    func placeholderRendererDoesNotExportImageData() async {
        let result = await PlaceholderDailyHealthCardRenderer().renderCard(
            report: MockDailyRhythmData.sampleReport,
            template: .healthSummary,
            privacyLevel: .detailed
        )

        #expect(result.reportId == MockDailyRhythmData.sampleReport.id)
        #expect(result.template == .healthSummary)
        #expect(result.privacyLevel == .detailed)
        #expect(result.isPlaceholder)
        #expect(result.imageData == nil)
        #expect(result.fileName == nil)
    }

    @Test
    func previewImageExportRequiresExplicitLocalActionAndShareButton() throws {
        let contents = try sourceContents("SleepSoundApp/Features/DailyRhythm/DailyHealthCardPreviewView.swift")

        #expect(contents.contains("ImageRenderer"))
        #expect(contents.contains("UIActivityViewController"))
        #expect(contents.contains("completionWithItemsHandler"))
        #expect(contents.contains("DailyHealthCardExportConfirmationSheet"))
        #expect(contents.contains("isShowingSensitiveExportConfirmation"))
        #expect(contents.contains("이미지 만들기"))
        #expect(contents.contains("FileManager.default.temporaryDirectory"))
        #expect(contents.contains("자동 공유와 서버 업로드는 없습니다."))
        #expect(contents.contains("공유를 완료했습니다."))
        #expect(contents.contains("공유를 취소했거나 진행하지 않았습니다."))
        #expect(contents.contains(".pngData()"))
        #expect(contents.contains(".png"))
        #expect(!contents.contains("URLSession"))
        #expect(!contents.contains("http://"))
        #expect(!contents.contains("https://"))
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
            nightReport: makeFixture().nightReport,
            healthMetricSamples: samples,
            template: .healthSummary,
            privacyLevel: .standard,
            calendar: calendar
        )
        let combinedCopy = ([content.summaryText, content.referenceText] + content.keyMetrics.flatMap {
            [$0.title, $0.value, $0.subtitle]
        }).joined(separator: " ")
        let restrictedTerms = [
            "고혈압" + "입니다",
            "비만" + "입니다",
            "수면" + "무호흡증 가능성이 " + "높습니다",
            "치료" + "가 필요합니다",
            "코골기" + " 때문에 " + "혈압",
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

    private func makeFixture() -> DailyHealthCardFixture {
        let samples = MockHealthDataService.makeDefaultSamples(
            referenceDate: referenceDate,
            calendar: calendar
        )
        let nightReport = NightReport(
            sessionId: UUID(),
            generatedAt: calendar.startOfDay(for: referenceDate).addingTimeInterval(8 * 60 * 60),
            measurementDuration: 8 * 60 * 60,
            estimatedSleepDuration: 7 * 60 * 60,
            receivedAudioDuration: 8 * 60 * 60,
            analyzedAudioDuration: 8 * 60 * 60,
            audioCoverageRatio: 0.96,
            sleepSoundScore: 86,
            snoreTotalSeconds: 12 * 60,
            snoreRatio: 0.03,
            bruxismLikeCount: 0,
            suspectedPauseCount: 0,
            gaspLikeCount: 0,
            coughLikeCount: 1,
            sleepTalkLikeCount: 0,
            environmentalNoiseCount: 1,
            awakeningSuspectedCount: 1,
            longestSuspectedPause: 0,
            mostDisturbedHourRange: nil,
            mainDisturbanceReason: "수면 소리 기록"
        )

        return DailyHealthCardFixture(nightReport: nightReport, samples: samples)
    }

    private struct DailyHealthCardFixture {
        var nightReport: NightReport
        var samples: [HealthMetricSample]
    }

    private func sourceContents(_ relativePath: String) throws -> String {
        let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        return try String(contentsOf: root.appendingPathComponent(relativePath), encoding: .utf8)
    }
}
