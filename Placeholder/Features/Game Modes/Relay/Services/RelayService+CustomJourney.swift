import Foundation
import Supabase

extension RelayService {
    func startCustom(teamID: Int64, start: RelayEndpoint, finish: RelayEndpoint) async throws -> UUID {
        try await supabase.rpc("start_custom_relay", params: CustomRelayParameters(
            requested_team_id: teamID,
            start_name: String(start.name.prefix(80)),
            start_latitude: start.latitude,
            start_longitude: start.longitude,
            finish_name: String(finish.name.prefix(80)),
            finish_latitude: finish.latitude,
            finish_longitude: finish.longitude
        )).execute().value
    }
    func cancelGame(teamID: Int64) async throws {
        try await supabase.rpc("cancel_team_game", params: ["requested_team_id": teamID]).execute()
    }
}

nonisolated private struct CustomRelayParameters: Encodable, Sendable {
    let requested_team_id: Int64
    let start_name: String
    let start_latitude: Double
    let start_longitude: Double
    let finish_name: String
    let finish_latitude: Double
    let finish_longitude: Double
}
