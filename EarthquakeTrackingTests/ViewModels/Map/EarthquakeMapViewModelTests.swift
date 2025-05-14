import XCTest
import MapKit
@testable import EarthquakeTracking

class EarthquakeMapViewModelTests: XCTestCase {
    
    var viewModel: EarthquakeMapViewModel!
    var mockDelegate: MockEarthquakeMapViewModelDelegate!
    
    override func setUp() {
        super.setUp()
        viewModel = EarthquakeMapViewModel()
        mockDelegate = MockEarthquakeMapViewModelDelegate()
        viewModel.delegate = mockDelegate
    }
    
    override func tearDown() {
        viewModel = nil
        mockDelegate = nil
        super.tearDown()
    }
    
    // MARK: - Test Helpers
    private func createMockEarthquakes() -> [Earthquake] {
        return [
            Earthquake(date: "2024-01-01", time: "10:00:00", latitude: "39.0", longitude: "35.0",
                      depth_km: "10.0", md: "", ml: "4.5", mw: "", location: "Location 1"),
            Earthquake(date: "2024-01-02", time: "11:00:00", latitude: "40.0", longitude: "36.0",
                      depth_km: "15.0", md: "", ml: "3.2", mw: "", location: "Location 2")
        ]
    }
    
    private func simulateEarthquakeUpdate(_ earthquakes: [Earthquake]) {
        NotificationCenter.default.post(
            name: NetworkManager.earthquakesUpdatedNotification,
            object: nil,
            userInfo: ["earthquakes": earthquakes]
        )
    }
    
    // MARK: - Core Functionality Tests
    func testFetchEarthquakes() {
        viewModel.fetchEarthquakes()
        
        XCTAssertTrue(viewModel.isLoading)
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertTrue(mockDelegate.didChangeLoadingStateCalled)
    }
    
    func testEarthquakeUpdate() {
        let earthquakes = createMockEarthquakes()
        
        simulateEarthquakeUpdate(earthquakes)
        
        XCTAssertEqual(viewModel.earthquakes.count, earthquakes.count)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertTrue(mockDelegate.didUpdateEarthquakesCalled)
    }
    
    func testSelectEarthquake() {
        let earthquakes = createMockEarthquakes()
        simulateEarthquakeUpdate(earthquakes)
        let annotations = viewModel.getAnnotations()
        
        viewModel.selectEarthquake(annotations[0])
        
        XCTAssertEqual(viewModel.selectedEarthquake?.location, earthquakes[0].location)
        XCTAssertTrue(mockDelegate.didSelectEarthquakeCalled)
    }
    
    func testClearSelectedEarthquake() {
        let earthquakes = createMockEarthquakes()
        simulateEarthquakeUpdate(earthquakes)
        let annotations = viewModel.getAnnotations()
        viewModel.selectEarthquake(annotations[0])
        
        viewModel.clearSelectedEarthquake()
        
        XCTAssertNil(viewModel.selectedEarthquake)
    }
    
    // MARK: - Magnitude Tests
    func testGetMagnitude() {
        let mlEarthquake = Earthquake(date: "", time: "", latitude: "", longitude: "",
                                     depth_km: "", md: "", ml: "5.5", mw: "", location: "")
        let mwEarthquake = Earthquake(date: "", time: "", latitude: "", longitude: "",
                                     depth_km: "", md: "", ml: "", mw: "6.2", location: "")
        let mdEarthquake = Earthquake(date: "", time: "", latitude: "", longitude: "",
                                     depth_km: "", md: "4.8", ml: "", mw: "", location: "")
        let noMagEarthquake = Earthquake(date: "", time: "", latitude: "", longitude: "",
                                        depth_km: "", md: "", ml: "", mw: "", location: "")
        
        XCTAssertEqual(viewModel.getMagnitude(for: mlEarthquake), 5.5)
        XCTAssertEqual(viewModel.getMagnitude(for: mwEarthquake), 6.2)
        XCTAssertEqual(viewModel.getMagnitude(for: mdEarthquake), 4.8)
        XCTAssertEqual(viewModel.getMagnitude(for: noMagEarthquake), 0.0)
    }
    
