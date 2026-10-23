import SwiftUI
import MapKit
import Combine

struct RelayPlaceSearchView: View {
    let title: String
    let onSelect: (RelayEndpoint) -> Void

    @Environment(\.dismiss) private var dismiss

    @StateObject private var search = RelayPlaceSearchModel()

    @State private var query = ""
    @State private var isResolving = false
    @State private var selectionError: String?
    @State private var selectionTask: Task<Void, Never>?

    var body: some View {
        NavigationStack {
            List {
                ForEach(
                    Array(search.suggestions.enumerated()),
                    id: \.offset
                ) { _, suggestion in
                    Button {
                        select(suggestion)
                    } label: {
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: "mappin.circle.fill")
                                .foregroundStyle(.cyan)
                                .font(.title3)

                            VStack(alignment: .leading, spacing: 4) {
                                Text(suggestion.title)
                                    .foregroundStyle(.primary)

                                if !suggestion.subtitle.isEmpty {
                                    Text(suggestion.subtitle)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }

                            Spacer()
                        }
                        .padding(.vertical, 4)
                        .frame(
                            maxWidth: .infinity,
                            alignment: .leading
                        )
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .disabled(isResolving)
                }
            }
            .overlay {
                if isResolving {
                    ProgressView("Finding location…")
                        .padding()
                        .background(
                            .regularMaterial,
                            in: RoundedRectangle(cornerRadius: 12)
                        )
                } else if search.isSearching {
                    ProgressView("Searching…")
                } else if search.suggestions.isEmpty {
                    ContentUnavailableView(
                        query.trimmingCharacters(
                            in: .whitespacesAndNewlines
                        ).count < 2
                            ? "Find a Place"
                            : "No Suggestions",
                        systemImage: "magnifyingglass",
                        description: Text(
                            "Search for a city, address or landmark. "
                            + "Include the country for more specific results."
                        )
                    )
                }
            }
            .safeAreaInset(edge: .bottom) {
                if let message = selectionError ?? search.errorMessage {
                    Text(message)
                        .font(.footnote)
                        .foregroundStyle(.red)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(.regularMaterial)
                }
            }
            .searchable(
                text: $query,
                prompt: "City, address or landmark"
            )
            .onChange(of: query) { _, newValue in
                selectionError = nil
                search.update(query: newValue)
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        selectionTask?.cancel()
                        dismiss()
                    }
                }
            }
            .onDisappear {
                selectionTask?.cancel()
                search.stop()
            }
        }
    }

    @MainActor
    private func select(_ suggestion: MKLocalSearchCompletion) {
        guard !isResolving else { return }

        isResolving = true
        selectionError = nil

        selectionTask = Task { @MainActor in
            defer {
                isResolving = false
            }

            do {
                let request = MKLocalSearch.Request(
                    completion: suggestion
                )

                let response = try await MKLocalSearch(
                    request: request
                ).start()

                try Task.checkCancellation()

                guard let item = response.mapItems.first else {
                    selectionError = "Could not find this location."
                    return
                }

                let coordinate = item.placemark.coordinate

                let endpoint = RelayEndpoint(
                    id: UUID(),
                    name: item.name ?? suggestion.title,
                    subtitle: suggestion.subtitle,
                    latitude: coordinate.latitude,
                    longitude: coordinate.longitude
                )

                onSelect(endpoint)
                dismiss()
            } catch {
                guard !Task.isCancelled else { return }
                selectionError = error.localizedDescription
            }
        }
    }
}

@MainActor
private final class RelayPlaceSearchModel:
    NSObject,
    ObservableObject,
    @preconcurrency MKLocalSearchCompleterDelegate
{
    @Published private(set) var suggestions:
        [MKLocalSearchCompletion] = []

    @Published private(set) var isSearching = false
    @Published private(set) var errorMessage: String?

    private let completer = MKLocalSearchCompleter()
    private var currentQuery = ""

    override init() {
        super.init()

        completer.delegate = self

        // Include addresses, cities and named places.
        // Exclude general search-category suggestions.
        completer.resultTypes = [
            .address,
            .pointOfInterest
        ]
    }

    func update(query: String) {
        let trimmed = query.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        guard trimmed != currentQuery else { return }

        currentQuery = trimmed

        completer.cancel()
        suggestions = []
        errorMessage = nil

        guard trimmed.count >= 2 else {
            isSearching = false
            return
        }

        isSearching = true
        completer.queryFragment = trimmed
    }

    func stop() {
        completer.cancel()
        isSearching = false
    }

    func completerDidUpdateResults(
        _ completer: MKLocalSearchCompleter
    ) {
        guard currentQuery.count >= 2 else { return }

        suggestions = completer.results
        isSearching = false
        errorMessage = nil
    }

    func completer(
        _ completer: MKLocalSearchCompleter,
        didFailWithError error: Error
    ) {
        guard currentQuery.count >= 2 else { return }

        suggestions = []
        isSearching = false
        errorMessage = error.localizedDescription
    }
}
