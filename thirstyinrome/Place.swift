import Foundation

struct Place: Codable, Identifiable {
    let id = UUID()
    let title: String?
    let lat: Double
    let lon: Double

    enum CodingKeys: String, CodingKey {
        case title, lat, lon
    }
}
