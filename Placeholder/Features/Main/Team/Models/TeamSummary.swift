import Foundation

nonisolated struct TeamSummary: Decodable, Identifiable, Sendable {
    let id: Int64
    let name: String
    let isOwner: Bool
    let memberCount: Int
}

nonisolated struct TeamFriend: Decodable, Identifiable, Sendable {
    let id: UUID
    let firstName: String?
    let surname: String?
    let username: String?

    var displayName: String {
        let name = [firstName, surname]
            .compactMap { $0 }
            .joined(separator: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        return name.isEmpty ? (username ?? "User") : name
    }
}

nonisolated struct TeamInvitation: Decodable, Identifiable, Sendable {
    let id: UUID
    let teamID: Int64
    let teamName: String
}

nonisolated struct TeamDashboard: Decodable, Sendable {
    let teams: [TeamSummary]
    let friends: [TeamFriend]
    let invitations: [TeamInvitation]
}

nonisolated struct TeamOperationParameters: Encodable, Sendable {
    let operation: String

    var requested_team_id: Int64? = nil
    var requested_friend_id: UUID? = nil
    var requested_name: String? = nil
    var requested_invitation_id: UUID? = nil
}

nonisolated struct OwnerTeamOperationParameters: Encodable, Sendable {
    let requested_team_id: Int64
    let requested_action: String
    let requested_name: String?
}
