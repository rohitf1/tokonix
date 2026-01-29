import AppKit
import Foundation

final class TokonixAppServerClient {
    struct Configuration {
        let tokonixExecutable: String
        let tokonixHome: URL?
        let cwd: URL
        let model: String?
        let apiKey: String?
        let resumeLatestThread: Bool
        let approvalPolicy: String
        let sandboxMode: String
        let sandboxPolicy: [String: Any]
        let configOverrides: [String: Any]

        static func loadFromEnvironment() -> Configuration {
            let env = ProcessInfo.processInfo.environment
            let executable = resolveTokonixExecutable(env: env)
            let homeOverride = env["TOKONIX_VOICE_OVERLAY_HOME"]
                ?? env["CODEX_VOICE_OVERLAY_HOME"]
                ?? env["TOKONIX_HOME"]
            let resolvedHome = resolveTokonixHome(override: homeOverride)
            let tokonixHome = prepareOverlayHome(resolvedHome)
            let cwdOverride = env["TOKONIX_VOICE_OVERLAY_CWD"] ?? env["CODEX_VOICE_OVERLAY_CWD"]
            let cwd = cwdOverride
                .map { URL(fileURLWithPath: ($0 as NSString).expandingTildeInPath) }
                ?? FileManager.default.homeDirectoryForCurrentUser
            let model = env["TOKONIX_VOICE_OVERLAY_MODEL"] ?? env["CODEX_VOICE_OVERLAY_MODEL"]
            let apiKey = env["TOKONIX_VOICE_OVERLAY_API_KEY"] ?? env["CODEX_VOICE_OVERLAY_API_KEY"]
            let resumeLatestThread = (env["TOKONIX_VOICE_OVERLAY_RESUME_LATEST"]
                ?? env["CODEX_VOICE_OVERLAY_RESUME_LATEST"]
                ?? "1") != "0"

            return Configuration(
                tokonixExecutable: executable,
                tokonixHome: tokonixHome,
                cwd: cwd,
                model: model,
                apiKey: apiKey,
                resumeLatestThread: resumeLatestThread,
                approvalPolicy: "never",
                sandboxMode: "danger-full-access",
                sandboxPolicy: ["type": "dangerFullAccess"],
                configOverrides: [
                    "features": ["exec_policy": false]
                ]
            )
        }

        private static func resolveTokonixHome(override: String?) -> String {
            if let override, !override.isEmpty {
                return (override as NSString).expandingTildeInPath
            }
            return defaultOverlayHome()
        }

        private static func defaultOverlayHome() -> String {
            if let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
                return appSupport
                    .appendingPathComponent("Tokonix")
                    .appendingPathComponent("overlay")
                    .path
            }
            return (NSHomeDirectory() as NSString).appendingPathComponent(".tokonix-overlay")
        }

        private static func prepareOverlayHome(_ path: String) -> URL? {
            let expanded = (path as NSString).expandingTildeInPath
            let url = URL(fileURLWithPath: expanded)
            do {
                try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
            } catch {
                return url
            }

            ensureAgentsFile(at: url)
            ensureConfigFile(at: url)
            ensureReportArtifactsSkill(at: url)
            ensureAppArtifactsSkill(at: url)
            ensureGameArtifactsSkill(at: url)
            ensureVideoArtifactsSkill(at: url)
            ensureVisualDiagramsSkill(at: url)
            ensureSimpleNotesSkill(at: url)
            ensureIotAutomationsSkill(at: url)
            ensureMusicGenerationSkill(at: url)
            return url
        }

        private static func ensureAgentsFile(at home: URL) {
            let agentsPath = home.appendingPathComponent("AGENTS.md")
            let contents = """
Instructions

Add instructions here.
"""
            let legacyContents = [
                """
# Tokonix Overlay Instructions

Add overlay-specific instructions here. Changes apply after restarting the overlay (or starting a new thread).
""",
                """
# AGENTS.md

Add instructions for this profile here. Changes apply after restarting the app (or starting a new thread).
"""
            ]
            if FileManager.default.fileExists(atPath: agentsPath.path) {
                if let existing = try? String(contentsOf: agentsPath, encoding: .utf8),
                   legacyContents.contains(existing) {
                    try? contents.write(to: agentsPath, atomically: true, encoding: .utf8)
                }
                return
            }
            do {
                try contents.write(to: agentsPath, atomically: true, encoding: .utf8)
            } catch {
                // Best-effort; if this fails the overlay still runs without custom instructions.
            }
        }

        private static func ensureConfigFile(at home: URL) {
            let configPath = home.appendingPathComponent("config.toml")
            let contents = """
[features]
web_search_request = true
"""

            if FileManager.default.fileExists(atPath: configPath.path) {
                if let existing = try? String(contentsOf: configPath, encoding: .utf8),
                   existing.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    try? contents.write(to: configPath, atomically: true, encoding: .utf8)
                }
                return
            }