    // MARK: - Color, Scale, Icon Tests
    func testMagnitudeBasedProperties() {
        let earthquakes = [
            (magnitude: "6.5", expectedColor: UIColor(red: 1.0, green: 0.0, blue: 0.0, alpha: 1.0), expectedScale: CGFloat(1.4)),
            (magnitude: "5.2", expectedColor: UIColor(red: 1.0, green: 0.4, blue: 0.0, alpha: 1.0), expectedScale: CGFloat(1.2)),
            (magnitude: "4.3", expectedColor: UIColor(red: 0.9, green: 0.6, blue: 0.0, alpha: 1.0), expectedScale: CGFloat(1.1)),
            (magnitude: "3.1", expectedColor: UIColor(red: 0.8, green: 0.8, blue: 0.0, alpha: 1.0), expectedScale: CGFloat(1.0)),
            (magnitude: "2.5", expectedColor: UIColor(red: 0.6, green: 0.8, blue: 0.0, alpha: 1.0), expectedScale: CGFloat(0.9)),
            (magnitude: "1.8", expectedColor: UIColor(red: 0.0, green: 0.7, blue: 0.0, alpha: 1.0), expectedScale: CGFloat(0.8))
        ]
        
        for (mag, expectedColor, expectedScale) in earthquakes {
            let earthquake = Earthquake(date: "", time: "", latitude: "", longitude: "",
                                       depth_km: "", md: "", ml: mag, mw: "", location: "")
            
            XCTAssertEqual(viewModel.getColor(for: earthquake), expectedColor)
            XCTAssertEqual(viewModel.getMarkerScale(for: earthquake), expectedScale)
        }
    }
    
    func testGetMarkerIcon() {
        let highMag = Earthquake(date: "", time: "", latitude: "", longitude: "",
                                depth_km: "", md: "", ml: "5.5", mw: "", location: "")
        let medMag = Earthquake(date: "", time: "", latitude: "", longitude: "",
                               depth_km: "", md: "", ml: "4.5", mw: "", location: "")
        let lowMag = Earthquake(date: "", time: "", latitude: "", longitude: "",
                               depth_km: "", md: "", ml: "3.5", mw: "", location: "")
        
        XCTAssertEqual(viewModel.getMarkerIcon(for: highMag), UIImage(systemName: "exclamationmark.triangle.fill"))
        XCTAssertEqual(viewModel.getMarkerIcon(for: medMag), UIImage(systemName: "exclamationmark"))
        XCTAssertEqual(viewModel.getMarkerIcon(for: lowMag), UIImage(systemName: "waveform.path.ecg"))
    }
    
    // MARK: - Coordinate and Span Tests
    func testGetCenterCoordinate() {
        let earthquakes = createMockEarthquakes()
        simulateEarthquakeUpdate(earthquakes)
        
        let coordinate = viewModel.getCenterCoordinate()
        
        XCTAssertEqual(coordinate?.latitude, 39.0)
        XCTAssertEqual(coordinate?.longitude, 35.0)
    }
    
    func testGetInitialSpan() {
        let earthquakes = createMockEarthquakes()
        simulateEarthquakeUpdate(earthquakes)
        
        let span = viewModel.getInitialSpan()
        
        // Mock depremlerin koordinatları yakın olduğu için minimum 5.0 değerini döndürür
        XCTAssertGreaterThanOrEqual(span.latitudeDelta, 5.0)
        XCTAssertGreaterThanOrEqual(span.longitudeDelta, 5.0)
    }
    
