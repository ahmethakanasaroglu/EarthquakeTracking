import XCTest
import Foundation
@testable import EarthquakeTracking // Projenizin module adını buraya yazın

class EarthquakeTests: XCTestCase {
    
    // MARK: - Initialization Tests
    
    func testEarthquakeCreation() {
        // Given
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
        XCTAssertNotNil(earthquake.id)
        XCTAssertEqual(earthquake.date, "2025-05-14")
        XCTAssertEqual(earthquake.time, "10:30:15")
        XCTAssertEqual(earthquake.latitude, "40.7128")
        XCTAssertEqual(earthquake.longitude, "29.0128")
        XCTAssertEqual(earthquake.depth_km, "10.5")
        XCTAssertEqual(earthquake.md, "3.2")
        XCTAssertEqual(earthquake.ml, "3.4")
        XCTAssertEqual(earthquake.mw, "3.3")
        XCTAssertEqual(earthquake.location, "Istanbul, Turkey")
    }
    
    func testEarthquakeUniqueIDs() {
        // Given & When
        let earthquake1 = Earthquake(
            date: "2025-05-14", time: "10:30:15", latitude: "40.7128",
            longitude: "29.0128", depth_km: "10.5", md: "3.2",
            ml: "3.4", mw: "3.3", location: "Istanbul, Turkey"
        )
        
        let earthquake2 = Earthquake(
            date: "2025-05-14", time: "10:30:15", latitude: "40.7128",
            longitude: "29.0128", depth_km: "10.5", md: "3.2",
            ml: "3.4", mw: "3.3", location: "Istanbul, Turkey"
        )
        
        // Then - Aynı değerlere sahip iki deprem farklı ID'lere sahip olmalı
        XCTAssertNotEqual(earthquake1.id, earthquake2.id)
    }
    
    // MARK: - Codable Tests
    
