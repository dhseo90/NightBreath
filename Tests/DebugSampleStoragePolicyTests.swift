import Foundation
import Testing
@testable import SleepSoundCore

@Suite("DebugSampleStoragePolicy")
struct DebugSampleStoragePolicyTests {
    @Test
    func rejectsSamplesLongerThanFiveSeconds() throws {
        let root = makeTemporaryDirectory()
        let policy = DebugSampleStoragePolicy(
            maxSampleDuration: 5,
            minimumAvailableDiskSpaceBytes: 1
        )

        #expect(throws: DebugSampleStorageError.sampleDurationTooLong(maxSeconds: 5)) {
            try policy.validateBeforeSaving(
                duration: 5.1,
                sessionSampleCount: 0,
                estimatedAdditionalBytes: 0,
                samplesDirectory: root
            )
        }

        try? FileManager.default.removeItem(at: root)
    }

    @Test
    func rejectsWhenSessionSampleLimitIsReached() throws {
        let root = makeTemporaryDirectory()
        let policy = DebugSampleStoragePolicy(
            maxSamplesPerSession: 100,
            minimumAvailableDiskSpaceBytes: 1
        )

        #expect(throws: DebugSampleStorageError.sessionSampleLimitReached(maxSamples: 100)) {
            try policy.validateBeforeSaving(
                duration: 2,
                sessionSampleCount: 100,
                estimatedAdditionalBytes: 0,
                samplesDirectory: root
            )
        }

        try? FileManager.default.removeItem(at: root)
    }

    @Test
    func rejectsWhenFolderSizeLimitWouldBeExceeded() throws {
        let root = makeTemporaryDirectory()
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        let existingSample = root.appendingPathComponent("old.caf")
        try Data(repeating: 1, count: 80).write(to: existingSample)
        let policy = DebugSampleStoragePolicy(
            maxFolderSizeBytes: 100,
            minimumAvailableDiskSpaceBytes: 1
        )

        #expect(throws: DebugSampleStorageError.folderSizeLimitExceeded(maxBytes: 100)) {
            try policy.validateBeforeSaving(
                duration: 2,
                sessionSampleCount: 0,
                estimatedAdditionalBytes: 30,
                samplesDirectory: root
            )
        }

        try? FileManager.default.removeItem(at: root)
    }

    @Test
    func prunesSamplesOlderThanSevenDaysWithMetadata() throws {
        let root = makeTemporaryDirectory()
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        let audioURL = root.appendingPathComponent("expired_snore.caf")
        let metadataURL = root.appendingPathComponent("expired_snore.metadata.json")
        let csvURL = root.appendingPathComponent("expired_snore.features.csv")
        try Data([1]).write(to: audioURL)
        try Data([2]).write(to: metadataURL)
        try Data([3]).write(to: csvURL)

        let oldDate = Date(timeIntervalSince1970: 1_700_000_000)
        try FileManager.default.setAttributes([.modificationDate: oldDate], ofItemAtPath: audioURL.path)
        let policy = DebugSampleStoragePolicy(
            maxSampleAge: 7 * 24 * 60 * 60,
            minimumAvailableDiskSpaceBytes: 1
        )
        let removed = try policy.pruneExpiredSamples(
            in: root,
            now: oldDate.addingTimeInterval(8 * 24 * 60 * 60)
        )

        #expect(removed == 1)
        #expect(!FileManager.default.fileExists(atPath: audioURL.path))
        #expect(!FileManager.default.fileExists(atPath: metadataURL.path))
        #expect(!FileManager.default.fileExists(atPath: csvURL.path))

        try? FileManager.default.removeItem(at: root)
    }

    @Test
    func statusKeepsFullNightRawAudioDisabled() throws {
        let root = makeTemporaryDirectory()
        let policy = DebugSampleStoragePolicy.default
        let status = policy.storageStatus(in: root)

        #expect(status.fullNightRawAudioStorageEnabled == false)
    }

    private func makeTemporaryDirectory() -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent("NightBreathDebugSamplePolicyTests-\(UUID().uuidString)", isDirectory: true)
    }
}
