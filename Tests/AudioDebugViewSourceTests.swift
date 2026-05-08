import Foundation
import Testing

@Suite("Audio Debug View Source")
struct AudioDebugViewSourceTests {
    @Test
    func liveDebugFeatureSummariesUseBoundedStorage() throws {
        let source = try read("SleepSoundApp/Features/Settings/AudioDebugView.swift")

        #expect(source.contains("AudioDebugValueSampler"))
        #expect(source.contains("maxStoredValueCount: 7_200"))
        #expect(source.contains("maxDebugRawOutputCount = 720"))
        #expect(source.contains("trimRawOutputsForLiveDebug()"))
        #expect(source.contains("SummaryStats.make(values: values, totalCount: observedValueCount)"))
        #expect(!source.contains("private var rmsValues: [Double]"))
        #expect(!source.contains("private var energyValues: [Double]"))
        #expect(!source.contains("private var lowBandValues: [Double]"))
    }

    @Test
    func liveDebugUsesSharedSnoreLikeFeatureObserver() throws {
        let source = try read("SleepSoundApp/Features/Settings/AudioDebugView.swift")

        #expect(source.contains("SnoreLikeFeatureObserver.observe"))
        #expect(!source.contains("private func snoreLikeFeatureObservation"))
        #expect(!source.contains("private func isDistantLowInputSnoreLikeHint"))
    }

    private func read(_ relativePath: String) throws -> String {
        let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        return try String(contentsOf: root.appendingPathComponent(relativePath), encoding: .utf8)
    }
}
