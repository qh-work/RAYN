import SwiftUI

@main
@MainActor
struct RAYNApp: App {
    @StateObject private var appState = AppState()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            BroadcastView()
                .environmentObject(appState)
        }
        .onChange(of: scenePhase) { _, phase in
            appState.handleScenePhase(phase)
        }
    }
}
