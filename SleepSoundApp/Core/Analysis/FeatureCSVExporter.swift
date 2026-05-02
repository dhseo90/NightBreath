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

public struct FeatureLabelSummary: Equatable, Sendable {
    public var label: String
    public var sampleCount: Int
    public var averageRMS: Double
    public var averageEnergy: Double
    public var averageZeroCrossingRate: Double
    public var averageSpectralCentroid: Double
    public var averageLowBandEnergy: Double
    public var averageMidBandEnergy: Double
    public var averageHighBandEnergy: Double

    public init(
        label: String,
        sampleCount: Int,
        averageRMS: Double,
        averageEnergy: Double,
        averageZeroCrossingRate: Double,
        averageSpectralCentroid: Double,
        averageLowBandEnergy: Double,
        averageMidBandEnergy: Double,
        averageHighBandEnergy: Double
    ) {
        self.label = label
        self.sampleCount = max(0, sampleCount)
        self.averageRMS = Self.finite(averageRMS)
        self.averageEnergy = Self.finite(averageEnergy)
        self.averageZeroCrossingRate = Self.finite(averageZeroCrossingRate)
        self.averageSpectralCentroid = Self.finite(averageSpectralCentroid)
        self.averageLowBandEnergy = Self.finite(averageLowBandEnergy)
        self.averageMidBandEnergy = Self.finite(averageMidBandEnergy)
        self.averageHighBandEnergy = Self.finite(averageHighBandEnergy)
    }

    private static func finite(_ value: Double) -> Double {
        guard value.isFinite else { return 0 }
        return value
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

    public func summarizeByLabel(records: [FeatureCSVRecord]) -> [FeatureLabelSummary] {
        Self.summarizeByLabel(records: records)
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

    public static func summarizeByLabel(records: [FeatureCSVRecord]) -> [FeatureLabelSummary] {
        let groupedRecords = Dictionary(grouping: records) { record in
            record.label
        }

        return groupedRecords.keys.sorted().compactMap { label in
            guard let records = groupedRecords[label], !records.isEmpty else {
                return nil
            }

            let count = Double(records.count)
            return FeatureLabelSummary(
                label: label,
                sampleCount: records.count,
                averageRMS: records.reduce(0) { $0 + $1.features.rms } / count,
                averageEnergy: records.reduce(0) { $0 + $1.features.energy } / count,
                averageZeroCrossingRate: records.reduce(0) { $0 + $1.features.zeroCrossingRate } / count,
                averageSpectralCentroid: records.reduce(0) { $0 + $1.features.spectralCentroid } / count,
                averageLowBandEnergy: records.reduce(0) { $0 + $1.features.lowBandEnergy } / count,
                averageMidBandEnergy: records.reduce(0) { $0 + $1.features.midBandEnergy } / count,
                averageHighBandEnergy: records.reduce(0) { $0 + $1.features.highBandEnergy } / count
            )
        }
    }

    public static func makeLabelSummaryCSV(records: [FeatureCSVRecord]) -> String {
        let columns = [
            "label",
            "sampleCount",
            "averageRMS",
            "averageEnergy",
            "averageZeroCrossingRate",
            "averageSpectralCentroid",
            "averageLowBandEnergy",
            "averageMidBandEnergy",
            "averageHighBandEnergy"
        ]
        let summaries = summarizeByLabel(records: records)
        var lines: [String] = [columns.joined(separator: ",")]

        for summary in summaries {
            let values = [
                summary.label,
                String(summary.sampleCount),
                format(summary.averageRMS),
                format(summary.averageEnergy),
                format(summary.averageZeroCrossingRate),
                format(summary.averageSpectralCentroid),
                format(summary.averageLowBandEnergy),
                format(summary.averageMidBandEnergy),
                format(summary.averageHighBandEnergy)
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
