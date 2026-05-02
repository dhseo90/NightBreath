import Foundation

public struct DebugSampleStorageStatus: Equatable, Sendable {
    public var sampleCount: Int
    public var folderSizeBytes: Int64
    public var lastSampleSavedAt: Date?
    public var availableDiskSpaceBytes: Int64?
    public var fullNightRawAudioStorageEnabled: Bool

    public init(
        sampleCount: Int = 0,
        folderSizeBytes: Int64 = 0,
        lastSampleSavedAt: Date? = nil,
        availableDiskSpaceBytes: Int64? = nil,
        fullNightRawAudioStorageEnabled: Bool = false
    ) {
        self.sampleCount = max(0, sampleCount)
        self.folderSizeBytes = max(0, folderSizeBytes)
        self.lastSampleSavedAt = lastSampleSavedAt
        self.availableDiskSpaceBytes = availableDiskSpaceBytes
        self.fullNightRawAudioStorageEnabled = fullNightRawAudioStorageEnabled
    }
}

public enum DebugSampleStorageError: LocalizedError, Equatable, Sendable {
    case sampleDurationTooLong(maxSeconds: TimeInterval)
    case sessionSampleLimitReached(maxSamples: Int)
    case folderSizeLimitExceeded(maxBytes: Int64)
    case insufficientDiskSpace(requiredBytes: Int64, availableBytes: Int64)
    case fullNightRawAudioStorageDisabled

    public var errorDescription: String? {
        switch self {
        case .sampleDurationTooLong(let maxSeconds):
            return "DEBUG 샘플은 최대 \(Int(maxSeconds))초까지만 저장할 수 있습니다."
        case .sessionSampleLimitReached(let maxSamples):
            return "이번 앱 실행 중 저장 가능한 DEBUG 샘플 수 \(maxSamples)개에 도달했습니다."
        case .folderSizeLimitExceeded(let maxBytes):
            return "DEBUG 샘플 폴더 용량 제한 \(Self.formatBytes(maxBytes))에 도달했습니다."
        case .insufficientDiskSpace(_, let availableBytes):
            return "디스크 여유 공간이 부족해 DEBUG 샘플을 저장하지 않았습니다. 현재 여유 공간: \(Self.formatBytes(availableBytes))"
        case .fullNightRawAudioStorageDisabled:
            return "전체 밤 원본 오디오 저장은 비활성화되어 있습니다."
        }
    }

    private static func formatBytes(_ bytes: Int64) -> String {
        ByteCountFormatter.string(fromByteCount: bytes, countStyle: .file)
    }
}

public struct DebugSampleStoragePolicy: Equatable, Sendable {
    public static let `default` = DebugSampleStoragePolicy()

    public var maxSampleDuration: TimeInterval
    public var maxSamplesPerSession: Int
    public var maxFolderSizeBytes: Int64
    public var maxSampleAge: TimeInterval
    public var minimumAvailableDiskSpaceBytes: Int64
    public var fullNightRawAudioStorageEnabled: Bool

    public init(
        maxSampleDuration: TimeInterval = 5,
        maxSamplesPerSession: Int = 100,
        maxFolderSizeBytes: Int64 = 200 * 1_024 * 1_024,
        maxSampleAge: TimeInterval = 7 * 24 * 60 * 60,
        minimumAvailableDiskSpaceBytes: Int64 = 200 * 1_024 * 1_024,
        fullNightRawAudioStorageEnabled: Bool = false
    ) {
        self.maxSampleDuration = max(1, maxSampleDuration)
        self.maxSamplesPerSession = max(1, maxSamplesPerSession)
        self.maxFolderSizeBytes = max(1, maxFolderSizeBytes)
        self.maxSampleAge = max(60, maxSampleAge)
        self.minimumAvailableDiskSpaceBytes = max(1, minimumAvailableDiskSpaceBytes)
        self.fullNightRawAudioStorageEnabled = fullNightRawAudioStorageEnabled
    }

    public func clampedSampleDuration(_ duration: TimeInterval) -> TimeInterval {
        min(max(duration.isFinite ? duration : 1, 1), maxSampleDuration)
    }

