import Foundation

struct DailyRhythmMockBundle {
  var date: Date
  var nightReport: NightReport?
  var morningCheckIn: MorningCheckIn?
  var eveningCheckIn: EveningCheckIn?
  var healthSamples: [HealthMetricSample]
  var snapshot: DailyHealthSnapshot
  var report: DailyRhythmReport
  var cardContent: DailyHealthCardContent

  func latestSample(_ metricType: HealthMetricType) -> HealthMetricSample? {
    healthSamples.latestSample(metricType: metricType)
  }
}

enum DailyRhythmMockFactory {
  static func makeBundle(
    referenceDate: Date = Date(),
    nightReport: NightReport? = nil,
    morningCheckIn: MorningCheckIn? = nil,
    eveningCheckIn: EveningCheckIn? = nil,
    calendar: Calendar = .current
  ) -> DailyRhythmMockBundle {
    let daySamples = MockHealthDataService
      .makeDefaultSamples(referenceDate: referenceDate, calendar: calendar)
      .filter { calendar.isDate($0.measuredAt, inSameDayAs: referenceDate) }
      .sortedByMeasuredAtAscending()
    let snapshot = DailyHealthSnapshotBuilder(calendar: calendar).build(
      date: referenceDate,
      sleepReport: nightReport,
      morningCheckIn: morningCheckIn,
      eveningCheckIn: eveningCheckIn,
      healthMetricSamples: daySamples,
      createdAt: referenceDate
    )
    let report = DailyRhythmReportBuilder(calendar: calendar).build(
      snapshot: snapshot,
      nightReport: nightReport,
      morningCheckIn: morningCheckIn,
      eveningCheckIn: eveningCheckIn,
      healthMetricSamples: daySamples,
      createdAt: referenceDate
    )
    let cardContent = DailyHealthCardContent.make(
      date: referenceDate,
      report: report,
      nightReport: nightReport,
      healthMetricSamples: daySamples,
      template: .healthSummary,
      privacyLevel: .standard,
      calendar: calendar
    )

    return DailyRhythmMockBundle(
      date: referenceDate,
      nightReport: nightReport,
      morningCheckIn: morningCheckIn,
      eveningCheckIn: eveningCheckIn,
      healthSamples: daySamples,
      snapshot: snapshot,
      report: report,
      cardContent: cardContent
    )
  }

  static func makePreviewBundle(referenceDate: Date = Date()) -> DailyRhythmMockBundle {
    let sample = MockSleepDataFactory.latestBundle(now: referenceDate)
    let eveningCheckIn = EveningCheckIn(
      date: referenceDate,
      fatigueScore: 3,
      stressScore: 2,
      moodScore: 4,
      caffeine: true,
      exercise: true,
      memo: "저녁 산책 후 비교적 차분한 하루"
    )

    return makeBundle(
      referenceDate: referenceDate,
      nightReport: sample.2,
      morningCheckIn: sample.3,
      eveningCheckIn: eveningCheckIn
    )
  }
}
