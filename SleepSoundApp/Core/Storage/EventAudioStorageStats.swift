import Foundation

public struct EventAudioStorageStats: Equatable, Sendable {
    public static let empty = EventAudioStorageStats()

    public var sampleCount: Int
    public var linkedSampleCount: Int
    public var orphanSampleCount: Int
    public var totalBytes: Int64
    public var linkedBytes: Int64
    public var orphanBytes: Int64
    public var totalDurationSeconds: TimeInterval
    public var linkedDurationSeconds: TimeInterval
    public var orphanDurationSeconds: TimeInterval
    public var latestSampleCreatedAt: Date?

    public init(
        sampleCount: Int = 0,
        linkedSampleCount: Int = 0,
        orphanSampleCount: Int = 0,
        totalBytes: Int64 = 0,
        linkedBytes: Int64 = 0,
        orphanBytes: Int64 = 0,
        totalDurationSeconds: TimeInterval = 0,
        linkedDurationSeconds: TimeInterval = 0,
        orphanDurationSeconds: TimeInterval = 0,
        latestSampleCreatedAt: Date? = nil
    ) {
        self.sampleCount = max(0, sampleCount)
        self.linkedSampleCount = max(0, linkedSampleCount)
        self.orphanSampleCount = max(0, orphanSampleCount)
        self.totalBytes = max(0, totalBytes)
        self.linkedBytes = max(0, linkedBytes)
        self.orphanBytes = max(0, orphanBytes)
        self.totalDurationSeconds = max(0, totalDurationSeconds)
        self.linkedDurationSeconds = max(0, linkedDurationSeconds)
        self.orphanDurationSeconds = max(0, orphanDurationSeconds)
        self.latestSampleCreatedAt = latestSampleCreatedAt
    }

    public var formattedTotalSize: String {
        Self.formatBytes(totalBytes)
    }

    public var formattedLinkedSize: String {
        Self.formatBytes(linkedBytes)
    }

    public var formattedOrphanSize: String {
        Self.formatBytes(orphanBytes)
    }

    public static func formatBytes(_ bytes: Int64) -> String {
        let safeBytes = max(0, bytes)
        if safeBytes < 1_024 {
            return "\(safeBytes)B"
        }

        let kilobytes = Double(safeBytes) / 1_024
        if kilobytes < 1_024 {
            return "\(Int(kilobytes.rounded()))KB"
        }

        let megabytes = kilobytes / 1_024
        if megabytes < 1_024 {
            return String(format: "%.2fMB", megabytes)
        }

        let gigabytes = megabytes / 1_024
        return String(format: "%.2fGB", gigabytes)
    }
}

public struct EventAudioCleanupResult: Equatable, Sendable {
    public var deletedFileCount: Int
    public var deletedBytes: Int64
    public var failedFileCount: Int

    public init(
        deletedFileCount: Int = 0,
        deletedBytes: Int64 = 0,
        failedFileCount: Int = 0
    ) {
        self.deletedFileCount = max(0, deletedFileCount)
        self.deletedBytes = max(0, deletedBytes)
        self.failedFileCount = max(0, failedFileCount)
    }

    public var formattedDeletedSize: String {
        EventAudioStorageStats.formatBytes(deletedBytes)
    }
}
