import XCTest
import Foundation
@testable import EarthquakeTracking

class EarthquakeTests: XCTestCase {
    
    // MARK: - Test Earthquake Creation
    func testEarthquakeCreation() {
        // Given & When
        let earthquake = Earthquake(
            date: "2025-05-14",
            time: "10:30:15",
            latitude: "40.7128",
            longitude: "29.0128",
            depth_km: "10.5",
            md: "3.2",
            ml: "3.4",
            mw: "3.3",
            location: "Istanbul, Turkey"
        )
        
        // Then
        XCTAssertEqual(earthquake.date, "2025-05-14")
        XCTAssertEqual(earthquake.location, "Istanbul, Turkey")
        XCTAssertNotNil(earthquake.id)
    }
    
    // MARK: - Test Unique IDs
    func testUniqueIDs() {
        // Given & When
        let earthquake1 = Earthquake(date: "2025-05-14", time: "10:30:15", latitude: "40.7128", longitude: "29.0128", depth_km: "10.5", md: "3.2", ml: "3.4", mw: "3.3", location: "Istanbul")
        let earthquake2 = Earthquake(date: "2025-05-14", time: "10:30:15", latitude: "40.7128", longitude: "29.0128", depth_km: "10.5", md: "3.2", ml: "3.4", mw: "3.3", location: "Istanbul")
        
        // Then
        XCTAssertNotEqual(earthquake1.id, earthquake2.id)
    }
    
    // MARK: - Test JSON Decoding
    func testJSONDecoding() throws {
        // Given
        let json = """
        {
            "date": "2025-05-14",
            "time": "10:30:15",
            "latitude": "40.7128",
            "longitude": "29.0128",
            "depth_km": "10.5",
            "md": "3.2",
            "ml": "3.4",
            "mw": "3.3",
            "location": "Istanbul, Turkey"
        }
        """
        
        // When
        let data = json.data(using: .utf8)!
        let earthquake = try JSONDecoder().decode(Earthquake.self, from: data)
        
        // Then
        XCTAssertEqual(earthquake.date, "2025-05-14")
        XCTAssertEqual(earthquake.location, "Istanbul, Turkey")
    }
    
    // MARK: - Test JSON Encoding
    func testJSONEncoding() throws {
        // Given
        let earthquake = Earthquake(date: "2025-05-14", time: "10:30:15", latitude: "40.7128", longitude: "29.0128", depth_km: "10.5", md: "3.2", ml: "3.4", mw: "3.3", location: "Istanbul")
        
        // When
        let data = try JSONEncoder().encode(earthquake)
        let json = String(data: data, encoding: .utf8)!
        
        // Then
        XCTAssertTrue(json.contains("\"date\":\"2025-05-14\""))
        XCTAssertFalse(json.contains("\"id\"")) // ID should not be encoded
    }
    
    // MARK: - Test CodingKeys
    func testCodingKeys() {
        // Then
        XCTAssertEqual(Earthquake.CodingKeys.date.rawValue, "date")
        XCTAssertEqual(Earthquake.CodingKeys.location.rawValue, "location")
    }
}
