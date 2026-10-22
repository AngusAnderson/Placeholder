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
    
    func fetchDetails(
        teamID: Int64
    ) async throws -> TeamDetails {
        let details: TeamDetails = try await supabase
            .rpc(
                "get_team_details",
                params: [
                    "requested_team_id": teamID
                ]
            )
            .execute()
            .value
        
        return details
    }
    
    func removeMember(
        userID: UUID,
        from teamID: Int64
    ) async throws {
        let parameters = TeamMembershipParameters(
            requested_team_id: teamID,
            requested_action: "remove",
            requested_member_id: userID
        )

        try await supabase
            .rpc(
                "change_team_membership",
                params: parameters
            )
            .execute()
    }

    func leaveTeam(
        teamID: Int64
    ) async throws {
        let parameters = TeamMembershipParameters(
            requested_team_id: teamID,
            requested_action: "leave",
            requested_member_id: nil
        )

        try await supabase
            .rpc(
                "change_team_membership",
                params: parameters
            )
            .execute()
    }
    
    func fetchInvitableFriends(
        teamID: Int64
    ) async throws -> [TeamFriend] {
        let friends: [TeamFriend] = try await supabase
            .rpc(
                "get_invitable_team_friends",
                params: [
                    "requested_team_id": teamID
                ]
            )
            .execute()
            .value

        return friends
    }
}
