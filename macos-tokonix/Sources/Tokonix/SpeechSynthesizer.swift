import AVFoundation

final class SpeechSynthesizer: NSObject, AVSpeechSynthesizerDelegate {
    private let synthesizer = AVSpeechSynthesizer()
    var onStart: (() -> Void)?
    var onFinish: (() -> Void)?
    var onSpokenPrefix: ((String) -> Void)?
    var onAudioLevel: ((Double) -> Void)?
    private var lastSpokenIndex = 0
    private var preferredVoiceIdentifier: String?

    override init() {
        super.init()
        synthesizer.delegate = self
    }

    func speak(_ text: String) {
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        lastSpokenIndex = 0
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = resolveVoice()
        utterance.rate = 0.52
        utterance.volume = 0.9
        synthesizer.speak(utterance)
    }

    func stop() {
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        onStart?()
        onAudioLevel?(0.35)
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, willSpeakRangeOfSpeechString characterRange: NSRange, utterance: AVSpeechUtterance) {
        let end = characterRange.location + characterRange.length
        guard end > lastSpokenIndex else { return }
        lastSpokenIndex = end
        let text = utterance.speechString
        let clampedEnd = min(end, text.count)
        guard let endIndex = text.index(text.startIndex, offsetBy: clampedEnd, limitedBy: text.endIndex) else { return }
        onSpokenPrefix?(String(text[..<endIndex]))
        onAudioLevel?(estimatedLevel(for: characterRange))
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        onFinish?()
        onAudioLevel?(0)
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        onFinish?()
        onAudioLevel?(0)
    }

    func setPreferredVoice(identifier: String?) {
        preferredVoiceIdentifier = identifier
    }

    func voiceDescription() -> String {
        let voice = resolveVoice()
        let name = voice?.name ?? "Default"
        let quality: String
        switch voice?.quality {
        case .premium:
            quality = "Premium"
        case .enhanced:
            quality = "Enhanced"
        case .default, .none:
            quality = "Standard"
        @unknown default:
            quality = "Standard"
        }
        return "Voice: \(name) (\(quality))"
    }

    static func availableVoiceOptions() -> [VoiceOption] {
        AVSpeechSynthesisVoice.speechVoices()
            .map(VoiceOption.init)
            .sorted { VoiceOption.sort(lhs: $0, rhs: $1) }
    }

    private func resolveVoice() -> AVSpeechSynthesisVoice? {
        if let identifier = preferredVoiceIdentifier,
           let voice = AVSpeechSynthesisVoice(identifier: identifier) {
            return voice
        }
        return Self.defaultVoice()
    }

    private static func defaultVoice() -> AVSpeechSynthesisVoice? {
        let preferredIdentifier = "com.apple.voice.enhanced.en-US.Evan"
        if let voice = AVSpeechSynthesisVoice(identifier: preferredIdentifier) {
            return voice
        }
        let preferredName = "Evan"
        let voices = AVSpeechSynthesisVoice.speechVoices()
        if let enhanced = voices.first(where: { $0.name == preferredName && $0.quality == .enhanced }) {
            return enhanced
        }
        if let standard = voices.first(where: { $0.name == preferredName }) {
            return standard
        }
        return AVSpeechSynthesisVoice(language: "en-US")
    }

    private func estimatedLevel(for range: NSRange) -> Double {
        let length = max(1, range.length)
        let scaled = 0.2 + Double(length) / 22.0
        return min(1, max(0, scaled))
    }
}
