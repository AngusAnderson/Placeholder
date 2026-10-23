import CoreLocation
import MapKit
import SwiftUI
import UIKit

struct MapView: View {
    let profileImage: UIImage?

    @StateObject private var userLocation =
        UserLocationManager()

    @State private var cameraPosition:
        MapCameraPosition = .region(
            MKCoordinateRegion(
                center: .appleHQ,
                latitudinalMeters: 1300,
                longitudinalMeters: 1300
            )
        )

    @State private var lookAroundScene:
        MKLookAroundScene?

    @State private var isShowingLookAround = false

    @State private var route: MKRoute?

    @State private var hasCenteredOnUser = false
    
    // Relay integrations - A.Anderson
    @State private var relayModel = RelayViewModel()
    
    // Team selector
    @State private var selectedTeamID: Int64?
    @State private var teamModel = TeamViewModel()
    @State private var showTeams = false
    
    // Notification stuff
    @State private var showNotifications = false

    var body: some View {
        ZStack {
            Map(position: $cameraPosition) {

                // Selected team's shared game.
                if let game = selectedRelayGame,
                   let geometry = selectedRelayGeometry {
                    RelayMapContent(
                        geometry: geometry,
                        startName: game.startName,
                        finishName: game.finishName,
                        creditedMetres: game.creditedMetres,
                        targetMetres: game.targetMetres
                    )
                }

                // Actual device location.
                if let coordinate = userLocation.coordinate {
                    Annotation(
                        "You",
                        coordinate: coordinate,
                        anchor: .center
                    ) {
                        ProfileMapAnnotation(
                            image: profileImage
                        )
                    }
                }

                // Separate personal-directions route, if used.
                if let route {
                    MapPolyline(route)
                        .stroke(
                            Color.pink,
                            lineWidth: 4
                        )
                }
            }
            .onAppear {
                userLocation.startUpdatingLocation()
            }
            .onDisappear {
                userLocation.stopUpdatingLocation()
            }
            .onChange(
                of: userLocation.coordinate?.latitude
            ) { _, _ in
                centerOnUserIfNeeded()
            }
            .onChange(
                of: userLocation.coordinate?.longitude
            ) { _, _ in
                centerOnUserIfNeeded()
            }
            .mapControls {
                MapUserLocationButton()
                MapCompass()
                MapPitchToggle()
            }
            .mapStyle(.standard)
            .lookAroundViewer(
                isPresented: $isShowingLookAround,
                initialScene: lookAroundScene
            )

            // Team selector.
            .overlay(alignment: .top) {
                TeamSelectorView(
                    teams: teamModel.teams,
                    isLoading: teamModel.isLoading,
                    hasLoaded: teamModel.hasLoaded,
                    errorMessage: teamModel.errorMessage,
                    selection: $selectedTeamID,
                    hint: "Team",
                    onManageTeams: {
                        showTeams = true
                    },
                    onRetry: {
                        Task {
                            await teamModel.load()
                        }
                    }
                )
                .padding(.top, 14)
                .padding(.horizontal, 16)
            }

            // Notifications button.
            .overlay(alignment: .topLeading) {
                Group {
                    if #available(iOS 26.0, *) {
                        notificationButton
                            .buttonStyle(.glass)
                            .buttonBorderShape(.circle)
                            .tint(.blue)
                    } else {
                        notificationButton
                            .buttonStyle(.plain)
                            .foregroundStyle(.cyan)
                            .background(
                                .regularMaterial,
                                in: Circle()
                            )
                            .overlay {
                                Circle()
                                    .stroke(
                                        .white.opacity(0.15),
                                        lineWidth: 1
                                    )
                            }
                    }
                }
                .padding(.leading, 16)
                .padding(.top, 15)
            }
        }

        // Load the user's team memberships.
        .task {
            await teamModel.load()
        }

        // Load/poll the game belonging to the selected team.
        .task(id: selectedTeamID) {
            await relayModel.watch(
                teamID: selectedTeamID
            )
        }

        // Frame a new game once, not every time its distance changes.
        .onChange(of: selectedRelayGame?.id) { _, _ in
            fitSelectedRelay()
        }

