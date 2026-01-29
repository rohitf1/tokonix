import Foundation

struct OverlayLogEntry: Identifiable, Equatable {
    let id: UUID
    let date: Date
    let message: String
}
