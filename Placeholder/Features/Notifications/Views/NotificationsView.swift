import SwiftUI
import Supabase

struct NotificationsView: View {
    let client: SupabaseClient
    @Environment(\.dismiss) private var dismiss
    @State private var model: RelayEndNotificationsModel

    init(client: SupabaseClient) {
        self.client = client
        _model = State(initialValue: RelayEndNotificationsModel(client: client))
    }

    var body: some View {
        List {
            Section {
                NavigationLink {
                    FriendRequestsView(client: client)
                } label: {
                    HStack(spacing: 14) {
                        Image(systemName: "person.2.fill")
                            .font(.title3).foregroundStyle(.cyan)
                            .frame(width: 40, height: 40)
                            .background(Color.cyan.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Friend Requests").font(.headline)
                            Text("View and respond to requests")
                                .font(.subheadline).foregroundStyle(.secondary)
                        }
                    }.padding(.vertical, 4)
                }
            }
            Section("Notifications") {
                if model.isLoading && model.notifications.isEmpty {
                    ProgressView("Loading notifications…")
                } else if model.notifications.isEmpty && model.errorMessage == nil {
                    ContentUnavailableView("You’re All Caught Up", systemImage: "bell.badge",
                        description: Text("Your notifications will appear here."))
                        .frame(maxWidth: .infinity).listRowBackground(Color.clear)
                }
                ForEach(model.notifications) { notification in
                    Button { model.open(notification) } label: {
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: notification.isCompleted ? "flag.checkered" : "xmark.circle")
                                .font(.title3).foregroundStyle(.cyan)
                                .frame(width: 36, height: 36)
                            VStack(alignment: .leading, spacing: 5) {
                                Text(notification.title).font(.headline).foregroundStyle(.primary)
                                Text(notification.message).font(.subheadline).foregroundStyle(.secondary)
                                Text(notification.createdAt, style: .relative)
                                    .font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer(minLength: 0)
                            if notification.readAt == nil {
                                Circle().fill(.cyan).frame(width: 8, height: 8)
                                    .accessibilityLabel("Unread")
                            }
                        }.padding(.vertical, 6)
                    }.buttonStyle(.plain)
                }
            }
            if let error = model.errorMessage {
                Section {
                    Text(error).font(.footnote).foregroundStyle(.red)
                    Button("Try Again") { Task { await model.load() } }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } }
        }
        .task { await model.load() }
        .refreshable { await model.load() }
        .sheet(item: $model.presented, onDismiss: {
            Task { await model.presentationDismissed() }
        }) { notification in
            RelayResultSheet(notification: notification)
        }
    }
}
