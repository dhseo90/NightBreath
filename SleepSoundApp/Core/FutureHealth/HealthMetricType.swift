import Foundation

public enum HealthMetricType: String, Codable, CaseIterable, Identifiable, Sendable {
    case systolicBloodPressure
    case diastolicBloodPressure
    case bodyMass
    case bodyFatPercentage
    case bodyMassIndex
    case leanBodyMass
    case stepCount
    case activeEnergy
    case heartRate
    case restingHeartRate
    case sleepDuration
    case respiratoryRate

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .systolicBloodPressure:
            "수축기 혈압"
        case .diastolicBloodPressure:
            "이완기 혈압"
        case .bodyMass:
            "체중"
        case .bodyFatPercentage:
            "체지방률"
        case .bodyMassIndex:
            "BMI"
        case .leanBodyMass:
            "제지방량"
        case .stepCount:
            "걸음 수"
        case .activeEnergy:
            "활동량"
        case .heartRate:
            "심박수"
        case .restingHeartRate:
            "안정시 심박수"
        case .sleepDuration:
            "수면 시간"
        case .respiratoryRate:
            "호흡수"
        }
    }

    public var unitLabel: String {
        switch self {
        case .systolicBloodPressure, .diastolicBloodPressure:
            "mmHg"
        case .bodyMass, .leanBodyMass:
            "kg"
        case .bodyFatPercentage:
            "%"
        case .bodyMassIndex:
            "BMI"
        case .stepCount:
            "걸음"
        case .activeEnergy:
            "kcal"
        case .heartRate, .restingHeartRate:
            "bpm"
        case .sleepDuration:
            "시간"
        case .respiratoryRate:
            "회/분"
        }
    }

    public var dashboardSectionName: String {
        switch self {
        case .systolicBloodPressure, .diastolicBloodPressure:
            "혈압"
        case .bodyMass:
            "체중"
        case .bodyFatPercentage:
            "체지방률"
        case .bodyMassIndex:
            "BMI"
        case .leanBodyMass:
            "제지방량"
        case .stepCount, .activeEnergy:
            "활동"
        case .heartRate, .restingHeartRate:
            "심박수"
        case .sleepDuration:
            "수면 시간"
        case .respiratoryRate:
            "호흡수"
        }
    }

    public static var readOnlyHealthKitMetrics: [HealthMetricType] {
        [
            .systolicBloodPressure,
            .diastolicBloodPressure,
            .bodyMass,
            .bodyFatPercentage,
            .bodyMassIndex,
            .leanBodyMass,
            .restingHeartRate,
            .respiratoryRate,
        ]
    }

    public static var dailyRhythmMockMetrics: [HealthMetricType] {
        [
            .systolicBloodPressure,
            .diastolicBloodPressure,
            .bodyMass,
            .bodyFatPercentage,
            .bodyMassIndex,
            .leanBodyMass,
            .stepCount,
            .activeEnergy,
            .heartRate,
            .restingHeartRate,
            .sleepDuration,
            .respiratoryRate,
        ]
    }
}
