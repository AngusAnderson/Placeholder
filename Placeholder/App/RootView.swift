import SwiftUI
import Supabase

struct RootView: View {
    @StateObject private var auth = AuthViewModel()

    @StateObject private var locationPermission =
        LocationPermissionManager()

    @Environment(UserProfileStore.self) private var userProfileStore

    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        Group {
            if auth.isLoading && auth.session == nil {
                LoadingView()

            } else if auth.session == nil {
                SignInView(auth: auth)

            } else if userProfileStore.isLoadingProfile
                        && userProfileStore.profile == nil {
                LoadingView()

            } else if userProfileStore.profile == nil {
                ProfileErrorView(
                    message: userProfileStore.errorMessage
                        ?? "Could not load your profile.",
                    retry: {
                        Task {
                            await userProfileStore.loadProfile()
                        }
                    }
                )

            } else if !userProfileStore.isOnboarded {
                NameView(auth: auth)

            } else if locationPermission.isAlwaysAuthorized {
                HomeView(auth: auth)

            } else {
                LocationRequiredView(
                    locationPermission: locationPermission
                )
            }
        }
        .task {
            await auth.restoreSession()
        }
        .task(id: auth.session?.user.id) {
            guard auth.session != nil else {
                userProfileStore.clear()
                return
            }

            await userProfileStore.loadProfileIfNeeded()
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
