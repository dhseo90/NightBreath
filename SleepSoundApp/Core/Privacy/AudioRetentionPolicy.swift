import Foundation

public enum AudioRetentionPolicy: String, Codable, CaseIterable, Identifiable {
    case discardRawAudio
    case shortEventSamplesOptIn

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .discardRawAudio:
            "원본 전체 오디오 저장 안 함"
        case .shortEventSamplesOptIn:
            "짧은 이벤트 샘플만 선택 저장"
        }
    }

    public var description: String {
        switch self {
        case .discardRawAudio:
            "V1 기본 정책입니다. 분석 결과와 이벤트 메타데이터만 로컬에 남깁니다."
        case .shortEventSamplesOptIn:
            "향후 선택 기능으로만 제공하며, 사용자가 명시적으로 켠 경우에 한정합니다."
        }
    }
}
