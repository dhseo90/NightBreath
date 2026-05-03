import SwiftUI

@main
struct SleepSoundApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            Group {
                if appState.hasCompletedOnboarding {
                    HomeDashboardView()
                } else {
                    OnboardingView()
                }
            }
            .environmentObject(appState)
        }
    }
}
