import SwiftUI


// Currently not in use as this is for other peoples profiles after searching for them.

struct PublicProfileView: View {
    
    @Environment(UserProfileStore.self) private var userProfileStore
    
    @Environment(\.dismiss) private var dismiss
    @State private var isFollowing = false

    var onMessage: () -> Void = {}

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

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 22) {
                        Color.clear
                            .frame(height: geometry.size.height * 0.47)
                            .accessibilityHidden(true)

                        identity

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
            .frame(
                width: geometry.size.width,
                height: geometry.size.height
            )
        }
        .background(Color.black.ignoresSafeArea())
        .foregroundStyle(.white)
        .preferredColorScheme(.dark)
        .toolbar(.hidden, for: .navigationBar)
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
            

            Spacer()

            Menu {
                Button {
                    onMessage()
                } label: {
                    Label("Settings", systemImage: "gear")
                }

                Button {
                    onMessage()
                } label: {
                    Label("Credits", systemImage: "info.circle")
                }
            } label: {
                circularIcon("ellipsis")
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
                Text(isFollowing ? "Following" : "Follow")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(
                        isFollowing ? Color.white : Color.black
                    )
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background {
                        Capsule()
                            .fill(
                                isFollowing
                                    ? Color.white.opacity(0.15)
                                    : Color.white
                            )
                    }
                    .overlay {
                        Capsule()
                            .stroke(
                                .white.opacity(isFollowing ? 0.2 : 0),
                                lineWidth: 1
                            )
                    }
            }

            Button(action: onMessage) {
                Image(systemName: "bubble.left.and.bubble.right.fill")
                    .font(.system(size: 21))
                    .frame(width: 56, height: 56)
                    .background(
                        .white.opacity(0.05),
                        in: Circle()
                    )
                    .overlay {
                        Circle()
                            .stroke(.white.opacity(0.15), lineWidth: 1)
                    }
            }
            .accessibilityLabel("Send message")
        }
        .buttonStyle(.plain)
    }

    // MARK: - Statistics

    private var statistics: some View {
        HStack {
            statistic(value: "252", title: "Following")
            statistic(value: "24K", title: "Followers")
            statistic(value: "732", title: "Creations")
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
        Text(
            "Designer focused on creating impactful, "
            + "user-centred digital experiences and branding."
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

    // MARK: - Creations

    private var creationsGrid: some View {
        LazyVGrid(columns: columns, spacing: 14) {
            ForEach(creations.indices, id: \.self) { index in
                Color.clear
                    .aspectRatio(0.85, contentMode: .fit)
                    .overlay {
                        Image(creations[index])
                            .resizable()
                            .scaledToFill()
                    }
                    .clipShape(
                        RoundedRectangle(cornerRadius: 20)
                    )
            }
        }
    }
}
