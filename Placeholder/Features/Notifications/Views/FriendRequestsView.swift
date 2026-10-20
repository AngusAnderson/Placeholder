import SwiftUI
import Supabase

struct FriendRequestsView: View {
    let client: SupabaseClient

    @State private var requests: [IncomingFriendRequest] = []
    @State private var isLoading = true
    @State private var isPerformingAction = false
    @State private var errorMessage: String?

    private var service: FriendshipService {
        FriendshipService(client: client)
    }

    var body: some View {
        List {
            if let errorMessage {
                Section {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundStyle(.red)

                    Button("Retry") {
                        Task {
                            await loadRequests()
                        }
                    }
                    .disabled(isLoading || isPerformingAction)
                }
            }

            ForEach(requests) { request in
                requestRow(request)
            }
        }
        .listStyle(.insetGrouped)
        .overlay {
            if isLoading && requests.isEmpty {
                ProgressView("Loading requests…")
            } else if requests.isEmpty && errorMessage == nil {
                ContentUnavailableView(
                    "No Friend Requests",
                    systemImage: "person.crop.circle.badge.checkmark",
                    description: Text(
                        "New friend requests will appear here."
                    )
                )
            }
        }
        .navigationTitle("Friend Requests")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadRequests()
        }
        .refreshable {
            await loadRequests()
        }
    }

    private func requestRow(
        _ request: IncomingFriendRequest
    ) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                Image(systemName: "person.fill")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .frame(width: 44, height: 44)
                    .background(
                        Color.secondary.opacity(0.12),
                        in: Circle()
                    )

                VStack(alignment: .leading, spacing: 4) {
                    Text(request.displayName)
                        .font(.headline)

                    if let username = request.username,
                       !username.isEmpty {
                        Text("@\(username)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    Text(request.createdAt, style: .relative)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            HStack(spacing: 12) {
                Button {
                    Task {
                        await respond(.accept, to: request)
                    }
                } label: {
                    Text("Accept")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)

                Button(role: .destructive) {
                    Task {
                        await respond(.decline, to: request)
                    }
                } label: {
                    Text("Decline")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
            .disabled(isLoading || isPerformingAction)
        }
        .padding(.vertical, 8)
    }

    @MainActor
    private func loadRequests() async {
        guard !isPerformingAction else {
            return
        }

        isLoading = true
        errorMessage = nil

        defer {
            isLoading = false
        }

        do {
            let fetchedRequests = try await service.fetchIncomingRequests()
            try Task.checkCancellation()

            requests = fetchedRequests
        } catch {
            guard !Task.isCancelled else {
                return
            }

            errorMessage = error.localizedDescription
        }
    }

    @MainActor
    private func respond(
        _ action: FriendshipAction,
        to request: IncomingFriendRequest
    ) async {
        guard !isPerformingAction, !isLoading else {
            return
        }

        isPerformingAction = true
        errorMessage = nil

        defer {
            isPerformingAction = false
        }

        do {
            try await service.perform(
                action,
                with: request.requesterID
            )

            requests.removeAll {
                $0.id == request.id
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
