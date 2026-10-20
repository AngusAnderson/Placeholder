import SwiftUI

@main
struct PlaceholderApp: App {
    @State private var userProfileStore = UserProfileStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(userProfileStore)
        }
    }
}
