import SwiftUI

struct RootView: View {
    @StateObject private var auth = AuthViewModel()

    @StateObject private var locationPermission =
        LocationPermissionManager()

    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        Group {
            if auth.isLoading && auth.session == nil {
                LoadingView()

            } else if auth.session == nil {
                SignInView(auth: auth)

            } else if auth.onboardingCompleted == nil {
                LoadingView()

            } else if auth.onboardingCompleted == false {
                NameView(auth: auth)

            } else if locationPermission.isAlwaysAuthorized {
                HomeView()

            } else {
                LocationRequiredView()
            }
        }
        .task {
            await auth.restoreSession()
        }
        .onAppear {
            locationPermission.refreshAuthorizationStatus()
        }
        .onChange(of: scenePhase) { _, newPhase in
            guard newPhase == .active else {
                return
            }

            locationPermission.refreshAuthorizationStatus()
        }
    }
}
