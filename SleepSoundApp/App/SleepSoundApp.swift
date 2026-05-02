import SwiftUI

@main
struct SleepSoundApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            HomeDashboardView()
                .environmentObject(appState)
        }
    }
}
