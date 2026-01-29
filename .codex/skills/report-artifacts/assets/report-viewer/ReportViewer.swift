import AppKit
import WebKit

private func logMessage(_ message: String) {
    let env = ProcessInfo.processInfo.environment
    let logPath = env["REPORT_VIEWER_LOG"] ?? env["CODEX_HOME"].map { "\($0)/skill-workspaces/artifacts/report-viewer/ReportViewer.log" }
    guard let path = logPath else { return }
    let url = URL(fileURLWithPath: path)
    let line = "\(message)\n"
    if let data = line.data(using: .utf8) {
        if FileManager.default.fileExists(atPath: url.path) == false {
            FileManager.default.createFile(atPath: url.path, contents: nil)
        }
        if let handle = try? FileHandle(forWritingTo: url) {
            defer { try? handle.close() }
            try? handle.seekToEnd()
            try? handle.write(contentsOf: data)
        }
    }
}

final class ReportAppDelegate: NSObject, NSApplicationDelegate {
    private let url: URL
    private let windowTitle: String
    private var window: NSWindow?

    init(url: URL, windowTitle: String) {
        self.url = url
        self.windowTitle = windowTitle
        super.init()
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        let pid = ProcessInfo.processInfo.processIdentifier
        logMessage("ReportViewer launch pid=\(pid)")
        let env = ProcessInfo.processInfo.environment
        let envSummary = [
            "LSUIElement": env["LSUIElement"] ?? "nil",
            "LSBackgroundOnly": env["LSBackgroundOnly"] ?? "nil",
            "CGSessionID": env["CGSessionID"] ?? "nil"
        ]
        logMessage("ReportViewer env=\(envSummary)")
        DispatchQueue.main.async { [weak self] in
            self?.createWindow()
        }
    }

    private func createWindow() {
        let screenFrame = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1000, height: 700)
        logMessage("ReportViewer screen frame=\(screenFrame)")
        let width = min(1200.0, screenFrame.width * 0.8)
        let height = min(860.0, screenFrame.height * 0.8)
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
        logMessage("ReportViewer window created frame=\(frame)")

        let configuration = WKWebViewConfiguration()
        let webView = WKWebView(frame: window.contentView?.bounds ?? frame, configuration: configuration)
        webView.autoresizingMask = [.width, .height]
        webView.setValue(false, forKey: "drawsBackground")
        logMessage("ReportViewer webView created")

        window.contentView = webView
        window.center()
        window.makeKeyAndOrderFront(nil)
        window.orderFrontRegardless()
        logMessage("ReportViewer window ordered front")

        let accessPath = url.deletingLastPathComponent()
        webView.loadFileURL(url, allowingReadAccessTo: accessPath)
        logMessage("ReportViewer webView loading url=\(url.path)")

        NSApp.activate(ignoringOtherApps: true)
        NSRunningApplication.current.activate(options: [.activateIgnoringOtherApps, .activateAllWindows])
        self.window = window
        logMessage("ReportViewer window frame=\(frame) url=\(url.path)")
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }
}

let args = CommandLine.arguments
logMessage("ReportViewer args=\(args)")
if args.count < 2 {
    logMessage("ReportViewer missing args; exiting")
    fputs("Usage: ReportViewer <path-to-html> [window-title]\n", stderr)
    exit(1)
}

let htmlPath = args[1]
let title = args.count > 2 ? args[2] : "AI Report"

let url = URL(fileURLWithPath: htmlPath).standardizedFileURL
let app = NSApplication.shared
app.setActivationPolicy(.regular)
let appDelegate = ReportAppDelegate(url: url, windowTitle: title)
app.delegate = appDelegate
withExtendedLifetime(appDelegate) {
    app.run()
}
