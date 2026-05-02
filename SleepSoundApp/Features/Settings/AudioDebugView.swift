#if DEBUG
import Foundation
import SwiftUI

struct AudioDebugView: View {
    @StateObject private var viewModel = AudioDebugViewModel()

    var body: some View {
        List {
            Section("캡처") {
                AudioDebugRow(title: "상태", value: viewModel.captureState.displayText)
                AudioDebugRow(title: "마이크 권한", value: viewModel.permissionState.displayText)
                AudioDebugRow(title: "오디오 청크", value: "\(viewModel.chunkCount)개")

                HStack {
                    Button {
                        Task {
                            await viewModel.startCapture()
                        }
                    } label: {
                        Label("시작", systemImage: "play.fill")
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(viewModel.captureState.isCapturing || viewModel.captureState.isPreparing)

                    Button(role: .destructive) {
                        viewModel.stopCapture()
                    } label: {
                        Label("중지", systemImage: "stop.fill")
                    }
                    .buttonStyle(.bordered)
                    .disabled(!viewModel.captureState.isCapturing)
                }

                if let message = viewModel.message {
                    Text(message)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }

            Section("실시간 Feature") {
                AudioDebugProgressRow(title: "RMS", value: viewModel.currentRMS)
                AudioDebugRow(title: "Energy", value: viewModel.formattedEnergy)
                AudioDebugProgressRow(title: "Peak", value: viewModel.currentPeak)
                AudioDebugProgressRow(title: "Zero Crossing", value: viewModel.currentZeroCrossingRate)
                AudioDebugRow(title: "Spectral Centroid", value: viewModel.formattedSpectralCentroid)
                AudioDebugProgressRow(title: "Low Band", value: viewModel.currentLowBandEnergy)
                AudioDebugProgressRow(title: "Mid Band", value: viewModel.currentMidBandEnergy)
                AudioDebugProgressRow(title: "High Band", value: viewModel.currentHighBandEnergy)
                AudioDebugProgressRow(title: "Noise Level", value: viewModel.currentEstimatedNoiseLevel)
                AudioDebugRow(title: "무음 추정", value: viewModel.silenceStatusText)
                AudioDebugRow(title: "소음 추정", value: viewModel.noiseStatusText)
            }

            Section("Latest DetectorOutput") {
                if let output = viewModel.latestOutput {
                    AudioDebugRow(title: "eventType", value: output.eventType.displayName)
                    AudioDebugProgressRow(title: "confidence", value: output.confidence)
                    AudioDebugProgressRow(title: "intensity", value: output.intensity)
                    AudioDebugRow(title: "duration", value: viewModel.format(output.duration, digits: 2) + "초")
                    if let debugReason = output.debugReason {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("debugReason")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(debugReason)
                                .font(.callout)
                        }
                    }
                } else {
                    Text("아직 감지된 이벤트 후보가 없습니다.")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
            }

            Section("Detector Backend") {
                AudioDebugRow(title: "현재 backend", value: viewModel.detectorBackend.displayName)
                AudioDebugRow(title: "Core ML model", value: viewModel.coreMLModelStatus)
                AudioDebugRow(title: "Hybrid fallback", value: viewModel.hybridFallbackStatus)
            }

            Section("Threshold") {
                AudioDebugThresholdSlider(
                    title: "silence RMS",
                    value: $viewModel.silenceThreshold,
                    range: 0...0.08
                )
                AudioDebugThresholdSlider(
                    title: "snore RMS",
                    value: $viewModel.snoreThreshold,
                    range: 0.01...0.20
                )
                AudioDebugThresholdSlider(
                    title: "noise RMS",
                    value: $viewModel.noiseThreshold,
                    range: 0.05...0.60
                )
                Stepper(
                    "호흡정지 의심 구간 최소 \(Int(viewModel.suspectedPauseMinimumDuration))초",
                    value: $viewModel.suspectedPauseMinimumDuration,
                    in: 1...30,
                    step: 1
                )

                Button {
                    viewModel.resetThresholds()
                } label: {
                    Label("기본값으로 되돌리기", systemImage: "arrow.counterclockwise")
                }
            }

            Section("개발 메모") {
                Text("이 화면은 DEBUG 빌드에서만 노출됩니다. 원본 전체 오디오 파일을 저장하지 않고, sleep talk 내용을 텍스트화하지 않습니다.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Audio Debug")
        .onAppear {
            viewModel.refreshPermissionState()
        }
        .onDisappear {
            viewModel.stopCapture()
        }
    }
}

@MainActor
private final class AudioDebugViewModel: ObservableObject {
    @Published var captureState: AudioCaptureState = .idle
    @Published var permissionState: MicrophonePermissionState = .notDetermined
    @Published var message: String?
    @Published var chunkCount: Int = 0
    @Published var currentRMS: Double = 0
    @Published var currentEnergy: Double = 0
    @Published var currentPeak: Double = 0
    @Published var currentZeroCrossingRate: Double = 0
    @Published var currentSpectralCentroid: Double = 0
    @Published var currentLowBandEnergy: Double = 0
    @Published var currentMidBandEnergy: Double = 0
    @Published var currentHighBandEnergy: Double = 0
    @Published var currentEstimatedNoiseLevel: Double = 0
    @Published var latestFeatures: AudioFeatures?
    @Published var latestOutput: DetectorOutput?
    @Published var detectorBackend: SleepDetectionBackend = .ruleBased
    @Published var coreMLModelStatus: String = "Not installed"
    @Published var hybridFallbackStatus: String = "Available"
    @Published var silenceThreshold: Double = RuleBasedDetectionThresholds.default.silenceRMS {
        didSet { updateDetectorThresholds() }
    }
    @Published var snoreThreshold: Double = RuleBasedDetectionThresholds.default.snoreRMS {
        didSet { updateDetectorThresholds() }
    }
    @Published var noiseThreshold: Double = RuleBasedDetectionThresholds.default.noiseRMS {
        didSet { updateDetectorThresholds() }
    }
    @Published var suspectedPauseMinimumDuration: Double = RuleBasedDetectionThresholds.default.suspectedPauseMinimumDuration {
        didSet { updateDetectorThresholds() }
    }

    private let audioSessionManager: AudioSessionManaging
    private let audioCaptureService: AudioCaptureServiceProtocol
    private let featureExtractor: AudioFeatureExtracting
    private var detector: RuleBasedSleepEventDetector

    init(
        audioSessionManager: AudioSessionManaging = AudioSessionManager(),
        audioCaptureService: AudioCaptureServiceProtocol? = nil,
        featureExtractor: AudioFeatureExtracting = AudioFeatureExtractor()
    ) {
        self.audioSessionManager = audioSessionManager
        self.audioCaptureService = audioCaptureService ?? AudioCaptureService(sessionManager: audioSessionManager)
        self.featureExtractor = featureExtractor
        self.detector = RuleBasedSleepEventDetector()
        self.permissionState = audioSessionManager.microphonePermissionState()

        self.audioCaptureService.onChunk = { [weak self] chunk in
            Task { @MainActor [weak self] in
                self?.handle(chunk)
            }
        }

        self.audioCaptureService.onStateChange = { [weak self] state in
            Task { @MainActor [weak self] in
                self?.captureState = state
                if case .failed(let message) = state {
                    self?.message = message
                }
            }
        }
    }

    var formattedEnergy: String {
        format(currentEnergy, digits: 6)
    }

    var formattedSpectralCentroid: String {
        format(currentSpectralCentroid, digits: 1) + " Hz"
    }

    var silenceStatusText: String {
        guard let latestFeatures else { return "대기 중" }

        if latestFeatures.isLikelySilence || latestFeatures.rms < silenceThreshold {
            return "저에너지/무음 후보"
        }
        return "소리 입력 있음"
    }

    var noiseStatusText: String {
        guard let latestFeatures else { return "대기 중" }

        if latestFeatures.rms >= noiseThreshold || latestFeatures.peak >= 0.85 {
            return "환경 소음 후보"
        }
        return "일반 입력 범위"
    }

    func refreshPermissionState() {
        permissionState = audioSessionManager.microphonePermissionState()
    }

    func startCapture() async {
        message = nil
        chunkCount = 0
        latestOutput = nil
        latestFeatures = nil
        captureState = .requestingPermission

        var nextPermissionState = audioSessionManager.microphonePermissionState()
        permissionState = nextPermissionState

        if nextPermissionState == .notDetermined {
            nextPermissionState = await audioSessionManager.requestMicrophonePermission()
            permissionState = nextPermissionState
        }

        guard nextPermissionState == .granted else {
            let message = AudioCaptureError.microphonePermissionDenied.message
            captureState = .failed(message: message)
            self.message = message
            return
        }

        captureState = .ready

        do {
            try audioCaptureService.startCapture()
            captureState = audioCaptureService.state
        } catch let error as AudioCaptureError {
            captureState = .failed(message: error.message)
            message = error.message
        } catch let error as AudioSessionError {
            captureState = .failed(message: error.message)
            message = error.message
        } catch {
            captureState = .failed(message: error.localizedDescription)
            message = error.localizedDescription
        }
    }

    func stopCapture() {
        audioCaptureService.stopCapture()
        captureState = audioCaptureService.state
    }

    func resetThresholds() {
        let defaults = RuleBasedDetectionThresholds.default
        silenceThreshold = defaults.silenceRMS
        snoreThreshold = defaults.snoreRMS
        noiseThreshold = defaults.noiseRMS
        suspectedPauseMinimumDuration = defaults.suspectedPauseMinimumDuration
        updateDetectorThresholds()
    }

    func format(_ value: Double, digits: Int) -> String {
        String(format: "%.\(digits)f", value)
    }

    private func handle(_ chunk: AudioChunk) {
        let features = featureExtractor.extractFeatures(from: chunk)
        let outputs = detector.detect(features: features)

        chunkCount += 1
        latestFeatures = features
        currentRMS = features.rms
        currentEnergy = features.energy
        currentPeak = features.peak
        currentZeroCrossingRate = features.zeroCrossingRate
        currentSpectralCentroid = features.spectralCentroid
        currentLowBandEnergy = features.lowBandEnergy
        currentMidBandEnergy = features.midBandEnergy
        currentHighBandEnergy = features.highBandEnergy
        currentEstimatedNoiseLevel = features.estimatedNoiseLevel
        latestOutput = outputs.max { lhs, rhs in
            lhs.confidence < rhs.confidence
        }
    }

    private func updateDetectorThresholds() {
        detector = RuleBasedSleepEventDetector(
            thresholds: RuleBasedDetectionThresholds(
                silenceRMS: silenceThreshold,
                snoreRMS: snoreThreshold,
                noiseRMS: noiseThreshold,
                suspectedPauseMinimumDuration: suspectedPauseMinimumDuration
            )
        )
    }
}

private struct AudioDebugRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .multilineTextAlignment(.trailing)
                .font(.callout.monospacedDigit())
        }
    }
}

private struct AudioDebugProgressRow: View {
    let title: String
    let value: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(String(format: "%.4f", value))
                    .font(.callout.monospacedDigit())
            }

            ProgressView(value: min(max(value, 0), 1))
                .progressViewStyle(.linear)
        }
    }
}

private struct AudioDebugThresholdSlider: View {
    let title: String
    @Binding var value: Double
    let range: ClosedRange<Double>

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                Spacer()
                Text(String(format: "%.3f", value))
                    .font(.callout.monospacedDigit())
                    .foregroundStyle(.secondary)
            }

            Slider(value: $value, in: range, step: 0.001)
        }
    }
}
#endif
