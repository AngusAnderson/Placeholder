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
    
    // Team selector
    @State private var selectedTeamID: Int64?
    @State private var teamModel = TeamViewModel()
    @State private var showTeams = false
    
    // Notification stuff
    @State private var showNotifications = false

    var body: some View {
        ZStack {
            Map(position: $cameraPosition) {

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
        .task {
            await teamModel.load()
        }

        .onChange(of: teamModel.teams.map(\.id)) { _, availableIDs in
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
                    await teamModel.load()
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
                    await teamModel.load()
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
}
