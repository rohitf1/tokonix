import SwiftUI

struct SkillsPanel: View {
    @ObservedObject var model: OverlayViewModel
    let onClose: () -> Void
    var presentation: PanelPresentation = .standalone
    @FocusState private var isEditorFocused: Bool

    var body: some View {
        let content = VStack(spacing: 12) {
            header

            HStack(spacing: 12) {
                skillsColumn

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

                editorColumn
            }
        }
        Group {
            if presentation.isEmbedded {
                content
                    .padding(16)
                    .background(panelBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
                    .overlay(loadingOverlay)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            } else {
                content
                    .padding(16)
                    .frame(width: OverlayLayout.skillsPanelWidth, height: OverlayLayout.skillsPanelHeight)
                    .background(panelBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
                    .shadow(color: OverlayPalette.deepSpace.opacity(0.55), radius: 16, x: 0, y: 10)
                    .overlay(loadingOverlay)
            }
        }
        .onAppear {
            model.refreshSkills(forceReload: true)
        }
        .onChange(of: model.selectedSkillPath) { newValue in
            if newValue != nil {
                DispatchQueue.main.async {
                    isEditorFocused = true
                }
            }
        }
    }

    private var header: some View {
        HStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Skills")
                    .font(.custom("Avenir Next", size: 13).weight(.semibold))
                    .foregroundColor(.white.opacity(0.92))
                Text("Manage SKILL.md files")
                    .font(.custom("Avenir Next", size: 9))
                    .foregroundColor(OverlayPalette.cyan.opacity(0.7))
            }

            Spacer()

            if model.isLoadingSkills {
                ProgressView()
                    .scaleEffect(0.6)
            }

            SkillsActionButton(
                title: "Reload",
                systemImage: "arrow.clockwise",
                colors: [OverlayPalette.electricPurple.opacity(0.7), OverlayPalette.magenta.opacity(0.6)],
                action: { model.refreshSkills(forceReload: true) }
            )
            .disabled(model.isLoadingSkills)

            if !presentation.isEmbedded {
                SkillsIconButton(systemName: "chevron.down", label: "Close", onTap: onClose)
            }
        }
    }

    private var skillsColumn: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let status = model.skillsStatusMessage {
                Text(status)
                    .font(.custom("Avenir Next", size: 9))
                    .foregroundColor(OverlayPalette.cyan.opacity(0.8))
            }

            newSkillSection

            skillsList

