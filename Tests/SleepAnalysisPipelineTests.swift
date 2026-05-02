import Foundation
import Testing
@testable import SleepSoundCore

@Suite("SleepAnalysisPipeline")
struct SleepAnalysisPipelineTests {
    @Test
    func capturedChunksFlowThroughAnalyzerSmoothingAndReport() {
        let startedAt = Date(timeIntervalSince1970: 1_772_000_000)
        let session = SleepSession(
            startedAt: startedAt,
            endedAt: startedAt.addingTimeInterval(8 * 60 * 60),
            measurementDuration: 8 * 60 * 60,
            estimatedSleepDuration: 7 * 60 * 60
        )
        let analyzer = SleepAnalyzer(
            smoothingPolicy: DetectionSmoothingPolicy(
                minimumEventDuration: 0.2,
                maximumMergeGap: 1,
                confidenceThreshold: 0.35
            )
        )
        let chunks = [
            snoreLikeChunk(startedAt: startedAt.addingTimeInterval(60), duration: 1),
            snoreLikeChunk(startedAt: startedAt.addingTimeInterval(61.5), duration: 1)
        ]

        let outputs = analyzer.analyze(chunks: chunks)
        let events = analyzer.analyze(session: session, chunks: chunks)
        let report = analyzer.makeReport(session: session, chunks: chunks)

        #expect(outputs.count == 1)
        #expect(outputs.first?.eventType == .snore)
        #expect(events.count == 1)
        #expect(events.first?.sessionId == session.id)
        #expect(events.first?.type == .snore)
        #expect(abs(report.snoreTotalSeconds - 2.5) < 0.0001)
        #expect(report.sleepSoundScore >= 0)
        #expect(report.sleepSoundScore <= 100)
    }

    @Test
    func detectorOutputMapperPreservesEventFields() {
        let sessionId = UUID()
        let startedAt = Date(timeIntervalSince1970: 100)
        let output = DetectorOutput(
            eventType: .coughLike,
            startedAt: startedAt,
            endedAt: startedAt.addingTimeInterval(2),
            confidence: 1.2,
            intensity: 0.4,
            debugReason: "mapper test"
        )

        let event = DetectorOutputMapper.makeEvent(from: output, sessionId: sessionId)

        #expect(event.sessionId == sessionId)
        #expect(event.type == .coughLike)
        #expect(event.startedAt == output.startedAt)
        #expect(event.endedAt == output.endedAt)
        #expect(event.confidence == 1)
        #expect(event.intensity == 0.4)
    }

    private func snoreLikeChunk(startedAt: Date, duration: TimeInterval) -> AudioChunk {
        AudioChunk(
            samples: Array(repeating: 0.08, count: 256),
            sampleRate: 16_000,
            startedAt: startedAt,
            duration: duration
        )
    }
}
