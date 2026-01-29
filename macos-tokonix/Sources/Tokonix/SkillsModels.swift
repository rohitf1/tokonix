import Foundation

enum SkillScope: String, CaseIterable, Equatable {
    case user
    case repo
    case system
    case admin

    var label: String {
        switch self {
        case .user:
            return "Profile (TOKONIX_HOME)"
        case .repo:
            return "Project (.codex)"
        case .system:
            return "System"
        case .admin:
            return "Admin"
        }
    }

    var pillLabel: String {
        switch self {
        case .user:
            return "User"
        case .repo:
            return "Repo"
        case .system:
            return "System"
        case .admin:
            return "Admin"
        }
    }

    var isEditable: Bool {
        switch self {
        case .user, .repo:
            return true
        case .system, .admin:
            return false
        }
    }
}

struct SkillInterface: Equatable {
    let displayName: String?
    let shortDescription: String?
    let iconSmall: String?
    let iconLarge: String?
    let brandColor: String?
    let defaultPrompt: String?
}

struct SkillMetadata: Identifiable, Equatable {
    let name: String
    let description: String
    let shortDescription: String?
    let interface: SkillInterface?
    let path: String
    let scope: SkillScope
    var enabled: Bool

    var id: String { path }

    var displayName: String {
        interface?.displayName ?? name
    }

    var summary: String {
        if let short = interface?.shortDescription, !short.isEmpty {
            return short
        }
        if let short = shortDescription, !short.isEmpty {
            return short
        }
        return description
    }
}

struct SkillErrorInfo: Identifiable, Equatable {
    let path: String
    let message: String

    var id: String {
        "\(path)|\(message)"
    }
}

struct SkillsListEntry: Equatable {
    let cwd: String
    let skills: [SkillMetadata]
    let errors: [SkillErrorInfo]
}
