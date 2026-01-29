import AVFoundation
import Speech

final class SpeechRecognizer: NSObject {
    enum SpeechError: Error, LocalizedError {
        case recognizerUnavailable
        case notAuthorized
        case engineFailure

        var errorDescription: String? {
            switch self {
            case .recognizerUnavailable:
                return "Speech recognizer is unavailable."
            case .notAuthorized:
                return "Speech recognition or microphone permission denied."
            case .engineFailure:
                return "Audio engine failed to start."
            }
        }
    }

    var onTranscript: ((String) -> Void)?
    var onStateChanged: ((Bool) -> Void)?
    var onError: ((String) -> Void)?
    var onAudioLevel: ((Double) -> Void)?
    var onDebugLog: ((String) -> Void)?

    private let recognizer = SFSpeechRecognizer()
    private var audioEngine = AVAudioEngine()
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var isAuthorized = false
    private var isListeningState = false
    private var isStarting = false
    private var isStopping = false
    private var isRestarting = false
    private var startGeneration: Int = 0
    private var configurationObserver: NSObjectProtocol?
    private var ignoreErrorsUntil: Date?
    private var startAttemptAt: Date?
    private var lastStartAt: Date?
    private var lastStopAt: Date?
    private var recognitionResetTask: Task<Void, Never>?
    private var lastRecognitionResetAt: Date?
    private var committedTranscript: String = ""
    private var configRestartTask: Task<Void, Never>?
    private var engineHealthTask: Task<Void, Never>?

    private let restartCooldown: TimeInterval = 0.6
    private let configChangeGrace: TimeInterval = 1.0
    private let recognitionResetDelay: TimeInterval = 0.2
    private let recognitionResetCooldown: TimeInterval = 0.7
    private let authorizationTimeout: TimeInterval = 6.0

    var isStartingTranscription: Bool {
        isStarting
    }

    func requestAuthorization() async -> Bool {
        if !hasUsageDescription("NSSpeechRecognitionUsageDescription") {
            debugLog("missing NSSpeechRecognitionUsageDescription")
            isAuthorized = false
            onError?("Missing NSSpeechRecognitionUsageDescription")
            return false
        }
        if !hasUsageDescription("NSMicrophoneUsageDescription") {
            debugLog("missing NSMicrophoneUsageDescription")
            isAuthorized = false
            onError?("Missing NSMicrophoneUsageDescription")
            return false
        }
        let speechStatus = SFSpeechRecognizer.authorizationStatus()
        let micStatus = AVCaptureDevice.authorizationStatus(for: .audio)
        debugLog("auth status speech=\(speechStatus) mic=\(micStatus)")
        if speechStatus == .authorized && micStatus == .authorized {
            isAuthorized = true
            return true
        }
        if speechStatus == .denied || speechStatus == .restricted || micStatus == .denied || micStatus == .restricted {
            isAuthorized = false
            onError?(SpeechError.notAuthorized.localizedDescription)
            return false
        }
        let speechAuth = speechStatus == .authorized
            ? true
            : await requestSpeechAuthorizationWithTimeout()
        let micAuth = micStatus == .authorized
            ? true
            : await requestMicrophoneAuthorizationWithTimeout()
        debugLog("auth result speech=\(speechAuth) mic=\(micAuth)")
        let authorized = speechAuth && micAuth
        isAuthorized = authorized
        if !authorized {
            onError?(SpeechError.notAuthorized.localizedDescription)
        }
        return authorized
    }

