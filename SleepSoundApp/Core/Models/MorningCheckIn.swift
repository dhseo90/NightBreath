import Foundation

public struct MorningCheckIn: Identifiable, Codable, Equatable {
    public var id: UUID
    public var sessionId: UUID
    public var refreshScore: Int
    public var fatigueScore: Int
    public var headache: Bool
    public var dryMouth: Bool
    public var soreThroat: Bool
    public var rememberedAwakenings: Int
    public var memo: String
    public var createdAt: Date

    public init(
        id: UUID = UUID(),
        sessionId: UUID,
        refreshScore: Int = 3,
        fatigueScore: Int = 3,
        headache: Bool = false,
        dryMouth: Bool = false,
        soreThroat: Bool = false,
        rememberedAwakenings: Int = 0,
        memo: String = "",
        createdAt: Date = Date()
    ) {
        self.id = id
        self.sessionId = sessionId
        self.refreshScore = min(max(refreshScore, 1), 5)
        self.fatigueScore = min(max(fatigueScore, 1), 5)
        self.headache = headache
        self.dryMouth = dryMouth
        self.soreThroat = soreThroat
        self.rememberedAwakenings = max(rememberedAwakenings, 0)
        self.memo = memo
        self.createdAt = createdAt
    }
}
