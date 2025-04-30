import Foundation

struct Earthquake: Codable, Identifiable {
    let id = UUID()
    let date: String
    let time: String
    let latitude: String
    let longitude: String
    let depth_km: String
    let md: String
    let ml: String
    let mw: String
    let location: String

    enum CodingKeys: String, CodingKey {
        case date, time, latitude, longitude, depth_km, md, ml, mw, location
    }
}
