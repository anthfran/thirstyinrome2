import Testing
import Foundation
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
