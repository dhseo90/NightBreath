import Foundation

public struct EventFeedbackManifest: Codable, Equatable, Sendable {
    public var datasetName: String
    public var datasetLicenseNote: String
    public var generatedAt: Date
    public var records: [EventFeedbackManifestRecord]

    public init(
        datasetName: String = "NightBreath Local Event Feedback",
        datasetLicenseNote: String = "Local user feedback metadata only. Audio files are not included.",
        generatedAt: Date = Date(),
        records: [EventFeedbackManifestRecord]
    ) {
        self.datasetName = datasetName
        self.datasetLicenseNote = datasetLicenseNote
        self.generatedAt = generatedAt
        self.records = records
    }
}

public struct EventFeedbackManifestRecord: Codable, Equatable, Identifiable, Sendable {
    public var id: String { feedbackId.uuidString }

    public var feedbackId: UUID
    public var fileId: String
    public var eventId: UUID
    public var sessionId: UUID
    public var eventType: SleepEventType
    public var selectedFeedback: EventFeedbackSelection
    public var correctedLabel: EventFeedbackCorrectedLabel?
    public var expectedLabels: [DatasetManifestLabel]
    public var negativeLabels: [DatasetManifestLabel]
    public var labelConfidence: Double
    public var trainingAction: String
    public var localFilePath: String
    public var audioSamplePath: String?
    public var hasAudioSample: Bool
    public var audioSampleId: String?
    public var segmentStartSeconds: TimeInterval
    public var segmentDurationSeconds: TimeInterval
    public var eventConfidence: Double?
    public var eventIntensity: Double?
    public var createdAt: Date
    public var notes: String?
}

public struct EventFeedbackManifestExportResult: Equatable, Sendable {
    public var jsonURL: URL
    public var csvURL: URL
    public var recordCount: Int
}

public final class EventFeedbackManifestExporter: @unchecked Sendable {
    private let fileManager: FileManager
    private let encoder: JSONEncoder

