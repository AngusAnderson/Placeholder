import Foundation
import MapKit

nonisolated enum GameStatus: String, Codable, Sendable {
    case active, completed, cancelled
}

nonisolated struct RelayCoordinate: Codable, Sendable {
    let latitude: Double
    let longitude: Double
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

nonisolated struct RelayRouteDefinition: Decodable, Identifiable, Sendable {
    let id: UUID
    let name: String
    let targetMetres: Double
}

nonisolated struct RelayContribution: Decodable, Identifiable, Sendable {
    let userID: UUID
    let displayName: String
    let metres: Double
    var id: UUID { userID }
}

nonisolated struct RelayGame: Decodable, Identifiable, Sendable {
    let id: UUID
    let teamID: Int64
    let status: GameStatus
    let startName: String
    let finishName: String
    let targetMetres: Double
    let creditedMetres: Double
    let coordinates: [RelayCoordinate]
    let checkpoints: [Int]
    let contributions: [RelayContribution]
    var progress: Double { targetMetres > 0 ? min(max(creditedMetres / targetMetres, 0), 1) : 0 }
}

nonisolated struct RelayReceipt: Decodable, Sendable {
    let gameStatus: GameStatus
    let creditedMetres: Double
}

nonisolated struct RelayPendingActivity: Codable, Sendable {
    let id: UUID
    let userID: UUID
    let gameID: UUID
    let startedAt: Date
    let endedAt: Date
    let metres: Double
    let steps: Int
}

nonisolated struct RelayRecordingDraft: Codable, Sendable {
    let userID: UUID
    let gameID: UUID
    let teamID: Int64
    let startedAt: Date
    var cursor: Date
    var stopAt: Date?
}

nonisolated struct RelayRecordingArchive: Codable, Sendable {
    var draft: RelayRecordingDraft?
    var pending: RelayPendingActivity?
}