            do {
                try contents.write(to: configPath, atomically: true, encoding: .utf8)
            } catch {
                // Best-effort; if this fails the overlay still runs with defaults.
            }
        }

        private static func ensureReportArtifactsSkill(at home: URL) {
            let skillsRoot = home.appendingPathComponent("skills")
            let destination = skillsRoot.appendingPathComponent("report-artifacts")
            let marker = destination.appendingPathComponent("SKILL.md")
            if FileManager.default.fileExists(atPath: marker.path) {
                return
            }
            _ = removeLegacyArtifactsSkill(at: skillsRoot)
            guard let source = locateReportArtifactsSkillSource() else { return }
            do {
                try FileManager.default.createDirectory(at: skillsRoot, withIntermediateDirectories: true)
                try FileManager.default.copyItem(at: source, to: destination)
            } catch {
                // Best-effort; if this fails the overlay still runs without bundled skills.
            }
        }

        private static func locateReportArtifactsSkillSource() -> URL? {
            let fileManager = FileManager.default
            var current = Bundle.main.bundleURL

            for _ in 0..<8 {
                let candidate = current
                    .appendingPathComponent(".codex")
                    .appendingPathComponent("skills")
                    .appendingPathComponent("report-artifacts")
                let marker = candidate.appendingPathComponent("SKILL.md")
                if fileManager.fileExists(atPath: marker.path) {
                    return candidate
                }
                let parent = current.deletingLastPathComponent()
                if parent.path == current.path {
                    break
                }
                current = parent
            }
            return nil
        }

        private static func ensureAppArtifactsSkill(at home: URL) {
            let skillsRoot = home.appendingPathComponent("skills")
            let destination = skillsRoot.appendingPathComponent("app-artifacts")
            let marker = destination.appendingPathComponent("SKILL.md")
            if FileManager.default.fileExists(atPath: marker.path) {
                return
            }
            guard let source = locateAppArtifactsSkillSource() else { return }
            do {
                try FileManager.default.createDirectory(at: skillsRoot, withIntermediateDirectories: true)
                try FileManager.default.copyItem(at: source, to: destination)
            } catch {
                // Best-effort; if this fails the overlay still runs without bundled skills.
            }
        }

        private static func locateAppArtifactsSkillSource() -> URL? {
            let fileManager = FileManager.default
            var current = Bundle.main.bundleURL

            for _ in 0..<8 {
                let candidate = current
                    .appendingPathComponent(".codex")
                    .appendingPathComponent("skills")
                    .appendingPathComponent("app-artifacts")
                let marker = candidate.appendingPathComponent("SKILL.md")
                if fileManager.fileExists(atPath: marker.path) {
                    return candidate
                }
                let parent = current.deletingLastPathComponent()
                if parent.path == current.path {
                    break
                }
                current = parent
            }
            return nil
        }

        private static func ensureGameArtifactsSkill(at home: URL) {
            let skillsRoot = home.appendingPathComponent("skills")
            let destination = skillsRoot.appendingPathComponent("game-artifacts")
            let marker = destination.appendingPathComponent("SKILL.md")
            if FileManager.default.fileExists(atPath: marker.path) {
                return
            }
            guard let source = locateGameArtifactsSkillSource() else { return }
            do {
                try FileManager.default.createDirectory(at: skillsRoot, withIntermediateDirectories: true)
                try FileManager.default.copyItem(at: source, to: destination)
            } catch {
                // Best-effort; if this fails the overlay still runs without bundled skills.
            }
        }

        private static func locateGameArtifactsSkillSource() -> URL? {
            let fileManager = FileManager.default
            var current = Bundle.main.bundleURL

            for _ in 0..<8 {
                let candidate = current
                    .appendingPathComponent(".codex")
                    .appendingPathComponent("skills")
                    .appendingPathComponent("game-artifacts")
                let marker = candidate.appendingPathComponent("SKILL.md")
                if fileManager.fileExists(atPath: marker.path) {
                    return candidate
                }
                let parent = current.deletingLastPathComponent()
                if parent.path == current.path {
                    break
                }
                current = parent
            }
            return nil
        }

        private static func ensureVideoArtifactsSkill(at home: URL) {
            let skillsRoot = home.appendingPathComponent("skills")
            let destination = skillsRoot.appendingPathComponent("video-artifacts")
            let marker = destination.appendingPathComponent("SKILL.md")
            if FileManager.default.fileExists(atPath: marker.path) {
                return
            }
            guard let source = locateVideoArtifactsSkillSource() else { return }
            do {
                try FileManager.default.createDirectory(at: skillsRoot, withIntermediateDirectories: true)
                try FileManager.default.copyItem(at: source, to: destination)
            } catch {
                // Best-effort; if this fails the overlay still runs without bundled skills.
            }
        }

        private static func locateVideoArtifactsSkillSource() -> URL? {
            let fileManager = FileManager.default
            var current = Bundle.main.bundleURL

            for _ in 0..<8 {
                let candidate = current
                    .appendingPathComponent(".codex")
                    .appendingPathComponent("skills")
                    .appendingPathComponent("video-artifacts")
                let marker = candidate.appendingPathComponent("SKILL.md")
                if fileManager.fileExists(atPath: marker.path) {
                    return candidate
                }
                let parent = current.deletingLastPathComponent()
                if parent.path == current.path {
                    break
                }
                current = parent
            }
            return nil
        }

        private static func removeLegacyArtifactsSkill(at skillsRoot: URL) -> Bool {
            let legacy = skillsRoot.appendingPathComponent("artifacts")
            let marker = legacy.appendingPathComponent("SKILL.md")
            guard FileManager.default.fileExists(atPath: marker.path) else {
                return false
            }
            do {
                try FileManager.default.removeItem(at: legacy)
                return true
            } catch {
                return false
            }
        }

        private static func ensureVisualDiagramsSkill(at home: URL) {
            let skillsRoot = home.appendingPathComponent("skills")
            let destination = skillsRoot.appendingPathComponent("visual-diagrams")
            let marker = destination.appendingPathComponent("SKILL.md")
            if FileManager.default.fileExists(atPath: marker.path) {
                return
            }
            if removeLegacyVisualNotesSkill(at: skillsRoot) == false {
                // best-effort; continue to seed bundled copy.
            }
            guard let source = locateVisualDiagramsSkillSource() else { return }
            do {
                try FileManager.default.createDirectory(at: skillsRoot, withIntermediateDirectories: true)
                try FileManager.default.copyItem(at: source, to: destination)
            } catch {
                // Best-effort; if this fails the overlay still runs without bundled skills.
            }
        }

        private static func locateVisualDiagramsSkillSource() -> URL? {
            let fileManager = FileManager.default
            var current = Bundle.main.bundleURL

            for _ in 0..<8 {
                let candidate = current
                    .appendingPathComponent(".codex")
                    .appendingPathComponent("skills")
                    .appendingPathComponent("visual-diagrams")
                let marker = candidate.appendingPathComponent("SKILL.md")
                if fileManager.fileExists(atPath: marker.path) {
                    return candidate
                }
                let parent = current.deletingLastPathComponent()
                if parent.path == current.path {
                    break
                }
                current = parent
            }
            return nil
        }

        private static func removeLegacyVisualNotesSkill(at skillsRoot: URL) -> Bool {
            let legacy = skillsRoot.appendingPathComponent("visual-notes")
            let marker = legacy.appendingPathComponent("SKILL.md")
            guard FileManager.default.fileExists(atPath: marker.path) else {
                return false
            }
            do {
                try FileManager.default.removeItem(at: legacy)
                return true
            } catch {
                return false
            }
        }

        private static func ensureSimpleNotesSkill(at home: URL) {
            let skillsRoot = home.appendingPathComponent("skills")
            let destination = skillsRoot.appendingPathComponent("simple-notes")
            let marker = destination.appendingPathComponent("SKILL.md")
            if FileManager.default.fileExists(atPath: marker.path) {
                return
            }
            guard let source = locateSimpleNotesSkillSource() else { return }
            do {
                try FileManager.default.createDirectory(at: skillsRoot, withIntermediateDirectories: true)
                try FileManager.default.copyItem(at: source, to: destination)
            } catch {
                // Best-effort; if this fails the overlay still runs without bundled skills.
            }
        }

        private static func locateSimpleNotesSkillSource() -> URL? {
            let fileManager = FileManager.default
            var current = Bundle.main.bundleURL

            for _ in 0..<8 {
                let candidate = current
                    .appendingPathComponent(".codex")
                    .appendingPathComponent("skills")
                    .appendingPathComponent("simple-notes")
                let marker = candidate.appendingPathComponent("SKILL.md")
                if fileManager.fileExists(atPath: marker.path) {
                    return candidate
                }
                let parent = current.deletingLastPathComponent()
                if parent.path == current.path {
                    break
                }
                current = parent
            }
            return nil
        }

        private static func ensureIotAutomationsSkill(at home: URL) {
            let skillsRoot = home.appendingPathComponent("skills")
            let destination = skillsRoot.appendingPathComponent("iot-automations")
            let marker = destination.appendingPathComponent("SKILL.md")
            if FileManager.default.fileExists(atPath: marker.path) {
                return
            }
            guard let source = locateIotAutomationsSkillSource() else { return }
            do {
                try FileManager.default.createDirectory(at: skillsRoot, withIntermediateDirectories: true)
                try FileManager.default.copyItem(at: source, to: destination)
            } catch {
                // Best-effort; if this fails the overlay still runs without bundled skills.
            }
        }

        private static func locateIotAutomationsSkillSource() -> URL? {
            let fileManager = FileManager.default
            var current = Bundle.main.bundleURL

            for _ in 0..<8 {
                let candidate = current
                    .appendingPathComponent(".codex")
                    .appendingPathComponent("skills")
                    .appendingPathComponent("iot-automations")
                let marker = candidate.appendingPathComponent("SKILL.md")
                if fileManager.fileExists(atPath: marker.path) {
                    return candidate
                }
                let parent = current.deletingLastPathComponent()
                if parent.path == current.path {
                    break
                }
                current = parent
            }
            return nil
        }

        private static func ensureMusicGenerationSkill(at home: URL) {
            let skillsRoot = home.appendingPathComponent("skills")
            let destination = skillsRoot.appendingPathComponent("music-generation")
            let marker = destination.appendingPathComponent("SKILL.md")
            if FileManager.default.fileExists(atPath: marker.path) {
                return
            }
            guard let source = locateMusicGenerationSkillSource() else { return }
            do {
                try FileManager.default.createDirectory(at: skillsRoot, withIntermediateDirectories: true)
                try FileManager.default.copyItem(at: source, to: destination)
            } catch {
                // Best-effort; if this fails the overlay still runs without bundled skills.
            }
        }

        private static func locateMusicGenerationSkillSource() -> URL? {
            let fileManager = FileManager.default
            var current = Bundle.main.bundleURL

            for _ in 0..<8 {
                let candidate = current
                    .appendingPathComponent(".codex")
                    .appendingPathComponent("skills")
                    .appendingPathComponent("music-generation")
                let marker = candidate.appendingPathComponent("SKILL.md")
                if fileManager.fileExists(atPath: marker.path) {
                    return candidate
                }
                let parent = current.deletingLastPathComponent()
                if parent.path == current.path {
                    break
                }
                current = parent
            }
            return nil
        }

        private static func resolveTokonixExecutable(env: [String: String]) -> String {
            if let override = env["TOKONIX_VOICE_OVERLAY_BIN"] ?? env["CODEX_VOICE_OVERLAY_BIN"],
               !override.isEmpty {
                return override
            }
            if let bundled = locateRepoTokonixBinary() {
                return bundled
            }
            return "tokonix"
        }

        private static func locateRepoTokonixBinary() -> String? {
            let fileManager = FileManager.default
            let repoCandidates = ["tokonix-rs", "codex-rs"]
            let binCandidates = ["tokonix", "codex"]
            let buildCandidates = ["release", "debug"]
            var current = Bundle.main.bundleURL

            for _ in 0..<8 {
                for repo in repoCandidates {
                    for build in buildCandidates {
                        for bin in binCandidates {
                            let candidate = current
                                .appendingPathComponent(repo)
                                .appendingPathComponent("target")
                                .appendingPathComponent(build)
                                .appendingPathComponent(bin)
                            if fileManager.isExecutableFile(atPath: candidate.path) {
                                return candidate.path
                            }
                        }
                    }
                }

                let parent = current.deletingLastPathComponent()
                if parent.path == current.path {
                    break
                }
                current = parent
            }
            return nil
        }
    }

    enum ClientError: Error, LocalizedError {
        case notRunning
        case invalidResponse
        case missingThread
        case processExited

        var errorDescription: String? {
            switch self {
            case .notRunning:
                return "Tokonix app-server is not running."
            case .invalidResponse:
                return "Received an invalid response from tokonix app-server."
            case .missingThread:
                return "No active Tokonix thread is available."
            case .processExited:
                return "tokonix app-server exited unexpectedly."
            }
        }
    }

    var onAgentMessageDelta: ((String) -> Void)?
    var onTurnStarted: (() -> Void)?
    var onTurnCompleted: ((String?) -> Void)?
    var onStatus: ((String) -> Void)?
    var onError: ((String) -> Void)?
    var onConnected: (() -> Void)?
    var onDisconnected: (() -> Void)?
    var onThreadLoaded: ((ThreadDetail) -> Void)?
    var onLoginStateChanged: ((LoginState) -> Void)?
    var onReasoningSummaryDelta: ((String) -> Void)?
    var onReasoningSummaryBreak: (() -> Void)?
    var onReasoningRawDelta: ((String) -> Void)?

    private let configuration: Configuration
    private let stateQueue = DispatchQueue(label: "tokonix.appserver.state")
    private var process: Process?
    private var stdinHandle: FileHandle?
    private var stdoutHandle: FileHandle?
    private var stderrHandle: FileHandle?
    private var buffer = Data()
    private var nextRequestId: Int = 1
    private var pendingResponses: [Int: CheckedContinuation<[String: Any], Error>] = [:]
    private var threadId: String?
    private var activeTurnId: String?
    private var pendingLogin: (id: String, continuation: CheckedContinuation<Void, Error>)?

    init(configuration: Configuration = .loadFromEnvironment()) {
        self.configuration = configuration
    }

    var overlayHome: URL? {
        configuration.tokonixHome
    }

    var overlayAgentsPath: URL? {
        configuration.tokonixHome?.appendingPathComponent("AGENTS.md")
    }

    var overlayCwd: URL {
        configuration.cwd
    }

    func start() async throws {
        if process != nil, threadId != nil {
            return
        }
        if process != nil {
            stop()
        }

        DispatchQueue.main.async { [weak self] in
            self?.onStatus?("Starting app-server")
        }
        try spawnProcess()
        startReading()

        DispatchQueue.main.async { [weak self] in
            self?.onStatus?("Initializing")
        }
        _ = try await sendRequest(method: "initialize", params: [
            "clientInfo": [
                "name": "tokonix-overlay",
                "title": "Tokonix",
                "version": "0.1.0"
            ]
        ])

        sendNotification(method: "initialized", params: nil)

        DispatchQueue.main.async { [weak self] in
            self?.onStatus?("Authenticating")
        }
        try await ensureAuthenticated()

        let threadDetail = try await openInitialThread()
        DispatchQueue.main.async { [weak self] in
            self?.onThreadLoaded?(threadDetail)
            self?.onConnected?()
        }
    }

    func listThreads(cursor: String? = nil, limit: Int? = nil) async throws -> ThreadListPage {
        var params: [String: Any] = [:]
        if let cursor {
            params["cursor"] = cursor
        }
        if let limit {
            params["limit"] = limit
        }
        let response = try await sendRequest(method: "thread/list", params: params)
        let data = response["data"] as? [[String: Any]] ?? []
        let threads = data.compactMap(parseThreadSummary)
        let nextCursor = response["nextCursor"] as? String
        return ThreadListPage(threads: threads, nextCursor: nextCursor)
    }

    func listModels(cursor: String? = nil, limit: Int? = nil) async throws -> ModelListPage {
        var params: [String: Any] = [:]
        if let cursor {
            params["cursor"] = cursor
        }
        if let limit {
            params["limit"] = limit
        }
        let response = try await sendRequest(method: "model/list", params: params)
        let data = response["data"] as? [[String: Any]] ?? []
        let models = data.compactMap(parseModelOption)
        let nextCursor = response["nextCursor"] as? String
        return ModelListPage(models: models, nextCursor: nextCursor)
    }

    func listSkills(forceReload: Bool = false) async throws -> [SkillsListEntry] {
        let response = try await sendRequest(method: "skills/list", params: [
            "forceReload": forceReload
        ])
        let entries = response["data"] as? [[String: Any]] ?? []
        return entries.compactMap(parseSkillsListEntry)
    }

    func setSkillEnabled(path: String, enabled: Bool) async throws -> Bool {
        let response = try await sendRequest(method: "skills/config/write", params: [
            "path": path,
            "enabled": enabled
        ])
        return response["effectiveEnabled"] as? Bool ?? enabled
    }

    func resumeThread(threadId: String) async throws -> ThreadDetail {
        let response = try await sendRequest(method: "thread/resume", params: buildThreadResumeParams(threadId: threadId))
        let model = response["model"] as? String
        let reasoningEffort = parseReasoningEffort(response["reasoningEffort"])
        guard let thread = response["thread"] as? [String: Any],
              let detail = parseThreadDetail(thread, model: model, reasoningEffort: reasoningEffort) else {
            throw ClientError.invalidResponse
        }
        self.threadId = detail.summary.id
        setActiveTurnId(nil)
        return detail
    }

    func startNewThread() async throws -> ThreadDetail {
        let threadParams = buildThreadStartParams()
        let response = try await sendRequest(method: "thread/start", params: threadParams)
        guard let thread = response["thread"] as? [String: Any],
              let summary = parseThreadSummary(thread) else {
            throw ClientError.invalidResponse
        }
        let model = response["model"] as? String
        let reasoningEffort = parseReasoningEffort(response["reasoningEffort"])
        let detail = ThreadDetail(summary: summary, messages: [], model: model, reasoningEffort: reasoningEffort)
        self.threadId = summary.id
        setActiveTurnId(nil)
        return detail
    }

    func beginChatGptLogin() async throws {
        setLoginState(.inProgress)
        try await startChatGptLogin()
    }

    func sendUserMessage(
        _ text: String,
        model: String? = nil,
        reasoningEffort: ReasoningEffort? = nil
    ) async throws {
        guard let threadId else {
            throw ClientError.missingThread
        }

        var params: [String: Any] = [
            "threadId": threadId,
            "input": [
                ["type": "text", "text": text]
            ],
            "approvalPolicy": configuration.approvalPolicy,
            "sandboxPolicy": configuration.sandboxPolicy
        ]
        if let model {
            params["model"] = model
        }
        if let reasoningEffort {
            params["effort"] = reasoningEffort.rawValue
        }

        let response = try await sendRequest(method: "turn/start", params: params)
        if let turn = response["turn"] as? [String: Any],
           let turnId = turn["id"] as? String {
            setActiveTurnId(turnId)
        }
    }

    func interruptActiveTurn() async throws -> Bool {
        guard let threadId,
              let turnId = getActiveTurnId() else {
            return false
        }
        _ = try await sendRequest(method: "turn/interrupt", params: [
            "threadId": threadId,
            "turnId": turnId
        ])
        return true
    }

    func stop() {
        stdoutHandle?.readabilityHandler = nil
        stderrHandle?.readabilityHandler = nil
        stdinHandle?.closeFile()
        stdoutHandle?.closeFile()
        stderrHandle?.closeFile()
        process?.terminate()
        process = nil
        threadId = nil
        setActiveTurnId(nil)
        failPendingResponses(with: ClientError.processExited)
    }

    private func buildThreadStartParams() -> [String: Any] {
        var params: [String: Any] = [
            "approvalPolicy": configuration.approvalPolicy,
            "sandbox": configuration.sandboxMode,
            "config": configuration.configOverrides
        ]

        params["cwd"] = configuration.cwd.path

        if let model = configuration.model {
            params["model"] = model
        }

        return params
    }

    private func buildThreadResumeParams(threadId: String) -> [String: Any] {
        var params = buildThreadStartParams()
        params["threadId"] = threadId
        return params
    }

    private func openInitialThread() async throws -> ThreadDetail {
        if configuration.resumeLatestThread {
            do {
                DispatchQueue.main.async { [weak self] in
                    self?.onStatus?("Resuming last session")
                }
                let page = try await listThreads(limit: 1)
                if let latest = page.threads.first {
                    return try await resumeThread(threadId: latest.id)
                }
            } catch {
                // Fall back to starting a new thread.
            }
        }
        DispatchQueue.main.async { [weak self] in
            self?.onStatus?("Starting thread")
        }
        return try await startNewThread()
    }

    private func ensureAuthenticated() async throws {
        let response = try await sendRequest(method: "account/read", params: [
            "refreshToken": true
        ])

        let requiresAuth = response["requiresOpenaiAuth"] as? Bool ?? false
        let accountValue = response["account"]
        let hasAccount = !(accountValue is NSNull) && accountValue != nil

        guard requiresAuth && !hasAccount else {
            setLoginState(.ready)
            return
        }

        if let apiKey = configuration.apiKey, !apiKey.isEmpty {
            _ = try await sendRequest(method: "account/login/start", params: [
                "type": "apiKey",
                "apiKey": apiKey
            ])
            setLoginState(.ready)
            return
        }

        setLoginState(.required)
        DispatchQueue.main.async { [weak self] in
            self?.onStatus?("Login required — opening browser")
        }
        do {
            setLoginState(.inProgress)
            try await startChatGptLogin()
        } catch {
            setLoginState(.failed(error.localizedDescription))
            throw error
        }
    }

    private func startChatGptLogin() async throws {
        let response = try await sendRequest(method: "account/login/start", params: [
            "type": "chatgpt"
        ])

        guard let type = response["type"] as? String, type == "chatgpt" else {
            throw ClientError.invalidResponse
        }
        guard let loginId = response["loginId"] as? String,
              let authUrl = response["authUrl"] as? String,
              let url = URL(string: authUrl) else {
            throw ClientError.invalidResponse
        }

        DispatchQueue.main.async {
            NSWorkspace.shared.open(url)
        }

        try await waitForLoginCompletion(loginId: loginId)
    }

    private func waitForLoginCompletion(loginId: String) async throws {
        try await withCheckedThrowingContinuation { continuation in
            stateQueue.sync {
                self.pendingLogin = (id: loginId, continuation: continuation)
            }
        }
    }

    private func spawnProcess() throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        process.arguments = [
            configuration.tokonixExecutable,
            "--config",
            "cli_auth_credentials_store=auto",
            "app-server",
        ]
        process.currentDirectoryURL = configuration.cwd

        var environment = ProcessInfo.processInfo.environment
        let basePath = environment["PATH"] ?? "/usr/bin:/bin:/usr/sbin:/sbin"
        let extraPaths = ["/opt/homebrew/bin", "/usr/local/bin", "\(NSHomeDirectory())/.cargo/bin"]
        let pathComponents = basePath.split(separator: ":").map(String.init)
        let mergedPaths = extraPaths.filter { !pathComponents.contains($0) } + pathComponents
        environment["PATH"] = mergedPaths.joined(separator: ":")
        if let tokonixHome = configuration.tokonixHome {
            try? FileManager.default.createDirectory(at: tokonixHome, withIntermediateDirectories: true)
            environment["TOKONIX_HOME"] = tokonixHome.path
            environment["CODEX_HOME"] = tokonixHome.path
        }
        process.environment = environment

        let stdinPipe = Pipe()
        let stdoutPipe = Pipe()
        let stderrPipe = Pipe()
        process.standardInput = stdinPipe
        process.standardOutput = stdoutPipe
        process.standardError = stderrPipe

        process.terminationHandler = { [weak self] _ in
            self?.cleanupAfterTermination()
            DispatchQueue.main.async {
                self?.onDisconnected?()
            }
        }

        try process.run()

        self.process = process
        self.stdinHandle = stdinPipe.fileHandleForWriting
        self.stdoutHandle = stdoutPipe.fileHandleForReading
        self.stderrHandle = stderrPipe.fileHandleForReading
    }

    private func startReading() {
        stdoutHandle?.readabilityHandler = { [weak self] handle in
            let data = handle.availableData
            guard !data.isEmpty else {
                self?.handleProcessExit()
                return
            }
            self?.buffer.append(data)
            self?.drainBuffer()
        }

        stderrHandle?.readabilityHandler = { [weak self] handle in
            let data = handle.availableData
            guard !data.isEmpty else { return }
            let message = String(data: data, encoding: .utf8) ?? ""
            if !message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                DispatchQueue.main.async {
                    self?.onStatus?("tokonix app-server: \(message.trimmingCharacters(in: .whitespacesAndNewlines))")
                }
            }
        }
    }

    private func handleProcessExit() {
        cleanupAfterTermination()
        DispatchQueue.main.async { [weak self] in
            self?.onError?(ClientError.processExited.localizedDescription)
        }
    }

    private func cleanupAfterTermination() {
        stdoutHandle?.readabilityHandler = nil
        stderrHandle?.readabilityHandler = nil
        stdinHandle?.closeFile()
        stdoutHandle?.closeFile()
        stderrHandle?.closeFile()
        process = nil
        threadId = nil
        setActiveTurnId(nil)
        failPendingResponses(with: ClientError.processExited)
    }

    private func failPendingResponses(with error: Error) {
        let continuations: [CheckedContinuation<[String: Any], Error>] = stateQueue.sync {
            let values = Array(pendingResponses.values)
            pendingResponses.removeAll()
            return values
        }
        continuations.forEach { $0.resume(throwing: error) }
        let loginContinuation = stateQueue.sync { () -> CheckedContinuation<Void, Error>? in
            let continuation = pendingLogin?.continuation
            pendingLogin = nil
            return continuation
        }
        loginContinuation?.resume(throwing: error)
    }

    private func drainBuffer() {
        while let range = buffer.range(of: Data([0x0A])) {
            let lineData = buffer.subdata(in: buffer.startIndex..<range.lowerBound)
            buffer.removeSubrange(buffer.startIndex...range.lowerBound)
            guard let line = String(data: lineData, encoding: .utf8) else { continue }
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.isEmpty { continue }
            handleLine(trimmed)
        }
    }

    private func handleLine(_ line: String) {
        guard let data = line.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) else {
            DispatchQueue.main.async { [weak self] in
                self?.onError?("Failed to parse app-server message.")
            }
            return
        }

        if let dict = json as? [String: Any] {
            handleMessage(dict)
        }
    }

    private func handleMessage(_ message: [String: Any]) {
        if let method = message["method"] as? String {
            if let id = message["id"] {
                handleServerRequest(id: id, method: method, params: message["params"])
            } else {
                handleNotification(method: method, params: message["params"])
            }
            return
        }

        if let id = message["id"] as? Int {
            if let result = message["result"] as? [String: Any] {
                resolvePending(id: id, result: result)
            } else if let error = message["error"] as? [String: Any] {
                resolvePendingError(id: id, error: error)
            } else {
                resolvePendingError(id: id, error: ["message": "Unknown response format"]) 
            }
        }
    }

    private func handleNotification(method: String, params: Any?) {
        switch method {
        case "turn/started":
            DispatchQueue.main.async { [weak self] in
                if let turn = (params as? [String: Any])?["turn"] as? [String: Any],
                   let turnId = turn["id"] as? String {
                    self?.setActiveTurnId(turnId)
                }
                self?.onTurnStarted?()
            }
        case "turn/completed":
            let status = (params as? [String: Any])?["turn"] as? [String: Any]
            let statusValue = status?["status"] as? String
            DispatchQueue.main.async { [weak self] in
                self?.setActiveTurnId(nil)
                self?.onTurnCompleted?(statusValue)
            }
        case "item/agentMessage/delta", "item/assistantMessage/delta":
            if let params = params as? [String: Any],
               let delta = params["delta"] as? String {
                DispatchQueue.main.async { [weak self] in
                    self?.onAgentMessageDelta?(delta)
                }
            }
        case "item/reasoning/summaryTextDelta":
            if let params = params as? [String: Any],
               let delta = params["delta"] as? String {
                DispatchQueue.main.async { [weak self] in
                    self?.onReasoningSummaryDelta?(delta)
                }
            }
        case "item/reasoning/summaryPartAdded":
            DispatchQueue.main.async { [weak self] in
                self?.onReasoningSummaryBreak?()
            }
        case "item/reasoning/textDelta":
            if let params = params as? [String: Any],
               let delta = params["delta"] as? String {
                DispatchQueue.main.async { [weak self] in
                    self?.onReasoningRawDelta?(delta)
                }
            }
        case "error":
            let message = (params as? [String: Any])?["error"] as? [String: Any]
            let text = message?["message"] as? String ?? "Unknown error"
            DispatchQueue.main.async { [weak self] in
                self?.onError?(text)
            }
        case "account/login/completed":
            if let params = params as? [String: Any] {
                handleLoginCompleted(params: params)
            }
        default:
            break
        }
    }

    private func handleLoginCompleted(params: [String: Any]) {
        let success = params["success"] as? Bool ?? false
        let loginId = params["loginId"] as? String
        let error = params["error"] as? String

        let pending = stateQueue.sync { () -> CheckedContinuation<Void, Error>? in
            guard let pendingLogin else { return nil }
            if let loginId, pendingLogin.id != loginId {
                return nil
            }
            self.pendingLogin = nil
            return pendingLogin.continuation
        }

        guard let continuation = pending else { return }

        if success {
            setLoginState(.ready)
            continuation.resume()
        } else {
            let message = error ?? "Login failed"
            setLoginState(.failed(message))
            continuation.resume(throwing: NSError(domain: "TokonixAuth", code: -1, userInfo: [
                NSLocalizedDescriptionKey: message
            ]))
        }
    }

    private func handleServerRequest(id: Any, method: String, params: Any?) {
        switch method {
        case "item/commandExecution/requestApproval":
            sendResponse(id: id, result: ["decision": "acceptForSession"])
        case "item/fileChange/requestApproval":
            sendResponse(id: id, result: ["decision": "acceptForSession"])
        case "execCommandApproval":
            sendResponse(id: id, result: ["decision": "approved_for_session"])
        case "applyPatchApproval":
            sendResponse(id: id, result: ["decision": "approved_for_session"])
        default:
            sendErrorResponse(id: id, message: "Unsupported request: \(method)")
        }
    }

    private func sendRequest(method: String, params: [String: Any]) async throws -> [String: Any] {
        let requestId = nextId()
        var payload: [String: Any] = [
            "id": requestId,
            "method": method,
            "params": params
        ]

        if method == "initialize" {
            payload["params"] = params
        }

        return try await withCheckedThrowingContinuation { continuation in
            stateQueue.sync {
                self.pendingResponses[requestId] = continuation
            }
            do {
                try self.sendPayload(payload)
            } catch {
                self.stateQueue.sync {
                    _ = self.pendingResponses.removeValue(forKey: requestId)
                }
                continuation.resume(throwing: error)
            }
        }
    }

    private func sendNotification(method: String, params: [String: Any]?) {
        var payload: [String: Any] = ["method": method]
        if let params {
            payload["params"] = params
        }
        try? sendPayload(payload)
    }

    private func sendResponse(id: Any, result: [String: Any]) {
        var payload: [String: Any] = ["id": id, "result": result]
        if let intId = id as? Int {
            payload["id"] = intId
        } else if let stringId = id as? String {
            payload["id"] = stringId
        }
        try? sendPayload(payload)
    }

    private func sendErrorResponse(id: Any, message: String) {
        var payload: [String: Any] = [
            "id": id,
            "error": [
                "message": message
            ]
        ]
        if let intId = id as? Int {
            payload["id"] = intId
        } else if let stringId = id as? String {
            payload["id"] = stringId
        }
        try? sendPayload(payload)
    }

    private func setLoginState(_ state: LoginState) {
        DispatchQueue.main.async { [weak self] in
            self?.onLoginStateChanged?(state)
        }
    }

    private func sendPayload(_ payload: [String: Any]) throws {
        guard let stdinHandle else { throw ClientError.notRunning }
        let data = try JSONSerialization.data(withJSONObject: payload)
        stdinHandle.write(data)
        stdinHandle.write(Data([0x0A]))
    }

    private func nextId() -> Int {
        stateQueue.sync {
            let id = nextRequestId
            nextRequestId += 1
            return id
        }
    }

    private func setActiveTurnId(_ id: String?) {
        stateQueue.sync {
            activeTurnId = id
        }
    }

    private func getActiveTurnId() -> String? {
        stateQueue.sync {
            activeTurnId
        }
    }

    private func parseThreadSummary(_ dict: [String: Any]) -> ThreadSummary? {
        guard let id = dict["id"] as? String else { return nil }
        let preview = dict["preview"] as? String ?? ""
        let modelProvider = dict["modelProvider"] as? String ?? "unknown"
        let createdAtValue = dict["createdAt"] as? TimeInterval
            ?? (dict["createdAt"] as? NSNumber)?.doubleValue
            ?? 0
        let path = dict["path"] as? String ?? ""
        return ThreadSummary(
            id: id,
            preview: preview,
            createdAt: Date(timeIntervalSince1970: createdAtValue),
            modelProvider: modelProvider,
            path: path
        )
    }

    private func parseThreadDetail(
        _ dict: [String: Any],
        model: String? = nil,
        reasoningEffort: ReasoningEffort? = nil
    ) -> ThreadDetail? {
        guard let summary = parseThreadSummary(dict) else { return nil }
        let turns = dict["turns"] as? [[String: Any]] ?? []
        let messages = turns.flatMap(parseTurnMessages)
        return ThreadDetail(summary: summary, messages: messages, model: model, reasoningEffort: reasoningEffort)
    }

    private func parseTurnMessages(_ turn: [String: Any]) -> [ChatMessage] {
        guard let items = turn["items"] as? [[String: Any]] else { return [] }
        return items.compactMap(parseThreadItem)
    }

    private func parseThreadItem(_ item: [String: Any]) -> ChatMessage? {
        guard let type = item["type"] as? String else { return nil }
        switch type {
        case "userMessage":
            let content = item["content"] as? [[String: Any]] ?? []
            let text = parseUserContent(content)
            guard !text.isEmpty else { return nil }
            let id = item["id"] as? String ?? UUID().uuidString
            return ChatMessage(id: id, role: .user, text: text, isStreaming: false)
        case "agentMessage":
            let text = item["text"] as? String ?? ""
            guard !text.isEmpty else { return nil }
            let id = item["id"] as? String ?? UUID().uuidString
            return ChatMessage(id: id, role: .assistant, text: text, isStreaming: false)
        case "assistantMessage":
            let text = item["text"] as? String ?? ""
            guard !text.isEmpty else { return nil }
            let id = item["id"] as? String ?? UUID().uuidString
            return ChatMessage(id: id, role: .assistant, text: text, isStreaming: false)
        default:
            return nil
        }
    }

    private func parseUserContent(_ content: [[String: Any]]) -> String {
        var parts: [String] = []
        for entry in content {
            guard let type = entry["type"] as? String else { continue }
            switch type {
            case "text":
                if let text = entry["text"] as? String {
                    parts.append(text)
                }
            case "image", "localImage":
                parts.append("[image]")
            case "skill":
                if let name = entry["name"] as? String {
                    parts.append("[skill: \(name)]")
                } else {
                    parts.append("[skill]")
                }
            default:
                break
            }
        }
        return parts.joined(separator: " ")
    }

    private func parseModelOption(_ dict: [String: Any]) -> ModelOption? {
        guard let slug = dict["model"] as? String else { return nil }
        let displayName = dict["displayName"] as? String ?? slug
        let description = dict["description"] as? String ?? ""
        guard let defaultEffortValue = dict["defaultReasoningEffort"] as? String,
              let defaultEffort = parseReasoningEffort(defaultEffortValue) else {
            return nil
        }
        let supported = (dict["supportedReasoningEfforts"] as? [[String: Any]] ?? [])
            .compactMap(parseReasoningEffortOption)
        let isDefault = dict["isDefault"] as? Bool ?? false
        return ModelOption(
            slug: slug,
            displayName: displayName,
            description: description,
            supportedReasoningEfforts: supported,
            defaultReasoningEffort: defaultEffort,
            isDefault: isDefault
        )
    }

    private func parseReasoningEffortOption(_ dict: [String: Any]) -> ReasoningEffortOption? {
        guard let rawValue = dict["reasoningEffort"] as? String,
              let effort = parseReasoningEffort(rawValue) else {
            return nil
        }
        let description = dict["description"] as? String ?? ""
        return ReasoningEffortOption(effort: effort, description: description)
    }

    private func parseReasoningEffort(_ value: Any?) -> ReasoningEffort? {
        guard let rawValue = value as? String else { return nil }
        return ReasoningEffort(rawValue: rawValue.lowercased())
    }

    private func parseSkillsListEntry(_ dict: [String: Any]) -> SkillsListEntry? {
        let cwd = dict["cwd"] as? String ?? ""
        let skills = (dict["skills"] as? [[String: Any]] ?? [])
            .compactMap(parseSkillMetadata)
        let errors = (dict["errors"] as? [[String: Any]] ?? [])
            .compactMap(parseSkillError)
        return SkillsListEntry(cwd: cwd, skills: skills, errors: errors)
    }

    private func parseSkillMetadata(_ dict: [String: Any]) -> SkillMetadata? {
        guard let name = dict["name"] as? String,
              let description = dict["description"] as? String,
              let path = dict["path"] as? String,
              let scopeRaw = dict["scope"] as? String,
              let scope = SkillScope(rawValue: scopeRaw) else {
            return nil
        }
        let shortDescription = dict["shortDescription"] as? String
        let interface = (dict["interface"] as? [String: Any]).flatMap(parseSkillInterface)
        let enabled = dict["enabled"] as? Bool ?? true
        return SkillMetadata(
            name: name,
            description: description,
            shortDescription: shortDescription,
            interface: interface,
            path: path,
            scope: scope,
            enabled: enabled
        )
    }

    private func parseSkillInterface(_ dict: [String: Any]) -> SkillInterface {
        SkillInterface(
            displayName: dict["displayName"] as? String,
            shortDescription: dict["shortDescription"] as? String,
            iconSmall: dict["iconSmall"] as? String,
            iconLarge: dict["iconLarge"] as? String,
            brandColor: dict["brandColor"] as? String,
            defaultPrompt: dict["defaultPrompt"] as? String
        )
    }

    private func parseSkillError(_ dict: [String: Any]) -> SkillErrorInfo? {
        guard let path = dict["path"] as? String,
              let message = dict["message"] as? String else {
            return nil
        }
        return SkillErrorInfo(path: path, message: message)
    }

    private func resolvePending(id: Int, result: [String: Any]) {
        let continuation = stateQueue.sync { pendingResponses.removeValue(forKey: id) }
        continuation?.resume(returning: result)
    }

    private func resolvePendingError(id: Int, error: [String: Any]) {
        let continuation = stateQueue.sync { pendingResponses.removeValue(forKey: id) }
        let message = (error["message"] as? String) ?? "Unknown error"
        continuation?.resume(throwing: NSError(domain: "TokonixAppServer", code: -1, userInfo: [
            NSLocalizedDescriptionKey: message
        ]))
    }
}

private extension URL {
    func expandingTildeInPath() -> URL {
        let path = (path as NSString).expandingTildeInPath
        return URL(fileURLWithPath: path)
    }
}
