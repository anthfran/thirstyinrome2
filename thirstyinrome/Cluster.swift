import Foundation
import CoreLocation

struct Cluster: Identifiable {
    var id: String { places.map(\.id).sorted().joined() }
    let coordinate: CLLocationCoordinate2D
    let count: Int
    let places: [Place]
}
