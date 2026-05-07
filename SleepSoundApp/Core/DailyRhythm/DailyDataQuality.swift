import Foundation

public enum DailyDataQuality: String, Codable, CaseIterable, Identifiable, Equatable, Sendable {
    case excellent
    case good
    case limited
    case poor
    case insufficient

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .excellent:
            "매우 충분"
        case .good:
            "충분"
        case .limited:
            "제한적"
        case .poor:
            "부족"
        case .insufficient:
            "매우 부족"
        }
    }

    public static func quality(for completenessScore: Double) -> DailyDataQuality {
        let score = clampedCompleteness(completenessScore)

        switch score {
        case 0.9...1:
            return .excellent
        case 0.7..<0.9:
            return .good
        case 0.45..<0.7:
            return .limited
        case 0.2..<0.45:
            return .poor
        default:
            return .insufficient
        }
    }

    public static func clampedCompleteness(_ value: Double) -> Double {
        guard value.isFinite else { return 0 }
        return min(max(value, 0), 1)
    }
}

public enum DailyRhythmDataReadinessSignal: String, Codable, CaseIterable, Identifiable, Equatable, Sendable {
    case sleepReport
    case morningCheckIn
    case eveningCheckIn
    case bloodPressure
    case bodyMetrics
    case activityAndRecovery

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .sleepReport:
            "수면 리포트"
        case .morningCheckIn:
            "아침 컨디션"
        case .eveningCheckIn:
            "저녁 기록"
        case .bloodPressure:
            "혈압 데이터"
        case .bodyMetrics:
            "체성분 데이터"
        case .activityAndRecovery:
            "활동/회복 데이터"
        }
    }

    var availableDetail: String {
        switch self {
        case .sleepReport:
            "수면 소리 리포트가 연결되었습니다."
        case .morningCheckIn:
            "아침 컨디션 기록이 연결되었습니다."
        case .eveningCheckIn:
            "저녁 컨디션 기록이 연결되었습니다."
        case .bloodPressure:
            "혈압 샘플이 연결되었습니다."
        case .bodyMetrics:
            "체중/체성분 샘플이 연결되었습니다."
        case .activityAndRecovery:
            "활동 또는 회복 관련 샘플이 연결되었습니다."
        }
    }

    var missingDetail: String {
        switch self {
        case .sleepReport:
            "수면 리포트가 생기면 수면 항목을 함께 표시합니다."
        case .morningCheckIn:
            "아침 기록이 없으면 회복 리듬 항목은 제한적으로 표시합니다."
        case .eveningCheckIn:
            "저녁 기록이 없으면 하루 맥락은 제한적으로 표시합니다."
        case .bloodPressure:
            "혈압 샘플이 없으면 해당 항목은 데이터 없음으로 표시합니다."
        case .bodyMetrics:
            "체중/체성분 샘플이 없으면 해당 항목은 데이터 없음으로 표시합니다."
        case .activityAndRecovery:
            "활동 또는 회복 관련 샘플이 없으면 일부 구성 점수는 제한적으로 표시합니다."
        }
    }
}

public enum DailyRhythmDataReadinessStatus: String, Codable, Equatable, Sendable {
    case available
    case missing

    public var displayName: String {
        switch self {
        case .available:
            "준비됨"
        case .missing:
            "제한"
        }
    }
}

public struct DailyRhythmDataReadinessItem: Identifiable, Codable, Equatable, Sendable {
    public var id: DailyRhythmDataReadinessSignal { signal }
    public var signal: DailyRhythmDataReadinessSignal
    public var status: DailyRhythmDataReadinessStatus
    public var title: String
    public var detail: String

    public init(
        signal: DailyRhythmDataReadinessSignal,
        status: DailyRhythmDataReadinessStatus,
        title: String? = nil,
        detail: String? = nil
    ) {
        self.signal = signal
        self.status = status
        self.title = title ?? signal.displayName
        self.detail = detail ?? (status == .available ? signal.availableDetail : signal.missingDetail)
    }
}

public struct DailyRhythmDataReadinessSummary: Codable, Equatable, Sendable {
    public var quality: DailyDataQuality
    public var completenessScore: Double
    public var availableItems: [DailyRhythmDataReadinessItem]
    public var missingItems: [DailyRhythmDataReadinessItem]

    public init(
        quality: DailyDataQuality,
        completenessScore: Double,
        availableItems: [DailyRhythmDataReadinessItem],
        missingItems: [DailyRhythmDataReadinessItem]
    ) {
        self.quality = quality
        self.completenessScore = DailyDataQuality.clampedCompleteness(completenessScore)
        self.availableItems = availableItems
        self.missingItems = missingItems
    }

    public var includedSignalCount: Int {
        availableItems.count
    }

