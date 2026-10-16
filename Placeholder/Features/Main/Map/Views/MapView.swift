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
    
    // Team selector stuff
    @State private var selection: String?
    
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
            
            // Team drop down menu.
            // Later I'll change the 'Team' to be the actual team name, that is currently selected.
            
            .overlay(alignment: .top) {
                TeamView(
                    hint: "Team",
                    options: [
                        "Team 1",
                        "Team 2",
                        "Team 3"
                    ],
                    selection: $selection
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
        .sheet(isPresented: $showNotifications) {
            NotificationsView()
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
