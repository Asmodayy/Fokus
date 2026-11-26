import Foundation

struct UsageState: Codable, Equatable {
    /// Début de la tranche en cours (démarre à la première utilisation).
    var windowStart: Date?
    var usedSeconds: Double = 0
}

/// Compte le temps passé sur chaque réseau, uniquement quand son onglet est
/// affiché et que l'appli est au premier plan.
final class UsageTracker: ObservableObject {
    @Published private(set) var states: [String: UsageState] = [:]
    @Published private(set) var now = Date()

    /// Réseau actuellement à l'écran (nil = aucun, ou appli en arrière-plan).
    var activePlatform: Platform?

    private let settings: SettingsStore
    private var timer: Timer?
    private var lastTick = Date()
    private let key = "fokus.usage.v1"

    init(settings: SettingsStore) {
        self.settings = settings
        if let data = UserDefaults.standard.data(forKey: key),
           let decoded = try? JSONDecoder().decode([String: UsageState].self, from: data) {
            states = decoded
        }
        let t = Timer(timeInterval: 1, repeats: true) { [weak self] _ in
            self?.tick()
        }
        RunLoop.main.add(t, forMode: .common)
        timer = t
    }

    // MARK: - API

    func isLocked(_ platform: Platform) -> Bool {
        let config = self.config(platform)
        guard config.enabled else { return false }
        return currentState(platform, at: now).usedSeconds >= limitSeconds(config)
    }

    /// Temps restant sur la tranche, ou nil si aucune limite n'est active.
    func remaining(_ platform: Platform) -> TimeInterval? {
        let config = self.config(platform)
        guard config.enabled else { return nil }
        return max(0, limitSeconds(config) - currentState(platform, at: now).usedSeconds)
    }

    func unlockDate(_ platform: Platform) -> Date? {
        guard isLocked(platform), let start = currentState(platform, at: now).windowStart else { return nil }
        return start.addingTimeInterval(windowSeconds(config(platform)))
    }

    // MARK: - Interne

    private func config(_ platform: Platform) -> TimerConfig {
        settings.settings(for: platform).timer
    }

    private func limitSeconds(_ config: TimerConfig) -> Double {
        Double(config.limitMinutes * 60)
    }

    private func windowSeconds(_ config: TimerConfig) -> TimeInterval {
        TimeInterval(config.windowHours * 3600)
    }

    /// État de la tranche, remis à zéro si la tranche est terminée.
    private func currentState(_ platform: Platform, at date: Date) -> UsageState {
        var state = states[platform.rawValue] ?? UsageState()
        if let start = state.windowStart,
           date >= start.addingTimeInterval(windowSeconds(config(platform))) {
            state = UsageState()
        }
        return state
    }

    private func tick() {
        let date = Date()
        // Plafonné à 2 s : pas de saut de compteur au retour d'arrière-plan.
        let delta = min(max(date.timeIntervalSince(lastTick), 0), 2)
        lastTick = date

        if let platform = activePlatform {
            let config = self.config(platform)
            if config.enabled {
                var state = currentState(platform, at: date)
                if state.windowStart == nil { state.windowStart = date }
                let limit = limitSeconds(config)
                if state.usedSeconds < limit {
                    state.usedSeconds = min(limit, state.usedSeconds + delta)
                }
                states[platform.rawValue] = state
                save()
            }
        }
        now = date
    }

    private func save() {
        if let data = try? JSONEncoder().encode(states) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
}
