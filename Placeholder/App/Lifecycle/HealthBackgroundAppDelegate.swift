import UIKit
import Supabase

@MainActor
final class HealthBackgroundAppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions:
            [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        AutomaticActivityCoordinator.shared
            .installObserversIfPreviouslyEnabled()

        Task { @MainActor in
            if let session = try? await supabase.auth.session {
                AutomaticActivityCoordinator.shared.configure(
                    userID: session.user.id
                )

                AutomaticActivityCoordinator.shared
                    .restoreLocalStatus()

                await AutomaticActivityCoordinator.shared
                    .synchronize()
            }
        }

        return true
    }

    func applicationProtectedDataDidBecomeAvailable(
        _ application: UIApplication
    ) {
        Task { @MainActor in
            await AutomaticActivityCoordinator.shared
                .synchronize()
        }
    }
}
