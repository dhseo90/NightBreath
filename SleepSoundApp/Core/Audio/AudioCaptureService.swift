import AVFoundation
import Combine
import Foundation

@MainActor
public final class AudioCaptureService: ObservableObject, AudioCaptureServiceProtocol {
    @Published public private(set) var state: AudioCaptureState = .idle {
        didSet {
            onStateChange?(state)
        }
    }
    @Published public private(set) var metrics = AudioCaptureMetrics()

    public var onChunk: AudioChunkConsumer?
    public var onStateChange: AudioCaptureStateConsumer?

    public var isCapturing: Bool {
        state.isCapturing
    }

    private let engine: AVAudioEngine
    private let sessionManager: AudioSessionManaging
    private let retainedSampleLimitPerChunk: Int
    private var continuations: [UUID: AsyncStream<AudioChunk>.Continuation] = [:]
    private var interruptionObserver: NotificationObserverToken?
    private var stopSafetyTask: Task<Void, Never>?
    private var captureGeneration: UInt64 = 0
    private var didRunPhysicalStop = false

    public init(
        engine: AVAudioEngine = AVAudioEngine(),
        sessionManager: AudioSessionManaging = AudioSessionManager(),
        retainedSampleLimitPerChunk: Int = 4_096
    ) {
        self.engine = engine
        self.sessionManager = sessionManager
        self.retainedSampleLimitPerChunk = max(0, retainedSampleLimitPerChunk)
        installInterruptionObserver()
    }

    deinit {
        stopSafetyTask?.cancel()
        if let interruptionObserver {
            NotificationCenter.default.removeObserver(interruptionObserver.observer)
        }
    }

    public func makeChunkStream() -> AsyncStream<AudioChunk> {
        let id = UUID()

        return AsyncStream { [weak self] continuation in
            Task { @MainActor [weak self] in
                self?.continuations[id] = continuation
            }

            continuation.onTermination = { [weak self] _ in
                Task { @MainActor [weak self] in
                    self?.continuations.removeValue(forKey: id)
                }
            }
        }
    }

    public func startCapture() throws {
        guard !isCapturing, state != .stopping else { return }
        stopSafetyTask?.cancel()
        stopSafetyTask = nil
        didRunPhysicalStop = false
        captureGeneration &+= 1
        metrics = AudioCaptureMetrics()

        switch sessionManager.microphonePermissionState() {
        case .granted:
            break
        case .notDetermined:
            metrics.recordCaptureError()
            state = .failed(message: AudioCaptureError.microphonePermissionNotDetermined.message)
            throw AudioCaptureError.microphonePermissionNotDetermined
        case .denied:
            metrics.recordCaptureError()
            state = .failed(message: AudioCaptureError.microphonePermissionDenied.message)
            throw AudioCaptureError.microphonePermissionDenied
        }

        do {
            try sessionManager.prepareForSleepRecording()
        } catch let error as AudioSessionError {
            metrics.recordCaptureError()
            state = .failed(message: error.message)
            throw error
        } catch {
            metrics.recordCaptureError()
            state = .failed(message: error.localizedDescription)
            throw error
        }

        let inputNode = engine.inputNode
        let format = inputNode.outputFormat(forBus: 0)
        guard format.sampleRate > 0, format.channelCount > 0 else {
            metrics.recordCaptureError()
            state = .failed(message: AudioCaptureError.microphoneUnavailable.message)
            throw AudioCaptureError.microphoneUnavailable
        }

        inputNode.removeTap(onBus: 0)

        let generation = captureGeneration
        let tapBlock = AudioCaptureTapFactory.makeTapBlock(
            retainedSampleLimit: retainedSampleLimitPerChunk,
            service: self,
            generation: generation
        )
        inputNode.installTap(onBus: 0, bufferSize: 4_096, format: nil, block: tapBlock)

        engine.prepare()

        do {
            try engine.start()
            let startedAt = Date()
            metrics.start(at: startedAt)
            state = .capturing(startedAt: startedAt)
        } catch {
            inputNode.removeTap(onBus: 0)
            captureGeneration &+= 1
            didRunPhysicalStop = true
            sessionManager.finishSleepRecording()
            metrics.recordCaptureError()
            state = .failed(message: AudioCaptureError.engineStartFailed(error.localizedDescription).message)
            throw AudioCaptureError.engineStartFailed(error.localizedDescription)
        }
    }

