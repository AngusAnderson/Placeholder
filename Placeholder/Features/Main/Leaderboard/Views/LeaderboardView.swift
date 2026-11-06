import Foundation
import SwiftUI

struct LeaderboardView: View {
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var teamModel = TeamViewModel()
    @State private var model = RelayLeaderboardViewModel()
    @State private var selectedTeamID: Int64?
    @State private var showTeams = false
    @State private var selectedPane: LeaderboardPane = .standings

    private enum LeaderboardPane: String, CaseIterable {
        case standings = "Standings"
        case you = "Your stats"
    }
    private var podiumEntries: [RelayLeaderboard.Entry] {
        guard !dynamicTypeSize.isAccessibilitySize else { return [] }
        return Array((model.leaderboard?.entries ?? [])
            .filter { $0.creditedMetres > 0 }.prefix(3))
    }
    private var remainingEntries: [RelayLeaderboard.Entry] {
        let shown = Set(podiumEntries.map(\.id))
        return (model.leaderboard?.entries ?? []).filter { !shown.contains($0.id) }
    }
    private var hasGame: Bool { model.leaderboard?.game != nil }

    var body: some View {
        NavigationStack {
            MapPageScaffold {
                ScrollView(showsIndicators: false) {
                    LazyVStack(alignment: .leading, spacing: 20) {
                        header
                        if let error = teamModel.errorMessage {
                            errorCard(error) { Task { await teamModel.load() } }
                        }
                        if selectedTeamID == nil {
                            emptyCard("Choose a team", symbol: "person.3",
                                message: "Select a team to see its Relay contributions.")
                        } else if let error = model.errorMessage {
                            errorCard(error) { Task { await refreshLeaderboard() } }
                        } else if let board = model.leaderboard {
                            if let game = board.game {
                                RelayJourneySummary(game: game)
                                if selectedPane == .standings {
                                    standings(board)
                                } else {
                                    yourStats(board)
                                }
                                if abs(board.attributionDifference) > 0.01 {
                                    Label(
                                        "The game total differs from available member records by \(RelayLeaderboardStyle.distance(abs(board.attributionDifference))).",
                                        systemImage: "exclamationmark.triangle"
                                    )
                                    .font(.footnote).foregroundStyle(.orange)
                                    .padding(16).frame(maxWidth: .infinity, alignment: .leading)
                                    .mapContentPanel()
                                }
                                footer
                            } else {
                                emptyCard("No Relay yet", symbol: "flag.checkered",
                                    message: "Start a Relay in Team Details. Your team's contributions will appear here.")
                            }
                        } else {
                            ProgressView("Loading contributions…")
                                .frame(maxWidth: .infinity).padding(30)
                                .mapContentPanel()
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 24)
                    .frame(maxWidth: 640)
                    .frame(maxWidth: .infinity)
                }
                .contentMargins(
                    .bottom,
                    44,
                    for: .scrollContent
                )
                .refreshable {
                    await teamModel.load()
                    validateSelection()
                    await refreshLeaderboard()
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .task {
                if teamModel.teams.isEmpty {
                    await teamModel.load()
                }
                if selectedTeamID == nil {
                    selectedTeamID = teamModel.teams.first?.id
                }
            }
            .task(id: selectedTeamID) { await model.watch(teamID: selectedTeamID) }
            .onChange(of: teamModel.teams.map(\.id)) { _, _ in validateSelection() }
            .onChange(of: scenePhase) { _, phase in
                if phase == .active { Task { await refreshLeaderboard() } }
            }
            .onReceive(NotificationCenter.default.publisher(for: .relayActivityDidSync)) { _ in
                Task { await refreshLeaderboard() }
            }
            .sheet(isPresented: $showTeams, onDismiss: {
                Task {
                    await teamModel.load()
                    validateSelection()
                    if selectedTeamID == nil { selectedTeamID = teamModel.teams.first?.id }
                    await refreshLeaderboard()
                }
            }) { TeamView() }
        }
    }

    private var header: some View {
        VStack(spacing: 24) {
            Text("Leaderboard")
                .font(.largeTitle.weight(.bold))
                .frame(maxWidth: .infinity)
                .accessibilityAddTraits(.isHeader)
                .padding(.top, 8)

            MapGlassControlGroup {
                VStack(alignment: .leading, spacing: 12) {
                    TeamSelectorView(
                        teams: teamModel.teams,
                        isLoading: teamModel.isLoading,
                        hasLoaded: teamModel.hasLoaded,
                        errorMessage: teamModel.errorMessage,
                        selection: $selectedTeamID,
                        hint: "Choose team",
                        maxWidth: .infinity,
                        onManageTeams: { showTeams = true },
                        onRetry: { Task { await teamModel.load() } }
                    )
                    if hasGame { paneSelector }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private var paneSelector: some View {
        HStack(spacing: 4) {
            ForEach(LeaderboardPane.allCases, id: \.self) { pane in
                Button {
                    selectedPane = pane
                } label: {
                    Text(pane.rawValue)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(selectedPane == pane ? Color.primary : Color.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 11)
                        .background {
                            if selectedPane == pane {
                                RoundedRectangle(cornerRadius: 15, style: .continuous)
                                    .fill(Color.cyan.opacity(0.18))
                            }
                        }
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(selectedPane == pane ? .isSelected : [])
            }
        }
        .padding(5)
        .mapControlGlass(cornerRadius: 20)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Leaderboard section")
    }

    @ViewBuilder
    private func standings(_ board: RelayLeaderboard) -> some View {
        if !podiumEntries.isEmpty { RelayLeaderboardPodium(entries: podiumEntries) }
        if !remainingEntries.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .firstTextBaseline) {
                    Text(podiumEntries.isEmpty ? "Team standings" : "More contributors")
                        .font(.headline)
                    Spacer()
                    Text("\(board.entries.count) listed")
                        .font(.caption).foregroundStyle(.secondary)
                }
                if board.entries.allSatisfy({ $0.creditedMetres <= 0 }) {
                    Text("Eligible activity will start the rankings.")
                        .font(.footnote).foregroundStyle(.secondary)
                }
                LazyVStack(spacing: 10) {
                    ForEach(remainingEntries) { entry in RelayStandingRow(entry: entry) }
                }
            }
        } else if board.entries.isEmpty {
            emptyCard("No contributions yet", symbol: "figure.walk",
                message: "Eligible synced activity will appear here.")
        }
    }

    @ViewBuilder
    private func yourStats(_ board: RelayLeaderboard) -> some View {
        if let entry = board.entries.first(where: \.isCurrentUser) {
            RelayStandingRow(entry: entry)
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 145), spacing: 12)], spacing: 12) {
                RelayStatTile(title: "Your contribution", value: RelayLeaderboardStyle.distance(entry.creditedMetres), symbol: "figure.walk")
                RelayStatTile(title: "Your rank", value: entry.rank > 0 ? "#\(entry.rank)" : "Not ranked", symbol: "trophy")
                RelayStatTile(title: "Share of team distance", value: String(format: "%.1f%%", entry.share * 100), symbol: "chart.pie")
                RelayStatTile(title: "Members / contributors", value: String(board.entries.count), symbol: "person.3")
            }
        } else {
            emptyCard("No personal entry", symbol: "person.crop.circle",
                message: "Refresh to load your contribution for this team.")
        }
    }

    private var footer: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Credited distance for this Relay. Equal distances share a rank.")
                .font(.caption).foregroundStyle(.secondary)
            HStack(spacing: 8) {
                if model.isLoading { ProgressView().controlSize(.small) }
                if let updated = model.lastUpdated {
                    Text("Updated \(updated, style: .time)")
                        .font(.caption2).foregroundStyle(.secondary)
                }
            }
        }
        .padding(16).frame(maxWidth: .infinity, alignment: .leading)
        .mapContentPanel(cornerRadius: 20)
    }
    private func errorCard(_ message: String, retry: @escaping () -> Void) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Couldn't refresh", systemImage: "exclamationmark.triangle")
                .font(.headline).foregroundStyle(.orange)
            Text(message).font(.footnote).foregroundStyle(.secondary)
            if #available(iOS 26.0, *) {
                Button("Try again", action: retry).buttonStyle(.glass)
            } else {
                Button("Try again", action: retry).buttonStyle(.bordered)
            }
        }
        .padding(18).frame(maxWidth: .infinity, alignment: .leading)
        .mapContentPanel()
    }
    private func emptyCard(_ title: String, symbol: String, message: String) -> some View {
        ContentUnavailableView(title, systemImage: symbol, description: Text(message))
            .frame(maxWidth: .infinity).mapContentPanel()
    }
    @MainActor
    private func refreshLeaderboard() async {
        guard let selectedTeamID else { return }
        await model.refresh(teamID: selectedTeamID)
    }
    private func validateSelection() {
        guard teamModel.hasLoaded, teamModel.errorMessage == nil else { return }
        if let selectedTeamID, !teamModel.teams.contains(where: { $0.id == selectedTeamID }) {
            self.selectedTeamID = nil
        }
    }
}
