import XCTest
import Foundation
@testable import EarthquakeTracking

class EarthquakeListViewModelTests: XCTestCase {
    
    var viewModel: EarthquakeListViewModel!
    var mockDelegate: MockEarthquakeListViewModelDelegate!
    
    override func setUp() {
        super.setUp()
        viewModel = EarthquakeListViewModel()
        mockDelegate = MockEarthquakeListViewModelDelegate()
        viewModel.delegate = mockDelegate
    }
    
    override func tearDown() {
        viewModel = nil
        mockDelegate = nil
        super.tearDown()
    }
    
    // MARK: - Test Initialization
    func testInitialization() {
        XCTAssertTrue(viewModel.earthquakes.isEmpty)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.errorMessage)
    }
    
    // MARK: - Test fetchEarthquakes()
    func testFetchEarthquakes() {
        // When
        viewModel.fetchEarthquakes()
        
        // Then
        XCTAssertTrue(viewModel.isLoading)
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertTrue(mockDelegate.didChangeLoadingStateCalled)
    }
    
    // MARK: - Test sortByDate()
    func testSortByDate() {
        // Given
        let earthquake1 = Earthquake(date: "2025.05.14", time: "10:30:15", latitude: "40.7128", longitude: "29.0128", depth_km: "10.5", md: "3.2", ml: "3.4", mw: "3.3", location: "Istanbul")
        let earthquake2 = Earthquake(date: "2025.05.15", time: "11:45:30", latitude: "39.9334", longitude: "32.8597", depth_km: "15.2", md: "2.8", ml: "3.0", mw: "2.9", location: "Ankara")
        
        viewModel.allEarthquakes = [earthquake1, earthquake2]
        
        // When
        viewModel.sortByDate()
        
        // Then
        XCTAssertEqual(viewModel.earthquakes.count, 2)
        XCTAssertTrue(mockDelegate.didUpdateEarthquakesCalled)
    }
    
    // MARK: - Test sortByMagnitude()
    func testSortByMagnitude() {
        // Given
        let earthquake1 = Earthquake(date: "2025.05.14", time: "10:30:15", latitude: "40.7128", longitude: "29.0128", depth_km: "10.5", md: "3.2", ml: "3.4", mw: "3.3", location: "Istanbul")
        let earthquake2 = Earthquake(date: "2025.05.15", time: "11:45:30", latitude: "39.9334", longitude: "32.8597", depth_km: "15.2", md: "2.8", ml: "4.0", mw: "2.9", location: "Ankara")
        
        viewModel.allEarthquakes = [earthquake1, earthquake2]
        
        // When
        viewModel.sortByMagnitude()
        
        // Then
        XCTAssertEqual(viewModel.earthquakes.count, 2)
        XCTAssertEqual(viewModel.earthquakes.first?.location, "Ankara") // Higher magnitude first
    }
    
    // MARK: - Test filterByMagnitude()
    func testFilterByMagnitude() {
        // Given
        let earthquake1 = Earthquake(date: "2025.05.14", time: "10:30:15", latitude: "40.7128", longitude: "29.0128", depth_km: "10.5", md: "3.2", ml: "3.4", mw: "3.3", location: "Istanbul")
        let earthquake2 = Earthquake(date: "2025.05.15", time: "11:45:30", latitude: "39.9334", longitude: "32.8597", depth_km: "15.2", md: "2.8", ml: "2.5", mw: "2.9", location: "Ankara")
        
        viewModel.allEarthquakes = [earthquake1, earthquake2]
        
        // When
        viewModel.filterByMagnitude(minMagnitude: 3.0)
        
        // Then
        XCTAssertEqual(viewModel.earthquakes.count, 1)
        XCTAssertEqual(viewModel.earthquakes.first?.location, "Istanbul")
    }
    
    // MARK: - Test getMagnitudeValue()
    func testGetMagnitudeValue() {
        // Given
        let earthquake = Earthquake(date: "2025.05.14", time: "10:30:15", latitude: "40.7128", longitude: "29.0128", depth_km: "10.5", md: "3.2", ml: "3.4", mw: "3.3", location: "Istanbul")
        
        // When
        let magnitude = viewModel.getMagnitudeValue(for: earthquake)
        
        // Then
        XCTAssertEqual(magnitude, 3.4) // ml value should be returned
    }
    
    // MARK: - Test createDateFromStrings()
    func testCreateDateFromStrings() {
        // When
        let date = viewModel.createDateFromStrings(date: "2025.05.14", time: "10:30:15")
        
        // Then
        XCTAssertNotEqual(date, Date.distantPast)
    }
    
    // MARK: - Test Loading State Change (indirect)
    func testLoadingStateChange() {
        // Given
        mockDelegate.didChangeLoadingStateCalled = false
        
        // When - Trigger loading state change indirectly
        viewModel.fetchEarthquakes() // This sets isLoading = true
        
        // Then
        XCTAssertTrue(mockDelegate.didChangeLoadingStateCalled)
        XCTAssertTrue(mockDelegate.lastLoadingState)
    }
    
    // MARK: - Test Error Handling (indirect)
    func testErrorHandling() {
        // Given - We can't set errorMessage directly
        // The property starts as nil, which is expected
        mockDelegate.didReceiveErrorCalled = false
        
        // When - Verify initial state and delegate pattern
        
        // Then
        XCTAssertNil(viewModel.errorMessage) // Initially nil as expected
        XCTAssertFalse(mockDelegate.didReceiveErrorCalled) // Not called yet
        
        // Note: To test actual error scenarios, we would need to mock NetworkManager
        // or trigger a network failure, which requires more complex setup
    }
    
    // MARK: - Test applySortOnLoad()
    func testApplySortOnLoad() {
        // Given
        let earthquake1 = Earthquake(date: "2025.05.14", time: "10:30:15", latitude: "40.7128", longitude: "29.0128", depth_km: "10.5", md: "3.2", ml: "3.4", mw: "3.3", location: "Istanbul")
        let earthquake2 = Earthquake(date: "2025.05.15", time: "11:45:30", latitude: "39.9334", longitude: "32.8597", depth_km: "15.2", md: "2.8", ml: "3.0", mw: "2.9", location: "Ankara")
        
        viewModel.allEarthquakes = [earthquake1, earthquake2]
        
        // When
        viewModel.applySortOnLoad()
        
        // Then - Should sort by date (default)
        XCTAssertEqual(viewModel.earthquakes.count, 2)
        XCTAssertTrue(mockDelegate.didUpdateEarthquakesCalled)
    }
    
    // MARK: - Test Notifications
    func testNotificationPosted() {
        // Given
        let expectation = XCTestExpectation(description: "notification posted")
        
        NotificationCenter.default.addObserver(
            forName: EarthquakeListViewModel.earthquakesUpdatedNotification,
            object: viewModel,
            queue: .main
        ) { _ in
            expectation.fulfill()
        }
        
        // When
        viewModel.sortByDate()
        
        // Then
        wait(for: [expectation], timeout: 1.0)
    }
}

// MARK: - Mock Delegate
class MockEarthquakeListViewModelDelegate: EarthquakeListViewModelDelegate {
    var didUpdateEarthquakesCalled = false
    var didChangeLoadingStateCalled = false
    var didReceiveErrorCalled = false
    var lastLoadingState = false
    var lastErrorMessage: String?
    
    func didUpdateEarthquakes() {
        didUpdateEarthquakesCalled = true
    }
    
    func didChangeLoadingState(isLoading: Bool) {
        didChangeLoadingStateCalled = true
        lastLoadingState = isLoading
    }
    
    func didReceiveError(message: String?) {
        didReceiveErrorCalled = true
        lastErrorMessage = message
    }
}
