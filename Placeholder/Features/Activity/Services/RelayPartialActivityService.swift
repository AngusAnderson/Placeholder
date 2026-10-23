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
    func synchronize(
        reader: HealthActivityReader,
        userID: UUID
    ) async throws {
        let windows: [RelayPartialWindow] = try await supabase.rpc(
            "get_relay_partial_windows",
            params: [
                "expected_user_id": userID.uuidString
            ]
        )
        .execute()
        .value

        #if DEBUG
        print(
            "[Relay Partial] Windows returned:",
            windows.count
        )
        #endif

        var failures: [String] = []

        for window in windows {
            try Task.checkCancellation()

            let end = min(
                window.endEpoch,
                window.measuredUntilEpoch
            )

            guard end > window.startEpoch else {
                continue
            }

            let elapsedSeconds = end - window.startEpoch

            // Diagnostic only. The server remains authoritative.
            let approximateLimit = min(
                100_000.0,
                elapsedSeconds * 5 + 100
            )

            var measuredMetres: Double?

            do {
                let metres = try await reader.relayPartialMetres(
                    start: Date(
                        timeIntervalSince1970: window.startEpoch
                    ),
                    end: Date(
                        timeIntervalSince1970: end
                    )
                )

                measuredMetres = metres

                guard metres.isFinite, metres >= 0 else {
                    throw RelayPartialActivityError.invalidDistance
                }

                #if DEBUG
                print(
                    "[Relay Partial]",
                    "Game:", window.gameSessionID,
                    "Metres:", metres,
                    "Elapsed seconds:", elapsedSeconds,
                    "Approximate limit:", approximateLimit
                )
                #endif

                guard metres > 0 else {
                    continue
                }

                try Task.checkCancellation()

                _ = try await supabase.rpc(
                    "sync_relay_partial_distance",
                    params: RelayPartialUpload(
                        expected_user_id: userID,
                        requested_game_id: window.gameSessionID,
                        requested_start_epoch: window.startEpoch,
                        requested_measured_until_epoch: end,
                        requested_metres: metres
                    )
                )
                .execute()
            } catch {
                if Task.isCancelled {
                    throw CancellationError()
                }

                let distanceText = measuredMetres.map {
                    String(format: "%.1f m", $0)
                } ?? "unavailable"

                let details = """
                Game \(window.gameSessionID): \
                distance \(distanceText), \
                interval \(String(format: "%.1f", elapsedSeconds)) seconds, \
                approximate limit \(String(format: "%.1f", approximateLimit)) m. \
                \(error.localizedDescription)
                """

                failures.append(details)

                #if DEBUG
                print("[Relay Partial] Failed:", details)
                #endif

                // Continue with the next game's window.
            }
        }

        if !failures.isEmpty {
            throw RelayPartialActivityError.syncFailures(failures)
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
    case syncFailures([String])

    var errorDescription: String? {
        switch self {
        case .invalidDistance:
            return "Health returned an invalid partial distance."

        case .syncFailures(let failures):
            return failures.joined(separator: "\n")
        }
    }
}
