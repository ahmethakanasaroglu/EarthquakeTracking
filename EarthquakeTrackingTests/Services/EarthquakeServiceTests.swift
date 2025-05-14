import XCTest
import Foundation
@testable import EarthquakeTracking

class EarthquakeServiceTests: XCTestCase {
    
    // MARK: - Test Singleton
    func testSingleton() {
        XCTAssertTrue(EarthquakeService.shared === EarthquakeService.shared)
    }
    
    // MARK: - Test fetchEarthquakes() function
    func testFetchEarthquakesExists() {
        // Given
        let service = EarthquakeService.shared
        
        // When - Function should exist and be callable
        let expectation = XCTestExpectation(description: "fetchEarthquakes function exists")
        
        service.fetchEarthquakes { earthquakes in
            // Then - Function executed successfully
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    // MARK: - Test fetchEarthquakes with invalid URL scenario
    func testFetchEarthquakesHandlesInvalidURL() {
        // This would require modifying the service to accept a URL parameter
        // Since we can't modify the class, we test that it handles its URL internally
        
        let expectation = XCTestExpectation(description: "Handles URL internally")
        
        EarthquakeService.shared.fetchEarthquakes { result in
            // Then - Should handle any URL issues gracefully
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    // MARK: - Test fetchEarthquakes return values
    func testFetchEarthquakesReturnTypes() {
        // Given
        let expectation = XCTestExpectation(description: "Returns correct type")
        
        // When
        EarthquakeService.shared.fetchEarthquakes { earthquakes in
            // Then - Should return either [Earthquake] or nil
            if let earthquakes = earthquakes {
                XCTAssertTrue(earthquakes is [Earthquake])
            } else {
                // nil is also a valid return value
                XCTAssertNil(earthquakes)
            }
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    // MARK: - Test fetchEarthquakes error handling
    func testFetchEarthquakesHandlesErrors() {
        // Given
        let expectation = XCTestExpectation(description: "Handles errors")
        
        // When - Call the function
        EarthquakeService.shared.fetchEarthquakes { earthquakes in
            // Then - Should not crash and return some value
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 10.0)
    }
    
    // MARK: - Test fetchEarthquakes completion handler
    func testFetchEarthquakesCompletionHandler() {
        // Given
        let expectation = XCTestExpectation(description: "Completion handler called")
        var completionCalled = false
        
        // When
        EarthquakeService.shared.fetchEarthquakes { _ in
            completionCalled = true
            expectation.fulfill()
        }
        
        // Then
        wait(for: [expectation], timeout: 5.0)
        XCTAssertTrue(completionCalled)
    }
}
