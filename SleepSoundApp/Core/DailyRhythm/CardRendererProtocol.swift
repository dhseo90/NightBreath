import Foundation

public struct DailyHealthCardImageResult: Identifiable, Codable, Equatable, Sendable {
    public var id: UUID
    public var reportId: UUID
    public var template: DailyHealthCardTemplate
    public var privacyLevel: DailyHealthCardPrivacyLevel
    public var renderedAt: Date
    public var fileName: String?
    public var imageData: Data?

    public var isPlaceholder: Bool {
        imageData == nil
    }

    public init(
        id: UUID = UUID(),
        reportId: UUID,
        template: DailyHealthCardTemplate,
        privacyLevel: DailyHealthCardPrivacyLevel,
        renderedAt: Date = Date(),
        fileName: String? = nil,
        imageData: Data? = nil
    ) {
        self.id = id
        self.reportId = reportId
        self.template = template
        self.privacyLevel = template.effectivePrivacyLevel ?? privacyLevel
        self.renderedAt = renderedAt
        self.fileName = fileName
        self.imageData = imageData
    }
}

public protocol CardRendererProtocol: Sendable {
    func renderCard(
        report: DailyRhythmReport,
        template: DailyHealthCardTemplate,
        privacyLevel: DailyHealthCardPrivacyLevel
    ) async -> DailyHealthCardImageResult
}

public struct PlaceholderDailyHealthCardRenderer: CardRendererProtocol {
    public init() {}

    public func renderCard(
        report: DailyRhythmReport,
        template: DailyHealthCardTemplate,
        privacyLevel: DailyHealthCardPrivacyLevel
    ) async -> DailyHealthCardImageResult {
        DailyHealthCardImageResult(
            reportId: report.id,
            template: template,
            privacyLevel: privacyLevel,
            fileName: nil,
            imageData: nil
        )
    }
}
