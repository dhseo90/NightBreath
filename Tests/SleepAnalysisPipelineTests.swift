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
    func lowLevelSnoreLikeCandidateSurvivesSmoothingAndReportAggregation() {
        let startedAt = Date(timeIntervalSince1970: 1_772_010_000)
        let session = SleepSession(
            startedAt: startedAt,
            endedAt: startedAt.addingTimeInterval(300),
            measurementDuration: 300,
            estimatedSleepDuration: 300
        )
        let analyzer = DetectorTuningProfile.balanced.configuration.makeSleepAnalyzer(backend: .ruleBased)
        let chunks = (0..<3).map { index in
            snoreLikeSineChunk(
                startedAt: startedAt.addingTimeInterval(TimeInterval(index)),
                duration: 1,
                amplitude: 0.065
            )
        }

        let rawOutputs = analyzer.detectOutputs(from: chunks)
        let smoothedOutputs = analyzer.smooth(outputs: rawOutputs)
        let events = analyzer.makeEvents(session: session, outputs: smoothedOutputs)
        let report = SleepScoreCalculator().makeReport(session: session, events: events)

        #expect(rawOutputs.contains { $0.eventType == .snore })
        #expect(smoothedOutputs.contains { $0.eventType == .snore })
        #expect(events.contains { $0.type == .snore })
        #expect(report.snoreTotalSeconds > 0)
    }

    @Test
    func distantLowLevelSnoreLikePatternSurvivesBalancedSmoothing() {
        let startedAt = Date(timeIntervalSince1970: 1_772_011_000)
        let session = SleepSession(
            startedAt: startedAt,
            endedAt: startedAt.addingTimeInterval(300),
            measurementDuration: 300,
            estimatedSleepDuration: 300
        )
        let analyzer = DetectorTuningProfile.balanced.configuration.makeSleepAnalyzer(backend: .ruleBased)
        let chunks = (0..<3).map { index in
            snoreLikeSineChunk(
                startedAt: startedAt.addingTimeInterval(TimeInterval(index)),
                duration: 1,
                amplitude: 0.042
            )
        }

        let rawOutputs = analyzer.detectOutputs(from: chunks)
        let smoothingResult = analyzer.smoothWithDiagnostics(outputs: rawOutputs)
        let events = analyzer.makeEvents(session: session, outputs: smoothingResult.outputs)

        #expect(rawOutputs.filter { $0.eventType == .snore }.count >= 3)
        #expect(smoothingResult.outputs.contains { $0.eventType == .snore })
        #expect(smoothingResult.diagnostics.postSmoothingEventCountByType[.snore] == 1)
        #expect(events.contains { $0.type == .snore })
    }

    @Test
    func quietAndNoiseNegativesDoNotBecomeSnoreEvents() {
        let startedAt = Date(timeIntervalSince1970: 1_772_020_000)
        let analyzer = DetectorTuningProfile.balanced.configuration.makeSleepAnalyzer(backend: .ruleBased)
        let negativeChunks = SyntheticAudioSource.makeChunks(
            pattern: .silence,
            duration: 3,
            sampleRate: 16_000,
            chunkDuration: 1,
            startedAt: startedAt
        ) + SyntheticAudioSource.makeChunks(
            pattern: .lowEnergyNoise,
            duration: 3,
            sampleRate: 16_000,
            chunkDuration: 1,
            startedAt: startedAt.addingTimeInterval(3)
        ) + [
            highFrequencySineChunk(
                startedAt: startedAt.addingTimeInterval(6),
                duration: 1,
                amplitude: 0.065
            )
        ]

        let outputs = analyzer.analyze(chunks: negativeChunks)

        #expect(!outputs.contains { $0.eventType == .snore })
    }

    @Test
    func lowAudioCoverageDoesNotInventSnoreInReport() {
        let startedAt = Date(timeIntervalSince1970: 1_772_030_000)
        let session = SleepSession(
            startedAt: startedAt,
            endedAt: startedAt.addingTimeInterval(300),
            measurementDuration: 300,
            estimatedSleepDuration: 300
        )
        let metrics = AudioCaptureMetrics(
            captureStartedAt: startedAt,
            captureStoppedAt: startedAt.addingTimeInterval(300),
            receivedAudioSeconds: 3,
            analyzedAudioSeconds: 3,
            receivedChunkCount: 3,
            analyzedChunkCount: 3,
            audioCoverageRatio: 0.01
        )

        let report = SleepScoreCalculator().makeReport(
            session: session,
            events: [],
            captureMetrics: metrics
        )

        #expect(report.measurementQuality == .poor)
        #expect(report.snoreTotalSeconds == 0)
        #expect(report.snoreRatio == 0)
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

    private func snoreLikeSineChunk(
        startedAt: Date,
        duration: TimeInterval,
        amplitude: Double
    ) -> AudioChunk {
        sineChunk(
            frequency: 120,
            amplitude: amplitude,
            startedAt: startedAt,
            duration: duration
        )
    }

    private func highFrequencySineChunk(
        startedAt: Date,
        duration: TimeInterval,
        amplitude: Double
    ) -> AudioChunk {
        sineChunk(
            frequency: 3_200,
            amplitude: amplitude,
            startedAt: startedAt,
            duration: duration
        )
    }

    private func sineChunk(
        frequency: Double,
        amplitude: Double,
        startedAt: Date,
        duration: TimeInterval
    ) -> AudioChunk {
        let sampleRate = 16_000.0
        let frameCount = max(1, Int((duration * sampleRate).rounded()))
        let samples = (0..<frameCount).map { frame -> Float in
            let t = Double(frame) / sampleRate
            return Float(sin(2 * Double.pi * frequency * t) * amplitude)
        }

        return AudioChunk(
            samples: samples,
            sampleRate: sampleRate,
            startedAt: startedAt,
            duration: duration
        )
    }
}
