import SwiftUI

enum AppTab: Hashable {
    case platform(Platform)
    case settings
}

struct ContentView: View {
    @EnvironmentObject private var settings: SettingsStore
    @EnvironmentObject private var tracker: UsageTracker
    @EnvironmentObject private var webStore: WebViewStore
    @Environment(\.scenePhase) private var scenePhase

    @State private var selection: AppTab = .platform(.instagram)

    var body: some View {
        TabView(selection: $selection) {
            ForEach(settings.visiblePlatforms) { platform in
                PlatformView(platform: platform)
                    .tabItem { Label(platform.name, systemImage: platform.icon) }
                    .tag(AppTab.platform(platform))
            }
            SettingsView()
                .tabItem { Label("Réglages", systemImage: "gearshape") }
                .tag(AppTab.settings)
        }
        .tint(.purple)
        .onAppear {
            fixSelection()
            updateActive()
        }
        .onChange(of: selection) { _ in updateActive() }
        .onChange(of: scenePhase) { _ in updateActive() }
        .onChange(of: settings.visiblePlatforms) { _ in fixSelection() }
    }

    /// Si l'onglet sélectionné a été masqué dans les réglages, on en choisit un autre.
    private func fixSelection() {
        if case .platform(let platform) = selection, !settings.visiblePlatforms.contains(platform) {
            selection = settings.visiblePlatforms.first.map { AppTab.platform($0) } ?? .settings
        }
    }

    /// Indique au compteur quel réseau est à l'écran, et coupe les vidéos des autres onglets.
    private func updateActive() {
        guard scenePhase == .active else {
            tracker.activePlatform = nil
            return
        }
        switch selection {
        case .platform(let platform):
            tracker.activePlatform = platform
            webStore.pauseMedia(except: platform)
        case .settings:
            tracker.activePlatform = nil
            webStore.pauseMedia(except: nil)
        }
    }
}
