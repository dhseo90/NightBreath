import Foundation

public struct FeatureCSVRecord: Equatable, Sendable {
    public var label: String
    public var features: AudioFeatures
    public var detectorOutput: DetectorOutput?

    public init(
        label: String,
        features: AudioFeatures,
        detectorOutput: DetectorOutput? = nil
    ) {
        self.label = label
        self.features = features
        self.detectorOutput = detectorOutput
    }
}

public struct FeatureCSVExporter: Sendable {
    public init() {}

    public static let columns: [String] = [
        "timestamp",
        "label",
        "rms",
        "energy",
        "zeroCrossingRate",
        "spectralCentroid",
        "lowBandEnergy",
        "midBandEnergy",
        "highBandEnergy",
        "detectorOutput",
        "confidence"
    ]

    public func export(records: [FeatureCSVRecord]) -> String {
        Self.makeCSV(records: records)
    }

    public static func makeCSV(records: [FeatureCSVRecord]) -> String {
        let formatter = ISO8601DateFormatter()
        var lines: [String] = [columns.joined(separator: ",")]

        for record in records {
            let features = record.features
            let values: [String] = [
                formatter.string(from: features.timestamp),
                record.label,
                format(features.rms),
                format(features.energy),
                format(features.zeroCrossingRate),
                format(features.spectralCentroid),
                format(features.lowBandEnergy),
                format(features.midBandEnergy),
                format(features.highBandEnergy),
                record.detectorOutput?.eventType.rawValue ?? "",
                record.detectorOutput.map { format($0.confidence) } ?? ""
            ]

            lines.append(values.map(escape).joined(separator: ","))
        }

        return lines.joined(separator: "\n")
    }

    private static func format(_ value: Double) -> String {
        guard value.isFinite else { return "0" }
        return String(format: "%.6f", value)
    }

    private static func escape(_ value: String) -> String {
        guard value.contains(",") || value.contains("\"") || value.contains("\n") else {
            return value
        }

        return "\"" + value.replacingOccurrences(of: "\"", with: "\"\"") + "\""
    }
}