    func testEarthquakeDecoding() throws {
        // Given
        let jsonString = """
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
        let data = jsonString.data(using: .utf8)!
        let earthquake = try JSONDecoder().decode(Earthquake.self, from: data)
        
        // Then
        XCTAssertEqual(earthquake.date, "2025-05-14")
        XCTAssertEqual(earthquake.time, "10:30:15")
        XCTAssertEqual(earthquake.latitude, "40.7128")
        XCTAssertEqual(earthquake.longitude, "29.0128")
        XCTAssertEqual(earthquake.depth_km, "10.5")
        XCTAssertEqual(earthquake.md, "3.2")
        XCTAssertEqual(earthquake.ml, "3.4")
        XCTAssertEqual(earthquake.mw, "3.3")
        XCTAssertEqual(earthquake.location, "Istanbul, Turkey")
    }
    
    func testEarthquakeEncoding() throws {
        // Given
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
        
        // When
        let data = try JSONEncoder().encode(earthquake)
        let jsonString = String(data: data, encoding: .utf8)!
        
        // Then
        XCTAssertTrue(jsonString.contains("\"date\":\"2025-05-14\""))
        XCTAssertTrue(jsonString.contains("\"time\":\"10:30:15\""))
        XCTAssertTrue(jsonString.contains("\"latitude\":\"40.7128\""))
        XCTAssertTrue(jsonString.contains("\"longitude\":\"29.0128\""))
        XCTAssertTrue(jsonString.contains("\"depth_km\":\"10.5\""))
        XCTAssertTrue(jsonString.contains("\"md\":\"3.2\""))
        XCTAssertTrue(jsonString.contains("\"ml\":\"3.4\""))
        XCTAssertTrue(jsonString.contains("\"mw\":\"3.3\""))
        XCTAssertTrue(jsonString.contains("\"location\":\"Istanbul, Turkey\""))
        // ID'nin encode edilmediğini kontrol et (CodingKeys'te yok)
        XCTAssertFalse(jsonString.contains("\"id\""))
    }
    
    func testEarthquakeEncodingDecoding() throws {
        // Given
        let originalEarthquake = Earthquake(
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
        
        // When
        let data = try JSONEncoder().encode(originalEarthquake)
        let decodedEarthquake = try JSONDecoder().decode(Earthquake.self, from: data)
        
        // Then - ID hariç tüm özellikler aynı olmalı (UUID yeniden oluşturulur)
        XCTAssertEqual(originalEarthquake.date, decodedEarthquake.date)
        XCTAssertEqual(originalEarthquake.time, decodedEarthquake.time)
        XCTAssertEqual(originalEarthquake.latitude, decodedEarthquake.latitude)
        XCTAssertEqual(originalEarthquake.longitude, decodedEarthquake.longitude)
        XCTAssertEqual(originalEarthquake.depth_km, decodedEarthquake.depth_km)
        XCTAssertEqual(originalEarthquake.md, decodedEarthquake.md)
        XCTAssertEqual(originalEarthquake.ml, decodedEarthquake.ml)
        XCTAssertEqual(originalEarthquake.mw, decodedEarthquake.mw)
        XCTAssertEqual(originalEarthquake.location, decodedEarthquake.location)
        XCTAssertNotEqual(originalEarthquake.id, decodedEarthquake.id)
    }
    
    // MARK: - CodingKeys Tests
    
    func testCodingKeysCorrespondToProperties() {
        // Then - CodingKeys'teki her key property ile eşleşmeli
        XCTAssertEqual(Earthquake.CodingKeys.date.rawValue, "date")
        XCTAssertEqual(Earthquake.CodingKeys.time.rawValue, "time")
        XCTAssertEqual(Earthquake.CodingKeys.latitude.rawValue, "latitude")
        XCTAssertEqual(Earthquake.CodingKeys.longitude.rawValue, "longitude")
        XCTAssertEqual(Earthquake.CodingKeys.depth_km.rawValue, "depth_km")
        XCTAssertEqual(Earthquake.CodingKeys.md.rawValue, "md")
        XCTAssertEqual(Earthquake.CodingKeys.ml.rawValue, "ml")
        XCTAssertEqual(Earthquake.CodingKeys.mw.rawValue, "mw")
        XCTAssertEqual(Earthquake.CodingKeys.location.rawValue, "location")
    }
    
    // MARK: - Edge Cases Tests
    
    func testEarthquakeWithEmptyStrings() throws {
        // Given
        let earthquake = Earthquake(
            date: "",
            time: "",
            latitude: "",
            longitude: "",
            depth_km: "",
            md: "",
            ml: "",
            mw: "",
            location: ""
        )
        
        // When & Then
        let data = try JSONEncoder().encode(earthquake)
        let decodedEarthquake = try JSONDecoder().decode(Earthquake.self, from: data)
        
        XCTAssertEqual(decodedEarthquake.date, "")
        XCTAssertEqual(decodedEarthquake.time, "")
        XCTAssertEqual(decodedEarthquake.latitude, "")
        XCTAssertEqual(decodedEarthquake.longitude, "")
        XCTAssertEqual(decodedEarthquake.depth_km, "")
        XCTAssertEqual(decodedEarthquake.md, "")
        XCTAssertEqual(decodedEarthquake.ml, "")
        XCTAssertEqual(decodedEarthquake.mw, "")
        XCTAssertEqual(decodedEarthquake.location, "")
    }
    
    func testEarthquakeWithUnicodeCharacters() throws {
        // Given
        let earthquake = Earthquake(
            date: "2025-05-14",
            time: "10:30:15",
            latitude: "40.7128",
            longitude: "29.0128",
            depth_km: "10.5",
            md: "3.2",
            ml: "3.4",
            mw: "3.3",
            location: "İstanbul, Türkiye - Çok güzel şehir! 🌟"
        )
        
        // When & Then
        let data = try JSONEncoder().encode(earthquake)
        let decodedEarthquake = try JSONDecoder().decode(Earthquake.self, from: data)
        
        XCTAssertEqual(decodedEarthquake.location, "İstanbul, Türkiye - Çok güzel şehir! 🌟")
    }
    
    // MARK: - Array Decoding Tests
    
    func testEarthquakeArrayDecoding() throws {
        // Given
        let jsonString = """
        [
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
            },
            {
                "date": "2025-05-14",
                "time": "11:45:30",
                "latitude": "39.9334",
                "longitude": "32.8597",
                "depth_km": "15.2",
                "md": "2.8",
                "ml": "3.0",
                "mw": "2.9",
                "location": "Ankara, Turkey"
            }
        ]
        """
        
        // When
        let data = jsonString.data(using: .utf8)!
        let earthquakes = try JSONDecoder().decode([Earthquake].self, from: data)
        
        // Then
        XCTAssertEqual(earthquakes.count, 2)
        
        XCTAssertEqual(earthquakes[0].location, "Istanbul, Turkey")
        XCTAssertEqual(earthquakes[0].latitude, "40.7128")
        
        XCTAssertEqual(earthquakes[1].location, "Ankara, Turkey")
        XCTAssertEqual(earthquakes[1].latitude, "39.9334")
        
        // Her depremin farklı ID'ye sahip olduğunu kontrol et
        XCTAssertNotEqual(earthquakes[0].id, earthquakes[1].id)
    }
    
    // MARK: - Invalid JSON Tests
    
    func testEarthquakeDecodingWithMissingFields() {
        // Given - Bazı alanları eksik JSON
        let incompleteJsonString = """
        {
            "date": "2025-05-14",
            "time": "10:30:15",
            "latitude": "40.7128"
        }
        """
        
        // When & Then
        let data = incompleteJsonString.data(using: .utf8)!
        XCTAssertThrowsError(try JSONDecoder().decode(Earthquake.self, from: data)) { error in
            XCTAssertTrue(error is DecodingError)
        }
    }
    
    func testEarthquakeDecodingWithWrongDataTypes() {
        // Given - Yanlış data type'ları ile JSON
        let invalidJsonString = """
        {
            "date": "2025-05-14",
            "time": "10:30:15",
            "latitude": 40.7128,
            "longitude": "29.0128",
            "depth_km": "10.5",
            "md": "3.2",
            "ml": "3.4",
            "mw": "3.3",
            "location": "Istanbul, Turkey"
        }
        """
        
        // When & Then
        let data = invalidJsonString.data(using: .utf8)!
        XCTAssertThrowsError(try JSONDecoder().decode(Earthquake.self, from: data)) { error in
            XCTAssertTrue(error is DecodingError)
        }
    }
}