    public var missingSignalCount: Int {
        missingItems.count
    }

    public var completenessPercentText: String {
        "\(Int((completenessScore * 100).rounded()))%"
    }

    public var availableText: String {
        itemText(availableItems, fallback: "아직 준비된 항목 없음")
    }

    public var missingText: String {
        itemText(missingItems, fallback: "제한 항목 없음")
    }

    public var title: String {
        switch quality {
        case .excellent, .good:
            "오늘 리듬 데이터가 충분합니다"
        case .limited:
            "일부 데이터로 리듬을 정리했습니다"
        case .poor, .insufficient:
            "데이터가 적어 참고 범위가 제한됩니다"
        }
    }

    public var message: String {
        switch quality {
        case .excellent, .good:
            "사용 가능한 항목을 기준으로 오늘 리듬을 정리했습니다."
        case .limited:
            "비어 있는 항목은 데이터 없음으로 두고, 준비된 항목만 참고용으로 표시합니다."
        case .poor, .insufficient:
            "점수보다 어떤 데이터가 있는지 먼저 확인하는 상태입니다."
        }
    }

    public static func make(
        snapshot: DailyHealthSnapshot,
        nightReport: NightReport? = nil,
        morningCheckIn: MorningCheckIn? = nil,
        eveningCheckIn: EveningCheckIn? = nil,
        healthMetricSamples: [HealthMetricSample] = []
    ) -> DailyRhythmDataReadinessSummary {
        let sampleIDs = Set(snapshot.healthMetricSampleIds)
        let scopedSamples = healthMetricSamples.filter { sampleIDs.isEmpty || sampleIDs.contains($0.id) }
        let availableSignals = Set(
            DailyRhythmDataReadinessSignal.allCases.filter { signal in
                isAvailable(
                    signal,
                    snapshot: snapshot,
                    nightReport: nightReport,
                    morningCheckIn: morningCheckIn,
                    eveningCheckIn: eveningCheckIn,
                    healthMetricSamples: scopedSamples
                )
            }
        )
        let availableItems = DailyRhythmDataReadinessSignal.allCases
            .filter { availableSignals.contains($0) }
            .map { DailyRhythmDataReadinessItem(signal: $0, status: .available) }
        let missingItems = DailyRhythmDataReadinessSignal.allCases
            .filter { !availableSignals.contains($0) }
            .map { DailyRhythmDataReadinessItem(signal: $0, status: .missing) }

        return DailyRhythmDataReadinessSummary(
            quality: snapshot.dataQuality,
            completenessScore: snapshot.dataCompletenessScore,
            availableItems: availableItems,
            missingItems: missingItems
        )
    }

    private static func isAvailable(
        _ signal: DailyRhythmDataReadinessSignal,
        snapshot: DailyHealthSnapshot,
        nightReport: NightReport?,
        morningCheckIn: MorningCheckIn?,
        eveningCheckIn: EveningCheckIn?,
        healthMetricSamples: [HealthMetricSample]
    ) -> Bool {
        switch signal {
        case .sleepReport:
            nightReport != nil || snapshot.sleepReportId != nil
        case .morningCheckIn:
            morningCheckIn != nil || snapshot.morningCheckInId != nil
        case .eveningCheckIn:
            eveningCheckIn != nil || snapshot.eveningCheckInId != nil
        case .bloodPressure:
            hasSample(in: healthMetricSamples, matching: bloodPressureMetrics)
        case .bodyMetrics:
            hasSample(in: healthMetricSamples, matching: bodyMetricMetrics)
        case .activityAndRecovery:
            hasSample(in: healthMetricSamples, matching: activityAndRecoveryMetrics)
        }
    }

    private static func hasSample(
        in samples: [HealthMetricSample],
        matching metricTypes: Set<HealthMetricType>
    ) -> Bool {
        samples.contains { metricTypes.contains($0.metricType) }
    }

    private func itemText(
        _ items: [DailyRhythmDataReadinessItem],
        fallback: String
    ) -> String {
        guard !items.isEmpty else { return fallback }
        return items.map(\.title).joined(separator: " · ")
    }

    private static let bloodPressureMetrics: Set<HealthMetricType> = [
        .systolicBloodPressure,
        .diastolicBloodPressure,
    ]

    private static let bodyMetricMetrics: Set<HealthMetricType> = [
        .bodyMass,
        .bodyFatPercentage,
        .bodyMassIndex,
        .leanBodyMass,
    ]

    private static let activityAndRecoveryMetrics: Set<HealthMetricType> = [
        .stepCount,
        .activeEnergy,
        .heartRate,
        .restingHeartRate,
        .sleepDuration,
        .respiratoryRate,
    ]
}
