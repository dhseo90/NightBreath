import Foundation

public protocol SleepAnalyzing {
    func analyze(session: SleepSession, chunks: [AudioChunk]) -> [SleepEvent]
    func analyze(chunks: [AudioChunk]) -> [DetectorOutput]
    func detectOutputs(from chunks: [AudioChunk]) -> [DetectorOutput]
    func smooth(outputs: [DetectorOutput]) -> [DetectorOutput]
    func makeEvents(session: SleepSession, outputs: [DetectorOutput]) -> [SleepEvent]
    func makeReport(session: SleepSession, outputs: [DetectorOutput]) -> NightReport
}

public struct SleepAnalyzer: SleepAnalyzing {
    public var extractor: any AudioFeatureExtracting
    public var detector: any SleepEventDetector
    public var smoothingPolicy: DetectionSmoothingPolicy

    public init(
        extractor: any AudioFeatureExtracting = AudioFeatureExtractor(),
        detector: any SleepEventDetector = CompositeSleepEventDetector.ruleBasedDefault,
        smoothingPolicy: DetectionSmoothingPolicy = DetectionSmoothingPolicy()
    ) {
        self.extractor = extractor
        self.detector = detector
        self.smoothingPolicy = smoothingPolicy
    }

    public func analyze(session: SleepSession, chunks: [AudioChunk]) -> [SleepEvent] {
        makeEvents(session: session, outputs: analyze(chunks: chunks))
    }

    public func analyze(chunks: [AudioChunk]) -> [DetectorOutput] {
        smooth(outputs: detectOutputs(from: chunks))
    }

    public func detectOutputs(from chunks: [AudioChunk]) -> [DetectorOutput] {
        chunks.flatMap { chunk in
            detectOutputs(from: chunk)
        }
    }

    public func detectOutputs(from chunk: AudioChunk) -> [DetectorOutput] {
        let features = extractor.extractFeatures(from: chunk)
        return detector.detect(features: features)
    }

    public func smooth(outputs: [DetectorOutput]) -> [DetectorOutput] {
        smoothingPolicy.apply(to: outputs)
    }

    public func makeEvents(session: SleepSession, outputs: [DetectorOutput]) -> [SleepEvent] {
        DetectorOutputMapper.makeEvents(from: outputs, sessionId: session.id)
    }

    public func analyze(session: SleepSession, chunkStream: AsyncStream<AudioChunk>) async -> [SleepEvent] {
        var rawOutputs: [DetectorOutput] = []

        for await chunk in chunkStream {
            let features = extractor.extractFeatures(from: chunk)
            rawOutputs.append(contentsOf: detector.detect(features: features))
        }

        return makeEvents(session: session, outputs: smooth(outputs: rawOutputs))
    }

    public func makeReport(session: SleepSession, chunks: [AudioChunk]) -> NightReport {
        let events = analyze(session: session, chunks: chunks)
        return SleepScoreCalculator().makeReport(session: session, events: events)
    }

    public func makeReport(session: SleepSession, outputs: [DetectorOutput]) -> NightReport {
        let events = makeEvents(session: session, outputs: smooth(outputs: outputs))
        return SleepScoreCalculator().makeReport(session: session, events: events)
    }
}
