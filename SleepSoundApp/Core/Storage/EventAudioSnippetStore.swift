import AVFoundation
import Foundation

public struct EventAudioSnippetPolicy: Equatable, Sendable {
    public static let `default` = EventAudioSnippetPolicy()

    public var preEventSeconds: TimeInterval
    public var postEventSeconds: TimeInterval
    public var maxSnippetDuration: TimeInterval
    public var maxSnippetsPerSession: Int
    public var maxFolderSizeBytes: Int64
    public var maxSnippetAge: TimeInterval

    public init(
        preEventSeconds: TimeInterval = 2,
        postEventSeconds: TimeInterval = 3,
        maxSnippetDuration: TimeInterval = 10,
        maxSnippetsPerSession: Int = 100,
        maxFolderSizeBytes: Int64 = 200 * 1_024 * 1_024,
        maxSnippetAge: TimeInterval = 7 * 24 * 60 * 60
    ) {
        self.preEventSeconds = max(0, preEventSeconds)
        self.postEventSeconds = max(0, postEventSeconds)
        self.maxSnippetDuration = max(1, maxSnippetDuration)
        self.maxSnippetsPerSession = max(1, maxSnippetsPerSession)
        self.maxFolderSizeBytes = max(1_024 * 1_024, maxFolderSizeBytes)
        self.maxSnippetAge = max(60, maxSnippetAge)
    }
}

public struct EventAudioSnippet: Codable, Equatable, Identifiable, Sendable {
    public var id: UUID
    public var sessionId: UUID
    public var eventType: SleepEventType
    public var eventStartedAt: Date
    public var eventEndedAt: Date
    public var snippetStartedAt: Date
    public var snippetEndedAt: Date
    public var duration: TimeInterval
    public var fileName: String
    public var createdAt: Date
    public var sampleRate: Double
    public var channelCount: Int

    public init(
        id: UUID = UUID(),
        sessionId: UUID,
        eventType: SleepEventType,
        eventStartedAt: Date,
        eventEndedAt: Date,
        snippetStartedAt: Date,
        snippetEndedAt: Date,
        duration: TimeInterval,
        fileName: String,
        createdAt: Date = Date(),
        sampleRate: Double,
        channelCount: Int = 1
    ) {
        self.id = id
        self.sessionId = sessionId
        self.eventType = eventType
        self.eventStartedAt = eventStartedAt
        self.eventEndedAt = eventEndedAt
        self.snippetStartedAt = snippetStartedAt
        self.snippetEndedAt = snippetEndedAt
        self.duration = max(0, duration)
        self.fileName = fileName
        self.createdAt = createdAt
        self.sampleRate = sampleRate
        self.channelCount = max(1, channelCount)
    }
}

public struct EventAudioSnippetFileRecord: Identifiable, Equatable, Sendable {
    public var id: String { fileName }

    public var url: URL
    public var fileName: String
    public var sizeBytes: Int64
    public var duration: TimeInterval
    public var createdAt: Date?

    public init(
        url: URL,
        fileName: String,
        sizeBytes: Int64,
        duration: TimeInterval,
        createdAt: Date?
    ) {
        self.url = url
        self.fileName = fileName
        self.sizeBytes = max(0, sizeBytes)
        self.duration = max(0, duration)
        self.createdAt = createdAt
    }

    public var isDebugPreview: Bool {
        fileName.hasPrefix("debug-preview_")
    }

    public func belongsToSession(id sessionId: UUID) -> Bool {
        let fullID = sessionId.uuidString
        let shortID = String(fullID.prefix(8))
        return fileName.contains(fullID) || fileName.contains(shortID)
    }
}

public enum EventAudioSnippetStoreError: LocalizedError, Equatable {
    case noAudioSamples
    case snippetLimitReached
    case folderSizeLimitExceeded
    case invalidFormat

