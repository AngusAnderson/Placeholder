import SwiftUI

struct AutomaticActivityLifecycleModifier: ViewModifier {
    let userID: UUID?
    @Environment(\.scenePhase) private var scenePhase
    private let coordinator = AutomaticActivityCoordinator.shared
    private var identity: String {
        (userID?.uuidString ?? "signed-out") + (scenePhase == .active ? "-active" : "-inactive")
    }
    func body(content: Content) -> some View {
        content.task(id: identity) {
            coordinator.configure(userID: userID)
            guard userID != nil, scenePhase == .active else { return }
            coordinator.restoreLocalStatus()
            while !Task.isCancelled {
                await coordinator.synchronize()
                do { try await Task.sleep(for: .seconds(60)) }
                catch { return }
            }
        }
    }
}
