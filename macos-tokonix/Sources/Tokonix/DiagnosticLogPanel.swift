import SwiftUI

struct DiagnosticLogPanel: View {
    @ObservedObject var model: OverlayViewModel
    let onClose: () -> Void
    var presentation: PanelPresentation = .standalone

    var body: some View {
        let content = VStack(spacing: 10) {
            header

            ScrollView {
                LazyVStack(alignment: .leading, spacing: 8) {
                    if model.errorLog.isEmpty {
                        Text("No errors logged.")
                            .font(.custom("Avenir Next", size: 10))
                            .foregroundColor(.white.opacity(0.6))
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.vertical, 12)
                    } else {
                        ForEach(model.errorLog.reversed()) { entry in
                            LogRow(entry: entry)
                        }
                    }
                }
                .padding(.vertical, 4)
            }
        }
        Group {
            if presentation.isEmbedded {
                content
                    .padding(14)
                    .background(panelBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            } else {
                content
                    .padding(14)
                    .frame(width: OverlayLayout.diagnosticsPanelWidth, height: OverlayLayout.diagnosticsPanelHeight)
                    .background(panelBackground)
                    .shadow(color: OverlayPalette.deepSpace.opacity(0.55), radius: 14, x: 0, y: 8)
            }
        }
    }

    private var header: some View {
        HStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Diagnostics")
                    .font(.custom("Avenir Next", size: 12).weight(.semibold))
                    .foregroundColor(.white.opacity(0.92))
                Text("Recent errors")
                    .font(.custom("Avenir Next", size: 9))
                    .foregroundColor(OverlayPalette.cyan.opacity(0.7))
            }

            Spacer()

            if !model.errorLog.isEmpty {
                DiagnosticsActionButton(
                    title: "Clear",
                    systemImage: "trash",
                    colors: [OverlayPalette.magenta.opacity(0.7), OverlayPalette.electricPurple.opacity(0.6)],
                    action: model.clearErrorLog
                )
            }

            if !presentation.isEmbedded {
                DiagnosticsCloseButton(onTap: onClose)
            }
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
                                OverlayPalette.neonBlue.opacity(0.12),
                                OverlayPalette.magenta.opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [
                                OverlayPalette.cyan.opacity(0.4),
                                OverlayPalette.electricPurple.opacity(0.3),
                                OverlayPalette.magenta.opacity(0.3)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .background(panelGlow)
    }

    private var panelGlow: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            OverlayPalette.cyan.opacity(0.2),
                            OverlayPalette.neonBlue.opacity(0.08),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 10,
                        endRadius: 120
                    )
                )
                .frame(width: 160, height: 160)
                .offset(x: -70, y: -40)

            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            OverlayPalette.magenta.opacity(0.16),
                            OverlayPalette.electricPurple.opacity(0.06),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 12,
                        endRadius: 130
                    )
                )
                .frame(width: 170, height: 170)
                .offset(x: 70, y: 60)
        }
    }
}

private struct LogRow: View {
    let entry: OverlayLogEntry

    private static let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter
    }()

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(Self.formatter.string(from: entry.date))
                .font(.custom("Avenir Next", size: 9))
                .foregroundColor(OverlayPalette.cyan.opacity(0.6))

            Text(entry.message)
                .font(.custom("Avenir Next", size: 10))
                .foregroundColor(.white.opacity(0.9))
                .multilineTextAlignment(.leading)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(rowBackground)
        .overlay(rowBorder)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var rowBackground: some View {
        RoundedRectangle(cornerRadius: 14, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [
                        OverlayPalette.deepSpace.opacity(0.5),
                        OverlayPalette.midnight.opacity(0.55)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
    }

    private var rowBorder: some View {
        RoundedRectangle(cornerRadius: 14, style: .continuous)
            .stroke(OverlayPalette.neonBlue.opacity(0.2), lineWidth: 1)
    }
}

private struct DiagnosticsActionButton: View {
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
            .foregroundColor(.white.opacity(0.9))
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
            .shadow(color: colors.first?.opacity(0.35) ?? .clear, radius: 4, x: 0, y: 2)
        }
        .buttonStyle(.plain)
    }
}

private struct DiagnosticsCloseButton: View {
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Image(systemName: "xmark")
                .font(.system(size: 9, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 18, height: 18)
                .background(
                    Circle().fill(
                        LinearGradient(
                            colors: [OverlayPalette.neonBlue.opacity(0.7), OverlayPalette.electricPurple.opacity(0.55)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                )
                .overlay(
                    Circle().stroke(Color.white.opacity(0.25), lineWidth: 1)
                )
                .shadow(color: OverlayPalette.neonBlue.opacity(0.4), radius: 5)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Close diagnostics")
    }
}
