import SwiftUI
import Supabase

struct FriendshipButtonView: View {
    let targetUserID: UUID

    @State private var model: FriendshipViewModel
    @State private var showRemoveConfirmation = false

    init(
        targetUserID: UUID,
        client: SupabaseClient
    ) {
        self.targetUserID = targetUserID

        _model = State(
            initialValue: FriendshipViewModel(
                service: FriendshipService(client: client)
            )
        )
    }

    var body: some View {
        VStack(spacing: 10) {
            if model.isLoading && model.state == nil {
                ProgressView("Loading relationship…")
                    .tint(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)

            } else if let state = model.state {
                controls(for: state)
                    .disabled(
                        model.isLoading || model.isPerformingAction
                    )

            } else {
                Button("Retry relationship loading") {
                    Task {
                        await model.load(with: targetUserID)
                    }
                }
                .buttonStyle(.bordered)
            }

            if model.isPerformingAction {
                ProgressView()
                    .tint(.white)
            }

            if let errorMessage = model.errorMessage {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
            }
        }
        .task(id: targetUserID) {
            await model.load(with: targetUserID)
        }
        .confirmationDialog(
            "Remove this friend?",
            isPresented: $showRemoveConfirmation,
            titleVisibility: .visible
        ) {
            Button("Remove Friend", role: .destructive) {
                performAction(.remove)
            }

            Button("Cancel", role: .cancel) {}
        }
    }

    // MARK: - Relationship controls

    @ViewBuilder
    private func controls(
        for state: FriendshipState
    ) -> some View {
        switch state {
        case .ownProfile:
            EmptyView()

        case .none:
            actionButton(
                "Add Friend",
                symbol: "person.badge.plus"
            ) {
                performAction(.send)
            }

        case .outgoing:
            Menu {
                Button("Cancel Request", role: .destructive) {
                    performAction(.cancel)
                }
            } label: {
                buttonLabel(
                    "Requested",
                    symbol: "clock"
                )
            }
            .buttonStyle(.plain)

        case .incoming:
            VStack(spacing: 10) {
                actionButton(
                    "Accept Request",
                    symbol: "person.crop.circle.badge.checkmark"
                ) {
                    performAction(.accept)
                }

                Button("Decline Request", role: .destructive) {
                    performAction(.decline)
                }
                .font(.subheadline)
            }

        case .friends:
            Menu {
                Button("Remove Friend", role: .destructive) {
                    showRemoveConfirmation = true
                }
            } label: {
                buttonLabel(
                    "Friends",
                    symbol: "checkmark"
                )
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Button styling

    private func actionButton(
        _ title: String,
        symbol: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            buttonLabel(title, symbol: symbol)
        }
        .buttonStyle(.plain)
    }

    private func buttonLabel(
        _ title: String,
        symbol: String
    ) -> some View {
        Label(title, systemImage: symbol)
            .font(.system(size: 17, weight: .semibold))
            .foregroundStyle(.black)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(.white, in: Capsule())
            .contentShape(Capsule())
    }

    // MARK: - Database actions

    private func performAction(
        _ action: FriendshipAction
    ) {
        Task {
            await model.perform(
                action,
                with: targetUserID
            )
        }
    }
}
