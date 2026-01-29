import AppKit
import SwiftUI

struct OverlayRootView: View {
    @StateObject private var model = OverlayViewModel()
    @State private var isHovering = false
    @State private var isOrbHovering = false
    @State private var isConfigurationsOpen = false
    @State private var configurationsPanelPresenter = ConfigurationsPanelPresenter()
    @State private var dragStartMouse: NSPoint?
    @State private var dragStartOrigin: NSPoint?
    @State private var newSessionPulseToken = 0

    var body: some View {
        ZStack {
            Color.clear

            orbCluster

            if isHovering && !isConfigurationsOpen {
                HoverControls(
                    model: model,
                    onClose: { NSApplication.shared.terminate(nil) },
                    onConfigurations: {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
                            if isConfigurationsOpen {
                                closeConfigurationsPanel()
                            } else {
                                isConfigurationsOpen = true
                                configurationsPanelPresenter.show(model: model, anchorWindow: overlayWindow()) {
                                    closeConfigurationsPanel()
                                }
                            }
                        }
                    },
                    onNewSession: {
                        newSessionPulseToken += 1
                        model.startNewThread()
                    }
                )
                .transition(.opacity.combined(with: .scale(scale: 0.96)))
            }

        }
        .frame(width: OverlayLayout.windowWidth, height: OverlayLayout.windowHeight)
        .contentShape(Rectangle())
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.25)) {
                isHovering = hovering
            }
        }
        .onAppear {
            model.start()
        }
    }

    private var orbCluster: some View {
        let historyScale: CGFloat = 1.0
        let hoverScale: CGFloat = isHovering ? 1.04 : 1.0
        return ZStack {
            ThreeOrbView(
                state: OrbVisualState(
                    isListening: model.isListening,
                    isBusy: model.isBusy,
                    isSpeaking: model.isSpeaking,
                    isHovering: isHovering,
                    isEnabled: model.isAutoListenEnabled,
                    audioLevel: model.audioLevel,
                    silenceProgress: model.silenceProgress
                )
            )
            .allowsHitTesting(false)

            NewSessionPulseRing(trigger: newSessionPulseToken)
                .frame(width: OverlayLayout.orbRingSize * 1.05, height: OverlayLayout.orbRingSize * 1.05)
                .allowsHitTesting(false)
                .zIndex(0.5)

            MicSilenceRing(
                progress: model.silenceProgress,
                isListening: model.isListening,
                isEnabled: model.isAutoListenEnabled,
                size: OverlayLayout.orbRingSize,
                lineWidth: 11.4,
                showButton: isOrbHovering,
                onToggle: { model.toggleListeningEnabled() }
            )
            .zIndex(1)

            if model.isReasoningVisible {
                ReasoningThoughtStream(
                    text: model.reasoningText,
                    isActive: model.isReasoningVisible,
                    palette: OverlayPalette.reasoningStream,
                    maxActive: 3,
                    repeatInterval: 0.6
                )
                .frame(width: OverlayLayout.orbFieldSize, height: OverlayLayout.orbFieldSize)
                .allowsHitTesting(false)
                .zIndex(2)
            }

            SentenceWordStream(
                userText: model.transcript,
                agentText: model.assistantSpokenText,
                isUserActive: model.isListening,
                isAgentActive: model.isSpeaking || !model.assistantSpokenText.isEmpty,
                maxLines: 3,
                maxWidth: OverlayLayout.orbFieldSize * 0.86
            )
            .frame(width: OverlayLayout.orbFieldSize, height: OverlayLayout.orbFieldSize)
            .offset(y: -OverlayLayout.orbSize * 1.05)
            .allowsHitTesting(false)
            .zIndex(2)

            VStack(spacing: 8) {
                let showThinkingTimer = model.isReasoningVisible || !model.thinkingElapsedText.isEmpty
                ReasoningTicker(
                    text: model.reasoningText,
                    isVisible: showThinkingTimer,
                    thinkingTime: model.thinkingElapsedText
                )
            }
            .frame(width: OverlayLayout.reasoningTickerWidth)
            .offset(y: OverlayLayout.orbSize * 0.9 + 18)
            .allowsHitTesting(false)
            .zIndex(2)
        }
        .frame(width: OverlayLayout.orbFieldSize, height: OverlayLayout.orbFieldSize)
        .background(Color.clear)
        .contentShape(Circle())
        .scaleEffect(historyScale * hoverScale)
        .offset(y: 0)
        .animation(.spring(response: 0.45, dampingFraction: 0.8), value: isHovering)
        .animation(.spring(response: 0.45, dampingFraction: 0.86), value: isConfigurationsOpen)
        .simultaneousGesture(dragGesture)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isOrbHovering = hovering
            }
        }
    }

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 12)
            .onChanged { _ in
                updateWindowDrag()
            }
            .onEnded { _ in
                endWindowDrag()
            }
    }

    private func updateWindowDrag() {
        guard let window = overlayWindow() else { return }
        let mouse = NSEvent.mouseLocation
        if dragStartMouse == nil {
            dragStartMouse = mouse
            dragStartOrigin = window.frame.origin
        }
        guard let startMouse = dragStartMouse,
              let startOrigin = dragStartOrigin else { return }
        let dx = mouse.x - startMouse.x
        let dy = mouse.y - startMouse.y
        window.setFrameOrigin(NSPoint(x: startOrigin.x + dx, y: startOrigin.y + dy))
    }

    private func endWindowDrag() {
        dragStartMouse = nil
        dragStartOrigin = nil
    }

    private func overlayWindow() -> NSWindow? {
        NSApplication.shared.windows.first { window in
            window.level == .floating && window.styleMask.contains(.borderless)
        }
    }

    private var orbFieldLeading: CGFloat {
        (OverlayLayout.windowWidth - OverlayLayout.orbFieldSize) / 2
    }

    private var orbFieldTop: CGFloat {
        (OverlayLayout.windowHeight - OverlayLayout.orbFieldSize) / 2
    }

    private func closeConfigurationsPanel() {
        configurationsPanelPresenter.close()
        isConfigurationsOpen = false
    }
}

