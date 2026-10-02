import AuthenticationServices
import SwiftUI
import Combine

struct SignInView: View {
    @StateObject private var auth = AuthViewModel()

    var body: some View {
        VStack(spacing: 24) {
            Text("Placeholder")
                .font(.largeTitle)

            SignInWithAppleButton(
                .signIn,
                onRequest: { request in
                    auth.prepareAppleRequest(request)
                },
                onCompletion: { result in
                    switch result {
                    case .success(let authorization):
                        guard let credential =
                                authorization.credential
                                as? ASAuthorizationAppleIDCredential
                        else {
                            auth.errorMessage =
                                "Invalid Apple credential."
                            return
                        }

                        Task {
                            await auth.signInWithApple(
                                credential: credential
                            )
                        }

                    case .failure(let error):
                        auth.errorMessage = error.localizedDescription
                    }
                }
            )
            .signInWithAppleButtonStyle(.black)
            .frame(height: 50)
            .padding(.horizontal)

            if let errorMessage = auth.errorMessage {
                Text(errorMessage)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
        }
    }
}
