import SwiftUI

@main
struct PlaceholderApp: App {
    @State private var userProfileStore = UserProfileStore()
    @UIApplicationDelegateAdaptor(HealthBackgroundAppDelegate.self)
    private var healthAppDelegate

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(userProfileStore)
        }
    }
}
