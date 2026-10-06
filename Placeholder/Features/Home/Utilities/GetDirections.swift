import MapKit

extension MapView {
    func GetDirections(
        to destination: CLLocationCoordinate2D
    ) {
        Task {
            guard let userLocation = await GetUserLocation() else {
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
            } catch {
                print(
                    "Cannot calculate directions: "
                    + error.localizedDescription
                )
            }
        }
    }
}