    func startTranscribing(resetTranscript: Bool = true) async throws {
        debugLog("startTranscribing reset=\(resetTranscript) authorized=\(isAuthorized)")
        guard recognizer != nil else {
            throw SpeechError.recognizerUnavailable
        }

        try Task.checkCancellation()

        if !isAuthorized {
            let authorized = await requestAuthorization()
            guard authorized else {
                throw SpeechError.notAuthorized
            }
        }

        try Task.checkCancellation()

        if isStarting || isListeningState {
            return
        }
        isStarting = true
        defer { isStarting = false }

        if resetTranscript {
            committedTranscript = ""
        }
        recognitionResetTask?.cancel()
        stopTranscribing(clearTranscript: false, notifyState: false, bumpGeneration: false)
        startGeneration += 1
        let generation = startGeneration
        startAttemptAt = Date()
        engineHealthTask?.cancel()
        configRestartTask?.cancel()
        if let lastStopAt {
            let elapsed = Date().timeIntervalSince(lastStopAt)
            if elapsed < restartCooldown {
                let delay = restartCooldown - elapsed
                try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            }
        }

        if Task.isCancelled || generation != startGeneration {
            return
        }

        var lastError: Error?
        for attempt in 0..<3 {
            debugLog("start attempt \(attempt + 1)")
            audioEngine = AVAudioEngine()
            let request = buildRecognitionRequest()
            self.request = request

            let isReady = await waitForInputReady(retries: 10, delayNanos: 150_000_000)
            guard isReady else {
                lastError = SpeechError.engineFailure
                if attempt < 2 {
                    try? await Task.sleep(nanoseconds: 250_000_000)
                    continue
                }
                onError?("No audio input available.")
                debugLog("input not ready")
                stopTranscribing()
                throw SpeechError.engineFailure
            }

            if Task.isCancelled || generation != startGeneration {
                stopTranscribing(clearTranscript: false, notifyState: false)
                return
            }

            do {
                try await MainActor.run {
                    try configureAndStartEngine()
                }
            } catch {
                lastError = error
                debugLog("engine start error \(error.localizedDescription)")
                if shouldRetryEngineStart(error), attempt < 2 {
                    try? await Task.sleep(nanoseconds: 250_000_000)
                    continue
                }
                onError?(error.localizedDescription)
                stopTranscribing()
                throw SpeechError.engineFailure
            }

            if Task.isCancelled || generation != startGeneration {
                stopTranscribing(clearTranscript: false, notifyState: false)
                return
            }

            observeEngineConfiguration()
            lastStartAt = Date()
            setListening(true)
            debugLog("engine started")
            startEngineHealthMonitor()

            startRecognitionTask(with: request)
            return
        }

        if let lastError {
            onError?(lastError.localizedDescription)
        }
        stopTranscribing()
        throw SpeechError.engineFailure
    }

    func stopTranscribing(
        clearTranscript: Bool = true,
        notifyState: Bool = true,
        bumpGeneration: Bool = true
    ) {
        if isStopping {
            return
        }
        isStopping = true
        defer { isStopping = false }

        if bumpGeneration {
            startGeneration += 1
        }
        ignoreErrorsUntil = Date().addingTimeInterval(0.6)
        recognitionResetTask?.cancel()
        recognitionResetTask = nil
        if audioEngine.isRunning {
            audioEngine.stop()
        }
        removeEngineObserver()
        configRestartTask?.cancel()
        engineHealthTask?.cancel()
        audioEngine.inputNode.removeTap(onBus: 0)
        request?.endAudio()
        recognitionTask?.cancel()
        request = nil
        recognitionTask = nil
        if clearTranscript {
            committedTranscript = ""
        }
        updateListeningState(false, notify: notifyState)
        onAudioLevel?(0)
        lastStopAt = Date()
    }

    private func configureAndStartEngine() throws {
        let inputNode = audioEngine.inputNode
        let format = inputNode.outputFormat(forBus: 0)
        debugLog("input format channels=\(format.channelCount) sampleRate=\(format.sampleRate)")
        guard format.channelCount > 0, format.sampleRate > 0 else {
            throw SpeechError.engineFailure
        }
        inputNode.removeTap(onBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: nil) { [weak self] buffer, _ in
            self?.request?.append(buffer)
            guard let self else { return }
            let level = rmsLevel(from: buffer)
            self.onAudioLevel?(level)
        }
        audioEngine.prepare()
        try audioEngine.start()
    }

    private func waitForInputReady(retries: Int, delayNanos: UInt64) async -> Bool {
        for _ in 0..<retries {
            let format = audioEngine.inputNode.outputFormat(forBus: 0)
            if format.channelCount > 0, format.sampleRate > 0 {
                return true
            }
            try? await Task.sleep(nanoseconds: delayNanos)
        }
        return false
    }

    private func shouldRetryEngineStart(_ error: Error) -> Bool {
        let nsError = error as NSError
        if nsError.domain == NSOSStatusErrorDomain || nsError.domain == "com.apple.coreaudio.avfaudio" {
            if nsError.code == -10877 {
                return true
            }
            if nsError.code == -10876 || nsError.code == -10875 || nsError.code == -10868 {
                return true
            }
        }
        return false
    }

