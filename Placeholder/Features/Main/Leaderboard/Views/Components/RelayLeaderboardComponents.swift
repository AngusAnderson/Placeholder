import SwiftUI

enum RelayLeaderboardStyle {
    static let accent = Color.cyan
    static let background = Color(uiColor: .systemBackground)
    static let card = Color(uiColor: .secondarySystemBackground)
    static func distance(_ metres: Double) -> String {
        metres < 1000 ? String(format: "%.0f m", metres) : String(format: "%.2f km", metres / 1000)
    }
    static func rankColor(_ rank: Int) -> Color {
        switch rank {
        case 1: return .orange
        case 2: return Color(red: 0.47, green: 0.57, blue: 0.67)
        case 3: return Color(red: 0.70, green: 0.43, blue: 0.26)
        default: return .cyan
        }
    }
}

struct RelayLeaderboardAvatar: View {
    let entry: RelayLeaderboard.Entry
    var size: CGFloat = 44
    var color: Color = .cyan
    @State private var imageURL: URL?
    private let pictureService = ProfilePictureService()

    var body: some View {
        ZStack {
            Circle().fill(LinearGradient(
                colors: [color.opacity(0.85), color.opacity(0.5)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            ))
            Text(entry.initials)
                .font(.system(size: size * 0.30, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
            if let imageURL {
                AsyncImage(url: imageURL) { phase in
                    switch phase {
                    case .success(let image): image.resizable().scaledToFill()
                    case .empty, .failure: Color.clear
                    @unknown default: Color.clear
                    }
                }.frame(width: size, height: size).clipped()
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .overlay { Circle().stroke(color.opacity(0.8), lineWidth: 2) }
        .task(id: entry.profilePicturePath) { await loadPhoto() }
        .accessibilityHidden(true)
    }
    @MainActor
    private func loadPhoto() async {
        imageURL = nil
        guard let path = entry.profilePicturePath?.trimmingCharacters(in: .whitespacesAndNewlines),
              !path.isEmpty else { return }
        do {
            let url = try await pictureService.createSignedProfilePictureURL(path: path, expiresIn: 3600)
            try Task.checkCancellation()
            imageURL = url
        } catch {
            guard !Task.isCancelled else { return }
            #if DEBUG
            print("[Leaderboard Avatar] Could not sign photo for", entry.userID, ":", error)
            #endif
        }
    }
}

struct RelayStandingRow: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    let entry: RelayLeaderboard.Entry
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(entry.rank > 0 ? String(entry.rank) : "—")
                .font(.title3.weight(.bold)).monospacedDigit()
                .foregroundStyle(entry.rank > 0 && entry.rank <= 3
                    ? RelayLeaderboardStyle.rankColor(entry.rank) : Color.secondary)
                .frame(width: 25).padding(.top, 10)
            if !dynamicTypeSize.isAccessibilitySize { RelayLeaderboardAvatar(entry: entry) }
            VStack(alignment: .leading, spacing: 8) {
                Text(entry.displayName + (entry.isCurrentUser ? " · You" : ""))
                    .font(.subheadline.weight(.semibold))
                    .fixedSize(horizontal: false, vertical: true)
                if !entry.isCurrentMember {
                    Text("Former member").font(.caption2).foregroundStyle(.secondary)
                }
                HStack(alignment: .firstTextBaseline) {
                    Text(RelayLeaderboardStyle.distance(entry.creditedMetres))
                        .font(.subheadline.weight(.bold)).monospacedDigit()
                    Spacer()
                    Text(String(format: "%.1f%%", entry.share * 100))
                        .font(.caption).foregroundStyle(.secondary).monospacedDigit()
                }
                ProgressView(value: min(max(entry.share, 0), 1)).tint(.cyan)
            }
        }
        .padding(16).frame(maxWidth: .infinity, alignment: .leading)
        .mapContentPanel(cornerRadius: 22)
        .overlay {
            if entry.isCurrentUser {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(Color.cyan.opacity(0.4), lineWidth: 1)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(entry.displayName)\(entry.isCurrentUser ? ", you" : ""), \(entry.rank > 0 ? "rank \(entry.rank)" : "not ranked"), \(RelayLeaderboardStyle.distance(entry.creditedMetres)), \(String(format: "%.1f", entry.share * 100)) percent of team distance\(entry.isCurrentMember ? "" : ", former member")")
    }
}

struct RelayStatTile: View {
    let title: String
    let value: String
    let symbol: String
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: symbol).foregroundStyle(.cyan)
            Text(value).font(.title3.weight(.bold)).monospacedDigit()
                .fixedSize(horizontal: false, vertical: true)
            Text(title).font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(16).mapContentPanel(cornerRadius: 22)
    }
}

struct RelayJourneySummary: View {
    let game: RelayLeaderboard.Game
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label(game.status == "completed" ? "Completed Relay" : "Current Relay", systemImage: "flag.checkered")
                    .font(.caption.weight(.semibold)).foregroundStyle(.secondary)
                Spacer()
                Text(String(format: "%.0f%%", game.progress * 100))
                    .font(.caption.weight(.bold)).monospacedDigit()
            }
            Text("\(game.startName) → \(game.finishName)")
                .font(.headline).fixedSize(horizontal: false, vertical: true)
            ProgressView(value: game.progress).tint(.cyan)
            Text("\(RelayLeaderboardStyle.distance(game.creditedMetres)) of \(RelayLeaderboardStyle.distance(game.targetMetres))")
                .font(.caption).foregroundStyle(.secondary).monospacedDigit()
        }
        .padding(18).frame(maxWidth: .infinity, alignment: .leading)
        .mapContentPanel()
    }
}
