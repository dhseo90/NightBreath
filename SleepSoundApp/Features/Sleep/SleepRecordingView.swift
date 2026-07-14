import SwiftUI

struct SleepRecordingView: View {
  @EnvironmentObject private var appState: AppState
  @Environment(\.scenePhase) private var scenePhase
  @State private var clockDate = Date()
  @State private var showsDetailedDiagnostics = false

  var body: some View {
    ScrollView {
      VStack(spacing: NBSpacing.sectionVertical) {
        if let session = appState.activeSession {
          recordingCard(session: session)
        } else {
          completedCard
        }
      }
      .padding(.horizontal, NBSpacing.screenHorizontal)
      .padding(.vertical, NBSpacing.sectionVertical)
    }
    .background(NBColor.pageBackground)
    .nbAvoidFloatingTabBar()
    .task(id: appState.activeSession?.id) { [hasSession = appState.activeSession != nil] in
      guard hasSession else { return }
      await runRecordingClock()
    }
    .onChange(of: scenePhase) { _, newPhase in
      appState.recordDebugLifecycleEvent("scene phase: \(scenePhaseText(newPhase))")
    }
  }

  private func runRecordingClock() async {
    while !Task.isCancelled {
      await MainActor.run {
        clockDate = Date()
      }
      try? await Task.sleep(nanoseconds: 1_000_000_000)
    }
  }

  private func recordingCard(session: SleepSession) -> some View {
    NBCard {
      VStack(spacing: NBSpacing.large) {
        NBRecordingPulseIcon(tint: NBColor.danger)
          .frame(width: 64, height: 64)
          .accessibilityHidden(true)

        Text(recordingTitle)
          .font(.title.bold())
          .foregroundStyle(NBColor.primaryText)

        Text(
          SleepFormatters.compactDurationString(
            displayedSessionElapsed(for: session, at: clockDate)
          )
        )
        .font(.system(size: 42, weight: .bold, design: .rounded))
        .monospacedDigit()

        Text(recordingMessage)
          .font(.callout)
          .foregroundStyle(NBColor.secondaryText)
          .multilineTextAlignment(.center)

        if appState.sleepRecordingPhase != .recording {
          ProgressView(appState.sleepRecordingPhase == .stoppingCapture ? "녹음을 멈추는 중입니다" : "잠시만 기다려 주세요")
            .font(.callout)
          finalizationStatus
        }

        audioCaptureStatus
        measurementStatus(session: session, asOf: clockDate)

        NBPrivacyNoticeCard(
          title: "저장 정책",
          message: "원본 전체 오디오는 저장하지 않습니다. 이벤트 오디오 샘플은 설정이 켜진 경우에만 짧게 저장됩니다.",
          systemImage: "lock.shield"
        )

        NBDangerButton(
          title: stopButtonTitle,
          systemImage: stopButtonIcon,
          isDisabled: isStopButtonDisabled,
          isBusy: isStopButtonBusy
        ) {
          appState.endSleepSession()
        }
      }
    }
  }

  private var finalizationStatus: some View {
    NBInlineStatus(
      title: appState.sleepRecordingPhase.title,
      detail: finalizationDetailText,
      kind: .privacy,
      systemImage: appState.sleepRecordingPhase == .reportReady ? "checkmark.circle" : "hourglass",
      isLoading: appState.sleepRecordingPhase != .reportReady
    )
  }

  private var recordingTitle: String {
    if isCaptureFailed {
      return "수면 기록 중단됨"
    }
    return appState.sleepRecordingPhase.title
  }

  private var recordingMessage: String {
    if case .failed(let message) = appState.audioCaptureState {
      return message
    }
    return appState.sleepRecordingPhase.message
  }

  private var stopButtonTitle: String {
    if isCaptureFailed {
      return "리포트 정리"
    }
    return appState.sleepRecordingPhase.isStopButtonDisabled ? "종료 처리 중" : "수면 종료"
  }

  private var stopButtonIcon: String {
    if isCaptureFailed {
      return "doc.text.magnifyingglass"
    }
    return appState.sleepRecordingPhase.isStopButtonDisabled ? "hourglass" : "stop.fill"
  }

  private var isStopButtonDisabled: Bool {
    appState.sleepRecordingPhase.isStopButtonDisabled && !isCaptureFailed
  }

  private var isStopButtonBusy: Bool {
    appState.sleepRecordingPhase != .recording && !isCaptureFailed
  }

  private var isCaptureFailed: Bool {
    if case .failed = appState.audioCaptureState {
      return true
    }
    return false
  }

