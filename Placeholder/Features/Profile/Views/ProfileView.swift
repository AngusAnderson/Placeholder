import SwiftUI

struct ProfileView: View {
    
    @Environment(UserProfileStore.self) private var userProfileStore
    
    @Environment(\.dismiss) private var dismiss
    @State private var isFollowing = false
    
    @State private var showUserSearch = false
    @State private var selectedPublicProfile: UserSearchResult?

    var openSettings: () -> Void = {}
    
    @State private var showSettings = false

    private let columns = [
        GridItem(.flexible(), spacing: 14),
        GridItem(.flexible(), spacing: 14)
    ]

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .top) {
                profileBackground(size: geometry.size)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 22) {
                        Color.clear
                            .frame(height: geometry.size.height * 0.47)
                            .accessibilityHidden(true)

                        identity

                        actions

                        statistics

                        biography
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 30)
                    .frame(maxWidth: .infinity)
                }

                topControls
                    .padding(.horizontal, 24)
                    .padding(.top, 12)
            }
            .frame(
                width: geometry.size.width,
                height: geometry.size.height
            )
        }
        .background(Color.black.ignoresSafeArea())
        .foregroundStyle(.white)
        .preferredColorScheme(.dark)
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .toolbar(.hidden, for: .navigationBar)
        .overlay {
            if showUserSearch {
                UserSearchOverlay(
                    onClose: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            showUserSearch = false
                        }
                    },
                    onSelect: { user in
                        withAnimation(.easeInOut(duration: 0.2)) {
                            showUserSearch = false
                        }

                        DispatchQueue.main.async {
                            selectedPublicProfile = user
                        }
                    }
                )
                .transition(
                    .opacity.combined(with: .scale(scale: 0.97))
                )
                .zIndex(10)
            }
        }
        .navigationDestination(item: $selectedPublicProfile) { user in
            PublicProfileView(profileID: user.id)
        }
    }

    // MARK: - Background

    private func profileBackground(size: CGSize) -> some View {
        ZStack {
            if let profileImage = userProfileStore.profileImage {
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
                .frame(width: size.width, height: size.height)
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
                    .init(color: .clear, location: 0.3),
                    .init(
                        color: .black.opacity(0.15),
                        location: 0.48
                    ),
                    .init(
                        color: .black.opacity(0.55),
                        location: 0.72
                    ),
                    .init(
                        color: .black.opacity(0.8),
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
                withAnimation(.easeInOut(duration: 0.2)) {
                    showUserSearch = true
                }
            } label: {
                circularIcon("magnifyingglass")
            }
            .accessibilityLabel("Search users")

            Spacer()

            Menu {
                Button {
                    showSettings = true
                } label: {
                    Label("Settings", systemImage: "gear")
                }

                Button {
                    openSettings()
                } label: {
                    Label("Credits", systemImage: "info.circle")
                }
            } label: {
                circularIcon("ellipsis")
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
            .accessibilityLabel("Profile settings and credits")
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
                    .stroke(.white.opacity(0.1), lineWidth: 1)
            }
    }

    // MARK: - Identity

    private var identity: some View {
        VStack(spacing: 8) {
            Text(userProfileStore.displayName)
                .font(.system(size: 38, weight: .semibold))
                .multilineTextAlignment(.center)
            
            Text("@" + (userProfileStore.username ?? "Error"))
                .font(.system(size: 18))
                .foregroundStyle(.white.opacity(0.55))
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Actions

    private var actions: some View {
        HStack(spacing: 14) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isFollowing.toggle()
                }
            } label: {
                Text("Edit Profile")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Color.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background {
                        Capsule()
                            .fill(Color.white)
                    }
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Statistics

    private var statistics: some View {
        HStack {
            statistic(value: "1", title: "Following")
            statistic(value: "2K", title: "Followers")
            statistic(value: "124K", title: "Steps")
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

    // MARK: - Biography

    private var biography: some View {
        // Eventaully will be replaced with a bio or status set by the user in the settings.
        // Currently just pseudotext
        Text(
            "'No Michael! No Michael, no! That was so not right!'"
        )
        .font(.system(size: 15))
        .foregroundStyle(.white.opacity(0.9))
        .lineSpacing(3)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background {
            RoundedRectangle(cornerRadius: 20)
                .fill(.black.opacity(0.2))
        }
        .overlay {
            RoundedRectangle(cornerRadius: 20)
                .stroke(.white.opacity(0.12), lineWidth: 1)
        }
    }
}
