import AppKit
import SwiftUI

@main
struct TokonixApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var windowController: OverlayWindowController?
    private let debugLogger = OverlayDebugLogger.shared

    func applicationDidFinishLaunching(_ notification: Notification) {
        let controller = OverlayWindowController()
        controller.showWindow(nil)
        windowController = controller
        debugLogger.log("app didFinishLaunching")
    }

    func applicationWillTerminate(_ notification: Notification) {
        debugLogger.log("app willTerminate")
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        debugLogger.log("app terminateAfterLastWindowClosed false")
        return false
    }
}

final class OverlayWindowController: NSWindowController, NSWindowDelegate {
    private let debugLogger = OverlayDebugLogger.shared

    init() {
        let env = ProcessInfo.processInfo.environment
        let isProbeMode = env["TOKONIX_OVERLAY_MIC_STRESS"] == "1" || env["TOKONIX_OVERLAY_MIC_TOGGLE"] == "1"
        let rootView = isProbeMode ? AnyView(ProbeRootView()) : AnyView(OverlayRootView())
        let hostingView = DraggableHostingView(rootView: rootView)
        hostingView.translatesAutoresizingMaskIntoConstraints = false

        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: OverlayLayout.windowWidth, height: OverlayLayout.windowHeight),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.isFloatingPanel = true
        panel.level = .floating
        panel.hasShadow = false
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.hidesOnDeactivate = false
        panel.contentView = hostingView
        panel.titleVisibility = .hidden
        panel.titlebarAppearsTransparent = true
        panel.isMovableByWindowBackground = false

        super.init(window: panel)
        panel.delegate = self
        positionBottomCenter(panel)
        debugLogger.log("window created")
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func positionBottomCenter(_ window: NSWindow) {
        guard let screen = NSScreen.main else { return }
        let frame = screen.visibleFrame
        let size = window.frame.size
        let margin: CGFloat = 24
        let x = frame.midX - size.width / 2
        let y = frame.minY + margin
        window.setFrameOrigin(NSPoint(x: x, y: y))
    }

    func windowWillClose(_ notification: Notification) {
        debugLogger.log("window willClose")
    }

    func windowDidResignKey(_ notification: Notification) {
        debugLogger.log("window didResignKey")
    }
}

final class DraggableHostingView<Content: View>: NSHostingView<Content> {
    override var mouseDownCanMoveWindow: Bool {
        false
    }

    override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
        true
    }
}