    public func stopCapture() {
        if performStop(reason: "user stop request", force: false) {
            scheduleStopSafetyCheck()
        }
    }

    public func forceStopCapture(reason: String) {
        performStop(reason: reason, force: true)
    }

    @discardableResult
    private func performStop(reason: String, force: Bool) -> Bool {
        let stopStartedAt = Date()
        metrics.recordStopRequested(at: stopStartedAt)
        if force {
            metrics.recordForceStop(reason: reason, at: stopStartedAt)
        }

        guard !didRunPhysicalStop else {
            if case .failed = state {
                return false
            }
            state = .stopped
            return false
        }

        didRunPhysicalStop = true
        metrics.recordCaptureStopStarted(at: stopStartedAt)
        state = .stopping
        captureGeneration &+= 1
        engine.inputNode.removeTap(onBus: 0)
        metrics.recordInputTapRemoved(at: Date())
        engine.stop()
        metrics.recordAudioEngineStopped(at: Date())
        sessionManager.finishSleepRecording()
        metrics.recordAudioSessionDeactivated(at: Date())
        finishChunkStreams()
        metrics.recordCaptureTaskCancelled(at: Date())
        metrics.stop(at: Date())
        state = .stopped
        return true
    }

    fileprivate func emit(_ chunk: AudioChunk, generation: UInt64) {
        guard generation == captureGeneration else {
            if metrics.stopRequestedAt != nil {
                metrics.recordReceivedAfterStopRequest(chunk: chunk)
                forceStopCapture(reason: "stale audio chunk received after stop request")
            }
            return
        }

        guard state.isCapturing, metrics.stopRequestedAt == nil else {
            metrics.recordReceivedAfterStopRequest(chunk: chunk)
            forceStopCapture(reason: "audio chunk received after stop request")
            return
        }

        metrics.recordReceived(chunk: chunk)
        onChunk?(chunk)

        for continuation in continuations.values {
            continuation.yield(chunk)
        }
    }

    private func finishChunkStreams() {
        for continuation in continuations.values {
            continuation.finish()
        }
        continuations.removeAll(keepingCapacity: true)
    }

    private func scheduleStopSafetyCheck() {
        stopSafetyTask?.cancel()
        stopSafetyTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 1_200_000_000)
            await MainActor.run { [weak self] in
                guard let self else { return }
                if self.state != .stopped || self.metrics.chunksReceivedAfterStopRequest > 0 {
                    self.forceStopCapture(reason: "stop timeout safety check")
                }
            }
        }
    }

    private func installInterruptionObserver() {
        #if os(iOS)
        let observer = NotificationCenter.default.addObserver(
            forName: AVAudioSession.interruptionNotification,
            object: AVAudioSession.sharedInstance(),
            queue: .main
        ) { [weak self] notification in
            let rawType = notification.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt

            Task { @MainActor [weak self] in
                self?.handleInterruption(rawType: rawType)
            }
        }
        interruptionObserver = NotificationObserverToken(observer: observer)
        #endif
    }

    private func handleInterruption(rawType: UInt?) {
        #if os(iOS)
        guard let rawType,
              let type = AVAudioSession.InterruptionType(rawValue: rawType),
              type == .began,
              isCapturing else {
            return
        }

        forceStopCapture(reason: "audio session interruption")
        metrics.recordInterruption()
        metrics.recordCaptureError()
        state = .failed(message: AudioCaptureError.captureInterrupted.message)
        #endif
    }
}

private struct NotificationObserverToken: @unchecked Sendable {
    let observer: NSObjectProtocol
}

