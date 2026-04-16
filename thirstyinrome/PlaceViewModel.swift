import Foundation
import CoreLocation
import Observation

@Observable
final class PlaceViewModel: NSObject, CLLocationManagerDelegate {
    var places: [Place] = []
    var userLocation: CLLocation?

    private let locationManager = CLLocationManager()

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
        if locationManager.authorizationStatus == .notDetermined {
            locationManager.requestWhenInUseAuthorization()
        }
    }

    // MARK: - CLLocationManagerDelegate

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            manager.startUpdatingLocation()
        default:
            break
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        userLocation = locations.last
    }
}
