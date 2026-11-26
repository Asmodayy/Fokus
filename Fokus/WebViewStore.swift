import Foundation
import UIKit
import WebKit
import Combine

/// Garde une WKWebView par réseau, pour que chaque onglet reste connecté
/// et garde sa position quand on change d'onglet.
final class WebViewStore: ObservableObject {
    static let userAgent =
        "Mozilla/5.0 (iPhone; CPU iPhone OS 18_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.0 Mobile/15E148 Safari/604.1"

    private let settings: SettingsStore
    private var webViews: [Platform: WKWebView] = [:]
    private var navigators: [Platform: Navigator] = [:]
    private var appliedFilters: [Platform: Set<FilterKind>] = [:]
    private var cancellable: AnyCancellable?

    init(settings: SettingsStore) {
        self.settings = settings
        cancellable = settings.$platforms
            .receive(on: RunLoop.main)
            .sink { [weak self] all in
                self?.refreshFilters(all)
            }
    }

    func webView(for platform: Platform) -> WKWebView {
        if let existing = webViews[platform] { return existing }

        let config = WKWebViewConfiguration()
        config.websiteDataStore = .default()
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.customUserAgent = Self.userAgent
        webView.allowsBackForwardNavigationGestures = true

        let navigator = Navigator(platform: platform, settings: settings)
        navigator.webView = webView
        webView.navigationDelegate = navigator
        webView.uiDelegate = navigator
        navigators[platform] = navigator

        if platform.allowsPullToRefresh {
            let refresh = UIRefreshControl()
            refresh.addTarget(navigator, action: #selector(Navigator.handleRefresh(_:)), for: .valueChanged)
            webView.scrollView.refreshControl = refresh
        }

        install(settings.settings(for: platform).filters, for: platform, in: webView)
        webView.load(URLRequest(url: platform.homeURL))
        webViews[platform] = webView
        return webView
    }

    func goBack(_ platform: Platform) {
        guard let webView = webViews[platform], webView.canGoBack else { return }
        webView.goBack()
    }

    func goHome(_ platform: Platform) {
        webViews[platform]?.load(URLRequest(url: platform.homeURL))
    }

    func reload(_ platform: Platform) {
        webViews[platform]?.reload()
    }

    func pauseMedia(_ platform: Platform) {
        webViews[platform]?.evaluateJavaScript(Self.pauseScript, completionHandler: nil)
    }

    /// Met en pause les vidéos de tous les onglets sauf celui affiché.
    func pauseMedia(except visible: Platform?) {
        for (platform, webView) in webViews where platform != visible {
            webView.evaluateJavaScript(Self.pauseScript, completionHandler: nil)
        }
    }

    func clearAllData() {
        let store = WKWebsiteDataStore.default()
        store.removeData(ofTypes: WKWebsiteDataStore.allWebsiteDataTypes(), modifiedSince: .distantPast) { [weak self] in
            guard let self = self else { return }
            for (platform, webView) in self.webViews {
                webView.load(URLRequest(url: platform.homeURL))
            }
        }
    }

    // MARK: - Interne

    private static let pauseScript =
        "document.querySelectorAll('video,audio').forEach(function(m){try{m.pause();}catch(e){}});"

    private func install(_ filters: Set<FilterKind>, for platform: Platform, in webView: WKWebView) {
        let controller = webView.configuration.userContentController
        controller.removeAllUserScripts()
        let script = WKUserScript(
            source: FilterScripts.source(for: platform, filters: filters),
            injectionTime: .atDocumentStart,
            forMainFrameOnly: true
        )
        controller.addUserScript(script)
        appliedFilters[platform] = filters
    }

    private func refreshFilters(_ all: [String: PlatformSettings]) {
        for (platform, webView) in webViews {
            let filters = (all[platform.rawValue] ?? .defaults(for: platform)).filters
            if appliedFilters[platform] != filters {
                install(filters, for: platform, in: webView)
                webView.reload()
            }
        }
    }
}

final class Navigator: NSObject, WKNavigationDelegate, WKUIDelegate {
    let platform: Platform
    private let settings: SettingsStore
    weak var webView: WKWebView?

    init(platform: Platform, settings: SettingsStore) {
        self.platform = platform
        self.settings = settings
        super.init()
    }

    func webView(_ webView: WKWebView,
                 decidePolicyFor navigationAction: WKNavigationAction,
                 decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard let url = navigationAction.request.url else {
            decisionHandler(.allow)
            return
        }

        // Bloque les liens « Ouvrir dans l'appli » (instagram://, tiktok://, etc.)
        let scheme = (url.scheme ?? "").lowercased()
        let webSchemes: Set<String> = ["http", "https", "about", "blob", "data", "javascript"]
        guard webSchemes.contains(scheme) else {
            decisionHandler(.cancel)
            return
        }

        let isMainFrame = navigationAction.targetFrame?.isMainFrame ?? true
        if isMainFrame,
           let target = Rules.redirect(for: url, platform: platform,
                                       filters: settings.settings(for: platform).filters) {
            decisionHandler(.cancel)
            webView.load(URLRequest(url: target))
            return
        }
        decisionHandler(.allow)
    }

    // Liens qui s'ouvrent dans une nouvelle fenêtre : on les ouvre dans le même onglet.
    func webView(_ webView: WKWebView,
                 createWebViewWith configuration: WKWebViewConfiguration,
                 for navigationAction: WKNavigationAction,
                 windowFeatures: WKWindowFeatures) -> WKWebView? {
        if navigationAction.targetFrame == nil {
            webView.load(navigationAction.request)
        }
        return nil
    }

    @objc func handleRefresh(_ sender: UIRefreshControl) {
        webView?.reload()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            sender.endRefreshing()
        }
    }
}