  private var finalizationDetailText: String {
    var details = [appState.audioCaptureMessage ?? appState.sleepRecordingPhase.message]
    if let elapsedText = finalizationElapsedText {
      details.append(elapsedText)
    }
    return details.joined(separator: "\n")
  }

  private var finalizationElapsedText: String? {
    guard appState.sleepRecordingPhase != .recording else { return nil }
    let metrics = appState.audioCaptureMetrics.snapshot(at: clockDate)
    guard let startedAt = metrics.stopButtonTappedAt ?? metrics.stopRequestedAt else { return nil }
    let elapsed = max(0, clockDate.timeIntervalSince(startedAt))
    return "종료 요청 후 \(SleepFormatters.compactDurationString(elapsed)) 경과"
  }

  private func measurementStatus(session: SleepSession, asOf date: Date) -> some View {
    let metrics = appState.audioCaptureMetrics.snapshot(at: date)
    let shouldShowDetails = showsDetailedDiagnostics || metrics.stopRequestedAt != nil

    return NBReportSection(title: "측정 상태", systemImage: "waveform.badge.magnifyingglass") {
      VStack(alignment: .leading, spacing: NBSpacing.small) {
        LazyVGrid(
          columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: NBSpacing.small
        ) {
          MeasurementStatusTile(
            title: "세션 경과",
            value: SleepFormatters.compactDurationString(metrics.sessionElapsedSeconds),
            systemImage: "clock",
            tint: NBColor.sleep
          )
          MeasurementStatusTile(
            title: "오디오 수신",
            value: SleepFormatters.compactDurationString(metrics.receivedAudioSeconds),
            systemImage: "waveform",
            tint: NBColor.breath
          )
          MeasurementStatusTile(
            title: "분석 시간",
            value: SleepFormatters.compactDurationString(metrics.analyzedAudioSeconds),
            systemImage: "waveform.path.ecg",
            tint: NBColor.audioTint
          )
          MeasurementStatusTile(
            title: "녹음 커버리지",
            value: percentString(metrics.audioCoverageRatio),
            systemImage: "gauge.with.dots.needle.67percent",
            tint: coverageTint(metrics.audioCoverageRatio),
            status: coverageStatus(metrics.audioCoverageRatio)
          )
        }

        HStack(spacing: NBSpacing.sm) {
          NBStatusBadge(coverageDescription(metrics.audioCoverageRatio), kind: coverageStatus(metrics.audioCoverageRatio), systemImage: "waveform")
          NBStatusBadge(
            appState.isEventAudioSampleStorageEnabled ? "이벤트 샘플 저장 켜짐" : "이벤트 샘플 저장 꺼짐",
            kind: appState.isEventAudioSampleStorageEnabled ? .debug : .privacy,
            systemImage: appState.isEventAudioSampleStorageEnabled ? "waveform.circle" : "lock.shield"
          )
        }

        MeasurementStatusRow(
          title: "마지막 오디오 입력", value: optionalTime(metrics.lastChunkReceivedAt))
        MeasurementStatusRow(title: "마지막 분석", value: optionalTime(metrics.lastChunkAnalyzedAt))
        MeasurementStatusRow(
          title: "현재 입력 공백",
          value: SleepFormatters.compactDurationString(metrics.currentChunkGapSeconds)
        )

        Button {
          showsDetailedDiagnostics.toggle()
        } label: {
          Label(shouldShowDetails ? "상세 진단 접기" : "상세 진단 보기", systemImage: shouldShowDetails ? "chevron.up" : "chevron.down")
        }
        .buttonStyle(.nbSecondary)

        if shouldShowDetails {
          detailedMeasurementRows(metrics: metrics)
        }
      }
    }
  }

