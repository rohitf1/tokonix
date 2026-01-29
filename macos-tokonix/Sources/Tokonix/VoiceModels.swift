import AVFoundation
import Foundation

struct VoiceOption: Identifiable, Equatable {
    let identifier: String
    let name: String
    let language: String
    let quality: AVSpeechSynthesisVoiceQuality

    var id: String { identifier }

    var qualityLabel: String {
        switch quality {
        case .premium:
            return "Premium"
        case .enhanced:
            return "Enhanced"
        case .default:
            return "Standard"
        @unknown default:
            return "Unknown"
        }
    }

    var detailLabel: String {
        let languageLabel = language.isEmpty ? "Unknown locale" : language
        return "\(languageLabel) • \(qualityLabel)"
    }

    init(voice: AVSpeechSynthesisVoice) {
        identifier = voice.identifier
        name = voice.name
        language = voice.language
        quality = voice.quality
    }

    static func sort(lhs: VoiceOption, rhs: VoiceOption) -> Bool {
        if lhs.language != rhs.language {
            return lhs.language < rhs.language
        }
        if lhs.name != rhs.name {
            return lhs.name < rhs.name
        }
        return qualityRank(lhs.quality) < qualityRank(rhs.quality)
    }

    private static func qualityRank(_ quality: AVSpeechSynthesisVoiceQuality) -> Int {
        switch quality {
        case .premium:
            return 0
        case .enhanced:
            return 1
        case .default:
            return 2
        @unknown default:
            return 3
        }
    }
}
