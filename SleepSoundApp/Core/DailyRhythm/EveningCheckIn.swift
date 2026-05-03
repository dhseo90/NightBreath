import Foundation

public struct EveningCheckIn: Identifiable, Codable, Equatable, Sendable {
    public var id: UUID
    public var date: Date
    public var fatigueScore: Int
    public var stressScore: Int
    public var moodScore: Int?
    public var caffeine: Bool
    public var alcohol: Bool
    public var lateMeal: Bool
    public var exercise: Bool
    public var nap: Bool
    public var memo: String
    public var createdAt: Date
    public var updatedAt: Date

    public var lifestyleTags: [LifestyleTag] {
        var tags: [LifestyleTag] = []
        if caffeine { tags.append(.caffeine) }
        if alcohol { tags.append(.alcohol) }
        if lateMeal { tags.append(.lateMeal) }
        if exercise { tags.append(.exercise) }
        if nap { tags.append(.nap) }
        return tags
    }

    public init(
        id: UUID = UUID(),
        date: Date,
        fatigueScore: Int = 3,
        stressScore: Int = 3,
        moodScore: Int? = nil,
        caffeine: Bool = false,
        alcohol: Bool = false,
        lateMeal: Bool = false,
        exercise: Bool = false,
        nap: Bool = false,
        memo: String = "",
        createdAt: Date = Date(),
        updatedAt: Date? = nil
    ) {
        self.id = id
        self.date = date
        self.fatigueScore = Self.clampedScore(fatigueScore)
        self.stressScore = Self.clampedScore(stressScore)
        self.moodScore = moodScore.map(Self.clampedScore)
        self.caffeine = caffeine
        self.alcohol = alcohol
        self.lateMeal = lateMeal
        self.exercise = exercise
        self.nap = nap
        self.memo = memo
        self.createdAt = createdAt
        self.updatedAt = updatedAt ?? createdAt
    }

    private static func clampedScore(_ value: Int) -> Int {
        min(max(value, 1), 5)
    }
}
