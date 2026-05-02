import Foundation

public protocol HealthKitServiceProtocol {
    var isAvailable: Bool { get }
    func authorizationStatusDescription() -> String
}

public struct DisabledHealthKitService: HealthKitServiceProtocol {
    public var isAvailable: Bool { false }

    public init() {}

    public func authorizationStatusDescription() -> String {
        "V1에서는 건강앱 데이터 권한을 요청하지 않습니다."
    }
}
