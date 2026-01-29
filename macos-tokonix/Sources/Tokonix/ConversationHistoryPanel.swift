import SwiftUI

struct ConversationHistoryPanel: View {
    @ObservedObject var model: OverlayViewModel
    let onClose: () -> Void
    var presentation: PanelPresentation = .standalone

    var body: some View {
        let content = VStack(spacing: 12) {
            header

            HStack(spacing: 12) {
                sessionList

                Capsule(style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                OverlayPalette.cyan.opacity(0.25),
                                OverlayPalette.neonBlue.opacity(0.12),
                                OverlayPalette.magenta.opacity(0.18)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 2)

                transcriptPanel
            }
        }
        Group {
            if presentation.isEmbedded {
                content
                    .padding(.horizontal, 18)
                    .padding(.vertical, 14)
                    .background(panelBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 34, style: .continuous))
                    .overlay(loadingOverlay)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            } else {
                content
                    .padding(.horizontal, 18)
                    .padding(.vertical, 14)
                    .frame(width: OverlayLayout.historyPanelWidth, height: OverlayLayout.historyPanelHeight)
                    .background(panelBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 34, style: .continuous))
                    .background(panelGlow)
                    .shadow(color: OverlayPalette.deepSpace.opacity(0.55), radius: 18, x: 0, y: 12)
                    .overlay(loadingOverlay)
            }
        }
        .onAppear {
            model.refreshThreads(reset: true)
        }
    }

    private var header: some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Session History")
                    .font(.custom("Avenir Next", size: 14).weight(.semibold))
                    .foregroundColor(.white.opacity(0.92))
                Text(currentSessionLabel)
                    .font(.custom("Avenir Next", size: 10))
                    .foregroundColor(OverlayPalette.cyan.opacity(0.75))
            }

            Spacer()

            if model.loginState != .ready {
                LoginStatusButton(state: model.loginState, onTap: model.retryLogin)
            }

            PanelActionButton(
                title: "New",
                systemImage: "plus",
                colors: [OverlayPalette.cyan.opacity(0.85), OverlayPalette.neonBlue.opacity(0.7)],
                action: model.startNewThread
            )

            if !presentation.isEmbedded {
                MinimizeButton(onTap: onClose)
            }
        }
        .padding(.horizontal, 8)
    }

    private var sessionList: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Sessions")
                    .font(.custom("Avenir Next", size: 11).weight(.semibold))
                    .foregroundColor(.white.opacity(0.85))
                Spacer()
                if model.isLoadingThreads {
                    ProgressView()
                        .scaleEffect(0.6)
                }
            }

            ScrollView {
                LazyVStack(alignment: .leading, spacing: 8) {
                    if model.threadSummaries.isEmpty && !model.isLoadingThreads {
                        Text("No sessions yet.")
                            .font(.custom("Avenir Next", size: 10))
                            .foregroundColor(.white.opacity(0.55))
                            .padding(.vertical, 12)
                    } else {
                        ForEach(model.threadSummaries) { summary in
                            SessionRow(
                                summary: summary,
                                isActive: summary.id == model.currentThreadId,
                                onSelect: {
                                    model.resumeThread(summary)
                                }
                            )
                            .disabled(model.isResumingThread)
                        }
                    }
                }
                .padding(.vertical, 4)
            }

            if let _ = model.threadCursor {
                PanelActionButton(
                    title: model.isLoadingThreads ? "Loading..." : "Load more",
                    systemImage: "arrow.down",
                    colors: [OverlayPalette.electricPurple.opacity(0.7), OverlayPalette.magenta.opacity(0.6)],
                    action: {
                        model.refreshThreads(reset: false)
                    }
                )
                .disabled(model.isLoadingThreads)
            }
        }
        .padding(12)
        .frame(width: OverlayLayout.historyListWidth)
        .background(sectionBackground)
        .overlay(sectionBorder)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var transcriptPanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Conversation")
                    .font(.custom("Avenir Next", size: 11).weight(.semibold))
                    .foregroundColor(.white.opacity(0.85))
                Spacer()
                if model.isResumingThread {
                    Text("Resuming...")
                        .font(.custom("Avenir Next", size: 10))
                        .foregroundColor(OverlayPalette.cyan.opacity(0.75))
                }
            }

            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 10) {
                        if model.chatMessages.isEmpty {
                            Text("No messages in this session yet.")
                                .font(.custom("Avenir Next", size: 10))
                                .foregroundColor(.white.opacity(0.6))
                                .padding(.vertical, 16)
                                .frame(maxWidth: .infinity, alignment: .center)
                        } else {
                            ForEach(model.chatMessages) { message in
                                MessageBubble(message: message)
                                    .id(message.id)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
                .onChange(of: model.chatMessages.count) { _ in
                    scrollToBottom(proxy)
                }
                .onChange(of: model.chatMessages.last?.text ?? "") { _ in
                    scrollToBottom(proxy)
                }
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(sectionBackground)
        .overlay(sectionBorder)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var panelBackground: some View {
        RoundedRectangle(cornerRadius: 34, style: .continuous)
            .fill(.ultraThinMaterial)
            .overlay(
                RoundedRectangle(cornerRadius: 34, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                OverlayPalette.midnight.opacity(0.62),
                                OverlayPalette.deepSpace.opacity(0.45),
                                OverlayPalette.neonBlue.opacity(0.2),
                                OverlayPalette.magenta.opacity(0.18),
                                OverlayPalette.cyan.opacity(0.12)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .overlay(panelBorder)
    }

    private var panelBorder: some View {
        RoundedRectangle(cornerRadius: 34, style: .continuous)
            .stroke(
                LinearGradient(
                    colors: [
                        OverlayPalette.cyan.opacity(0.55),
                        OverlayPalette.neonBlue.opacity(0.45),
                        OverlayPalette.magenta.opacity(0.45)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: 1
            )
    }

    private var sectionBackground: some View {
        RoundedRectangle(cornerRadius: 18, style: .continuous)
            .fill(OverlayPalette.midnight.opacity(0.35))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                OverlayPalette.neonBlue.opacity(0.16),
                                OverlayPalette.electricPurple.opacity(0.12),
                                OverlayPalette.deepSpace.opacity(0.12),
                                OverlayPalette.cyan.opacity(0.08)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
    }

    private var sectionBorder: some View {
        RoundedRectangle(cornerRadius: 18, style: .continuous)
            .stroke(OverlayPalette.neonBlue.opacity(0.35), lineWidth: 1)
    }

    private var loadingOverlay: some View {
        Group {
            if model.isResumingThread {
                RoundedRectangle(cornerRadius: 34, style: .continuous)
                    .fill(Color.black.opacity(0.25))
            }
        }
    }

    private var panelGlow: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            OverlayPalette.cyan.opacity(0.32),
                            OverlayPalette.neonBlue.opacity(0.15),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 10,
                        endRadius: 170
                    )
                )
                .frame(width: 220, height: 220)
                .offset(x: -120, y: -60)

            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            OverlayPalette.magenta.opacity(0.24),
                            OverlayPalette.electricPurple.opacity(0.14),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 20,
                        endRadius: 190
                    )
                )
                .frame(width: 240, height: 240)
                .offset(x: 120, y: 80)
        }
    }

    private var currentSessionLabel: String {
        guard let currentId = model.currentThreadId else {
            return "No active session"
        }
        if let summary = model.threadSummaries.first(where: { $0.id == currentId }) {
            let preview = SessionRow.previewText(for: summary)
            return "Active: \(preview)"
        }
        return "Active: \(currentId)"
    }

    private func scrollToBottom(_ proxy: ScrollViewProxy) {
        guard let lastId = model.chatMessages.last?.id else { return }
        DispatchQueue.main.async {
            withAnimation(.easeOut(duration: 0.25)) {
                proxy.scrollTo(lastId, anchor: .bottom)
            }
        }
    }
}

