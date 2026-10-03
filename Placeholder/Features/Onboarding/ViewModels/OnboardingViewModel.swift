import Combine
import Foundation

@MainActor
final class OnboardingViewModel: ObservableObject {
    @Published var firstName = ""
    @Published var surname = ""

    @Published private(set) var isSaving = false
    @Published var errorMessage: String?

    private let profileService = ProfileService()

    var canContinueFromNameScreen: Bool {
        !firstName.trimmingCharacters(
            in: .whitespacesAndNewlines
        ).isEmpty &&
        !surname.trimmingCharacters(
            in: .whitespacesAndNewlines
        ).isEmpty
    }

    func saveName() async -> Bool {
        guard canContinueFromNameScreen else {
            errorMessage = "Please enter your first name and surname."
            return false
        }

        isSaving = true
        errorMessage = nil

        defer {
            isSaving = false
        }

        do {
            try await profileService.saveName(
                firstName: firstName,
                surname: surname
            )

            return true

        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }
}
