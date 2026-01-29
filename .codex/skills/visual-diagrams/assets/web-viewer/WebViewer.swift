import AppKit
import WebKit

final class WebAppDelegate: NSObject, NSApplicationDelegate {
    private let url: URL
    private let windowTitle: String
    private let isFile: Bool
    private var window: NSWindow?

    init(url: URL, windowTitle: String, isFile: Bool) {
        self.url = url
        self.windowTitle = windowTitle
        self.isFile = isFile
        super.init()
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        let screenFrame = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1000, height: 700)
        let width = min(1200.0, screenFrame.width * 0.85)
        let height = min(860.0, screenFrame.height * 0.85)
        let originX = screenFrame.midX - width / 2.0
        let originY = screenFrame.midY - height / 2.0
        let frame = NSRect(x: originX, y: originY, width: width, height: height)

        let window = NSWindow(
            contentRect: frame,
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = windowTitle
        window.isReleasedWhenClosed = false

        let configuration = WKWebViewConfiguration()
        let webView = WKWebView(frame: window.contentView?.bounds ?? frame, configuration: configuration)
        webView.autoresizingMask = [.width, .height]
        webView.setValue(false, forKey: "drawsBackground")

        window.contentView = webView
        window.makeKeyAndOrderFront(nil)

        if isFile {
            let accessPath = url.deletingLastPathComponent()
            webView.loadFileURL(url, allowingReadAccessTo: accessPath)
        } else {
            let request = URLRequest(url: url)
            webView.load(request)
        }

        NSApp.activate(ignoringOtherApps: true)
        self.window = window
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }
}

let args = CommandLine.arguments
if args.count < 2 {
    fputs("Usage: WebViewer <url-or-path> [window-title]\n", stderr)
    exit(1)
}

let target = args[1]
let title = args.count > 2 ? args[2] : "Visual Notes"

let isFile = !(target.hasPrefix("http://") || target.hasPrefix("https://"))
let url = isFile
    ? URL(fileURLWithPath: target).standardizedFileURL
    : (URL(string: target) ?? URL(fileURLWithPath: target).standardizedFileURL)

let app = NSApplication.shared
app.setActivationPolicy(.regular)
let appDelegate = WebAppDelegate(url: url, windowTitle: title, isFile: isFile)
app.delegate = appDelegate
withExtendedLifetime(appDelegate) {
    app.run()
}
