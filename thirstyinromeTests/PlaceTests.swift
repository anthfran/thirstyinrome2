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
        [{"id": "CCCCCCCC", "lat": 41.9, "lon": 12.5}]
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

    @Test func testPlaceIdDecodesFromJSON() throws {
        let json = Data("""
        [{"id": "AAAAAAAA", "title": "Test", "lat": 41.9, "lon": 12.5}]
        """.utf8)
        let places = try JSONDecoder().decode([Place].self, from: json)
        #expect(places[0].id == "AAAAAAAA")
    }

    @Test func testPlaceIdIsStableAcrossDecodes() throws {
        let json = Data("""
        [{"id": "BBBBBBBB", "lat": 41.9, "lon": 12.5}]
        """.utf8)
        let a = try JSONDecoder().decode([Place].self, from: json)
        let b = try JSONDecoder().decode([Place].self, from: json)
        #expect(a[0].id == b[0].id)
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
            Place(id: "AAAAAAAA", title: "A", lat: 41.900, lon: 12.470),
            Place(id: "BBBBBBBB", title: "B", lat: 41.901, lon: 12.471)
        ]
        let result = vm.clusteringResult()
        try #require(result.clusters.count == 1)
        #expect(result.clusters[0].count == 2)
        #expect(result.singles.isEmpty)
    }

    // Two places in different 0.008° cells → two singles, no clusters
    @Test func testTwoPlacesInDifferentCellsAreEachSingles() {
        let vm = PlaceViewModel()
        vm.places = [
            Place(id: "AAAAAAAA", title: "A", lat: 41.900, lon: 12.470),
            Place(id: "BBBBBBBB", title: "B", lat: 41.950, lon: 12.520)
        ]
        let result = vm.clusteringResult()
        #expect(result.clusters.isEmpty)
        #expect(result.singles.count == 2)
    }

    // One place alone → not in clusters, appears in singlePlaces
    @Test func testOnePlaceIsASingle() {
        let vm = PlaceViewModel()
        vm.places = [Place(id: "AAAAAAAA", title: "A", lat: 41.900, lon: 12.470)]
        let result = vm.clusteringResult()
        #expect(result.clusters.isEmpty)
        #expect(result.singles.count == 1)
    }

    // Empty places → empty results
    @Test func testEmptyPlacesReturnEmpty() {
        let vm = PlaceViewModel()
        vm.places = []
        let result = vm.clusteringResult()
        #expect(result.clusters.isEmpty)
        #expect(result.singles.isEmpty)
    }

    // Cluster centroid is the average of its member coordinates
    @Test func testClusterCentroidIsAverage() throws {
        let vm = PlaceViewModel()
        vm.places = [
            Place(id: "AAAAAAAA", title: "A", lat: 41.900, lon: 12.470),
            Place(id: "BBBBBBBB", title: "B", lat: 41.902, lon: 12.471)
        ]
        let result = vm.clusteringResult()
        try #require(result.clusters.count == 1)
        #expect(abs(result.clusters[0].coordinate.latitude  - 41.901) < 0.0001)
        #expect(abs(result.clusters[0].coordinate.longitude - 12.4705) < 0.0001)
    }

    @Test func testClusterIdIsStableAcrossCalls() throws {
        let vm = PlaceViewModel()
        vm.places = [
            Place(id: "AAAAAAAA", title: "A", lat: 41.900, lon: 12.470),
            Place(id: "BBBBBBBB", title: "B", lat: 41.901, lon: 12.471)
        ]
        let first = vm.clusteringResult().clusters
        let second = vm.clusteringResult().clusters
        try #require(first.count == 1)
        try #require(second.count == 1)
        #expect(first[0].id == second[0].id)
    }

    @Test func testClusterIdIsDeterministic() throws {
        let vm1 = PlaceViewModel()
        vm1.places = [
            Place(id: "AAAAAAAA", title: "A", lat: 41.900, lon: 12.470),
            Place(id: "BBBBBBBB", title: "B", lat: 41.901, lon: 12.471)
        ]
        let vm2 = PlaceViewModel()
        vm2.places = [
            Place(id: "AAAAAAAA", title: "A", lat: 41.900, lon: 12.470),
            Place(id: "BBBBBBBB", title: "B", lat: 41.901, lon: 12.471)
        ]
        let c1 = try #require(vm1.clusteringResult().clusters.first)
        let c2 = try #require(vm2.clusteringResult().clusters.first)
        #expect(c1.id == c2.id)
    }
}

struct LocationViewModelTests {

    @Test func testAuthorizationStatusIsReadable() {
        let vm = PlaceViewModel()
        let _ = vm.authorizationStatus
    }

    @Test func testAuthorizationStatusMatchesSystemAfterInit() {
        let vm = PlaceViewModel()
        #expect(vm.authorizationStatus == CLLocationManager().authorizationStatus)
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