    public var errorDescription: String? {
        switch self {
        case .noAudioSamples:
            return "저장할 이벤트 오디오 샘플이 없습니다."
        case .snippetLimitReached:
            return "이번 세션에서 저장 가능한 이벤트 오디오 샘플 수에 도달했습니다."
        case .folderSizeLimitExceeded:
            return "이벤트 오디오 샘플 폴더 용량 제한에 도달했습니다."
        case .invalidFormat:
            return "이벤트 오디오 샘플 형식을 만들 수 없습니다."
        }
    }
}

public final class EventAudioSnippetStore: @unchecked Sendable {
    public let snippetsDirectory: URL

    private let fileManager: FileManager
    private let policy: EventAudioSnippetPolicy

    public init(
        snippetsDirectory: URL? = nil,
        policy: EventAudioSnippetPolicy = .default,
        fileManager: FileManager = .default
    ) {
        self.fileManager = fileManager
        self.policy = policy
        self.snippetsDirectory = snippetsDirectory ?? Self.defaultSnippetsDirectory(fileManager: fileManager)
        try? fileManager.createDirectory(at: self.snippetsDirectory, withIntermediateDirectories: true)
    }

    public static func defaultSnippetsDirectory(fileManager: FileManager = .default) -> URL {
        let baseURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? fileManager.temporaryDirectory

        return baseURL
            .appendingPathComponent("NightBreath", isDirectory: true)
            .appendingPathComponent("EventAudioSnippets", isDirectory: true)
    }

    public func saveSnippet(
        sessionId: UUID,
        output: DetectorOutput,
        chunks: [AudioChunk]
    ) throws -> EventAudioSnippet {
        let existingCount = try snippetFiles().count
        guard existingCount < policy.maxSnippetsPerSession else {
            throw EventAudioSnippetStoreError.snippetLimitReached
        }

        guard folderSizeBytes() < policy.maxFolderSizeBytes else {
            throw EventAudioSnippetStoreError.folderSizeLimitExceeded
        }

        let targetStart = output.startedAt.addingTimeInterval(-policy.preEventSeconds)
        let targetEnd = output.endedAt.addingTimeInterval(policy.postEventSeconds)
        let extracted = extractSamples(from: chunks, targetStart: targetStart, targetEnd: targetEnd)

        guard !extracted.samples.isEmpty, extracted.sampleRate > 0 else {
            throw EventAudioSnippetStoreError.noAudioSamples
        }

        let maxSampleCount = Int(policy.maxSnippetDuration * extracted.sampleRate)
        let samples = Array(extracted.samples.prefix(max(1, maxSampleCount)))
        let duration = Double(samples.count) / extracted.sampleRate
        let fileName = makeFileName(
            sessionId: sessionId,
            eventType: output.eventType,
            eventStartedAt: output.startedAt
        )
        let url = snippetsDirectory.appendingPathComponent(fileName)

        try writeCAF(samples: samples, sampleRate: extracted.sampleRate, to: url)

        return EventAudioSnippet(
            sessionId: sessionId,
            eventType: output.eventType,
            eventStartedAt: output.startedAt,
            eventEndedAt: output.endedAt,
            snippetStartedAt: maxDate(targetStart, extracted.firstSampleAt),
            snippetEndedAt: maxDate(targetStart, extracted.firstSampleAt).addingTimeInterval(duration),
            duration: duration,
            fileName: fileName,
            sampleRate: extracted.sampleRate
        )
    }

