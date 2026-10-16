import Foundation
import Observation

@MainActor
@Observable
final class FriendshipViewModel {
    private let service: FriendshipService

    private(set) var state: FriendshipState?
    private(set) var isLoading = false
    private(set) var isPerformingAction = false

    var errorMessage: String?

    init(service: FriendshipService) {
        self.service = service
    }

    // MARK: - Load relationship

    func load(with userID: UUID) async {
        guard !isLoading, !isPerformingAction else {
            return
        }

        isLoading = true
        errorMessage = nil

        defer {
            isLoading = false
        }

        do {
            state = try await service.fetchState(with: userID)
        } catch {
            guard !Task.isCancelled else {
                return
            }

            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Change relationship

    func perform(
        _ action: FriendshipAction,
        with userID: UUID
    ) async {
        guard !isLoading, !isPerformingAction else {
            return
        }

        isPerformingAction = true
        errorMessage = nil

        defer {
            isPerformingAction = false
        }

        do {
            try await service.perform(
                action,
                with: userID
            )

            state = try await service.fetchState(
                with: userID
            )
        } catch {
            guard !Task.isCancelled else {
                return
            }

            if let refreshedState = try? await service.fetchState(
                with: userID
            ) {
                state = refreshedState
            }

            errorMessage = error.localizedDescription
        }
    }
}
