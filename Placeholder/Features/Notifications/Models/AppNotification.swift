import Foundation

struct AppNotification: Identifiable {
    let id: UUID
    let title: String
    let message: String
    let createdAt: Date
    var isRead: Bool

    let systemImage: String
}