    #if DEBUG
    public func saveDebugPreview(
        sessionId: UUID,
        chunks: [AudioChunk],
        createdAt: Date = Date()
    ) throws -> EventAudioSnippet {
        let existingCount = try snippetFiles().count
        guard existingCount < policy.maxSnippetsPerSession else {
            throw EventAudioSnippetStoreError.snippetLimitReached
        }

        let sortedChunks = chunks.sorted { $0.startedAt < $1.startedAt }
        guard let latestChunk = sortedChunks.last else {
            throw EventAudioSnippetStoreError.noAudioSamples
        }

        guard folderSizeBytes() < policy.maxFolderSizeBytes else {
            throw EventAudioSnippetStoreError.folderSizeLimitExceeded
        }

        let targetEnd = latestChunk.startedAt.addingTimeInterval(latestChunk.duration)
        let targetStart = targetEnd.addingTimeInterval(-policy.maxSnippetDuration)
        let extracted = extractSamples(from: sortedChunks, targetStart: targetStart, targetEnd: targetEnd)

        guard !extracted.samples.isEmpty, extracted.sampleRate > 0 else {
            throw EventAudioSnippetStoreError.noAudioSamples
        }

        let maxSampleCount = Int(policy.maxSnippetDuration * extracted.sampleRate)
        let samples = Array(extracted.samples.suffix(max(1, maxSampleCount)))
        let duration = Double(samples.count) / extracted.sampleRate
        let fileName = makeDebugPreviewFileName(sessionId: sessionId, createdAt: createdAt)
        let url = snippetsDirectory.appendingPathComponent(fileName)

        try writeCAF(samples: samples, sampleRate: extracted.sampleRate, to: url)

        let snippetStart = maxDate(targetStart, extracted.firstSampleAt)
        return EventAudioSnippet(
            sessionId: sessionId,
            eventType: .unknown,
            eventStartedAt: snippetStart,
            eventEndedAt: snippetStart.addingTimeInterval(duration),
            snippetStartedAt: snippetStart,
            snippetEndedAt: snippetStart.addingTimeInterval(duration),
            duration: duration,
            fileName: fileName,
            createdAt: createdAt,
            sampleRate: extracted.sampleRate
        )
    }

    public func debugPreviewRecords(sessionId: UUID? = nil) -> [EventAudioSnippetFileRecord] {
        snippetFileRecords()
            .filter { record in
                guard record.isDebugPreview else { return false }
                guard let sessionId else { return true }
                return record.belongsToSession(id: sessionId)
            }
            .sorted { lhs, rhs in
                (lhs.createdAt ?? .distantPast) > (rhs.createdAt ?? .distantPast)
            }
            .map(EventAudioSnippetFileRecord.init)
    }

    public func debugPlayableRecords(sessionId: UUID? = nil) -> [EventAudioSnippetFileRecord] {
        snippetFileRecords()
            .filter { record in
                guard let sessionId else { return true }
                return record.belongsToSession(id: sessionId)
            }
            .sorted { lhs, rhs in
                (lhs.createdAt ?? .distantPast) > (rhs.createdAt ?? .distantPast)
            }
            .map(EventAudioSnippetFileRecord.init)
    }
    #endif

    public func url(for fileName: String) -> URL {
        snippetsDirectory.appendingPathComponent(fileName)
    }

    public func snippetExists(fileName: String?) -> Bool {
        guard let fileName, !fileName.isEmpty else { return false }
        return fileManager.fileExists(atPath: url(for: fileName).path)
    }

    public func deleteSnippet(fileName: String) throws {
        let url = url(for: fileName)
        guard fileManager.fileExists(atPath: url.path) else { return }
        try fileManager.removeItem(at: url)
    }

    public func deleteAllSnippets() throws {
        guard fileManager.fileExists(atPath: snippetsDirectory.path) else { return }
        try fileManager.removeItem(at: snippetsDirectory)
        try fileManager.createDirectory(at: snippetsDirectory, withIntermediateDirectories: true)
    }

