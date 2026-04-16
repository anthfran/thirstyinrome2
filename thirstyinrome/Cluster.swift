import Foundation
import CoreLocation

struct Cluster: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
    let count: Int
    let places: [Place]
}