            if !model.skillErrors.isEmpty {
                skillsErrorsSection
            }
        }
        .padding(12)
        .frame(width: OverlayLayout.skillsListWidth)
        .background(sectionBackground)
        .overlay(sectionBorder)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var newSkillSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("New Skill")
                .font(.custom("Avenir Next", size: 10).weight(.semibold))
                .foregroundColor(.white.opacity(0.8))
                .tracking(0.6)

            SkillsTextField(placeholder: "Name", text: $model.newSkillName)
            SkillsTextField(placeholder: "Description", text: $model.newSkillDescription)

            if let scopePath = model.profileSkillsRootPath {
                Text(scopePath)
                    .font(.custom("Avenir Next", size: 8))
                    .foregroundColor(.white.opacity(0.5))
                    .lineLimit(1)
                    .truncationMode(.middle)
            } else {
                Text("Profile skills path unavailable")
                    .font(.custom("Avenir Next", size: 8))
                    .foregroundColor(OverlayPalette.ember.opacity(0.8))
            }

            SkillsActionButton(
                title: model.isCreatingSkill ? "Creating..." : "Create",
                systemImage: "plus",
                colors: [OverlayPalette.cyan.opacity(0.85), OverlayPalette.neonBlue.opacity(0.7)],
                action: model.createSkill
            )
            .disabled(!canCreateSkill)
        }
    }

    private var skillsList: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Available")
                    .font(.custom("Avenir Next", size: 10).weight(.semibold))
                    .foregroundColor(.white.opacity(0.8))
                Spacer()
                Text("\(model.flatSkills.count)")
                    .font(.custom("Avenir Next", size: 9))
                    .foregroundColor(.white.opacity(0.5))
            }

            ScrollView {
                LazyVStack(alignment: .leading, spacing: 8) {
                    if model.visibleSkills.isEmpty && !model.isLoadingSkills {
                        Text("No skills found.")
                            .font(.custom("Avenir Next", size: 9))
                            .foregroundColor(.white.opacity(0.6))
                            .padding(.vertical, 12)
                            .frame(maxWidth: .infinity, alignment: .center)
                    } else {
                        ForEach(sortedVisibleSkills) { skill in
                            SkillRow(
                                skill: skill,
                                isSelected: skill.path == model.selectedSkillPath,
                                onSelect: { model.selectSkill(skill) },
                                onToggle: { enabled in
                                    model.toggleSkillEnabled(skill, enabled: enabled)
                                }
                            )
                        }
                    }
                }
                .padding(.vertical, 4)
            }
        }
    }

    private var skillsErrorsSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Errors")
                .font(.custom("Avenir Next", size: 9).weight(.semibold))
                .foregroundColor(OverlayPalette.ember.opacity(0.85))
                .tracking(0.6)
            ForEach(model.skillErrors) { error in
                VStack(alignment: .leading, spacing: 2) {
                    Text(error.message)
                        .font(.custom("Avenir Next", size: 9))
                        .foregroundColor(OverlayPalette.ember.opacity(0.85))
                    Text(error.path)
                        .font(.custom("Avenir Next", size: 8))
                        .foregroundColor(.white.opacity(0.4))
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
                .padding(6)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(OverlayPalette.deepSpace.opacity(0.35))
                )
            }
        }
    }

    private var editorColumn: some View {
        VStack(alignment: .leading, spacing: 10) {
            editorHeader

            if let selected = model.selectedSkill {
                ZStack(alignment: .topLeading) {
                    TextEditor(text: $model.skillEditorText)
                        .font(.custom("Avenir Next", size: 10))
                        .foregroundColor(.white.opacity(0.92))
                        .padding(10)
                        .scrollContentBackground(.hidden)
                        .background(editorBackground)
                        .disabled(!selected.scope.isEditable)
                        .focused($isEditorFocused)

                    if model.skillEditorText.isEmpty {
                        Text("Skill file is empty.")
                            .font(.custom("Avenir Next", size: 10))
                            .foregroundColor(.white.opacity(0.4))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)
                            .allowsHitTesting(false)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                if let status = model.skillEditorStatusMessage {
                    Text(status)
                        .font(.custom("Avenir Next", size: 9))
                        .foregroundColor(statusColor(status))
                }

                Text(selected.path)
                    .font(.custom("Avenir Next", size: 8))
                    .foregroundColor(.white.opacity(0.5))
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .textSelection(.enabled)

                HStack(spacing: 8) {
                    SkillsActionButton(
                        title: "Reload",
                        systemImage: "arrow.clockwise",
                        colors: [OverlayPalette.electricPurple.opacity(0.7), OverlayPalette.magenta.opacity(0.6)],
                        action: { model.selectSkill(selected) }
                    )
                    .disabled(model.isLoadingSkillFile || model.isSavingSkillFile)

                    SkillsActionButton(
                        title: model.isSavingSkillFile ? "Saving..." : "Save",
                        systemImage: "tray.and.arrow.down",
                        colors: [OverlayPalette.cyan.opacity(0.85), OverlayPalette.neonBlue.opacity(0.7)],
                        action: model.saveSkillFile
                    )
                    .disabled(!model.hasUnsavedSkillText || !selected.scope.isEditable || model.isSavingSkillFile)

                    Spacer()

                    if !selected.scope.isEditable {
                        Text("Read-only")
                            .font(.custom("Avenir Next", size: 9).weight(.semibold))
                            .foregroundColor(OverlayPalette.ember.opacity(0.9))
                    }
                }
            } else {
                Spacer()
                Text("Select a skill to edit.")
                    .font(.custom("Avenir Next", size: 10))
                    .foregroundColor(.white.opacity(0.6))
                    .frame(maxWidth: .infinity, alignment: .center)
                Spacer()
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(sectionBackground)
        .overlay(sectionBorder)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var panelBackground: some View {
        RoundedRectangle(cornerRadius: 30, style: .continuous)
            .fill(.ultraThinMaterial)
            .overlay(
                RoundedRectangle(cornerRadius: 30, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                OverlayPalette.midnight.opacity(0.62),
                                OverlayPalette.deepSpace.opacity(0.45),
                                OverlayPalette.neonBlue.opacity(0.18),
                                OverlayPalette.magenta.opacity(0.16)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .overlay(panelBorder)
    }

    private var panelBorder: some View {
        RoundedRectangle(cornerRadius: 30, style: .continuous)
            .stroke(
                LinearGradient(
                    colors: [
                        OverlayPalette.cyan.opacity(0.5),
                        OverlayPalette.neonBlue.opacity(0.45),
                        OverlayPalette.magenta.opacity(0.4)
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
            if model.isLoadingSkills || model.isCreatingSkill || model.isSavingSkillFile || model.isLoadingSkillFile {
                RoundedRectangle(cornerRadius: 30, style: .continuous)
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

    private var editorHeader: some View {
        HStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Editor")
                    .font(.custom("Avenir Next", size: 11).weight(.semibold))
                    .foregroundColor(.white.opacity(0.85))
                if let skill = model.selectedSkill {
                    Text(skill.displayName)
                        .font(.custom("Avenir Next", size: 9))
                        .foregroundColor(OverlayPalette.cyan.opacity(0.75))
                } else {
                    Text("No skill selected")
                        .font(.custom("Avenir Next", size: 9))
                        .foregroundColor(.white.opacity(0.5))
                }
            }

            Spacer()

            if let _ = model.selectedSkill {
                Text("Profile")
                    .font(.custom("Avenir Next", size: 8).weight(.semibold))
                    .foregroundColor(.white.opacity(0.65))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(
                        Capsule().fill(OverlayPalette.cyan.opacity(0.2))
                    )
            }
        }
    }

    private var loadingLabel: String {
        if model.isCreatingSkill {
            return "Creating skill..."
        }
        if model.isSavingSkillFile {
            return "Saving skill..."
        }
        if model.isLoadingSkillFile {
            return "Loading skill..."
        }
        return "Loading skills..."
    }

    private var canCreateSkill: Bool {
        let name = model.newSkillName.trimmingCharacters(in: .whitespacesAndNewlines)
        let description = model.newSkillDescription.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty, !description.isEmpty else { return false }
        guard model.profileSkillsRootPath != nil else { return false }
        return !model.isCreatingSkill
    }

    private var sortedVisibleSkills: [SkillMetadata] {
        model.visibleSkills.sorted { $0.displayName.lowercased() < $1.displayName.lowercased() }
    }

    private func statusColor(_ status: String) -> Color {
        let lower = status.lowercased()
        if lower.contains("fail") || lower.contains("error") {
            return OverlayPalette.ember
        }
        if lower.contains("saved") || lower.contains("created") {
            return OverlayPalette.cyan
        }
        return .white.opacity(0.7)
    }
}

private struct SkillRow: View {
    let skill: SkillMetadata
    let isSelected: Bool
    let onSelect: () -> Void
    let onToggle: (Bool) -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            VStack(alignment: .leading, spacing: 3) {
                Text(skill.displayName)
                    .font(.custom("Avenir Next", size: 10).weight(.semibold))
                    .foregroundColor(.white.opacity(skill.enabled ? 0.95 : 0.55))
                Text(skill.summary)
                    .font(.custom("Avenir Next", size: 9))
                    .foregroundColor(.white.opacity(0.55))
                    .lineLimit(2)
            }
            Spacer()
            Toggle("", isOn: Binding(
                get: { skill.enabled },
                set: { value in
                    onToggle(value)
                }
            ))
            .labelsHidden()
            .toggleStyle(SwitchToggleStyle(tint: OverlayPalette.cyan))
            .scaleEffect(0.65)
        }
        .padding(8)
        .background(rowBackground)
        .overlay(rowBorder)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .contentShape(Rectangle())
        .onTapGesture { onSelect() }
    }

    private var rowBackground: some View {
        RoundedRectangle(cornerRadius: 12, style: .continuous)
            .fill(isSelected ? OverlayPalette.neonBlue.opacity(0.22) : OverlayPalette.deepSpace.opacity(0.35))
    }

    private var rowBorder: some View {
        RoundedRectangle(cornerRadius: 12, style: .continuous)
            .stroke(
                isSelected ? OverlayPalette.cyan.opacity(0.55) : OverlayPalette.neonBlue.opacity(0.2),
                lineWidth: 1
            )
    }
}

private struct SkillsActionButton: View {
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

private struct SkillsIconButton: View {
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

private struct SkillsTextField: View {
    let placeholder: String
    @Binding var text: String

    var body: some View {
        TextField(placeholder, text: $text)
            .textFieldStyle(.plain)
            .font(.custom("Avenir Next", size: 9))
            .foregroundColor(.white.opacity(0.9))
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
}