    public func validateBeforeSaving(
        duration: TimeInterval,
        sessionSampleCount: Int,
        estimatedAdditionalBytes: Int64,
        samplesDirectory: URL,
        fileManager: FileManager = .default,
        now: Date = Date()
    ) throws -> DebugSampleStorageStatus {
        guard !fullNightRawAudioStorageEnabled else {
            throw DebugSampleStorageError.fullNightRawAudioStorageDisabled
        }

        guard duration <= maxSampleDuration else {
            throw DebugSampleStorageError.sampleDurationTooLong(maxSeconds: maxSampleDuration)
        }

        guard sessionSampleCount < maxSamplesPerSession else {
            throw DebugSampleStorageError.sessionSampleLimitReached(maxSamples: maxSamplesPerSession)
        }

        try pruneExpiredSamples(in: samplesDirectory, fileManager: fileManager, now: now)

        let status = storageStatus(in: samplesDirectory, fileManager: fileManager)
        if status.folderSizeBytes + max(0, estimatedAdditionalBytes) > maxFolderSizeBytes {
            throw DebugSampleStorageError.folderSizeLimitExceeded(maxBytes: maxFolderSizeBytes)
        }

        if let available = status.availableDiskSpaceBytes,
           available < minimumAvailableDiskSpaceBytes + max(0, estimatedAdditionalBytes) {
            throw DebugSampleStorageError.insufficientDiskSpace(
                requiredBytes: minimumAvailableDiskSpaceBytes,
                availableBytes: available
            )
        }

        return status
    }

    @discardableResult
    public func pruneExpiredSamples(
        in samplesDirectory: URL,
        fileManager: FileManager = .default,
        now: Date = Date()
    ) throws -> Int {
        guard fileManager.fileExists(atPath: samplesDirectory.path) else { return 0 }

        let cutoff = now.addingTimeInterval(-maxSampleAge)
        let audioFiles = try fileManager.contentsOfDirectory(
            at: samplesDirectory,
            includingPropertiesForKeys: [.contentModificationDateKey],
            options: [.skipsHiddenFiles]
        )
        .filter { $0.pathExtension.lowercased() == "caf" }

        var removedCount = 0
        for audioURL in audioFiles {
            let modifiedAt = try audioURL.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate
                ?? .distantFuture
            guard modifiedAt < cutoff else { continue }

            let baseName = audioURL.deletingPathExtension().lastPathComponent
            let relatedURLs = [
                audioURL,
                samplesDirectory.appendingPathComponent(baseName + ".metadata.json"),
                samplesDirectory.appendingPathComponent(baseName + ".features.csv")
            ]

            for url in relatedURLs where fileManager.fileExists(atPath: url.path) {
                try? fileManager.removeItem(at: url)
            }
            removedCount += 1
        }

        return removedCount
    }

    public func storageStatus(
        in samplesDirectory: URL,
        fileManager: FileManager = .default
    ) -> DebugSampleStorageStatus {
        let availableBytes = availableDiskSpaceBytes(for: samplesDirectory, fileManager: fileManager)
        guard fileManager.fileExists(atPath: samplesDirectory.path),
              let files = try? fileManager.contentsOfDirectory(
                at: samplesDirectory,
                includingPropertiesForKeys: [.fileSizeKey, .contentModificationDateKey],
                options: [.skipsHiddenFiles]
              ) else {
            return DebugSampleStorageStatus(
                availableDiskSpaceBytes: availableBytes,
                fullNightRawAudioStorageEnabled: fullNightRawAudioStorageEnabled
            )
        }

        var folderSizeBytes: Int64 = 0
        var sampleCount = 0
        var lastSampleSavedAt: Date?

        for file in files {
            let values = try? file.resourceValues(forKeys: [.fileSizeKey, .contentModificationDateKey])
            folderSizeBytes += Int64(values?.fileSize ?? 0)

            if file.pathExtension.lowercased() == "caf" {
                sampleCount += 1
                if let modifiedAt = values?.contentModificationDate,
                   lastSampleSavedAt.map({ modifiedAt > $0 }) ?? true {
                    lastSampleSavedAt = modifiedAt
                }
            }
        }

        return DebugSampleStorageStatus(
            sampleCount: sampleCount,
            folderSizeBytes: folderSizeBytes,
            lastSampleSavedAt: lastSampleSavedAt,
            availableDiskSpaceBytes: availableBytes,
            fullNightRawAudioStorageEnabled: fullNightRawAudioStorageEnabled
        )
    }

    private func availableDiskSpaceBytes(
        for samplesDirectory: URL,
        fileManager: FileManager
    ) -> Int64? {
        let probeURL = fileManager.fileExists(atPath: samplesDirectory.path)
            ? samplesDirectory
            : samplesDirectory.deletingLastPathComponent()

        guard let values = try? probeURL.resourceValues(forKeys: [.volumeAvailableCapacityForImportantUsageKey]),
              let capacity = values.volumeAvailableCapacityForImportantUsage else {
            return nil
        }

        return max(0, capacity)
    }
}