    private func shouldIgnoreError(_ error: Error) -> Bool {
        if let ignoreErrorsUntil, Date() < ignoreErrorsUntil {
            return true
        }
        let nsError = error as NSError
        if nsError.domain == "SFSpeechRecognizerErrorDomain" && nsError.code == 1110 {
            return true
        }
        if nsError.domain == "kAFAssistantErrorDomain" && nsError.code == 1110 {
            return true
        }
        let description = nsError.localizedDescription.lowercased()
        return description.contains("no speech") || description.contains("cancel")
    }

    private func observeEngineConfiguration() {
        removeEngineObserver()
        configurationObserver = NotificationCenter.default.addObserver(
            forName: .AVAudioEngineConfigurationChange,
            object: audioEngine,
            queue: .main
        ) { [weak self] _ in
            self?.handleEngineConfigurationChange()
        }
    }

    private func removeEngineObserver() {
        if let configurationObserver {
            NotificationCenter.default.removeObserver(configurationObserver)
            self.configurationObserver = nil
        }
    }

    private func handleEngineConfigurationChange() {
        guard !isRestarting else { return }
        if isStarting {
            return
        }
        if let startAttemptAt, Date().timeIntervalSince(startAttemptAt) < configChangeGrace {
            return
        }
        guard isListeningState || isStarting else { return }
        if let lastStartAt, Date().timeIntervalSince(lastStartAt) < configChangeGrace {
            return
        }
        scheduleConfigurationRestart()
    }

    private func scheduleConfigurationRestart() {
        if configRestartTask != nil {
            return
        }
        configRestartTask = Task { [weak self] in
            guard let self else { return }
            try? await Task.sleep(nanoseconds: 500_000_000)
            self.configRestartTask = nil
            guard self.isListeningState else { return }
            if self.audioEngine.isRunning {
                return
            }
            await self.restartTranscribing(reason: "Audio configuration changed")
        }
    }

    private func startEngineHealthMonitor() {
        engineHealthTask?.cancel()
        engineHealthTask = Task { [weak self] in
            guard let self else { return }
            try? await Task.sleep(nanoseconds: 900_000_000)
            guard self.isListeningState else { return }
            if !self.audioEngine.isRunning {
                await self.restartTranscribing(reason: "Audio engine stopped")
            }
        }
    }

    private func restartTranscribing(reason: String) async {
        guard !isRestarting else { return }
        isRestarting = true
        defer { isRestarting = false }
        stopTranscribing(clearTranscript: false, notifyState: false)
        try? await Task.sleep(nanoseconds: 300_000_000)
        var lastError: Error?
        for attempt in 0..<3 {
            do {
                try await startTranscribing(resetTranscript: false)
                return
            } catch {
                lastError = error
                if error is CancellationError {
                    try? await Task.sleep(nanoseconds: 300_000_000)
                    continue
                }
                if shouldRetryEngineStart(error) && attempt < 2 {
                    try? await Task.sleep(nanoseconds: 300_000_000)
                    continue
                }
                onError?("\(reason): \(error.localizedDescription)")
                return
            }
        }
        if let lastError {
            onError?("\(reason): \(lastError.localizedDescription)")
        }
    }

    private func buildRecognitionRequest() -> SFSpeechAudioBufferRecognitionRequest {
        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        return request
    }

    private func startRecognitionTask(with request: SFSpeechAudioBufferRecognitionRequest) {
        recognitionTask?.cancel()
        recognitionTask = recognizer?.recognitionTask(with: request) { [weak self] result, error in
            guard let self else { return }
            if let result = result {
                self.handleRecognitionResult(result)
            }
            if let error {
                self.handleRecognitionError(error)
            }
        }
    }

    private func handleRecognitionResult(_ result: SFSpeechRecognitionResult) {
        let text = result.bestTranscription.formattedString
        if result.isFinal {
            commitTranscript(text)
            scheduleRecognitionReset(reason: "Final result")
            return
        }
        let combined = mergeTranscript(with: text)
        onTranscript?(combined)
    }

    private func handleRecognitionError(_ error: Error) {
        if isStopping {
            return
        }
        debugLog("recognition error \(error.localizedDescription)")
        if shouldIgnoreError(error) {
            scheduleRecognitionReset(reason: "Ignored recognition error")
            return
        }
        if isRecoverableRecognitionError(error) {
            Task { [weak self] in
                await self?.restartTranscribing(reason: "Recoverable recognition error")
            }
            return
        }
        onError?(error.localizedDescription)
        stopTranscribing()
    }

