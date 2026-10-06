import SwiftUI

struct AuthenticatedRootView: View {
    @ObservedObject var auth: AuthViewModel

    @StateObject private var locationPermission =
        LocationPermissionManager()

    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        Group {
            if let session = auth.session {
                if locationPermission.isAlwaysAuthorized {
                    HomeView()
                } else {
                    LocationRequiredView()
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
        .onChange(
            of: locationPermission.isAlwaysAuthorized
        ) { _, isAuthorized in
            guard isAuthorized else {
                return
            }

            print("Always location permission restored.")
        }
    }
}
