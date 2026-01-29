import Foundation
import AppKit

@MainActor
final class OverlayViewModel: ObservableObject {
    @Published var transcript: String = ""
    @Published var assistantReply: String = ""
    @Published var assistantSpokenText: String = ""
    @Published var audioLevel: Double = 0
    @Published var silenceProgress: Double = 0
    @Published var chatMessages: [ChatMessage] = []
    @Published var threadSummaries: [ThreadSummary] = []
    @Published var threadCursor: String? = nil
    @Published var isLoadingThreads: Bool = false
    @Published var isResumingThread: Bool = false
    @Published var currentThreadId: String? = nil
    @Published var isReasoningVisible: Bool = true
    @Published var reasoningText: String = ""
    @Published var loginState: LoginState = .ready
    @Published var errorLog: [OverlayLogEntry] = []
    @Published var statusText: String = "Idle"
    @Published var isListening: Bool = false {
        didSet {
            if oldValue != isListening {
                updateReasoningVisibility()
            }
        }
    }
    @Published var isBusy: Bool = false {
        didSet {
            if oldValue != isBusy {
                updateReasoningVisibility()
            }
        }
    }
    @Published var isSpeaking: Bool = false {
        didSet {
            if oldValue != isSpeaking {
                updateReasoningVisibility()
            }
        }
    }
    @Published var isConnected: Bool = false
    @Published var shouldSpeakReplies: Bool = true
    @Published var isAutoListenEnabled: Bool = true
    @Published var errorMessage: String? = nil
    @Published var voiceDescription: String = "Voice: Default"
    @Published var thinkingElapsedText: String = ""
    @Published var availableVoices: [VoiceOption] = []
    @Published var isLoadingVoices: Bool = false
    @Published var voiceListError: String? = nil
    @Published var selectedVoiceIdentifier: String? = nil
    @Published var availableModels: [ModelOption] = []
    @Published var isLoadingModels: Bool = false
    @Published var modelListError: String? = nil
    @Published var selectedModelSlug: String? = nil
    @Published var selectedReasoningEffort: ReasoningEffort? = nil
    @Published var instructionsText: String = ""
    @Published var isLoadingInstructions: Bool = false
    @Published var isSavingInstructions: Bool = false
    @Published var isRestartingSession: Bool = false
    @Published var instructionsStatusMessage: String? = nil
    @Published var skillsEntries: [SkillsListEntry] = []
    @Published var isLoadingSkills: Bool = false
    @Published var skillsStatusMessage: String? = nil
    @Published var selectedSkillPath: String? = nil
    @Published var skillEditorText: String = ""
    @Published var isLoadingSkillFile: Bool = false
    @Published var isSavingSkillFile: Bool = false
    @Published var isCreatingSkill: Bool = false
    @Published var skillEditorStatusMessage: String? = nil
    @Published var newSkillName: String = ""
    @Published var newSkillDescription: String = ""

    private let speechRecognizer = SpeechRecognizer()
    private let speechSynthesizer = SpeechSynthesizer()
    private let tokonixClient = TokonixAppServerClient()
    private let debugLogger = OverlayDebugLogger.shared
    private var pendingTranscript: String?
    private var hasListenSession = false
    private var isInterrupting = false
    private var userAudioLevel: Double = 0
    private var agentAudioLevel: Double = 0
    private var levelTask: Task<Void, Never>?
    private var micStressTask: Task<Void, Never>?
    private var listenStartTask: Task<Void, Never>?
    private var listenTask: Task<Void, Never>?
    private var micRecoveryTask: Task<Void, Never>?
    private var hasSpeechActivity = false
    private var lastSpeechActivityAt: Date?
    private var hasRecoverableMicError = false
    private var listenSessionStartAt: Date?
    private let micProbeLogger = MicProbeLogger()
    private let minListenDuration: TimeInterval = 0.5
    private var lastToggleAt: Date?
    private let toggleDebounce: TimeInterval = 0.35
    private let speechActivityThreshold: Double = 0.12
    private let silenceDuration: TimeInterval = 1.5
    private let silenceDebounceDuration: TimeInterval = 0.25
    private let autoListenRetryInterval: TimeInterval = 0.9
    private let micRecoveryDelay: TimeInterval = 1.0
    private let listenStartTimeout: TimeInterval = 2.5
    private let listenStartMaxDelay: TimeInterval = 6.0
    private var lastAutoListenAttempt = Date.distantPast
    private var lastListenSkipReason: String?
    private var lastListenSkipAt = Date.distantPast
    private let listenSkipLogInterval: TimeInterval = 1.0
    private var activeAssistantMessageId: String?
    private var thinkingStartTime: Date?
    private var thinkingElapsedSeconds: Int = 0
    private let maxReasoningCharacters = 560
    private let maxErrorLogEntries = 80
    private var hasReceivedReasoning = false
    private let reasoningPlaceholder = "Thinking in progress"
    private var hasAgentResponseStarted = false
    private var lastSavedInstructions: String = ""
    private var lastLoadedSkillText: String = ""
    private var lastLoadedSkillPath: String? = nil
    private var pendingSkillSelectionPath: String? = nil
    private let voicePreferenceKey = "TokonixOverlayVoiceIdentifier"
    private let voicePreviewText = "Tokonix voice preview. How does this sound?"

    init() {
        selectedVoiceIdentifier = loadPreferredVoiceIdentifier()
        speechSynthesizer.setPreferredVoice(identifier: selectedVoiceIdentifier)
        voiceDescription = speechSynthesizer.voiceDescription()
        wireSpeechRecognizer()
        wireTokonixClient()
        wireSpeechSynthesizer()
        refreshVoices()
        startLevelTimer()
    }

    deinit {
        levelTask?.cancel()
        listenStartTask?.cancel()
        listenTask?.cancel()
        micStressTask?.cancel()
    }

    func start() {
        if ProcessInfo.processInfo.environment["TOKONIX_OVERLAY_MIC_STRESS"] == "1" {
            statusText = "Mic stress"
            startMicStress()
            return
        }
        if ProcessInfo.processInfo.environment["TOKONIX_OVERLAY_MIC_TOGGLE"] == "1" {
            statusText = "Mic toggle probe"
            startMicToggleProbe()
            return
        }
        statusText = "Connecting"
        Task {
            do {
                try await tokonixClient.start()
            } catch {
                recordError(error.localizedDescription)
                errorMessage = error.localizedDescription
                statusText = "Connection failed"
            }
        }
    }

    func reconnect() {
        errorMessage = nil
        statusText = "Reconnecting"
        Task {
            tokonixClient.stop()
            do {
                try await tokonixClient.start()
            } catch {
                recordError(error.localizedDescription)
                errorMessage = error.localizedDescription
                statusText = "Connection failed"
                if isRestartingSession {
                    isRestartingSession = false
                    setInstructionsStatus("Restart failed", clearAfter: 3.0)
                }
            }
        }
    }

    var instructionsFilePath: String? {
        instructionsFileURL?.path
    }

    var hasUnsavedInstructions: Bool {
        instructionsText != lastSavedInstructions
    }

    func loadOverlayInstructions() {
        guard !isLoadingInstructions else { return }
        guard let url = instructionsFileURL else {
            setInstructionsStatus("Instructions file unavailable", clearAfter: 3.0)
            return
        }
        isLoadingInstructions = true
        let loadURL = url
        Task.detached { [weak self] in
            let result = Result { try String(contentsOf: loadURL, encoding: .utf8) }
            await MainActor.run {
                guard let self else { return }
                self.isLoadingInstructions = false
                switch result {
                case .success(let text):
                    self.instructionsText = text
                    self.lastSavedInstructions = text
                case .failure(let error):
                    self.setInstructionsStatus("Load failed: \(error.localizedDescription)", clearAfter: 3.0)
                }
            }
        }
    }

