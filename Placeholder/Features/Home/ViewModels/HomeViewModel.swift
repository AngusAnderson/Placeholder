import Combine
import Foundation
import UIKit

@MainActor
final class HomeViewModel: ObservableObject {
    @Published private(set) var profileImage: UIImage?
    @Published private(set) var isLoadingProfileImage = false
    @Published var errorMessage: String?

    private let profilePictureService =
        ProfilePictureService()

    func loadProfileImage() async {
        isLoadingProfileImage = true
        errorMessage = nil

        defer {
            isLoadingProfileImage = false
        }

        do {
            guard let path = try await profilePictureService
                .fetchProfilePicturePath(),
                  !path.isEmpty
            else {
                profileImage = nil
                return
            }

            let imageURL = try await profilePictureService
                .createSignedProfilePictureURL(
                    path: path
                )

            let (data, _) = try await URLSession.shared
                .data(from: imageURL)

            guard let image = UIImage(data: data) else {
                throw ProfilePictureServiceError.invalidImage
            }

            profileImage = image

        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
