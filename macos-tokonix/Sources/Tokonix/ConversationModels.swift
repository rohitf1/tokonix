import Foundation

enum ChatRole: String {
    case user
    case assistant
}

struct ChatMessage: Identifiable, Equatable {
    let id: String
    let role: ChatRole
    var text: String
    var isStreaming: Bool
}

struct ThreadSummary: Identifiable, Equatable {
    let id: String
    let preview: String
    let createdAt: Date
    let modelProvider: String
    let path: String
}

struct ThreadDetail: Equatable {
    let summary: ThreadSummary
    let messages: [ChatMessage]
    let model: String?
    let reasoningEffort: ReasoningEffort?

    init(
        summary: ThreadSummary,
        messages: [ChatMessage],
        model: String? = nil,
        reasoningEffort: ReasoningEffort? = nil
    ) {
        self.summary = summary
        self.messages = messages
        self.model = model
        self.reasoningEffort = reasoningEffort
    }
}

struct ThreadListPage: Equatable {
    let threads: [ThreadSummary]
    let nextCursor: String?
}

enum ReasoningEffort: String, CaseIterable, Equatable {
    case minimal
    case low
    case medium
    case high
    case xhigh

    var label: String {
        switch self {
        case .minimal:
            return "Minimal"
        case .low:
            return "Low"
        case .medium:
            return "Medium"
        case .high:
            return "High"
        case .xhigh:
            return "Extra High"
        }
    }
}

struct ReasoningEffortOption: Identifiable, Equatable {
    let effort: ReasoningEffort
    let description: String

    var id: String { effort.rawValue }
}

struct ModelOption: Identifiable, Equatable {
    let slug: String
    let displayName: String
    let description: String
    let supportedReasoningEfforts: [ReasoningEffortOption]
    let defaultReasoningEffort: ReasoningEffort
    let isDefault: Bool

    var id: String { slug }

    func supports(_ effort: ReasoningEffort) -> Bool {
        supportedReasoningEfforts.contains { $0.effort == effort }
    }
}

struct ModelListPage: Equatable {
    let models: [ModelOption]
    let nextCursor: String?
}

enum LoginState: Equatable {
    case ready
    case required
    case inProgress
    case failed(String)
}