    public init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        self.encoder = encoder
    }

    public func export(
        feedbacks: [EventFeedback],
        events: [SleepEvent],
        outputDirectory: URL,
        snippetsDirectory: URL? = nil,
        datasetName: String = "NightBreath Local Event Feedback"
    ) throws -> EventFeedbackManifestExportResult {
        try fileManager.createDirectory(at: outputDirectory, withIntermediateDirectories: true)

        let records = makeRecords(
            feedbacks: feedbacks,
            events: events,
            snippetsDirectory: snippetsDirectory
        )
        let manifest = EventFeedbackManifest(datasetName: datasetName, records: records)
        let jsonURL = outputDirectory.appendingPathComponent("export_feedback_manifest.json")
        let csvURL = outputDirectory.appendingPathComponent("export_feedback_manifest.csv")

        let data = try encoder.encode(manifest)
        try data.write(to: jsonURL, options: [.atomic])
        try makeCSV(records: records).write(to: csvURL, atomically: true, encoding: .utf8)

        return EventFeedbackManifestExportResult(
            jsonURL: jsonURL,
            csvURL: csvURL,
            recordCount: records.count
        )
    }

    public func makeRecords(
        feedbacks: [EventFeedback],
        events: [SleepEvent],
        snippetsDirectory: URL? = nil
    ) -> [EventFeedbackManifestRecord] {
        let eventsByID = Dictionary(uniqueKeysWithValues: events.map { ($0.id, $0) })
        return feedbacks
            .sorted { $0.createdAt < $1.createdAt }
            .map { feedback in
                makeRecord(
                    feedback: feedback,
                    event: eventsByID[feedback.eventId],
                    snippetsDirectory: snippetsDirectory
                )
            }
    }

    private func makeRecord(
        feedback: EventFeedback,
        event: SleepEvent?,
        snippetsDirectory: URL?
    ) -> EventFeedbackManifestRecord {
        let labels = trainingLabels(for: feedback)
        let audioSampleId = feedback.audioSampleId ?? event?.audioSnippetFileName
        let hasAudioSample = feedback.hasAudioSample || audioSampleId != nil
        let audioSamplePath = makeAudioSamplePath(
            audioSampleId: audioSampleId,
            hasAudioSample: hasAudioSample,
            snippetsDirectory: snippetsDirectory
        )

        return EventFeedbackManifestRecord(
            feedbackId: feedback.id,
            fileId: audioSampleId ?? "feedback-\(feedback.eventId.uuidString)",
            eventId: feedback.eventId,
            sessionId: feedback.sessionId,
            eventType: feedback.eventType,
            selectedFeedback: feedback.selectedFeedback,
            correctedLabel: feedback.correctedLabel,
            expectedLabels: labels.expected,
            negativeLabels: labels.negative,
            labelConfidence: labels.confidence,
            trainingAction: labels.action,
            localFilePath: audioSamplePath ?? "",
            audioSamplePath: audioSamplePath,
            hasAudioSample: hasAudioSample,
            audioSampleId: audioSampleId,
            segmentStartSeconds: 0,
            segmentDurationSeconds: max(0, event?.duration ?? 0),
            eventConfidence: event?.confidence,
            eventIntensity: event?.intensity,
            createdAt: feedback.createdAt,
            notes: feedback.note
        )
    }

    private func trainingLabels(
        for feedback: EventFeedback
    ) -> (expected: [DatasetManifestLabel], negative: [DatasetManifestLabel], confidence: Double, action: String) {
        switch feedback.selectedFeedback {
        case .correct:
            let label = datasetLabel(for: feedback.eventType)
            return ([label], [], 1.0, label == .snore ? "positive" : "negative")
        case .incorrect:
            if let correctedLabel = feedback.correctedLabel {
                let label = datasetLabel(for: correctedLabel)
                return ([label], negativeLabels(for: feedback.eventType), 0.9, "correctedLabel")
            }
            return ([.unknown], negativeLabels(for: feedback.eventType), 0.8, "negative")
        case .unsure:
            return ([], [], 0.2, "excludedUnsure")
        }
    }

    private func datasetLabel(for eventType: SleepEventType) -> DatasetManifestLabel {
        DatasetManifestLabel(rawValue: eventType.rawValue) ?? .unknown
    }

    private func datasetLabel(for correctedLabel: EventFeedbackCorrectedLabel) -> DatasetManifestLabel {
        DatasetManifestLabel(rawValue: correctedLabel.rawValue) ?? .unknown
    }

    private func negativeLabels(for eventType: SleepEventType) -> [DatasetManifestLabel] {
        guard let label = DatasetManifestLabel(rawValue: eventType.rawValue) else {
            return []
        }
        return [label]
    }

    private func makeAudioSamplePath(
        audioSampleId: String?,
        hasAudioSample: Bool,
        snippetsDirectory: URL?
    ) -> String? {
        guard hasAudioSample, let audioSampleId, !audioSampleId.isEmpty else {
            return nil
        }
        guard let snippetsDirectory else {
            return audioSampleId
        }
        return snippetsDirectory.appendingPathComponent(audioSampleId).path
    }

    private func makeCSV(records: [EventFeedbackManifestRecord]) -> String {
        let header = [
            "feedbackId",
            "fileId",
            "eventId",
            "sessionId",
            "eventType",
            "selectedFeedback",
            "correctedLabel",
            "expectedLabels",
            "negativeLabels",
            "labelConfidence",
            "trainingAction",
            "localFilePath",
            "hasAudioSample",
            "audioSampleId",
            "segmentStartSeconds",
            "segmentDurationSeconds",
            "eventConfidence",
            "eventIntensity",
            "createdAt",
            "notes",
        ]
        var rows = [header.joined(separator: ",")]
        rows.append(
            contentsOf: records.map { record in
                [
                    record.feedbackId.uuidString,
                    record.fileId,
                    record.eventId.uuidString,
                    record.sessionId.uuidString,
                    record.eventType.rawValue,
                    record.selectedFeedback.rawValue,
                    record.correctedLabel?.rawValue ?? "",
                    record.expectedLabels.map(\.rawValue).joined(separator: "|"),
                    record.negativeLabels.map(\.rawValue).joined(separator: "|"),
                    String(format: "%.3f", record.labelConfidence),
                    record.trainingAction,
                    record.localFilePath,
                    record.hasAudioSample ? "true" : "false",
                    record.audioSampleId ?? "",
                    String(format: "%.3f", record.segmentStartSeconds),
                    String(format: "%.3f", record.segmentDurationSeconds),
                    record.eventConfidence.map { String(format: "%.3f", $0) } ?? "",
                    record.eventIntensity.map { String(format: "%.3f", $0) } ?? "",
                    ISO8601DateFormatter().string(from: record.createdAt),
                    record.notes ?? "",
                ].map(csvEscape).joined(separator: ",")
            }
        )
        return rows.joined(separator: "\n") + "\n"
    }

    private func csvEscape(_ value: String) -> String {
        if value.contains(",") || value.contains("\"") || value.contains("\n") {
            return "\"\(value.replacingOccurrences(of: "\"", with: "\"\""))\""
        }
        return value
    }
}
