import SwiftUI

struct InviteTeamFriendsView: View {
    let team: TeamSummary

    @Environment(\.dismiss) private var dismiss

    @State private var friends: [TeamFriend] = []
    @State private var isLoading = true
    @State private var isSending = false
    @State private var errorMessage: String?

    private let service = TeamService()

    var body: some View {
        NavigationStack {
            List {
                if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundStyle(.red)

                        Button("Refresh List") {
                            Task {
                                await loadFriends()
                            }
                        }
                        .disabled(isLoading || isSending)
                    }
                }

                if isSending {
                    Section {
                        HStack(spacing: 12) {
                            ProgressView()

                            Text("Sending invitation…")
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                if !friends.isEmpty {
                    Section("Invite to \(team.name)") {
                        ForEach(friends) { friend in
                            friendRow(friend)
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .overlay {
                if isLoading && friends.isEmpty {
                    ProgressView("Loading friends…")

                } else if friends.isEmpty && errorMessage == nil {
                    ContentUnavailableView(
                        "No Friends to Invite",
                        systemImage: "person.2",
                        description: Text(
                            "You have no eligible friends to invite. "
                            + "Friends already in this team or with "
                            + "pending invitations are hidden."
                        )
                    )
                }
            }
            .navigationTitle("Invite Friends")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .disabled(isSending)
                }
            }
            .interactiveDismissDisabled(isSending)
            .task(id: team.id) {
                await loadFriends()
            }
            .refreshable {
                await loadFriends()
            }
        }
    }

    // MARK: - Friend row

    private func friendRow(
        _ friend: TeamFriend
    ) -> some View {
        Button {
            Task {
                await invite(friend)
            }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "person.crop.circle.fill")
                    .font(.title)
                    .foregroundStyle(.secondary)

                VStack(alignment: .leading, spacing: 4) {
                    Text(friend.displayName)
                        .foregroundStyle(.primary)

                    if let username = friend.username,
                       !username.isEmpty {
                        Text("@\(username)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                Image(systemName: "person.badge.plus")
                    .foregroundStyle(.tint)
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.borderless)
        .disabled(isLoading || isSending)
    }

    // MARK: - Load eligible friends

    @MainActor
    private func loadFriends() async {
        guard !isSending else {
            return
        }

        isLoading = true
        errorMessage = nil

        defer {
            isLoading = false
        }

        do {
            let fetchedFriends = try await service.fetchInvitableFriends(
                teamID: team.id
            )

            try Task.checkCancellation()

            friends = fetchedFriends
        } catch {
            guard !Task.isCancelled else {
                return
            }

            friends = []
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Send invitation

    @MainActor
    private func invite(
        _ friend: TeamFriend
    ) async {
        guard !isLoading, !isSending else {
            return
        }

        isSending = true
        errorMessage = nil

        defer {
            isSending = false
        }

        do {
            try await service.perform(
                TeamOperationParameters(
                    operation: "invite",
                    requested_team_id: team.id,
                    requested_friend_id: friend.id
                )
            )

            dismiss()
        } catch {
            errorMessage = error.localizedDescription

            // Another device may have invited or added this friend
            // since the picker was opened.
            if let refreshedFriends = try? await service
                .fetchInvitableFriends(teamID: team.id) {
                friends = refreshedFriends
            }
        }
    }
}
