import Foundation
import Observation

@MainActor
@Observable
final class RelayLeaderboardViewModel {
    private let service = RelayLeaderboardService()
    private var requestID = UUID()
    private(set) var selectedTeamID: Int64?
    private(set) var leaderboard: RelayLeaderboard?
    private(set) var isLoading = false
    private(set) var lastUpdated: Date?
    var errorMessage: String?

    func watch(teamID: Int64?) async {
        requestID = UUID()
        selectedTeamID = teamID
        leaderboard = nil
        errorMessage = nil
        lastUpdated = nil
        isLoading = false
        guard let teamID else { return }
        while !Task.isCancelled && selectedTeamID == teamID {
            await refresh(teamID: teamID)
            do { try await Task.sleep(for: .seconds(15)) }
            catch { return }
        }
    }
    func refresh(teamID: Int64) async {
        guard selectedTeamID == teamID else { return }
        let token = UUID()
        requestID = token
        isLoading = true
        defer {
            if requestID == token { isLoading = false }
        }
        do {
            let result = try await service.fetch(teamID: teamID)
            try Task.checkCancellation()
            guard selectedTeamID == teamID, requestID == token else { return }
            leaderboard = result
            lastUpdated = Date()
            errorMessage = nil
        } catch {
            guard !Task.isCancelled, selectedTeamID == teamID, requestID == token else { return }
            // Avoid retaining another team's/account's stale data after access changes.
            leaderboard = nil
            errorMessage = error.localizedDescription
        }
    }
}