private enum AudioCaptureTapFactory {
    static func makeTapBlock(
        retainedSampleLimit: Int,
        service: AudioCaptureService,
        generation: UInt64
    ) -> AVAudioNodeTapBlock {
        { [weak service] buffer, _ in
            guard let chunk = AudioChunkFactory.makeChunk(
                from: buffer,
                retainedSampleLimit: retainedSampleLimit
            ) else {
                return
            }

            Task { @MainActor [weak service] in
                service?.emit(chunk, generation: generation)
            }
        }
    }
}

private enum AudioChunkFactory {
    static func makeChunk(
        from buffer: AVAudioPCMBuffer,
        retainedSampleLimit: Int
    ) -> AudioChunk? {
        guard let floatChannelData = buffer.floatChannelData else {
            return nil
        }

        let frameCount = Int(buffer.frameLength)
        let format = buffer.format
        let channelCount = Int(format.channelCount)
        guard frameCount > 0, channelCount > 0 else {
            return nil
        }

        var retainedSamples: [Float] = []
        if retainedSampleLimit > 0 {
            retainedSamples.reserveCapacity(min(frameCount, retainedSampleLimit))
        }

        var squareSum = 0.0
        let retainedStride = max(1, frameCount / max(1, retainedSampleLimit))

        for frameIndex in 0..<frameCount {
            var mixedSample = 0.0

            for channelIndex in 0..<channelCount {
                mixedSample += Double(floatChannelData[channelIndex][frameIndex])
            }

            mixedSample /= Double(channelCount)
            squareSum += mixedSample * mixedSample

            if retainedSamples.count < retainedSampleLimit, frameIndex % retainedStride == 0 {
                retainedSamples.append(Float(mixedSample))
            }
        }

        let sampleRate = format.sampleRate
        let duration = Double(frameCount) / sampleRate
        let rms = min(max(sqrt(squareSum / Double(frameCount)), 0), 1)

        return AudioChunk(
            timestamp: Date(),
            sampleRate: sampleRate,
            channelCount: channelCount,
            frameCount: frameCount,
            duration: duration,
            rms: rms,
            samples: retainedSamples
        )
    }
}

@MainActor
public final class MockAudioCaptureService: ObservableObject, AudioCaptureServiceProtocol {
    @Published public private(set) var state: AudioCaptureState = .idle {
        didSet {
            onStateChange?(state)
        }
    }
    @Published public private(set) var metrics = AudioCaptureMetrics()

    public var onChunk: AudioChunkConsumer?
    public var onStateChange: AudioCaptureStateConsumer?
    private var didRunPhysicalStop = false

    public var isCapturing: Bool {
        state.isCapturing
    }

    public init() {}

    public func makeChunkStream() -> AsyncStream<AudioChunk> {
        AsyncStream { continuation in
            continuation.finish()
        }
    }

    public func startCapture() throws {
        let startedAt = Date()
        didRunPhysicalStop = false
        metrics.start(at: startedAt)
        state = .capturing(startedAt: startedAt)
    }

    public func stopCapture() {
        metrics.recordStopRequested()
        guard !didRunPhysicalStop else {
            if case .failed = state {
                return
            }
            state = .stopped
            return
        }

        didRunPhysicalStop = true
        metrics.recordCaptureStopStarted()
        metrics.recordInputTapRemoved()
        metrics.recordAudioEngineStopped()
        metrics.recordAudioSessionDeactivated()
        metrics.recordCaptureTaskCancelled()
        metrics.stop(at: Date())
        state = .stopped
    }

    public func forceStopCapture(reason: String) {
        metrics.recordForceStop(reason: reason)
        stopCapture()
    }

    public func emitTestChunk(_ chunk: AudioChunk) {
        guard state.isCapturing, metrics.stopRequestedAt == nil else {
            metrics.recordReceivedAfterStopRequest(chunk: chunk)
            forceStopCapture(reason: "test audio chunk received after stop request")
            return
        }

        metrics.recordReceived(chunk: chunk)
        onChunk?(chunk)
    }
}
