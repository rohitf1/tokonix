import AppKit
import SwiftUI
import WebKit

struct OrbVisualState: Equatable {
    let isListening: Bool
    let isBusy: Bool
    let isSpeaking: Bool
    let isHovering: Bool
    let isEnabled: Bool
    let audioLevel: Double
    let silenceProgress: Double
}

struct ThreeOrbView: NSViewRepresentable {
    let state: OrbVisualState

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeNSView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.setValue(false, forKey: "drawsBackground")
        webView.wantsLayer = true
        webView.layer?.backgroundColor = NSColor.clear.cgColor

        let orbUrl = Bundle.module.url(forResource: "orb", withExtension: "html", subdirectory: "Orb")
            ?? Bundle.module.url(forResource: "orb", withExtension: "html")
        if let orbUrl {
            webView.loadFileURL(orbUrl, allowingReadAccessTo: orbUrl.deletingLastPathComponent())
        }

        context.coordinator.webView = webView
        return webView
    }

    func updateNSView(_ webView: WKWebView, context: Context) {
        context.coordinator.updateState(state)
    }

    final class Coordinator: NSObject, WKNavigationDelegate {
        weak var webView: WKWebView?
        private var lastState: OrbVisualState?
        private var pendingState: OrbVisualState?
        private var isReady = false

        func updateState(_ state: OrbVisualState) {
            if isReady {
                sendState(state)
            } else {
                pendingState = state
            }
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            isReady = true
            if let pendingState {
                sendState(pendingState)
                self.pendingState = nil
            }
        }

        private func sendState(_ state: OrbVisualState) {
            guard state != lastState else { return }
            guard let webView else { return }
            lastState = state
            let mode = stateMode(for: state)
            let level = (state.audioLevel * 100).rounded() / 100
            let silence = (state.silenceProgress * 100).rounded() / 100
            let payload: [String: Any] = [
                "mode": mode,
                "hover": state.isHovering,
                "enabled": state.isEnabled,
                "level": level,
                "silence": silence
            ]
            guard let data = try? JSONSerialization.data(withJSONObject: payload),
                  let json = String(data: data, encoding: .utf8) else {
                return
            }
            let js = "window.setOrbState && window.setOrbState(\(json));"
            webView.evaluateJavaScript(js, completionHandler: nil)
        }

        private func stateMode(for state: OrbVisualState) -> String {
            if state.isListening {
                return "listening"
            }
            if state.isBusy {
                return "busy"
            }
            if state.isSpeaking {
                return "speaking"
            }
            return "idle"
        }
    }
}