  @ViewBuilder
  private func detailedMeasurementRows(metrics: AudioCaptureMetrics) -> some View {
    MeasurementStatusRow(
      title: "마지막 이벤트 감지", value: optionalTime(appState.latestDetectedEventAt))
    MeasurementStatusRow(title: "오디오 chunk 수", value: "\(metrics.receivedChunkCount)개")
    MeasurementStatusRow(title: "분석 chunk 수", value: "\(metrics.analyzedChunkCount)개")
    MeasurementStatusRow(
      title: "종료 후 입력 chunk",
      value: "\(metrics.chunksReceivedAfterStopRequest)개"
    )
    MeasurementStatusRow(
      title: "종료 후 입력 시간",
      value: SleepFormatters.compactDurationString(metrics.secondsReceivingAudioAfterStopRequest)
    )
    if metrics.stopRequestedAt != nil {
      MeasurementStatusRow(title: "종료 버튼 탭", value: optionalTime(metrics.stopButtonTappedAt))
      MeasurementStatusRow(title: "종료 요청", value: optionalTime(metrics.stopRequestedAt))
      MeasurementStatusRow(title: "캡처 중단 시작", value: optionalTime(metrics.captureStopStartedAt))
      MeasurementStatusRow(title: "Input tap 제거", value: optionalTime(metrics.inputTapRemovedAt))
      MeasurementStatusRow(title: "Audio engine 정지", value: optionalTime(metrics.audioEngineStoppedAt))
      MeasurementStatusRow(title: "Audio session 비활성화", value: optionalTime(metrics.audioSessionDeactivatedAt))
      MeasurementStatusRow(title: "Capture task 종료", value: optionalTime(metrics.captureTaskCancelledAt))
      MeasurementStatusRow(title: "Analyzer finalize 시작", value: optionalTime(metrics.analyzerFinalizeStartedAt))
      MeasurementStatusRow(title: "Analyzer finalize 완료", value: optionalTime(metrics.analyzerFinalizeFinishedAt))
      MeasurementStatusRow(title: "리포트 생성 시작", value: optionalTime(metrics.reportGenerationStartedAt))
      MeasurementStatusRow(title: "리포트 생성 완료", value: optionalTime(metrics.reportGenerationFinishedAt))
      if let forceStopReason = metrics.forceStopReason {
        MeasurementStatusRow(title: "Force stop", value: forceStopReason)
      }
    }
    if let audioSessionEventSummary = metrics.audioSessionEventSummary {
      MeasurementStatusRow(title: "오디오 세션 이벤트", value: audioSessionEventSummary)
    }
    MeasurementStatusRow(title: "오디오 중단 횟수", value: "\(metrics.interruptionCount)회")
    MeasurementStatusRow(
      title: "가장 긴 입력 공백",
      value: SleepFormatters.compactDurationString(metrics.longestChunkGapSeconds)
    )
    MeasurementStatusRow(title: "앱 상태", value: scenePhaseDisplayText)
    MeasurementStatusRow(title: "캡처 상태", value: appState.audioCaptureState.displayText)
    MeasurementStatusRow(
      title: "마이크 권한", value: appState.microphonePermissionState.displayText)
    MeasurementStatusRow(title: "Background audio mode", value: backgroundAudioModeText)
    MeasurementStatusRow(title: "Detector backend", value: appState.currentDetectorBackend.displayName)
    MeasurementStatusRow(title: "Tuning profile", value: appState.detectorTuningProfile.displayName)
    MeasurementStatusRow(title: "Debug mode", value: debugModeText)
    MeasurementStatusRow(title: "원본 전체 오디오 저장", value: "꺼짐")
    MeasurementStatusRow(
      title: "이벤트 오디오 샘플 저장",
      value: appState.isEventAudioSampleStorageEnabled ? "켜짐" : "꺼짐"
    )

    #if DEBUG
      if !appState.debugLifecycleLog.isEmpty {
        VStack(alignment: .leading, spacing: 4) {
          Text("최근 lifecycle 로그")
            .font(.caption)
            .foregroundStyle(.secondary)
          ForEach(Array(appState.debugLifecycleLog.suffix(5)), id: \.self) { entry in
            Text(entry)
              .font(.caption2.monospacedDigit())
              .foregroundStyle(.secondary)
          }
        }
      }
    #endif
  }

  private var audioCaptureStatus: some View {
    NBCard(background: NBColor.audioTint.opacity(0.08)) {
      VStack(alignment: .leading, spacing: NBSpacing.small) {
        HStack {
          Label(appState.audioCaptureState.displayText, systemImage: "mic")
            .font(.subheadline.weight(.semibold))
          Spacer()
          Text("\(Int(displayAudioLevel * 100))%")
            .font(.caption.monospacedDigit())
            .foregroundStyle(NBColor.secondaryText)
        }

        ProgressView(value: displayAudioLevel)
          .progressViewStyle(.linear)

        Text(String(format: "최근 RMS %.4f", appState.latestAudioLevel))
          .font(.caption)
          .foregroundStyle(NBColor.secondaryText)

        Text("정리된 이벤트 후보 \(appState.detectedEventCandidateCount)개")
          .font(.caption)
          .foregroundStyle(NBColor.secondaryText)

        Text("최근 감지 후보 \(appState.latestDetectedEventText)")
          .font(.caption)
          .foregroundStyle(NBColor.secondaryText)

        Text("수집된 오디오 청크 \(appState.capturedAudioChunkCount)개")
          .font(.caption)
          .foregroundStyle(NBColor.secondaryText)

        Text("마이크 권한 \(appState.microphonePermissionState.displayText)")
          .font(.caption)
          .foregroundStyle(NBColor.secondaryText)

        if let message = appState.audioCaptureMessage {
          Text(message)
            .font(.caption)
            .foregroundStyle(messageTint)
        }
      }
    }
  }

