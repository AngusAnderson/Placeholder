import Foundation
import Supabase

struct RelayLeaderboardService {
    func fetch(teamID: Int64) async throws -> RelayLeaderboard {
        try await supabase.rpc(
            "get_team_relay_leaderboard",
            params: ["requested_team_id": teamID]
        ).execute().value
    }
}
