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

    var body: some View {
        Map(position: $cameraPosition) {
            Annotation(
                "Smithstone",
                coordinate: .smithstone,
                anchor: .center
            ) {
                Image(systemName: "house.fill")
                    .resizable()
                    .aspectRatio(
                        contentMode: .fit
                    )
                    .foregroundStyle(.white)
                    .frame(
                        width: 20,
                        height: 20
                    )
                    .padding(7)
                    .background(
                        .red.gradient,
                        in: .circle
                    )
                    .contextMenu {
                        Button(
                            "Open Look Around",
                            systemImage: "binoculars"
                        ) {
                            openLookAround()
                        }

                        Button(
                            "Get Directions",
                            systemImage: "arrow.turn.down.right"
                        ) {
                            getDirections(
                                to: .smithstone
                            )
                        }
                    }
            }

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
            MapScaleView()
        }
        .mapStyle(.standard)
        .lookAroundViewer(
            isPresented: $isShowingLookAround,
            initialScene: lookAroundScene
        )
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
}