        // Clear selections that are no longer memberships.
        .onChange(
            of: teamModel.teams.map(\.id)
        ) { _, availableIDs in
            if let selectedTeamID,
               !availableIDs.contains(selectedTeamID) {
                self.selectedTeamID = nil
            }
        }

        // Team management.
        .sheet(
            isPresented: $showTeams,
            onDismiss: {
                Task {
                    await refreshTeamsAndGame()
                }
            }
        ) {
            TeamView()
        }

        // Notifications.
        .sheet(
            isPresented: $showNotifications,
            onDismiss: {
                Task {
                    await refreshTeamsAndGame()
                }
            }
        ) {
            NavigationStack {
                NotificationsView(client: supabase)
            }
        }
    }

    private func centerOnUserIfNeeded() {
        guard
            selectedRelayGame == nil,
            !hasCenteredOnUser,
            let coordinate = userLocation.coordinate
        else {
            return
        }

        cameraPosition = .region(
            MKCoordinateRegion(
                center: coordinate,
                latitudinalMeters: 1300,
                longitudinalMeters: 1300
            )
        )

        hasCenteredOnUser = true
    }

    private func openLookAround() {
        Task {
            let scene = await GetLookAroundScene(
                from: .smithstone
            )

            guard let scene else {
                return
            }

            lookAroundScene = scene
            isShowingLookAround = true
        }
    }

    private func getDirections(
        to destination: CLLocationCoordinate2D
    ) {
        Task {
            guard let userCoordinate =
                    await GetUserLocation()
            else {
                print("Could not get the user's location.")
                return
            }

            let request = MKDirections.Request()

            request.source = MKMapItem(
                placemark: MKPlacemark(
                    coordinate: userCoordinate
                )
            )

            request.destination = MKMapItem(
                placemark: MKPlacemark(
                    coordinate: destination
                )
            )

            request.transportType = .automobile

            do {
                let directions = try await MKDirections(
                    request: request
                )
                .calculate()

                route = directions.routes.first

                if let route {
                    cameraPosition = .rect(
                        route.polyline.boundingMapRect
                    )
                }
            } catch {
                print(
                    """
                    Cannot calculate directions:
                    \(error.localizedDescription)
                    """
                )
            }
        }
    }
    
    private var notificationButton: some View {
        Button {
            showNotifications = true
        } label: {
            Image(systemName: "bell.fill")
                .font(.system(size: 20, weight: .semibold))
                .frame(width: 32, height: 32)
        }
        .accessibilityLabel("Open notifications")
    }
    
    func coordinates(from polyline: MKPolyline) -> [CLLocationCoordinate2D] {
        var result = Array(
            repeating: CLLocationCoordinate2D(latitude: 0, longitude: 0),
            count: polyline.pointCount
        )
        
        polyline.getCoordinates(
            &result,
            range: NSRange(
                location: 0,
                length: polyline.pointCount
            )
        )
        
        return result
    }
    
    // MARK: - Selected team's game

    private var selectedRelayGame: RelayGame? {
        guard let selectedTeamID,
              relayModel.selectedTeamID == selectedTeamID
        else {
            return nil
        }

        return relayModel.game
    }

    private var selectedRelayGeometry: RelayRouteGeometry? {
        guard let game = selectedRelayGame else {
            return nil
        }

        return RelayRouteGeometry(
            coordinates: game.coordinates.map(\.coordinate)
        )
    }
    
    // MARK: - Relay camera

    private func fitSelectedRelay() {
        guard let geometry = selectedRelayGeometry,
              geometry.coordinates.count >= 2
        else {
            return
        }

        let line = MKPolyline(
            coordinates: geometry.coordinates,
            count: geometry.coordinates.count
        )

        hasCenteredOnUser = true

        cameraPosition = .rect(
            line.boundingMapRect
        )
    }

    // MARK: - Refresh teams and current game

    @MainActor
    private func refreshTeamsAndGame() async {
        await teamModel.load()

        guard let selectedTeamID else {
            return
        }

        guard teamModel.teams.contains(
            where: { $0.id == selectedTeamID }
        ) else {
            self.selectedTeamID = nil
            return
        }

        await relayModel.refresh(
            teamID: selectedTeamID
        )
    }
}
