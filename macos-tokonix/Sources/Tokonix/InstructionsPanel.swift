import SwiftUI

struct InstructionsPanel: View {
    @ObservedObject var model: OverlayViewModel
    let onClose: () -> Void
    var presentation: PanelPresentation = .standalone
    @FocusState private var isEditorFocused: Bool

    var body: some View {
        let content = VStack(spacing: 12) {
            header

            editorSection

            footer
        }
        Group {
            if presentation.isEmbedded {
                content
                    .padding(16)
                    .background(panelBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
                    .overlay(loadingOverlay)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            } else {
                content
                    .padding(16)
                    .frame(width: OverlayLayout.instructionsPanelWidth, height: OverlayLayout.instructionsPanelHeight)
                    .background(panelBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
                    .shadow(color: OverlayPalette.deepSpace.opacity(0.55), radius: 16, x: 0, y: 10)
                    .overlay(loadingOverlay)
            }
        }
        .onAppear {
            model.loadOverlayInstructions()
            DispatchQueue.main.async {
                isEditorFocused = true
            }
        }
    }

    private var header: some View {
        HStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Instructions")
                    .font(.custom("Avenir Next", size: 12).weight(.semibold))
                    .foregroundColor(.white.opacity(0.92))
                Text("AGENTS.md")
                    .font(.custom("Avenir Next", size: 9))
                    .foregroundColor(OverlayPalette.cyan.opacity(0.7))
            }

            Spacer()

            if model.hasUnsavedInstructions {
                Text("Unsaved")
                    .font(.custom("Avenir Next", size: 8).weight(.semibold))
                    .foregroundColor(OverlayPalette.ember)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(
                        Capsule().fill(OverlayPalette.ember.opacity(0.18))
                    )
            }

            if !presentation.isEmbedded {
                InstructionsIconButton(
                    systemName: "chevron.down",
                    label: "Close",
                    onTap: onClose
                )
            }
        }
    }

    private var editorSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            ZStack(alignment: .topLeading) {
                TextEditor(text: $model.instructionsText)
                    .font(.custom("Avenir Next", size: 10))
                    .foregroundColor(.white.opacity(0.92))
                    .padding(10)
                    .scrollContentBackground(.hidden)
                    .background(editorBackground)
                    .focused($isEditorFocused)

                if model.instructionsText.isEmpty {
                    Text("Add overlay instructions here...")
                        .font(.custom("Avenir Next", size: 10))
                        .foregroundColor(.white.opacity(0.4))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        .allowsHitTesting(false)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            if let path = model.instructionsFilePath {
                Text(path)
                    .font(.custom("Avenir Next", size: 8))
                    .foregroundColor(.white.opacity(0.5))
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .textSelection(.enabled)
            } else {
                Text("Instructions file unavailable")
                    .font(.custom("Avenir Next", size: 8))
                    .foregroundColor(OverlayPalette.ember.opacity(0.8))
            }
        }
    }

    private var footer: some View {
        HStack(spacing: 8) {
            if let status = model.instructionsStatusMessage {
                Text(status)
                    .font(.custom("Avenir Next", size: 9))
                    .foregroundColor(statusColor)
            }

            Spacer()

            InstructionsActionButton(
                title: "Reload",
                systemImage: "arrow.clockwise",
                colors: [OverlayPalette.electricPurple.opacity(0.7), OverlayPalette.magenta.opacity(0.6)],
                action: model.loadOverlayInstructions
            )
            .disabled(model.isLoadingInstructions || model.isSavingInstructions || model.isRestartingSession)

            InstructionsActionButton(
                title: model.isSavingInstructions ? "Saving..." : "Save",
                systemImage: "tray.and.arrow.down",
                colors: [OverlayPalette.cyan.opacity(0.85), OverlayPalette.neonBlue.opacity(0.7)],
                action: { model.saveOverlayInstructions() }
            )
            .disabled(!model.hasUnsavedInstructions || model.isSavingInstructions || model.isRestartingSession)

            InstructionsActionButton(
                title: model.isRestartingSession ? "Restarting..." : "Apply & Restart",
                systemImage: "arrow.triangle.2.circlepath",
                colors: [OverlayPalette.teal.opacity(0.85), OverlayPalette.cyan.opacity(0.7)],
                action: model.applyInstructionsAndRestart
            )
            .disabled(model.isSavingInstructions || model.isRestartingSession)
        }
    }

    private var panelBackground: some View {
        RoundedRectangle(cornerRadius: 26, style: .continuous)
            .fill(.ultraThinMaterial)
            .overlay(
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                OverlayPalette.midnight.opacity(0.65),
                                OverlayPalette.deepSpace.opacity(0.5),
                                OverlayPalette.neonBlue.opacity(0.16),
                                OverlayPalette.magenta.opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .overlay(panelBorder)
    }

    private var panelBorder: some View {
        RoundedRectangle(cornerRadius: 26, style: .continuous)
            .stroke(
                LinearGradient(
                    colors: [
                        OverlayPalette.cyan.opacity(0.35),
                        OverlayPalette.electricPurple.opacity(0.28),
                        OverlayPalette.magenta.opacity(0.25)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: 1
            )
    }

    private var editorBackground: some View {
        RoundedRectangle(cornerRadius: 18, style: .continuous)
            .fill(OverlayPalette.deepSpace.opacity(0.35))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(OverlayPalette.neonBlue.opacity(0.25), lineWidth: 1)
            )
    }

    private var loadingOverlay: some View {
        Group {
            if model.isLoadingInstructions || model.isSavingInstructions || model.isRestartingSession {
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .fill(OverlayPalette.deepSpace.opacity(0.35))
                    .overlay(
                        VStack(spacing: 8) {
                            ProgressView()
                                .scaleEffect(0.7)
                                .tint(OverlayPalette.cyan)
                            Text(loadingLabel)
                                .font(.custom("Avenir Next", size: 9))
                                .foregroundColor(.white.opacity(0.7))
                        }
                    )
            }
        }
    }

    private var loadingLabel: String {
        if model.isRestartingSession {
            return "Restarting session..."
        }
        if model.isSavingInstructions {
            return "Saving instructions..."
        }
        return "Loading instructions..."
    }

    private var statusColor: Color {
        guard let status = model.instructionsStatusMessage?.lowercased() else {
            return .white.opacity(0.7)
        }
        if status.contains("fail") || status.contains("error") || status.contains("unavailable") {
            return OverlayPalette.ember
        }
        if status.contains("saved") || status.contains("applied") {
            return OverlayPalette.cyan
        }
        return .white.opacity(0.7)
    }
}

private struct InstructionsActionButton: View {
    let title: String
    let systemImage: String
    let colors: [Color]
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: systemImage)
                    .font(.system(size: 9, weight: .bold))
                Text(title)
                    .font(.custom("Avenir Next", size: 9).weight(.semibold))
            }
            .foregroundColor(.white.opacity(0.92))
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: colors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )
            .shadow(color: colors.first?.opacity(0.3) ?? .clear, radius: 5, x: 0, y: 3)
        }
        .buttonStyle(.plain)
    }
}

private struct InstructionsIconButton: View {
    let systemName: String
    let label: String
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Image(systemName: systemName)
                .font(.system(size: 9, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 18, height: 18)
                .background(
                    Circle().fill(
                        LinearGradient(
                            colors: [OverlayPalette.deepSpace.opacity(0.75), OverlayPalette.neonBlue.opacity(0.5)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                )
                .overlay(
                    Circle().stroke(Color.white.opacity(0.3), lineWidth: 1)
                )
                .shadow(color: OverlayPalette.neonBlue.opacity(0.4), radius: 5)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }
}
