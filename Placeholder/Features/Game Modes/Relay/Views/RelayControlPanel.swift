import SwiftUI

struct RelayControlPanel: View {
    let teamID: Int64
    let isOwner: Bool
    let model: RelayViewModel
    var allowsStartingGame: Bool = false
    private let recorder = RelayActivityRecorder.shared
    @State private var confirmDiscard = false
    @State private var showContributions = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let game = model.game {
                HStack {
                    Text("Relay · \(game.startName) → \(game.finishName)").font(.headline)
                    Spacer()
                    Button { showContributions = true } label: {
                        Image(systemName: "person.3.fill")
                    }
                    .accessibilityLabel("Team contributions")
                }
                ProgressView(value: game.progress).tint(.cyan)
                Text(String(format: "%.2f / %.2f km · %@", game.creditedMetres / 1000,
                    game.targetMetres / 1000, game.status == .completed ? "Completed" : "Shared progress"))
                    .font(.caption)
                Text("Checkpoints: " + [25, 50, 75].map {
                    "\($0)%" + (game.checkpoints.contains($0) ? " ✓" : "")
                }.joined(separator: "  ")).font(.caption)
                if game.status == .active && recorder.draft == nil && recorder.pending == nil {
                    Button("Start Walk / Run") {
                        Task { await recorder.start(game: game) }
                    }
                    .buttonStyle(.borderedProminent).disabled(recorder.isBusy)
                }
            } else if model.isLoading {
                ProgressView("Loading Relay…")
            } else if model.errorMessage == nil {
                Text("No active Relay").font(.headline)
            }

            if let draft = recorder.draft {
                Text(draft.gameID == model.game?.id
                     ? "Recording for this Relay"
                     : "Recording for another Relay (team \(draft.teamID))")
                    .font(.caption).foregroundStyle(.secondary)
                HStack {
                    Button("Sync Now") { Task { await recorder.sync() } }
                    Button(draft.stopAt == nil ? "Finish & Sync" : "Retry Finish") {
                        Task { await recorder.sync(finish: true) }
                    }
                    Button(role: .destructive) { confirmDiscard = true } label: {
                        Image(systemName: "trash")
                    }
                }
                .buttonStyle(.bordered).disabled(recorder.isBusy)
            }
            if recorder.isBusy { ProgressView("Processing activity…") }
            if let error = recorder.errorMessage {
                Text(error).font(.caption).foregroundStyle(.red)
            }
            if let message = recorder.message {
                Text(message).font(.caption).foregroundStyle(.secondary)
            }
            if let error = model.errorMessage {
                Text(error).font(.caption).foregroundStyle(.red)
                Button("Retry") { Task { await model.refresh(teamID: teamID) } }
            }
            if allowsStartingGame
                && isOwner
                && model.errorMessage == nil
                && model.game?.status != .active {
                Menu("Start a New Relay") {
                    ForEach(model.routes) { route in
                        Button(route.name) {
                            Task { await model.start(routeID: route.id, teamID: teamID) }
                        }
                    }
                }.disabled(model.isStarting || model.isLoading || model.routes.isEmpty)
            }
        }
        .padding(14)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20))
        .alert("Discard unsubmitted activity?", isPresented: $confirmDiscard) {
            Button("Cancel", role: .cancel) {}
            Button("Discard", role: .destructive) { recorder.discard() }
        } message: {
            Text("Unsubmitted distance in this recording will be lost. Distance already credited on the server is not removed.")
        }
        .sheet(isPresented: $showContributions) {
            NavigationStack {
                List(model.game?.contributions ?? []) { item in
                    LabeledContent(item.displayName, value: String(format: "%.2f km", item.metres / 1000))
                }
                .navigationTitle("Relay Contributions")
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") { showContributions = false }
                    }
                }
            }
        }
    }
}
