import Foundation

public protocol SleepAnalyzing {
    func analyze(session: SleepSession, chunks: [AudioChunk]) -> [SleepEvent]
}

public struct SleepAnalyzer: SleepAnalyzing {
    public var extractor: AudioFeatureExtracting
    public var detector: SleepEventDetecting

    public init(
        extractor: AudioFeatureExtracting = AudioFeatureExtractor(),
        detector: SleepEventDetecting = RuleBasedSleepEventDetector()
    ) {
        self.extractor = extractor
        self.detector = detector
    }

    public func analyze(session: SleepSession, chunks: [AudioChunk]) -> [SleepEvent] {
        chunks.flatMap { chunk in
            let features = extractor.extractFeatures(from: chunk)
            return detector
                .detect(features: features, startedAt: chunk.startedAt, duration: chunk.duration)
                .map { $0.makeEvent(sessionId: session.id) }
        }
    }
}