    func saveOverlayInstructions(restartAfterSave: Bool = false) {
        guard !isSavingInstructions else { return }
        guard let url = instructionsFileURL else {
            setInstructionsStatus("Instructions file unavailable", clearAfter: 3.0)
            return
        }
        let payload = instructionsText
        isSavingInstructions = true
        setInstructionsStatus("Saving...", clearAfter: nil)
        Task.detached { [weak self] in
            let result = Result {
                try payload.write(to: url, atomically: true, encoding: .utf8)
            }
            await MainActor.run {
                guard let self else { return }
                self.isSavingInstructions = false
                switch result {
                case .success:
                    self.lastSavedInstructions = payload
                    if restartAfterSave {
                        self.setInstructionsStatus("Restarting...", clearAfter: nil)
                        self.restartSessionForInstructions()
                    } else {
                        self.setInstructionsStatus("Saved", clearAfter: 2.0)
                    }
                case .failure(let error):
                    self.setInstructionsStatus("Save failed: \(error.localizedDescription)", clearAfter: 3.0)
                }
            }
        }
    }

    func applyInstructionsAndRestart() {
        saveOverlayInstructions(restartAfterSave: true)
    }

    private var instructionsFileURL: URL? {
        tokonixClient.overlayAgentsPath
    }

    private func restartSessionForInstructions() {
        guard !isRestartingSession else { return }
        isRestartingSession = true
        reconnect()
    }

