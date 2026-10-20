import SwiftUI
import Supabase

struct PublicProfileView: View {
    let profileID: UUID
    let client: SupabaseClient

    @Environment(\.dismiss) private var dismiss

    @State private var profile: PublicProfile?
    @State private var profileImage: UIImage?

    @State private var isLoading = true
    @State private var errorMessage: String?

    private let profileService = ProfileService()
    private let profilePictureService = ProfilePictureService()

    private let creations = [
        "creation1",
        "creation2",
        "creation1",
        "creation2"
    ]

    private let columns = [
        GridItem(.flexible(), spacing: 14),
        GridItem(.flexible(), spacing: 14)
    ]

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .top) {
                profileBackground(size: geometry.size)

                if isLoading {
                    ProgressView("Loading profile…")
                        .tint(.white)
                        .foregroundStyle(.white)

                } else if let errorMessage {
                    errorView(errorMessage)

                } else if let profile {
                    profileContent(profile, geometry: geometry)
                }
            }
            .frame(
                width: geometry.size.width,
                height: geometry.size.height
            )
        }
        .background(Color.black.ignoresSafeArea())
        .foregroundStyle(.white)
        .preferredColorScheme(.dark)
        .toolbar(.hidden, for: .navigationBar)
        .task(id: profileID) {
            await loadProfile()
        }
    }

    // MARK: - Main content

    private func profileContent(
        _ profile: PublicProfile,
        geometry: GeometryProxy
    ) -> some View {
        ZStack(alignment: .top) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 22) {
                    Color.clear
                        .frame(height: geometry.size.height * 0.47)
                        .accessibilityHidden(true)

                    identity(profile)

                    actions

                    statistics

                    biography

                    creationsGrid
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 30)
                .frame(maxWidth: .infinity)
            }

            topControls
                .padding(.horizontal, 24)
                .padding(.top, 12)
        }
    }

    // MARK: - Data loading

    @MainActor
    private func loadProfile() async {
        isLoading = true
        errorMessage = nil
        profile = nil
        profileImage = nil

        defer {
            isLoading = false
        }

        let fetchedProfile: PublicProfile

        do {
            fetchedProfile = try await profileService.fetchPublicProfile(
                id: profileID
            )

            try Task.checkCancellation()
        } catch {
            guard !Task.isCancelled else {
                return
            }

            // Only failure to fetch the profile blocks the whole screen.
            errorMessage = error.localizedDescription
            return
        }

        profile = fetchedProfile

        // The profile can now display while its image loads.
        isLoading = false

        await loadProfileImage(
            path: fetchedProfile.profilePicturePath
        )
    }

    // MARK: - Background

    private func profileBackground(size: CGSize) -> some View {
        ZStack {
            if let profileImage {
                Image(uiImage: profileImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: size.width, height: size.height)
                    .clipped()
            } else {
                LinearGradient(
                    colors: [
                        Color(red: 0.10, green: 0.12, blue: 0.17),
                        Color(red: 0.02, green: 0.03, blue: 0.06)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .overlay {
                    Image(systemName: "person.crop.circle.fill")
                        .font(.system(size: 110))
                        .foregroundStyle(.white.opacity(0.18))
                }
            }

            Rectangle()
                .fill(.ultraThinMaterial)
                .mask {
                    LinearGradient(
                        stops: [
                            .init(color: .clear, location: 0.35),
                            .init(
                                color: .black.opacity(0.15),
                                location: 0.45
                            ),
                            .init(color: .black, location: 0.65),
                            .init(color: .black, location: 1)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                }

            LinearGradient(
                stops: [
                    .init(color: .clear, location: 0.30),
                    .init(
                        color: .black.opacity(0.15),
                        location: 0.48
                    ),
                    .init(
                        color: .black.opacity(0.55),
                        location: 0.72
                    ),
                    .init(
                        color: .black.opacity(0.80),
                        location: 1
                    )
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
        .frame(width: size.width, height: size.height)
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    // MARK: - Top controls

    private var topControls: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                circularIcon("chevron.left")
            }
            .accessibilityLabel("Back")

            Spacer()

            Menu {
                Button(role: .destructive) {
                    // Add a report flow later.
                } label: {
                    Label("Report user", systemImage: "exclamationmark.flag")
                }

                Button {
                    // Add a block flow later.
                } label: {
                    Label("Block user", systemImage: "hand.raised")
                }
            } label: {
                circularIcon("ellipsis")
            }
            .accessibilityLabel("Profile options")
        }
        .buttonStyle(.plain)
    }

    private func circularIcon(_ symbol: String) -> some View {
        Image(systemName: symbol)
            .font(.system(size: 19, weight: .semibold))
            .frame(width: 46, height: 46)
            .background(.ultraThinMaterial, in: Circle())
            .overlay {
                Circle()
                    .stroke(.white.opacity(0.10), lineWidth: 1)
            }
    }

    // MARK: - Identity

    private func identity(_ profile: PublicProfile) -> some View {
        VStack(spacing: 8) {
            Text(profile.displayName)
                .font(.system(size: 38, weight: .semibold))
                .multilineTextAlignment(.center)

            if let username = profile.username, !username.isEmpty {
                Text("@\(username)")
                    .font(.system(size: 18))
                    .foregroundStyle(.white.opacity(0.55))
            }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Actions

    private var actions: some View {
        FriendshipButtonView(
            targetUserID: profileID,
            client: client
        )
        .id(profileID)
    }

    // MARK: - Placeholder sections

    private var statistics: some View {
        HStack {
            statistic(value: "—", title: "Following")
            statistic(value: "—", title: "Followers")
        }
        .padding(.vertical, 6)
    }

    private func statistic(value: String, title: String) -> some View {
        VStack(spacing: 8) {
            Text(value)
                .font(.system(size: 28, weight: .semibold))

            Text(title)
                .font(.system(size: 14))
                .foregroundStyle(.white.opacity(0.55))
        }
        .frame(maxWidth: .infinity)
    }

    private var biography: some View {
        Text("This user has not added a bio yet.")
            .font(.system(size: 15))
            .foregroundStyle(.white.opacity(0.9))
            .lineSpacing(3)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background {
                RoundedRectangle(cornerRadius: 20)
                    .fill(.black.opacity(0.20))
            }
            .overlay {
                RoundedRectangle(cornerRadius: 20)
                    .stroke(.white.opacity(0.12), lineWidth: 1)
            }
    }

    private var creationsGrid: some View {
        LazyVGrid(columns: columns, spacing: 14) {
            ForEach(creations.indices, id: \.self) { index in
                Image(creations[index])
                    .resizable()
                    .scaledToFill()
                    .aspectRatio(0.85, contentMode: .fit)
                    .clipShape(
                        RoundedRectangle(cornerRadius: 20)
                    )
            }
        }
    }

    private func errorView(_ message: String) -> some View {
        VStack(spacing: 14) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 38))
                .foregroundStyle(.yellow)

            Text("Couldn’t load profile")
                .font(.title3.weight(.semibold))

            Text(message)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.7))
                .multilineTextAlignment(.center)

            Button("Try Again") {
                Task {
                    await loadProfile()
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(28)
    }
    
    @MainActor
    private func loadProfileImage(path: String?) async {
        guard let path, !path.isEmpty else {
            return
        }

        do {
            let imageURL = try await profilePictureService
                .createSignedProfilePictureURL(path: path)

            let (data, response) = try await URLSession.shared.data(
                from: imageURL
            )

            try Task.checkCancellation()

            guard let httpResponse = response as? HTTPURLResponse,
                  (200..<300).contains(httpResponse.statusCode)
            else {
                throw URLError(.badServerResponse)
            }

            guard let image = UIImage(data: data) else {
                throw ProfilePictureServiceError.invalidImage
            }

            profileImage = image
        } catch {
            guard !Task.isCancelled else {
                return
            }

            // Keep the profile visible using its existing placeholder.
            profileImage = nil

            #if DEBUG
            print("Public profile avatar failed:", error)
            print("Avatar path:", path)
            #endif
        }
    }
}
