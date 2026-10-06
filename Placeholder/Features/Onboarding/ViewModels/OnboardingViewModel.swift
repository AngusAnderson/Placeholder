import Combine
import Foundation
import UIKit

@MainActor
final class OnboardingViewModel: ObservableObject {
    @Published var firstName = ""
    @Published var surname = ""

    @Published private(set) var profilePicturePath: String?

    @Published private(set) var isSaving = false
    @Published private(set) var isUploadingImage = false

    @Published var errorMessage: String?

    private let profileService = ProfileService()
    private let profilePictureService = ProfilePictureService()

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

    func uploadProfilePicture(
        image: UIImage?
    ) async -> Bool {
        guard let image else {
            return true
        }

        guard let imageData = image.jpegData(
            compressionQuality: 0.8
        ) else {
            errorMessage =
                ProfilePictureServiceError
                    .imageConversionFailed
                    .localizedDescription

            return false
        }

        isUploadingImage = true
        errorMessage = nil

        defer {
            isUploadingImage = false
        }

        do {
            let path = try await profilePictureService
                .uploadProfilePicture(
                    imageData: imageData,
                    fileExtension: "jpg"
                )

            profilePicturePath = path
            return true

        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }
}
