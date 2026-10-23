import CoreLocation
import MapKit

struct RelayRouteGeometry {
    let coordinates: [CLLocationCoordinate2D]
    
    private let cumulativeMetres: [Double]
    private let totalMetres: Double
    
    init(coordinates: [CLLocationCoordinate2D]) {
        self.coordinates = coordinates
        
        var distances: [Double] = []
        var runningTotal = 0.0
        
        for index in coordinates.indices {
            if index > 0 {
                let previous = CLLocation(
                    latitude: coordinates[index - 1].latitude,
                    longitude: coordinates[index - 1].longitude
                )
                
                let current = CLLocation(
                    latitude: coordinates[index].latitude,
                    longitude: coordinates[index].longitude
                )
                
                runningTotal += current.distance(from: previous)
            }
            
            distances.append(runningTotal)
        }
        
        cumulativeMetres = distances
        totalMetres = runningTotal
    }
    
    func position(at progress: Double) -> CLLocationCoordinate2D? {
        completedCoordinates(at: progress).last
    }
    
    func completedCoordinates(at progress: Double) -> [CLLocationCoordinate2D] {
        guard let first = coordinates.first else {
            return []
        }
        
        guard coordinates.count > 1, totalMetres > 0 else {
            return [first]
        }
        
        let fraction = min(max(progress, 0), 1)
        
        if fraction <= 0 {
            return [first]
        }
        
        if fraction >= 1 {
            return coordinates
        }
        
        let targetDistance = totalMetres * fraction
        var result = [first]
        
        for index in 1..<coordinates.count {
            let segmentStart = cumulativeMetres[index - 1]
            let segmentEnd = cumulativeMetres[index]
            
            if segmentEnd <= targetDistance {
                result.append(coordinates[index])
                continue
            }
            
            let segmentLength = segmentEnd - segmentStart
            
            guard segmentLength > 0 else {
                continue
            }
            
            let segmentFraction = (targetDistance - segmentStart) / segmentLength
            
            let startPoint = MKMapPoint(coordinates[index - 1])
            let endPoint = MKMapPoint(coordinates[index])
            
            let interpolatedPoint = MKMapPoint(
                x: startPoint.x + (endPoint.x - startPoint.x) * segmentFraction,
                y: startPoint.y + (endPoint.y - startPoint.y) * segmentFraction
            )
            
            result.append(interpolatedPoint.coordinate)
            
            return result
        }
        
        return result
    }
}
