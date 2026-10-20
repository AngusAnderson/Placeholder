import SwiftUI
import Supabase

struct NotificationsView: View {
    let client: SupabaseClient

    @Environment(\.dismiss) private var dismiss

    // Empty until a notification backend is connected.
    @State private var notifications: [AppNotification] = []

    var body: some View {
        List {
            Section {
                NavigationLink {
                    FriendRequestsView(client: client)
                } label: {
                    HStack(spacing: 14) {
                        Image(systemName: "person.2.fill")
                            .font(.title3)
                            .foregroundStyle(.cyan)
                            .frame(width: 40, height: 40)
                            .background(
                                Color.cyan.opacity(0.12),
                                in: RoundedRectangle(cornerRadius: 12)
                            )

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Friend Requests")
                                .font(.headline)

                            Text("View and respond to requests")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }

            Section("Notifications") {
                if notifications.isEmpty {
                    ContentUnavailableView(
                        "You’re All Caught Up",
                        systemImage: "bell.badge",
                        description: Text(
                            "Your notifications will appear here."
                        )
                    )
                    .frame(maxWidth: .infinity)
                    .listRowBackground(Color.clear)
                } else {
                    ForEach(notifications) { notification in
                        notificationRow(notification)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") {
                    dismiss()
                }
            }
        }
    }

    private func notificationRow(
        _ notification: AppNotification
    ) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: notification.systemImage)
                .font(.title3)
                .foregroundStyle(.cyan)
                .frame(width: 36, height: 36)

            VStack(alignment: .leading, spacing: 5) {
                Text(notification.title)
                    .font(.headline)

                Text(notification.message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Text(notification.createdAt, style: .relative)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)

            if !notification.isRead {
                Circle()
                    .fill(.cyan)
                    .frame(width: 8, height: 8)
                    .accessibilityLabel("Unread")
            }
        }
        .padding(.vertical, 6)
    }
}
