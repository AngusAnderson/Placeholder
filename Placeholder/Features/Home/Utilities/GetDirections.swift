import CoreLocation
import MapKit
import SwiftUI

extension MapView {

    func GetDirections(
        to destination: CLLocationCoordinate2D
    ) {
        Task {
            guard let userLocation = await GetUserLocation() else {
                print("Could not get the user's location.")
                return
            }

            let request = MKDirections.Request()

            request.source = MKMapItem(
                placemark: MKPlacemark(
                    coordinate: userLocation
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
                ).calculate()

                route = directions.routes.first

                if let route {
                    cameraPosition = .rect(
                        route.polyline.boundingMapRect
                    )
                }
            } catch {
                print(
                    "Cannot calculate directions: "
                    + error.localizedDescription
                )
            }
        }
    }
}
