import AppKit
import SwiftUI

@MainActor
final class ModelPanelPresenter {
    private var panel: NSPanel?
    private let debugLogger = OverlayDebugLogger.shared

    func show(model: OverlayViewModel, anchorWindow: NSWindow?, onClose: @escaping () -> Void) {
        let size = NSSize(width: OverlayLayout.modelPickerWidth, height: 380)

        if let panel {
            updatePanel(panel, size: size)
            position(panel, anchorWindow: anchorWindow)
            panel.makeKeyAndOrderFront(nil)
            debugLogger.log("model panel reuse")
            return
        }

        let panel = NSPanel(
            contentRect: NSRect(origin: .zero, size: size),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.isFloatingPanel = true
        panel.level = .floating
        panel.hasShadow = false
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.isMovableByWindowBackground = true
        panel.hidesOnDeactivate = false
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

        let hostingView = MovableHostingView(rootView: ModelPickerPanel(model: model, onClose: onClose))
        hostingView.frame = NSRect(origin: .zero, size: size)
        panel.contentView = hostingView

        position(panel, anchorWindow: anchorWindow)
        panel.makeKeyAndOrderFront(nil)
        self.panel = panel
        debugLogger.log("model panel open")
    }

    func close() {
        debugLogger.log("model panel close")
        panel?.orderOut(nil)
        panel = nil
    }

    private func updatePanel(_ panel: NSPanel, size: NSSize) {
        panel.setContentSize(size)
        if let hostingView = panel.contentView {
            hostingView.frame = NSRect(origin: .zero, size: size)
        }
    }

    private func position(_ panel: NSPanel, anchorWindow: NSWindow?) {
        let screen = anchorWindow?.screen ?? NSScreen.main
        guard let screen else { return }
        let frame = screen.visibleFrame
        let size = panel.frame.size
        let margin: CGFloat = 16
        var origin = NSPoint(
            x: frame.maxX - size.width - margin,
            y: frame.maxY - size.height - margin
        )
        if let anchorWindow {
            let anchorFrame = anchorWindow.frame
            origin = NSPoint(
                x: anchorFrame.maxX - size.width,
                y: anchorFrame.maxY + 12
            )
        }
        let minX = frame.minX + margin
        let maxX = frame.maxX - size.width - margin
        let minY = frame.minY + margin
        let maxY = frame.maxY - size.height - margin
        origin.x = min(max(origin.x, minX), maxX)
        origin.y = min(max(origin.y, minY), maxY)
        panel.setFrameOrigin(origin)
    }
}
