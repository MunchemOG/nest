import AppKit
import NestKit
import SwiftUI
import WebKit

/// The approved 3D studio behind Home: the prototype's own scene, running locally in WebKit with three.js bundled in the app.
struct StudioView: NSViewRepresentable {
    let state: StudioState
    /// Each bird's newest action, so the studio can make it hop once when a new one arrives.
    let latestActions: [Bird: NestEvent]

    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    @Environment(\.reduceMotionOverride) private var reduceMotionOverride

    private var shownState: StudioState {
        var state = state
        state.reduceMotion = reduceMotionOverride ?? systemReduceMotion
        return state
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeNSView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.userContentController.addUserScript(WKUserScript(source: Self.fontFaces, injectionTime: .atDocumentStart, forMainFrameOnly: true))
        let view = WKWebView(frame: .zero, configuration: configuration)
        view.setValue(false, forKey: "drawsBackground")
        view.allowsMagnification = false
        view.navigationDelegate = context.coordinator
        view.setAccessibilityElement(false)
        Self.loadLocally(view)
        context.coordinator.view = view
        context.coordinator.update(state: shownState, latestActions: latestActions)
        return view
    }

    func updateNSView(_ view: WKWebView, context: Context) {
        context.coordinator.update(state: shownState, latestActions: latestActions)
    }

    /// Loads the studio with a rule that blocks every request except files inside the app,
    /// so nothing in the page can reach the network (the sandbox allows it only because WebKit needs it to start).
    private static func loadLocally(_ view: WKWebView) {
        guard let page = Bundle.main.url(forResource: "studio", withExtension: "html") else { return }
        WKContentRuleListStore.default().compileContentRuleList(forIdentifier: "nest.studio.local-only", encodedContentRuleList: localOnlyRules) { rules, _ in
            MainActor.assumeIsolated {
                if let rules { view.configuration.userContentController.add(rules) }
                view.loadFileURL(page, allowingReadAccessTo: Bundle.main.bundleURL)
            }
        }
    }

    /// Block everything, then allow `file:` URLs.
    static let localOnlyRules = #"[{"trigger":{"url-filter":".*"},"action":{"type":"block"}},{"trigger":{"url-filter":"^file:"},"action":{"type":"ignore-previous-rules"}}]"#

    /// `@font-face` rules pointing at the app's own font files, so the tags use Inter and Inter Tight offline.
    private static var fontFaces: String {
        let faces = NestFont.bundledFontURLs.compactMap { url -> String? in
            let family = switch url.deletingPathExtension().lastPathComponent {
            case "InterTight": "Inter Tight"
            case "Inter": "Inter"
            default: nil as String?
            }
            return family.map { "@font-face { font-family: \"\($0)\"; src: url(\"\(url.absoluteString)\"); font-weight: 100 900; }" }
        }
        let css = faces.joined(separator: " ").replacingOccurrences(of: "`", with: "")
        return "document.addEventListener('DOMContentLoaded', () => { const s = document.createElement('style'); s.textContent = `\(css)`; document.head.appendChild(s); });"
    }

    /// Sends the state to the page once it has loaded, and again whenever it changes.
    @MainActor
    final class Coordinator: NSObject, WKNavigationDelegate {
        weak var view: WKWebView?
        private var isLoaded = false
        private var sent: StudioState?
        private var state = StudioState()
        private var hopped: [Bird: String] = [:]
        private var latestActions: [Bird: NestEvent] = [:]

        func update(state: StudioState, latestActions: [Bird: NestEvent]) {
            self.state = state
            self.latestActions = latestActions
            flush()
        }

            nonisolated func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            MainActor.assumeIsolated {
                isLoaded = true
                hopped = latestActions.mapValues(\.id)
                flush()
            }
        }

        private func flush() {
            guard isLoaded, let view else { return }
            if sent != state {
                sent = state
                view.evaluateJavaScript("nest.set(\(state.script))")
            }
            for (bird, event) in latestActions where hopped[bird] != event.id {
                hopped[bird] = event.id
                let summary = (try? String(decoding: JSONSerialization.data(withJSONObject: [event.summary]), as: UTF8.self)) ?? "[\"\"]"
                view.evaluateJavaScript("nest.hop(\"\(bird.rawValue)\", \(summary)[0])")
            }
        }
    }
}

