import Foundation

public enum MockDailyRhythmData {
    public static let referenceDate = Date(timeIntervalSince1970: 1_777_680_000)

    private static let day: TimeInterval = 24 * 60 * 60
    private static let sleepReportID = UUID(uuidString: "10000000-0000-0000-0000-000000000001")!
    private static let morningCheckInID = UUID(uuidString: "10000000-0000-0000-0000-000000000002")!
    private static let eveningCheckInID = UUID(uuidString: "10000000-0000-0000-0000-000000000003")!
    private static let bodyMassSampleID = UUID(uuidString: "10000000-0000-0000-0000-000000000101")!
    private static let systolicSampleID = UUID(uuidString: "10000000-0000-0000-0000-000000000102")!
    private static let diastolicSampleID = UUID(uuidString: "10000000-0000-0000-0000-000000000103")!

    public static var sampleEveningCheckIn: EveningCheckIn {
        EveningCheckIn(
            id: eveningCheckInID,
            date: referenceDate,
            fatigueScore: 3,
            stressScore: 2,
            moodScore: 4,
            caffeine: true,
            alcohol: false,
            lateMeal: false,
            exercise: true,
            nap: false,
            memo: "저녁 산책 후 비교적 차분한 하루",
            createdAt: referenceDate.addingTimeInterval(20 * 60 * 60)
        )
    }

    public static var sampleHealthMetricSamples: [HealthMetricSample] {
        [
            HealthMetricSample(
                id: systolicSampleID,
                metricType: .systolicBloodPressure,
                value: 118,
                unit: HealthMetricType.systolicBloodPressure.unitLabel,
                measuredAt: referenceDate.addingTimeInterval(8 * 60 * 60),
                sourceName: "Omron Connect",
                sourceBundleIdentifier: "com.omronhealthcare.omronconnect"
            ),
            HealthMetricSample(
                id: diastolicSampleID,
                metricType: .diastolicBloodPressure,
                value: 76,
                unit: HealthMetricType.diastolicBloodPressure.unitLabel,
                measuredAt: referenceDate.addingTimeInterval(8 * 60 * 60 + 60),
                sourceName: "Omron Connect",
                sourceBundleIdentifier: "com.omronhealthcare.omronconnect"
            ),
            HealthMetricSample(
                id: bodyMassSampleID,
                metricType: .bodyMass,
                value: 72.1,
                unit: HealthMetricType.bodyMass.unitLabel,
                measuredAt: referenceDate.addingTimeInterval(7 * 60 * 60),
                sourceName: "Fitdays",
                sourceBundleIdentifier: "com.fitdays.app"
            ),
        ]
    }

    public static var sampleSnapshot: DailyHealthSnapshot {
        DailyHealthSnapshot(
            id: UUID(uuidString: "10000000-0000-0000-0000-000000000010")!,
            date: referenceDate,
            sleepReportId: sleepReportID,
            morningCheckInId: morningCheckInID,
            eveningCheckInId: eveningCheckInID,
            healthMetricSampleIds: sampleHealthMetricSamples.map(\.id),
            lifestyleTags: sampleEveningCheckIn.lifestyleTags,
            dataCompletenessScore: 0.82,
            createdAt: referenceDate.addingTimeInterval(9 * 60 * 60),
            updatedAt: referenceDate.addingTimeInterval(21 * 60 * 60)
        )
    }

    public static var sampleScore: DailyRhythmScore {
        DailyRhythmScore(
            totalScore: 84,
            sleepComponent: 86,
            recoveryComponent: 82,
            activityComponent: 80,
            bloodPressureComponent: 85,
            bodyMetricComponent: 83,
            dataCompleteness: sampleSnapshot.dataCompletenessScore,
            computedAt: referenceDate.addingTimeInterval(21 * 60 * 60)
        )
    }

    public static var sampleInsights: [DailyInsight] {
        [
            DailyInsight(
                id: UUID(uuidString: "10000000-0000-0000-0000-000000000201")!,
                type: .sleep,
                severity: .neutral,
                title: "수면 소리와 아침 기록",
                message: "지난밤 수면 소리 리포트와 아침 컨디션을 같은 날짜에서 함께 볼 수 있습니다.",
                createdAt: referenceDate.addingTimeInterval(9 * 60 * 60)
            ),
            DailyInsight(
                id: UUID(uuidString: "10000000-0000-0000-0000-000000000202")!,
                type: .lifestyle,
                severity: .positive,
                title: "생활 태그 기록",
                message: "운동과 카페인 기록을 하루 리듬 카드에 참고용으로 표시합니다.",
                relatedLifestyleTags: [.exercise, .caffeine],
                createdAt: referenceDate.addingTimeInterval(21 * 60 * 60)
            ),
            DailyInsight(
                id: UUID(uuidString: "10000000-0000-0000-0000-000000000203")!,
                type: .dataQuality,
                severity: .neutral,
                title: "데이터 품질",
                message: "데이터가 있는 항목만 사용하며, 부족한 항목은 제한적으로 표시합니다.",
                createdAt: referenceDate.addingTimeInterval(21 * 60 * 60)
            ),
        ]
    }

    public static var sampleReport: DailyRhythmReport {
        DailyRhythmReport(
            id: UUID(uuidString: "10000000-0000-0000-0000-000000000020")!,
            date: referenceDate,
            dailyRhythmScore: sampleScore,
            insights: sampleInsights
        )
    }

    public static func healthMetricSamplesForLastThreeDays() -> [HealthMetricSample] {
        sampleHealthMetricSamples + [
            HealthMetricSample(
                metricType: .bodyMass,
                value: 72.4,
                unit: HealthMetricType.bodyMass.unitLabel,
                measuredAt: referenceDate.addingTimeInterval(-day + 7 * 60 * 60),
                sourceName: "Fitdays",
                sourceBundleIdentifier: "com.fitdays.app"
            ),
            HealthMetricSample(
                metricType: .systolicBloodPressure,
                value: 121,
                unit: HealthMetricType.systolicBloodPressure.unitLabel,
                measuredAt: referenceDate.addingTimeInterval(-day + 8 * 60 * 60),
                sourceName: "Omron Connect",
                sourceBundleIdentifier: "com.omronhealthcare.omronconnect"
            ),
        ]
    }
}
