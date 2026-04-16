import Foundation
import CoreLocation
import Observation

@Observable
final class PlaceViewModel: NSObject, CLLocationManagerDelegate {
    var places: [Place] = []
    var userLocation: CLLocation?
    var authorizationStatus: CLAuthorizationStatus = .notDetermined

    private let locationManager = CLLocationManager()
    private var isUpdatingLocation = false

    override init() {
        super.init()
        loadPlaces()
        setupLocationManager()
    }

    // MARK: - Private

    private func loadPlaces() {
        guard let url = Bundle.main.url(forResource: "Places", withExtension: "json") else {
            print("ThirstyInRome: Places.json not found in bundle")
            return
        }
        do {
            let data = try Data(contentsOf: url)
            places = try JSONDecoder().decode([Place].self, from: data)
        } catch {
            print("ThirstyInRome: Failed to decode Places.json: \(error)")
        }
    }

    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 10
        if locationManager.authorizationStatus == .notDetermined {
            locationManager.requestWhenInUseAuthorization()
        }
    }

    func requestAuthorization() {
        locationManager.requestWhenInUseAuthorization()
    }

    // MARK: - CLLocationManagerDelegate

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            if !isUpdatingLocation {
                isUpdatingLocation = true
                manager.startUpdatingLocation()
            }
        default:
            break
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last {
            userLocation = location
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        if (error as? CLError)?.code == .locationUnknown {
            userLocation = nil
        }
    }

    // MARK: - Clustering

    private static let defaultGridSize: Double = 0.008

    private func groupByCell(gridSize: Double) -> [[Place]] {
        var cells: [String: [Place]] = [:]
        for place in places {
            let row = Int(floor(place.lat / gridSize))
            let col = Int(floor(place.lon / gridSize))
            let key = "\(row)_\(col)"
            cells[key, default: []].append(place)
        }
        return Array(cells.values)
    }

    /// Groups places into clusters and singles in a single pass.
    /// Use this from call sites that need both to avoid processing `places` twice.
    func clusteringResult(gridSize: Double = defaultGridSize) -> (clusters: [Cluster], singles: [Place]) {
        let groups = groupByCell(gridSize: gridSize)
        let clusters = groups.compactMap { group -> Cluster? in
            guard group.count >= 2 else { return nil }
            let avgLat = group.map(\.lat).reduce(0, +) / Double(group.count)
            let avgLon = group.map(\.lon).reduce(0, +) / Double(group.count)
            return Cluster(
                coordinate: CLLocationCoordinate2D(latitude: avgLat, longitude: avgLon),
                count: group.count,
                places: group
            )
        }
        let singles = groups.compactMap { $0.count == 1 ? $0.first : nil }
        return (clusters, singles)
    }

    func clusters(gridSize: Double = defaultGridSize) -> [Cluster] {
        clusteringResult(gridSize: gridSize).clusters
    }

    func singlePlaces(gridSize: Double = defaultGridSize) -> [Place] {
        clusteringResult(gridSize: gridSize).singles
    }
}
