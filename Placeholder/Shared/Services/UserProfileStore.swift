import SwiftUI
import UIKit

@MainActor
@Observable
final class UserProfileStore {
    private let profileService = ProfileService()
    private let profilePictureService = ProfilePictureService()

    private(set) var profile: Profile?
    private(set) var profileImage: UIImage?

    private(set) var isLoadingProfile = false
    private(set) var isLoadingProfileImage = false
    
    private(set) var isCompletingOnboarding = false
    
    private(set) var isSavingName = false

    var errorMessage: String?

    var isOnboarded: Bool {
        profile?.onboardingCompleted ?? false
    }

    var firstName: String? {
        profile?.firstName
    }

    var surname: String? {
        profile?.surname
    }

    // Both names put together, yeah this is efficient like that.
    var displayName: String {
        let name = [profile?.firstName, profile?.surname]
            .compactMap { $0 }
            .joined(separator: " ")

        return name.isEmpty ? "Anonymous" : name
    }

    func loadProfileIfNeeded() async {
        guard profile == nil, !isLoadingProfile else {
            return
        }

        await loadProfile()
    }

    func loadProfile() async {
        isLoadingProfile = true
        errorMessage = nil

        defer {
            isLoadingProfile = false
        }

        do {
            profile = try await profileService.fetchCurrentProfile()
            await loadProfileImage()
        } catch {
            profile = nil
            profileImage = nil
            errorMessage = error.localizedDescription
        }
    }

    func loadProfileImage() async {
        guard let path = profile?.profilePicturePath,
              !path.isEmpty
        else {
            profileImage = nil
            return
        }

        isLoadingProfileImage = true

        defer {
            isLoadingProfileImage = false
        }

        do {
            let imageURL = try await profilePictureService
                .createSignedProfilePictureURL(path: path)

            let (data, _) = try await URLSession.shared
                .data(from: imageURL)

            guard let image = UIImage(data: data) else {
                throw ProfilePictureServiceError.invalidImage
            }

            profileImage = image
        } catch {
            profileImage = nil
            errorMessage = error.localizedDescription
        }
    }

    func saveName(
        firstName: String,
        surname: String
    ) async -> Bool {
        guard !isSavingName else {
            return false
        }

        isSavingName = true
        errorMessage = nil

        defer {
            isSavingName = false
        }

        do {
            try await profileService.saveName(
                firstName: firstName,
                surname: surname
            )
            
            profile = try await profileService.fetchCurrentProfile()

            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    func completeOnboarding() async -> Bool {
        guard !isCompletingOnboarding else {
            return false
        }

        isCompletingOnboarding = true
        errorMessage = nil

        defer {
            isCompletingOnboarding = false
        }

        do {
            try await profileService.completeOnboarding()

            let refreshedProfile = try await profileService
                .fetchCurrentProfile()

            guard refreshedProfile.onboardingCompleted else {
                errorMessage = "Onboarding could not be completed. Please try again."
                return false
            }

            profile = refreshedProfile

            await loadProfileImage()

            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    func clear() {
        profile = nil
        profileImage = nil
        errorMessage = nil
    }
}
