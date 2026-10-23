import SwiftUI
import Foundation

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
        return Array((model.leaderboard?.entries ?? []).filter { $0.creditedMetres > 0 }.prefix(3))
    }
    private var remainingEntries: [RelayLeaderboard.Entry] {
        let shown = Set(podiumEntries.map(\.id))
        return (model.leaderboard?.entries ?? []).filter { !shown.contains($0.id) }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                RelayLeaderboardStyle.background.ignoresSafeArea()
                LinearGradient(
                    colors: [Color.cyan.opacity(0.14), Color.clear, Color.clear],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                ).ignoresSafeArea()
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 22) {
                        header
                        if let error = teamModel.errorMessage {
                            errorCard(error, retry: { Task { await teamModel.load() } })
                        }
                        if selectedTeamID == nil {
                            ContentUnavailableView(
                                "Choose a Team", systemImage: "person.3",
                                description: Text("Select a team to see who is moving its Relay forward.")
                            ).frame(maxWidth: .infinity)
                        } else if let error = model.errorMessage {
                            errorCard(error, retry: { Task { await refreshLeaderboard() } })
                        } else if let board = model.leaderboard {
                            if let game = board.game {
                                RelayJourneySummary(game: game)
                                Picker("Leaderboard section", selection: $selectedPane) {
                                    ForEach(LeaderboardPane.allCases, id: \.self) { pane in
                                        Text(pane.rawValue).tag(pane)
                                    }
                                }.pickerStyle(.segmented)
                                if selectedPane == .standings {
                                    standings(board)
                                } else {
                                    yourStats(board)
                                }
                                if abs(board.attributionDifference) > 0.01 {
                                    Label(
                                        "The game total differs from the available member records by \(RelayLeaderboardStyle.distance(abs(board.attributionDifference))).",
                                        systemImage: "exclamationmark.triangle"
                                    ).font(.footnote).foregroundStyle(.orange)
                                }
                                footer
                            } else {
                                ContentUnavailableView(
                                    "No Relay Yet", systemImage: "flag.checkered",
                                    description: Text("Start a Relay in Team Details. Your team's contributors will appear here.")
                                ).frame(maxWidth: .infinity)
                            }
                        } else {
                            ProgressView("Loading contributions…")
                                .frame(maxWidth: .infinity).padding(.vertical, 50)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    .padding(.bottom, 28)
                    .frame(maxWidth: 640)
                    .frame(maxWidth: .infinity)
                }
                .refreshable {
                    await teamModel.load()
                    validateSelection()
                    await refreshLeaderboard()
                }
            }
            .navigationTitle("Leaderboard")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(RelayLeaderboardStyle.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .task {
                await teamModel.load()
                if selectedTeamID == nil { selectedTeamID = teamModel.teams.first?.id }
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
        .preferredColorScheme(.dark)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 7) {
                    Text("EVERY METRE MATTERS")
                        .font(.system(size: 10, weight: .bold)).tracking(1.5)
                        .foregroundStyle(.cyan)
                    Text("Move together.\nRise together.")
                        .font(.system(.title, design: .rounded, weight: .bold))
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 8)
                Image(systemName: "trophy.fill")
                    .font(.system(size: 36)).foregroundStyle(.cyan)
                    .frame(width: 72, height: 72)
                    .background(Color.cyan.opacity(0.08), in: RoundedRectangle(cornerRadius: 24))
                    .accessibilityHidden(true)
            }
            HStack {
                TeamSelectorView(
                    teams: teamModel.teams, isLoading: teamModel.isLoading,
                    hasLoaded: teamModel.hasLoaded, errorMessage: teamModel.errorMessage,
                    selection: $selectedTeamID, hint: "Choose team", maxWidth: 220,
                    onManageTeams: { showTeams = true },
                    onRetry: { Task { await teamModel.load() } }
                )
                Spacer(minLength: 4)
                Text("THIS RELAY").font(.system(size: 9, weight: .bold)).tracking(0.5)
                    .foregroundStyle(.secondary).lineLimit(1)
            }
        }
    }

    @ViewBuilder
    private func standings(_ board: RelayLeaderboard) -> some View {
        if !podiumEntries.isEmpty {
            RelayLeaderboardPodium(entries: podiumEntries)
        }
        HStack {
            Text(podiumEntries.isEmpty ? "Team standings" : "The rest of the team")
                .font(.headline)
            Spacer()
            Text("\(board.entries.count) contributors / members")
                .font(.caption2).foregroundStyle(.secondary)
        }
        if board.entries.allSatisfy({ $0.creditedMetres <= 0 }) {
            Text("The podium is waiting. Eligible activity will start the rankings.")
                .font(.footnote).foregroundStyle(.secondary)
        }
        if !remainingEntries.isEmpty {
            LazyVStack(spacing: 12) {
                ForEach(remainingEntries) { entry in RelayStandingRow(entry: entry) }
            }
        } else if !podiumEntries.isEmpty {
            Text("Everyone with a recorded contribution is on the podium.")
                .font(.footnote).foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private func yourStats(_ board: RelayLeaderboard) -> some View {
        if let entry = board.entries.first(where: \.isCurrentUser) {
            RelayStandingRow(entry: entry)
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                RelayStatTile(title: "Your contribution", value: RelayLeaderboardStyle.distance(entry.creditedMetres), symbol: "figure.walk")
                RelayStatTile(title: "Your rank", value: entry.rank > 0 ? "#\(entry.rank)" : "Not ranked", symbol: "trophy")
                RelayStatTile(title: "Share of team distance", value: String(format: "%.1f%%", entry.share * 100), symbol: "chart.pie")
                RelayStatTile(title: "Members / contributors", value: String(board.entries.count), symbol: "person.3")
            }
            Text("These numbers are for this Relay only. Distances appear after eligible activity has synced and been credited.")
                .font(.footnote).foregroundStyle(.secondary)
        } else {
            ContentUnavailableView("No Personal Entry", systemImage: "person.crop.circle",
                description: Text("Refresh to load your contribution for this team."))
        }
    }

    private var footer: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Rankings use credited distance, not raw steps. Equal distances share a rank.")
                .font(.caption).foregroundStyle(.secondary)
            HStack {
                if model.isLoading { ProgressView().controlSize(.small) }
                if let updated = model.lastUpdated {
                    Text("Updated \(updated, style: .time)")
                        .font(.caption2).foregroundStyle(.secondary)
                }
            }
        }
    }
    private func errorCard(_ message: String, retry: @escaping () -> Void) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Couldn't refresh", systemImage: "exclamationmark.triangle")
                .font(.headline).foregroundStyle(.orange)
            Text(message).font(.footnote).foregroundStyle(.secondary)
            Button("Try Again", action: retry).buttonStyle(.bordered)
        }
        .padding(18).frame(maxWidth: .infinity, alignment: .leading)
        .background(RelayLeaderboardStyle.card, in: RoundedRectangle(cornerRadius: 20))
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
