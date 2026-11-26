import Foundation

/// Génère le script injecté dans chaque page pour masquer Reels, Shorts, etc.
/// Les sites changent souvent leur code : si un élément réapparaît,
/// c'est ici qu'il faut ajuster les sélecteurs.
enum FilterScripts {
    static func source(for platform: Platform, filters: Set<FilterKind>) -> String {
        var config: [String: Any] = ["platform": platform.rawValue]
        for kind in FilterKind.allCases {
            config[kind.rawValue] = filters.contains(kind)
        }
        let configJSON = (try? JSONSerialization.data(withJSONObject: config))
            .flatMap { String(data: $0, encoding: .utf8) } ?? "{}"
        let cssJSON = jsonStringLiteral(css(for: platform, filters: filters))

        return template
            .replacingOccurrences(of: "__FOKUS_CONFIG__", with: configJSON)
            .replacingOccurrences(of: "__FOKUS_CSS__", with: cssJSON)
    }

    // MARK: - CSS par réseau

    static func css(for platform: Platform, filters: Set<FilterKind>) -> String {
        var rules: [String] = []

        switch platform {
        case .instagram:
            if filters.contains(.reels) {
                rules.append(#"""
                a[href="/reels/"], a[href^="/reels/"], a[href$="/reels/"],
                article:has(a[href*="/reel/"]) { display: none !important; }
                """#)
            }
            if filters.contains(.explore) {
                rules.append(#"a[href="/explore/"], a[href^="/explore"] { display: none !important; }"#)
            }

        case .youtube:
            if filters.contains(.reels) {
                rules.append(#"""
                ytm-reel-shelf-renderer, ytm-reel-item-renderer,
                ytm-shorts-lockup-view-model, ytm-shorts-lockup-view-model-v2,
                ytm-rich-section-renderer:has(ytm-reel-shelf-renderer),
                ytm-rich-section-renderer:has(ytm-shorts-lockup-view-model),
                ytm-rich-section-renderer:has(ytm-shorts-lockup-view-model-v2),
                ytm-pivot-bar-item-renderer:has(.pivot-shorts),
                ytm-rich-item-renderer:has(a[href^="/shorts"]),
                ytm-video-with-context-renderer:has(a[href^="/shorts"]),
                ytm-compact-video-renderer:has(a[href^="/shorts"]) { display: none !important; }
                """#)
            }
            if filters.contains(.suggested) {
                rules.append(#"""
                ytm-item-section-renderer[section-identifier="related-items"],
                ytm-watch-next-secondary-results-renderer,
                .ytm-autonav-bar, .ytp-autonav-endscreen-countdown-overlay,
                .ytp-endscreen-content { display: none !important; }
                """#)
            }
            if filters.contains(.homeFeed) {
                rules.append(#"""
                html.fokus-home ytm-rich-grid-renderer,
                html.fokus-home ytm-browse ytm-section-list-renderer,
                html.fokus-home ytm-feed-filter-chip-bar-renderer { display: none !important; }
                html.fokus-home ytm-browse::after {
                  content: "Fil d’accueil masqué par Fokus. Utilise la recherche 🔍";
                  display: block; padding: 48px 24px; text-align: center;
                  color: #888; font-size: 15px;
                }
                """#)
            }

        case .facebook:
            if filters.contains(.reels) {
                rules.append(#"""
                a[href*="/reel/"], a[href*="/reels/"], a[href*="/watch/"],
                article:has(a[href*="/reel/"]),
                [role="article"]:has(a[href*="/reel/"]) { display: none !important; }
                """#)
            }

        case .tiktok:
            if filters.contains(.appBanner) {
                rules.append(#"""
                [class*="OpenInApp"], [class*="openInApp"], [class*="AppDownload"],
                [class*="DivBottomBannerContainer"], [data-e2e*="open-app"],
                [data-e2e*="launch-app"] { display: none !important; }
                """#)
            }
        }
        return rules.joined(separator: "\n")
    }

    // MARK: - Utilitaires

    private static func jsonStringLiteral(_ string: String) -> String {
        if let data = try? JSONSerialization.data(withJSONObject: [string]),
           let array = String(data: data, encoding: .utf8) {
            return String(array.dropFirst().dropLast())
        }
        return "\"\""
    }

    // MARK: - Script

    private static let template = #"""
    (function () {
      if (window.__fokusLoaded) { return; }
      window.__fokusLoaded = true;

      var C = __FOKUS_CONFIG__;
      var CSS = __FOKUS_CSS__;
      var PHRASES = [
        'Suggested for you', 'Suggestions pour vous', 'Suggested posts',
        'Publications suggérées', 'Sponsored', 'Sponsorisé', 'Sponsorisée',
        'Reels and short videos', 'Reels et vidéos courtes'
      ];

      function addStyle() {
        if (!CSS || document.getElementById('fokus-style')) { return; }
        var root = document.head || document.documentElement;
        if (!root) { return; }
        var style = document.createElement('style');
        style.id = 'fokus-style';
        style.textContent = CSS;
        root.appendChild(style);
      }

      function redirectTarget() {
        var p = location.pathname;
        if (C.platform === 'instagram') {
          if (C.reels && /^\/reels(\/|$)/.test(p)) { return '/'; }
          if (C.explore && /^\/explore(\/|$)/.test(p)) { return '/'; }
        } else if (C.platform === 'youtube') {
          if (C.reels) {
            var m = p.match(/^\/shorts\/([^\/?#]+)/);
            if (m) { return '/watch?v=' + m[1]; }
            if (/^\/shorts\/?$/.test(p)) { return '/'; }
          }
        } else if (C.platform === 'facebook') {
          if (C.reels && /^\/(reels|watch)(\/|$)/.test(p)) { return '/'; }
        }
        return null;
      }

      function checkRedirect() {
        var target = redirectTarget();
        if (target && target !== location.pathname + location.search) {
          location.replace(target);
        }
      }

      function hideByText(selector, phrases) {
        var nodes = document.querySelectorAll(selector);
        for (var i = 0; i < nodes.length; i++) {
          var el = nodes[i];
          if (el.style.display === 'none') { continue; }
          var text = el.textContent || '';
          for (var j = 0; j < phrases.length; j++) {
            if (text.indexOf(phrases[j]) !== -1) {
              el.style.setProperty('display', 'none', 'important');
              break;
            }
          }
        }
      }

      function sweep() {
        addStyle();
        if (C.platform === 'youtube') {
          var isHome = location.pathname === '/';
          document.documentElement.classList.toggle('fokus-home', !!(C.homeFeed && isHome));
        }
        if (C.suggested) {
          if (C.platform === 'instagram') { hideByText('article', PHRASES); }
          if (C.platform === 'facebook') { hideByText('article, [role="article"]', PHRASES); }
        }
      }

      var pending = false;
      function schedule() {
        if (pending) { return; }
        pending = true;
        setTimeout(function () {
          pending = false;
          try { sweep(); } catch (e) {}
        }, 250);
      }

      function onNavigate() {
        checkRedirect();
        schedule();
      }

      ['pushState', 'replaceState'].forEach(function (name) {
        var original = history[name];
        history[name] = function () {
          var result = original.apply(this, arguments);
          try { onNavigate(); } catch (e) {}
          return result;
        };
      });
      window.addEventListener('popstate', onNavigate);

      checkRedirect();
      addStyle();
      new MutationObserver(schedule).observe(document.documentElement, { childList: true, subtree: true });
      document.addEventListener('DOMContentLoaded', schedule);
      setInterval(checkRedirect, 1000);
    })();
    """#
}
