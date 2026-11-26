import SwiftUI

@main
struct FokusApp: App {
    @StateObject private var settings: SettingsStore
    @StateObject private var tracker: UsageTracker
    @StateObject private var webStore: WebViewStore

    init() {
        let store = SettingsStore()
        _settings = StateObject(wrappedValue: store)
        _tracker = StateObject(wrappedValue: UsageTracker(settings: store))
        _webStore = StateObject(wrappedValue: WebViewStore(settings: store))
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(settings)
                .environmentObject(tracker)
                .environmentObject(webStore)
        }
    }
}
