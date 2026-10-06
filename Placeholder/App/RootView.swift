import SwiftUI

struct RootView: View {
    @StateObject private var auth = AuthViewModel()
    
    var body: some View {
        Group {
            if auth.isLoading && auth.session == nil {
                ProgressView("Loading...")
            } else if auth.session == nil {
                SignInView(auth: auth)
            } else if auth.onboardingCompleted == nil {
                ProgressView("Loading...")
            } else if auth.onboardingCompleted == false {
                NameView(auth: auth)
            } else {
                HomeView()
            }
        }
        .task {
            await auth.restoreSession()
        }
    }
}
