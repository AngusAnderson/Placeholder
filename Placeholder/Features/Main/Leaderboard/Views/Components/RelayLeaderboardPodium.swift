import SwiftUI

struct RelayLeaderboardPodium: View {
    let entries: [RelayLeaderboard.Entry]
    private var first: RelayLeaderboard.Entry? { entries.first }
    private var second: RelayLeaderboard.Entry? { entries.count > 1 ? entries[1] : nil }
    private var third: RelayLeaderboard.Entry? { entries.count > 2 ? entries[2] : nil }
    private var hasTopTie: Bool { entries.filter { $0.rank == 1 }.count > 1 }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Leading contributors", systemImage: "trophy")
                .font(.headline)
            HStack(alignment: .bottom, spacing: 8) {
                column(second)
                column(first)
                column(third)
            }
            if hasTopTie {
                Text("Equal contributions share a rank.")
                    .font(.caption).foregroundStyle(.secondary)
            }
        }
        .padding(18).mapContentPanel(cornerRadius: 26)
        .accessibilityElement(children: .contain)
    }

    @ViewBuilder
    private func column(_ entry: RelayLeaderboard.Entry?) -> some View {
        if let entry {
            MapRelayPodiumColumn(entry: entry).frame(maxWidth: .infinity)
        } else {
            VStack(spacing: 8) {
                Image(systemName: "person.crop.circle").font(.title2)
                Text("Open spot").font(.caption2)
            }
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity).frame(height: 80)
        }
    }
}

private struct MapRelayPodiumColumn: View {
    let entry: RelayLeaderboard.Entry
    private var color: Color { RelayLeaderboardStyle.rankColor(entry.rank) }
    private var pedestalHeight: CGFloat {
        switch entry.rank {
        case 1: return 82
        case 2: return 62
        default: return 46
        }
    }
    var body: some View {
        VStack(spacing: 0) {
            Image(systemName: entry.rank == 1 ? "crown.fill" : "medal")
                .font(.caption.weight(.semibold)).foregroundStyle(color)
                .frame(height: 24)
            RelayLeaderboardAvatar(entry: entry, size: 52, color: color)
                .padding(.bottom, 10)
            Text(entry.displayName)
                .font(.caption.weight(.semibold)).multilineTextAlignment(.center)
                .lineLimit(2).frame(height: 34, alignment: .top)
            Text(RelayLeaderboardStyle.distance(entry.creditedMetres))
                .font(.caption2.weight(.bold)).monospacedDigit()
                .foregroundStyle(.secondary).padding(.bottom, 10)
            VStack(spacing: 5) {
                Text(String(entry.rank))
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundStyle(color)
                Text(String(format: "%.1f%%", entry.share * 100))
                    .font(.caption2).foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity).frame(height: pedestalHeight, alignment: .top)
            .padding(.top, 12)
            .background {
                UnevenRoundedRectangle(topLeadingRadius: 14, topTrailingRadius: 14)
                    .fill(LinearGradient(colors: [color.opacity(0.18), color.opacity(0.025)],
                        startPoint: .top, endPoint: .bottom))
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Rank \(entry.rank), \(entry.displayName)\(entry.isCurrentUser ? ", you" : ""), \(RelayLeaderboardStyle.distance(entry.creditedMetres))\(entry.isCurrentMember ? "" : ", former member")")
    }
}
