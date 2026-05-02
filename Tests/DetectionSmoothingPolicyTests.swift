import Foundation
import Testing
@testable import SleepSoundCore

@Suite("DetectionSmoothingPolicy")
struct DetectionSmoothingPolicyTests {
    @Test
    func filtersShortAndLowConfidenceOutputs() {
        let start = Date(timeIntervalSince1970: 0)
        let policy = DetectionSmoothingPolicy(
            minimumEventDuration: 1,
            maximumMergeGap: 0.5,
            confidenceThreshold: 0.5
        )

        let outputs = policy.apply(to: [
            makeOutput(.snore, start: start, duration: 0.2, confidence: 0.8),
            makeOutput(.snore, start: start.addingTimeInterval(2), duration: 1.5, confidence: 0.2),
            makeOutput(.snore, start: start.addingTimeInterval(4), duration: 1.5, confidence: 0.8)
        ])

        #expect(outputs.count == 1)
        #expect(outputs.first?.startedAt == start.addingTimeInterval(4))
    }

    @Test
    func mergesCloseSameTypeEvents() {
        let start = Date(timeIntervalSince1970: 0)
        let policy = DetectionSmoothingPolicy(
            minimumEventDuration: 0.1,
            maximumMergeGap: 1,
            confidenceThreshold: 0.1
        )

        let outputs = policy.apply(to: [
            makeOutput(.snore, start: start, duration: 1, confidence: 0.6),
            makeOutput(.snore, start: start.addingTimeInterval(1.5), duration: 1, confidence: 0.8)
        ])

        #expect(outputs.count == 1)
        #expect(outputs.first?.eventType == .snore)
        #expect(outputs.first?.duration == 2.5)
        #expect(outputs.first?.confidence == 0.8)
    }

    @Test
    func keepsDifferentTypesSeparate() {
        let start = Date(timeIntervalSince1970: 0)
        let policy = DetectionSmoothingPolicy(
            minimumEventDuration: 0.1,
            maximumMergeGap: 1,
            confidenceThreshold: 0.1
        )

        let outputs = policy.apply(to: [
            makeOutput(.snore, start: start, duration: 1, confidence: 0.6),
            makeOutput(.coughLike, start: start.addingTimeInterval(1.2), duration: 1, confidence: 0.8)
        ])

        #expect(outputs.count == 2)
    }

    @Test
    func sleepAnalyzerUsesDetectorProtocolAndSmoothingPolicy() {
        let session = SleepSession(startedAt: Date(timeIntervalSince1970: 0))
        let chunk = AudioChunk(
            samples: [0.1, 0.1],
            sampleRate: 16_000,
            startedAt: Date(timeIntervalSince1970: 10),
            duration: 1
        )
        let analyzer = SleepAnalyzer(
            extractor: StubExtractor(),
            detector: StubDetector(),
            smoothingPolicy: DetectionSmoothingPolicy(
                minimumEventDuration: 0.1,
                maximumMergeGap: 1,
                confidenceThreshold: 0.1
            )
        )

        let events = analyzer.analyze(session: session, chunks: [chunk])

        #expect(events.count == 1)
        #expect(events.first?.sessionId == session.id)
        #expect(events.first?.type == .snore)
    }

    private func makeOutput(
        _ type: SleepEventType,
        start: Date,
        duration: TimeInterval,
        confidence: Double
    ) -> DetectorOutput {
        DetectorOutput(
            eventType: type,
            startedAt: start,
            endedAt: start.addingTimeInterval(duration),
            confidence: confidence,
            intensity: 0.5
        )
    }
}

private struct StubExtractor: AudioFeatureExtracting {
    func extractFeatures(from chunk: AudioChunk) -> AudioFeatures {
        AudioFeatures(
            startedAt: chunk.startedAt,
            duration: chunk.duration,
            rms: 0.1,
            peak: 0.1,
            zeroCrossingRate: 0.1,
            lowFrequencyEnergyRatio: 0.8
        )
    }
}

private struct StubDetector: SleepEventDetector {
    func detect(features: AudioFeatures) -> [DetectorOutput] {
        [
            DetectorOutput(
                eventType: .snore,
                startedAt: features.startedAt,
                endedAt: features.endedAt,
                confidence: 0.8,
                intensity: 0.5,
                debugReason: "stub"
            )
        ]
    }
}
