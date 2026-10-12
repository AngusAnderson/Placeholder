import Foundation
import Supabase

enum ProfileServiceError: LocalizedError {
    case noAuthenticatedUser
    case invalidFirstName
    case invalidSurname

    var errorDescription: String? {
        switch self {
        case .noAuthenticatedUser:
            return "No authenticated user found."

        case .invalidFirstName:
            return "Please enter your first name."

        case .invalidSurname:
            return "Please enter your surname."
        }
    }
}

struct ProfileService {
    func fetchCurrentProfile() async throws -> Profile {
        let user = try await currentUser()

        let profile: Profile = try await supabase
            .from("profiles")
            .select()
            .eq("id", value: user.id)
            .single()
            .execute()
            .value

        return profile
    }

    func saveName(
        firstName: String,
        surname: String
    ) async throws {
        let cleanedFirstName = firstName.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        let cleanedSurname = surname.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        guard !cleanedFirstName.isEmpty else {
            throw ProfileServiceError.invalidFirstName
        }

        guard !cleanedSurname.isEmpty else {
            throw ProfileServiceError.invalidSurname
        }

        let user = try await currentUser()

        let update = NameUpdate(
            firstName: cleanedFirstName,
            surname: cleanedSurname
        )

        try await supabase
            .from("profiles")
            .update(update)
            .eq("id", value: user.id)
            .execute()
    }

    func completeOnboarding() async throws {
        let user = try await currentUser()

        let update = OnboardingCompletionUpdate(
            onboardingCompleted: true
        )

        try await supabase
            .from("profiles")
            .update(update)
            .eq("id", value: user.id)
            .execute()
    }

    private func currentUser() async throws -> User {
        do {
            return try await supabase.auth.user()
        } catch {
            throw ProfileServiceError.noAuthenticatedUser
        }
    }
}
