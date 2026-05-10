import SwiftUI

@main
@MainActor
struct SleepSoundApp: App {
    @StateObject private var appState = AppState()
    @Environment(\.scenePhase) private var scenePhase
    #if DEBUG
    private let launchScreenshotScenario = ScreenshotScenario.launchArgumentScenario()
    private let launchScreenshotSurface = ScreenshotSurface.launchArgumentSurface()
    #endif

    init() {
        NBTabBarAppearance.configure()
    }

    var body: some Scene {
        WindowGroup {
            Group {
                #if DEBUG
                if let launchScreenshotScenario {
                    ScreenshotScenarioLaunchView(
                        scenario: launchScreenshotScenario,
                        surface: launchScreenshotSurface
                    )
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
            .overlay {
                if scenePhase != .active {
                    PrivacySnapshotCoverView()
                        .transition(.opacity)
                }
            }
        }
    }
}

struct PrivacySnapshotCoverView: View {
    var body: some View {
        ZStack {
            NBColor.pageBackground.ignoresSafeArea()

            VStack(spacing: NBSpacing.large) {
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 54, weight: .semibold))
                    .foregroundStyle(NBColor.privacyTint)
                    .accessibilityHidden(true)

                VStack(spacing: NBSpacing.xs) {
                    Text("밤숨")
                        .font(NBTypography.screenTitle)
                        .foregroundStyle(NBColor.primaryText)
                    Text("개인 데이터 보호 중")
                        .font(NBTypography.body)
                        .foregroundStyle(NBColor.secondaryText)
                }
            }
            .padding(NBSpacing.xl)
        }
        .privacySensitive()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("개인 데이터 보호 화면")
    }
}

#if DEBUG
struct PrivacySnapshotCoverQAView: View {
    var body: some View {
        PrivacySnapshotCoverView()
            .navigationTitle("Privacy Snapshot")
            .toolbar(.hidden, for: .tabBar)
            .background(NBColor.pageBackground)
            .nbAvoidFloatingTabBar()
    }
}
#endif

#if DEBUG
private struct ScreenshotScenarioLaunchView: View {
    @EnvironmentObject private var appState: AppState
    @State private var didApplyScenario = false
    let scenario: ScreenshotScenario
    let surface: ScreenshotSurface

    var body: some View {
        NavigationStack {
            ScreenshotScenarioDestinationView(scenario: scenario, surface: surface)
        }
        .onAppear {
            guard !didApplyScenario else { return }
            didApplyScenario = true
            appState.completeOnboarding()
            appState.applyScreenshotScenario(scenario, surface: surface)
        }
    }
}
#endif
