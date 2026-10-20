import Foundation
import Supabase

struct TeamService {
    func fetchDashboard() async throws -> TeamDashboard {
        let dashboard: TeamDashboard = try await supabase
            .rpc("get_team_dashboard")
            .execute()
            .value

        return dashboard
    }

    func perform(
        _ parameters: TeamOperationParameters
    ) async throws {
        try await supabase
            .rpc(
                "manage_team",
                params: parameters
            )
            .execute()
    }
}
