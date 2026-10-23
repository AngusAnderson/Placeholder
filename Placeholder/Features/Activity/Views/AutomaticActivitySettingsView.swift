import SwiftUI

struct AutomaticActivitySettingsView: View {
    private let coordinator = AutomaticActivityCoordinator.shared
    @State private var confirmEnable = false
    @State private var confirmDisable = false

    var body: some View {
        List {
            Section("Automatic Team Activity") {
                Text("Walking and running distance contributes automatically to every eligible active team Relay. Selecting a map team only changes what you view.")
                Text("This sends aggregated activity distance and steps to the app's server. Teammates can see your credited distance. It does not upload GPS routes or individual Health samples.")
                    .font(.footnote).foregroundStyle(.secondary)
                LabeledContent("Sharing", value: coordinator.enabled ? "On" : "Off")
                if coordinator.enabled {
                    Button("Turn Off Automatic Sharing", role: .destructive) { confirmDisable = true }
                } else {
                    Button("Enable Automatic Activity") { confirmEnable = true }
                }
            }
            Section("Sync Status") {
                Text(coordinator.statusMessage).font(.subheadline)
                if let cutoff = coordinator.cutoff {
                    LabeledContent("Eligible from") { Text(cutoff, format: .dateTime.day().month().hour().minute()) }
                }
                if let lastSync = coordinator.lastSync {
                    LabeledContent("Last reconciliation") { Text(lastSync, style: .relative) }
                }
                LabeledContent("Queued intervals", value: String(coordinator.pendingCount))
                if coordinator.isBusy { ProgressView("Processing activity…") }
                if let error = coordinator.errorMessage { Text(error).font(.footnote).foregroundStyle(.red) }
                Button("Retry Sync") { Task { await coordinator.synchronize() } }
            }
            Section {
                Text("Health read access is controlled in Health/Settings. An empty result does not prove that permission was granted or denied. iOS controls background timing; step-count delivery is at most hourly, not every minute. Locked-device data may be deferred until unlock.")
                    .font(.footnote).foregroundStyle(.secondary)
            }
        }
        .disabled(coordinator.isBusy)
        .navigationTitle("Automatic Activity")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { coordinator.restoreLocalStatus() }
        .alert("Enable automatic team activity?", isPresented: $confirmEnable) {
            Button("Cancel", role: .cancel) {}
            Button("Enable") { Task { await coordinator.enable() } }
        } message: {
            Text("Allow the app to read Health steps and walking/running distance and send aggregated totals to its server for eligible team games? Health permissions will be requested next.")
        }
        .alert("Turn off sharing?", isPresented: $confirmDisable) {
            Button("Cancel", role: .cancel) {}
            Button("Turn Off", role: .destructive) { Task { await coordinator.disable() } }
        } message: {
            Text("Future automatic uploads will stop for this account. Previously credited activity is not removed.")
        }
    }
}
