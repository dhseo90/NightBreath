import SwiftUI

#if DEBUG
@MainActor
private enum NBPreviewFactory {
  static func appState(recording: Bool = false) -> AppState {
    let settings = PreviewUserSettings()
    settings.isEventAudioSampleStorageEnabled = true
    settings.hasCompletedOnboarding = true

    let state = AppState(
      repository: InMemorySleepRepository(),
      audioSessionManager: PreviewAudioSessionManager(),
      audioCaptureService: MockAudioCaptureService(),
      userSettings: settings
    )

    if recording {
      state.activeSession = state.latestSession
      state.audioCaptureState = .capturing(startedAt: state.latestSession.startedAt)
      state.latestAudioLevel = 0.07
      state.capturedAudioChunkCount = 48
      state.detectedEventCandidateCount = 3
      state.latestDetectedEventText = "코골기 후보"
    }

    return state
  }
}

private final class PreviewUserSettings: UserSettingsProviding {
  var isEventAudioSampleStorageEnabled = false
  var hasCompletedOnboarding = false
}

@MainActor
private struct NBPreviewShell<Content: View>: View {
  let title: String
  let colorScheme: ColorScheme
  let appState: AppState
  let content: Content

  init(
    _ title: String,
    colorScheme: ColorScheme,
    appState: AppState = NBPreviewFactory.appState(),
    @ViewBuilder content: () -> Content
  ) {
    self.title = title
    self.colorScheme = colorScheme
    self.appState = appState
    self.content = content()
  }

  var body: some View {
    NavigationStack {
      content
    }
    .environmentObject(appState)
    .preferredColorScheme(colorScheme)
    .previewDisplayName(title)
  }
}

@MainActor
struct NBPrimaryScreenAppearance_Previews: PreviewProvider {
  static var previews: some View {
    Group {
      NBPreviewShell("HomeDashboardView Light", colorScheme: .light) {
        HomeDashboardView()
      }
      NBPreviewShell("HomeDashboardView Dark", colorScheme: .dark) {
        HomeDashboardView()
      }

      NBPreviewShell("SleepStartView Light", colorScheme: .light) {
        SleepStartView()
      }
      NBPreviewShell("SleepStartView Dark", colorScheme: .dark) {
        SleepStartView()
      }

      NBPreviewShell("SleepRecordingView Light", colorScheme: .light, appState: NBPreviewFactory.appState(recording: true)) {
        SleepRecordingView()
      }
      NBPreviewShell("SleepRecordingView Dark", colorScheme: .dark, appState: NBPreviewFactory.appState(recording: true)) {
        SleepRecordingView()
      }

      NBPreviewShell("SleepReportView Light", colorScheme: .light) {
        SleepReportView(
          report: NBPreviewFactory.appState().latestReport,
          events: NBPreviewFactory.appState().latestEvents
        )
      }
      NBPreviewShell("SleepReportView Dark", colorScheme: .dark) {
        SleepReportView(
          report: NBPreviewFactory.appState().latestReport,
          events: NBPreviewFactory.appState().latestEvents
        )
      }

      NBPreviewShell("SleepTimelineView Light", colorScheme: .light) {
        SleepTimelineView(
          report: NBPreviewFactory.appState().latestReport,
          events: NBPreviewFactory.appState().latestEvents
        )
      }
      NBPreviewShell("SleepTimelineView Dark", colorScheme: .dark) {
        SleepTimelineView(
          report: NBPreviewFactory.appState().latestReport,
          events: NBPreviewFactory.appState().latestEvents
        )
      }

      NBPreviewShell("PrivacySettingsView Light", colorScheme: .light) {
        PrivacySettingsView()
      }
      NBPreviewShell("PrivacySettingsView Dark", colorScheme: .dark) {
        PrivacySettingsView()
      }

      NBPreviewShell("HealthDashboardView Light", colorScheme: .light) {
        HealthDashboardView(service: MockHealthKitService())
      }
      NBPreviewShell("HealthDashboardView Dark", colorScheme: .dark) {
        HealthDashboardView(service: MockHealthKitService())
      }

      NBPreviewShell("TrendDashboardView Light", colorScheme: .light) {
        TrendDashboardView()
      }
      NBPreviewShell("TrendDashboardView Dark", colorScheme: .dark) {
        TrendDashboardView()
      }

      NBPreviewShell("DetectorTuningView Dark", colorScheme: .dark) {
        DetectorTuningView()
      }
    }
  }
}
#endif
