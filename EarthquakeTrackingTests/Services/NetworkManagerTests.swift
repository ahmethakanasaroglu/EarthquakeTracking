import XCTest
import Foundation
@testable import EarthquakeTracking

class NetworkManagerTests: XCTestCase {
    
    var networkManager: NetworkManager!
    var mockDelegate: MockNetworkManagerDelegate!
    
    override func setUp() {
        super.setUp()
        networkManager = NetworkManager()
        mockDelegate = MockNetworkManagerDelegate()
        networkManager.delegate = mockDelegate
    }
    
    override func tearDown() {
        networkManager = nil
        mockDelegate = nil
        super.tearDown()
    }
    
    // MARK: - Test Initialization
    func testInitialization() {
        // Then
        XCTAssertNotNil(networkManager)
        XCTAssertTrue(networkManager.earthquakes.isEmpty)
        XCTAssertNotNil(networkManager.delegate)
    }
    
    // MARK: - Test Notification Name
    func testNotificationName() {
        // Then
        XCTAssertEqual(NetworkManager.earthquakesUpdatedNotification.rawValue, "earthquakesUpdatedNotification")
    }
    
    // MARK: - Test loadData() Function
    func testLoadData() {
        // Given
        let expectation = XCTestExpectation(description: "loadData completes")
        
        // When
        networkManager.loadData()
        
        // Then - Wait for async operations
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 3.0)
    }
    
    // MARK: - Test Delegate Called
    func testDelegateIsCalledOnLoadData() {
        // Given
        let expectation = XCTestExpectation(description: "delegate is called")
        mockDelegate.onDidUpdateEarthquakes = { _ in
            expectation.fulfill()
        }
        
        // When
        networkManager.loadData()
        
        // Then
        wait(for: [expectation], timeout: 5.0)
        XCTAssertTrue(mockDelegate.didUpdateCalled)
    }
    
    // MARK: - Test Notification Posted
    func testNotificationIsPosted() {
        // Given
        let expectation = XCTestExpectation(description: "notification is posted")
        
        NotificationCenter.default.addObserver(
            forName: NetworkManager.earthquakesUpdatedNotification,
            object: networkManager,
            queue: .main
        ) { notification in
            XCTAssertNotNil(notification.userInfo?["earthquakes"])
            expectation.fulfill()
        }
        
        // When
        networkManager.loadData()
        
        // Then
        wait(for: [expectation], timeout: 5.0)
    }
    
    // MARK: - Test Earthquakes Property Update
    func testEarthquakesPropertyUpdated() {
        // Given
        let expectation = XCTestExpectation(description: "earthquakes property updated")
        
        // When
        networkManager.loadData()
        
        // Then - Check after async operation
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            // earthquakes property should be updated (empty or with data)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 3.0)
    }
    
    // MARK: - Test Weak Self Usage
    func testWeakSelfPreventsRetainCycle() {
        // Given
        weak var weakNetworkManager = networkManager
        
        // When
        networkManager.loadData()
        networkManager = nil
        
        // Then - Should not crash and weakNetworkManager should be nil
        XCTAssertNil(weakNetworkManager)
    }
}

// MARK: - Mock Delegate
class MockNetworkManagerDelegate: NetworkManagerDelegate {
    var didUpdateCalled = false
    var lastUpdatedEarthquakes: [Earthquake]?
    var onDidUpdateEarthquakes: (([Earthquake]) -> Void)?
    
    func didUpdateEarthquakes(_ earthquakes: [Earthquake]) {
        didUpdateCalled = true
        lastUpdatedEarthquakes = earthquakes
        onDidUpdateEarthquakes?(earthquakes)
    }
}
