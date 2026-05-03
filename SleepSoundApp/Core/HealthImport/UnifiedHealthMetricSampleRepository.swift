import Foundation

public protocol UnifiedHealthMetricSampleRepositoryProtocol: AnyObject, Sendable {
    func save(batch: ImportBatch, samples: [UnifiedHealthMetricSample]) throws
    func fetchBatches() -> [ImportBatch]
    func fetchSamples(importBatchId: String?) -> [UnifiedHealthMetricSample]
    func deleteBatch(id: UUID) throws
}

public extension UnifiedHealthMetricSampleRepositoryProtocol {
    func fetchSamples() -> [UnifiedHealthMetricSample] {
        fetchSamples(importBatchId: nil)
    }
}

public final class InMemoryUnifiedHealthMetricSampleRepository: UnifiedHealthMetricSampleRepositoryProtocol, @unchecked Sendable {
    private var archive = UnifiedHealthMetricArchive()
    private let lock = NSLock()

    public init() {}

    public func save(batch: ImportBatch, samples: [UnifiedHealthMetricSample]) throws {
        lock.lock()
        defer { lock.unlock() }

        archive.replaceImport(batch: batch, samples: samples)
    }

    public func fetchBatches() -> [ImportBatch] {
        lock.lock()
        defer { lock.unlock() }

        return archive.importBatches.sorted { $0.importedAt > $1.importedAt }
    }

    public func fetchSamples(importBatchId: String? = nil) -> [UnifiedHealthMetricSample] {
        lock.lock()
        defer { lock.unlock() }

        return archive.samples
            .filter { sample in
                guard let importBatchId else { return true }
                return sample.importBatchId == importBatchId
            }
            .sortedByMeasuredAtAscending()
    }

    public func deleteBatch(id: UUID) throws {
        lock.lock()
        defer { lock.unlock() }

        archive.deleteBatch(id: id)
    }
}

public final class JSONUnifiedHealthMetricSampleRepository: UnifiedHealthMetricSampleRepositoryProtocol, @unchecked Sendable {
    public let fileURL: URL

    private let fileManager: FileManager
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    private let lock = NSLock()

    public init(
        fileURL: URL? = nil,
        fileManager: FileManager = .default
    ) {
        self.fileManager = fileManager
        self.fileURL = fileURL ?? Self.defaultStoreURL(fileManager: fileManager)

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        self.encoder = encoder

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        self.decoder = decoder

        try? fileManager.createDirectory(
            at: self.fileURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
    }

    public func save(batch: ImportBatch, samples: [UnifiedHealthMetricSample]) throws {
        try updateArchive { archive in
            archive.replaceImport(batch: batch, samples: samples)
        }
    }

    public func fetchBatches() -> [ImportBatch] {
        readArchive().importBatches.sorted { $0.importedAt > $1.importedAt }
    }

    public func fetchSamples(importBatchId: String? = nil) -> [UnifiedHealthMetricSample] {
        readArchive().samples
            .filter { sample in
                guard let importBatchId else { return true }
                return sample.importBatchId == importBatchId
            }
            .sortedByMeasuredAtAscending()
    }

    public func deleteBatch(id: UUID) throws {
        try updateArchive { archive in
            archive.deleteBatch(id: id)
        }
    }

    private static func defaultStoreURL(fileManager: FileManager) -> URL {
        let baseURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? fileManager.temporaryDirectory

        return baseURL
            .appendingPathComponent("NightBreath", isDirectory: true)
            .appendingPathComponent("imported-health-metrics.json")
    }

    private func readArchive() -> UnifiedHealthMetricArchive {
        lock.lock()
        defer { lock.unlock() }

        guard let data = try? Data(contentsOf: fileURL), !data.isEmpty else {
            return UnifiedHealthMetricArchive()
        }

        return (try? decoder.decode(UnifiedHealthMetricArchive.self, from: data)) ?? UnifiedHealthMetricArchive()
    }

    private func updateArchive(_ update: (inout UnifiedHealthMetricArchive) -> Void) throws {
        lock.lock()
        defer { lock.unlock() }

        var archive = loadArchiveWithoutLock()
        update(&archive)
        try persistArchiveWithoutLock(archive)
    }

    private func loadArchiveWithoutLock() -> UnifiedHealthMetricArchive {
        guard let data = try? Data(contentsOf: fileURL), !data.isEmpty else {
            return UnifiedHealthMetricArchive()
        }

        return (try? decoder.decode(UnifiedHealthMetricArchive.self, from: data)) ?? UnifiedHealthMetricArchive()
    }

    private func persistArchiveWithoutLock(_ archive: UnifiedHealthMetricArchive) throws {
        try fileManager.createDirectory(
            at: fileURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )

        let data = try encoder.encode(archive)
        try data.write(to: fileURL, options: [.atomic])
    }
}

public struct UnifiedHealthMetricArchive: Codable, Equatable, Sendable {
    public var schemaVersion: Int
    public var importBatches: [ImportBatch]
    public var samples: [UnifiedHealthMetricSample]