private struct SessionRow: View {
    let summary: ThreadSummary
    let isActive: Bool
    let onSelect: () -> Void

    private static let relativeFormatter: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter
    }()

    var body: some View {
        Button(action: onSelect) {
            HStack(alignment: .top, spacing: 8) {
                Circle()
                    .fill(isActive ? OverlayPalette.cyan : OverlayPalette.neonBlue.opacity(0.4))
                    .frame(width: 6, height: 6)
                    .padding(.top, 6)

                VStack(alignment: .leading, spacing: 4) {
                    Text(Self.previewText(for: summary))
                        .font(.custom("Avenir Next", size: 11).weight(.semibold))
                        .foregroundColor(.white.opacity(isActive ? 0.95 : 0.8))
                        .lineLimit(2)

                    Text(Self.detailText(for: summary))
                        .font(.custom("Avenir Next", size: 9))
                        .foregroundColor(OverlayPalette.cyan.opacity(0.55))
                        .lineLimit(1)
                }
                Spacer(minLength: 0)
            }
            .padding(10)
            .background(rowBackground)
            .overlay(rowBorder)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private var rowBackground: some View {
        RoundedRectangle(cornerRadius: 14, style: .continuous)
            .fill(
                LinearGradient(
                    colors: isActive
                        ? [OverlayPalette.neonBlue.opacity(0.4), OverlayPalette.electricPurple.opacity(0.3)]
                        : [OverlayPalette.deepSpace.opacity(0.55), OverlayPalette.midnight.opacity(0.6)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
    }

    private var rowBorder: some View {
        RoundedRectangle(cornerRadius: 14, style: .continuous)
            .stroke(
                isActive ? OverlayPalette.cyan.opacity(0.6) : OverlayPalette.neonBlue.opacity(0.25),
                lineWidth: 1
            )
    }

    static func previewText(for summary: ThreadSummary) -> String {
        let trimmed = summary.preview.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "Untitled session" : trimmed
    }

    static func detailText(for summary: ThreadSummary) -> String {
        let timeLabel = relativeFormatter.localizedString(for: summary.createdAt, relativeTo: Date())
        var parts = [timeLabel]
        if !summary.modelProvider.isEmpty {
            parts.append(summary.modelProvider)
        }
        if let path = displayPath(summary.path) {
            parts.append(path)
        }
        return parts.joined(separator: " | ")
    }

    private static func displayPath(_ path: String) -> String? {
        let trimmed = path.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        let url = URL(fileURLWithPath: trimmed)
        let name = url.lastPathComponent.isEmpty ? trimmed : url.lastPathComponent
        if name.count > 22 {
            let prefix = name.prefix(21)
            return "\(prefix)..."
        }
        return name
    }
}

private struct MessageBubble: View {
    let message: ChatMessage

    var body: some View {
        HStack(alignment: .top) {
            if message.role == .assistant {
                bubble
                Spacer(minLength: 0)
            } else {
                Spacer(minLength: 0)
                bubble
            }
        }
    }

    private var bubble: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(message.role == .user ? "You" : "Tokonix")
                .font(.custom("Avenir Next", size: 9).weight(.semibold))
                .foregroundColor(.white.opacity(0.7))

            Text(message.isStreaming ? "\(message.text) ..." : message.text)
                .font(.custom("Avenir Next", size: 11))
                .foregroundColor(.white.opacity(0.9))
                .multilineTextAlignment(.leading)
                .textSelection(.enabled)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(bubbleBackground)
        .overlay(bubbleBorder)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .frame(maxWidth: 260, alignment: message.role == .user ? .trailing : .leading)
    }

    private var bubbleBackground: some View {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .fill(
                LinearGradient(
                    colors: message.role == .user
                        ? [OverlayPalette.neonBlue.opacity(0.5), OverlayPalette.cyan.opacity(0.35)]
                        : [OverlayPalette.magenta.opacity(0.45), OverlayPalette.electricPurple.opacity(0.35)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
    }

    private var bubbleBorder: some View {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .stroke(
                message.role == .user
                    ? OverlayPalette.cyan.opacity(0.45)
                    : OverlayPalette.magenta.opacity(0.4),
                lineWidth: 1
            )
    }
}

private struct PanelActionButton: View {
    let title: String
    let systemImage: String
    let colors: [Color]
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: systemImage)
                    .font(.system(size: 10, weight: .bold))
                Text(title)
                    .font(.custom("Avenir Next", size: 10).weight(.semibold))
            }
            .foregroundColor(.white.opacity(0.9))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: colors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )
            .shadow(color: colors.first?.opacity(0.35) ?? .clear, radius: 6, x: 0, y: 4)
        }
        .buttonStyle(.plain)
    }
}

private struct MinimizeButton: View {
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Image(systemName: "chevron.down")
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 20, height: 20)
                .background(
                    Circle().fill(
                        LinearGradient(
                            colors: [OverlayPalette.deepSpace.opacity(0.8), OverlayPalette.neonBlue.opacity(0.5)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                )
                .overlay(
                    Circle().stroke(Color.white.opacity(0.3), lineWidth: 1)
                )
                .shadow(color: OverlayPalette.neonBlue.opacity(0.4), radius: 6)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Minimize")
    }
}
