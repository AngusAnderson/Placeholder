import AuthenticationServices
import Combine
import Foundation
import Supabase

@MainActor
final class AuthViewModel: NSObject, ObservableObject {
    @Published private(set) var session: Session?
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?

    private var currentNonce: String?

    func prepareAppleRequest(_ request: ASAuthorizationAppleIDRequest) {
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
              ) else {
            errorMessage = "Unable to obtain Apple's identity token."
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            let session = try await supabase.auth.signInWithIdToken(
                credentials: OpenIDConnectCredentials(
                    provider: .apple,
                    idToken: identityToken,
                    nonce: nonce
                )
            )

            self.session = session
            currentNonce = nil
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func restoreSession() async {
        do {
            session = try await supabase.auth.session
        } catch {
            session = nil
        }
    }

    func signOut() async {
        do {
            try await supabase.auth.signOut()
            session = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