    public init(
        schemaVersion: Int = 1,
        importBatches: [ImportBatch] = [],
        samples: [UnifiedHealthMetricSample] = []
    ) {
        self.schemaVersion = schemaVersion
        self.importBatches = importBatches
        self.samples = samples
    }

    mutating func replaceImport(batch: ImportBatch, samples newSamples: [UnifiedHealthMetricSample]) {
        let replacementBatchIds = Set(
            importBatches
                .filter { $0.id == batch.id || ($0.sourceName == batch.sourceName && $0.fileName == batch.fileName) }
                .map { $0.id.uuidString }
        )
        let incomingDuplicateKeys = Set(newSamples.map(Self.duplicateKey(for:)))

        importBatches.removeAll { existingBatch in
            existingBatch.id == batch.id
                || (existingBatch.sourceName == batch.sourceName && existingBatch.fileName == batch.fileName)
        }
        samples.removeAll { sample in
            if let importBatchId = sample.importBatchId, replacementBatchIds.contains(importBatchId) {
                return true
            }
            return incomingDuplicateKeys.contains(Self.duplicateKey(for: sample))
        }

        importBatches.append(batch)
        samples.append(contentsOf: newSamples)
        importBatches.sort { $0.importedAt > $1.importedAt }
        samples = samples.sortedByMeasuredAtAscending()
    }

    mutating func deleteBatch(id: UUID) {
        importBatches.removeAll { $0.id == id }
        samples.removeAll { $0.importBatchId == id.uuidString }
    }

    private static func duplicateKey(for sample: UnifiedHealthMetricSample) -> String {
        [
            sample.metricID.rawValue,
            sample.sourceType.rawValue,
            sample.sourceName,
            sample.externalRecordId ?? "\(sample.measuredAt.timeIntervalSince1970)",
        ].joined(separator: "|")
    }
}

public extension Array where Element == UnifiedHealthMetricSample {
    func sortedByMeasuredAtAscending() -> [UnifiedHealthMetricSample] {
        sorted { lhs, rhs in
            if lhs.measuredAt == rhs.measuredAt {
                if lhs.metricID.rawValue == rhs.metricID.rawValue {
                    return lhs.id.uuidString < rhs.id.uuidString
                }
                return lhs.metricID.rawValue < rhs.metricID.rawValue
            }
            return lhs.measuredAt < rhs.measuredAt
        }
    }

    func sortedByMeasuredAtDescending() -> [UnifiedHealthMetricSample] {
        sorted { lhs, rhs in
            if lhs.measuredAt == rhs.measuredAt {
                if lhs.metricID.rawValue == rhs.metricID.rawValue {
                    return lhs.id.uuidString < rhs.id.uuidString
                }
                return lhs.metricID.rawValue < rhs.metricID.rawValue
            }
            return lhs.measuredAt > rhs.measuredAt
        }
    }
}
