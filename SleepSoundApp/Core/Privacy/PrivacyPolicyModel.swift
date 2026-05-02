import Foundation

public struct PrivacyPolicyModel: Equatable {
    public var title: String
    public var principles: [String]

    public init(
        title: String = "개인정보와 오디오 처리",
        principles: [String] = [
            "분석은 iPhone 내부에서 수행합니다.",
            "서버 업로드, 계정 시스템, 외부 분석 SDK를 사용하지 않습니다.",
            "원본 전체 오디오 파일은 기본 저장하지 않습니다.",
            "리포트는 감지된 소리와 수면 중 소리 기반 지표로 표현합니다."
        ]
    ) {
        self.title = title
        self.principles = principles
    }
}
