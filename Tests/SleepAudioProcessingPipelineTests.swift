import Foundation
import Testing
@testable import SleepSoundCore

@Suite("SleepAudioProcessingPipeline")
struct SleepAudioProcessingPipelineTests {
    @Test
    func pipelineCompactsContinuousRawOutputsAndPreservesDiagnosticsCounts() async throws {
        let sessionId = UUID()
        let startedAt = Date(timeIntervalSince1970: 10_000)
        let analyzer = DetectorTuningProfile.balanced.configuration.makeSleepAnalyzer()
        let pipeline = SleepAudioProcessingPipeline(
            sessionId: sessionId,
            startedAt: startedAt,
            analyzer: analyzer,
            detectorBackend: analyzer.detectorBackend.displayName,
            modelInstalled: analyzer.isModelInstalled,
            thresholdsSnapshot: analyzer.thresholdsSnapshot,
            tuningProfile: DetectorTuningProfile.balanced.displayName,
            eventAudioSampleStorageEnabled: false
        )

        let chunks = (0..<60).map { index in
            makeSnoreLikeChunk(startedAt: startedAt.addingTimeInterval(Double(index) * 0.1))
        }

        for chunk in chunks {
            _ = await pipeline.process(chunk: chunk)
        }

        var stopMetrics = await pipeline.metricsSnapshot()
        let endedAt = startedAt.addingTimeInterval(6)
        stopMetrics.stop(at: endedAt)
        stopMetrics.recordAnalyzerFinalizeStarted(at: endedAt)

        let result = await pipeline.finalize(endedAt: endedAt, stopMetrics: stopMetrics)
        let events = DetectorOutputMapper.makeEvents(from: result.smoothedOutputs, sessionId: sessionId)
        var finalMetrics = result.metrics
        finalMetrics.recordReportGenerationStarted(at: endedAt)
        finalMetrics.recordReportGenerationFinished(at: endedAt)
        let diagnostics = try #require(await pipeline.finalizeDiagnostics(
            endedAt: endedAt,
            finalEvents: events,
            finalMetrics: finalMetrics
        ))

        #expect(diagnostics.analyzedChunkCount == chunks.count)
        #expect(diagnostics.rmsSummary.count == chunks.count)
        #expect(diagnostics.rawCandidateCountByType[.snore, default: 0] >= chunks.count)
        #expect(result.allOutputs.count < chunks.count)
        #expect(!events.isEmpty)
    }

    @Test
    func diagnosticsCollectorBoundsStoredFeatureSamplesButKeepsObservedCount() throws {
        let collector = DetectorDiagnosticsCollector(maxStoredFeatureSamples: 3)
        let startedAt = Date(timeIntervalSince1970: 20_000)
        collector.reset(
            sessionId: UUID(),
            startedAt: startedAt,
            detectorBackend: SleepDetectionBackend.ruleBased.displayName,
            modelInstalled: false,
            thresholdsSnapshot: DetectorTuningProfile.balanced.configuration.thresholdSnapshot,
            tuningProfile: DetectorTuningProfile.balanced.displayName,
            eventAudioSampleStorageEnabled: false
        )

        for index in 0..<10 {
            collector.record(
                features: makeFeatures(
                    rms: 0.01 + Double(index) * 0.001,
                    energy: 0.0001 + Double(index) * 0.00001,
                    startedAt: startedAt.addingTimeInterval(Double(index))
                ),
                outputs: []
            )
        }

        let diagnostics = try #require(collector.finalize(
            endedAt: startedAt.addingTimeInterval(10),
            metrics: AudioCaptureMetrics.fallback(sessionElapsedSeconds: 10)
        ))

        #expect(diagnostics.analyzedChunkCount == 10)
        #expect(diagnostics.rmsSummary.count == 10)
        #expect(diagnostics.energySummary.count == 10)
        #expect(diagnostics.rmsSummary.max > diagnostics.rmsSummary.min)
    }

    @Test
    func fiveHourSyntheticSessionFinalizesWithBoundedProcessingState() async throws {
        let sessionId = UUID()
        let startedAt = Date(timeIntervalSince1970: 30_000)
        let analyzer = DetectorTuningProfile.balanced.configuration.makeSleepAnalyzer()
        let pipeline = SleepAudioProcessingPipeline(
            sessionId: sessionId,
            startedAt: startedAt,
            analyzer: analyzer,
            detectorBackend: analyzer.detectorBackend.displayName,
            modelInstalled: analyzer.isModelInstalled,
            thresholdsSnapshot: analyzer.thresholdsSnapshot,
            tuningProfile: DetectorTuningProfile.balanced.displayName,
            eventAudioSampleStorageEnabled: false
        )
        let chunkDuration = 5.0
        let chunkCount = Int((5 * 60 * 60) / chunkDuration)

        for index in 0..<chunkCount {
            let chunk = makeQuietSummaryOnlyChunk(
                startedAt: startedAt.addingTimeInterval(Double(index) * chunkDuration),
                duration: chunkDuration
            )
            _ = await pipeline.process(chunk: chunk)
        }

        var stopMetrics = await pipeline.metricsSnapshot()
        let endedAt = startedAt.addingTimeInterval(Double(chunkCount) * chunkDuration)
        stopMetrics.stop(at: endedAt)
        stopMetrics.recordAnalyzerFinalizeStarted(at: endedAt)

        let finalizeStarted = Date()
        let result = await pipeline.finalize(endedAt: endedAt, stopMetrics: stopMetrics)
        let finalizeElapsed = Date().timeIntervalSince(finalizeStarted)
        let events = DetectorOutputMapper.makeEvents(from: result.smoothedOutputs, sessionId: sessionId)
        var finalMetrics = result.metrics
        finalMetrics.recordReportGenerationStarted(at: endedAt)
        finalMetrics.recordReportGenerationFinished(at: endedAt)
        let diagnostics = try #require(await pipeline.finalizeDiagnostics(
            endedAt: endedAt,
            finalEvents: events,
            finalMetrics: finalMetrics
        ))

        #expect(finalizeElapsed < 1.5)
        #expect(result.metrics.receivedChunkCount == chunkCount)
        #expect(result.metrics.analyzedChunkCount == chunkCount)
        #expect(result.metrics.receivedAudioSeconds == Double(chunkCount) * chunkDuration)
        #expect(result.metrics.analyzedAudioSeconds == Double(chunkCount) * chunkDuration)
        #expect(result.allOutputs.count < 25)
        #expect(result.smoothedOutputs.isEmpty)
        #expect(diagnostics.analyzedChunkCount == chunkCount)
        #expect(diagnostics.rmsSummary.count == chunkCount)
        #expect(diagnostics.energySummary.count == chunkCount)
        #expect(diagnostics.eventAudioSampleStorageEnabled == false)
    }

    private func makeSnoreLikeChunk(startedAt: Date) -> AudioChunk {
        let sampleRate = 16_000.0
        let frameCount = 1_600
        let frequency = 95.0
        let samples = (0..<frameCount).map { index in
            let phase = 2 * Double.pi * frequency * Double(index) / sampleRate
            return Float(0.12 * sin(phase))
        }
        return AudioChunk(
            timestamp: startedAt,
            sampleRate: sampleRate,
            channelCount: 1,
            frameCount: frameCount,
            duration: Double(frameCount) / sampleRate,
            rms: AudioChunk.calculateRMS(samples),
            samples: samples
        )
    }

    private func makeFeatures(
        rms: Double,
        energy: Double,
        startedAt: Date
    ) -> AudioFeatures {
        AudioFeatures(
            startedAt: startedAt,
            duration: 1,
            sampleRate: 16_000,
            channelCount: 1,
            frameCount: 16_000,
            rms: rms,
            energy: energy,
            peak: min(rms * 1.6, 1),
            zeroCrossingRate: 0.08,
            lowFrequencyEnergyRatio: 0.7,
            highFrequencyActivity: 0.08,
            spectralCentroid: 240,
            lowBandEnergy: 0.7,
            midBandEnergy: 0.22,
            highBandEnergy: 0.08,
            estimatedNoiseLevel: rms,
            isLikelySilence: rms < 0.01
        )
    }

    private func makeQuietSummaryOnlyChunk(
        startedAt: Date,
        duration: TimeInterval
    ) -> AudioChunk {
        AudioChunk(
            timestamp: startedAt,
            sampleRate: 16_000,
            channelCount: 1,
            frameCount: Int(16_000 * duration),
            duration: duration,
            rms: 0.002,
            samples: []
        )
    }
}
