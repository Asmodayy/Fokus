import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var settings: SettingsStore
    @EnvironmentObject private var tracker: UsageTracker
    @EnvironmentObject private var webStore: WebViewStore
    @State private var showClearConfirm = false

    var body: some View {
        NavigationView {
            List {
                ForEach(Platform.allCases) { platform in
                    PlatformSettingsSection(
                        platform: platform,
                        settings: settings.binding(for: platform),
                        locked: tracker.isLocked(platform),
                        remaining: tracker.remaining(platform)
                    )
                }

                Section {
                    Button("Se déconnecter de tous les comptes", role: .destructive) {
                        showClearConfirm = true
                    }
                } footer: {
                    Text("Efface les connexions et cookies de tous les réseaux dans Fokus. Fokus 1.0")
                }
            }
            .navigationTitle("Réglages")
            .confirmationDialog("Se déconnecter partout ?",
                                isPresented: $showClearConfirm,
                                titleVisibility: .visible) {
                Button("Se déconnecter", role: .destructive) { webStore.clearAllData() }
                Button("Annuler", role: .cancel) {}
            }
        }
        .navigationViewStyle(.stack)
    }
}

struct PlatformSettingsSection: View {
    let platform: Platform
    @Binding var settings: PlatformSettings
    let locked: Bool
    let remaining: TimeInterval?

    var body: some View {
        Section {
            Toggle("Afficher l’onglet", isOn: $settings.visible)

            ForEach(platform.availableFilters, id: \.self) { kind in
                Toggle(kind.label(for: platform), isOn: filterBinding(kind))
            }

            Toggle("Limiter le temps", isOn: $settings.timer.enabled)
                .disabled(locked)

            if settings.timer.enabled {
                Stepper(value: $settings.timer.limitMinutes, in: 5...120, step: 5) {
                    Text("Durée : \(settings.timer.limitMinutes) min")
                }
                .disabled(locked)

                Stepper(value: $settings.timer.windowHours, in: 1...24) {
                    Text("Toutes les \(settings.timer.windowHours) h")
                }
                .disabled(locked)
            }
        } header: {
            Label(platform.name, systemImage: platform.icon)
        } footer: {
            if locked {
                Text("Verrouillé en ce moment : la limite ne peut pas être modifiée avant le déblocage.")
            } else if settings.timer.enabled, let remaining = remaining {
                Text("Il reste \(TimeFormat.duration(remaining)) sur cette tranche. Le compteur ne tourne que quand l’onglet est ouvert.")
            }
        }
    }

    private func filterBinding(_ kind: FilterKind) -> Binding<Bool> {
        Binding(
            get: { settings.filters.contains(kind) },
            set: { isOn in
                if isOn {
                    settings.filters.insert(kind)
                } else {
                    settings.filters.remove(kind)
                }
            }
        )
    }
}
