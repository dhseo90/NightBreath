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
            .buttonStyle(NBPrimaryButtonStyle(tint: NBColor.audioTint))
            .disabled(viewModel.captureState.isCapturing || viewModel.captureState.isPreparing)

            Button(role: .destructive) {
              viewModel.stopCapture()
            } label: {
              Label("중지", systemImage: "stop.fill")
            }
            .buttonStyle(NBDangerButtonStyle())
            .disabled(!viewModel.captureState.isCapturing)
          }

          if let message = viewModel.message {
            Text(message)
              .font(.caption)
              .foregroundStyle(NBColor.danger)
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
            NBDiagnosticCard(
              title: "Latest DetectorOutput",
              summary: output.debugReason,
              items: [
                NBDiagnosticItem(title: "eventType", value: output.eventType.timelineDisplayName, status: .debug),
                NBDiagnosticItem(title: "confidence", value: viewModel.percentString(output.confidence), status: .neutral),
                NBDiagnosticItem(title: "intensity", value: viewModel.percentString(output.intensity), status: .neutral),
                NBDiagnosticItem(title: "duration", value: viewModel.format(output.duration, digits: 2) + "초", status: .debug),
              ],
              showsDetails: true,
              systemImage: "waveform.and.magnifyingglass"
            )
            .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
            .listRowBackground(Color.clear)
          } else {
            NBEmptyStateView(
              title: "감지된 이벤트 후보 없음",
              message: "마이크 입력이 들어오면 최신 detector output을 DEBUG 요약으로 표시합니다.",
              systemImage: "waveform.slash"
            )
          }
        }

        Section("Detector Observability") {
          NBDiagnosticCard(
            title: "Detector Pipeline",
            summary: "실시간 입력이 feature, raw 후보, smoothing 기준에서 어떻게 처리되는지 DEBUG 빌드에서만 봅니다.",
            items: [
              NBDiagnosticItem(title: "chunks received/analyzed", value: "\(viewModel.chunkCount) / \(viewModel.analyzedChunkCount)", status: .debug),
              NBDiagnosticItem(title: "current thresholds", value: viewModel.currentThresholdText, status: .debug),
              NBDiagnosticItem(title: "RMS / energy p50/p90", value: viewModel.featureDistributionText, status: .neutral),
              NBDiagnosticItem(title: "low band p50/p90", value: viewModel.lowBandDistributionText, status: .neutral),
              NBDiagnosticItem(title: "snore-like feature", value: "\(viewModel.snoreLikeFeatureCandidateCount) / rejected \(viewModel.snoreLikeFeatureRejectedCount)", status: viewModel.snoreLikeFeatureRejectedCount > 0 ? .caution : .debug),
              NBDiagnosticItem(title: "last raw candidate", value: viewModel.latestRawCandidateText, status: .neutral),
              NBDiagnosticItem(title: "last reject reason", value: viewModel.lastRejectReasonText, status: .caution),
              NBDiagnosticItem(title: "recent raw candidate count", value: viewModel.rawCandidateCountText, status: .neutral),
              NBDiagnosticItem(title: "smoothing 전/후", value: "\(viewModel.preSmoothingCandidateCount) / \(viewModel.postSmoothingEventCount)", status: .debug),
              NBDiagnosticItem(title: "smoothing drop", value: "\(viewModel.smoothingDropCount)개", status: viewModel.smoothingDropCount > 0 ? .caution : .good),
              NBDiagnosticItem(title: "tuning profile", value: viewModel.tuningProfileText, status: .debug),
            ],
            showsDetails: true,
            systemImage: "waveform.path.ecg"
          )
          .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
          .listRowBackground(Color.clear)
        }

        Section("Detector Backend") {
          NBDiagnosticCard(
            title: "Detector Backend",
            summary: "DEBUG 빌드에서만 detector backend와 Core ML fallback 상태를 확인합니다.",
            items: [
              NBDiagnosticItem(title: "현재 backend", value: viewModel.detectorBackend.displayName, status: .debug),
              NBDiagnosticItem(title: "Snore ML model installed", value: viewModel.coreMLModelStatus, status: viewModel.coreMLModelStatus == "Installed" ? .good : .neutral),
              NBDiagnosticItem(title: "model version", value: viewModel.modelVersionText, status: .debug),
              NBDiagnosticItem(title: "last ML confidence", value: viewModel.latestCoreMLConfidenceText, status: .neutral),
              NBDiagnosticItem(title: "fallback count", value: "\(viewModel.coreMLFallbackCount)회", status: viewModel.coreMLFallbackCount > 0 ? .caution : .good),
              NBDiagnosticItem(title: "Hybrid fallback", value: viewModel.hybridFallbackStatus, status: .debug),
            ],
            showsDetails: true,
            systemImage: "cpu"
          )
          .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
          .listRowBackground(Color.clear)
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
          .buttonStyle(.nbSecondary)
        }

        Section("개발 메모") {
          NBPrivacyNoticeCard(
            title: "DEBUG 화면",
            messages: [
              "이 화면은 DEBUG 빌드에서만 노출됩니다.",
              "원본 전체 오디오 파일을 저장하지 않습니다.",
              "sleep talk 내용을 텍스트화하지 않습니다.",
            ],
            systemImage: "ladybug"
          )
          .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
          .listRowBackground(Color.clear)
        }
      }
      .navigationTitle("Audio Debug")
      .scrollContentBackground(.hidden)
      .background(NBColor.pageBackground)
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
    @Published var analyzedChunkCount: Int = 0
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
    @Published var latestRawCandidateText: String = "없음"
    @Published var lastRejectReasonText: String = "대기 중"
    @Published var rawCandidateCountByType: [SleepEventType: Int] = [:]
    @Published var preSmoothingCandidateCount: Int = 0
    @Published var postSmoothingEventCount: Int = 0
    @Published var smoothingDropCount: Int = 0
    @Published var snoreLikeFeatureCandidateCount: Int = 0
    @Published var snoreLikeFeatureRejectedCount: Int = 0
    @Published var detectorBackend: SleepDetectionBackend = .hybrid
    @Published var coreMLModelStatus: String = "Not installed"
    @Published var modelVersionText: String = CoreMLDetectorConfiguration.default.modelVersion
    @Published var latestCoreMLConfidenceText: String = "대기 중"
    @Published var coreMLFallbackCount: Int = 0
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
    @Published var suspectedPauseMinimumDuration: Double = RuleBasedDetectionThresholds.default
      .suspectedPauseMinimumDuration
    {
      didSet { updateDetectorThresholds() }
    }

    private let audioSessionManager: AudioSessionManaging
    private let audioCaptureService: AudioCaptureServiceProtocol
    private let featureExtractor: AudioFeatureExtracting
    private var detector: RuleBasedSleepEventDetector
    private var coreMLDetector: CoreMLSleepEventDetector
    private var rawOutputs: [DetectorOutput] = []
    private var rmsValues = AudioDebugValueSampler(maxStoredValueCount: 7_200)
    private var energyValues = AudioDebugValueSampler(maxStoredValueCount: 7_200)
    private var lowBandValues = AudioDebugValueSampler(maxStoredValueCount: 7_200)
    private let maxDebugRawOutputCount = 720

    init(
      audioSessionManager: AudioSessionManaging = AudioSessionManager(),
      audioCaptureService: AudioCaptureServiceProtocol? = nil,
      featureExtractor: AudioFeatureExtracting = AudioFeatureExtractor()
    ) {
      self.audioSessionManager = audioSessionManager
      self.audioCaptureService =
        audioCaptureService ?? AudioCaptureService(sessionManager: audioSessionManager)
      self.featureExtractor = featureExtractor
      self.detector = RuleBasedSleepEventDetector()
      self.coreMLDetector = CoreMLSleepEventDetector()
      self.permissionState = audioSessionManager.microphonePermissionState()
      self.coreMLModelStatus =
        coreMLDetector.modelProvider.isModelAvailable ? "Installed" : "Not installed"

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

    var currentThresholdText: String {
      String(
        format: "silence %.3f / snore %.3f / noise %.3f",
        silenceThreshold,
        snoreThreshold,
        noiseThreshold
      )
    }

    var featureDistributionText: String {
      let rms = rmsValues.summary()
      let energy = energyValues.summary()
      guard rms.count > 0 else { return "대기 중" }
      return "\(format(rms.p50, digits: 4))/\(format(rms.p90, digits: 4)) · \(format(energy.p50, digits: 6))/\(format(energy.p90, digits: 6))"
    }

    var lowBandDistributionText: String {
      let lowBand = lowBandValues.summary()
      guard lowBand.count > 0 else { return "대기 중" }
      return "\(format(lowBand.p50, digits: 3)) / \(format(lowBand.p90, digits: 3))"
    }

    var rawCandidateCountText: String {
      let parts = rawCandidateCountByType
        .sorted { lhs, rhs in lhs.key.rawValue < rhs.key.rawValue }
        .map { type, count in "\(type.timelineDisplayName) \(count)" }
      return parts.isEmpty ? "없음" : parts.joined(separator: ", ")
    }

    var tuningProfileText: String {
      DetectorTuningProfile.customDebug.displayName
    }

    func refreshPermissionState() {
      permissionState = audioSessionManager.microphonePermissionState()
    }

    func startCapture() async {
      message = nil
      chunkCount = 0
      analyzedChunkCount = 0
      latestOutput = nil
      latestRawCandidateText = "없음"
      lastRejectReasonText = "대기 중"
      latestFeatures = nil
      rawCandidateCountByType.removeAll()
      rawOutputs.removeAll()
      rmsValues.removeAll()
      energyValues.removeAll()
      lowBandValues.removeAll()
      preSmoothingCandidateCount = 0
      postSmoothingEventCount = 0
      smoothingDropCount = 0
      snoreLikeFeatureCandidateCount = 0
      snoreLikeFeatureRejectedCount = 0
      latestCoreMLConfidenceText = "대기 중"
      coreMLFallbackCount = 0
      hybridFallbackStatus = "Available"
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

    func percentString(_ ratio: Double) -> String {
      String(format: "%.1f%%", min(max(ratio, 0), 1) * 100)
    }

    private func handle(_ chunk: AudioChunk) {
      let features = featureExtractor.extractFeatures(from: chunk)
      let outputs = detector.detect(features: features)
      let coreMLResult = coreMLDetector.detectWithStatus(features: features)

      chunkCount += 1
      analyzedChunkCount += 1
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
      rmsValues.append(features.rms)
      energyValues.append(features.energy)
      lowBandValues.append(features.lowBandEnergy)
      if let mlSnoreOutput = coreMLResult.outputs.first(where: { $0.eventType == .snore }) {
        latestOutput = mlSnoreOutput
      } else {
        latestOutput = outputs.max { lhs, rhs in
          lhs.confidence < rhs.confidence
        }
      }
      updatePipelineObservability(features: features, outputs: outputs)
      updateCoreMLStatus(from: coreMLResult)
    }

    private func updatePipelineObservability(features: AudioFeatures, outputs: [DetectorOutput]) {
      let snoreObservation = SnoreLikeFeatureObserver.observe(
        features: features,
        thresholdsSnapshot: thresholdSnapshot
      )
      if snoreObservation.isCandidate {
        snoreLikeFeatureCandidateCount += 1
        if !outputs.contains(where: { $0.eventType == .snore }) {
          snoreLikeFeatureRejectedCount += 1
          lastRejectReasonText = snoreObservation.rejectReasons.map(\.displayName).joined(separator: ", ")
        }
      }

      if outputs.isEmpty {
        let reasons = RejectReason.inferredForFeatureWithoutOutput(
          features,
          thresholdsSnapshot: thresholdSnapshot
        )
        lastRejectReasonText = reasons.map(\.displayName).joined(separator: ", ")
      } else {
        for output in outputs {
          rawCandidateCountByType[output.eventType, default: 0] += 1
        }
        if let strongestOutput = outputs.max(by: { lhs, rhs in lhs.confidence < rhs.confidence }) {
          latestRawCandidateText =
            "\(strongestOutput.eventType.timelineDisplayName) \(percentString(strongestOutput.confidence))"
        }
      }

      rawOutputs.append(contentsOf: outputs)
      trimRawOutputsForLiveDebug()
      let smoothingDiagnostics = smoothingPolicy.applyWithDiagnostics(to: rawOutputs).diagnostics
      preSmoothingCandidateCount = smoothingDiagnostics.preSmoothingCandidateCount
      postSmoothingEventCount = smoothingDiagnostics.postSmoothingEventCount
      smoothingDropCount = max(0, preSmoothingCandidateCount - postSmoothingEventCount)
      if outputs.isEmpty == false,
         let topReason = smoothingDiagnostics.rejectedCountByReason.sorted(by: { lhs, rhs in
           if lhs.value == rhs.value { return lhs.key.rawValue < rhs.key.rawValue }
           return lhs.value > rhs.value
         }).first?.key {
        lastRejectReasonText = topReason.displayName
      }
    }

    private func trimRawOutputsForLiveDebug() {
      guard rawOutputs.count > maxDebugRawOutputCount else { return }
      rawOutputs.removeFirst(rawOutputs.count - maxDebugRawOutputCount)
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

    private var smoothingPolicy: DetectionSmoothingPolicy {
      DetectionSmoothingPolicy(
        minimumEventDuration: DetectorTuningProfile.customDebug.configuration.minimumEventDuration,
        maximumMergeGap: DetectorTuningProfile.customDebug.configuration.mergeGapSeconds,
        confidenceThreshold: DetectorTuningProfile.customDebug.configuration.minimumConfidence
      )
    }

    private var thresholdSnapshot: [String: Double] {
      [
        "rule.silenceRMS": silenceThreshold,
        "rule.snoreRMS": snoreThreshold,
        "rule.lowLevelSnoreRMS": max(silenceThreshold * 2.2, snoreThreshold * 0.55),
        "rule.lowLevelSnoreEnergy": max(silenceThreshold * 2.2, snoreThreshold * 0.55) *
          max(silenceThreshold * 2.2, snoreThreshold * 0.55) * 0.65,
        "rule.lowLevelSnoreLowBandRatio": 0.64,
        "rule.noiseRMS": noiseThreshold,
        "tuning.snoreEnergyThreshold": snoreThreshold * snoreThreshold
      ]
    }

    private func updateCoreMLStatus(from result: CoreMLDetectionResult) {
      coreMLModelStatus =
        coreMLDetector.modelProvider.isModelAvailable ? "Installed" : "Not installed"

      switch result.status {
      case .success:
        if let output = result.outputs.first {
          latestCoreMLConfidenceText = format(output.confidence, digits: 3)
          hybridFallbackStatus =
            output.eventType == .snore
            ? "Core ML snore 우선 사용 가능" : "non-snore 결과는 rule-based fallback"
          if output.eventType != .snore {
            coreMLFallbackCount += 1
          }
        } else {
          latestCoreMLConfidenceText = "결과 없음"
          hybridFallbackStatus = "rule-based fallback"
          coreMLFallbackCount += 1
        }
      case .belowConfidenceThreshold(let confidence):
        latestCoreMLConfidenceText = format(confidence, digits: 3)
        hybridFallbackStatus = "confidence 낮음 → rule-based fallback"
        coreMLFallbackCount += 1
      case .modelUnavailable:
        latestCoreMLConfidenceText = "모델 없음"
        hybridFallbackStatus = "모델 없음 → rule-based fallback"
        coreMLFallbackCount += 1
      case .predictionFailed:
        latestCoreMLConfidenceText = "예측 실패"
        hybridFallbackStatus = "예측 실패 → rule-based fallback"
        coreMLFallbackCount += 1
      }
    }
  }

  private struct AudioDebugValueSampler {
    private let maxStoredValueCount: Int
    private var observedValueCount = 0
    private var values: [Double] = []

    init(maxStoredValueCount: Int) {
      self.maxStoredValueCount = max(1, maxStoredValueCount)
    }

    mutating func append(_ value: Double) {
      guard value.isFinite else { return }

      observedValueCount += 1
      if values.count < maxStoredValueCount {
        values.append(value)
        return
      }

      values[observedValueCount % maxStoredValueCount] = value
    }

    mutating func removeAll() {
      observedValueCount = 0
      values.removeAll(keepingCapacity: true)
    }

    func summary() -> SummaryStats {
      SummaryStats.make(values: values, totalCount: observedValueCount)
    }
  }

  private struct AudioDebugRow: View {
    let title: String
    let value: String

    var body: some View {
      NBListRow(
        title: title,
        value: value,
        systemImage: "circle.grid.cross",
        tint: NBColor.audioTint
      )
    }
  }

  private struct AudioDebugProgressRow: View {
    let title: String
    let value: Double

    var body: some View {
      VStack(alignment: .leading, spacing: 6) {
        HStack {
          Text(title)
            .foregroundStyle(NBColor.secondaryText)
          Spacer()
          Text(String(format: "%.4f", value))
            .font(.callout.monospacedDigit())
            .foregroundStyle(NBColor.primaryText)
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
            .foregroundStyle(NBColor.secondaryText)
        }

        Slider(value: $value, in: range, step: 0.001)
      }
    }
  }
#endif