    private func isRecoverableRecognitionError(_ error: Error) -> Bool {
        if shouldRetryEngineStart(error) {
            return true
        }
        let nsError = error as NSError
        let description = nsError.localizedDescription.lowercased()
        if description.contains("audio engine") || description.contains("audio unit") {
            return true
        }
        if description.contains("avfaudio") || description.contains("input node") || description.contains("input device") {
            return true
        }
        if description.contains("no audio input") {
            return true
        }
        return false
    }

    private func mergeTranscript(with text: String) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return committedTranscript }
        guard !committedTranscript.isEmpty else { return trimmed }
        return "\(committedTranscript) \(trimmed)"
    }

    private func commitTranscript(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        if committedTranscript.isEmpty {
            committedTranscript = trimmed
        } else {
            committedTranscript = "\(committedTranscript) \(trimmed)"
        }
        onTranscript?(committedTranscript)
    }

    private func scheduleRecognitionReset(reason: String) {
        guard isListeningState, !isStopping else { return }
        if recognitionResetTask != nil {
            return
        }
        let now = Date()
        if let lastRecognitionResetAt, now.timeIntervalSince(lastRecognitionResetAt) < recognitionResetCooldown {
            return
        }
        recognitionResetTask = Task { @MainActor [weak self] in
            guard let self else { return }
            try? await Task.sleep(nanoseconds: UInt64(self.recognitionResetDelay * 1_000_000_000))
            self.recognitionResetTask = nil
            guard self.isListeningState, !self.isStopping else { return }
            self.lastRecognitionResetAt = Date()
            let request = self.buildRecognitionRequest()
            self.request?.endAudio()
            self.request = request
            self.startRecognitionTask(with: request)
        }
    }

    private func setListening(_ value: Bool) {
        updateListeningState(value, notify: true)
    }

    private func updateListeningState(_ value: Bool, notify: Bool) {
        guard isListeningState != value else { return }
        isListeningState = value
        if notify {
            onStateChanged?(value)
        }
    }

    private func debugLog(_ message: String) {
        onDebugLog?(message)
    }

    private func hasUsageDescription(_ key: String) -> Bool {
        guard let value = Bundle.main.object(forInfoDictionaryKey: key) as? String else {
            return false
        }
        return !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func requestSpeechAuthorization() async -> Bool {
        await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status == .authorized)
            }
        }
    }

    private func requestMicrophoneAuthorization() async -> Bool {
        await withCheckedContinuation { continuation in
            AVCaptureDevice.requestAccess(for: .audio) { granted in
                continuation.resume(returning: granted)
            }
        }
    }

    private func requestSpeechAuthorizationWithTimeout() async -> Bool {
        await withTaskGroup(of: Bool.self) { group in
            group.addTask { await self.requestSpeechAuthorization() }
            group.addTask {
                try? await Task.sleep(nanoseconds: UInt64(self.authorizationTimeout * 1_000_000_000))
                return false
            }
            let result = await group.next() ?? false
            group.cancelAll()
            if !result {
                debugLog("speech authorization timed out")
            }
            return result
        }
    }

    private func requestMicrophoneAuthorizationWithTimeout() async -> Bool {
        await withTaskGroup(of: Bool.self) { group in
            group.addTask { await self.requestMicrophoneAuthorization() }
            group.addTask {
                try? await Task.sleep(nanoseconds: UInt64(self.authorizationTimeout * 1_000_000_000))
                return false
            }
            let result = await group.next() ?? false
            group.cancelAll()
            if !result {
                debugLog("microphone authorization timed out")
            }
            return result
        }
    }

    private func rmsLevel(from buffer: AVAudioPCMBuffer) -> Double {
        let frameLength = Int(buffer.frameLength)
        guard frameLength > 0 else { return 0 }
        let stride = max(1, frameLength / 256)
        var sum: Double = 0
        var count = 0
        if let channels = buffer.floatChannelData {
            let channel = channels[0]
            var index = 0
            while index < frameLength {
                let sample = Double(channel[index])
                sum += sample * sample
                count += 1
                index += stride
            }
        } else if let channels = buffer.int16ChannelData {
            let channel = channels[0]
            var index = 0
            while index < frameLength {
                let sample = Double(channel[index]) / Double(Int16.max)
                sum += sample * sample
                count += 1
                index += stride
            }
        } else {
            return 0
        }
        guard count > 0 else { return 0 }
        let rms = sqrt(sum / Double(count))
        let scaled = rms * 3.2
        return min(1, max(0, scaled))
    }
}
