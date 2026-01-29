import SwiftUI

enum ConfigurationSection: String, CaseIterable, Identifiable {
    case model
    case voice
    case skills
    case instructions
    case history
    case diagnostics

    var id: String { rawValue }

    var title: String {
        switch self {
        case .model:
            return "Model"
        case .voice:
            return "Voice"
        case .skills:
            return "Skills"
        case .instructions:
            return "AGENTS.md"
        case .history:
            return "History"
        case .diagnostics:
            return "Diagnostics"
        }
    }

    var subtitle: String {
        switch self {
        case .model:
            return "Model + reasoning"
        case .voice:
            return "Speech voice"
        case .skills:
            return "Skill configs"
        case .instructions:
            return "Overlay guidance"
        case .history:
            return "Sessions"
        case .diagnostics:
            return "Logs"
        }
    }

    var systemImage: String {
        switch self {
        case .model:
            return "slider.horizontal.3"
        case .voice:
            return "waveform"
        case .skills:
            return "sparkles"
        case .instructions:
            return "doc.text"
        case .history:
            return "clock.arrow.circlepath"
        case .diagnostics:
            return "waveform.path.ecg"
        }
    }

    var accent: [Color] {
        switch self {
        case .model:
            return [OverlayPalette.teal.opacity(0.9), OverlayPalette.cyan.opacity(0.7)]
        case .voice:
            return [OverlayPalette.cyan.opacity(0.85), OverlayPalette.neonBlue.opacity(0.7)]
        case .skills:
            return [OverlayPalette.lime.opacity(0.85), OverlayPalette.teal.opacity(0.7)]
        case .instructions:
            return [OverlayPalette.cyan.opacity(0.85), OverlayPalette.neonBlue.opacity(0.7)]
        case .history:
            return [OverlayPalette.neonBlue.opacity(0.85), OverlayPalette.electricPurple.opacity(0.7)]
        case .diagnostics:
            return [OverlayPalette.neonBlue.opacity(0.85), OverlayPalette.magenta.opacity(0.7)]
        }
    }
}

struct ConfigurationsPanel: View {
    @ObservedObject var model: OverlayViewModel
    let onClose: () -> Void
    @State private var selection: ConfigurationSection = .model

    var body: some View {
        VStack(spacing: 14) {
            header

            HStack(spacing: 12) {
                sidebar

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

                content
            }
        }
        .padding(16)
        .frame(width: OverlayLayout.configurationsPanelWidth, height: OverlayLayout.configurationsPanelHeight)
        .background(panelBackground)
        .clipShape(RoundedRectangle(cornerRadius: 34, style: .continuous))
        .shadow(color: OverlayPalette.deepSpace.opacity(0.6), radius: 18, x: 0, y: 12)
        .onAppear { activate(selection) }
        .onChange(of: selection) { newValue in
            activate(newValue)
        }
    }

    private var header: some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Configurations")
                    .font(.custom("Avenir Next", size: 14).weight(.semibold))
                    .foregroundColor(.white.opacity(0.95))
                Text("Manage settings without leaving the overlay.")
                    .font(.custom("Avenir Next", size: 9))
                    .foregroundColor(OverlayPalette.cyan.opacity(0.75))
            }

            Spacer()

            if model.loginState != .ready {
                LoginStatusButton(state: model.loginState, onTap: model.retryLogin)
            }

            ConfigMinimizeButton(onTap: onClose)
        }
    }

    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(ConfigurationSection.allCases) { section in
                ConfigSidebarRow(
                    section: section,
                    isSelected: selection == section,
                    onTap: { selection = section }
                )
            }
            Spacer(minLength: 0)
        }
        .padding(12)
        .frame(width: OverlayLayout.configurationsSidebarWidth, alignment: .topLeading)
        .background(sidebarBackground)
        .overlay(sidebarBorder)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var content: some View {
        ZStack(alignment: .topLeading) {
            switch selection {
            case .model:
                ModelPickerPanel(model: model, presentation: .embedded)
            case .voice:
                VoicePickerPanel(model: model, presentation: .embedded)
            case .skills:
                SkillsPanel(model: model, onClose: {}, presentation: .embedded)
            case .instructions:
                InstructionsPanel(model: model, onClose: {}, presentation: .embedded)
            case .history:
                ConversationHistoryPanel(model: model, onClose: {}, presentation: .embedded)
            case .diagnostics:
                DiagnosticLogPanel(model: model, onClose: {}, presentation: .embedded)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var panelBackground: some View {
        RoundedRectangle(cornerRadius: 34, style: .continuous)
            .fill(.ultraThinMaterial)
            .overlay(
                RoundedRectangle(cornerRadius: 34, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                OverlayPalette.midnight.opacity(0.65),
                                OverlayPalette.deepSpace.opacity(0.5),
                                OverlayPalette.neonBlue.opacity(0.2),
                                OverlayPalette.magenta.opacity(0.12)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 34, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [
                                OverlayPalette.cyan.opacity(0.45),
                                OverlayPalette.neonBlue.opacity(0.35),
                                OverlayPalette.magenta.opacity(0.25)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
    }

    private var sidebarBackground: some View {
        RoundedRectangle(cornerRadius: 18, style: .continuous)
            .fill(OverlayPalette.midnight.opacity(0.35))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                OverlayPalette.deepSpace.opacity(0.6),
                                OverlayPalette.neonBlue.opacity(0.08),
                                OverlayPalette.magenta.opacity(0.08)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
    }

    private var sidebarBorder: some View {
        RoundedRectangle(cornerRadius: 18, style: .continuous)
            .stroke(
                LinearGradient(
                    colors: [
                        OverlayPalette.cyan.opacity(0.35),
                        OverlayPalette.magenta.opacity(0.2),
                        OverlayPalette.neonBlue.opacity(0.25)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: 1
            )
    }

    private func activate(_ section: ConfigurationSection) {
        switch section {
        case .model:
            model.refreshModels(force: true)
        case .voice:
            model.refreshVoices()
        case .skills:
            model.refreshSkills(forceReload: true)
        case .instructions:
            model.loadOverlayInstructions()
        case .history:
            model.refreshThreads(reset: true)
        case .diagnostics:
            break
        }
    }
}

private struct ConfigSidebarRow: View {
    let section: ConfigurationSection
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 10) {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: section.accent,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 18, height: 18)
                    .overlay(
                        Image(systemName: section.systemImage)
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.white.opacity(0.9))
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text(section.title)
                        .font(.custom("Avenir Next", size: 11).weight(.semibold))
                        .foregroundColor(.white.opacity(isSelected ? 0.95 : 0.75))
                    Text(section.subtitle)
                        .font(.custom("Avenir Next", size: 8))
                        .foregroundColor(OverlayPalette.cyan.opacity(isSelected ? 0.7 : 0.45))
                }

                Spacer()
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 10)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: isSelected
                                ? [OverlayPalette.neonBlue.opacity(0.28), OverlayPalette.magenta.opacity(0.18)]
                                : [Color.clear, Color.clear],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(
                        isSelected ? OverlayPalette.cyan.opacity(0.3) : Color.white.opacity(0.08),
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

private struct ConfigMinimizeButton: View {
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Image(systemName: "chevron.down")
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 22, height: 22)
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
