import Foundation

enum Platform: String, CaseIterable, Identifiable, Codable, Hashable {
    case instagram, facebook, youtube, tiktok

    var id: String { rawValue }

    var name: String {
        switch self {
        case .instagram: return "Instagram"
        case .facebook: return "Facebook"
        case .youtube: return "YouTube"
        case .tiktok: return "TikTok"
        }
    }

    var icon: String {
        switch self {
        case .instagram: return "camera"
        case .facebook: return "person.2"
        case .youtube: return "play.rectangle"
        case .tiktok: return "music.note"
        }
    }

    var homeURL: URL {
        switch self {
        case .instagram: return URL(string: "https://www.instagram.com/")!
        case .facebook: return URL(string: "https://m.facebook.com/")!
        case .youtube: return URL(string: "https://m.youtube.com/")!
        case .tiktok: return URL(string: "https://www.tiktok.com/")!
        }
    }

    /// Filtres proposés dans les réglages pour ce réseau.
    var availableFilters: [FilterKind] {
        switch self {
        case .instagram: return [.reels, .explore, .suggested]
        case .facebook: return [.reels, .suggested]
        case .youtube: return [.reels, .suggested, .homeFeed]
        case .tiktok: return [.appBanner]
        }
    }

    /// Le tirer-pour-rafraîchir gêne le scroll vertical de TikTok.
    var allowsPullToRefresh: Bool { self != .tiktok }
}

enum FilterKind: String, CaseIterable, Codable, Hashable {
    case reels, explore, suggested, homeFeed, appBanner

    func label(for platform: Platform) -> String {
        switch self {
        case .reels:
            switch platform {
            case .youtube: return "Masquer les Shorts"
            case .facebook: return "Masquer Reels et vidéos"
            default: return "Masquer les Reels"
            }
        case .explore:
            return "Masquer Explorer"
        case .suggested:
            return platform == .youtube
                ? "Masquer les vidéos suggérées"
                : "Masquer les suggestions et pubs"
        case .homeFeed:
            return "Masquer le fil d’accueil"
        case .appBanner:
            return "Masquer « Ouvrir l’appli »"
        }
    }
}
