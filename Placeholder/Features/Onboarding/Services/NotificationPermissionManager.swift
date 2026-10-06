import Combine
import Foundation
import UserNotifications

@MainActor
final class NotificationPermissionManager: ObservableObject {
    @Published private(set) var isRequestingPermission = false
    @Published private(set) var permissionRequestCompleted = false

    func requestPermission() async {
        guard !isRequestingPermission else {
            return
        }

        isRequestingPermission = true

        defer {
            isRequestingPermission = false
            permissionRequestCompleted = true
        }

        do {
            let granted = try await UNUserNotificationCenter
                .current()
                .requestAuthorization(
                    options: [.alert, .sound, .badge]
                )

            print("Notification permission granted: \(granted)")
        } catch {
            // Damn, not letting notifications.
            print(
                "Notification permission request failed: \(error)"
            )
        }
    }
}
