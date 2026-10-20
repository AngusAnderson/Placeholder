import Foundation

struct IncomingFriendRequest: Decodable, Identifiable, Sendable {
    let id: UUID
    let requesterID: UUID
    let firstName: String?
    let surname: String?
    let username: String?
    let createdAt: Date

    var displayName: String {
        let name = [firstName, surname]
            .compactMap { $0 }
            .joined(separator: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        return name.isEmpty ? (username ?? "User") : name
    }

    enum CodingKeys: String, CodingKey {
        case id
        case requesterID = "requester_id"
        case firstName = "first_name"
        case surname
        case username
        case createdAt = "created_at"
    }
}
