import Foundation
import Supabase

enum TeamServiceError: LocalizedError {
    case missingTeamID

    var errorDescription: String? {
        switch self {
        case .missingTeamID:
            return "No team was selected."
        }
    }
}

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
        if parameters.operation == "rename"
            || parameters.operation == "delete" {

            guard let teamID = parameters.requested_team_id else {
                throw TeamServiceError.missingTeamID
            }

            let ownerParameters = OwnerTeamOperationParameters(
                requested_team_id: teamID,
                requested_action: parameters.operation,
                requested_name: parameters.requested_name
            )

            try await supabase
                .rpc(
                    "manage_owned_team",
                    params: ownerParameters
                )
                .execute()

        } else {
            try await supabase
                .rpc(
                    "manage_team",
                    params: parameters
                )
                .execute()
        }
    }
}
