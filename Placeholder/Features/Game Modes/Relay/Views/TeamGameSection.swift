import SwiftUI

struct TeamGameSection: View {
    let teamID: Int64
    let isOwner: Bool
    let model: RelayViewModel
    @Binding var showCreateRelay: Bool
    @State private var confirmCancel = false
    @State private var isCancelling = false
    @State private var actionError: String?
    private let service = RelayService()

    var body: some View {
        Section("Team Game") {
            if let game = model.game {
                Label("Relay", systemImage: "flag.checkered").font(.headline)
                Text("\(game.startName) → \(game.finishName)").foregroundStyle(.secondary)
                ProgressView(value: game.progress).tint(.cyan)
                Text(String(format: "%.2f / %.2f km", game.creditedMetres / 1000, game.targetMetres / 1000))
                    .font(.subheadline)
                Text(game.status == .completed ? "Completed" : "In progress")
                    .font(.caption).foregroundStyle(.secondary)
            } else if model.isLoading {
                ProgressView("Loading team game…")
            } else if model.errorMessage == nil {
                Text("This team has no active game.").foregroundStyle(.secondary)
            }
            if let error = model.errorMessage {
                Text(error).font(.footnote).foregroundStyle(.red)
                Button("Try Again") { Task { await model.refresh(teamID: teamID) } }
                    .disabled(model.isLoading || isCancelling)
            }
            if let actionError { Text(actionError).font(.footnote).foregroundStyle(.red) }
            if isOwner && model.errorMessage == nil {
                if model.game?.status == .active {
                    Button("Cancel Current Game", role: .destructive) { confirmCancel = true }
                        .disabled(model.isLoading || isCancelling)
                } else {
                    Menu {
                        Button("Relay — Choose Start and Destination") { showCreateRelay = true }
                    } label: {
                        Label("Choose Team Game", systemImage: "play.circle.fill")
                    }
                    .disabled(model.isLoading || isCancelling)
                }
            } else if !isOwner && model.game == nil && model.errorMessage == nil && !model.isLoading {
                Text("The team owner can choose a game.").font(.footnote).foregroundStyle(.secondary)
            }
            if isCancelling { ProgressView("Cancelling…") }
        }
        .task(id: teamID) { await model.watch(teamID: teamID) }
        .alert("Cancel this Relay?", isPresented: $confirmCancel) {
            Button("Keep Playing", role: .cancel) {}
            Button("Cancel Game", role: .destructive) { Task { await cancel() } }
        } message: {
            Text("The current game will stop. Its history is preserved, but a new game starts from zero and does not reuse old activity.")
        }
    }
    @MainActor
    private func cancel() async {
        guard !isCancelling else { return }
        isCancelling = true
        actionError = nil
        defer { isCancelling = false }
        do { try await service.cancelGame(teamID: teamID) }
        catch { actionError = error.localizedDescription; return }
        await model.refresh(teamID: teamID)
    }
}
