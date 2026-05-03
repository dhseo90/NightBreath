import Foundation

public struct DailyRhythmReport: Identifiable, Codable, Equatable, Sendable {
    public static let defaultCautionText = "개인 패턴을 살펴보기 위한 참고용 보기입니다. 이 앱은 진단 목적의 의료기기가 아닙니다."

    public var id: UUID
    public var date: Date
    public var dailyRhythmScore: DailyRhythmScore
    public var sleepComponentScore: Int
    public var recoveryComponentScore: Int
    public var activityComponentScore: Int
    public var bloodPressureComponentScore: Int
    public var bodyMetricComponentScore: Int
    public var dataQuality: DailyDataQuality
    public var insights: [DailyInsight]
    public var cautionText: String
    public var isMedicalDisclaimerRequired: Bool

    public init(
        id: UUID = UUID(),
        date: Date,
        dailyRhythmScore: DailyRhythmScore,
        sleepComponentScore: Int? = nil,
        recoveryComponentScore: Int? = nil,
        activityComponentScore: Int? = nil,
        bloodPressureComponentScore: Int? = nil,
        bodyMetricComponentScore: Int? = nil,
        dataQuality: DailyDataQuality? = nil,
        insights: [DailyInsight] = [],
        cautionText: String = DailyRhythmReport.defaultCautionText,
        isMedicalDisclaimerRequired: Bool = true
    ) {
        self.id = id
        self.date = date
        self.dailyRhythmScore = dailyRhythmScore
        self.sleepComponentScore = DailyRhythmScore.clampedScore(
            sleepComponentScore ?? dailyRhythmScore.sleepComponent
        )
        self.recoveryComponentScore = DailyRhythmScore.clampedScore(
            recoveryComponentScore ?? dailyRhythmScore.recoveryComponent
        )
        self.activityComponentScore = DailyRhythmScore.clampedScore(
            activityComponentScore ?? dailyRhythmScore.activityComponent
        )
        self.bloodPressureComponentScore = DailyRhythmScore.clampedScore(
            bloodPressureComponentScore ?? dailyRhythmScore.bloodPressureComponent
        )
        self.bodyMetricComponentScore = DailyRhythmScore.clampedScore(
            bodyMetricComponentScore ?? dailyRhythmScore.bodyMetricComponent
        )
        self.dataQuality = dataQuality ?? dailyRhythmScore.dataQuality
        self.insights = insights
        self.cautionText = cautionText
        self.isMedicalDisclaimerRequired = isMedicalDisclaimerRequired
    }
}
