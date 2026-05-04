import SwiftUI

struct SleepRecordingView: View {
  @EnvironmentObject private var appState: AppState
  @Environment(\.scenePhase) private var scenePhase

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
    .onChange(of: scenePhase) { _, newPhase in
      appState.recordDebugLifecycleEvent("scene phase: \(scenePhaseText(newPhase))")
    }
  }

  private func recordingCard(session: SleepSession) -> some View {
    NBCard {
      VStack(spacing: NBSpacing.large) {
        NBRecordingPulseIcon(tint: NBColor.danger)
          .frame(width: 64, height: 64)
          .accessibilityHidden(true)

        Text(appState.isFinalizingSleepSession ? "수면 리포트 정리 중" : "수면 기록 중")
          .font(.title.bold())
          .foregroundStyle(NBColor.primaryText)

        TimelineView(.periodic(from: session.startedAt, by: 1)) { context in
          Text(
            SleepFormatters.compactDurationString(context.date.timeIntervalSince(session.startedAt))
          )
          .font(.system(size: 42, weight: .bold, design: .rounded))
          .monospacedDigit()
        }

        Text(appState.isFinalizingSleepSession ? "캡처는 멈췄고, iPhone 안에서 리포트를 정리하고 있습니다." : "감지 결과는 로컬 리포트 생성을 위한 이벤트 형태로 정리됩니다.")
          .font(.callout)
          .foregroundStyle(NBColor.secondaryText)
          .multilineTextAlignment(.center)

        if appState.isFinalizingSleepSession {
          ProgressView("잠시만 기다려 주세요")
            .font(.callout)
        }

        audioCaptureStatus
        measurementStatus(session: session)

        NBPrivacyNoticeCard(
          title: "저장 정책",
          message: "원본 전체 오디오는 저장하지 않습니다. 이벤트 오디오 샘플은 설정이 켜진 경우에만 짧게 저장됩니다.",
          systemImage: "lock.shield"
        )

        NBDangerButton(
          title: appState.isFinalizingSleepSession ? "리포트 정리 중" : "수면 종료",
          systemImage: appState.isFinalizingSleepSession ? "hourglass" : "stop.fill",
          isDisabled: appState.isFinalizingSleepSession
        ) {
          appState.endSleepSession()
        }
      }
    }
  }

  private func measurementStatus(session: SleepSession) -> some View {
    TimelineView(.periodic(from: session.startedAt, by: 1)) { context in
      let metrics = appState.audioCaptureMetrics.snapshot(at: context.date)

      NBReportSection(title: "측정 상태", systemImage: "waveform.badge.magnifyingglass") {
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
            title: "마지막 이벤트 감지", value: optionalTime(appState.latestDetectedEventAt))
          MeasurementStatusRow(title: "오디오 chunk 수", value: "\(metrics.receivedChunkCount)개")
          MeasurementStatusRow(title: "분석 chunk 수", value: "\(metrics.analyzedChunkCount)개")
          MeasurementStatusRow(title: "오디오 중단 횟수", value: "\(metrics.interruptionCount)회")
          MeasurementStatusRow(
            title: "가장 긴 입력 공백",
            value: SleepFormatters.compactDurationString(metrics.longestChunkGapSeconds)
          )
          MeasurementStatusRow(
            title: "현재 입력 공백",
            value: SleepFormatters.compactDurationString(metrics.currentChunkGapSeconds)
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
      }
    }
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