    public func storageStats(linkedFileNames: Set<String>) -> EventAudioStorageStats {
        let records = snippetFileRecords()
        var stats = EventAudioStorageStats(sampleCount: records.count)

        for record in records {
            let isLinked = linkedFileNames.contains(record.fileName)
            stats.totalBytes += record.sizeBytes
            stats.totalDurationSeconds += record.duration

            if isLinked {
                stats.linkedSampleCount += 1
                stats.linkedBytes += record.sizeBytes
                stats.linkedDurationSeconds += record.duration
            } else {
                stats.orphanSampleCount += 1
                stats.orphanBytes += record.sizeBytes
                stats.orphanDurationSeconds += record.duration
            }

            if let createdAt = record.createdAt,
               stats.latestSampleCreatedAt == nil || createdAt > stats.latestSampleCreatedAt! {
                stats.latestSampleCreatedAt = createdAt
            }
        }

        return stats
    }

    public func cleanupOrphanSnippets(linkedFileNames: Set<String>) -> EventAudioCleanupResult {
        var result = EventAudioCleanupResult()

        for record in snippetFileRecords() where !linkedFileNames.contains(record.fileName) {
            do {
                try fileManager.removeItem(at: record.url)
                result.deletedFileCount += 1
                result.deletedBytes += record.sizeBytes
            } catch {
                result.failedFileCount += 1
            }
        }

        return result
    }

    public func folderSizeBytes() -> Int64 {
        guard let enumerator = fileManager.enumerator(
            at: snippetsDirectory,
            includingPropertiesForKeys: [.fileSizeKey],
            options: [.skipsHiddenFiles]
        ) else {
            return 0
        }

        var total: Int64 = 0
        for case let fileURL as URL in enumerator {
            guard fileURL.pathExtension.lowercased() == "caf" else { continue }
            let size = (try? fileURL.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0
            total += Int64(size)
        }
        return total
    }

    public func pruneExpiredSnippets(now: Date = Date()) throws {
        let cutoff = now.addingTimeInterval(-policy.maxSnippetAge)
        for fileURL in try snippetFiles() {
            let modifiedAt = (try? fileURL.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate)
                ?? .distantFuture
            if modifiedAt < cutoff {
                try? fileManager.removeItem(at: fileURL)
            }
        }
    }

    private func snippetFiles() throws -> [URL] {
        guard fileManager.fileExists(atPath: snippetsDirectory.path) else { return [] }
        return try fileManager.contentsOfDirectory(
            at: snippetsDirectory,
            includingPropertiesForKeys: [.contentModificationDateKey, .fileSizeKey]
        )
        .filter { $0.pathExtension.lowercased() == "caf" }
    }

    private func snippetFileRecords() -> [SnippetFileRecord] {
        let files = (try? snippetFiles()) ?? []
        return files.compactMap { fileURL in
            let values = try? fileURL.resourceValues(forKeys: [
                .fileSizeKey,
                .creationDateKey,
                .contentModificationDateKey
            ])
            let sizeBytes = Int64(values?.fileSize ?? 0)
            let createdAt = values?.creationDate ?? values?.contentModificationDate
            return SnippetFileRecord(
                url: fileURL,
                fileName: fileURL.lastPathComponent,
                sizeBytes: max(0, sizeBytes),
                duration: audioDuration(at: fileURL),
                createdAt: createdAt
            )
        }
    }

    private func audioDuration(at url: URL) -> TimeInterval {
        guard let audioFile = try? AVAudioFile(forReading: url) else {
            return 0
        }

        let sampleRate = audioFile.fileFormat.sampleRate
        guard sampleRate.isFinite, sampleRate > 0 else {
            return 0
        }

        return max(0, Double(audioFile.length) / sampleRate)
    }

    private func extractSamples(
        from chunks: [AudioChunk],
        targetStart: Date,
        targetEnd: Date
    ) -> (samples: [Float], sampleRate: Double, firstSampleAt: Date) {
        var samples: [Float] = []
        var sampleRate = 0.0
        var firstSampleAt: Date?

        for chunk in chunks.sorted(by: { $0.startedAt < $1.startedAt }) {
            guard !chunk.samples.isEmpty, chunk.sampleRate > 0, chunk.duration > 0 else { continue }

            let chunkStart = chunk.startedAt
            let chunkEnd = chunkStart.addingTimeInterval(chunk.duration)
            guard chunkEnd > targetStart, chunkStart < targetEnd else { continue }

            let overlapStart = maxDate(targetStart, chunkStart)
            let overlapEnd = minDate(targetEnd, chunkEnd)
            guard overlapEnd > overlapStart else { continue }

            let startRatio = overlapStart.timeIntervalSince(chunkStart) / chunk.duration
            let endRatio = overlapEnd.timeIntervalSince(chunkStart) / chunk.duration
            let startIndex = min(max(0, Int((startRatio * Double(chunk.samples.count)).rounded(.down))), chunk.samples.count)
            let endIndex = min(max(startIndex, Int((endRatio * Double(chunk.samples.count)).rounded(.up))), chunk.samples.count)

            guard endIndex > startIndex else { continue }

            if sampleRate == 0 {
                sampleRate = chunk.sampleRate
            }
            if firstSampleAt == nil {
                firstSampleAt = overlapStart
            }
            samples.append(contentsOf: chunk.samples[startIndex..<endIndex])
        }

        return (samples, sampleRate, firstSampleAt ?? targetStart)
    }

    private func writeCAF(samples: [Float], sampleRate: Double, to url: URL) throws {
        guard let format = AVAudioFormat(
            commonFormat: .pcmFormatFloat32,
            sampleRate: sampleRate,
            channels: 1,
            interleaved: false
        ),
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(samples.count)),
        let channelData = buffer.floatChannelData else {
            throw EventAudioSnippetStoreError.invalidFormat
        }

        buffer.frameLength = AVAudioFrameCount(samples.count)
        samples.withUnsafeBufferPointer { pointer in
            channelData[0].update(from: pointer.baseAddress!, count: samples.count)
        }

        try fileManager.createDirectory(at: snippetsDirectory, withIntermediateDirectories: true)
        let file = try AVAudioFile(forWriting: url, settings: format.settings)
        try file.write(from: buffer)
    }

