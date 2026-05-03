import SwiftUI

@main
struct SleepSoundApp: App {
    @StateObject private var appState = AppState()
    #if DEBUG
    private let launchScreenshotScenario = ScreenshotScenario.launchArgumentScenario()
    #endif

    var body: some Scene {
        WindowGroup {
            Group {
                #if DEBUG
                if let launchScreenshotScenario {
                    ScreenshotScenarioLaunchView(scenario: launchScreenshotScenario)
                } else if appState.hasCompletedOnboarding {
                    HomeDashboardView()
                } else {
                    OnboardingView()
                }
                #else
                if appState.hasCompletedOnboarding {
                    HomeDashboardView()
                } else {
                    OnboardingView()
                }
                #endif
            }
            .environmentObject(appState)
            .onOpenURL { url in
                appState.handleOpenURL(url)
            }
            .sheet(item: $appState.pendingFitdaysImportFile) { pendingFile in
                NavigationStack {
                    FitdaysImportView(
                        initialFileURL: pendingFile.url,
                        initialStatusMessage: pendingFile.statusMessage
                    )
                }
            }
            .alert(
                "Fitdays 가져오기",
                isPresented: Binding(
                    get: { appState.fitdaysOpenInMessage != nil },
                    set: { isPresented in
                        if !isPresented {
                            appState.fitdaysOpenInMessage = nil
                        }
                    }
                )
            ) {
                Button("확인", role: .cancel) {
                    appState.fitdaysOpenInMessage = nil
                }
            } message: {
                Text(appState.fitdaysOpenInMessage ?? "")
            }
        }
    }
}

#if DEBUG
private struct ScreenshotScenarioLaunchView: View {
    @EnvironmentObject private var appState: AppState
    @State private var didApplyScenario = false
    let scenario: ScreenshotScenario

    var body: some View {
        NavigationStack {
            ScreenshotScenarioDestinationView(scenario: scenario)
        }
        .onAppear {
            guard !didApplyScenario else { return }
            didApplyScenario = true
            appState.completeOnboarding()
            appState.applyScreenshotScenario(scenario)
        }
    }
}
#endif
