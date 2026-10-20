import SwiftUI

struct TeamView: View {

    @State private var model = TeamViewModel()
    @State private var teamName = ""
    @State private var teamToInviteTo: TeamSummary?
    
    @State private var teamToRename: TeamSummary?
    @State private var renamedTeamName = ""
    @State private var showRenameAlert = false

    @State private var teamToDelete: TeamSummary?
    @State private var showDeleteConfirmation = false

    private var cleanedTeamName: String {
        teamName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var canCreateTeam: Bool {
        model.hasLoaded
            && !model.isBusy
            && model.teams.count < 5
            && cleanedTeamName.count >= 2
            && cleanedTeamName.count <= 40
    }

    var body: some View {
        NavigationStack {
            List {
                errorSection

                Section("Your Teams (\(model.teams.count)/5)") {
                    if model.hasLoaded && model.teams.isEmpty {
                        Text("You haven’t joined any teams yet.")
                            .foregroundStyle(.secondary)
                    }

                    ForEach(model.teams) { team in
                        teamRow(team)
                    }
                }

                Section("Create a Team") {
                    TextField("Team name", text: $teamName)
                        .textInputAutocapitalization(.words)
                        .disabled(model.isBusy)

                    Button {
                        Task {
                            let saved = await model.perform(
                                TeamOperationParameters(
                                    operation: "create",
                                    requested_name: cleanedTeamName
                                )
                            )

                            if saved {
                                teamName = ""
                            }
                        }
                    } label: {
                        Label("Create Team", systemImage: "plus.circle.fill")
                    }
                    .disabled(!canCreateTeam)

                    Text("Up to 5 teams per account and 8 members per team.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                invitationsSection
            }
            .overlay {
                if model.isLoading && !model.hasLoaded {
                    ProgressView("Loading teams…")
                }
            }
            .navigationTitle("Teams")
            .task {
                await model.load()
            }
            .refreshable {
                await model.load()
            }
            .sheet(item: $teamToInviteTo) { team in
                inviteFriendsSheet(for: team)
            }
            .alert(
                "Rename Team",
                isPresented: $showRenameAlert
            ) {
                TextField("Team name", text: $renamedTeamName)

                Button("Cancel", role: .cancel) {
                    teamToRename = nil
                }

                Button("Save") {
                    guard let team = teamToRename else {
                        return
                    }

                    let newName = renamedTeamName.trimmingCharacters(
                        in: .whitespacesAndNewlines
                    )

                    Task {
                        _ = await model.perform(
                            TeamOperationParameters(
                                operation: "rename",
                                requested_team_id: team.id,
                                requested_name: newName
                            )
                        )
                    }

                    teamToRename = nil
                }
                .disabled(
                    renamedTeamName.trimmingCharacters(
                        in: .whitespacesAndNewlines
                    ).count < 2
                    || renamedTeamName.trimmingCharacters(
                        in: .whitespacesAndNewlines
                    ).count > 40
                )
            } message: {
                Text("Choose a name containing 2–40 characters.")
            }
            .alert(
                "Delete Team?",
                isPresented: $showDeleteConfirmation,
                presenting: teamToDelete
            ) { team in
                Button("Cancel", role: .cancel) {
                    teamToDelete = nil
                }

                Button("Delete Team", role: .destructive) {
                    Task {
                        _ = await model.perform(
                            TeamOperationParameters(
                                operation: "delete",
                                requested_team_id: team.id
                            )
                        )
                    }

                    teamToDelete = nil
                }
            } message: { team in
                Text(
                    "Delete “\(team.name)” for everyone? "
                    + "All memberships and invitations for this team "
                    + "will be removed. This cannot be undone."
                )
            }
        }
    }

    // MARK: - Errors

    @ViewBuilder
    private var errorSection: some View {
        if let errorMessage = model.errorMessage {
            Section {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundStyle(.red)

                Button("Refresh") {
                    Task {
                        await model.load()
                    }
                }
                .disabled(model.isBusy)
            }
        }
    }

    // MARK: - Teams

    private func teamRow(_ team: TeamSummary) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "person.3.fill")
                    .foregroundStyle(.cyan)

                VStack(alignment: .leading, spacing: 4) {
                    Text(team.name)
                        .font(.headline)

                    Text(
                        "\(team.memberCount)/8 members"
                        + (team.isOwner ? " · Owner" : "")
                    )
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                }

                Spacer()

                if team.isOwner {
                    Menu {
                        Button {
                            teamToRename = team
                            renamedTeamName = team.name
                            showRenameAlert = true
                        } label: {
                            Label(
                                "Rename Team",
                                systemImage: "pencil"
                            )
                        }

                        Button(role: .destructive) {
                            teamToDelete = team
                            showDeleteConfirmation = true
                        } label: {
                            Label(
                                "Delete Team",
                                systemImage: "trash"
                            )
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.system(size: 18, weight: .semibold))
                            .frame(width: 44, height: 44)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.borderless)
                    .disabled(model.isBusy)
                    .accessibilityLabel(
                        "Manage \(team.name)"
                    )
                }
            }

            if team.isOwner {
                Button {
                    model.errorMessage = nil
                    teamToInviteTo = team
                } label: {
                    Label(
                        "Invite a Friend",
                        systemImage: "person.badge.plus"
                    )
                }
                .buttonStyle(.bordered)
                .disabled(model.isBusy || team.memberCount >= 8)
            }
        }
        .padding(.vertical, 6)
    }

    // MARK: - Incoming invitations

    private var invitationsSection: some View {
        Section("Team Invitations") {
            if model.hasLoaded && model.invitations.isEmpty {
                Text("No pending team invitations.")
                    .foregroundStyle(.secondary)
            }

            ForEach(model.invitations) { invitation in
                VStack(alignment: .leading, spacing: 12) {
                    Text(invitation.teamName)
                        .font(.headline)

                    Text("You’ve been invited to join this team.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    HStack {
                        Button("Accept") {
                            respond("accept", to: invitation)
                        }
                        .buttonStyle(.borderedProminent)

                        Button("Decline", role: .destructive) {
                            respond("decline", to: invitation)
                        }
                        .buttonStyle(.bordered)
                    }
                    .disabled(model.isBusy)
                }
                .padding(.vertical, 6)
            }
        }
    }

    private func respond(
        _ operation: String,
        to invitation: TeamInvitation
    ) {
        Task {
            _ = await model.perform(
                TeamOperationParameters(
                    operation: operation,
                    requested_invitation_id: invitation.id
                )
            )
        }
    }

    // MARK: - Friend picker

    private func inviteFriendsSheet(
        for team: TeamSummary
    ) -> some View {
        NavigationStack {
            List {
                errorSection

                if model.friends.isEmpty {
                    ContentUnavailableView(
                        "No Friends Yet",
                        systemImage: "person.2",
                        description: Text(
                            "Add friends before inviting them to a team."
                        )
                    )
                } else {
                    Section("Invite to \(team.name)") {
                        ForEach(model.friends) { friend in
                            Button {
                                Task {
                                    let saved = await model.perform(
                                        TeamOperationParameters(
                                            operation: "invite",
                                            requested_team_id: team.id,
                                            requested_friend_id: friend.id
                                        )
                                    )

                                    if saved {
                                        teamToInviteTo = nil
                                    }
                                }
                            } label: {
                                HStack {
                                    VStack(
                                        alignment: .leading,
                                        spacing: 4
                                    ) {
                                        Text(friend.displayName)
                                            .foregroundStyle(.primary)

                                        if let username = friend.username {
                                            Text("@\(username)")
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                    }

                                    Spacer()

                                    Image(
                                        systemName: "person.badge.plus"
                                    )
                                }
                            }
                            .disabled(model.isBusy)
                        }
                    }
                }
            }
            .navigationTitle("Invite Friends")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        teamToInviteTo = nil
                    }
                }
            }
        }
    }
}
