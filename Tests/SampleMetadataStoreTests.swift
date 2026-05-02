import Foundation
import Testing
@testable import SleepSoundCore

@Suite("SampleMetadataStore")
struct SampleMetadataStoreTests {
    @Test
    func savesMetadataJSONAndFeatureCSV() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("NightBreathSampleMetadataStoreTests-\(UUID().uuidString)", isDirectory: true)
        let store = SampleMetadataStore(samplesDirectory: root)
        let capturedAt = Date(timeIntervalSince1970: 1_700_000_000)
        let baseName = store.makeFileBaseName(capturedAt: capturedAt, label: .snore)
        let features = AudioFeatures(
            startedAt: capturedAt,
            duration: 2,
            rms: 0.12,
            energy: 0.0144,
            peak: 0.2,
            zeroCrossingRate: 0.1,
            lowFrequencyEnergyRatio: 0.7,
            spectralCentroid: 180,
            lowBandEnergy: 0.7,
            midBandEnergy: 0.2,
            highBandEnergy: 0.1,
            estimatedNoiseLevel: 0.1
        )
        let metadata = LabeledAudioSample(
            label: .snore,
            capturedAt: capturedAt,
            features: features,
            notes: "synthetic test",
            appVersion: "test",
            deviceModel: "unit-test",
            audioFileName: baseName + ".caf",
            metadataFileName: store.metadataFileName(fileBaseName: baseName),
            featureCSVFileName: store.featureCSVFileName(fileBaseName: baseName)
        )

        let saved = try store.save(metadata: metadata, features: features)

        #expect(FileManager.default.fileExists(atPath: saved.metadataURL.path))
        #expect(FileManager.default.fileExists(atPath: saved.featureCSVURL.path))
        #expect(saved.audioURL.lastPathComponent == baseName + ".caf")

        let metadataData = try Data(contentsOf: saved.metadataURL)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(LabeledAudioSample.self, from: metadataData)

        #expect(decoded.label == .snore)
        #expect(decoded.notes == "synthetic test")
        #expect(decoded.audioFileName == baseName + ".caf")

        let csv = try String(contentsOf: saved.featureCSVURL, encoding: .utf8)
        #expect(csv.contains("timestamp,label,rms,energy"))
        #expect(csv.contains("snore"))

        try? FileManager.default.removeItem(at: root)
    }

    @Test
    func fileBaseNameIncludesTimestampAndLabel() {
        let store = SampleMetadataStore(samplesDirectory: URL(fileURLWithPath: "/tmp/samples"))
        let capturedAt = Date(timeIntervalSince1970: 1_779_984_900)
        let baseName = store.makeFileBaseName(capturedAt: capturedAt, label: .coughLike)

        #expect(baseName.contains("_coughLike"))
        #expect(!baseName.contains(":"))
    }
}