    private func makeFileName(
        sessionId: UUID,
        eventType: SleepEventType,
        eventStartedAt: Date
    ) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let timestamp = formatter.string(from: eventStartedAt)
            .replacingOccurrences(of: ":", with: "")
            .replacingOccurrences(of: ".", with: "-")
        return "\(timestamp)_\(sessionId.uuidString.prefix(8))_\(eventType.rawValue).caf"
    }

    #if DEBUG
    private func makeDebugPreviewFileName(sessionId: UUID, createdAt: Date) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let timestamp = formatter.string(from: createdAt)
            .replacingOccurrences(of: ":", with: "")
            .replacingOccurrences(of: ".", with: "-")
        return "debug-preview_\(timestamp)_\(sessionId.uuidString).caf"
    }
    #endif

    private func maxDate(_ lhs: Date, _ rhs: Date) -> Date {
        lhs >= rhs ? lhs : rhs
    }

    private func minDate(_ lhs: Date, _ rhs: Date) -> Date {
        lhs <= rhs ? lhs : rhs
    }
}

private struct SnippetFileRecord {
    var url: URL
    var fileName: String
    var sizeBytes: Int64
    var duration: TimeInterval
    var createdAt: Date?

    var isDebugPreview: Bool {
        fileName.hasPrefix("debug-preview_")
    }

    func belongsToSession(id sessionId: UUID) -> Bool {
        let fullID = sessionId.uuidString
        let shortID = String(fullID.prefix(8))
        return fileName.contains(fullID) || fileName.contains(shortID)
    }
}

private extension EventAudioSnippetFileRecord {
    init(_ record: SnippetFileRecord) {
        self.init(
            url: record.url,
            fileName: record.fileName,
            sizeBytes: record.sizeBytes,
            duration: record.duration,
            createdAt: record.createdAt
        )
    }
}
