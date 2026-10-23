import SwiftUI

struct RelayRecordingLifecycleModifier: ViewModifier {
    let userID: UUID?
    @Environment(\.scenePhase) private var scenePhase
    private let recorder = RelayActivityRecorder.shared

    private var taskID: String {
        (userID?.uuidString ?? "signed-out") + (scenePhase == .active ? "-active" : "-inactive")
    }

    func body(content: Content) -> some View {
        content.task(id: taskID) {
            recorder.configure(userID: userID)
            guard userID != nil, scenePhase == .active else { return }
            while !Task.isCancelled {
                await recorder.sync()
                do { try await Task.sleep(for: .seconds(60)) }
                catch { return }
            }
        }
    }
}
