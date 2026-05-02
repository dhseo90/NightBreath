import Foundation

public enum HealthMetricType: String, Codable, CaseIterable, Identifiable {
    case systolicBloodPressure
    case diastolicBloodPressure
    case bodyMass
    case bodyFatPercentage
    case bodyMassIndex
    case leanBodyMass
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
        case .restingHeartRate:
            "안정시 심박수"
        case .sleepDuration:
            "수면 시간"
        case .respiratoryRate:
            "호흡수"
        }
    }
}