    private func setInstructionsStatus(_ message: String?, clearAfter: TimeInterval?) {
        instructionsStatusMessage = message
        guard let clearAfter else { return }
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: UInt64(clearAfter * 1_000_000_000))
            if instructionsStatusMessage == message {
                instructionsStatusMessage = nil
            }
        }
    }

    var flatSkills: [SkillMetadata] {
        skillsEntries.flatMap { $0.skills }
    }

    var skillErrors: [SkillErrorInfo] {
        let prefix = userSkillsRootPrefix
        return skillsEntries
            .flatMap { $0.errors }
            .filter { error in
                guard let prefix else { return false }
                return error.path.hasPrefix(prefix)
            }
    }

    var selectedSkill: SkillMetadata? {
        guard let selectedSkillPath else { return nil }
        return visibleSkills.first { $0.path == selectedSkillPath }
    }

    var hasUnsavedSkillText: Bool {
        guard selectedSkill != nil else { return false }
        return skillEditorText != lastLoadedSkillText
    }

    var profileSkillsRootPath: String? {
        resolveUserSkillsRoot()?.path
    }

    var visibleSkills: [SkillMetadata] {
        flatSkills.filter { $0.scope == .user }
    }

    func refreshSkills(forceReload: Bool = false) {
        guard !isLoadingSkills else { return }
        isLoadingSkills = true
        setSkillsStatus("Loading...", clearAfter: nil)
        Task {
            do {
                let entries = try await tokonixClient.listSkills(forceReload: forceReload)
                await MainActor.run {
                    self.skillsEntries = entries
                    self.isLoadingSkills = false
                    self.setSkillsStatus(nil, clearAfter: nil)
                    self.restoreSkillSelectionIfNeeded()
                }
            } catch {
                await MainActor.run {
                    self.recordError(error.localizedDescription)
                    self.setSkillsStatus("Failed to load skills", clearAfter: 3.0)
                    self.isLoadingSkills = false
                }
            }
        }
    }

    func selectSkill(_ skill: SkillMetadata) {
        selectedSkillPath = skill.path
        loadSkillFile(at: skill.path)
    }

    func saveSkillFile() {
        guard let selected = selectedSkill else {
            setSkillEditorStatus("Select a skill to save", clearAfter: 3.0)
            return
        }
        guard selected.scope.isEditable else {
            setSkillEditorStatus("This skill is read-only", clearAfter: 3.0)
            return
        }
        guard !isSavingSkillFile else { return }
        let payload = skillEditorText
        isSavingSkillFile = true
        setSkillEditorStatus("Saving...", clearAfter: nil)
        let url = URL(fileURLWithPath: selected.path)
        Task.detached { [weak self] in
            let result = Result {
                try payload.write(to: url, atomically: true, encoding: .utf8)
            }
            await MainActor.run {
                guard let self else { return }
                self.isSavingSkillFile = false
                switch result {
                case .success:
                    self.lastLoadedSkillText = payload
                    self.lastLoadedSkillPath = selected.path
                    self.setSkillEditorStatus("Saved", clearAfter: 2.0)
                case .failure(let error):
                    self.setSkillEditorStatus("Save failed: \(error.localizedDescription)", clearAfter: 3.0)
                }
            }
        }
    }

    func toggleSkillEnabled(_ skill: SkillMetadata, enabled: Bool) {
        let originalValue = skill.enabled
        updateSkillEnabled(path: skill.path, enabled: enabled)
        Task {
            do {
                let effective = try await tokonixClient.setSkillEnabled(path: skill.path, enabled: enabled)
                updateSkillEnabled(path: skill.path, enabled: effective)
                setSkillsStatus(effective ? "Skill enabled" : "Skill disabled", clearAfter: 2.0)
            } catch {
                updateSkillEnabled(path: skill.path, enabled: originalValue)
                recordError(error.localizedDescription)
                setSkillsStatus("Failed to update skill", clearAfter: 3.0)
            }
        }
    }

    func createSkill() {
        guard !isCreatingSkill else { return }
        let name = newSkillName.trimmingCharacters(in: .whitespacesAndNewlines)
        let description = newSkillDescription.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else {
            setSkillEditorStatus("Skill name is required", clearAfter: 3.0)
            return
        }
        guard !description.isEmpty else {
            setSkillEditorStatus("Skill description is required", clearAfter: 3.0)
            return
        }
        guard let skillsRoot = resolveUserSkillsRoot() else {
            setSkillEditorStatus("Skill location unavailable", clearAfter: 3.0)
            return
        }

        let sanitized = sanitizeSkillFolderName(name)
        let folderName = uniqueSkillFolderName(base: sanitized, root: skillsRoot)
        let skillDir = skillsRoot.appendingPathComponent(folderName)
        let skillFile = skillDir.appendingPathComponent("SKILL.md")
        let contents = buildSkillTemplate(name: name, description: description)

        isCreatingSkill = true
        setSkillEditorStatus("Creating...", clearAfter: nil)
        Task.detached { [weak self] in
            let result = Result {
                try FileManager.default.createDirectory(at: skillDir, withIntermediateDirectories: true)
                try contents.write(to: skillFile, atomically: true, encoding: .utf8)
            }
            await MainActor.run {
                guard let self else { return }
                self.isCreatingSkill = false
                switch result {
                case .success:
                    self.newSkillName = ""
                    self.newSkillDescription = ""
                    self.selectedSkillPath = skillFile.path
                    self.skillEditorText = contents
                    self.lastLoadedSkillText = contents
                    self.lastLoadedSkillPath = skillFile.path
                    self.pendingSkillSelectionPath = skillFile.path
                    self.setSkillEditorStatus("Created", clearAfter: 2.0)
                    self.refreshSkills(forceReload: true)
                case .failure(let error):
                    self.setSkillEditorStatus("Create failed: \(error.localizedDescription)", clearAfter: 3.0)
                }
            }
        }
    }

    private func loadSkillFile(at path: String) {
        guard !isLoadingSkillFile else { return }
        isLoadingSkillFile = true
        setSkillEditorStatus("Loading...", clearAfter: nil)
        let url = URL(fileURLWithPath: path)
        Task.detached { [weak self] in
            let result = Result { try String(contentsOf: url, encoding: .utf8) }
            await MainActor.run {
                guard let self else { return }
                self.isLoadingSkillFile = false
                switch result {
                case .success(let text):
                    self.skillEditorText = text
                    self.lastLoadedSkillText = text
                    self.lastLoadedSkillPath = path
                    self.setSkillEditorStatus(nil, clearAfter: nil)
                case .failure(let error):
                    self.setSkillEditorStatus("Load failed: \(error.localizedDescription)", clearAfter: 3.0)
                }
            }
        }
    }

    private func resolveUserSkillsRoot() -> URL? {
        tokonixClient.overlayHome?.appendingPathComponent("skills")
    }

    private func buildSkillTemplate(name: String, description: String) -> String {
        """
---
name: \(name)
description: \(description)
---

# \(name)

Add instructions here.
"""
    }

    private func sanitizeSkillFolderName(_ name: String) -> String {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let allowed = CharacterSet.alphanumerics
        let separators = CharacterSet(charactersIn: " _-")
        var result = ""
        var previousWasDash = false
        for scalar in trimmed.unicodeScalars {
            if allowed.contains(scalar) {
                result.append(Character(scalar))
                previousWasDash = false
            } else if separators.contains(scalar) {
                if !previousWasDash {
                    result.append("-")
                    previousWasDash = true
                }
            }
        }
        let trimmedResult = result.trimmingCharacters(in: CharacterSet(charactersIn: "-"))
        return trimmedResult.isEmpty ? "new-skill" : trimmedResult
    }

    private func uniqueSkillFolderName(base: String, root: URL) -> String {
        var candidate = base
        var suffix = 2
        while FileManager.default.fileExists(atPath: root.appendingPathComponent(candidate).path) {
            candidate = "\(base)-\(suffix)"
            suffix += 1
        }
        return candidate
    }

    private func restoreSkillSelectionIfNeeded() {
        if let pending = pendingSkillSelectionPath {
            pendingSkillSelectionPath = nil
            if let skill = visibleSkills.first(where: { $0.path == pending }) {
                selectSkill(skill)
                return
            }
        }
        guard let selectedSkillPath else { return }
        if visibleSkills.contains(where: { $0.path == selectedSkillPath }) {
            return
        }
        clearSkillSelection()
    }

    private func clearSkillSelection() {
        selectedSkillPath = nil
        skillEditorText = ""
        lastLoadedSkillText = ""
        lastLoadedSkillPath = nil
    }

    private func updateSkillEnabled(path: String, enabled: Bool) {
        skillsEntries = skillsEntries.map { entry in
            var skills = entry.skills
            if let index = skills.firstIndex(where: { $0.path == path }) {
                var updated = skills[index]
                updated.enabled = enabled
                skills[index] = updated
            }
            return SkillsListEntry(cwd: entry.cwd, skills: skills, errors: entry.errors)
        }
    }

    private var userSkillsRootPrefix: String? {
        guard let root = profileSkillsRootPath else { return nil }
        if root.hasSuffix("/") {
            return root
        }
        return root + "/"
    }

    private func setSkillsStatus(_ message: String?, clearAfter: TimeInterval?) {
        skillsStatusMessage = message
        guard let clearAfter else { return }
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: UInt64(clearAfter * 1_000_000_000))
            if skillsStatusMessage == message {
                skillsStatusMessage = nil
            }
        }
    }

    private func setSkillEditorStatus(_ message: String?, clearAfter: TimeInterval?) {
        skillEditorStatusMessage = message
        guard let clearAfter else { return }
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: UInt64(clearAfter * 1_000_000_000))
            if skillEditorStatusMessage == message {
                skillEditorStatusMessage = nil
            }
        }
    }

    func beginListening() {
        guard !hasListenSession else { return }
        guard !isListening else { return }
        hasListenSession = true
        listenSessionStartAt = Date()
        debugLogger.log("beginListening auto=\(isAutoListenEnabled) busy=\(isBusy) speaking=\(isSpeaking)")
        micProbeLogger.log("beginListening hasListenSession=\(hasListenSession) isListening=\(isListening) isAutoListenEnabled=\(isAutoListenEnabled)")
        resetSilenceTracking()
        errorMessage = nil
        transcript = ""
        assistantReply = ""
        assistantSpokenText = ""
        isSpeaking = false
        speechSynthesizer.stop()
        if isBusy {
            statusText = "Interrupting"
            interruptActiveTurnIfNeeded()
        } else {
            statusText = "Listening"
        }
        listenTask?.cancel()
        listenTask = Task { [weak self] in
            guard let self else { return }
            do {
                try await self.speechRecognizer.startTranscribing()
            } catch {
                if Task.isCancelled || !self.isAutoListenEnabled {
                    return
                }
                self.micProbeLogger.log("beginListening failed error=\(error.localizedDescription)")
                self.hasListenSession = false
                self.handleSpeechFailure(error.localizedDescription)
            }
            self.listenTask = nil
        }
        updateReasoningVisibility()
        scheduleListenWatchdog()
    }

    func endListeningAndSend() {
        guard hasListenSession else { return }
        hasListenSession = false
        speechRecognizer.stopTranscribing()
        resetSilenceTracking()
        debugLogger.log("endListeningAndSend transcriptLen=\(transcript.count)")
        let trimmed = transcript.trimmingCharacters(in: .whitespacesAndNewlines)
        transcript = ""
        assistantSpokenText = ""
        guard !trimmed.isEmpty else {
            if !isBusy {
                statusText = "Listening"
            }
            startListeningIfNeeded()
            return
        }
        Task {
            await handleTranscript(trimmed)
        }
    }

    func cancelListening() {
        hasListenSession = false
        speechRecognizer.stopTranscribing()
        resetSilenceTracking()
        statusText = "Ready"
        listenStartTask?.cancel()
        listenTask?.cancel()
        debugLogger.log("cancelListening")
        micProbeLogger.log("cancelListening")
    }

    func toggleListeningEnabled() {
        micProbeLogger.log("toggleListeningEnabled current=\(isAutoListenEnabled)")
        setListeningEnabled(!isAutoListenEnabled)
    }

    func setListeningEnabled(_ enabled: Bool) {
        guard isAutoListenEnabled != enabled else { return }
        if let lastToggleAt, Date().timeIntervalSince(lastToggleAt) < toggleDebounce {
            micProbeLogger.log("setListeningEnabled ignored debounce")
            return
        }
        lastToggleAt = Date()
        micProbeLogger.log("setListeningEnabled \(enabled)")
        debugLogger.log("setListeningEnabled \(enabled)")
        isAutoListenEnabled = enabled
        if enabled {
            statusText = isConnected ? "Ready" : "Idle"
            errorMessage = nil
            hasRecoverableMicError = false
            micRecoveryTask?.cancel()
            micRecoveryTask = nil
            hasListenSession = false
            speechRecognizer.stopTranscribing()
            resetSilenceTracking()
            listenStartTask?.cancel()
            listenTask?.cancel()
            lastAutoListenAttempt = .distantPast
            listenStartTask = Task { @MainActor [weak self] in
                guard let self else { return }
                try? await Task.sleep(nanoseconds: 150_000_000)
                if self.isSpeaking {
                    self.isSpeaking = false
                    self.speechSynthesizer.stop()
                }
                if self.isBusy {
                    self.statusText = "Interrupting"
                    self.interruptActiveTurnIfNeeded()
                }
                self.beginListening()
            }
        } else {
            hasListenSession = false
            speechRecognizer.stopTranscribing()
            resetSilenceTracking()
            statusText = "Paused"
            listenStartTask?.cancel()
            listenTask?.cancel()
        }
    }

    private func startMicStress() {
        micStressTask?.cancel()
        micStressTask = Task { @MainActor [weak self] in
            guard let self else { return }
            let env = ProcessInfo.processInfo.environment
            let cycles = Int(env["TOKONIX_OVERLAY_MIC_STRESS_CYCLES"] ?? "") ?? 6
            let hold = Double(env["TOKONIX_OVERLAY_MIC_STRESS_HOLD"] ?? "") ?? 0.4
            let interval = Double(env["TOKONIX_OVERLAY_MIC_STRESS_INTERVAL"] ?? "") ?? 0.7

            let previousAuto = self.isAutoListenEnabled
            self.isAutoListenEnabled = false
            self.statusText = "Mic stress running"

            for index in 0..<cycles {
                self.recordError("Mic stress cycle \(index + 1) start")
                self.beginListening()
                try? await Task.sleep(nanoseconds: UInt64(hold * 1_000_000_000))
                self.cancelListening()
                try? await Task.sleep(nanoseconds: UInt64(interval * 1_000_000_000))
            }

            self.isAutoListenEnabled = previousAuto
            self.statusText = "Mic stress complete"
        }
    }

    private func startMicToggleProbe() {
        micStressTask?.cancel()
        micStressTask = Task { @MainActor [weak self] in
            guard let self else { return }
            let env = ProcessInfo.processInfo.environment
            let cycles = Int(env["TOKONIX_OVERLAY_MIC_TOGGLE_CYCLES"] ?? "") ?? 6
            let onHold = Double(env["TOKONIX_OVERLAY_MIC_TOGGLE_ON_HOLD"] ?? "") ?? 0.8
            let offHold = Double(env["TOKONIX_OVERLAY_MIC_TOGGLE_OFF_HOLD"] ?? "") ?? 0.8
            let doubleToggle = env["TOKONIX_OVERLAY_MIC_TOGGLE_DOUBLE"] == "1"
            let previousAuto = self.isAutoListenEnabled
            self.micProbeLogger.log("toggleProbe config cycles=\(cycles) onHold=\(String(format: "%.2f", onHold)) offHold=\(String(format: "%.2f", offHold))")

            for index in 0..<cycles {
                self.micProbeLogger.log("toggleProbe cycle \(index + 1) enable")
                self.setListeningEnabled(true)
                if doubleToggle {
                    try? await Task.sleep(nanoseconds: 50_000_000)
                    self.setListeningEnabled(true)
                }
                try? await Task.sleep(nanoseconds: UInt64(onHold * 1_000_000_000))
                self.micProbeLogger.log("toggleProbe cycle \(index + 1) disable")
                self.setListeningEnabled(false)
                if doubleToggle {
                    try? await Task.sleep(nanoseconds: 50_000_000)
                    self.setListeningEnabled(false)
                }
                try? await Task.sleep(nanoseconds: UInt64(offHold * 1_000_000_000))
            }

            self.setListeningEnabled(previousAuto)
            self.statusText = "Mic toggle complete"
        }
    }

    func refreshThreads(reset: Bool) {
        if isLoadingThreads {
            return
        }
        isLoadingThreads = true
        if reset {
            threadSummaries = []
            threadCursor = nil
        }
        let cursor = reset ? nil : threadCursor
        Task {
            do {
                let page = try await tokonixClient.listThreads(cursor: cursor, limit: 20)
                await MainActor.run {
                    if reset {
                        self.threadSummaries = page.threads
                    } else {
                        self.threadSummaries.append(contentsOf: page.threads)
                    }
                    self.threadCursor = page.nextCursor
                    self.isLoadingThreads = false
                }
            } catch {
                await MainActor.run {
                    self.recordError(error.localizedDescription)
                    self.errorMessage = error.localizedDescription
                    self.isLoadingThreads = false
                }
            }
        }
    }

    func resumeThread(_ summary: ThreadSummary) {
        guard !isResumingThread else { return }
        isResumingThread = true
        speechSynthesizer.stop()
        cancelListening()
        statusText = "Resuming"
        Task {
            do {
                let detail = try await tokonixClient.resumeThread(threadId: summary.id)
                await MainActor.run {
                    self.currentThreadId = detail.summary.id
                    self.chatMessages = detail.messages
                    self.assistantReply = ""
                    self.assistantSpokenText = ""
                    self.activeAssistantMessageId = nil
                    self.reasoningText = ""
                    self.hasAgentResponseStarted = false
                    self.isBusy = false
                    self.isInterrupting = false
                    self.statusText = "Ready"
                    self.isResumingThread = false
                    self.startListeningIfNeeded()
                }
            } catch {
                await MainActor.run {
                    self.recordError(error.localizedDescription)
                    self.errorMessage = error.localizedDescription
                    self.statusText = "Resume failed"
                    self.isResumingThread = false
                }
            }
        }
    }

    func startNewThread() {
        guard !isResumingThread else { return }
        isResumingThread = true
        speechSynthesizer.stop()
        cancelListening()
        statusText = "Starting new"
        Task {
            do {
                let detail = try await tokonixClient.startNewThread()
                await MainActor.run {
                    self.currentThreadId = detail.summary.id
                    self.chatMessages = []
                    self.assistantReply = ""
                    self.assistantSpokenText = ""
                    self.activeAssistantMessageId = nil
                    self.reasoningText = ""
                    self.hasAgentResponseStarted = false
                    self.isBusy = false
                    self.isInterrupting = false
                    self.statusText = "Ready"
                    self.isResumingThread = false
                    self.refreshThreads(reset: true)
                    self.startListeningIfNeeded()
                }
            } catch {
                await MainActor.run {
                    self.recordError(error.localizedDescription)
                    self.errorMessage = error.localizedDescription
                    self.statusText = "Start failed"
                    self.isResumingThread = false
                }
            }
        }
    }

    func refreshModels(force: Bool = false) {
        if isLoadingModels {
            return
        }
        if !force && !availableModels.isEmpty {
            return
        }
        debugLogger.log("models refresh start force=\(force) cachedCount=\(availableModels.count)")
        isLoadingModels = true
        modelListError = nil
        Task {
            do {
                let models = try await fetchAllModels()
                availableModels = models
                alignModelSelection(with: models)
                debugLogger.log("models refresh ok count=\(models.count) selected=\(selectedModelSlug ?? "nil") effort=\(selectedReasoningEffort?.label ?? "nil")")
                isLoadingModels = false
            } catch {
                modelListError = error.localizedDescription
                debugLogger.log("models refresh error=\(error.localizedDescription)")
                isLoadingModels = false
            }
        }
    }

    func selectModel(_ model: ModelOption) {
        debugLogger.log("model select slug=\(model.slug) name=\(model.displayName) currentEffort=\(selectedReasoningEffort?.label ?? "nil")")
        selectedModelSlug = model.slug
        if let effort = selectedReasoningEffort, model.supports(effort) {
            debugLogger.log("model select kept effort=\(effort.label)")
            return
        }
        let preferred = preferredReasoningEffort(for: model)
        selectedReasoningEffort = preferred
        debugLogger.log("model select set effort=\(preferred.label)")
    }

    func selectReasoningEffort(_ effort: ReasoningEffort) {
        guard let model = selectedModelOption, model.supports(effort) else {
            debugLogger.log("effort select rejected effort=\(effort.label) model=\(selectedModelSlug ?? "nil")")
            return
        }
        selectedReasoningEffort = effort
        debugLogger.log("effort select set effort=\(effort.label) model=\(model.slug)")
    }

    func refreshVoices() {
        if isLoadingVoices {
            return
        }
        isLoadingVoices = true
        voiceListError = nil
        let voices = SpeechSynthesizer.availableVoiceOptions()
        availableVoices = voices
        alignVoiceSelection(with: voices)
        isLoadingVoices = false
    }

    func selectVoice(_ option: VoiceOption?) {
        let identifier = option?.identifier
        debugLogger.log("voice select id=\(identifier ?? "default")")
        selectedVoiceIdentifier = identifier
        applySelectedVoice()
    }

    func retryLogin() {
        Task {
            do {
                try await tokonixClient.beginChatGptLogin()
            } catch {
                await MainActor.run {
                    self.recordError(error.localizedDescription)
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }

    func clearErrorLog() {
        errorLog.removeAll()
    }

    var selectedVoiceOption: VoiceOption? {
        guard let selectedVoiceIdentifier else { return nil }
        return availableVoices.first { $0.identifier == selectedVoiceIdentifier }
    }

    var currentVoiceLabel: String {
        selectedVoiceOption?.name ?? "System Default"
    }

    var currentVoiceDetail: String {
        selectedVoiceOption?.detailLabel ?? voiceDescription.replacingOccurrences(of: "Voice: ", with: "")
    }

    var canPreviewVoice: Bool {
        !isBusy && !isListening && !isSpeaking
    }

    func previewVoice() {
        guard canPreviewVoice else { return }
        debugLogger.log("voice preview")
        speechSynthesizer.speak(voicePreviewText)
    }

    private func sendTranscript(_ text: String) async {
        isInterrupting = false
        statusText = "Thinking"
        isBusy = true
        hasAgentResponseStarted = false
        startThinkingTimer()
        assistantReply = ""
        assistantSpokenText = ""
        activeAssistantMessageId = nil
        transcript = ""
        if isSpeaking {
            isSpeaking = false
        }
        speechSynthesizer.stop()
        appendUserMessage(text)
        do {
            try await tokonixClient.sendUserMessage(
                text,
                model: selectedModelSlug,
                reasoningEffort: selectedReasoningEffort
            )
        } catch {
            recordError(error.localizedDescription)
            errorMessage = error.localizedDescription
            statusText = "Send failed"
            isBusy = false
            stopThinkingTimer()
        }
    }

    private func handleTranscript(_ text: String) async {
        if isBusy {
            pendingTranscript = text
            statusText = "Interrupting"
            interruptActiveTurnIfNeeded()
            return
        }
        await sendTranscript(text)
    }

    private func appendUserMessage(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let message = ChatMessage(
            id: UUID().uuidString,
            role: .user,
            text: trimmed,
            isStreaming: false
        )
        chatMessages.append(message)
    }

    private func appendAssistantDelta(_ delta: String) {
        guard !delta.isEmpty else { return }
        if let activeId = activeAssistantMessageId,
           let index = chatMessages.firstIndex(where: { $0.id == activeId }) {
            chatMessages[index].text = assistantReply
            chatMessages[index].isStreaming = true
        } else {
            let id = UUID().uuidString
            let message = ChatMessage(
                id: id,
                role: .assistant,
                text: assistantReply,
                isStreaming: true
            )
            chatMessages.append(message)
            activeAssistantMessageId = id
        }
    }

    private func finishAssistantMessage() {
        guard let activeId = activeAssistantMessageId,
              let index = chatMessages.firstIndex(where: { $0.id == activeId }) else {
            return
        }
        chatMessages[index].isStreaming = false
        activeAssistantMessageId = nil
    }

    private func appendReasoning(_ delta: String) {
        guard !hasAgentResponseStarted else { return }
        guard !delta.isEmpty else { return }
        if !hasReceivedReasoning {
            hasReceivedReasoning = true
            reasoningText = ""
            debugLogger.log("reasoning started")
        }
        reasoningText.append(delta)
        if reasoningText.count > maxReasoningCharacters {
            reasoningText = String(reasoningText.suffix(maxReasoningCharacters))
        }
        updateReasoningVisibility()
    }

    private func appendReasoningBreak() {
        guard !hasAgentResponseStarted else { return }
        if !hasReceivedReasoning {
            hasReceivedReasoning = true
            reasoningText = ""
        }
        if !reasoningText.isEmpty, !reasoningText.hasSuffix("\n") {
            reasoningText.append("\n")
        }
        updateReasoningVisibility()
    }

    private func updateReasoningVisibility() {
        let shouldShow = isBusy
            && !isListening
            && !isSpeaking
            && !hasAgentResponseStarted
            && !reasoningText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        if isReasoningVisible != shouldShow {
            let trimmedEmpty = reasoningText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            debugLogger.log("reasoningVisible \(isReasoningVisible) -> \(shouldShow) busy=\(isBusy) listening=\(isListening) speaking=\(isSpeaking) agentStarted=\(hasAgentResponseStarted) textEmpty=\(trimmedEmpty)")
            isReasoningVisible = shouldShow
        }
    }

    private func stopReasoningDisplay() {
        guard !hasAgentResponseStarted else { return }
        hasAgentResponseStarted = true
        reasoningText = ""
        hasReceivedReasoning = false
        debugLogger.log("stopReasoningDisplay busy=\(isBusy) listening=\(isListening) speaking=\(isSpeaking)")
        updateReasoningVisibility()
    }

    private func interruptActiveTurnIfNeeded() {
        guard isBusy else { return }
        if isInterrupting { return }
        isInterrupting = true
        Task {
            await attemptInterrupt(retries: 3)
        }
    }

    private func attemptInterrupt(retries: Int) async {
        guard isBusy else {
            isInterrupting = false
            return
        }
        do {
            let didInterrupt = try await tokonixClient.interruptActiveTurn()
            if didInterrupt {
                return
            }
            if retries > 0 {
                try? await Task.sleep(nanoseconds: 250_000_000)
                await attemptInterrupt(retries: retries - 1)
            } else {
                isInterrupting = false
            }
        } catch {
            errorMessage = error.localizedDescription
            statusText = "Interrupt failed"
            isInterrupting = false
        }
    }

    private func wireSpeechRecognizer() {
        speechRecognizer.onDebugLog = { [weak self] message in
            self?.micProbeLogger.log("speechRecognizer \(message)")
        }

        speechRecognizer.onTranscript = { [weak self] text in
            Task { @MainActor in
                guard let self else { return }
                guard self.hasListenSession || self.isListening else { return }
                self.transcript = text
                if !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    self.markSpeechActivity()
                }
            }
        }

        speechRecognizer.onStateChanged = { [weak self] isListening in
            Task { @MainActor in
                guard let self else { return }
                self.debugLogger.log("speech state listening=\(isListening) hasListenSession=\(self.hasListenSession) auto=\(self.isAutoListenEnabled)")
                self.micProbeLogger.log("speechRecognizer state=\(isListening) hasListenSession=\(self.hasListenSession) auto=\(self.isAutoListenEnabled)")
                self.isListening = isListening
                self.updateReasoningVisibility()
                self.micProbeLogger.log("onStateChanged isListening=\(isListening) hasListenSession=\(self.hasListenSession)")
                if !isListening,
                   self.hasListenSession,
                   self.isAutoListenEnabled,
                   let startAt = self.listenSessionStartAt {
                    let delta = Date().timeIntervalSince(startAt)
                    if delta < self.minListenDuration {
                        self.micProbeLogger.log("stopTooSoon delta=\(String(format: "%.3f", delta))")
                        self.hasListenSession = false
                        self.resetSilenceTracking()
                        self.listenStartTask?.cancel()
                        self.listenStartTask = Task { @MainActor [weak self] in
                            guard let self else { return }
                            try? await Task.sleep(nanoseconds: 200_000_000)
                            self.startListeningIfNeeded()
                        }
                        return
                    }
                }
                if isListening && self.hasRecoverableMicError {
                    self.errorMessage = nil
                    self.hasRecoverableMicError = false
                }
                if self.errorMessage != nil {
                    return
                }
                if self.isInterrupting {
                    self.statusText = "Interrupting"
                    return
                }
                if !self.isAutoListenEnabled && !isListening {
                    self.statusText = "Paused"
                    return
                }
                if isListening {
                    self.statusText = "Listening"
                    return
                }
                if self.isBusy {
                    self.statusText = "Responding"
                } else if self.isSpeaking {
                    self.statusText = "Speaking"
                } else {
                    self.statusText = self.isConnected ? "Ready" : "Idle"
                }
                if !isListening && self.hasListenSession && self.errorMessage == nil {
                    self.handleListeningStopped()
                }
            }
        }

        speechRecognizer.onAudioLevel = { [weak self] level in
            Task { @MainActor in
                guard let self else { return }
                self.userAudioLevel = self.clamp(level * 1.3)
            }
        }

        speechRecognizer.onError = { [weak self] message in
            Task { @MainActor in
                guard let self else { return }
                self.debugLogger.log("speech error=\(message)")
                self.micProbeLogger.log("speechRecognizer error=\(message)")
                if self.shouldIgnoreSpeechError(message) {
                    if !self.isListening && !self.isBusy {
                        self.statusText = self.isConnected ? "Ready" : "Idle"
                    }
                    return
                }
                self.hasListenSession = false
                self.resetSilenceTracking()
                self.handleSpeechFailure(message)
            }
        }
    }

    private func wireSpeechSynthesizer() {
        speechSynthesizer.onStart = { [weak self] in
            Task { @MainActor in
                guard let self else { return }
                self.debugLogger.log("speech start busy=\(self.isBusy) listening=\(self.isListening) reasoningVisible=\(self.isReasoningVisible)")
                if self.isListening || self.hasListenSession {
                    self.hasListenSession = false
                    self.speechRecognizer.stopTranscribing()
                    self.resetSilenceTracking()
                }
                self.isSpeaking = true
                self.stopReasoningDisplay()
                self.statusText = "Speaking"
                self.updateReasoningVisibility()
            }
        }

        speechSynthesizer.onSpokenPrefix = { [weak self] prefix in
            Task { @MainActor in
                guard let self else { return }
                self.debugLogger.log("speech prefix len=\(prefix.count) busy=\(self.isBusy) listening=\(self.isListening) hasListenSession=\(self.hasListenSession)")
                if self.isBusy || self.isListening || self.hasListenSession {
                    return
                }
                self.assistantSpokenText = prefix
                self.updateReasoningVisibility()
            }
        }

        speechSynthesizer.onAudioLevel = { [weak self] level in
            Task { @MainActor in
                guard let self else { return }
                self.agentAudioLevel = self.clamp(level * 1.1)
            }
        }

        speechSynthesizer.onFinish = { [weak self] in
            Task { @MainActor in
                guard let self else { return }
                self.debugLogger.log("speech finish busy=\(self.isBusy) listening=\(self.isListening)")
                self.isSpeaking = false
                self.agentAudioLevel = 0
                if self.isBusy && self.hasAgentResponseStarted {
                    self.isBusy = false
                }
                if self.isListening {
                    self.statusText = "Listening"
                } else if self.isBusy {
                    self.statusText = "Responding"
                } else {
                    self.statusText = "Ready"
                }
                self.updateReasoningVisibility()
                self.startListeningIfNeeded()
            }
        }
    }

    private func wireTokonixClient() {
        tokonixClient.onThreadLoaded = { [weak self] detail in
            Task { @MainActor in
                guard let self else { return }
                self.currentThreadId = detail.summary.id
                self.chatMessages = detail.messages
                self.assistantReply = ""
                self.assistantSpokenText = ""
                self.activeAssistantMessageId = nil
                self.applyThreadConfiguration(detail)
            }
        }

        tokonixClient.onLoginStateChanged = { [weak self] state in
            Task { @MainActor in
                self?.loginState = state
            }
        }

        tokonixClient.onReasoningSummaryDelta = { [weak self] delta in
            Task { @MainActor in
                self?.appendReasoning(delta)
            }
        }

        tokonixClient.onReasoningSummaryBreak = { [weak self] in
            Task { @MainActor in
                self?.appendReasoningBreak()
            }
        }

        tokonixClient.onReasoningRawDelta = { [weak self] delta in
            Task { @MainActor in
                self?.appendReasoning(delta)
            }
        }

        tokonixClient.onConnected = { [weak self] in
            self?.isConnected = true
            self?.statusText = "Ready"
            self?.refreshModels()
            self?.startListeningIfNeeded()
            if self?.isRestartingSession == true {
                self?.isRestartingSession = false
                self?.setInstructionsStatus("Applied", clearAfter: 2.0)
            }
        }

        tokonixClient.onDisconnected = { [weak self] in
            self?.isConnected = false
            self?.statusText = "Disconnected"
            self?.isBusy = false
            self?.isInterrupting = false
            self?.hasListenSession = false
            self?.speechRecognizer.stopTranscribing()
            self?.resetSilenceTracking()
            self?.stopThinkingTimer()
            self?.reasoningText = ""
            self?.hasAgentResponseStarted = false
            self?.hasReceivedReasoning = false
            self?.updateReasoningVisibility()
        }

        tokonixClient.onAgentMessageDelta = { [weak self] delta in
            Task { @MainActor in
                guard let self else { return }
                if !self.hasAgentResponseStarted {
                    self.debugLogger.log("agent delta first len=\(delta.count)")
                }
                if self.isListening || self.isInterrupting {
                    return
                }
                self.stopReasoningDisplay()
                self.assistantReply.append(delta)
                self.appendAssistantDelta(delta)
            }
        }

        tokonixClient.onTurnStarted = { [weak self] in
            Task { @MainActor in
                guard let self else { return }
                self.debugLogger.log("turn started")
                self.isBusy = true
                self.statusText = self.isInterrupting ? "Interrupting" : "Responding"
                self.isSpeaking = false
                self.speechSynthesizer.stop()
                self.activeAssistantMessageId = nil
                self.transcript = ""
                self.assistantSpokenText = ""
                self.hasAgentResponseStarted = false
                self.hasReceivedReasoning = false
                self.reasoningText = self.reasoningPlaceholder
                self.startThinkingTimer()
                self.updateReasoningVisibility()
            }
        }

        tokonixClient.onTurnCompleted = { [weak self] status in
            Task { @MainActor in
                guard let self else { return }
                self.debugLogger.log("turn completed status=\(status ?? "nil") replyLen=\(self.assistantReply.count) speaking=\(self.isSpeaking)")
                self.isBusy = false
                self.isInterrupting = false
                self.errorMessage = nil
                self.stopThinkingTimer()
                self.finishAssistantMessage()
                self.reasoningText = ""
                self.hasAgentResponseStarted = false
                self.hasReceivedReasoning = false
                self.updateReasoningVisibility()
                let pending = self.pendingTranscript
                self.pendingTranscript = nil
                if let pending {
                    await self.sendTranscript(pending)
                    return
                }
                if self.isInterruptedStatus(status) {
                    self.assistantReply = ""
                    if !self.isListening {
                        self.statusText = self.isConnected ? "Ready" : "Idle"
                    }
                    return
                }
                if self.shouldSpeakReplies && !self.assistantReply.isEmpty && !self.isListening {
                    self.assistantSpokenText = ""
                    self.speechSynthesizer.speak(self.assistantReply)
                } else if !self.isListening {
                    self.statusText = "Ready"
                    self.startListeningIfNeeded()
                }
            }
        }

        tokonixClient.onError = { [weak self] message in
            Task { @MainActor in
                guard let self else { return }
                self.recordError(message)
                if self.shouldLogOnlyAppServerError(message) {
                    if !self.isListening && !self.isSpeaking {
                        self.statusText = self.isBusy ? "Responding" : (self.isConnected ? "Ready" : "Idle")
                    }
                    return
                }
                self.errorMessage = message
                self.statusText = "Error: \(message)"
                self.isBusy = false
                self.isInterrupting = false
                self.stopThinkingTimer()
                self.stopReasoningDisplay()
            }
        }

        tokonixClient.onStatus = { [weak self] message in
            Task { @MainActor in
                if self?.errorMessage == nil {
                    self?.statusText = message
                }
            }
        }
    }

    private func startLevelTimer() {
        levelTask?.cancel()
        levelTask = Task { @MainActor [weak self] in
            while !Task.isCancelled {
                guard let self else { return }
                let target = max(self.userAudioLevel, self.agentAudioLevel)
                let smoothed = self.audioLevel + (target - self.audioLevel) * 0.2
                self.audioLevel = self.clamp(smoothed)
                self.agentAudioLevel *= 0.85
                self.userAudioLevel *= 0.92
                self.updateSilenceProgress()
                self.updateThinkingTimer()
                self.ensureAutoListen()
                try? await Task.sleep(nanoseconds: 33_000_000)
            }
        }
    }

    private func startListeningIfNeeded() {
        guard isAutoListenEnabled else {
            logListenSkip("auto-disabled")
            return
        }
        guard isConnected else {
            logListenSkip("disconnected")
            return
        }
        guard !isBusy else {
            logListenSkip("busy")
            return
        }
        guard !isSpeaking else {
            logListenSkip("speaking")
            return
        }
        guard !hasListenSession else {
            logListenSkip("session-active")
            return
        }
        guard errorMessage == nil else {
            logListenSkip("error=\(errorMessage ?? "unknown")")
            return
        }
        beginListening()
    }

    private func scheduleListenWatchdog() {
        listenStartTask?.cancel()
        listenStartTask = Task { @MainActor [weak self] in
            guard let self else { return }
            try? await Task.sleep(nanoseconds: UInt64(self.listenStartTimeout * 1_000_000_000))
            guard self.hasListenSession, !self.isListening else { return }
            guard self.errorMessage == nil else { return }
            if self.speechRecognizer.isStartingTranscription {
                if let startAt = self.listenSessionStartAt,
                   Date().timeIntervalSince(startAt) < self.listenStartMaxDelay {
                    self.scheduleListenWatchdog()
                    return
                }
            }
            self.recordError("Mic did not start; retrying.")
            self.micProbeLogger.log("listenWatchdog retrying")
            self.speechRecognizer.stopTranscribing(clearTranscript: false, notifyState: false)
            self.hasListenSession = false
            self.resetSilenceTracking()
            self.startListeningIfNeeded()
        }
    }

    private func handleListeningStopped() {
        guard hasListenSession else { return }
        let trimmed = transcript.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            micProbeLogger.log("handleListeningStopped empty transcript")
            hasListenSession = false
            resetSilenceTracking()
            startListeningIfNeeded()
            return
        }
        micProbeLogger.log("handleListeningStopped sending transcript")
        endListeningAndSend()
    }

    private func updateSilenceProgress() {
        guard hasListenSession, isListening else {
            resetSilenceTracking()
            return
        }
        if userAudioLevel > speechActivityThreshold {
            markSpeechActivity()
            return
        }
        guard hasSpeechActivity, let lastSpeechActivityAt else {
            silenceProgress = 0
            return
        }
        let elapsed = Date().timeIntervalSince(lastSpeechActivityAt)
        let adjustedElapsed = max(0, elapsed - silenceDebounceDuration)
        silenceProgress = min(1, adjustedElapsed / silenceDuration)
        if adjustedElapsed >= silenceDuration {
            handleSilenceTimeout()
        }
    }

    private func handleSilenceTimeout() {
        guard hasListenSession else { return }
        endListeningAndSend()
    }

    private func resetSilenceTracking() {
        silenceProgress = 0
        hasSpeechActivity = false
        lastSpeechActivityAt = nil
    }

    private func ensureAutoListen() {
        guard isAutoListenEnabled else { return }
        guard isConnected else { return }
        guard !isBusy else { return }
        guard !isSpeaking else { return }
        guard !isListening else { return }
        guard !hasListenSession else { return }
        guard errorMessage == nil else { return }
        let now = Date()
        guard now.timeIntervalSince(lastAutoListenAttempt) >= autoListenRetryInterval else { return }
        lastAutoListenAttempt = now
        beginListening()
    }

    private func logListenSkip(_ reason: String) {
        let now = Date()
        if reason != lastListenSkipReason || now.timeIntervalSince(lastListenSkipAt) > listenSkipLogInterval {
            lastListenSkipReason = reason
            lastListenSkipAt = now
            debugLogger.log("listen skip \(reason) connected=\(isConnected) busy=\(isBusy) speaking=\(isSpeaking) hasSession=\(hasListenSession) error=\(errorMessage ?? "nil")")
        }
    }

    private func clamp(_ value: Double) -> Double {
        min(1, max(0, value))
    }

    private func startThinkingTimer() {
        thinkingStartTime = Date()
        thinkingElapsedSeconds = 0
        thinkingElapsedText = formatElapsedCompact(seconds: 0)
    }

    private func stopThinkingTimer() {
        guard let thinkingStartTime else { return }
        let elapsed = max(0, Int(Date().timeIntervalSince(thinkingStartTime)))
        thinkingElapsedSeconds = elapsed
        thinkingElapsedText = formatElapsedCompact(seconds: elapsed)
        self.thinkingStartTime = nil
    }

    private func updateThinkingTimer() {
        guard isBusy, let thinkingStartTime else {
            return
        }
        let elapsed = max(0, Int(Date().timeIntervalSince(thinkingStartTime)))
        guard elapsed != thinkingElapsedSeconds else { return }
        thinkingElapsedSeconds = elapsed
        thinkingElapsedText = formatElapsedCompact(seconds: elapsed)
    }

    private func formatElapsedCompact(seconds: Int) -> String {
        if seconds < 60 {
            return "\(seconds)s"
        }
        if seconds < 3600 {
            let minutes = seconds / 60
            let remainingSeconds = seconds % 60
            return String(format: "%dm %02ds", minutes, remainingSeconds)
        }
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        let remainingSeconds = seconds % 60
        return String(format: "%dh %02dm %02ds", hours, minutes, remainingSeconds)
    }

    private func shouldIgnoreSpeechError(_ message: String) -> Bool {
        let normalized = message.lowercased()
        if isRecoverableSpeechError(message) {
            return false
        }
        return normalized.contains("no speech") || normalized.contains("cancel")
    }

    private func markSpeechActivity() {
        hasSpeechActivity = true
        lastSpeechActivityAt = Date()
        silenceProgress = 0
    }

    private func handleSpeechFailure(_ message: String) {
        recordError(message)
        if shouldDisableAutoListenForError(message) {
            if isAutoListenEnabled {
                setListeningEnabled(false)
            }
            errorMessage = message
            statusText = "Mic permission needed"
            return
        }
        if isRecoverableSpeechError(message) {
            scheduleMicRecovery(message)
            return
        }
        errorMessage = message
        statusText = "Speech error"
    }

    private func shouldDisableAutoListenForError(_ message: String) -> Bool {
        let normalized = message.lowercased()
        return normalized.contains("not authorized")
            || normalized.contains("permission")
            || normalized.contains("denied")
            || normalized.contains("restricted")
    }

    private func shouldLogOnlyAppServerError(_ message: String) -> Bool {
        let normalized = message.lowercased()
        if isSkillOrToolErrorMessage(normalized) {
            return true
        }
        if isBusy && !isConnectionOrAuthErrorMessage(normalized) {
            return true
        }
        return false
    }

    private func isSkillOrToolErrorMessage(_ message: String) -> Bool {
        let keywords = [
            "skill",
            "tool",
            "function",
            "command",
            "exec",
            "sandbox",
            "approval",
            "permission"
        ]
        return keywords.contains { message.contains($0) }
    }

    private func isConnectionOrAuthErrorMessage(_ message: String) -> Bool {
        let keywords = [
            "connection",
            "disconnected",
            "not running",
            "exited",
            "login",
            "auth",
            "unauthorized",
            "forbidden",
            "network"
        ]
        return keywords.contains { message.contains($0) }
    }

    private func recordError(_ message: String) {
        let trimmed = message.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let entry = OverlayLogEntry(id: UUID(), date: Date(), message: trimmed)
        errorLog.append(entry)
        if errorLog.count > maxErrorLogEntries {
            errorLog.removeFirst(errorLog.count - maxErrorLogEntries)
        }
    }

    private func isRecoverableSpeechError(_ message: String) -> Bool {
        let normalized = message.lowercased()
        if normalized.contains("not authorized") || normalized.contains("permission") || normalized.contains("denied") {
            return false
        }
        if normalized.contains("audio engine failed") {
            return true
        }
        if normalized.contains("audio engine") {
            return true
        }
        if normalized.contains("no audio input") {
            return true
        }
        if normalized.contains("input node") || normalized.contains("input device") {
            return true
        }
        if normalized.contains("audio unit") || normalized.contains("avfaudio") {
            return true
        }
        return false
    }

    private func scheduleMicRecovery(_ message: String) {
        if micRecoveryTask != nil {
            return
        }
        hasRecoverableMicError = true
        errorMessage = message
        statusText = "Recovering mic"
        micRecoveryTask = Task { @MainActor [weak self] in
            guard let self else { return }
            defer { self.micRecoveryTask = nil }
            try? await Task.sleep(nanoseconds: UInt64(micRecoveryDelay * 1_000_000_000))
            if !self.hasRecoverableMicError {
                return
            }
            self.errorMessage = nil
            self.statusText = self.isConnected ? "Ready" : "Idle"
            self.hasRecoverableMicError = false
            self.startListeningIfNeeded()
        }
    }

    private func isInterruptedStatus(_ status: String?) -> Bool {
        guard let status else { return false }
        switch status.lowercased() {
        case "interrupted", "cancelled", "canceled":
            return true
        default:
            return false
        }
    }

    private var selectedModelOption: ModelOption? {
        availableModels.first { $0.slug == selectedModelSlug }
            ?? availableModels.first(where: { $0.isDefault })
            ?? availableModels.first
    }

    private func alignModelSelection(with models: [ModelOption]) {
        let defaultModel = models.first(where: { $0.isDefault }) ?? models.first
        let resolvedModel = models.first { $0.slug == selectedModelSlug } ?? defaultModel
        selectedModelSlug = resolvedModel?.slug
        guard let resolvedModel else {
            selectedReasoningEffort = nil
            return
        }
        if let effort = selectedReasoningEffort, resolvedModel.supports(effort) {
            return
        }
        let preferred = preferredReasoningEffort(for: resolvedModel)
        selectedReasoningEffort = preferred
        debugLogger.log("model align selected=\(selectedModelSlug ?? "nil") effort=\(preferred.label)")
    }

    private func preferredReasoningEffort(for model: ModelOption) -> ReasoningEffort {
        if model.supports(.high) {
            return .high
        }
        return model.defaultReasoningEffort
    }

    private func alignVoiceSelection(with voices: [VoiceOption]) {
        if let selectedVoiceIdentifier,
           !voices.contains(where: { $0.identifier == selectedVoiceIdentifier }) {
            debugLogger.log("voice align cleared missing id=\(selectedVoiceIdentifier)")
            self.selectedVoiceIdentifier = nil
        }
        applySelectedVoice()
    }

    private func applySelectedVoice() {
        speechSynthesizer.setPreferredVoice(identifier: selectedVoiceIdentifier)
        voiceDescription = speechSynthesizer.voiceDescription()
        savePreferredVoiceIdentifier(selectedVoiceIdentifier)
    }

    private func loadPreferredVoiceIdentifier() -> String? {
        let stored = UserDefaults.standard.string(forKey: voicePreferenceKey)
        return stored?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false ? stored : nil
    }

    private func savePreferredVoiceIdentifier(_ identifier: String?) {
        if let identifier {
            UserDefaults.standard.set(identifier, forKey: voicePreferenceKey)
        } else {
            UserDefaults.standard.removeObject(forKey: voicePreferenceKey)
        }
    }

    func logUIEvent(_ message: String) {
        debugLogger.log("ui \(message)")
    }

    private func applyThreadConfiguration(_ detail: ThreadDetail) {
        if let model = detail.model {
            selectedModelSlug = model
        }
        if let effort = detail.reasoningEffort {
            selectedReasoningEffort = effort
        }
        if !availableModels.isEmpty {
            alignModelSelection(with: availableModels)
        } else {
            refreshModels()
        }
    }

    private func fetchAllModels() async throws -> [ModelOption] {
        var models: [ModelOption] = []
        var cursor: String? = nil
        repeat {
            let page = try await tokonixClient.listModels(cursor: cursor, limit: 100)
            models.append(contentsOf: page.models)
            cursor = page.nextCursor
        } while cursor != nil
        return normalizeModels(models)
    }

    private func normalizeModels(_ models: [ModelOption]) -> [ModelOption] {
        var ordered: [ModelOption] = []
        var indexBySlug: [String: Int] = [:]

        for model in models {
            var normalized = normalizeModel(model)
            let trimmedSlug = normalized.slug.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmedSlug.isEmpty else { continue }
            if trimmedSlug != normalized.slug {
                normalized = ModelOption(
                    slug: trimmedSlug,
                    displayName: normalized.displayName,
                    description: normalized.description,
                    supportedReasoningEfforts: normalized.supportedReasoningEfforts,
                    defaultReasoningEffort: normalized.defaultReasoningEffort,
                    isDefault: normalized.isDefault
                )
            }
            if let index = indexBySlug[trimmedSlug] {
                if shouldPreferModel(normalized, over: ordered[index]) {
                    ordered[index] = normalized
                }
            } else {
                indexBySlug[trimmedSlug] = ordered.count
                ordered.append(normalized)
            }
        }

        return ordered
    }

    private func normalizeModel(_ model: ModelOption) -> ModelOption {
        var options = dedupeReasoningOptions(model.supportedReasoningEfforts)
        if !options.contains(where: { $0.effort == model.defaultReasoningEffort }) {
            options.append(ReasoningEffortOption(effort: model.defaultReasoningEffort, description: ""))
        }
        return ModelOption(
            slug: model.slug,
            displayName: model.displayName,
            description: model.description,
            supportedReasoningEfforts: options,
            defaultReasoningEffort: model.defaultReasoningEffort,
            isDefault: model.isDefault
        )
    }

    private func dedupeReasoningOptions(_ options: [ReasoningEffortOption]) -> [ReasoningEffortOption] {
        var seen = Set<String>()
        var result: [ReasoningEffortOption] = []
        for option in options {
            if seen.insert(option.id).inserted {
                result.append(option)
            }
        }
        return result
    }

    private func shouldPreferModel(_ incoming: ModelOption, over existing: ModelOption) -> Bool {
        if incoming.isDefault && !existing.isDefault {
            return true
        }
        if incoming.supportedReasoningEfforts.count > existing.supportedReasoningEfforts.count {
            return true
        }
        if !incoming.description.isEmpty && existing.description.isEmpty {
            return true
        }
        return false
    }
}
