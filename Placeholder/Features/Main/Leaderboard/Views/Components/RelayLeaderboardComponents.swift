import SwiftUI

// Shared styling for the redesigned leaderboard views.
enum RelayLeaderboardStyle {
    static let background = Color(red: 0.035, green: 0.055, blue: 0.085)
    static let card = Color(red: 0.085, green: 0.11, blue: 0.15)
    static let accent = Color.cyan
    static func distance(_ metres: Double) -> String {
        metres < 1000
            ? String(format: "%.0f m", metres)
            : String(format: "%.2f km", metres / 1000)
    }
    static func rankColor(_ rank: Int) -> Color {
        switch rank {
        case 1: return Color(red: 1, green: 0.78, blue: 0.30)
        case 2: return Color(red: 0.72, green: 0.84, blue: 0.94)
        case 3: return Color(red: 0.91, green: 0.58, blue: 0.35)
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
            // Visible while loading, when no photo exists, or on failure.
            Circle().fill(LinearGradient(
                colors: [color.opacity(0.65), color.opacity(0.12)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            ))
            Text(entry.initials)
                .font(.system(size: size * 0.30, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            if let imageURL {
                AsyncImage(url: imageURL) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().scaledToFill()
                    case .empty:
                        Color.clear
                    case .failure:
                        Color.clear
                    @unknown default:
                        Color.clear
                    }
                }
                .frame(width: size, height: size)
                .clipped()
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
        guard let path = entry.profilePicturePath?
            .trimmingCharacters(in: .whitespacesAndNewlines),
              !path.isEmpty else { return }
        do {
            let url = try await pictureService.createSignedProfilePictureURL(
                path: path,
                expiresIn: 3600
            )
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
    let entry: RelayLeaderboard.Entry
    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Text(entry.rank > 0 ? String(entry.rank) : "—")
                .font(.system(size: 30, weight: .black, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(entry.rank > 0 && entry.rank <= 3
                    ? RelayLeaderboardStyle.rankColor(entry.rank).opacity(0.75)
                    : Color.white.opacity(0.25))
                .frame(minWidth: 28)
            RelayLeaderboardAvatar(entry: entry)
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Text(entry.displayName).font(.subheadline.weight(.semibold)).lineLimit(2)
                    if entry.isCurrentUser {
                        Text("YOU").font(.system(size: 9, weight: .bold))
                            .foregroundStyle(.cyan)
                            .padding(.horizontal, 6).padding(.vertical, 3)
                            .background(Color.cyan.opacity(0.12), in: Capsule())
                    }
                }
                if !entry.isCurrentMember {
                    Text("Former member").font(.caption2).foregroundStyle(.secondary)
                }
                ProgressView(value: min(max(entry.share, 0), 1)).tint(.cyan)
                Text(String(format: "%.1f%% of team distance", entry.share * 100))
                    .font(.caption2).foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
            Text(RelayLeaderboardStyle.distance(entry.creditedMetres))
                .font(.subheadline.weight(.bold)).monospacedDigit()
                .fixedSize(horizontal: true, vertical: false)
        }
        .padding(14)
        .background(RelayLeaderboardStyle.card, in: RoundedRectangle(cornerRadius: 20))
        .overlay {
            RoundedRectangle(cornerRadius: 20)
                .stroke(entry.isCurrentUser ? Color.cyan.opacity(0.5) : Color.white.opacity(0.055), lineWidth: 1)
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
            Text(title).font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(RelayLeaderboardStyle.card, in: RoundedRectangle(cornerRadius: 20))
    }
}

struct RelayJourneySummary: View {
    let game: RelayLeaderboard.Game
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label(game.status == "completed" ? "COMPLETED RELAY" : "CURRENT RELAY",
                      systemImage: "flag.checkered")
                    .font(.system(size: 10, weight: .bold)).tracking(1.2)
                    .foregroundStyle(.cyan)
                Spacer()
                Text(String(format: "%.0f%%", game.progress * 100))
                    .font(.caption.weight(.bold)).monospacedDigit()
            }
            Text("\(game.startName) → \(game.finishName)").font(.headline)
            ProgressView(value: game.progress).tint(.cyan)
            HStack {
                Text(RelayLeaderboardStyle.distance(game.creditedMetres)).foregroundStyle(.white)
                Text("of \(RelayLeaderboardStyle.distance(game.targetMetres))").foregroundStyle(.secondary)
                Spacer()
            }.font(.caption.weight(.medium)).monospacedDigit()
        }
        .padding(18)
        .background(RelayLeaderboardStyle.card.opacity(0.85), in: RoundedRectangle(cornerRadius: 22))
        .overlay { RoundedRectangle(cornerRadius: 22).stroke(Color.white.opacity(0.06), lineWidth: 1) }
    }
}