    func testGetInitialSpanWithDistantEarthquakes() {
        // Daha uzak koordinatlara sahip depremler oluşturalım
        let distantEarthquakes = [
            Earthquake(date: "2024-01-01", time: "10:00:00", latitude: "35.0", longitude: "30.0",
                      depth_km: "10.0", md: "", ml: "4.5", mw: "", location: "Location 1"),
            Earthquake(date: "2024-01-02", time: "11:00:00", latitude: "45.0", longitude: "45.0",
                      depth_km: "15.0", md: "", ml: "3.2", mw: "", location: "Location 2")
        ]
        simulateEarthquakeUpdate(distantEarthquakes)
        
        let span = viewModel.getInitialSpan()
        
        // Uzak koordinatlar için span daha büyük olmalı
        XCTAssertGreaterThan(span.latitudeDelta, 5.0)
        XCTAssertGreaterThan(span.longitudeDelta, 5.0)
    }
    
    func testGetInitialSpanWithNoEarthquakes() {
        let span = viewModel.getInitialSpan()
        
        XCTAssertEqual(span.latitudeDelta, 10.0)
        XCTAssertEqual(span.longitudeDelta, 10.0)
    }
    
    // MARK: - Filter Tests
    func testFilterByMagnitude() {
        let earthquakes = [
            Earthquake(date: "", time: "", latitude: "39.0", longitude: "35.0",
                      depth_km: "", md: "", ml: "5.5", mw: "", location: "High"),
            Earthquake(date: "", time: "", latitude: "40.0", longitude: "36.0",
                      depth_km: "", md: "", ml: "3.5", mw: "", location: "Low")
        ]
        simulateEarthquakeUpdate(earthquakes)
        
        viewModel.filterByMagnitude(minMagnitude: 4.0)
        
        XCTAssertEqual(viewModel.minMagnitudeFilter, 4.0)
        XCTAssertEqual(viewModel.earthquakes.count, 1)
        XCTAssertEqual(viewModel.earthquakes[0].location, "High")
    }
    
    // MARK: - Annotation Tests
    func testGetAnnotations() {
        let earthquakes = createMockEarthquakes()
        simulateEarthquakeUpdate(earthquakes)
        
        let annotations = viewModel.getAnnotations()
        
        XCTAssertEqual(annotations.count, earthquakes.count)
        XCTAssertEqual(annotations[0].coordinate.latitude, 39.0)
        XCTAssertEqual(annotations[0].title, "Location 1")
    }
    
    func testGetAnnotationsWithSelection() {
        let earthquakes = createMockEarthquakes()
        simulateEarthquakeUpdate(earthquakes)
        let annotations = viewModel.getAnnotations()
        viewModel.selectEarthquake(annotations[0])  // Public method kullanıyoruz
        
        let newAnnotations = viewModel.getAnnotations()
        
        XCTAssertTrue(newAnnotations[0].isSelected)
        XCTAssertFalse(newAnnotations[1].isSelected)
    }
    
    // MARK: - NetworkManagerDelegate Test
    func testDidUpdateEarthquakes() {
        let earthquakes = createMockEarthquakes()
        
        viewModel.didUpdateEarthquakes(earthquakes)
        
        XCTAssertEqual(viewModel.earthquakes.count, earthquakes.count)
        XCTAssertFalse(viewModel.isLoading)
    }
    
    // MARK: - Error Handling Tests
    func testErrorMessageProperty() {
        // Test olumlu senaryo
        viewModel.fetchEarthquakes()
        XCTAssertNil(viewModel.errorMessage)
        
        // Error durumu test etmek için notification gönderebiliriz
        // Gerçek implementasyonda error handling testi için mock network manager gerekebilir
    }
    
    // MARK: - Notification Tests
    func testNotificationPosting() {
        let earthquakes = createMockEarthquakes()
        
        // Notification observer ekleme
        let expectation = self.expectation(forNotification: EarthquakeMapViewModel.earthquakesUpdatedNotification, object: viewModel)
        
        simulateEarthquakeUpdate(earthquakes)
        
        waitForExpectations(timeout: 1.0)
    }
    
