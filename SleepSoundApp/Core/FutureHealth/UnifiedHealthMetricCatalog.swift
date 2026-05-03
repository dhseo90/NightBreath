import Foundation

public enum UnifiedHealthMetricID: String, Codable, CaseIterable, Identifiable, Sendable {
    case systolicBloodPressure
    case diastolicBloodPressure
    case bodyMass
    case bodyFatPercentage
    case bodyMassIndex
    case leanBodyMass
    case restingHeartRate
    case heartRate
    case respiratoryRate
    case stepCount
    case activeEnergy
    case sleepDuration

    case visceralFatLevel
    case visceralFatPercentage
    case bodyWaterPercentage
    case boneMass
    case mineralMass
    case skeletalMuscleMass
    case muscleMass
    case basalMetabolicRate
    case proteinPercentage
    case subcutaneousFatPercentage
    case metabolicAge
    case bodyScore
    case obesityLevel

    case sleepSoundScore
    case dailyRhythmScore
    case audioCoverageRatio

    public var id: String { rawValue }

    public init(healthMetricType: HealthMetricType) {
        switch healthMetricType {
        case .systolicBloodPressure:
            self = .systolicBloodPressure
        case .diastolicBloodPressure:
            self = .diastolicBloodPressure
        case .bodyMass:
            self = .bodyMass
        case .bodyFatPercentage:
            self = .bodyFatPercentage
        case .bodyMassIndex:
            self = .bodyMassIndex
        case .leanBodyMass:
            self = .leanBodyMass
        case .stepCount:
            self = .stepCount
        case .activeEnergy:
            self = .activeEnergy
        case .heartRate:
            self = .heartRate
        case .restingHeartRate:
            self = .restingHeartRate
        case .sleepDuration:
            self = .sleepDuration
        case .respiratoryRate:
            self = .respiratoryRate
        }
    }

    public var healthMetricType: HealthMetricType? {
        switch self {
        case .systolicBloodPressure:
            .systolicBloodPressure
        case .diastolicBloodPressure:
            .diastolicBloodPressure
        case .bodyMass:
            .bodyMass
        case .bodyFatPercentage:
            .bodyFatPercentage
        case .bodyMassIndex:
            .bodyMassIndex
        case .leanBodyMass:
            .leanBodyMass
        case .restingHeartRate:
            .restingHeartRate
        case .heartRate:
            .heartRate
        case .respiratoryRate:
            .respiratoryRate
        case .stepCount:
            .stepCount
        case .activeEnergy:
            .activeEnergy
        case .sleepDuration:
            .sleepDuration
        case .visceralFatLevel,
             .visceralFatPercentage,
             .bodyWaterPercentage,
             .boneMass,
             .mineralMass,
             .skeletalMuscleMass,
             .muscleMass,
             .basalMetabolicRate,
             .proteinPercentage,
             .subcutaneousFatPercentage,
             .metabolicAge,
             .bodyScore,
             .obesityLevel,
             .sleepSoundScore,
             .dailyRhythmScore,
             .audioCoverageRatio:
            nil
        }
    }
}

public enum HealthMetricSourceType: String, Codable, CaseIterable, Identifiable, Sendable {
    case healthKit
    case fitdaysCSV
    case manual
    case appComputed
    case mock

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .healthKit:
            "Apple 건강앱"
        case .fitdaysCSV:
            "Fitdays CSV"
        case .manual:
            "수동 입력"
        case .appComputed:
            "앱 계산값"
        case .mock:
            "예시 데이터"
        }
    }
}

public enum MetricCategory: String, Codable, CaseIterable, Identifiable, Sendable {
    case sleep
    case bloodPressure
    case bodyComposition
    case activity
    case recovery
    case app

    public var id: String { rawValue }
}

public struct UnifiedHealthMetricSample: Identifiable, Codable, Equatable, Sendable {
    public var id: UUID
    public var metricID: UnifiedHealthMetricID
    public var value: Double
    public var unit: String
    public var measuredAt: Date
    public var sourceType: HealthMetricSourceType
    public var sourceName: String
    public var sourceBundleIdentifier: String?
    public var externalRecordId: String?
    public var importBatchId: String?
    public var notes: String?
    public var createdAt: Date

    public init(
        id: UUID = UUID(),
        metricID: UnifiedHealthMetricID,
        value: Double,
        unit: String,
        measuredAt: Date,
        sourceType: HealthMetricSourceType,
        sourceName: String,
        sourceBundleIdentifier: String? = nil,
        externalRecordId: String? = nil,
        importBatchId: String? = nil,
        notes: String? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.metricID = metricID
        self.value = value.isFinite ? value : 0
        self.unit = unit
        self.measuredAt = measuredAt
        self.sourceType = sourceType
        self.sourceName = sourceName
        self.sourceBundleIdentifier = sourceBundleIdentifier
        self.externalRecordId = externalRecordId
        self.importBatchId = importBatchId
        self.notes = notes
        self.createdAt = createdAt
    }
}

