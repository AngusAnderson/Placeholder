import AuthenticationServices
import Combine
import Foundation
import Supabase

nonisolated struct Profile: Decodable, Sendable {
    let onboardingCompleted: Bool

    enum CodingKeys: String, CodingKey {
        case onboardingCompleted = "onboarding_completed"
    }
}

@MainActor
final class AuthViewModel: NSObject, ObservableObject {
    @Published private(set) var session: Session?
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?

    @Published private(set) var onboardingCompleted: Bool?

    private var currentNonce: String?

    func prepareAppleRequest(
        _ request: ASAuthorizationAppleIDRequest
    ) {
        let nonce = AppleSignInHelpers.randomNonce()

        currentNonce = nonce
        request.requestedScopes = [.fullName, .email]
        request.nonce = AppleSignInHelpers.sha256(nonce)
    }

    func signInWithApple(
        credential: ASAuthorizationAppleIDCredential
    ) async {
        guard let nonce = currentNonce else {
            errorMessage = "Missing Apple sign-in nonce."
            return
        }

        guard let identityTokenData = credential.identityToken,
              let identityToken = String(
                data: identityTokenData,
                encoding: .utf8
              )
        else {
            errorMessage = "Unable to obtain Apple's identity token."
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            let newSession = try await supabase.auth.signInWithIdToken(
                credentials: OpenIDConnectCredentials(
                    provider: .apple,
                    idToken: identityToken,
                    nonce: nonce
                )
            )

            self.session = newSession
            currentNonce = nil

            try await fetchProfile()

        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func restoreSession() async {
        isLoading = true
        errorMessage = nil

        do {
            let existingSession = try await supabase.auth.session

            session = existingSession

            try await fetchProfile()

        } catch {
            session = nil
            onboardingCompleted = nil
        }

        isLoading = false
    }

    private func fetchProfile() async throws {
        guard let userId = session?.user.id else {
            throw AuthError.noAuthenticatedUser
        }

        let profile: Profile = try await supabase
            .from("profiles")
            .select("onboarding_completed")
            .eq("id", value: userId)
            .single()
            .execute()
            .value

        onboardingCompleted = profile.onboardingCompleted
    }

    func completeOnboarding() async {
        guard let userId = session?.user.id else {
            errorMessage = "No authenticated user found."
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            try await supabase
                .from("profiles")
                .update([
                    "onboarding_completed": true
                ])
                .eq("id", value: userId)
                .execute()

            onboardingCompleted = true

        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func signOut() async {
        do {
            try await supabase.auth.signOut()

            session = nil
            onboardingCompleted = nil
            errorMessage = nil

        } catch {
            errorMessage = error.localizedDescription
        }
    }

    enum AuthError: LocalizedError {
        case noAuthenticatedUser

        var errorDescription: String? {
            switch self {
            case .noAuthenticatedUser:
                return "No authenticated user found."
            }
        }
    }
}