  private var messageTint: Color {
    if case .failed = appState.audioCaptureState {
      return NBColor.danger
    }
    return NBColor.secondaryText
  }

  private var displayAudioLevel: Double {
    min(max(appState.latestAudioLevel * 8, 0), 1)
  }

  private func displayedSessionElapsed(for session: SleepSession, at date: Date) -> TimeInterval {
    let metrics = appState.audioCaptureMetrics.snapshot(at: date)
    if metrics.stopRequestedAt != nil || appState.sleepRecordingPhase != .recording {
      return metrics.sessionElapsedSeconds
    }
    return date.timeIntervalSince(session.startedAt)
  }

  private var scenePhaseDisplayText: String {
    scenePhaseText(scenePhase)
  }

  private func scenePhaseText(_ phase: ScenePhase) -> String {
    switch phase {
    case .active:
      return "foreground"
    case .inactive:
      return "inactive"
    case .background:
      return "background"
    @unknown default:
      return "unknown"
    }
  }

  private var backgroundAudioModeText: String {
    let modes = Bundle.main.object(forInfoDictionaryKey: "UIBackgroundModes") as? [String]
    return modes?.contains("audio") == true ? "설정됨" : "미설정"
  }

  private var debugModeText: String {
    #if DEBUG
      return "DEBUG"
    #else
      return "Release"
    #endif
  }

  private func optionalTime(_ date: Date?) -> String {
    guard let date else { return "아직 없음" }
    return SleepFormatters.shortTime(date)
  }

  private func percentString(_ ratio: Double) -> String {
    String(format: "%.1f%%", min(max(ratio, 0), 1) * 100)
  }

  private func coverageStatus(_ ratio: Double) -> NBStatusKind {
    switch ratio {
    case 0.95...:
      return .good
    case 0.85..<0.95:
      return .neutral
    case 0.60..<0.85:
      return .caution
    default:
      return .danger
    }
  }

  private func coverageTint(_ ratio: Double) -> Color {
    coverageStatus(ratio).tint
  }

  private func coverageDescription(_ ratio: Double) -> String {
    switch ratio {
    case 0.95...:
      return "커버리지 좋음"
    case 0.85..<0.95:
      return "커버리지 보통"
    case 0.60..<0.85:
      return "커버리지 제한적"
    default:
      return "커버리지 낮음"
    }
  }

  private var completedCard: some View {
    NBCard {
      VStack(spacing: NBSpacing.large) {
        Image(systemName: "checkmark.circle.fill")
          .font(.system(size: 48))
          .foregroundStyle(NBColor.success)
        Text("최근 리포트가 준비되었습니다")
          .font(.title3.bold())
        Label(
          appState.latestReportSource.displayText,
          systemImage: appState.latestReportSource.systemImage
        )
        .font(.caption.weight(.semibold))
        .foregroundStyle(.secondary)
        if let message = appState.audioCaptureMessage {
          Text(message)
            .font(.caption)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
        }
        NavigationLink {
          SleepReportView(report: appState.latestReport, events: appState.latestEvents)
        } label: {
          Label("리포트 보기", systemImage: "doc.text")
        }
        .buttonStyle(.nbPrimary)
      }
    }
  }
}

private struct MeasurementStatusTile: View {
  let title: String
  let value: String
  var systemImage: String = "circle.grid.cross"
  var tint: Color = NBColor.audioTint
  var status: NBStatusKind?

  var body: some View {
    NBMetricCard(
      title: title,
      value: value,
      systemImage: systemImage,
      tint: tint,
      status: status,
      accessibilityLabel: "\(title), \(value)"
    )
  }
}

private struct MeasurementStatusRow: View {
  let title: String
  let value: String

  var body: some View {
    HStack(alignment: .firstTextBaseline) {
      Text(title)
        .font(.caption)
        .foregroundStyle(NBColor.secondaryText)
      Spacer()
      Text(value)
        .font(.caption.monospacedDigit())
        .multilineTextAlignment(.trailing)
        .foregroundStyle(NBColor.primaryText)
    }
  }
}
