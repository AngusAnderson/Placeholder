import SwiftUI

struct AuthenticatedRootView: View {
    @ObservedObject var auth: AuthViewModel

    @StateObject private var locationPermission =
        LocationPermissionManager()

    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        Group {
            if auth.session != nil {
                if locationPermission.isAlwaysAuthorized {
                    HomeView(auth: auth)
                } else {
                    LocationRequiredView(
                        locationPermission: locationPermission
                    )
                }
            } else {
                SignInView(auth: auth)
            }
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
