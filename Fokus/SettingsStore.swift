import Foundation
import SwiftUI

struct TimerConfig: Codable, Equatable {
    var enabled: Bool
    var limitMinutes: Int
    var windowHours: Int
}

struct PlatformSettings: Codable, Equatable {
    var visible: Bool
    var filters: Set<FilterKind>
    var timer: TimerConfig

    static func defaults(for platform: Platform) -> PlatformSettings {
        var filters = Set(platform.availableFilters)
        filters.remove(.homeFeed)
        return PlatformSettings(
            visible: true,
            filters: filters,
            timer: TimerConfig(enabled: platform == .tiktok, limitMinutes: 20, windowHours: 3)
        )
    }
}

final class SettingsStore: ObservableObject {
    @Published var platforms: [String: PlatformSettings] {
        didSet { save() }
    }

    private let key = "fokus.settings.v1"

    init() {
        if let data = UserDefaults.standard.data(forKey: key),
           let decoded = try? JSONDecoder().decode([String: PlatformSettings].self, from: data) {
            platforms = decoded
        } else {
            platforms = [:]
        }
    }

    func settings(for platform: Platform) -> PlatformSettings {
        platforms[platform.rawValue] ?? .defaults(for: platform)
    }

    func binding(for platform: Platform) -> Binding<PlatformSettings> {
        Binding(
            get: { self.settings(for: platform) },
            set: { self.platforms[platform.rawValue] = $0 }
        )
    }

    var visiblePlatforms: [Platform] {
        Platform.allCases.filter { settings(for: $0).visible }
    }

    private func save() {
        if let data = try? JSONEncoder().encode(platforms) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
}
