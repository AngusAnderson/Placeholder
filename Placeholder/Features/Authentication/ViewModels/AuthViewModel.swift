import AuthenticationServices
import Combine
import Foundation
import Supabase

@MainActor
final class AuthViewModel: NSObject, ObservableObject {
    @Published private(set) var session: Session?
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?

    @Published private(set) var onboardingCompleted: Bool?

    private var currentNonce: String?
    private let profileService = ProfileService()

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

        defer {
            isLoading = false
        }

        do {
            let newSession = try await supabase.auth.signInWithIdToken(
                credentials: OpenIDConnectCredentials(
                    provider: .apple,
                    idToken: identityToken,
                    nonce: nonce
                )
            )

            session = newSession
            currentNonce = nil

            try await fetchProfile()

        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func restoreSession() async {
        isLoading = true
        errorMessage = nil

        defer {
            isLoading = false
        }

        do {
            let existingSession = try await supabase.auth.session

            session = existingSession

            try await fetchProfile()

        } catch {
            session = nil
            onboardingCompleted = nil
        }
    }

    func completeOnboarding() async {
        isLoading = true
        errorMessage = nil

        defer {
            isLoading = false
        }

        do {
            try await profileService.completeOnboarding()
            onboardingCompleted = true

        } catch {
            errorMessage = error.localizedDescription
        }
    }

    @discardableResult
    func signOut() async -> Bool {
        errorMessage = nil

        do {
            try await supabase.auth.signOut(scope: .local)

            session = nil

            return true
        } catch {
            errorMessage = error.localizedDescription

            return false
        }
    }

    private func fetchProfile() async throws {
        let profile = try await profileService.fetchCurrentProfile()
        onboardingCompleted = profile.onboardingCompleted
    }
    
    // MARK: Debug test account
    #if DEBUG
    func signInWithTestAccount(
        email: String,
        password: String
    ) async {
        guard !isLoading else {
            return
        }

        isLoading = true
        errorMessage = nil

        defer {
            isLoading = false
        }

        do {
            let signedInSession = try await supabase.auth.signIn(
                email: email,
                password: password
            )

            session = signedInSession
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    #endif
    }
