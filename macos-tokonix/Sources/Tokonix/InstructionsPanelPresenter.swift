import AppKit
import SwiftUI

@MainActor
final class InstructionsPanelPresenter {
    private var panel: NSPanel?

    func show(model: OverlayViewModel, anchorWindow: NSWindow?, onClose: @escaping () -> Void) {
        let size = NSSize(width: OverlayLayout.instructionsPanelWidth, height: OverlayLayout.instructionsPanelHeight)

        if let panel {
            updatePanel(panel, size: size)
            center(panel, anchorWindow: anchorWindow)
            panel.makeKeyAndOrderFront(nil)
            return
        }

        let panel = KeyablePanel(
            contentRect: NSRect(origin: .zero, size: size),
            styleMask: [.borderless],
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

        let hostingView = MovableHostingView(rootView: InstructionsPanel(model: model, onClose: onClose))
        hostingView.frame = NSRect(origin: .zero, size: size)
        panel.contentView = hostingView

        center(panel, anchorWindow: anchorWindow)
        panel.makeKeyAndOrderFront(nil)
        self.panel = panel
    }

    func close() {
        panel?.orderOut(nil)
        panel = nil
    }

    private func updatePanel(_ panel: NSPanel, size: NSSize) {
        panel.setContentSize(size)
        if let hostingView = panel.contentView {
            hostingView.frame = NSRect(origin: .zero, size: size)
        }
    }

    private func center(_ panel: NSPanel, anchorWindow: NSWindow?) {
        let screen = anchorWindow?.screen ?? NSScreen.main
        guard let screen else { return }
        let frame = screen.visibleFrame
        let size = panel.frame.size
        let origin = NSPoint(
            x: frame.midX - size.width / 2,
            y: frame.midY - size.height / 2
        )
        panel.setFrameOrigin(origin)
    }
}

final class KeyablePanel: NSPanel {
    override var canBecomeKey: Bool {
        true
    }

    override var canBecomeMain: Bool {
        true
    }
}