public struct MetricDisplayMetadata: Identifiable, Codable, Equatable, Sendable {
    public var metricID: UnifiedHealthMetricID
    public var displayNameKo: String
    public var displayNameEn: String
    public var unit: String
    public var category: MetricCategory
    public var isHealthKitBacked: Bool
    public var isExtendedLocalOnly: Bool
    public var description: String
    public var disclaimer: String?

    public var id: UnifiedHealthMetricID { metricID }

    public init(
        metricID: UnifiedHealthMetricID,
        displayNameKo: String,
        displayNameEn: String,
        unit: String,
        category: MetricCategory,
        isHealthKitBacked: Bool,
        isExtendedLocalOnly: Bool,
        description: String,
        disclaimer: String? = nil
    ) {
        self.metricID = metricID
        self.displayNameKo = displayNameKo
        self.displayNameEn = displayNameEn
        self.unit = unit
        self.category = category
        self.isHealthKitBacked = isHealthKitBacked
        self.isExtendedLocalOnly = isExtendedLocalOnly
        self.description = description
        self.disclaimer = disclaimer
    }
}

public struct UnifiedHealthMetricDisplayModel: Identifiable, Equatable, Sendable {
    public var id: UUID { sample.id }
    public var sample: UnifiedHealthMetricSample
    public var metadata: MetricDisplayMetadata
    public var valueText: String
    public var sourceText: String

    public init(
        sample: UnifiedHealthMetricSample,
        metadata: MetricDisplayMetadata,
        valueText: String,
        sourceText: String
    ) {
        self.sample = sample
        self.metadata = metadata
        self.valueText = valueText
        self.sourceText = sourceText
    }
}

public struct MetricCatalog: Equatable, Sendable {
    public static let `default` = MetricCatalog()

    private let metadataByID: [UnifiedHealthMetricID: MetricDisplayMetadata]

    public init(metadata: [MetricDisplayMetadata]? = nil) {
        let metadata = metadata ?? MetricCatalog.defaultMetadata
        self.metadataByID = Dictionary(uniqueKeysWithValues: metadata.map { ($0.metricID, $0) })
    }

    public func allMetrics() -> [MetricDisplayMetadata] {
        UnifiedHealthMetricID.allCases.compactMap { metadataByID[$0] }
    }

    public func metrics(in category: MetricCategory) -> [MetricDisplayMetadata] {
        allMetrics().filter { $0.category == category }
    }

    public func metadata(for metricID: UnifiedHealthMetricID) -> MetricDisplayMetadata? {
        metadataByID[metricID]
    }

    public func isHealthKitBacked(_ metricID: UnifiedHealthMetricID) -> Bool {
        metadata(for: metricID)?.isHealthKitBacked == true
    }

    public func isExtendedLocalOnly(_ metricID: UnifiedHealthMetricID) -> Bool {
        metadata(for: metricID)?.isExtendedLocalOnly == true
    }
}

public enum HealthMetricSampleMapper {
    public static func unifiedSample(
        from sample: HealthMetricSample,
        sourceType: HealthMetricSourceType = .healthKit,
        externalRecordId: String? = nil,
        importBatchId: String? = nil,
        notes: String? = nil,
        createdAt: Date = Date()
    ) -> UnifiedHealthMetricSample {
        UnifiedHealthMetricSample(
            metricID: UnifiedHealthMetricID(healthMetricType: sample.metricType),
            value: sample.value,
            unit: sample.unit,
            measuredAt: sample.measuredAt,
            sourceType: sourceType,
            sourceName: sample.sourceName,
            sourceBundleIdentifier: sample.sourceBundleIdentifier,
            externalRecordId: externalRecordId,
            importBatchId: importBatchId,
            notes: notes,
            createdAt: createdAt
        )
    }

    public static func displayModel(
        from sample: UnifiedHealthMetricSample,
        catalog: MetricCatalog = .default
    ) -> UnifiedHealthMetricDisplayModel? {
        guard let metadata = catalog.metadata(for: sample.metricID) else {
            return nil
        }

        return UnifiedHealthMetricDisplayModel(
            sample: sample,
            metadata: metadata,
            valueText: formatValue(sample.value, unit: sample.unit),
            sourceText: "\(sample.sourceType.displayName) · \(sample.sourceName)"
        )
    }

    private static func formatValue(_ value: Double, unit: String) -> String {
        let rounded = value.rounded()
        let valueText = abs(value - rounded) < 0.05
            ? String(Int(rounded))
            : String(format: "%.1f", value)
        return unit.isEmpty ? valueText : "\(valueText) \(unit)"
    }
}

public extension HealthMetricSample {
    func unifiedSample(
        sourceType: HealthMetricSourceType = .healthKit,
        externalRecordId: String? = nil,
        importBatchId: String? = nil,
        notes: String? = nil,
        createdAt: Date = Date()
    ) -> UnifiedHealthMetricSample {
        HealthMetricSampleMapper.unifiedSample(
            from: self,
            sourceType: sourceType,
            externalRecordId: externalRecordId,
            importBatchId: importBatchId,
            notes: notes,
            createdAt: createdAt
        )
    }
}

