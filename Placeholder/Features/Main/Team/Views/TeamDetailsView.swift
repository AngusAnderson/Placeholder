import SwiftUI

struct TeamDetailsView: View {
    let teamID: Int64

    @Environment(\.dismiss) private var dismiss

    @State private var details: TeamDetails?
    @State private var isLoading = false
    @State private var isPerformingAction = false

    @State private var errorMessage: String?
    @State private var actionErrorMessage: String?

    @State private var memberToRemove: TeamMember?
    @State private var showRemoveConfirmation = false
    @State private var showLeaveConfirmation = false
    
    @State private var relayModel = RelayViewModel()
    @State private var showCreateRelay = false

    private let service = TeamService()

    private var currentUserIsOwner: Bool {
        details?.members.contains {
            $0.isCurrentUser && $0.isOwner
        } ?? false
    }

    private var isBusy: Bool {
        isLoading || isPerformingAction
    }

    var body: some View {
        NavigationStack {
            Group {
                if let details {
                    detailsList(details)

                } else if isLoading {
                    ProgressView("Loading team…")
                        .frame(
                            maxWidth: .infinity,
                            maxHeight: .infinity
                        )

                } else {
                    unavailableView
                }
            }
            .navigationTitle(details?.name ?? "Team Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .disabled(isPerformingAction)
                }
            }
            .task(id: teamID) {
                await loadDetails()
            }
            .interactiveDismissDisabled(isPerformingAction)
            .alert(
                "Remove Member?",
                isPresented: $showRemoveConfirmation,
                presenting: memberToRemove
            ) { member in
                Button("Cancel", role: .cancel) {
                    memberToRemove = nil
                }

                Button("Remove", role: .destructive) {
                    Task {
                        await removeMember(member)
                    }
                }
            } message: { member in
                Text(
                    "Remove \(member.displayName) from this team? "
                    + "They will need a new invitation to rejoin."
                )
            }
            .alert(
                "Leave Team?",
                isPresented: $showLeaveConfirmation
            ) {
                Button("Cancel", role: .cancel) {}

                Button("Leave Team", role: .destructive) {
                    Task {
                        await leaveTeam()
                    }
                }
            } message: {
                Text(
                    "You will lose access to this team. "
                    + "You’ll need a new invitation to rejoin."
                )
            }
        }
    }

    // MARK: - Team information

    private func detailsList(
        _ details: TeamDetails
    ) -> some View {
        List {
            if let actionErrorMessage {
                Section {
                    Text(actionErrorMessage)
                        .font(.footnote)
                        .foregroundStyle(.red)
                }
            }

            if isPerformingAction {
                Section {
                    HStack(spacing: 12) {
                        ProgressView()
                        Text("Updating team…")
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Section("Team Information") {
                LabeledContent("Name", value: details.name)

                LabeledContent(
                    "Members",
                    value: "\(details.members.count)/8"
                )

                LabeledContent("Created") {
                    Text(
                        details.createdAt,
                        format: .dateTime.day().month().year()
                    )
                }
            }
            
            TeamGameSection(
                teamID: details.id,
                isOwner: currentUserIsOwner,
                model: relayModel,
                showCreateRelay: $showCreateRelay
            )

            Section("Members") {
                ForEach(details.members) { member in
                    memberRow(member)
                }
            }

            if currentUserIsOwner {
                Section {
                    Text(
                        "You own this team. To leave, delete the "
                        + "team from the team-management menu. "
                        + "Ownership transfer is not available yet."
                    )
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                }
            } else {
                Section {
                    Button(role: .destructive) {
                        showLeaveConfirmation = true
                    } label: {
                        Label(
                            "Leave Team",
                            systemImage:
                                "rectangle.portrait.and.arrow.right"
                        )
                    }
                    .disabled(isBusy)
                }
            }
        }
        .listStyle(.insetGrouped)
        .refreshable {
            await loadDetails()
        }
        .sheet(
            isPresented: $showCreateRelay,
            onDismiss: {
                Task {
                    await relayModel.refresh(teamID: details.id)
                }
            }
        ) {
            CreateRelayView(teamID: details.id)
        }
    }

    // MARK: - Member row

    private func memberRow(
        _ member: TeamMember
    ) -> some View {
        HStack(spacing: 12) {
            NavigationLink {
                PublicProfileView(
                    profileID: member.id,
                    client: supabase
                )
            } label: {
                memberLabel(member)
            }
            .disabled(isBusy)

            if currentUserIsOwner && !member.isCurrentUser {
                Button(role: .destructive) {
                    memberToRemove = member
                    showRemoveConfirmation = true
                } label: {
                    Image(systemName: "person.crop.circle.badge.minus")
                        .font(.title3)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.borderless)
                .disabled(isBusy)
                .accessibilityLabel(
                    "Remove \(member.displayName) from team"
                )
            }
        }
        .padding(.vertical, 6)
    }

    private func memberLabel(
        _ member: TeamMember
    ) -> some View {
        HStack(alignment: .top, spacing: 12) {
            TeamMemberAvatarView(
                path: member.profilePicturePath
            )

            VStack(alignment: .leading, spacing: 5) {
                Text(
                    member.displayName
                    + (member.isCurrentUser ? " (You)" : "")
                )
                .font(.headline)

                if let username = member.username,
                   !username.isEmpty {
                    Text("@\(username)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Text(
                    "Joined "
                    + member.joinedAt.formatted(
                        date: .abbreviated,
                        time: .omitted
                    )
                )
                .font(.caption)
                .foregroundStyle(.secondary)

                if member.isOwner {
                    Text("Owner")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.cyan)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(
                            Color.cyan.opacity(0.12),
                            in: Capsule()
                        )
                }
            }

            Spacer(minLength: 0)
        }
    }

    // MARK: - Error state

    private var unavailableView: some View {
        ContentUnavailableView {
            Label(
                "Couldn’t Load Team",
                systemImage: "exclamationmark.triangle"
            )
        } description: {
            Text(
                errorMessage
                ?? "The team information is currently unavailable."
            )
        } actions: {
            Button("Try Again") {
                Task {
                    await loadDetails()
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(isBusy)
        }
    }

    // MARK: - Load details

    @MainActor
    private func loadDetails() async {
        guard !isBusy else {
            return
        }

        isLoading = true
        errorMessage = nil
        actionErrorMessage = nil

        defer {
            isLoading = false
        }

        do {
            let fetchedDetails = try await service.fetchDetails(
                teamID: teamID
            )

            try Task.checkCancellation()

            details = fetchedDetails
        } catch {
            guard !Task.isCancelled else {
                return
            }

            details = nil
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Remove member

    @MainActor
    private func removeMember(
        _ member: TeamMember
    ) async {
        guard !isBusy else {
            return
        }

        isPerformingAction = true
        actionErrorMessage = nil

        defer {
            isPerformingAction = false
            memberToRemove = nil
        }

        do {
            try await service.removeMember(
                userID: member.id,
                from: teamID
            )
        } catch {
            actionErrorMessage = error.localizedDescription
            return
        }

        // The removal succeeded. Update the visible list immediately.
        if let currentDetails = details {
            details = TeamDetails(
                id: currentDetails.id,
                name: currentDetails.name,
                createdAt: currentDetails.createdAt,
                members: currentDetails.members.filter {
                    $0.id != member.id
                }
            )
        }

        // Refresh without reporting a successful removal as a failure.
        do {
            details = try await service.fetchDetails(
                teamID: teamID
            )
        } catch {
            actionErrorMessage =
                "The member was removed, but team details "
                + "could not refresh. Pull down to try again."
        }
    }

    // MARK: - Leave team

    @MainActor
    private func leaveTeam() async {
        guard !isBusy else {
            return
        }

        isPerformingAction = true
        actionErrorMessage = nil

        defer {
            isPerformingAction = false
        }

        do {
            try await service.leaveTeam(teamID: teamID)

            // Do not fetch details after leaving:
            // the caller is no longer authorised to read them.
            dismiss()
        } catch {
            actionErrorMessage = error.localizedDescription
        }
    }
}
