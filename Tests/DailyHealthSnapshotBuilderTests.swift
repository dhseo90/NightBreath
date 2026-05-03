import Foundation
import Testing
@testable import SleepSoundCore

@Suite("DailyHealthSnapshotBuilder")
struct DailyHealthSnapshotBuilderTests {
    @Test
    func builderCombinesReportsCheckInsHealthSamplesAndLifestyleTags() async throws {
        let service = makeService()
        let daySamples = await service.fetchSamplesForDay(referenceDate, calendar: calendar)
        let outsideSample = sampleOutsideSelectedDay()
        let report = makeNightReport()
        let morningCheckIn = makeMorningCheckIn(sessionId: report.id)
        let eveningCheckIn = makeEveningCheckIn()
        let builder = DailyHealthSnapshotBuilder(calendar: calendar)

        let snapshot = builder.build(
            id: UUID(uuidString: "50000000-0000-0000-0000-000000000001")!,
            date: referenceDate,
            sleepReport: report,
            morningCheckIn: morningCheckIn,
            eveningCheckIn: eveningCheckIn,
            healthMetricSamples: daySamples + [outsideSample],
            lifestyleTags: [.stress, .exercise],
            createdAt: dayStart.addingTimeInterval(9 * hour),
            updatedAt: dayStart.addingTimeInterval(21 * hour)
        )

        #expect(snapshot.date == dayStart)
        #expect(snapshot.sleepReportId == report.id)
        #expect(snapshot.morningCheckInId == morningCheckIn.id)
        #expect(snapshot.eveningCheckInId == eveningCheckIn.id)
        #expect(snapshot.healthMetricSampleIds == daySamples.sortedByMeasuredAtAscending().map(\.id))
        #expect(!snapshot.healthMetricSampleIds.contains(outsideSample.id))
        #expect(snapshot.lifestyleTags == [.stress, .exercise, .caffeine])
        #expect(snapshot.dataCompletenessScore == 1)
        #expect(snapshot.dataQuality == .excellent)
    }

    @Test
    func builderFiltersSamplesToSelectedCalendarDay() async {
        let service = makeService()
        let samples = await service.fetchSamplesForDay(referenceDate, calendar: calendar)
        let nextDaySample = HealthMetricSample(
            id: UUID(uuidString: "50000000-0000-0000-0000-000000000010")!,
            metricType: .stepCount,
            value: 6_800,
            unit: HealthMetricType.stepCount.unitLabel,
            measuredAt: dayStart.addingTimeInterval(25 * hour),
            sourceName: "Apple Health Mock",
            sourceBundleIdentifier: "com.apple.Health.mock"
        )
        let builder = DailyHealthSnapshotBuilder(calendar: calendar)

        let snapshot = builder.build(
            date: referenceDate,
            healthMetricSamples: samples + [nextDaySample]
        )

        #expect(snapshot.healthMetricSampleIds.count == HealthMetricType.dailyRhythmMockMetrics.count)
        #expect(!snapshot.healthMetricSampleIds.contains(nextDaySample.id))
    }

    @Test
    func builderScoresSparseDataAsInsufficient() {
        let bodyMassSample = HealthMetricSample(
            id: UUID(uuidString: "50000000-0000-0000-0000-000000000020")!,
            metricType: .bodyMass,
            value: 72.1,
            unit: HealthMetricType.bodyMass.unitLabel,
            measuredAt: dayStart.addingTimeInterval(7 * hour),
            sourceName: "Fitdays",
            sourceBundleIdentifier: "com.fitdays.app"
        )
        let builder = DailyHealthSnapshotBuilder(calendar: calendar)

        let snapshot = builder.build(
            date: referenceDate,
            healthMetricSamples: [bodyMassSample]
        )

        #expect(snapshot.dataCompletenessScore < 0.2)
        #expect(snapshot.dataQuality == .insufficient)
    }

    private var referenceDate: Date {
        Date(timeIntervalSince1970: 1_777_680_000)
    }

    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }

    private var dayStart: Date {
        calendar.startOfDay(for: referenceDate)
    }

    private var hour: TimeInterval {
        60 * 60
    }

    private func makeService() -> MockHealthDataService {
        MockHealthDataService(
            samples: MockHealthDataService.makeDefaultSamples(
                referenceDate: referenceDate,
                calendar: calendar
            )
        )
    }

    private func makeNightReport() -> NightReport {
        NightReport(
            sessionId: UUID(uuidString: "50000000-0000-0000-0000-000000000101")!,
            generatedAt: dayStart.addingTimeInterval(8 * hour),
            measurementDuration: 8 * hour,
            estimatedSleepDuration: 7 * hour,
            sleepSoundScore: 86,
            snoreTotalSeconds: 240,
            snoreRatio: 0.01,
            bruxismLikeCount: 0,
            suspectedPauseCount: 0,
            gaspLikeCount: 0,
            coughLikeCount: 1,
            sleepTalkLikeCount: 0,
            environmentalNoiseCount: 2,
            awakeningSuspectedCount: 1,
            longestSuspectedPause: 0,
            mostDisturbedHourRange: nil,
            mainDisturbanceReason: "수면 소리 리포트"
        )
    }

    private func makeMorningCheckIn(sessionId: UUID) -> MorningCheckIn {
        MorningCheckIn(
            id: UUID(uuidString: "50000000-0000-0000-0000-000000000102")!,
            sessionId: sessionId,
            refreshScore: 4,
            fatigueScore: 2,
            memo: "아침 컨디션 기록",
            createdAt: dayStart.addingTimeInterval(8 * hour)
        )
    }

    private func makeEveningCheckIn() -> EveningCheckIn {
        EveningCheckIn(
            id: UUID(uuidString: "50000000-0000-0000-0000-000000000103")!,
            date: referenceDate,
            fatigueScore: 3,
            stressScore: 2,
            caffeine: true,
            exercise: true,
            createdAt: dayStart.addingTimeInterval(21 * hour)
        )
    }

    private func sampleOutsideSelectedDay() -> HealthMetricSample {
        HealthMetricSample(
            id: UUID(uuidString: "50000000-0000-0000-0000-000000000104")!,
            metricType: .bodyMass,
            value: 72.5,
            unit: HealthMetricType.bodyMass.unitLabel,
            measuredAt: dayStart.addingTimeInterval(-hour),
            sourceName: "Fitdays",
            sourceBundleIdentifier: "com.fitdays.app"
        )
    }
}
