import Foundation
import Supabase

struct RelayService {
    func routes() async throws -> [RelayRouteDefinition] {
        try await supabase.rpc("get_relay_routes").execute().value
    }

    func game(teamID: Int64) async throws -> RelayGame? {
        try await supabase.rpc("get_team_relay", params: ["requested_team_id": teamID])
            .execute().value
    }

    func start(teamID: Int64, routeID: UUID) async throws {
        let _: UUID = try await supabase.rpc("start_relay_game", params: StartParameters(
            requested_team_id: teamID, requested_route_id: routeID
        )).execute().value
    }

    func submit(_ activity: RelayPendingActivity) async throws -> RelayReceipt {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return try await supabase.rpc("submit_relay_activity", params: SubmissionParameters(
            expected_user_id: activity.userID,
            activity_id: activity.id,
            game_session_id: activity.gameID,
            started_at: formatter.string(from: activity.startedAt),
            ended_at: formatter.string(from: activity.endedAt),
            distance_metres: activity.metres,
            steps: activity.steps
        )).execute().value
    }
}

nonisolated private struct StartParameters: Encodable, Sendable {
    let requested_team_id: Int64
    let requested_route_id: UUID
}

nonisolated private struct SubmissionParameters: Encodable, Sendable {
    let expected_user_id: UUID
    let activity_id: UUID
    let game_session_id: UUID
    let started_at: String
    let ended_at: String
    let distance_metres: Double
    let steps: Int
}
