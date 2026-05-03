#if DEBUG
  import AVFoundation
  import SwiftUI

  struct SampleCaptureView: View {
    @StateObject private var viewModel = SampleCaptureViewModel()
    @State private var selectedLabel: SampleLabel = .unknown
    @State private var notes: String = ""

    var body: some View {
      List {
        Section("개발자용 샘플 수집") {
          SampleCaptureRow(title: "마이크 권한", value: viewModel.permissionState.displayText)
          SampleCaptureRow(title: "캡처 상태", value: viewModel.captureState.displayText)

          Picker("라벨", selection: $selectedLabel) {
            ForEach(SampleLabel.allCases) { label in
              Text(label.displayName).tag(label)
            }
          }

          Text(selectedLabel.captureGuide)
            .font(.footnote)
            .foregroundStyle(.secondary)

          TextField("메모", text: $notes, axis: .vertical)
            .lineLimit(2...4)

          HStack {
            sampleButton(seconds: 2)
            sampleButton(seconds: 3)
            sampleButton(seconds: 5)
          }

          if viewModel.isCapturingSample {
            ProgressView("짧은 샘플 캡처 중")
          }

          if let message = viewModel.message {
            Text(message)
              .font(.footnote)
              .foregroundStyle(viewModel.messageIsError ? NBColor.danger : .secondary)
          }
        }

        Section("실시간 Feature") {
          SampleCaptureProgressRow(title: "RMS", value: viewModel.currentRMS)
          SampleCaptureRow(
            title: "Energy", value: viewModel.format(viewModel.currentEnergy, digits: 6))
        }

        if let features = viewModel.latestSavedFeatures {
          Section("저장된 feature summary") {
            SampleCaptureRow(title: "RMS", value: viewModel.format(features.rms, digits: 4))
            SampleCaptureRow(title: "Energy", value: viewModel.format(features.energy, digits: 6))
            SampleCaptureRow(
              title: "Zero Crossing", value: viewModel.format(features.zeroCrossingRate, digits: 4))
            SampleCaptureRow(
              title: "Spectral Centroid",
              value: viewModel.format(features.spectralCentroid, digits: 1) + " Hz")
            SampleCaptureProgressRow(title: "Low Band", value: features.lowBandEnergy)
            SampleCaptureProgressRow(title: "Mid Band", value: features.midBandEnergy)
            SampleCaptureProgressRow(title: "High Band", value: features.highBandEnergy)
          }
        }

        if let savedSample = viewModel.latestSavedSample {
          Section("저장 결과") {
            SampleCaptureRow(title: "라벨", value: savedSample.metadata.label.rawValue)
            SampleCaptureRow(title: "오디오", value: savedSample.audioURL.lastPathComponent)
            SampleCaptureRow(title: "메타데이터", value: savedSample.metadataURL.lastPathComponent)
            SampleCaptureRow(
              title: "Feature CSV", value: savedSample.featureCSVURL.lastPathComponent)
            Text(savedSample.audioURL.deletingLastPathComponent().path)
              .font(.caption)
              .foregroundStyle(.secondary)
              .textSelection(.enabled)
          }
        }

        Section("저장 안전장치") {
          SampleCaptureRow(
            title: "Debug sample count", value: "\(viewModel.sampleStorageStatus.sampleCount)개")
          SampleCaptureRow(
            title: "Debug sample folder size",
            value: viewModel.formatBytes(viewModel.sampleStorageStatus.folderSizeBytes))
          SampleCaptureRow(title: "Last sample saved at", value: viewModel.lastSampleSavedAtText)
          SampleCaptureRow(title: "Available disk space", value: viewModel.availableDiskSpaceText)
          SampleCaptureRow(
            title: "샘플 1개 최대 길이", value: "\(Int(viewModel.storagePolicy.maxSampleDuration))초")
          SampleCaptureRow(
            title: "앱 실행당 최대 샘플", value: "\(viewModel.storagePolicy.maxSamplesPerSession)개")
          SampleCaptureRow(
            title: "샘플 폴더 최대 용량",
            value: viewModel.formatBytes(viewModel.storagePolicy.maxFolderSizeBytes))
          SampleCaptureRow(title: "오래된 샘플 정리", value: "7일")
          SampleCaptureRow(
            title: "Raw full-night audio storage", value: viewModel.fullNightStorageStatusText)
        }

        Section("개인정보 보호") {
          Label("개인 오디오 샘플은 서버로 전송되지 않습니다.", systemImage: "lock.shield")
          Label("전체 밤 오디오는 저장하지 않습니다.", systemImage: "moon.zzz")
          Label("사용자가 누른 2초/3초/5초 구간만 DEBUG 빌드에서 저장합니다.", systemImage: "timer")
          Label("이 기능은 Release 빌드에 포함되지 않습니다.", systemImage: "hammer")
        }
        .font(.footnote)
        .foregroundStyle(.secondary)
      }
      .navigationTitle("개발자용 샘플 수집")
      .scrollContentBackground(.hidden)
      .background(NBColor.pageBackground)
      .onAppear {
        viewModel.refreshPermissionState()
        viewModel.refreshStorageStatus()
      }
      .onDisappear {
        viewModel.stopCaptureIfNeeded()
      }
    }

    private func sampleButton(seconds: Int) -> some View {
      Button {
        Task {
          await viewModel.captureSample(
            duration: TimeInterval(seconds),
            label: selectedLabel,
            notes: notes
          )
        }
      } label: {
        Text("\(seconds)초")
          .frame(maxWidth: .infinity)
      }
      .buttonStyle(.borderedProminent)
      .disabled(viewModel.isCapturingSample)
    }
  }

  @MainActor
  private final class SampleCaptureViewModel: ObservableObject {
    @Published var permissionState: MicrophonePermissionState = .notDetermined
    @Published var captureState: AudioCaptureState = .idle
    @Published var isCapturingSample = false
    @Published var message: String?
    @Published var messageIsError = false
    @Published var currentRMS: Double = 0
    @Published var currentEnergy: Double = 0
    @Published var latestSavedFeatures: AudioFeatures?
    @Published var latestSavedSample: SavedLabeledAudioSample?
    @Published var sampleStorageStatus = DebugSampleStorageStatus()

    private let audioSessionManager: AudioSessionManaging
    private let audioCaptureService: AudioCaptureServiceProtocol
    private let featureExtractor: AudioFeatureExtracting
    private let metadataStore: SampleMetadataStore
    let storagePolicy: DebugSampleStoragePolicy
    private var capturedChunks: [AudioChunk] = []
    private var savedSampleCountInCurrentSession = 0

    init(
      audioSessionManager: AudioSessionManaging = AudioSessionManager(),
      audioCaptureService: AudioCaptureServiceProtocol? = nil,
      featureExtractor: AudioFeatureExtracting = AudioFeatureExtractor(),
      metadataStore: SampleMetadataStore = SampleMetadataStore(),
      storagePolicy: DebugSampleStoragePolicy = .default
    ) {
      self.audioSessionManager = audioSessionManager
      self.audioCaptureService =
        audioCaptureService ?? AudioCaptureService(sessionManager: audioSessionManager)
      self.featureExtractor = featureExtractor
      self.metadataStore = metadataStore
      self.storagePolicy = storagePolicy
      self.permissionState = audioSessionManager.microphonePermissionState()
      self.sampleStorageStatus = metadataStore.storageStatus(policy: storagePolicy)

      self.audioCaptureService.onChunk = { [weak self] chunk in
        Task { @MainActor [weak self] in
          self?.handle(chunk)
        }
      }

      self.audioCaptureService.onStateChange = { [weak self] state in
        Task { @MainActor [weak self] in
          self?.captureState = state
          if case .failed(let message) = state {
            self?.showError(message)
          }
        }
      }
    }

    func refreshPermissionState() {
      permissionState = audioSessionManager.microphonePermissionState()
    }

    func captureSample(duration: TimeInterval, label: SampleLabel, notes: String) async {
      guard !isCapturingSample else { return }

      resetForCapture()
      let safeDuration = storagePolicy.clampedSampleDuration(duration)

      do {
        try metadataStore.validateBeforeSaving(
          duration: safeDuration,
          sessionSampleCount: savedSampleCountInCurrentSession,
          estimatedAdditionalBytes: 0,
          policy: storagePolicy
        )
        try await prepareCapture()
        capturedChunks.removeAll(keepingCapacity: true)
        isCapturingSample = true
        message = "\(Int(safeDuration))초 샘플을 캡처하고 있습니다."
        messageIsError = false

        try await Task.sleep(nanoseconds: UInt64(safeDuration * 1_000_000_000))
        stopCaptureIfNeeded()
        try saveCapturedSample(label: label, notes: notes)
      } catch is CancellationError {
        stopCaptureIfNeeded()
      } catch let error as AudioCaptureError {
        stopCaptureIfNeeded()
        showError(error.message)
      } catch let error as AudioSessionError {
        stopCaptureIfNeeded()
        showError(error.message)
      } catch {
        stopCaptureIfNeeded()
        showError(error.localizedDescription)
      }
    }

    func stopCaptureIfNeeded() {
      if audioCaptureService.isCapturing {
        audioCaptureService.stopCapture()
      }
      isCapturingSample = false
      captureState = audioCaptureService.state
    }

    func format(_ value: Double, digits: Int) -> String {
      String(format: "%.\(digits)f", value)
    }

    var lastSampleSavedAtText: String {
      guard let lastSampleSavedAt = sampleStorageStatus.lastSampleSavedAt else {
        return "아직 없음"
      }

      let formatter = DateFormatter()
      formatter.locale = Locale(identifier: "ko_KR")
      formatter.dateFormat = "M/d HH:mm"
      return formatter.string(from: lastSampleSavedAt)
    }

    var availableDiskSpaceText: String {
      guard let bytes = sampleStorageStatus.availableDiskSpaceBytes else {
        return "확인 불가"
      }
      return formatBytes(bytes)
    }

    var fullNightStorageStatusText: String {
      sampleStorageStatus.fullNightRawAudioStorageEnabled ? "Enabled" : "Disabled"
    }

    func formatBytes(_ bytes: Int64) -> String {
      ByteCountFormatter.string(fromByteCount: bytes, countStyle: .file)
    }

    func refreshStorageStatus() {
      sampleStorageStatus = metadataStore.storageStatus(policy: storagePolicy)
    }

    private func prepareCapture() async throws {
      captureState = .requestingPermission
      var permissionState = audioSessionManager.microphonePermissionState()
      self.permissionState = permissionState

      if permissionState == .notDetermined {
        permissionState = await audioSessionManager.requestMicrophonePermission()
        self.permissionState = permissionState
      }

      guard permissionState == .granted else {
        throw AudioCaptureError.microphonePermissionDenied
      }

      try audioCaptureService.startCapture()
      captureState = audioCaptureService.state
    }

    private func handle(_ chunk: AudioChunk) {
      let features = featureExtractor.extractFeatures(from: chunk)
      currentRMS = features.rms
      currentEnergy = features.energy

      guard isCapturingSample else { return }
      capturedChunks.append(chunk)
    }

    private func resetForCapture() {
      capturedChunks.removeAll(keepingCapacity: true)
      latestSavedFeatures = nil
      latestSavedSample = nil
      message = nil
      messageIsError = false
      currentRMS = 0
      currentEnergy = 0
    }

    private func saveCapturedSample(label: SampleLabel, notes: String) throws {
      let combinedChunk = try makeCombinedChunk(from: capturedChunks)
      let features = featureExtractor.extractFeatures(from: combinedChunk)
      let capturedAt = Date()
      let fileBaseName = metadataStore.makeFileBaseName(capturedAt: capturedAt, label: label)
      let audioURL = metadataStore.audioURL(fileBaseName: fileBaseName)
      let metadataFileName = metadataStore.metadataFileName(fileBaseName: fileBaseName)
      let featureCSVFileName = metadataStore.featureCSVFileName(fileBaseName: fileBaseName)
      let estimatedAudioBytes = Int64(combinedChunk.samples.count * MemoryLayout<Float>.stride)

      try metadataStore.validateBeforeSaving(
        duration: combinedChunk.duration,
        sessionSampleCount: savedSampleCountInCurrentSession,
        estimatedAdditionalBytes: estimatedAudioBytes,
        policy: storagePolicy
      )
      try writeAudioFile(
        samples: combinedChunk.samples,
        sampleRate: combinedChunk.sampleRate,
        url: audioURL
      )

      let detectorOutput = RuleBasedSleepEventDetector()
        .detect(features: features)
        .max { lhs, rhs in lhs.confidence < rhs.confidence }

      let metadata = LabeledAudioSample(
        label: label,
        capturedAt: capturedAt,
        features: features,
        notes: notes,
        appVersion: Bundle.main.shortVersionString,
        deviceModel: DeviceModel.currentIdentifier,
        audioFileName: audioURL.lastPathComponent,
        metadataFileName: metadataFileName,
        featureCSVFileName: featureCSVFileName
      )

      let savedSample = try metadataStore.save(
        metadata: metadata,
        features: features,
        detectorOutput: detectorOutput
      )

      latestSavedFeatures = features
      latestSavedSample = savedSample
      savedSampleCountInCurrentSession += 1
      refreshStorageStatus()
      message = "샘플과 metadata가 저장되었습니다."
      messageIsError = false
    }

    private func makeCombinedChunk(from chunks: [AudioChunk]) throws -> AudioChunk {
      let validChunks = chunks.filter { !$0.samples.isEmpty }
      guard let firstChunk = validChunks.first else {
        throw SampleCaptureError.noAudioSamples
      }

      let sampleRate = firstChunk.sampleRate
      let samples = validChunks.flatMap(\.samples)
      guard !samples.isEmpty else {
        throw SampleCaptureError.noAudioSamples
      }
      let maxSampleCount = max(1, Int(storagePolicy.maxSampleDuration * sampleRate))
      let limitedSamples = Array(samples.prefix(maxSampleCount))

      return AudioChunk(
        samples: limitedSamples,
        sampleRate: sampleRate,
        startedAt: firstChunk.startedAt,
        duration: Double(limitedSamples.count) / sampleRate
      )
    }

    private func writeAudioFile(samples: [Float], sampleRate: Double, url: URL) throws {
      guard !samples.isEmpty else {
        throw SampleCaptureError.noAudioSamples
      }

      guard
        let format = AVAudioFormat(
          commonFormat: .pcmFormatFloat32,
          sampleRate: sampleRate,
          channels: 1,
          interleaved: false
        )
      else {
        throw SampleCaptureError.failedToCreateAudioFormat
      }

      guard
        let buffer = AVAudioPCMBuffer(
          pcmFormat: format,
          frameCapacity: AVAudioFrameCount(samples.count)
        )
      else {
        throw SampleCaptureError.failedToCreateAudioBuffer
      }

      buffer.frameLength = AVAudioFrameCount(samples.count)
      guard let channelData = buffer.floatChannelData?[0] else {
        throw SampleCaptureError.failedToCreateAudioBuffer
      }

      for index in samples.indices {
        channelData[index] = samples[index]
      }

      let file = try AVAudioFile(forWriting: url, settings: format.settings)
      try file.write(from: buffer)
    }

    private func showError(_ message: String) {
      refreshStorageStatus()
      self.message = message
      self.messageIsError = true
    }
  }

  private enum SampleCaptureError: LocalizedError {
    case noAudioSamples
    case failedToCreateAudioFormat
    case failedToCreateAudioBuffer

    var errorDescription: String? {
      switch self {
      case .noAudioSamples:
        "저장할 오디오 샘플이 없습니다. 마이크 권한과 입력 상태를 확인해 주세요."
      case .failedToCreateAudioFormat:
        "샘플 저장용 오디오 형식을 만들지 못했습니다."
      case .failedToCreateAudioBuffer:
        "샘플 저장용 오디오 버퍼를 만들지 못했습니다."
      }
    }
  }

  private struct SampleCaptureRow: View {
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

  private struct SampleCaptureProgressRow: View {
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

  private enum DeviceModel {
    static var currentIdentifier: String {
      var systemInfo = utsname()
      uname(&systemInfo)

      let mirror = Mirror(reflecting: systemInfo.machine)
      let identifier = mirror.children.reduce(into: "") { result, child in
        guard let value = child.value as? Int8, value != 0 else { return }
        result.append(String(UnicodeScalar(UInt8(value))))
      }

      return identifier.isEmpty ? "unknown" : identifier
    }
  }

  extension Bundle {
    fileprivate var shortVersionString: String {
      object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "debug"
    }
  }
#endif
