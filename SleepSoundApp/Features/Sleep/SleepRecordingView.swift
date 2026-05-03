import SwiftUI

struct SleepRecordingView: View {
  @EnvironmentObject private var appState: AppState
  @Environment(\.scenePhase) private var scenePhase
  let onStopComplete: () -> Void

  init(onStopComplete: @escaping () -> Void = {}) {
    self.onStopComplete = onStopComplete
  }

  var body: some View {
    ScrollView {
      VStack(spacing: NBSpacing.xLarge) {
        if let session = appState.activeSession {
          recordingCard(session: session)
        } else {
          completedCard
        }
      }
      .padding(NBSpacing.large)
    }
    .background(NBColor.pageBackground)
    .onChange(of: scenePhase) { _, newPhase in
      appState.recordDebugLifecycleEvent("scene phase: \(scenePhaseText(newPhase))")
    }
  }

  private func recordingCard(session: SleepSession) -> some View {
    NBCard {
      VStack(spacing: NBSpacing.large) {
        Image(systemName: "record.circle")
          .font(.system(size: 54))
          .foregroundStyle(NBColor.danger)

        Text("수면 기록 중")
          .font(.title.bold())

        TimelineView(.periodic(from: session.startedAt, by: 1)) { context in
          Text(
            SleepFormatters.compactDurationString(context.date.timeIntervalSince(session.startedAt))
          )
          .font(.system(size: 42, weight: .bold, design: .rounded))
          .monospacedDigit()
        }

        Text("감지 결과는 로컬 리포트 생성을 위한 이벤트 형태로 정리됩니다.")
          .font(.callout)
          .foregroundStyle(.secondary)
          .multilineTextAlignment(.center)

        audioCaptureStatus
        measurementStatus(session: session)

        NBPrivacyNoticeCard(
          title: "저장 정책",
          message: "원본 전체 오디오는 저장하지 않습니다. 이벤트 오디오 샘플은 설정이 켜진 경우에만 짧게 저장됩니다.",
          systemImage: "lock.shield"
        )

        Button(role: .destructive) {
          appState.endSleepSession()
          onStopComplete()
        } label: {
          Label("수면 종료", systemImage: "stop.fill")
        }
        .buttonStyle(NBPrimaryButtonStyle(tint: NBColor.danger))
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
              value: SleepFormatters.compactDurationString(metrics.sessionElapsedSeconds)
            )
            MeasurementStatusTile(
              title: "오디오 수신",
              value: SleepFormatters.compactDurationString(metrics.receivedAudioSeconds)
            )
            MeasurementStatusTile(
              title: "분석 시간",
              value: SleepFormatters.compactDurationString(metrics.analyzedAudioSeconds)
            )
            MeasurementStatusTile(
              title: "녹음 커버리지",
              value: percentString(metrics.audioCoverageRatio)
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
          MeasurementStatusRow(title: "Detector backend", value: "Rule-based")
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
            .foregroundStyle(.secondary)
        }

        ProgressView(value: displayAudioLevel)
          .progressViewStyle(.linear)

        Text(String(format: "최근 RMS %.4f", appState.latestAudioLevel))
          .font(.caption)
          .foregroundStyle(.secondary)

        Text("정리된 이벤트 후보 \(appState.detectedEventCandidateCount)개")
          .font(.caption)
          .foregroundStyle(.secondary)

        Text("최근 감지 후보 \(appState.latestDetectedEventText)")
          .font(.caption)
          .foregroundStyle(.secondary)

        Text("수집된 오디오 청크 \(appState.capturedAudioChunkCount)개")
          .font(.caption)
          .foregroundStyle(.secondary)

        Text("마이크 권한 \(appState.microphonePermissionState.displayText)")
          .font(.caption)
          .foregroundStyle(.secondary)

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
      return .red
    }
    return .secondary
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

  var body: some View {
    VStack(alignment: .leading, spacing: 3) {
      Text(title)
        .font(.caption2)
        .foregroundStyle(.secondary)
      Text(value)
        .font(.caption.weight(.semibold).monospacedDigit())
        .lineLimit(1)
        .minimumScaleFactor(0.75)
    }
    .padding(10)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(NBColor.elevatedSurface)
    .clipShape(RoundedRectangle(cornerRadius: 8))
  }
}

private struct MeasurementStatusRow: View {
  let title: String
  let value: String

  var body: some View {
    HStack(alignment: .firstTextBaseline) {
      Text(title)
        .font(.caption)
        .foregroundStyle(.secondary)
      Spacer()
      Text(value)
        .font(.caption.monospacedDigit())
        .multilineTextAlignment(.trailing)
    }
  }
}
