import Foundation
import Supabase

struct FriendshipService {
    let client: SupabaseClient
    
    func fetchState(
        with targetUserId: UUID
    ) async throws -> FriendshipState {
        let state: FriendshipState = try await client
            .rpc(
                "get_friendship_state",
                params: ["target_user_id": targetUserId.uuidString]
            )
            .execute()
            .value
        
        return state
    }
    
    func perform(
        _ action: FriendshipAction,
        with targetUserID: UUID
    ) async throws {
        try await client
            .rpc(
                "change_friendship",
                params: [
                    "target_user_id": targetUserID.uuidString,
                    "requested_action": action.rawValue
                ]
            )
            .execute()
    }
    
    func fetchIncomingRequests() async throws -> [IncomingFriendRequest] {
        let requests: [IncomingFriendRequest] = try await client
            .rpc("get_incoming_friend_requests")
            .execute()
            .value

        return requests
    }
}
