import SwiftUI
import Supabase

private struct RelayCompletionPresentation: ViewModifier {
    @Environment(\.scenePhase) private var scenePhase
    @State private var model: RelayEndNotificationsModel
    let refreshToken: String

    init(client: SupabaseClient, refreshToken: String) {
        self.refreshToken = refreshToken
        _model = State(initialValue: RelayEndNotificationsModel(client: client))
    }
    func body(content: Content) -> some View {
        content
            .task(id: refreshToken) { await model.load(autoPresent: true) }
            .onChange(of: scenePhase) { _, phase in
                if phase == .active { Task { await model.load(autoPresent: true) } }
            }
            .sheet(item: $model.presented, onDismiss: {
                Task { await model.presentationDismissed() }
            }) { notification in
                RelayResultSheet(notification: notification)
            }
    }
}

extension View {
    func relayCompletionPresentation(
        client: SupabaseClient,
        refreshToken: String = ""
    ) -> some View {
        modifier(RelayCompletionPresentation(client: client, refreshToken: refreshToken))
    }
}
