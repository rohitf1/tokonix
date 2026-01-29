import SwiftUI

struct VoicePickerPanel: View {
    @ObservedObject var model: OverlayViewModel
    var onClose: (() -> Void)? = nil
    var presentation: PanelPresentation = .standalone
    @State private var searchText: String = ""

    private var defaultDetail: String {
        model.voiceDescription.replacingOccurrences(of: "Voice: ", with: "")
    }

    var body: some View {
        let content = VStack(alignment: .leading, spacing: 10) {
            header
            searchField

            if model.isLoadingVoices {
                Text("Loading voices...")
                    .font(.custom("Avenir Next", size: 9))
                    .foregroundColor(.white.opacity(0.6))
            }

            if let error = model.voiceListError {
                Text(error)
                    .font(.custom("Avenir Next", size: 9))
                    .foregroundColor(OverlayPalette.ember)
                    .lineLimit(2)
            }

            if model.availableVoices.isEmpty {
                if !model.isLoadingVoices {
                    Text("No voices available.")
                        .font(.custom("Avenir Next", size: 10))
                        .foregroundColor(.white.opacity(0.7))
                }
            } else {
                voiceListSection
            }

            Text("Applies immediately to spoken replies.")
                .font(.custom("Avenir Next", size: 9))
                .foregroundColor(.white.opacity(0.5))
        }

        Group {
            if presentation.isEmbedded {
                content
                    .padding(14)
                    .background(panelBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            } else {
                content
                    .padding(14)
                    .frame(width: OverlayLayout.voicePickerWidth, height: OverlayLayout.voicePickerHeight)
                    .background(panelBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                    .shadow(color: OverlayPalette.deepSpace.opacity(0.55), radius: 12, x: 0, y: 8)
            }
        }
        .onAppear {
            model.refreshVoices()
            model.logUIEvent("voice panel appear")
        }
        .onDisappear {
            model.logUIEvent("voice panel disappear")
        }
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Voice")
                    .font(.custom("Avenir Next", size: 11).weight(.semibold))
                    .foregroundColor(.white.opacity(0.9))
                Text("Current: \(model.currentVoiceLabel)")
                    .font(.custom("Avenir Next", size: 9))
                    .foregroundColor(OverlayPalette.cyan.opacity(0.7))
                Text(model.currentVoiceDetail)
                    .font(.custom("Avenir Next", size: 8))
                    .foregroundColor(.white.opacity(0.55))
            }

            Spacer()

            Button(action: { model.previewVoice() }) {
                Image(systemName: "play.fill")
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
            .disabled(!model.canPreviewVoice)
            .accessibilityLabel("Preview voice")

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

            Button(action: { model.refreshVoices() }) {
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
            .accessibilityLabel("Refresh voices")
        }
    }

    private var voiceListSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            VoicePickerSectionTitle(text: "Voices")
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 6) {
                    VoiceDefaultRow(
                        detail: defaultDetail,
                        isSelected: model.selectedVoiceIdentifier == nil,
                        onTap: { model.selectVoice(nil) }
                    )
                    ForEach(filteredVoices) { option in
                        VoiceOptionRow(
                            option: option,
                            isSelected: option.identifier == model.selectedVoiceIdentifier,
                            onTap: {
                                model.logUIEvent("voice tap \(option.identifier)")
                                model.selectVoice(option)
                            }
                        )
                    }
                }
                .padding(.vertical, 2)
            }
            .frame(maxHeight: OverlayLayout.voicePickerListHeight)
        }
    }

    private var searchField: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.white.opacity(0.6))
            TextField("Search voices", text: $searchText)
                .textFieldStyle(.plain)
                .font(.custom("Avenir Next", size: 9))
                .foregroundColor(.white.opacity(0.92))
            if !searchText.isEmpty {
                Button(action: { searchText = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.white.opacity(0.6))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Clear search")
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(OverlayPalette.deepSpace.opacity(0.4))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(OverlayPalette.neonBlue.opacity(0.25), lineWidth: 1)
        )
    }

    private var filteredVoices: [VoiceOption] {
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return model.availableVoices }
        let needle = trimmed.lowercased()
        return model.availableVoices.filter { option in
            option.name.lowercased().contains(needle)
                || option.language.lowercased().contains(needle)
                || option.detailLabel.lowercased().contains(needle)
        }
    }

    private var panelBackground: some View {
        RoundedRectangle(cornerRadius: 24, style: .continuous)
            .fill(.ultraThinMaterial)
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
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
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
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
            )
    }
}

private struct VoicePickerSectionTitle: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.custom("Avenir Next", size: 9).weight(.semibold))
            .foregroundColor(.white.opacity(0.7))
            .tracking(0.6)
    }
}

private struct VoiceDefaultRow: View {
    let detail: String
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(isSelected ? OverlayPalette.cyan : .white.opacity(0.4))
                VStack(alignment: .leading, spacing: 2) {
                    Text("System Default")
                        .font(.custom("Avenir Next", size: 10).weight(.semibold))
                        .foregroundColor(.white.opacity(0.95))
                    Text(detail)
                        .font(.custom("Avenir Next", size: 9))
                        .foregroundColor(.white.opacity(0.6))
                        .lineLimit(2)
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

private struct VoiceOptionRow: View {
    let option: VoiceOption
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(isSelected ? OverlayPalette.cyan : .white.opacity(0.4))
                VStack(alignment: .leading, spacing: 2) {
                    Text(option.name)
                        .font(.custom("Avenir Next", size: 10).weight(.semibold))
                        .foregroundColor(.white.opacity(0.95))
                    Text(option.detailLabel)
                        .font(.custom("Avenir Next", size: 9))
                        .foregroundColor(.white.opacity(0.6))
                        .lineLimit(2)
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
