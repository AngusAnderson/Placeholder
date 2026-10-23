import Foundation
import Supabase

nonisolated struct RelayPartialWindow: Decodable, Sendable {
    let gameSessionID: UUID
    let startEpoch: Double
    let endEpoch: Double
    let measuredUntilEpoch: Double
}

@MainActor
struct RelayPartialActivityService {
    func synchronize(reader: HealthActivityReader, userID: UUID) async throws {
        let windows: [RelayPartialWindow] = try await supabase.rpc(
            "get_relay_partial_windows",
            params: ["expected_user_id": userID.uuidString]
        ).execute().value

        for window in windows {
            try Task.checkCancellation()
            let end = min(window.endEpoch, window.measuredUntilEpoch)
            guard end > window.startEpoch else { continue }
            let metres = try await reader.relayPartialMetres(
                start: Date(timeIntervalSince1970: window.startEpoch),
                end: Date(timeIntervalSince1970: end)
            )
            guard metres.isFinite, metres >= 0 else {
                throw RelayPartialActivityError.invalidDistance
            }
            guard metres > 0 else { continue }
            _ = try await supabase.rpc(
                "sync_relay_partial_distance",
                params: RelayPartialUpload(
                    expected_user_id: userID,
                    requested_game_id: window.gameSessionID,
                    requested_start_epoch: window.startEpoch,
                    requested_measured_until_epoch: end,
                    requested_metres: metres
                )
            ).execute()
        }
    }
}

nonisolated private struct RelayPartialUpload: Encodable, Sendable {
    let expected_user_id: UUID
    let requested_game_id: UUID
    let requested_start_epoch: Double
    let requested_measured_until_epoch: Double
    let requested_metres: Double
}

nonisolated enum RelayPartialActivityError: LocalizedError {
    case invalidDistance
    var errorDescription: String? { "Health returned an invalid partial distance." }
}
