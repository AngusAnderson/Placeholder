import SwiftUI

struct RelayLeaderboardPodium: View {
    // Input is the already-ranked server order. Only positive contributors.
    let entries: [RelayLeaderboard.Entry]
    private var first: RelayLeaderboard.Entry? { entries.first }
    private var second: RelayLeaderboard.Entry? { entries.count > 1 ? entries[1] : nil }
    private var third: RelayLeaderboard.Entry? { entries.count > 2 ? entries[2] : nil }
    private var highestRankCount: Int {
        entries.filter { $0.rank == 1 }.count
    }

    var body: some View {
        VStack(spacing: 16) {
            HStack(alignment: .bottom, spacing: 8) {
                column(second)
                column(first)
                column(third)
            }
            .padding(.top, 12)
            .padding(.horizontal, 4)
            if highestRankCount > 1 {
                Text("Tied contributions share a rank.")
                    .font(.caption).foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Leading contributors")
    }

    @ViewBuilder
    private func column(_ entry: RelayLeaderboard.Entry?) -> some View {
        if let entry {
            RelayPodiumColumn(entry: entry)
                .frame(maxWidth: .infinity)
        } else {
            VStack(spacing: 8) {
                Image(systemName: "person.crop.circle.badge.plus")
                    .font(.title2).foregroundStyle(.white.opacity(0.18))
                Text("Open spot").font(.caption2).foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 100)
            .background(Color.white.opacity(0.025), in: RoundedRectangle(cornerRadius: 16))
        }
    }
}

private struct RelayPodiumColumn: View {
    let entry: RelayLeaderboard.Entry
    private var color: Color { RelayLeaderboardStyle.rankColor(entry.rank) }
    private var pedestalHeight: CGFloat {
        // Equal rank receives equal height, even when records tie.
        switch entry.rank {
        case 1: return 142
        case 2: return 108
        default: return 82
        }
    }
    var body: some View {
        VStack(spacing: 0) {
            Group {
                if entry.rank == 1 {
                    Image(systemName: "crown.fill").foregroundStyle(color)
                } else {
                    Image(systemName: "sparkle").foregroundStyle(color.opacity(0.6))
                }
            }.font(.system(size: 18, weight: .semibold)).frame(height: 26)
            RelayLeaderboardAvatar(entry: entry, size: 64, color: color)
                .shadow(color: color.opacity(0.2), radius: 12)
                .padding(.bottom, 10)
            Text(entry.isCurrentUser ? "\(entry.displayName) · You" : entry.displayName)
                .font(.caption.weight(.semibold))
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .frame(height: 34, alignment: .top)
                .frame(maxWidth: .infinity)
            Text(RelayLeaderboardStyle.distance(entry.creditedMetres))
                .font(.caption.weight(.bold)).monospacedDigit()
                .foregroundStyle(color).padding(.bottom, 12)
            VStack(spacing: 0) {
                RelayPodiumTop().fill(color.opacity(0.34)).frame(height: 12)
                ZStack(alignment: .top) {
                    LinearGradient(
                        colors: [color.opacity(0.26), color.opacity(0.07)],
                        startPoint: .top, endPoint: .bottom
                    )
                    VStack(spacing: 7) {
                        Text(String(entry.rank))
                            .font(.system(size: 44, weight: .black, design: .rounded))
                            .foregroundStyle(color.opacity(0.9))
                        Text(String(format: "%.1f%%", entry.share * 100))
                            .font(.caption2.weight(.semibold)).foregroundStyle(.secondary)
                    }.padding(.top, 17)
                }
                .frame(height: pedestalHeight)
            }
            .clipShape(UnevenRoundedRectangle(topLeadingRadius: 10, topTrailingRadius: 10))
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Rank \(entry.rank), \(entry.displayName)\(entry.isCurrentUser ? ", you" : ""), \(RelayLeaderboardStyle.distance(entry.creditedMetres))\(entry.isCurrentMember ? "" : ", former member")")
    }
}

private struct RelayPodiumTop: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.width * 0.13, y: 0))
        p.addLine(to: CGPoint(x: rect.width * 0.87, y: 0))
        p.addLine(to: CGPoint(x: rect.width, y: rect.height))
        p.addLine(to: CGPoint(x: 0, y: rect.height))
        p.closeSubpath()
        return p
    }
}
