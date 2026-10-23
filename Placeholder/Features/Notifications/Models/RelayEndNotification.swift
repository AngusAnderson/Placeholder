import Foundation

nonisolated struct RelayEndNotification:
    Identifiable,
    Decodable,
    Sendable
{
    let id: UUID
    let userID: UUID
    let gameSessionID: UUID
    let teamID: Int64

    let kind: String
    let title: String
    let message: String

    let result: ResultSnapshot
    let createdAt: Date

    var readAt: Date?
    var celebrationSeenAt: Date?

    var isCompleted: Bool {
        kind == "relay_completed"
    }

    var localAcknowledgementKey: String {
        "relay-end.ack.\(userID.uuidString).\(id.uuidString)"
    }

    enum CodingKeys: String, CodingKey {
        case id
        case kind
        case title
        case message
        case result

        case userID = "user_id"
        case gameSessionID = "game_session_id"
        case teamID = "team_id"

        case createdAt = "created_at"
        case readAt = "read_at"
        case celebrationSeenAt = "celebration_seen_at"
    }

    nonisolated struct ResultSnapshot: Decodable, Sendable {
        let teamName: String?
        let startName: String?
        let finishName: String?
        let targetMetres: Double?
        let status: String?

        enum CodingKeys: String, CodingKey {
            case status

            case teamName = "team_name"
            case startName = "start_name"
            case finishName = "finish_name"
            case targetMetres = "target_metres"
        }
    }
}