struct HoverControls: View {
    @ObservedObject var model: OverlayViewModel
    let onClose: () -> Void
    let onConfigurations: () -> Void
    let onNewSession: () -> Void

    var body: some View {
        GeometryReader { proxy in
            let toggleSize: CGFloat = 22
            let orbCenter = CGPoint(x: proxy.size.width / 2, y: proxy.size.height / 2)
            let controlOffsetX: CGFloat = 18
            let toggleOrigin = CGPoint(
                x: orbCenter.x + OverlayLayout.orbRingSize / 2 - toggleSize - 6 + controlOffsetX,
                y: orbCenter.y - OverlayLayout.orbRingSize / 2 + 8
            )
            let closeOrigin = CGPoint(
                x: toggleOrigin.x - toggleSize - 6,
                y: toggleOrigin.y
            )
            let newSessionOrigin = CGPoint(
                x: closeOrigin.x - toggleSize - 6,
                y: toggleOrigin.y
            )

            ZStack(alignment: .topLeading) {
                if let error = model.errorMessage {
                    ErrorPod(message: error)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                        .padding(.trailing, 24)
                        .padding(.top, 10)
                }

                MenuToggleButton(isOpen: false) {
                    model.logUIEvent("configurations menu open")
                    onConfigurations()
                }
                .offset(x: toggleOrigin.x, y: toggleOrigin.y)

                NewSessionButton {
                    onNewSession()
                }
                .offset(x: newSessionOrigin.x, y: newSessionOrigin.y)

                CloseOverlayButton {
                    onClose()
                }
                .offset(x: closeOrigin.x, y: closeOrigin.y)
            }
        }
        .frame(width: OverlayLayout.windowWidth, height: OverlayLayout.windowHeight)
    }

}

private struct MenuToggleButton: View {
    let isOpen: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Image(systemName: isOpen ? "xmark" : "line.3.horizontal.decrease")
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 22, height: 22)
                .background(
                    Circle().fill(
                        LinearGradient(
                            colors: [OverlayPalette.neonBlue.opacity(0.85), OverlayPalette.cyan.opacity(0.65)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                )
                .overlay(
                    Circle().stroke(Color.white.opacity(0.3), lineWidth: 1)
                )
                .shadow(color: OverlayPalette.neonBlue.opacity(0.5), radius: 6)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isOpen ? "Hide actions" : "Show actions")
    }
}

