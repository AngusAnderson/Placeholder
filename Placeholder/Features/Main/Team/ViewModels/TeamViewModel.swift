import Foundation
import Observation

@MainActor
@Observable
final class TeamViewModel {
    private let service = TeamService()

    private(set) var teams: [TeamSummary] = []
    private(set) var friends: [TeamFriend] = []
    private(set) var invitations: [TeamInvitation] = []

    private(set) var hasLoaded = false
    private(set) var isLoading = false
    private(set) var isPerformingAction = false

    var errorMessage: String?

    var isBusy: Bool {
        isLoading || isPerformingAction
    }

    func load() async {
        guard !isBusy else {
            return
        }

        isLoading = true
        errorMessage = nil

        defer {
            isLoading = false
        }

        do {
            let dashboard = try await service.fetchDashboard()
            try Task.checkCancellation()

            apply(dashboard)
        } catch {
            guard !Task.isCancelled else {
                return
            }

            errorMessage = error.localizedDescription
        }
    }

    func perform(
        _ parameters: TeamOperationParameters
    ) async -> Bool {
        guard !isBusy else {
            return false
        }

        isPerformingAction = true
        errorMessage = nil

        defer {
            isPerformingAction = false
        }

        do {
            try await service.perform(parameters)
        } catch {
            errorMessage = error.localizedDescription
            return false
        }

        // The write succeeded. A refresh failure must not imply it failed.
        do {
            apply(try await service.fetchDashboard())
        } catch {
            errorMessage =
                "The change was saved, but the list could not refresh. "
                + "Pull down to try again."
        }

        return true
    }

    private func apply(_ dashboard: TeamDashboard) {
        teams = dashboard.teams
        friends = dashboard.friends
        invitations = dashboard.invitations
        hasLoaded = true
    }
}
