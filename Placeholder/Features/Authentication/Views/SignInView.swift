import AuthenticationServices
import SwiftUI
import Combine

struct SignInView: View {
    @ObservedObject var auth = AuthViewModel()

    var body: some View {
        ZStack {
            // Background image - Might be temporary, might not be...
            Image("login-bg")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
            
            
            VStack (spacing: 15) {
                
                // Centre text group
                VStack {
                    Text("Placeholder")
                        .font(.system(size: 40))
                        .italic()
                        .fontWeight(.heavy)
                        .foregroundStyle(.white)
                        .tracking(40*0.04)
                    
                    Text("A place to move.")
                        .font(.system(size: 26))
                        .fontWeight(.light)
                        .foregroundStyle(.white)
                        .tracking(26*0.04)
                }
                .padding(.top, 75)
                
                Spacer()
                
                // Quick tour button
                Button {
                    
                } label: {
                    Text("Take a quick tour")
                        .font(.system(size: 20))
                        .tracking(20*0.04)
                        .foregroundStyle(.black)
                        .frame(width: 320, height: 59)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                }
                
                .padding(.horizontal)
                
                // Apple sign in button
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
                .font(.system(size: 20))
                .tracking(20*0.04)
                .frame(width: 320, height: 59)
                .clipShape(RoundedRectangle(cornerRadius: 20))
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
}