private struct NewSessionButton: View {
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Image(systemName: "plus")
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 22, height: 22)
                .background(
                    Circle().fill(
                        LinearGradient(
                            colors: [OverlayPalette.cyan.opacity(0.85), OverlayPalette.neonBlue.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                )
                .overlay(
                    Circle().stroke(Color.white.opacity(0.3), lineWidth: 1)
                )
                .shadow(color: OverlayPalette.cyan.opacity(0.45), radius: 6)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("New session")
    }
}

private struct CloseOverlayButton: View {
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Image(systemName: "xmark")
                .font(.system(size: 9, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 22, height: 22)
                .background(
                    Circle().fill(
                        LinearGradient(
                            colors: [OverlayPalette.ember.opacity(0.9), OverlayPalette.magenta.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                )
                .overlay(
                    Circle().stroke(Color.white.opacity(0.3), lineWidth: 1)
                )
                .shadow(color: OverlayPalette.ember.opacity(0.45), radius: 6)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Close overlay")
    }
}

private struct ActionMenuRow: View {
    let label: String
    let systemName: String
    let colors: [Color]
    let shadow: Color
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 10) {
                MenuIconBadge(systemName: systemName, colors: colors, shadow: shadow)
                Text(label)
                    .font(.custom("Avenir Next", size: 10).weight(.semibold))
                    .foregroundColor(.white.opacity(0.95))
                Spacer()
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 8)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(OverlayPalette.deepSpace.opacity(0.35))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(OverlayPalette.neonBlue.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

private struct MenuIconBadge: View {
    let systemName: String
    let colors: [Color]
    let shadow: Color

    var body: some View {
        Image(systemName: systemName)
            .font(.system(size: 10, weight: .bold))
            .foregroundColor(.white)
            .frame(width: 18, height: 18)
            .background(
                Circle().fill(
                    LinearGradient(
                        colors: colors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            )
            .overlay(
                Circle().stroke(Color.white.opacity(0.3), lineWidth: 1)
            )
            .shadow(color: shadow.opacity(0.5), radius: 5)
    }
}

private struct ControlPod<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(podBackground)
            .overlay(podBorder)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .shadow(color: OverlayPalette.deepSpace.opacity(0.5), radius: 10, x: 0, y: 6)
    }

    private var podBackground: some View {
        RoundedRectangle(cornerRadius: 14, style: .continuous)
            .fill(.ultraThinMaterial)
            .overlay(
                LinearGradient(
                    colors: [
                        OverlayPalette.deepSpace.opacity(0.7),
                        OverlayPalette.neonBlue.opacity(0.15),
                        OverlayPalette.electricPurple.opacity(0.12),
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
    }

    private var podBorder: some View {
        RoundedRectangle(cornerRadius: 14, style: .continuous)
            .stroke(
                LinearGradient(
                    colors: [
                        OverlayPalette.cyan.opacity(0.5),
                        OverlayPalette.magenta.opacity(0.3),
                        OverlayPalette.teal.opacity(0.4),
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: 1
            )
    }
}

private struct ErrorPod: View {
    let message: String

    var body: some View {
        ControlPod {
            VStack(alignment: .leading, spacing: 6) {
                Text("Error")
                    .font(.custom("Avenir Next", size: 9).weight(.semibold))
                    .foregroundColor(.white.opacity(0.7))
                    .tracking(0.6)
                ScrollView {
                    Text(message)
                        .font(.custom("Avenir Next", size: 10))
                        .foregroundColor(OverlayPalette.ember)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .textSelection(.enabled)
                }
            }
        }
        .frame(width: 260, height: 120)
    }
}

struct ModelPickerButton: View {
    @ObservedObject var model: OverlayViewModel
    @State private var isPresented = false

    var body: some View {
        Button(action: togglePopover) {
            Image(systemName: "slider.horizontal.3")
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 20, height: 20)
                .background(
                    Circle().fill(
                        LinearGradient(
                            colors: [OverlayPalette.teal.opacity(0.85), OverlayPalette.cyan.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                )
                .overlay(
                    Circle().stroke(Color.white.opacity(0.3), lineWidth: 1)
                )
                .shadow(color: OverlayPalette.teal.opacity(0.5), radius: 6)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Choose model and reasoning effort")
        .popover(isPresented: $isPresented, arrowEdge: .top) {
            ModelPickerPanel(model: model)
        }
    }

    private func togglePopover() {
        let opening = !isPresented
        isPresented.toggle()
        model.logUIEvent("model popover \(opening ? "open" : "close")")
        if opening {
            model.refreshModels(force: true)
        }
    }
}

struct ModelPickerPanel: View {
    @ObservedObject var model: OverlayViewModel
    var onClose: (() -> Void)? = nil
    var presentation: PanelPresentation = .standalone

    private var selectedModel: ModelOption? {
        model.availableModels.first { $0.slug == model.selectedModelSlug }
            ?? model.availableModels.first(where: { $0.isDefault })
            ?? model.availableModels.first
    }

    private var currentModelLabel: String {
        selectedModel?.displayName ?? "Default"
    }

    private var currentReasoningLabel: String {
        model.selectedReasoningEffort?.label ?? "Default"
    }

    var body: some View {
        let content = VStack(alignment: .leading, spacing: 10) {
            header

            if model.isLoadingModels {
                Text("Loading models...")
                    .font(.custom("Avenir Next", size: 9))
                    .foregroundColor(.white.opacity(0.6))
            }

            if let error = model.modelListError {
                Text(error)
                    .font(.custom("Avenir Next", size: 9))
                    .foregroundColor(OverlayPalette.ember)
                    .lineLimit(2)
            }

            if model.availableModels.isEmpty {
                if !model.isLoadingModels {
                    Text("No models available.")
                        .font(.custom("Avenir Next", size: 10))
                        .foregroundColor(.white.opacity(0.7))
                }
            } else {
                modelListSection
                reasoningSection
            }

            Text("Applies to the next turn in this session.")
                .font(.custom("Avenir Next", size: 9))
                .foregroundColor(.white.opacity(0.5))
        }

        Group {
            if presentation.isEmbedded {
                ControlPod { content }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            } else {
                ControlPod { content }
                    .frame(width: OverlayLayout.modelPickerWidth)
            }
        }
        .onAppear { model.logUIEvent("model panel appear") }
        .onDisappear { model.logUIEvent("model panel disappear") }
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Model")
                    .font(.custom("Avenir Next", size: 11).weight(.semibold))
                    .foregroundColor(.white.opacity(0.9))
                Text("Current: \(currentModelLabel) / \(currentReasoningLabel)")
                    .font(.custom("Avenir Next", size: 9))
                    .foregroundColor(OverlayPalette.cyan.opacity(0.7))
            }

            Spacer()

            if let onClose {
                Button(action: { onClose() }) {
                    Image(systemName: "chevron.backward")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.white.opacity(0.85))
                        .frame(width: 18, height: 18)
                        .background(
                            Circle().fill(OverlayPalette.neonBlue.opacity(0.25))
                        )
                        .overlay(
                            Circle().stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Back to orb")
            }

            Button(action: { model.refreshModels(force: true) }) {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(.white.opacity(0.85))
                    .frame(width: 18, height: 18)
                    .background(
                        Circle().fill(OverlayPalette.neonBlue.opacity(0.25))
                    )
                    .overlay(
                        Circle().stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Refresh models")
        }
    }

    private var modelListSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            ModelPickerSectionTitle(text: "Models")
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 6) {
                    ForEach(model.availableModels) { option in
                        ModelOptionRow(
                            option: option,
                            isSelected: option.slug == selectedModel?.slug,
                            onTap: {
                                model.logUIEvent("model tap \(option.slug)")
                                model.selectModel(option)
                            }
                        )
                    }
                }
                .padding(.vertical, 2)
            }
            .frame(maxHeight: OverlayLayout.modelPickerModelListHeight)
        }
    }

    private var reasoningSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            ModelPickerSectionTitle(text: "Reasoning Effort")
            if let selectedModel {
                let options = selectedModel.supportedReasoningEfforts
                if options.isEmpty {
                    Text("Reasoning effort is not configurable for this model.")
                        .font(.custom("Avenir Next", size: 9))
                        .foregroundColor(.white.opacity(0.6))
                } else {
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 6) {
                            ForEach(options) { option in
                                ReasoningOptionRow(
                                    option: option,
                                    isSelected: option.effort == model.selectedReasoningEffort,
                                    isDefault: option.effort == selectedModel.defaultReasoningEffort,
                                    onTap: {
                                        model.logUIEvent("effort tap \(option.effort.label)")
                                        model.selectReasoningEffort(option.effort)
                                    }
                                )
                            }
                        }
                        .padding(.vertical, 2)
                    }
                    .frame(maxHeight: OverlayLayout.modelPickerReasoningListHeight)
                }
            } else {
                Text("Select a model to see options.")
                    .font(.custom("Avenir Next", size: 9))
                    .foregroundColor(.white.opacity(0.6))
            }
        }
    }
}

private struct ModelPickerSectionTitle: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.custom("Avenir Next", size: 9).weight(.semibold))
            .foregroundColor(.white.opacity(0.7))
            .tracking(0.6)
    }
}

private struct ModelOptionRow: View {
    let option: ModelOption
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(isSelected ? OverlayPalette.cyan : .white.opacity(0.4))
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(option.displayName)
                            .font(.custom("Avenir Next", size: 10).weight(.semibold))
                            .foregroundColor(.white.opacity(0.95))
                        if option.isDefault {
                            Text("Default")
                                .font(.custom("Avenir Next", size: 8).weight(.semibold))
                                .foregroundColor(OverlayPalette.cyan.opacity(0.8))
                                .padding(.horizontal, 4)
                                .padding(.vertical, 2)
                                .background(
                                    Capsule().fill(OverlayPalette.cyan.opacity(0.18))
                                )
                        }
                    }
                    if !option.description.isEmpty {
                        Text(option.description)
                            .font(.custom("Avenir Next", size: 9))
                            .foregroundColor(.white.opacity(0.6))
                            .lineLimit(2)
                    }
                }
                Spacer()
            }
            .padding(8)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(isSelected ? OverlayPalette.neonBlue.opacity(0.25) : OverlayPalette.deepSpace.opacity(0.35))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(
                        isSelected ? OverlayPalette.cyan.opacity(0.5) : OverlayPalette.neonBlue.opacity(0.2),
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

private struct ReasoningOptionRow: View {
    let option: ReasoningEffortOption
    let isSelected: Bool
    let isDefault: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(isSelected ? OverlayPalette.teal : .white.opacity(0.4))
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(option.effort.label)
                            .font(.custom("Avenir Next", size: 10).weight(.semibold))
                            .foregroundColor(.white.opacity(0.95))
                        if isDefault {
                            Text("Default")
                                .font(.custom("Avenir Next", size: 8).weight(.semibold))
                                .foregroundColor(OverlayPalette.teal.opacity(0.8))
                                .padding(.horizontal, 4)
                                .padding(.vertical, 2)
                                .background(
                                    Capsule().fill(OverlayPalette.teal.opacity(0.18))
                                )
                        }
                    }
                    if !option.description.isEmpty {
                        Text(option.description)
                            .font(.custom("Avenir Next", size: 9))
                            .foregroundColor(.white.opacity(0.6))
                            .lineLimit(2)
                    }
                }
                Spacer()
            }
            .padding(8)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(isSelected ? OverlayPalette.teal.opacity(0.25) : OverlayPalette.deepSpace.opacity(0.35))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(
                        isSelected ? OverlayPalette.teal.opacity(0.5) : OverlayPalette.neonBlue.opacity(0.2),
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

struct CloseButton: View {
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Image(systemName: "xmark")
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 20, height: 20)
                .background(
                    Circle().fill(
                        LinearGradient(
                            colors: [OverlayPalette.ember.opacity(0.9), OverlayPalette.magenta.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                )
                .overlay(
                    Circle().stroke(Color.white.opacity(0.3), lineWidth: 1)
                )
                .shadow(color: OverlayPalette.ember.opacity(0.6), radius: 6)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Close")
    }
}

struct ListeningToggleButton: View {
    let isEnabled: Bool
    let onTap: () -> Void
    @State private var isHovering = false

    var body: some View {
        Button(action: onTap) {
            Image(systemName: isEnabled ? "mic.fill" : "mic.slash.fill")
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 20, height: 20)
                .background(
                    Circle().fill(
                        LinearGradient(
                            colors: isEnabled
                                ? [OverlayPalette.neonBlue.opacity(0.9), OverlayPalette.cyan.opacity(0.7)]
                                : [OverlayPalette.ember.opacity(0.9), OverlayPalette.magenta.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                )
                .overlay(
                    Circle().stroke(Color.white.opacity(0.3), lineWidth: 1)
                )
                .shadow(color: (isEnabled ? OverlayPalette.cyan : OverlayPalette.ember).opacity(0.6), radius: 6)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            if hovering {
                if !isHovering {
                    NSCursor.pointingHand.push()
                    isHovering = true
                }
            } else if isHovering {
                NSCursor.pop()
                isHovering = false
            }
        }
        .onDisappear {
            if isHovering {
                NSCursor.pop()
                isHovering = false
            }
        }
        .accessibilityLabel(isEnabled ? "Pause listening" : "Resume listening")
    }
}

struct HistoryToggleButton: View {
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 20, height: 20)
                .background(
                    Circle().fill(
                        LinearGradient(
                            colors: [OverlayPalette.neonBlue.opacity(0.85), OverlayPalette.electricPurple.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                )
                .overlay(
                    Circle().stroke(Color.white.opacity(0.3), lineWidth: 1)
                )
                .shadow(color: OverlayPalette.electricPurple.opacity(0.5), radius: 6)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Open history")
    }
}

struct DiagnosticsToggleButton: View {
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Image(systemName: "waveform.path.ecg")
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 20, height: 20)
                .background(
                    Circle().fill(
                        LinearGradient(
                            colors: [OverlayPalette.neonBlue.opacity(0.85), OverlayPalette.magenta.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                )
                .overlay(
                    Circle().stroke(Color.white.opacity(0.3), lineWidth: 1)
                )
                .shadow(color: OverlayPalette.neonBlue.opacity(0.5), radius: 6)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Open diagnostics")
    }
}

struct ReasoningToggleButton: View {
    let isEnabled: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Image(systemName: isEnabled ? "brain.head.profile.fill" : "brain.head.profile")
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 20, height: 20)
                .background(
                    Circle().fill(
                        LinearGradient(
                            colors: isEnabled
                                ? [OverlayPalette.cyan.opacity(0.9), OverlayPalette.teal.opacity(0.7)]
                                : [OverlayPalette.deepSpace.opacity(0.75), OverlayPalette.neonBlue.opacity(0.5)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                )
                .overlay(
                    Circle().stroke(Color.white.opacity(0.3), lineWidth: 1)
                )
                .shadow(color: (isEnabled ? OverlayPalette.cyan : OverlayPalette.neonBlue).opacity(0.5), radius: 6)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isEnabled ? "Hide reasoning" : "Show reasoning")
    }
}

struct LoginStatusButton: View {
    let state: LoginState
    let onTap: () -> Void

    private var colors: [Color] {
        switch state {
        case .ready:
            return [OverlayPalette.cyan.opacity(0.9), OverlayPalette.neonBlue.opacity(0.7)]
        case .required, .failed:
            return [OverlayPalette.ember.opacity(0.95), OverlayPalette.magenta.opacity(0.75)]
        case .inProgress:
            return [OverlayPalette.neonBlue.opacity(0.9), OverlayPalette.electricPurple.opacity(0.7)]
        }
    }

    private var shadow: Color {
        switch state {
        case .required, .failed:
            return OverlayPalette.ember
        case .inProgress:
            return OverlayPalette.electricPurple
        case .ready:
            return OverlayPalette.cyan
        }
    }

    var body: some View {
        Button(action: onTap) {
            Image(systemName: "person.crop.circle.badge.exclamationmark")
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 20, height: 20)
                .background(
                    Circle().fill(
                        LinearGradient(
                            colors: colors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                )
                .overlay(
                    Circle().stroke(Color.white.opacity(0.3), lineWidth: 1)
                )
                .shadow(color: shadow.opacity(0.6), radius: 6)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(loginLabel)
    }

    private var loginLabel: String {
        switch state {
        case .ready:
            return "Account ready"
        case .required:
            return "Login required"
        case .inProgress:
            return "Login in progress"
        case .failed:
            return "Login failed"
        }
    }
}

struct ReasoningTicker: View {
    let text: String
    let isVisible: Bool
    let thinkingTime: String

    var body: some View {
        if isVisible {
            TimelineView(.animation) { context in
                let phase = context.date.timeIntervalSinceReferenceDate
                HStack(spacing: 10) {
                    RotatingHalo(phase: phase)
                    if !thinkingTime.isEmpty {
                        Text(thinkingTime)
                            .font(.custom("Avenir Next", size: 32).weight(.semibold))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [
                                        OverlayPalette.cyan.opacity(1.0),
                                        OverlayPalette.neonBlue.opacity(0.98),
                                        OverlayPalette.magenta.opacity(0.92),
                                        OverlayPalette.teal.opacity(0.9)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .shadow(color: OverlayPalette.cyan.opacity(0.7), radius: 12, x: 0, y: 0)
                            .shadow(color: OverlayPalette.magenta.opacity(0.6), radius: 16, x: 0, y: 0)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .transition(.opacity)
            }
        }
    }
}

struct SilenceCountdownBar: View {
    let progress: Double
    let isListening: Bool

    private let size: CGFloat = 22
    private let lineWidth: CGFloat = 3

    var body: some View {
        if isListening {
            ZStack {
                Circle()
                    .stroke(OverlayPalette.deepSpace.opacity(0.6), lineWidth: lineWidth)
                    .overlay(
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        OverlayPalette.neonBlue.opacity(0.25),
                                        OverlayPalette.cyan.opacity(0.2),
                                        OverlayPalette.magenta.opacity(0.18)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )

                Circle()
                    .trim(from: 0, to: 1 - max(0, min(1, progress)))
                    .stroke(
                        LinearGradient(
                            colors: [
                                OverlayPalette.cyan.opacity(1.0),
                                OverlayPalette.neonBlue.opacity(0.98),
                                OverlayPalette.magenta.opacity(0.92),
                                OverlayPalette.teal.opacity(0.9)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .shadow(color: OverlayPalette.cyan.opacity(0.6), radius: 6, x: 0, y: 0)
                    .shadow(color: OverlayPalette.magenta.opacity(0.4), radius: 10, x: 0, y: 0)

                GeometryReader { proxy in
                    let clamped = max(0, min(1, progress))
                    let remaining = 1 - clamped
                    let radius = min(proxy.size.width, proxy.size.height) / 2
                    let angle = Double.pi * 2 * remaining - Double.pi / 2
                    let x = cos(angle) * (radius - lineWidth * 0.6)
                    let y = sin(angle) * (radius - lineWidth * 0.6)
                    Circle()
                        .fill(OverlayPalette.cyan.opacity(0.95))
                        .frame(width: lineWidth + 2, height: lineWidth + 2)
                        .offset(x: x, y: y)
                        .shadow(color: OverlayPalette.cyan.opacity(0.7), radius: 5, x: 0, y: 0)
                        .overlay(
                            Circle()
                                .stroke(OverlayPalette.neonBlue.opacity(0.6), lineWidth: 1)
                                .frame(width: lineWidth + 4, height: lineWidth + 4)
                                .offset(x: x, y: y)
                                .blur(radius: 1.5)
                        )
                }
            }
            .frame(width: size, height: size)
            .animation(.easeInOut(duration: 0.12), value: progress)
            .transition(.opacity.combined(with: .move(edge: .bottom)))
        }
    }
}

struct MicSilenceRing: View {
    let progress: Double
    let isListening: Bool
    let isEnabled: Bool
    let size: CGFloat
    let lineWidth: CGFloat
    let showButton: Bool
    let onToggle: () -> Void

    var body: some View {
        ZStack {
            Circle()
                .stroke(OverlayPalette.deepSpace.opacity(0.6), lineWidth: lineWidth)
                .overlay(
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [
                                    OverlayPalette.neonBlue.opacity(0.25),
                                    OverlayPalette.cyan.opacity(0.2),
                                    OverlayPalette.magenta.opacity(0.18)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )

            Circle()
                .trim(from: 0, to: 1 - max(0, min(1, isListening ? progress : 0)))
                .stroke(
                    LinearGradient(
                        colors: [
                            OverlayPalette.cyan.opacity(isEnabled ? 1.0 : 0.6),
                            OverlayPalette.neonBlue.opacity(isEnabled ? 0.98 : 0.6),
                            OverlayPalette.magenta.opacity(isEnabled ? 0.9 : 0.5),
                            OverlayPalette.teal.opacity(isEnabled ? 0.9 : 0.5)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .shadow(color: OverlayPalette.cyan.opacity(isEnabled ? 0.6 : 0.25), radius: 6, x: 0, y: 0)
                .shadow(color: OverlayPalette.magenta.opacity(isEnabled ? 0.4 : 0.2), radius: 10, x: 0, y: 0)

            Button(action: onToggle) {
                Image(systemName: isEnabled ? "mic.fill" : "mic.slash.fill")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(isEnabled ? OverlayPalette.cyan : OverlayPalette.ember)
                    .frame(width: 44, height: 44)
                    .background(
                        Circle().fill(
                            LinearGradient(
                                colors: isEnabled
                                    ? [OverlayPalette.deepSpace.opacity(0.7), OverlayPalette.neonBlue.opacity(0.4)]
                                    : [OverlayPalette.deepSpace.opacity(0.7), OverlayPalette.ember.opacity(0.5)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    )
                    .overlay(
                        Circle().stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
                    .shadow(color: (isEnabled ? OverlayPalette.cyan : OverlayPalette.ember).opacity(0.5), radius: 6)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(isEnabled ? "Pause listening" : "Resume listening")
            .opacity(showButton ? 1 : 0)
            .scaleEffect(showButton ? 1 : 0.92)
            .allowsHitTesting(showButton)
            .animation(.easeInOut(duration: 0.18), value: showButton)
        }
        .frame(width: size, height: size)
        .animation(.easeInOut(duration: 0.12), value: progress)
    }
}

private struct RotatingHalo: View {
    let phase: TimeInterval

    var body: some View {
        ZStack {
            Circle()
                .stroke(
                    AngularGradient(
                        colors: [
                            OverlayPalette.cyan.opacity(0.8),
                            OverlayPalette.neonBlue.opacity(0.8),
                            OverlayPalette.magenta.opacity(0.7),
                            OverlayPalette.teal.opacity(0.7),
                            OverlayPalette.cyan.opacity(0.8)
                        ],
                        center: .center
                    ),
                    lineWidth: 2
                )
                .rotationEffect(.degrees(phase * 35))
                .frame(width: 18, height: 18)
            Circle()
                .trim(from: 0.25, to: 0.85)
                .stroke(OverlayPalette.cyan.opacity(0.7), lineWidth: 1.4)
                .rotationEffect(.degrees(-phase * 60))
                .frame(width: 14, height: 14)
            Circle()
                .fill(OverlayPalette.cyan.opacity(0.95))
                .frame(width: 4.5, height: 4.5)
                .shadow(color: OverlayPalette.cyan.opacity(0.8), radius: 6, x: 0, y: 0)
        }
    }
}

private struct NewSessionPulseRing: View {
    let trigger: Int
    @State private var isPulsing = false

    var body: some View {
        Circle()
            .stroke(
                LinearGradient(
                    colors: [
                        OverlayPalette.cyan.opacity(0.9),
                        OverlayPalette.neonBlue.opacity(0.7),
                        OverlayPalette.magenta.opacity(0.6)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: 3
            )
            .scaleEffect(isPulsing ? 1.12 : 0.92)
            .opacity(isPulsing ? 0.0 : 0.7)
            .onChange(of: trigger) { _ in
                isPulsing = false
                withAnimation(.easeOut(duration: 0.9)) {
                    isPulsing = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.95) {
                    isPulsing = false
                }
            }
    }
}
