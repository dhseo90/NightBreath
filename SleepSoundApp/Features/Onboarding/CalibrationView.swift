import SwiftUI

struct CalibrationView: View {
  @EnvironmentObject private var appState: AppState
  var showsTitle = true

  @State private var isRunning = false
  @State private var progress: Double = 0
  @State private var currentInputLevel: Double = 0
  @State private var receivedAudioSeconds: TimeInterval = 0
  @State private var audioCoverageRatio: Double = 0
  @State private var result: CalibrationResult?
  @State private var statusMessage = "캘리브레이션을 시작하면 30초 동안 입력 상태를 확인합니다."
  @State private var task: Task<Void, Never>?

  private let targetDuration: TimeInterval = 30

  var body: some View {
    VStack(alignment: .leading, spacing: NBSpacing.large) {
      if showsTitle {
        Text("30초 캘리브레이션")
          .font(NBTypography.sectionTitle)
          .foregroundStyle(NBColor.nightInk)
      }

      NBReportSection(title: "입력 상태 확인", systemImage: "waveform.badge.magnifyingglass") {
        VStack(alignment: .leading, spacing: NBSpacing.medium) {
          ProgressView(value: progress)
            .tint(NBColor.audioTint)

          CalibrationMetricGrid(
            currentInputLevel: currentInputLevel,
            receivedAudioSeconds: receivedAudioSeconds,
            audioCoverageRatio: audioCoverageRatio
          )

          Text(statusMessage)
            .font(.footnote)
            .foregroundStyle(.secondary)

          if let result {
            CalibrationResultCard(result: result)
          }

          Button {
            startCalibration()
          } label: {
            Label(isRunning ? "확인 중" : result == nil ? "캘리브레이션 시작" : "다시 시도", systemImage: "waveform")
          }
          .buttonStyle(NBPrimaryButtonStyle(tint: NBColor.audioTint))
          .disabled(isRunning)
        }
      }
    }
    .onDisappear {
      task?.cancel()
    }
  }

  private func startCalibration() {
    task?.cancel()
    result = nil
    progress = 0
    currentInputLevel = 0
    receivedAudioSeconds = 0
    audioCoverageRatio = 0
    isRunning = true
    statusMessage = "입력 상태를 확인하는 중입니다."

    task = Task {
      await runCalibration()
    }
  }

  @MainActor
  private func runCalibration() async {
    #if targetEnvironment(simulator)
      await runMockCalibration()
    #else
      let permissionState = await appState.requestMicrophonePermission()
      guard permissionState == .granted else {
        statusMessage = "마이크 권한이 허용되지 않아 캘리브레이션을 실행할 수 없습니다."
        isRunning = false
        return
      }
      await runMicrophoneCalibration()
    #endif
  }

  @MainActor
  private func runMockCalibration() async {
    let chunks = CalibrationService.simulatorMockChunks(duration: targetDuration)
    var collectedChunks: [AudioChunk] = []

    for chunk in chunks {
      if Task.isCancelled { return }
      collectedChunks.append(chunk)
      updateProgress(with: collectedChunks)
      try? await Task.sleep(nanoseconds: 35_000_000)
    }

    finish(with: collectedChunks, message: "Simulator mock 입력으로 캘리브레이션을 완료했습니다.")
  }

  @MainActor
  private func runMicrophoneCalibration() async {
    let captureService = AudioCaptureService()
    let stream = captureService.makeChunkStream()
    var collectedChunks: [AudioChunk] = []

    do {
      try captureService.startCapture()
    } catch let error as AudioCaptureError {
      statusMessage = error.message
      isRunning = false
      return
    } catch {
      statusMessage = error.localizedDescription
      isRunning = false
      return
    }

    for await chunk in stream {
      if Task.isCancelled {
        captureService.stopCapture()
        return
      }

      collectedChunks.append(chunk)
      updateProgress(with: collectedChunks)

      if receivedAudioSeconds >= targetDuration {
        break
      }
    }

    captureService.stopCapture()
    finish(with: collectedChunks, message: "30초 입력 확인을 완료했습니다.")
  }

  @MainActor
  private func updateProgress(with chunks: [AudioChunk]) {
    let service = CalibrationService(targetDuration: targetDuration)
    let interimResult = service.evaluate(chunks: chunks)
    receivedAudioSeconds = interimResult.receivedAudioSeconds
    audioCoverageRatio = interimResult.audioCoverageRatio
    currentInputLevel = chunks.last?.rms ?? 0
    progress = min(interimResult.receivedAudioSeconds / targetDuration, 1)
  }

  @MainActor
  private func finish(with chunks: [AudioChunk], message: String) {
    let service = CalibrationService(targetDuration: targetDuration)
    result = service.evaluate(chunks: chunks)
    updateProgress(with: chunks)
    statusMessage = message
    isRunning = false
  }
}

private struct CalibrationMetricGrid: View {
  let currentInputLevel: Double
  let receivedAudioSeconds: TimeInterval
  let audioCoverageRatio: Double

  var body: some View {
    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: NBSpacing.small) {
      NBMetricCard(
        title: "현재 입력",
        value: "\(Int((currentInputLevel * 100).rounded()))%",
        systemImage: "waveform",
        tint: NBColor.audioTint
      )
      NBMetricCard(
        title: "수신 시간",
        value: SleepFormatters.compactDurationString(receivedAudioSeconds),
        systemImage: "timer",
        tint: NBColor.breathBlue
      )
      NBMetricCard(
        title: "녹음 커버리지",
        value: "\(Int((audioCoverageRatio * 100).rounded()))%",
        systemImage: "waveform.badge.checkmark",
        tint: audioCoverageRatio >= 0.85 ? NBColor.success : NBColor.warning
      )
      NBMetricCard(
        title: "목표 시간",
        value: "30초",
        systemImage: "30.circle",
        tint: NBColor.neutral
      )
    }
  }
}

private struct CalibrationResultCard: View {
  let result: CalibrationResult

  var body: some View {
    VStack(alignment: .leading, spacing: NBSpacing.small) {
      NBStatusBadge(
        result.calibrationQuality.displayName,
        systemImage: resultIcon,
        tint: resultTint
      )

      Text(result.recommendedPlacementMessage)
        .font(.callout)
        .foregroundStyle(.secondary)

      HStack {
        Text("주변 소음 baseline")
        Spacer()
        Text("\(Int((result.ambientNoiseBaseline * 100).rounded()))%")
          .fontWeight(.semibold)
      }
      .font(.footnote)
      .foregroundStyle(.secondary)
    }
    .padding(NBSpacing.medium)
    .background(resultTint.opacity(0.10))
    .clipShape(RoundedRectangle(cornerRadius: NBCornerRadius.medium, style: .continuous))
  }

  private var resultTint: Color {
    switch result.calibrationQuality {
    case .good:
      NBColor.success
    case .highNoise, .weakInput, .retryRecommended:
      NBColor.warning
    case .microphonePossiblyBlocked:
      NBColor.danger
    }
  }

  private var resultIcon: String {
    switch result.calibrationQuality {
    case .good:
      "checkmark.circle"
    case .highNoise:
      "speaker.wave.3"
    case .weakInput:
      "waveform.badge.minus"
    case .microphonePossiblyBlocked:
      "mic.slash"
    case .retryRecommended:
      "arrow.clockwise"
    }
  }
}
