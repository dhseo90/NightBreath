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
        guard !isCapturing else { return }
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

        let tapBlock = AudioCaptureTapFactory.makeTapBlock(
            retainedSampleLimit: retainedSampleLimitPerChunk,
            service: self
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
            sessionManager.finishSleepRecording()
            metrics.recordCaptureError()
            state = .failed(message: AudioCaptureError.engineStartFailed(error.localizedDescription).message)
            throw AudioCaptureError.engineStartFailed(error.localizedDescription)
        }
    }

    public func stopCapture() {
        guard isCapturing else {
            metrics.stop(at: Date())
            state = .stopped
            sessionManager.finishSleepRecording()
            return
        }

        state = .stopping
        engine.inputNode.removeTap(onBus: 0)
        engine.stop()
        sessionManager.finishSleepRecording()
        metrics.stop(at: Date())
        state = .stopped
    }

    fileprivate func emit(_ chunk: AudioChunk) {
        metrics.recordReceived(chunk: chunk)
        onChunk?(chunk)

        for continuation in continuations.values {
            continuation.yield(chunk)
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

        engine.inputNode.removeTap(onBus: 0)
        engine.stop()
        sessionManager.finishSleepRecording()
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
        service: AudioCaptureService
    ) -> AVAudioNodeTapBlock {
        { [weak service] buffer, _ in
            guard let chunk = AudioChunkFactory.makeChunk(
                from: buffer,
                retainedSampleLimit: retainedSampleLimit
            ) else {
                return
            }

            Task { @MainActor [weak service] in
                service?.emit(chunk)
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
        metrics.start(at: startedAt)
        state = .capturing(startedAt: startedAt)
    }

    public func stopCapture() {
        metrics.stop(at: Date())
        state = .stopped
    }
}
