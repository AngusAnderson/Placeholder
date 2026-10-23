import Foundation

nonisolated struct RelayLeaderboard: Decodable, Sendable {
    let teamID: Int64
    let teamName: String
    let game: Game?
    let entries: [Entry]
    let attributedMetres: Double
    let attributionDifference: Double

    nonisolated struct Game: Identifiable, Decodable, Sendable {
        let id: UUID
        let status: String
        let startName: String
        let finishName: String
        let creditedMetres: Double
        let targetMetres: Double
        var progress: Double {
            guard targetMetres > 0 else { return 0 }
            return min(max(creditedMetres / targetMetres, 0), 1)
        }
    }
    nonisolated struct Entry: Identifiable, Decodable, Sendable {
        let userID: UUID
        let displayName: String
        let username: String?
        let profilePicturePath: String?
        let rank: Int
        let creditedMetres: Double
        let share: Double
        let isCurrentUser: Bool
        let isCurrentMember: Bool
        var id: UUID { userID }
        var initials: String {
            let value = displayName.split(separator: " ").prefix(2)
                .compactMap(\.first).map(String.init).joined()
            return value.isEmpty ? "?" : value.uppercased()
        }
    }
}