public extension UnifiedHealthMetricSample {
    func displayModel(catalog: MetricCatalog = .default) -> UnifiedHealthMetricDisplayModel? {
        HealthMetricSampleMapper.displayModel(from: self, catalog: catalog)
    }
}

private extension MetricCatalog {
    static let defaultMetadata: [MetricDisplayMetadata] = [
        metadata(.systolicBloodPressure, "수축기 혈압", "Systolic Blood Pressure", "mmHg", .bloodPressure, true),
        metadata(.diastolicBloodPressure, "이완기 혈압", "Diastolic Blood Pressure", "mmHg", .bloodPressure, true),
        metadata(.bodyMass, "체중", "Body Mass", "kg", .bodyComposition, true),
        metadata(.bodyFatPercentage, "체지방률", "Body Fat Percentage", "%", .bodyComposition, true),
        metadata(.bodyMassIndex, "BMI", "Body Mass Index", "BMI", .bodyComposition, true),
        metadata(.leanBodyMass, "제지방량", "Lean Body Mass", "kg", .bodyComposition, true),
        metadata(.restingHeartRate, "안정시 심박수", "Resting Heart Rate", "bpm", .recovery, true),
        metadata(.heartRate, "심박수", "Heart Rate", "bpm", .recovery, true),
        metadata(.respiratoryRate, "호흡수", "Respiratory Rate", "회/분", .recovery, true),
        metadata(.stepCount, "걸음 수", "Step Count", "걸음", .activity, true),
        metadata(.activeEnergy, "활동량", "Active Energy", "kcal", .activity, true),
        metadata(.sleepDuration, "수면 시간", "Sleep Duration", "시간", .sleep, false, localOnly: true),

        metadata(.visceralFatLevel, "내장지방 레벨", "Visceral Fat Level", "레벨", .bodyComposition, false, localOnly: true),
        metadata(.visceralFatPercentage, "복부지방률", "Visceral Fat Percentage", "%", .bodyComposition, false, localOnly: true),
        metadata(.bodyWaterPercentage, "체수분", "Body Water Percentage", "%", .bodyComposition, false, localOnly: true),
        metadata(.boneMass, "골량", "Bone Mass", "kg", .bodyComposition, false, localOnly: true),
        metadata(.mineralMass, "무기질", "Mineral Mass", "kg", .bodyComposition, false, localOnly: true),
        metadata(.skeletalMuscleMass, "골격근량", "Skeletal Muscle Mass", "kg", .bodyComposition, false, localOnly: true),
        metadata(.muscleMass, "근육량", "Muscle Mass", "kg", .bodyComposition, false, localOnly: true),
        metadata(.basalMetabolicRate, "기초대사량", "Basal Metabolic Rate", "kcal/day", .recovery, false, localOnly: true),
        metadata(.proteinPercentage, "단백질률", "Protein Percentage", "%", .bodyComposition, false, localOnly: true),
        metadata(.subcutaneousFatPercentage, "피하지방률", "Subcutaneous Fat Percentage", "%", .bodyComposition, false, localOnly: true),
        metadata(.metabolicAge, "대사 나이", "Metabolic Age", "세", .bodyComposition, false, localOnly: true),
        metadata(.bodyScore, "Fitdays 바디 점수", "Fitdays Body Score", "점", .bodyComposition, false, localOnly: true),
        metadata(.obesityLevel, "Fitdays 체형 레벨", "Fitdays Body Type Level", "레벨", .bodyComposition, false, localOnly: true),

        metadata(.sleepSoundScore, "수면 소리 점수", "Sleep Sound Score", "점", .app, false, localOnly: true, source: "밤숨 앱에서 계산한 개인 참고용 점수입니다."),
        metadata(.dailyRhythmScore, "오늘의 리듬 점수", "Daily Rhythm Score", "점", .app, false, localOnly: true, source: "수면, 컨디션, 활동, 사용 가능한 건강 데이터를 함께 정리한 개인 참고용 점수입니다."),
        metadata(.audioCoverageRatio, "오디오 측정 커버리지", "Audio Coverage Ratio", "%", .sleep, false, localOnly: true, source: "수면 소리 분석에 사용된 오디오 수신 비율입니다."),
    ]

    static func metadata(
        _ metricID: UnifiedHealthMetricID,
        _ displayNameKo: String,
        _ displayNameEn: String,
        _ unit: String,
        _ category: MetricCategory,
        _ isHealthKitBacked: Bool,
        localOnly: Bool = false,
        source: String? = nil
    ) -> MetricDisplayMetadata {
        MetricDisplayMetadata(
            metricID: metricID,
            displayNameKo: displayNameKo,
            displayNameEn: displayNameEn,
            unit: unit,
            category: category,
            isHealthKitBacked: isHealthKitBacked,
            isExtendedLocalOnly: localOnly,
            description: source ?? "개인 패턴을 살펴보기 위해 표시하는 참고용 지표입니다.",
            disclaimer: localOnly ? "HealthKit에서 직접 읽지 않고 로컬 import, 수동 입력, 앱 계산값 또는 예시 데이터로만 다룹니다." : nil
        )
    }
}
