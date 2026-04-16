import Foundation

struct Place: Codable, Identifiable {
    let id: String
    let title: String?
    let lat: Double
    let lon: Double
}
