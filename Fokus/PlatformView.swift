import SwiftUI
import WebKit

struct PlatformView: View {
    let platform: Platform
    @EnvironmentObject private var tracker: UsageTracker
    @EnvironmentObject private var webStore: WebViewStore

    var body: some View {
        let locked = tracker.isLocked(platform)
        VStack(spacing: 0) {
            topBar
            ZStack {
                WebViewContainer(webView: webStore.webView(for: platform))
                if locked {
                    LockView(platform: platform,
                             unlockDate: tracker.unlockDate(platform),
                             now: tracker.now)
                }
            }
        }
        .onChange(of: locked) { isLocked in
            if isLocked { webStore.pauseMedia(platform) }
        }
        .onAppear {
            if locked { webStore.pauseMedia(platform) }
        }
    }

    private var topBar: some View {
        HStack(spacing: 20) {
            Button { webStore.goBack(platform) } label: {
                Image(systemName: "chevron.left")
            }
            Button { webStore.goHome(platform) } label: {
                Image(systemName: "house")
            }
            Button { webStore.reload(platform) } label: {
                Image(systemName: "arrow.clockwise")
            }
            Spacer()
            if let remaining = tracker.remaining(platform) {
                Label(TimeFormat.duration(remaining), systemImage: "timer")
                    .font(.subheadline.monospacedDigit().weight(.semibold))
                    .foregroundColor(remaining < 120 ? .red : .primary)
            }
        }
        .font(.body.weight(.medium))
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(.bar)
    }
}

struct WebViewContainer: UIViewRepresentable {
    let webView: WKWebView

    func makeUIView(context: Context) -> UIView {
        let container = UIView()
        attach(to: container)
        return container
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        if webView.superview !== uiView {
            attach(to: uiView)
        }
    }

    private func attach(to container: UIView) {
        webView.removeFromSuperview()
        webView.frame = container.bounds
        webView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        container.addSubview(webView)
    }
}

struct LockView: View {
    let platform: Platform
    let unlockDate: Date?
    let now: Date

    var body: some View {
        ZStack {
            Color(.systemBackground)
                .opacity(0.97)
            VStack(spacing: 14) {
                Image(systemName: "lock.fill")
                    .font(.system(size: 44))
                    .foregroundColor(.purple)
                Text("Pause \(platform.name)")
                    .font(.title2.bold())
                Text("Tu as utilisé ton temps pour cette tranche.")
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                if let unlock = unlockDate {
                    Text(TimeFormat.duration(max(0, unlock.timeIntervalSince(now))))
                        .font(.system(size: 46, weight: .bold, design: .rounded).monospacedDigit())
                        .padding(.top, 8)
                    Text("Débloqué à \(TimeFormat.clock(unlock))")
                        .foregroundColor(.secondary)
                }
            }
            .padding(32)
        }
        .contentShape(Rectangle())
    }
}

enum TimeFormat {
    static func duration(_ interval: TimeInterval) -> String {
        let total = Int(interval.rounded(.up))
        let hours = total / 3600
        let minutes = (total % 3600) / 60
        let seconds = total % 60
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        }
        return String(format: "%d:%02d", minutes, seconds)
    }

    static func clock(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "fr_FR")
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}
