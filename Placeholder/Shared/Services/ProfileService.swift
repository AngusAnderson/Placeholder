import Foundation
import Supabase

enum ProfileServiceError: LocalizedError {
    case noAuthenticatedUser
    case invalidFirstName
    case invalidSurname
    case invalidUsername
    case usernameTaken
    case profileNotFound

    var errorDescription: String? {
        switch self {
        case .noAuthenticatedUser:
            return "No authenticated user found."

        case .invalidFirstName:
            return "Please enter your first name."

        case .invalidSurname:
            return "Please enter your surname."

        case .invalidUsername:
            return "Usernames must be 3–20 characters and contain only lowercase letters, numbers, and underscores."

        case .usernameTaken:
            return "That username is already taken."
            
        case .profileNotFound:
            return "This profile could not be found."
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
    
    // MARK: Username section
    
    func saveUsername(_ username: String) async throws {
        let cleanedUsername = username
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()

        guard isValidUsername(cleanedUsername) else {
            throw ProfileServiceError.invalidUsername
        }

        let user = try await currentUser()

        let update = UsernameUpdate(
            username: cleanedUsername
        )

        do {
            try await supabase
                .from("profiles")
                .update(update)
                .eq("id", value: user.id)
                .execute()
        } catch let error as PostgrestError {
            if error.code == "23505" {
                throw ProfileServiceError.usernameTaken
            }

            throw error
        }
    }

    func isUsernameAvailable(
        _ username: String,
        excludingUserID userID: UUID
    ) async throws -> Bool {
        struct UsernameRow: Decodable, Sendable {
            let id: UUID
        }

        let existingUsernames: [UsernameRow] = try await supabase
            .from("profiles")
            .select("id")
            .eq("username", value: username)
            .neq("id", value: userID)
            .execute()
            .value

        return existingUsernames.isEmpty
    }
    
    func searchUsers(query: String) async throws -> [UserSearchResult] {
        let cleanedQuery = query
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard cleanedQuery.count >= 2 else {
            return []
        }

        let results: [UserSearchResult] = try await supabase
            .rpc(
                "search_profiles",
                params: ["search_query": cleanedQuery]
            )
            .execute()
            .value

        return results
    }
    
    func fetchPublicProfile(
        id: UUID
    ) async throws -> PublicProfile {
        let profiles: [PublicProfile] = try await supabase
            .rpc(
                "get_public_profile",
                params: ["requested_profile_id": id.uuidString]
            )
            .execute()
            .value

        guard let profile = profiles.first else {
            throw ProfileServiceError.profileNotFound
        }

        return profile
    }

    private func isValidUsername(_ username: String) -> Bool {
        let allowedCharacters = CharacterSet(
            charactersIn: "abcdefghijklmnopqrstuvwxyz0123456789_"
        )

        return username.count >= 3
            && username.count <= 20
            && username.unicodeScalars.allSatisfy { allowedCharacters.contains($0) }
    }

    private func currentUser() async throws -> User {
        do {
            return try await supabase.auth.user()
        } catch {
            throw ProfileServiceError.noAuthenticatedUser
        }
    }
    
    // MARK: - Onboarding profile details

    func saveProfileDetails(
        firstName: String,
        surname: String,
        username: String
    ) async throws -> Profile {
        let cleanedFirstName = firstName.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        let cleanedSurname = surname.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        let cleanedUsername = username
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()

        guard !cleanedFirstName.isEmpty else {
            throw ProfileServiceError.invalidFirstName
        }

        guard !cleanedSurname.isEmpty else {
            throw ProfileServiceError.invalidSurname
        }

        guard isValidUsername(cleanedUsername) else {
            throw ProfileServiceError.invalidUsername
        }

        let user = try await currentUser()

        let update = ProfileDetailsUpdate(
            firstName: cleanedFirstName,
            surname: cleanedSurname,
            username: cleanedUsername
        )

        do {
            let updatedProfile: Profile = try await supabase
                .from("profiles")
                .update(update)
                .eq("id", value: user.id)
                .select()
                .single()
                .execute()
                .value

            return updatedProfile
        } catch let error as PostgrestError {
            if error.code == "23505" {
                throw ProfileServiceError.usernameTaken
            }

            throw error
        }
    }
}
