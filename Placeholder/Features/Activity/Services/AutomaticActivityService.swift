import Foundation
import Supabase

struct AutomaticActivityService {
    func preference() async throws -> HealthSharingPreference {
        try await supabase.rpc("get_health_sharing").execute().value
    }
    func setEnabled(_ enabled: Bool, userID: UUID) async throws -> HealthSharingPreference {
        try await supabase.rpc("set_health_sharing", params: SharingParameters(
            expected_user_id: userID, requested_enabled: enabled
        )).execute().value
    }
//    func upload(_ buckets: [HealthActivityBucket], userID: UUID) async throws {
//        try await supabase.rpc("sync_health_buckets", params: BucketParameters(
//            expected_user_id: userID, requested_buckets: buckets
//        )).execute()
//    }
    
    func upload(
        _ buckets: [HealthActivityBucket],
        userID: UUID
    ) async throws {
        #if DEBUG
        print("[Health Sync] Uploading \(buckets.count) buckets")
        #endif

        do {
            _ = try await supabase.rpc(
                "sync_health_buckets",
                params: BucketParameters(
                    expected_user_id: userID,
                    requested_buckets: buckets
                )
            )
            .execute()

            #if DEBUG
            print("[Health Sync] Upload RPC succeeded")
            #endif
        } catch {
            #if DEBUG
            print("[Health Sync] Upload RPC failed: \(error)")
            #endif

            throw error
        }
    }
}
nonisolated private struct SharingParameters: Encodable, Sendable {
    let expected_user_id: UUID
    let requested_enabled: Bool
}
nonisolated private struct BucketParameters: Encodable, Sendable {
    let expected_user_id: UUID
    let requested_buckets: [HealthActivityBucket]
}
