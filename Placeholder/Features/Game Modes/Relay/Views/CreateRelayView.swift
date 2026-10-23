import SwiftUI
import MapKit

struct CreateRelayView: View {
    let teamID: Int64
    @Environment(\.dismiss) private var dismiss
    @State private var start: RelayEndpoint?
    @State private var finish: RelayEndpoint?
    @State private var searchTarget: SearchTarget?
    @State private var isSaving = false
    @State private var errorMessage: String?
    private let service = RelayService()

    private enum SearchTarget: String, Identifiable {
        case start, finish
        var id: String { rawValue }
    }
    private var targetMetres: Double? {
        guard let start, let finish else { return nil }
        return RelayEndpoint.distance(from: start, to: finish)
    }
    private var canCreate: Bool {
        guard let start, let finish, let targetMetres else { return false }
        return targetMetres >= 100 && targetMetres <= 2_000_000
            && abs(start.latitude) <= 85 && abs(finish.latitude) <= 85
            && abs(finish.longitude - start.longitude) <= 180 && !isSaving
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Journey") {
                    Button { searchTarget = .start } label: {
                        endpointLabel("Start", place: start)
                    }.buttonStyle(.borderless)
                    Button { searchTarget = .finish } label: {
                        endpointLabel("Destination", place: finish)
                    }.buttonStyle(.borderless)
                }
                if let start, let finish, let targetMetres {
                    Section("Preview") {
                        Map {
                            MapPolyline(coordinates: [start.coordinate, finish.coordinate])
                                .stroke(.cyan.opacity(0.4), lineWidth: 5)
                            Marker(start.name, coordinate: start.coordinate).tint(.green)
                            Marker(finish.name, coordinate: finish.coordinate).tint(.orange)
                        }
                        .frame(height: 220)
                        LabeledContent("Approximate target", value: String(format: "%.2f km", targetMetres / 1000))
                        if !canCreate && !isSaving {
                            Text("Choose locations 100 metres to 2,000 km apart, away from the poles and without crossing the date line.")
                                .font(.footnote).foregroundStyle(.red)
                        }
                    }
                }
                Section {
                    Text("This is a virtual straight-line journey, not navigation. Eligible walking/running activity anywhere advances the team along it. The server calculates and stores the target distance.")
                        .font(.footnote).foregroundStyle(.secondary)
                }
                if let errorMessage {
                    Section { Text(errorMessage).font(.footnote).foregroundStyle(.red) }
                }
                Section {
                    Button {
                        Task { await create() }
                    } label: {
                        if isSaving { ProgressView("Starting Relay…") }
                        else { Label("Start Relay", systemImage: "flag.checkered") }
                    }
                    .disabled(!canCreate)
                }
            }
            .disabled(isSaving)
            .navigationTitle("Create Relay")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }.disabled(isSaving)
                }
            }
            .interactiveDismissDisabled(isSaving)
            .sheet(item: $searchTarget) { target in
                RelayPlaceSearchView(title: target == .start ? "Starting Point" : "Destination") { place in
                    if target == .start { start = place } else { finish = place }
                }
            }
        }
    }

    private func endpointLabel(_ title: String, place: RelayEndpoint?) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.caption).foregroundStyle(.secondary)
                Text(place?.name ?? "Choose a location").foregroundStyle(.primary)
            }
            Spacer()
            Image(systemName: "magnifyingglass").foregroundStyle(.cyan)
        }.padding(.vertical, 4)
    }
    @MainActor
    private func create() async {
        guard canCreate, let start, let finish else { return }
        isSaving = true
        errorMessage = nil
        defer { isSaving = false }
        do {
            _ = try await service.startCustom(teamID: teamID, start: start, finish: finish)
            await AutomaticActivityCoordinator.shared.synchronize()
            dismiss()
        } catch { errorMessage = error.localizedDescription }
    }
}
