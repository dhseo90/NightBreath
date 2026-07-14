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
    func dayGroupingDoesNotLeakAdjacentDaySamples() {
        let targetStart = date(2026, 5, 3, hour: 0)
        let samples = [
            sample(.bodyWaterPercentage, 56.6, targetStart.addingTimeInterval(-1), sourceType: .fitdaysCSV, sourceName: "Previous Synthetic CSV"),
            sample(.bodyWaterPercentage, 56.8, targetStart.addingTimeInterval(23 * 60 * 60 + 59 * 60), sourceType: .fitdaysCSV, sourceName: "Fitdays CSV Import"),
            sample(.bodyMass, 71.6, targetStart.addingTimeInterval(24 * 60 * 60), sourceType: .healthKit, sourceName: "Apple 건강앱"),
        ]

        let summary = builder.summary(
            for: targetStart,
            samples: samples,
            sleepReports: [],
            calendar: calendar
        )

        #expect(summary.sampleCount == 1)
        #expect(summary.hasBodyComposition)
        #expect(!summary.hasBloodPressure)
        #expect(summary.sourceTypes == [.fitdaysCSV])
    }

    @Test
    func cumulativeActivitySamplesCountAsOneVisibleMetricPerDay() {
        let targetDate = date(2026, 5, 3)
        let samples = [
            sample(.stepCount, 1_200, targetDate, sourceType: .healthKit, sourceName: "Apple 건강앱"),
            sample(.stepCount, 2_300, targetDate.addingTimeInterval(60), sourceType: .healthKit, sourceName: "Apple 건강앱"),
            sample(.activeEnergy, 120, targetDate.addingTimeInterval(120), sourceType: .healthKit, sourceName: "Apple 건강앱"),
            sample(.activeEnergy, 180, targetDate.addingTimeInterval(180), sourceType: .healthKit, sourceName: "Apple 건강앱"),
            sample(.bodyMass, 71.6, targetDate.addingTimeInterval(240), sourceType: .healthKit, sourceName: "Apple 건강앱"),
        ]

        let summary = builder.summary(
            for: targetDate,
            samples: samples,
            sleepReports: [],
            calendar: calendar
        )

        #expect(summary.sampleCount == 3)
        #expect(summary.hasActivity)
        #expect(summary.hasBodyComposition)
        #expect(summary.sourceTypes == [.healthKit])
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
    func checkInOnlyDayStillCountsAsDataWithoutMetricSamples() {
        let targetDate = date(2026, 5, 11)
        let summary = builder.summary(
            for: targetDate,
            samples: [],
            sleepReports: [],
            morningCheckIns: [
                MorningCheckIn(sessionId: UUID(), createdAt: targetDate.addingTimeInterval(60 * 60)),
            ],
            eveningCheckIns: [
                EveningCheckIn(date: targetDate.addingTimeInterval(12 * 60 * 60)),
            ],
            calendar: calendar
        )

        #expect(summary.hasAnyData)
        #expect(!summary.hasSleepReport)
        #expect(summary.hasMorningCheckIn)
        #expect(summary.hasEveningCheckIn)
        #expect(summary.sampleCount == 0)
        #expect(summary.sourceTypes.isEmpty)
        #expect(summary.dataQuality == .poor)
    }

    @Test
    func reportLinkedMorningCheckInStaysWithReportDayEvenWhenCreatedAfterMidnight() throws {
        let reportDay = date(2026, 5, 3)
        let nextDay = date(2026, 5, 4)
        let sessionID = UUID(uuidString: "44000000-0000-0000-0000-000000000001")!
        let linkedCheckIn = MorningCheckIn(
            sessionId: sessionID,
            refreshScore: 4,
            createdAt: nextDay.addingTimeInterval(60 * 60)
        )

        let detail = builder.detailData(
            for: reportDay,
            samples: [],
            sleepReports: [report(sessionID: sessionID, generatedAt: reportDay)],
            morningCheckIns: [linkedCheckIn],
            calendar: calendar
        )

        #expect(detail.summary.hasSleepReport)
        #expect(detail.summary.hasMorningCheckIn)
        #expect(detail.morningCheckIns.map { $0.sessionId } == [sessionID])
        #expect(detail.morningCheckIns.first?.createdAt == linkedCheckIn.createdAt)
    }

    @Test
    func detailAggregatesMultipleSleepReportsIntoOneDailySleepSummary() throws {
        let reportDay = date(2026, 5, 3)
        let firstSessionID = UUID(uuidString: "44000000-0000-0000-0000-000000000101")!
        let secondSessionID = UUID(uuidString: "44000000-0000-0000-0000-000000000102")!
        let firstReport = report(
            sessionID: firstSessionID,
            generatedAt: reportDay.addingTimeInterval(60 * 60),
            measurementDuration: 60,
            estimatedSleepDuration: 60,
            receivedAudioDuration: 60,
            sleepSoundScore: 80,
            snoreTotalSeconds: 12,
            bruxismLikeCount: 1,
            suspectedPauseCount: 0
        )
        let secondReport = report(
            sessionID: secondSessionID,
            generatedAt: reportDay.addingTimeInterval(2 * 60 * 60),
            measurementDuration: 180,
            estimatedSleepDuration: 180,
            receivedAudioDuration: 120,
            sleepSoundScore: 60,
            snoreTotalSeconds: 18,
            bruxismLikeCount: 2,
            suspectedPauseCount: 1
        )

        let detail = builder.detailData(
            for: reportDay,
            samples: [],
            sleepReports: [secondReport, firstReport],
            calendar: calendar
        )
        let summary = try #require(detail.sleepSummary)

        #expect(detail.sleepReports.count == 2)
        #expect(summary.reportCount == 2)
        #expect(summary.measurementDuration == 240)
        #expect(summary.estimatedSleepDuration == 240)
        #expect(summary.receivedAudioDuration == 180)
        #expect(abs(summary.audioCoverageRatio - 0.75) < 0.0001)
        #expect(summary.measurementQuality == .limited)
        #expect(summary.sleepSoundScore == 65)
        #expect(summary.snoreTotalSeconds == 30)
        #expect(abs(summary.snoreRatio - 0.125) < 0.0001)
        #expect(summary.bruxismLikeCount == 3)
        #expect(summary.suspectedPauseCount == 1)
        #expect(summary.mainDisturbanceReason == "2개 수면 기록을 하루 단위로 합산했습니다.")
    }

    @Test
    func excellentQualityRequiresAllMajorCategoriesAndEnoughSamples() {
        let targetDate = date(2026, 5, 3)
        let sessionID = UUID(uuidString: "44000000-0000-0000-0000-000000000002")!
        let samples = [
            sample(.systolicBloodPressure, 118, targetDate, sourceType: .healthKit, sourceName: "Omron Connect"),
            sample(.diastolicBloodPressure, 76, targetDate, sourceType: .healthKit, sourceName: "Omron Connect"),
            sample(.bodyMass, 71.6, targetDate, sourceType: .healthKit, sourceName: "Apple 건강앱"),
            sample(.bodyMassIndex, 23.1, targetDate, sourceType: .healthKit, sourceName: "Apple 건강앱"),
            sample(.bodyWaterPercentage, 56.8, targetDate, sourceType: .fitdaysCSV, sourceName: "Fitdays CSV Import"),
            sample(.stepCount, 6_400, targetDate, sourceType: .healthKit, sourceName: "Apple 건강앱"),
            sample(.activeEnergy, 310, targetDate, sourceType: .healthKit, sourceName: "Apple 건강앱"),
            sample(.dailyRhythmScore, 84, targetDate, sourceType: .appComputed, sourceName: "밤숨 앱"),
        ]

        let summary = builder.summary(
            for: targetDate,
            samples: samples,
            sleepReports: [report(sessionID: sessionID, generatedAt: targetDate)],
            morningCheckIns: [MorningCheckIn(sessionId: sessionID, createdAt: targetDate)],
            calendar: calendar
        )

        #expect(summary.sampleCount == 8)
        #expect(summary.hasSleepReport)
        #expect(summary.hasBloodPressure)
        #expect(summary.hasBodyComposition)
        #expect(summary.hasActivity)
        #expect(summary.hasMorningCheckIn)
        #expect(summary.dataQuality == .excellent)
    }

    @Test
    func largeImportedDatasetMonthAndDetailBuildStayResponsive() {
        let monthDate = date(2026, 5, 15)
        let metricIDs: [UnifiedHealthMetricID] = [
            .systolicBloodPressure,
            .diastolicBloodPressure,
            .bodyMass,
            .bodyMassIndex,
            .bodyFatPercentage,
            .bodyWaterPercentage,
            .skeletalMuscleMass,
            .basalMetabolicRate,
            .stepCount,
            .sleepSoundScore,
        ]
        var samples: [UnifiedHealthMetricSample] = []
        samples.reserveCapacity(365 * metricIDs.count)
        for dayOffset in 0..<365 {
            for (metricIndex, metricID) in metricIDs.enumerated() {
                let sourceType: HealthMetricSourceType = metricIndex.isMultiple(of: 2) ? .fitdaysCSV : .healthKit
                let sourceName = metricIndex.isMultiple(of: 2) ? "Synthetic Fitdays CSV" : "Synthetic HealthKit"
                let measuredAt = monthDate.addingTimeInterval(
                    Double(dayOffset - 220) * 24 * 60 * 60 + Double(metricIndex) * 60
                )
                samples.append(sample(
                    metricID,
                    60 + Double((dayOffset + metricIndex) % 40),
                    measuredAt,
                    sourceType: sourceType,
                    sourceName: sourceName
                ))
            }
        }
        let reports = (0..<120).map { offset in
            report(sessionID: UUID(), generatedAt: monthDate.addingTimeInterval(Double(offset - 80) * 24 * 60 * 60))
        }

        let startedAt = Date()
        let summaries = builder.summaries(
            forMonthContaining: monthDate,
            samples: samples,
            sleepReports: reports,
            calendar: calendar
        )
        let detail = builder.detailData(
            for: monthDate,
            samples: samples,
            sleepReports: reports,
            calendar: calendar
        )
        let elapsed = Date().timeIntervalSince(startedAt)

        #expect(summaries.count == 42)
        #expect(!detail.samples.isEmpty)
        #expect(elapsed < 1.5, "Large synthetic calendar build took \(elapsed)s")
    }

    @Test
    func calendarViewCombinesCalendarWithMetricSummaryAndDetail() throws {
        let contents = try sourceContents("SleepSoundApp/Features/Dashboard/HealthCalendarView.swift")

        #expect(contents.contains(".navigationTitle(\"캘린더 지표 종합\")"))
        #expect(contents.contains("selectedDateSummarySection"))
        #expect(contents.contains("selectedDateSummarySection\n        monthNavigator\n        calendarSection\n        selectedDateDetailSection"))
        #expect(contents.contains("CalendarMetricSummaryTile"))
        #expect(contents.contains("전체 지표 그래프"))
        #expect(contents.contains("HealthMetricsOverviewView("))
        #expect(contents.contains("headerTitle: \"선택일 지표 종합\""))
        #expect(contents.contains(".onAppear(perform: selectDataDateIfCurrentSelectionIsEmpty)"))
        #expect(contents.contains(".onChange(of: dataAvailabilitySignature)"))
        #expect(contents.contains("preferredDataDate(in: displayedMonth"))
        #expect(contents.contains("selectDate(date)"))
        #expect(contents.contains("let dates = monthDates"))
        #expect(contents.contains("let summaries = summariesByDay"))
        #expect(contents.contains(".frame(height: 48)"))
        #expect(!contents.contains("selectedDatePanel"))
        #expect(!contents.contains("CalendarDaySourceDotStrip"))
        #expect(!contents.contains("CalendarSelectedSourceStrip"))
        #expect(!contents.contains("출처 dot"))
        #expect(!contents.contains("selectedDateInlineDetail"))
        #expect(!contents.contains("CalendarInlineSummaryPill"))
        #expect(contents.contains("CalendarSelectedDateSummaryCard("))
        #expect(contents.contains("DailyMeasurementDetailContent("))
        #expect(contents.contains("detailData.sleepSummary"))
        #expect(contents.contains("개 수면 기록을 하루 단위로 합산"))
        #expect(!contents.contains("ForEach(detailData.sleepReports)"))
        #expect(contents.contains(".nbAvoidFloatingTabBar()"))
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

    private func report(
        sessionID: UUID,
        generatedAt: Date,
        measurementDuration: TimeInterval = 8 * 60 * 60,
        estimatedSleepDuration: TimeInterval = 7.2 * 60 * 60,
        receivedAudioDuration: TimeInterval? = nil,
        sleepSoundScore: Int = 82,
        snoreTotalSeconds: TimeInterval = 18 * 60,
        bruxismLikeCount: Int = 2,
        suspectedPauseCount: Int = 1
    ) -> NightReport {
        NightReport(
            sessionId: sessionID,
            generatedAt: generatedAt,
            measurementDuration: measurementDuration,
            estimatedSleepDuration: estimatedSleepDuration,
            receivedAudioDuration: receivedAudioDuration ?? measurementDuration * 0.94,
            sleepSoundScore: sleepSoundScore,
            snoreTotalSeconds: snoreTotalSeconds,
            snoreRatio: max(estimatedSleepDuration, 1) > 0 ? min(max(snoreTotalSeconds / max(estimatedSleepDuration, 1), 0), 1) : 0,
            bruxismLikeCount: bruxismLikeCount,
            suspectedPauseCount: suspectedPauseCount,
            gaspLikeCount: 0,
            coughLikeCount: 1,
            sleepTalkLikeCount: 0,
            environmentalNoiseCount: 3,
            awakeningSuspectedCount: 1,
            longestSuspectedPause: 8,
            mostDisturbedHourRange: nil,
            mainDisturbanceReason: "수면 소리 지표가 기록되었습니다."
        )
    }

    private func sourceContents(_ relativePath: String) throws -> String {
        let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        return try String(contentsOf: root.appendingPathComponent(relativePath), encoding: .utf8)
    }
}
