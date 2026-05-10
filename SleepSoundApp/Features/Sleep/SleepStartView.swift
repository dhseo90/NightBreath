import SwiftUI

struct SleepStartView: View {
  @EnvironmentObject private var appState: AppState
  @State private var showLatestReport = false
  @State private var didQueuePermissionRefresh = false

  var body: some View {
    Group {
      if appState.isRecording {
        SleepRecordingView()
      } else {
        startContent
      }
    }
    .navigationDestination(isPresented: $showLatestReport) {
      SleepReportView(report: appState.latestReport, events: appState.latestEvents)
    }
    .navigationDestination(for: SleepStartDestination.self) { destination in
      switch destination {
      case .latestReport:
        SleepReportView(report: appState.latestReport, events: appState.latestEvents)
      case .latestTimeline:
        SleepTimelineView(report: appState.latestReport, events: appState.latestEvents)
      case .trend:
        TrendDashboardView()
      }
    }
    .onChange(of: appState.isFinalizingSleepSession) { wasFinalizing, isFinalizing in
      if wasFinalizing, !isFinalizing, !appState.isRecording, appState.latestReportSource == .deviceAnalysis {
        showLatestReport = true
      }
    }
    .task {
      queueDeferredMicrophonePermissionRefresh()
    }
  }

  private var startContent: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: NBSpacing.sectionVertical) {
        NBCard(background: NBColor.sleep.opacity(0.10), stroke: NBColor.sleep.opacity(0.18)) {
          VStack(alignment: .leading, spacing: NBSpacing.md) {
            NBMoonBreathIcon(tint: NBColor.sleep)
              .frame(width: 54, height: 54)
              .accessibilityHidden(true)
            Text("수면 시작")
              .font(NBTypography.screenTitle)
              .foregroundStyle(NBColor.primaryText)
            Text("수면 중 소리 기반 지표를 기록합니다.")
              .font(NBTypography.body)
              .foregroundStyle(NBColor.secondaryText)
            Text("iPhone을 침대 옆에 두고, 아침에는 수면 소리 점수와 주요 이벤트를 확인할 수 있습니다.")
              .font(NBTypography.callout)
              .foregroundStyle(NBColor.secondaryText)
          }
        }

        permissionStatusCard

        NBPrimaryButton(title: startButtonTitle, systemImage: startButtonIcon, isDisabled: appState.isPreparingCapture) {
          appState.startSleepSession()
        }

        sleepStartActionFeedbackView
        setupSummaryCard
        latestResultSection

        NBPrivacyNoticeCard(
          title: "측정 전 개인정보 확인",
          messages: [
            "원본 전체 오디오는 저장하지 않습니다.",
            "이벤트 오디오 샘플은 사용자가 켠 경우에만 저장됩니다.",
            "분석은 iPhone 안에서 수행됩니다.",
            "서버로 전송하지 않습니다.",
          ]
        )
      }
      .padding(.horizontal, NBSpacing.screenHorizontal)
      .padding(.top, NBSpacing.sm)
      .padding(.bottom, NBSpacing.screenHorizontal)
    }
    .background(NBColor.pageBackground)
    .nbAvoidFloatingTabBar()
  }

  private func queueDeferredMicrophonePermissionRefresh() {
    guard !didQueuePermissionRefresh else { return }
    didQueuePermissionRefresh = true
    appState.refreshMicrophonePermissionStateAfterTabTransition()
  }

  private var latestResultSection: some View {
    NBReportSection(title: "최근 수면 결과", systemImage: "doc.text.magnifyingglass") {
      VStack(spacing: NBSpacing.md) {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: NBSpacing.medium) {
          NBMetricCard(
            title: "수면 소리 점수",
            value: "\(appState.latestReport.sleepSoundScore)",
            unit: "점",
            subtitle: SleepFormatters.shortDate(appState.latestReport.generatedAt),
            systemImage: "waveform.path.ecg",
            tint: NBColor.sleepTint
          )

          NBMetricCard(
            title: "측정 품질",
            value: appState.latestReport.measurementQuality.displayName,
            subtitle: "커버리지 \(percentString(appState.latestReport.audioCoverageRatio))",
            systemImage: "checkmark.seal",
            tint: appState.latestReport.measurementQuality == .poor ? NBColor.danger : NBColor.success
          )
        }

        HStack(spacing: NBSpacing.md) {
          NavigationLink(value: SleepStartDestination.latestReport) {
            Label("리포트", systemImage: "doc.text.magnifyingglass")
          }
          .buttonStyle(.nbSecondary)

          NavigationLink(value: SleepStartDestination.latestTimeline) {
            Label("타임라인", systemImage: "list.bullet.rectangle")
          }
          .buttonStyle(.nbSecondary)
        }

        NavigationLink(value: SleepStartDestination.trend) {
          Label("수면 트렌드", systemImage: "chart.line.uptrend.xyaxis")
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.nbSecondary)
      }
    }
  }

  private var permissionStatusCard: some View {
    NBCard {
      VStack(alignment: .leading, spacing: NBSpacing.small) {
        HStack {
          Label("마이크 권한", systemImage: "mic")
            .font(.headline)
          Spacer()
          NBStatusBadge(
            appState.microphonePermissionState.displayText,
            kind: permissionStatusKind,
            systemImage: permissionStatusIcon
          )
        }

        Text(permissionDescription)
          .font(.callout)
          .foregroundStyle(NBColor.secondaryText)

        if let message = appState.audioCaptureMessage {
          Text(message)
            .font(.caption)
            .foregroundStyle(NBColor.danger)
        }
      }
    }
  }

  @ViewBuilder
  private var sleepStartActionFeedbackView: some View {
    if appState.isFinalizingSleepSession {
      NBInlineStatus(
        title: "수면 기록 정리 중",
        detail: "캡처를 마무리하고 아침 리포트를 준비하고 있습니다.",
        kind: .privacy,
        systemImage: "arrow.triangle.2.circlepath",
        isLoading: true
      )
    } else {
      switch appState.audioCaptureState {
      case .requestingPermission:
        NBInlineStatus(
          title: "수면 시작 요청됨 · 권한 확인 중",
          detail: "마이크 권한 확인이 끝날 때까지 버튼은 잠시 비활성화됩니다.",
          kind: .privacy,
          systemImage: "mic.badge.plus",
          isLoading: true
        )
      case .ready:
        NBInlineStatus(
          title: "캡처 준비 완료",
          detail: "오디오 캡처 세션을 열고 수면 기록 화면으로 전환합니다.",
          kind: .good,
          systemImage: "checkmark.circle"
        )
      case .stopping:
        NBInlineStatus(
          title: "캡처 종료 요청됨",
          detail: "수면 기록을 저장 가능한 리포트로 정리하고 있습니다.",
          kind: .privacy,
          systemImage: "stop.circle",
          isLoading: true
        )
      case .failed(let message):
        NBInlineStatus(
          title: "수면 시작 완료 안 됨",
          detail: message,
          kind: .warning,
          systemImage: "exclamationmark.triangle"
        )
      case .idle, .capturing(_), .stopped:
        EmptyView()
      }
    }
  }

  private var setupSummaryCard: some View {
    NBReportSection(title: "오늘 밤 측정 준비", systemImage: "checklist") {
      VStack(spacing: NBSpacing.sm) {
        NBListRow(
          title: "기기 배치",
          value: "침대 옆",
          subtitle: "iPhone을 충전기에 연결하고 마이크가 막히지 않게 둡니다.",
          systemImage: "iphone",
          tint: NBColor.sleep
        )
        Divider().overlay(NBColor.divider)
        NBListRow(
          title: "이벤트 오디오 샘플 저장",
          value: appState.isEventAudioSampleStorageEnabled ? "켜짐" : "꺼짐",
          subtitle: "이벤트 오디오 샘플은 사용자가 켠 경우에만 저장됩니다.",
          systemImage: appState.isEventAudioSampleStorageEnabled ? "waveform.circle" : "waveform.slash",
          tint: appState.isEventAudioSampleStorageEnabled ? NBColor.audioTint : NBColor.privacy
        )
        Divider().overlay(NBColor.divider)
        NBListRow(
          title: "원본 전체 오디오",
          value: "저장 안 함",
          subtitle: "밤새 전체 원본 오디오 파일을 기본 동작으로 저장하지 않습니다.",
          systemImage: "lock.shield",
          tint: NBColor.privacy
        )
      }
    }
  }

  private var startButtonTitle: String {
    appState.isPreparingCapture ? "캡처 준비 중" : "수면 시작"
  }

  private var startButtonIcon: String {
    appState.isPreparingCapture ? "hourglass" : "play.fill"
  }

  private func percentString(_ ratio: Double) -> String {
    String(format: "%.0f%%", min(max(ratio, 0), 1) * 100)
  }

  private var permissionDescription: String {
    switch appState.microphonePermissionState {
    case .notDetermined:
      "수면 시작을 누르면 iPhone에서 마이크 권한을 요청합니다."
    case .granted:
      "마이크 권한이 허용되어 실제 오디오 캡처 테스트를 시작할 수 있습니다."
    case .denied:
      "설정 앱에서 밤숨의 마이크 권한을 허용한 뒤 다시 시도해 주세요."
    }
  }

  private var permissionStatusKind: NBStatusKind {
    switch appState.microphonePermissionState {
    case .notDetermined:
      .caution
    case .granted:
      .good
    case .denied:
      .danger
    }
  }

  private var permissionStatusIcon: String {
    switch appState.microphonePermissionState {
    case .notDetermined:
      "questionmark.circle"
    case .granted:
      "checkmark.circle"
    case .denied:
      "xmark.circle"
    }
  }
}

private enum SleepStartDestination: Hashable {
  case latestReport
  case latestTimeline
  case trend
}

private struct GuideRow: View {
  let systemImage: String
  let title: String
  let description: String

  var body: some View {
    NBCard(padding: NBSpacing.medium) {
      NBListRow(
        title: title,
        subtitle: description,
        systemImage: systemImage,
        tint: NBColor.breathBlue
      )
    }
  }
}
