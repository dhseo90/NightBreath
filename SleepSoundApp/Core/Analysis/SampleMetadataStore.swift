import Foundation

public struct SavedLabeledAudioSample: Equatable, Sendable {
    public var metadata: LabeledAudioSample
    public var metadataURL: URL
    public var featureCSVURL: URL
    public var audioURL: URL

    public init(
        metadata: LabeledAudioSample,
        metadataURL: URL,
        featureCSVURL: URL,
        audioURL: URL
    ) {
        self.metadata = metadata
        self.metadataURL = metadataURL
        self.featureCSVURL = featureCSVURL
        self.audioURL = audioURL
    }
}

public struct SampleMetadataStore {
    public var samplesDirectory: URL
    private let fileManager: FileManager
    private let jsonEncoder: JSONEncoder

    public init(
        samplesDirectory: URL = SampleMetadataStore.defaultPersonalSamplesDirectory(),
        fileManager: FileManager = .default
    ) {
        self.samplesDirectory = samplesDirectory
        self.fileManager = fileManager

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        self.jsonEncoder = encoder
    }

    public static func defaultPersonalSamplesDirectory(
        fileManager: FileManager = .default
    ) -> URL {
        let documents = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first
            ?? fileManager.temporaryDirectory

        return documents
            .appendingPathComponent("Samples", isDirectory: true)
            .appendingPathComponent("Personal", isDirectory: true)
    }

    public func ensureSamplesDirectoryExists() throws {
        try fileManager.createDirectory(
            at: samplesDirectory,
            withIntermediateDirectories: true
        )
    }

    public func storageStatus(
        policy: DebugSampleStoragePolicy = .default
    ) -> DebugSampleStorageStatus {
        policy.storageStatus(in: samplesDirectory, fileManager: fileManager)
    }

    @discardableResult
    public func pruneExpiredSamples(
        policy: DebugSampleStoragePolicy = .default,
        now: Date = Date()
    ) throws -> Int {
        try policy.pruneExpiredSamples(in: samplesDirectory, fileManager: fileManager, now: now)
    }

    @discardableResult
    public func validateBeforeSaving(
        duration: TimeInterval,
        sessionSampleCount: Int,
        estimatedAdditionalBytes: Int64,
        policy: DebugSampleStoragePolicy = .default,
        now: Date = Date()
    ) throws -> DebugSampleStorageStatus {
        try ensureSamplesDirectoryExists()
        return try policy.validateBeforeSaving(
            duration: duration,
            sessionSampleCount: sessionSampleCount,
            estimatedAdditionalBytes: estimatedAdditionalBytes,
            samplesDirectory: samplesDirectory,
            fileManager: fileManager,
            now: now
        )
    }

    public func makeFileBaseName(capturedAt: Date, label: SampleLabel) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd'T'HHmmss"
        return "\(formatter.string(from: capturedAt))_\(label.rawValue)"
    }

    public func audioURL(fileBaseName: String) -> URL {
        samplesDirectory.appendingPathComponent(fileBaseName).appendingPathExtension("caf")
    }

    public func metadataFileName(fileBaseName: String) -> String {
        fileBaseName + ".metadata.json"
    }

    public func featureCSVFileName(fileBaseName: String) -> String {
        fileBaseName + ".features.csv"
    }

    public func metadataURL(fileBaseName: String) -> URL {
        samplesDirectory.appendingPathComponent(metadataFileName(fileBaseName: fileBaseName))
    }

    public func featureCSVURL(fileBaseName: String) -> URL {
        samplesDirectory.appendingPathComponent(featureCSVFileName(fileBaseName: fileBaseName))
    }

    @discardableResult
    public func save(
        metadata: LabeledAudioSample,
        features: AudioFeatures,
        detectorOutput: DetectorOutput? = nil
    ) throws -> SavedLabeledAudioSample {
        try ensureSamplesDirectoryExists()

        let fileBaseName = metadata.audioFileName.replacingOccurrences(of: ".caf", with: "")
        let metadataURL = metadataURL(fileBaseName: fileBaseName)
        let featureCSVURL = featureCSVURL(fileBaseName: fileBaseName)
        let audioURL = audioURL(fileBaseName: fileBaseName)

        let metadataData = try jsonEncoder.encode(metadata)
        try metadataData.write(to: metadataURL, options: [.atomic])

        let csv = FeatureCSVExporter.makeCSV(records: [
            FeatureCSVRecord(
                label: metadata.label.rawValue,
                features: features,
                detectorOutput: detectorOutput
            )
        ])
        try csv.write(to: featureCSVURL, atomically: true, encoding: .utf8)

        return SavedLabeledAudioSample(
            metadata: metadata,
            metadataURL: metadataURL,
            featureCSVURL: featureCSVURL,
            audioURL: audioURL
        )
    }
}
