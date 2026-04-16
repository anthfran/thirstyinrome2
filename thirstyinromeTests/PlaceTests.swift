import Testing
import Foundation
import CoreLocation
@testable import thirstyinrome

struct PlaceTests {

    @Test func testPlacesJSONLoads() throws {
        let places = try loadAllPlaces()
        #expect(!places.isEmpty)
    }

    @Test func testNilTitleHandled() throws {
        let json = Data("""
        [{"lat": 41.9, "lon": 12.5}]
        """.utf8)
        let places = try JSONDecoder().decode([Place].self, from: json)
        #expect(places.count == 1)
        #expect(places[0].title == nil)
    }

    @Test func testCoordinatesInRomeBounds() throws {
        let places = try loadAllPlaces()
        for place in places {
            #expect((41.0...42.0).contains(place.lat), "lat \(place.lat) out of Rome bounds")
            #expect((12.0...13.0).contains(place.lon), "lon \(place.lon) out of Rome bounds")
        }
    }

    private func loadAllPlaces() throws -> [Place] {
        let url = try #require(Bundle.main.url(forResource: "Places", withExtension: "json"))
        return try JSONDecoder().decode([Place].self, from: Data(contentsOf: url))
    }
}

struct ClusterTests {

    // Two places in the same 0.008° cell → one cluster, no singles
    @Test func testTwoPlacesInSameCellFormOneCluster() throws {
        let vm = PlaceViewModel()
        vm.places = [
            Place(title: "A", lat: 41.900, lon: 12.470),
            Place(title: "B", lat: 41.901, lon: 12.471)
        ]
        let clusters = vm.clusters()
        let singles = vm.singlePlaces()
        try #require(clusters.count == 1)
        #expect(clusters[0].count == 2)
        #expect(singles.isEmpty)
    }

    // Two places in different 0.008° cells → two singles, no clusters
    @Test func testTwoPlacesInDifferentCellsAreEachSingles() {
        let vm = PlaceViewModel()
        vm.places = [
            Place(title: "A", lat: 41.900, lon: 12.470),
            Place(title: "B", lat: 41.950, lon: 12.520)
        ]
        let clusters = vm.clusters()
        let singles = vm.singlePlaces()
        #expect(clusters.isEmpty)
        #expect(singles.count == 2)
    }

    // One place alone → not in clusters, appears in singlePlaces
    @Test func testOnePlaceIsASingle() {
        let vm = PlaceViewModel()
        vm.places = [Place(title: "A", lat: 41.900, lon: 12.470)]
        #expect(vm.clusters().isEmpty)
        #expect(vm.singlePlaces().count == 1)
    }

    // Empty places → empty results
    @Test func testEmptyPlacesReturnEmpty() {
        let vm = PlaceViewModel()
        vm.places = []
        #expect(vm.clusters().isEmpty)
        #expect(vm.singlePlaces().isEmpty)
    }

    // Cluster centroid is the average of its member coordinates
    @Test func testClusterCentroidIsAverage() throws {
        let vm = PlaceViewModel()
        vm.places = [
            Place(title: "A", lat: 41.900, lon: 12.470),
            Place(title: "B", lat: 41.902, lon: 12.471)
        ]
        let clusters = vm.clusters()
        try #require(clusters.count == 1)
        #expect(abs(clusters[0].coordinate.latitude  - 41.901) < 0.0001)
        #expect(abs(clusters[0].coordinate.longitude - 12.4705) < 0.0001)
    }
}

struct LocationViewModelTests {

    @Test func testAuthorizationStatusIsReadable() {
        let vm = PlaceViewModel()
        let _ = vm.authorizationStatus // fails to compile until property added
    }

    @Test func testLocationUnknownErrorNilsUserLocation() {
        let vm = PlaceViewModel()
        vm.userLocation = CLLocation(latitude: 41.9, longitude: 12.5)
        vm.locationManager(CLLocationManager(), didFailWithError: CLError(.locationUnknown))
        #expect(vm.userLocation == nil)
    }

    @Test func testOtherLocationErrorPreservesUserLocation() {
        let vm = PlaceViewModel()
        vm.userLocation = CLLocation(latitude: 41.9, longitude: 12.5)
        vm.locationManager(CLLocationManager(), didFailWithError: CLError(.denied))
        #expect(vm.userLocation != nil)
    }
}
