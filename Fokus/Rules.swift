import Foundation

/// Redirections appliquées aux chargements de page complets.
/// (Les navigations internes des sites sont gérées par FilterScripts.)
enum Rules {
    static func redirect(for url: URL, platform: Platform, filters: Set<FilterKind>) -> URL? {
        let host = (url.host ?? "").lowercased()
        let path = url.path

        switch platform {
        case .instagram:
            guard host.hasSuffix("instagram.com") else { return nil }
            if filters.contains(.reels), matches(path, "/reels") {
                return platform.homeURL
            }
            if filters.contains(.explore), matches(path, "/explore") {
                return platform.homeURL
            }

        case .youtube:
            guard host.hasSuffix("youtube.com") else { return nil }
            if filters.contains(.reels), matches(path, "/shorts") {
                // Un Short envoyé par un ami s'ouvre comme une vidéo normale, sans scroll.
                let parts = path.split(separator: "/")
                if parts.count >= 2 {
                    return URL(string: "https://m.youtube.com/watch?v=\(parts[1])")
                }
                return platform.homeURL
            }

        case .facebook:
            guard host.hasSuffix("facebook.com") else { return nil }
            if filters.contains(.reels), matches(path, "/reels") || matches(path, "/watch") {
                return platform.homeURL
            }

        case .tiktok:
            break
        }
        return nil
    }

    private static func matches(_ path: String, _ prefix: String) -> Bool {
        path == prefix || path.hasPrefix(prefix + "/")
    }
}
