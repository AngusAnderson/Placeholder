import Foundation
import Observation

@MainActor
@Observable
final class RelayViewModel {
    private let service = RelayService()
    private(set) var selectedTeamID: Int64?
    private(set) var game: RelayGame?
    private(set) var routes: [RelayRouteDefinition] = []
    private(set) var isStarting = false
    private(set) var isLoading = false
    var errorMessage: String?
    
    private var refreshRequestID = UUID()

    func watch(teamID: Int64?) async {
        selectedTeamID = teamID
        game = nil
        routes = []
        errorMessage = nil
        guard let teamID else { return }
        while !Task.isCancelled {
            await refresh(teamID: teamID)
            do { try await Task.sleep(for: .seconds(10)) }
            catch { return }
        }
    }

    func refresh(teamID: Int64) async {
        guard selectedTeamID == teamID else {
            return
        }

        let requestID = UUID()
        refreshRequestID = requestID

        isLoading = true

        defer {
            if selectedTeamID == teamID,
               refreshRequestID == requestID {
                isLoading = false
            }
        }

        do {
            let fetchedGame = try await service.game(
                teamID: teamID
            )

            try Task.checkCancellation()

            guard selectedTeamID == teamID,
                  refreshRequestID == requestID else {
                return
            }

            game = fetchedGame
            errorMessage = nil
        } catch {
            guard !Task.isCancelled,
                  selectedTeamID == teamID,
                  refreshRequestID == requestID else {
                return
            }

            // Preserve the last successfully loaded game.
            errorMessage = error.localizedDescription
            return
        }

        // Route presets are optional for refreshing map progress.
        do {
            let fetchedRoutes = try await service.routes()

            try Task.checkCancellation()

            guard selectedTeamID == teamID,
                  refreshRequestID == requestID else {
                return
            }

            routes = fetchedRoutes
        } catch {
            #if DEBUG
            if !Task.isCancelled {
                print(
                    "[Relay] Route catalogue refresh failed:",
                    error
                )
            }
            #endif
        }
    }

    func start(routeID: UUID, teamID: Int64) async {
        guard !isStarting else { return }
        isStarting = true
        defer { isStarting = false }
        do {
            try await service.start(teamID: teamID, routeID: routeID)
        } catch {
            if selectedTeamID == teamID { errorMessage = error.localizedDescription }
            return
        }
        await refresh(teamID: teamID)
    }
}