    func testLoadingStateNotification() {
        let expectation = self.expectation(forNotification: EarthquakeMapViewModel.loadingStateChangedNotification, object: viewModel)
        
        viewModel.fetchEarthquakes()
        
        waitForExpectations(timeout: 1.0)
    }
    
    // MARK: - Edge Cases Tests
    func testGetAnnotationsWithInvalidCoordinates() {
        let invalidEarthquake = Earthquake(date: "2024-01-01", time: "10:00:00",
                                          latitude: "", longitude: "invalid",
                                          depth_km: "10.0", md: "", ml: "4.5", mw: "", location: "Invalid")
        simulateEarthquakeUpdate([invalidEarthquake])
        
        let annotations = viewModel.getAnnotations()
        
        XCTAssertEqual(annotations.count, 0) // Invalid coordinates should be filtered out
    }
    
    func testFilterWithNoEarthquakes() {
        // Boş liste ile filter test
        viewModel.filterByMagnitude(minMagnitude: 3.0)
        
        XCTAssertEqual(viewModel.earthquakes.count, 0)
        XCTAssertEqual(viewModel.minMagnitudeFilter, 3.0)
    }
}

// MARK: - Mock Delegate
class MockEarthquakeMapViewModelDelegate: EarthquakeMapViewModelDelegate {
    var didUpdateEarthquakesCalled = false
    var didSelectEarthquakeCalled = false
    var didChangeLoadingStateCalled = false
    var didReceiveErrorCalled = false
    
    func didUpdateEarthquakes() { didUpdateEarthquakesCalled = true }
    func didSelectEarthquake(_ earthquake: Earthquake?) { didSelectEarthquakeCalled = true }
    func didChangeLoadingState(isLoading: Bool) { didChangeLoadingStateCalled = true }
    func didReceiveError(message: String?) { didReceiveErrorCalled = true }
}

// MARK: - EarthquakeAnnotation Tests
class EarthquakeAnnotationTests: XCTestCase {
    
    func testEarthquakeAnnotation() {
        let earthquake = Earthquake(date: "2024-01-01", time: "10:00:00", latitude: "39.0", longitude: "35.0",
                                   depth_km: "10.0", md: "", ml: "4.5", mw: "", location: "Test Location")
        let annotation = EarthquakeAnnotation(coordinate: CLLocationCoordinate2D(latitude: 39.0, longitude: 35.0),
                                             earthquake: earthquake)
        
        XCTAssertEqual(annotation.title, "Test Location")
        XCTAssertTrue(annotation.subtitle?.contains("Büyüklük: 4.5") ?? false)
        XCTAssertTrue(annotation.subtitle?.contains("Derinlik: 10.0") ?? false)
        XCTAssertFalse(annotation.isSelected)
        XCTAssertTrue(annotation.matchesEarthquake(earthquake))
    }
    
    func testAnnotationMatching() {
        let earthquake1 = Earthquake(date: "2024-01-01", time: "10:00:00", latitude: "39.0", longitude: "35.0",
                                    depth_km: "10.0", md: "", ml: "4.5", mw: "", location: "Same")
        let earthquake2 = Earthquake(date: "2024-01-01", time: "10:00:00", latitude: "39.0", longitude: "35.0",
                                    depth_km: "10.0", md: "", ml: "4.5", mw: "", location: "Same")
        let earthquake3 = Earthquake(date: "2024-01-02", time: "11:00:00", latitude: "40.0", longitude: "36.0",
                                    depth_km: "15.0", md: "", ml: "3.2", mw: "", location: "Different")
        
        let annotation = EarthquakeAnnotation(coordinate: CLLocationCoordinate2D(latitude: 39.0, longitude: 35.0),
                                             earthquake: earthquake1)
        
        XCTAssertTrue(annotation.matchesEarthquake(earthquake2))
        XCTAssertFalse(annotation.matchesEarthquake(earthquake3))
    }
}
