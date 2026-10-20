import SwiftUI

struct UserSearchOverlay: View {
    let onClose: () -> Void
    let onSelect: (UserSearchResult) -> Void

    @State private var query = ""
    @State private var results: [UserSearchResult] = []
    @State private var isSearching = false
    @State private var errorMessage: String?
    @State private var profileImageURLs: [UUID: URL] = [:]

    @FocusState private var isSearchFocused: Bool

    private let profileService = ProfileService()
    private let profilePictureService = ProfilePictureService()

    private var trimmedQuery: String {
        query.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        ZStack(alignment: .top) {
            Color.black.opacity(0.45)
                .ignoresSafeArea()
                .onTapGesture {
                    close()
                }

            VStack(spacing: 0) {
                searchField

                if trimmedQuery.count >= 2 {
                    Divider()
                        .overlay(.white.opacity(0.1))

                    resultsContent
                } else {
                    Text("Search by name or username")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 18)
                        .padding(.bottom, 16)
                }
            }
            .background(
                .regularMaterial,
                in: RoundedRectangle(cornerRadius: 22)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 22)
                    .stroke(.white.opacity(0.15), lineWidth: 1)
            }
            .shadow(
                color: .black.opacity(0.3),
                radius: 25,
                y: 12
            )
            .frame(maxWidth: 560)
            .padding(.horizontal, 20)
            .padding(.top, 60)
        }
        .foregroundStyle(.white)
        .preferredColorScheme(.dark)
        .task {
            isSearchFocused = true
        }
        .task(id: query) {
            await performSearch(query)
        }
    }

    private var searchField: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 22))
                .foregroundStyle(.secondary)

            TextField("Search users", text: $query)
                .font(.system(size: 21))
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .focused($isSearchFocused)
                .submitLabel(.search)
                .accessibilityLabel("Search users")

            if !query.isEmpty {
                Button {
                    query = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .accessibilityLabel("Clear search")
            }

            Button {
                close()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 15, weight: .semibold))
                    .frame(width: 32, height: 32)
                    .background(
                        .white.opacity(0.08),
                        in: Circle()
                    )
            }
            .accessibilityLabel("Close search")
        }
        .padding(18)
        .buttonStyle(.plain)
    }
    
    private var resultsList: some View {
        Group {
            if results.count <= 4 {
                LazyVStack(spacing: 0) {
                    resultButtons
                }
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        resultButtons
                    }
                }
                .frame(maxHeight: 300)
                .scrollDismissesKeyboard(.interactively)
            }
        }
        .padding(.vertical, 6)
    }

    @ViewBuilder
    private var resultButtons: some View {
        ForEach(results) { user in
            Button {
                isSearchFocused = false
                onSelect(user)
            } label: {
                resultRow(user)
            }
            .buttonStyle(.plain)
        }
    }

    @ViewBuilder
    private var resultsContent: some View {
        if isSearching {
            HStack(spacing: 12) {
                ProgressView()
                Text("Searching…")
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(20)

        } else if let errorMessage {
            Text(errorMessage)
                .font(.subheadline)
                .foregroundStyle(.red)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(20)

        } else if results.isEmpty {
            Text("No users found")
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(20)

        } else {
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(results) { user in
                        Button {
                            isSearchFocused = false
                            onSelect(user)
                        } label: {
                            resultRow(user)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 6)
            }
            .frame(maxHeight: 300)
            .scrollDismissesKeyboard(.interactively)
        }
    }

    private func resultRow(_ user: UserSearchResult) -> some View {
        HStack(spacing: 12) {
            SearchAvatarView(
                imageURL: profileImageURLs[user.id]
            )

            VStack(alignment: .leading, spacing: 4) {
                Text(user.displayName)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)

                if let username = user.username, !username.isEmpty {
                    Text("@\(username)")
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
    }

    @MainActor
    private func performSearch(_ rawQuery: String) async {
        let searchTerm = rawQuery.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        results = []
        errorMessage = nil
        isSearching = false

        guard searchTerm.count >= 2 else {
            return
        }

        isSearching = true

        do {
            try await Task.sleep(for: .milliseconds(300))
            try Task.checkCancellation()

            let matches = try await profileService.searchUsers(
                query: searchTerm
            )

            try Task.checkCancellation()

            guard query == rawQuery else {
                return
            }

            results = matches
            profileImageURLs = await loadProfileImageURLs(for: matches)
            isSearching = false
        } catch {
            guard !Task.isCancelled, query == rawQuery else {
                return
            }

            results = []
            isSearching = false
            errorMessage = error.localizedDescription
            print("User search failed:", error)
        }
    }
    
    private func loadProfileImageURLs(
        for users: [UserSearchResult]
    ) async -> [UUID: URL] {
        var urls: [UUID: URL] = [:]

        await withTaskGroup(of: (UUID, URL?).self) { group in
            for user in users {
                guard let path = user.profilePicturePath,
                      !path.isEmpty
                else {
                    continue
                }

                group.addTask {
                    do {
                        let url = try await profilePictureService
                            .createSignedProfilePictureURL(path: path)

                        return (user.id, url)
                    } catch {
                        return (user.id, nil)
                    }
                }
            }

            for await (id, url) in group {
                if let url {
                    urls[id] = url
                }
            }
        }

        return urls
    }

    private func close() {
        isSearchFocused = false
        onClose()
    }
}
