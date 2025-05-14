import XCTest
import CoreLocation
import UserNotifications
import UIKit
@testable import EarthquakeTracking

class PersonalizedViewModelTests: XCTestCase {
    
    var viewModel: PersonalizedViewModel!
    var mockDelegate: MockPersonalizedViewModelDelegate!
    
    override func setUp() {
        super.setUp()
        // Clear UserDefaults before each test
        UserDefaults.standard.removeObject(forKey: "enableNotifications")
        UserDefaults.standard.removeObject(forKey: "magnitudeThreshold")
        UserDefaults.standard.removeObject(forKey: "monitoredLocations")
        
        viewModel = PersonalizedViewModel()
        mockDelegate = MockPersonalizedViewModelDelegate()
        viewModel.delegate = mockDelegate
        
        // Reset delegate flags
        mockDelegate.reset()
    }
    
    override func tearDown() {
        // Clear UserDefaults after each test
        UserDefaults.standard.removeObject(forKey: "enableNotifications")
        UserDefaults.standard.removeObject(forKey: "magnitudeThreshold")
        UserDefaults.standard.removeObject(forKey: "monitoredLocations")
        
        viewModel = nil
        mockDelegate = nil
        super.tearDown()
    }
    
    // MARK: - Test Initialization
    func testInitialization() {
        XCTAssertNotNil(viewModel)
        XCTAssertEqual(viewModel.selectedMagnitudeThreshold, 4.0)
        XCTAssertTrue(viewModel.monitoredLocations.isEmpty)
        XCTAssertFalse(viewModel.isAddingMonitoredLocation)
        XCTAssertNotNil(viewModel.userLocation)
        XCTAssertEqual(viewModel.userLocation?.latitude, 39.9334)
        XCTAssertEqual(viewModel.userLocation?.longitude, 32.8597)
    }
    
    // MARK: - Test setEnableNotifications()
    func testSetEnableNotifications() {
        // When
        viewModel.setEnableNotifications(true)
        
        // Then
        XCTAssertTrue(viewModel.enableNotifications)
        XCTAssertTrue(mockDelegate.didUpdateNotificationSettingsCalled)
        XCTAssertTrue(mockDelegate.lastNotificationEnabled)
    }
    
    // MARK: - Test setMagnitudeThreshold()
    func testSetMagnitudeThreshold() {
        // Given
        let threshold = 5.5
        
        // When
        viewModel.setMagnitudeThreshold(threshold)
        
        // Then
        XCTAssertEqual(viewModel.selectedMagnitudeThreshold, threshold)
        XCTAssertTrue(mockDelegate.didUpdateMagnitudeThresholdCalled)
        XCTAssertEqual(mockDelegate.lastMagnitudeThreshold, threshold)
    }
    
    // MARK: - Test setIsAddingMonitoredLocation()
    func testSetIsAddingMonitoredLocation() {
        // When
        viewModel.setIsAddingMonitoredLocation(true)
        
        // Then
        XCTAssertTrue(viewModel.isAddingMonitoredLocation)
        XCTAssertTrue(mockDelegate.didUpdateAddingLocationStateCalled)
        XCTAssertTrue(mockDelegate.lastIsAdding)
    }
    
    // MARK: - Test setNewLocationName()
    func testSetNewLocationName() {
        // Given
        let locationName = "Test Location"
        
        // When
        viewModel.setNewLocationName(locationName)
        
        // Then
        XCTAssertEqual(viewModel.newLocationName, locationName)
        XCTAssertTrue(mockDelegate.didUpdateNewLocationCalled)
        XCTAssertEqual(mockDelegate.lastLocationName, locationName)
    }
    
    // MARK: - Test setNewLocationCoordinate()
    func testSetNewLocationCoordinate() {
        // Given
        let coordinate = CLLocationCoordinate2D(latitude: 40.7589, longitude: 29.4315)
        
        // When
        viewModel.setNewLocationCoordinate(coordinate)
        
        // Then
        XCTAssertNotNil(viewModel.newLocationCoordinate)
        XCTAssertEqual(viewModel.newLocationCoordinate!.latitude, coordinate.latitude, accuracy: 0.0001)
        XCTAssertEqual(viewModel.newLocationCoordinate!.longitude, coordinate.longitude, accuracy: 0.0001)
        XCTAssertTrue(mockDelegate.didUpdateNewLocationCalled)
    }
    
    // MARK: - Test addMonitoredLocation()
    func testAddMonitoredLocation() {
        // Given
        let locationName = "Test Location"
        let coordinate = CLLocationCoordinate2D(latitude: 40.7589, longitude: 29.4315)
        
        viewModel.setNewLocationName(locationName)
        viewModel.setNewLocationCoordinate(coordinate)
        
        // When
        viewModel.addMonitoredLocation()
        
        // Then
        XCTAssertEqual(viewModel.monitoredLocations.count, 1)
        XCTAssertEqual(viewModel.monitoredLocations.first?.name, locationName)
        XCTAssertEqual(viewModel.monitoredLocations.first!.latitude, coordinate.latitude, accuracy: 0.0001)
        XCTAssertEqual(viewModel.monitoredLocations.first!.longitude, coordinate.longitude, accuracy: 0.0001)
        XCTAssertTrue(mockDelegate.didUpdateMonitoredLocationsCalled)
    }
    
    // MARK: - Test addMonitoredLocation() with empty data
    func testAddMonitoredLocationWithEmptyData() {
        // Given - No name or coordinate set
        let initialCount = viewModel.monitoredLocations.count
        
        // When
        viewModel.addMonitoredLocation()
        
        // Then - Should not add location
        XCTAssertEqual(viewModel.monitoredLocations.count, initialCount)
    }
    
    // MARK: - Test removeMonitoredLocation()
    func testRemoveMonitoredLocation() {
        // Given - Add a location first
        viewModel.setNewLocationName("Test")
        viewModel.setNewLocationCoordinate(CLLocationCoordinate2D(latitude: 40.0, longitude: 29.0))
        viewModel.addMonitoredLocation()
        
        // Verify it was added
        XCTAssertEqual(viewModel.monitoredLocations.count, 1)
        
        // Reset delegate call flag
        mockDelegate.didUpdateMonitoredLocationsCalled = false
        
        // When
        viewModel.removeMonitoredLocation(at: 0)
        
        // Then
        XCTAssertTrue(viewModel.monitoredLocations.isEmpty)
        XCTAssertTrue(mockDelegate.didUpdateMonitoredLocationsCalled)
    }
    
    // MARK: - Test removeMonitoredLocation() with invalid index
    func testRemoveMonitoredLocationWithInvalidIndex() {
        // Given - No locations
        XCTAssertTrue(viewModel.monitoredLocations.isEmpty)
        
        // When - Try to remove with invalid index
        viewModel.removeMonitoredLocation(at: 5)
        
        // Then - Should not crash
        XCTAssertTrue(viewModel.monitoredLocations.isEmpty)
    }
    
    // MARK: - Test resetNewLocationForm()
    func testResetNewLocationForm() {
        // Given
        viewModel.setNewLocationName("Test")
        viewModel.setNewLocationCoordinate(CLLocationCoordinate2D(latitude: 40.0, longitude: 29.0))
        viewModel.setIsAddingMonitoredLocation(true)
        
        // When
        viewModel.resetNewLocationForm()
        
        // Then
        XCTAssertTrue(viewModel.newLocationName.isEmpty)
        XCTAssertNil(viewModel.newLocationCoordinate)
        XCTAssertFalse(viewModel.isAddingMonitoredLocation)
    }
    
    // MARK: - Test setSimulationMagnitude()
    func testSetSimulationMagnitude() {
        // Given
        let magnitude = 6.5
        
        // When
        viewModel.setSimulationMagnitude(magnitude)
        
        // Then
        XCTAssertEqual(viewModel.selectedSimulationMagnitude, magnitude)
        XCTAssertTrue(mockDelegate.didUpdateSimulationSettingsCalled)
        XCTAssertEqual(mockDelegate.lastSimulationMagnitude, magnitude)
    }
    
    // MARK: - Test startSimulation()
    func testStartSimulation() {
        // When
        viewModel.startSimulation()
        
        // Then
        XCTAssertTrue(viewModel.isSimulationActive)
        XCTAssertTrue(mockDelegate.didUpdateSimulationSettingsCalled)
        XCTAssertTrue(mockDelegate.lastSimulationIsActive)
    }
    
    // MARK: - Test stopSimulation()
    func testStopSimulation() {
        // Given
        viewModel.startSimulation()
        XCTAssertTrue(viewModel.isSimulationActive)
        
        // When
        viewModel.stopSimulation()
        
        // Then
        XCTAssertFalse(viewModel.isSimulationActive)
        XCTAssertEqual(viewModel.simulationIntensity, 0.0)
        XCTAssertTrue(mockDelegate.didUpdateSimulationSettingsCalled)
    }
    
    // MARK: - Test loadRiskDataForCurrentLocation()
    func testLoadRiskDataForCurrentLocation() {
        // Given
        let expectation = XCTestExpectation(description: "Risk data loaded")
        var callCount = 0
        
        mockDelegate.onDidUpdateRiskData = { level, isLoading, coordinates in
            if !isLoading {
                expectation.fulfill()
            }
        }
        
        // When
        viewModel.loadRiskDataForCurrentLocation()
        
        // Then
        wait(for: [expectation], timeout: 3.0)
        XCTAssertTrue(mockDelegate.didUpdateRiskDataCalled)
        XCTAssertFalse(viewModel.isLoadingRiskData)
        XCTAssertNotEqual(viewModel.riskLevelForCurrentLocation, .unknown)
        XCTAssertFalse(viewModel.riskAreaCoordinates.isEmpty)
    }
    
    // MARK: - Test loadRiskDataForCurrentLocation() - Multiple calls
    func testLoadRiskDataForCurrentLocationMultipleCalls() {
        // Given
        let expectation = XCTestExpectation(description: "First risk data loaded")
        
        mockDelegate.onDidUpdateRiskData = { level, isLoading, coordinates in
            if !isLoading {
                expectation.fulfill()
            }
        }
        
        // When - First call
        viewModel.loadRiskDataForCurrentLocation()
        wait(for: [expectation], timeout: 3.0)
        
        // Reset mock
        mockDelegate.reset()
        
        // When - Second call (should be cached)
        viewModel.loadRiskDataForCurrentLocation()
        
        // Then - Should not trigger new loading since it's cached
        XCTAssertFalse(mockDelegate.didUpdateRiskDataCalled)
    }
    
    // MARK: - Test saveUserPreferences()
    func testSaveUserPreferences() {
        // Given
        viewModel.setEnableNotifications(true)
        viewModel.setMagnitudeThreshold(5.0)
        
        // Add a monitored location
        viewModel.setNewLocationName("Test Location")
        viewModel.setNewLocationCoordinate(CLLocationCoordinate2D(latitude: 40.0, longitude: 29.0))
        viewModel.addMonitoredLocation()
        
        // When
        viewModel.saveUserPreferences()
        
        // Then - Verify UserDefaults are set
        let defaults = UserDefaults.standard
        XCTAssertTrue(defaults.bool(forKey: "enableNotifications"))
        XCTAssertEqual(defaults.double(forKey: "magnitudeThreshold"), 5.0)
        XCTAssertNotNil(defaults.object(forKey: "monitoredLocations"))
    }
    
    // MARK: - Test loadUserPreferences()
    func testLoadUserPreferences() {
        // Given - Set some preferences in UserDefaults
        let defaults = UserDefaults.standard
        defaults.set(true, forKey: "enableNotifications")
        defaults.set(5.5, forKey: "magnitudeThreshold")
        
        // Create and encode a test location
        let testLocation = MonitoredLocation(id: UUID(), name: "Test", latitude: 40.0, longitude: 29.0, notificationThreshold: 4.0)
        let encoder = JSONEncoder()
        if let data = try? encoder.encode([testLocation]) {
            defaults.set(data, forKey: "monitoredLocations")
        }
        
        // When - Create new ViewModel that will load preferences
        let newViewModel = PersonalizedViewModel()
        
        // Then
        XCTAssertTrue(newViewModel.enableNotifications)
        XCTAssertEqual(newViewModel.selectedMagnitudeThreshold, 5.5)
        XCTAssertEqual(newViewModel.monitoredLocations.count, 1)
        XCTAssertEqual(newViewModel.monitoredLocations.first?.name, "Test")
    }
    
    // MARK: - Test requestNotificationAuthorization()
    func testRequestNotificationAuthorization() {
        // This test verifies the method exists and can be called
        // Actual testing of UNUserNotificationCenter would require mocking
        
        // When
        viewModel.requestNotificationAuthorization()
        
        // Then - No assertion needed, just verify it doesn't crash
        XCTAssertTrue(true)
    }
    
    // MARK: - Test locationManager delegate
    func testLocationManagerDidUpdateLocations() {
        // Given
        let locations = [CLLocation(latitude: 41.0082, longitude: 28.9784)]
        let mockLocationManager = CLLocationManager()
        
        // When
        viewModel.locationManager(mockLocationManager, didUpdateLocations: locations)
        
        // Then
        XCTAssertEqual(viewModel.userLocation!.latitude, 41.0082, accuracy: 0.0001)
        XCTAssertEqual(viewModel.userLocation!.longitude, 28.9784, accuracy: 0.0001)
        XCTAssertTrue(mockDelegate.didUpdateUserLocationCalled)
    }
    
    // MARK: - Test clearCachedData()
    func testClearCachedData() {
        // Given - Load some risk data first
        let expectation = XCTestExpectation(description: "Risk data loaded")
        mockDelegate.onDidUpdateRiskData = { level, isLoading, coordinates in
            if !isLoading {
                expectation.fulfill()
            }
        }
        
        viewModel.loadRiskDataForCurrentLocation()
        wait(for: [expectation], timeout: 3.0)
        
        // When - Trigger clear cached data
        NotificationCenter.default.post(name: UIApplication.didFinishLaunchingNotification, object: nil)
        
        // Then - We can't directly verify cache clearing, but test that it doesn't crash
        XCTAssertTrue(true)
    }
    
    // MARK: - Test Notification Names
    func testNotificationNames() {
        XCTAssertEqual(PersonalizedViewModel.notificationSettingsChangedNotification.rawValue, "notificationSettingsChangedNotification")
        XCTAssertEqual(PersonalizedViewModel.magnitudeThresholdChangedNotification.rawValue, "magnitudeThresholdChangedNotification")
        XCTAssertEqual(PersonalizedViewModel.monitoredLocationsChangedNotification.rawValue, "monitoredLocationsChangedNotification")
        XCTAssertEqual(PersonalizedViewModel.addingLocationStateChangedNotification.rawValue, "addingLocationStateChangedNotification")
        XCTAssertEqual(PersonalizedViewModel.newLocationChangedNotification.rawValue, "newLocationChangedNotification")
        XCTAssertEqual(PersonalizedViewModel.userLocationChangedNotification.rawValue, "userLocationChangedNotification")
        XCTAssertEqual(PersonalizedViewModel.simulationSettingsChangedNotification.rawValue, "simulationSettingsChangedNotification")
        XCTAssertEqual(PersonalizedViewModel.riskDataChangedNotification.rawValue, "riskDataChangedNotification")
    }
    
    // MARK: - Test RiskLevel Enum
    func testRiskLevelRawValues() {
        XCTAssertEqual(RiskLevel.unknown.rawValue, "Bilinmiyor")
        XCTAssertEqual(RiskLevel.low.rawValue, "Düşük")
        XCTAssertEqual(RiskLevel.medium.rawValue, "Orta")
        XCTAssertEqual(RiskLevel.high.rawValue, "Yüksek")
    }
    
    func testRiskLevelColors() {
        XCTAssertEqual(RiskLevel.unknown.color, .systemGray)
        XCTAssertEqual(RiskLevel.low.color, .systemGreen)
        XCTAssertEqual(RiskLevel.medium.color, .systemOrange)
        XCTAssertEqual(RiskLevel.high.color, .systemRed)
    }
    
    // MARK: - Test SimulationEffect Enum
    func testSimulationEffectDescriptions() {
        XCTAssertTrue(SimulationEffect.light.description.contains("Hafif"))
        XCTAssertTrue(SimulationEffect.moderate.description.contains("Orta"))
        XCTAssertTrue(SimulationEffect.strong.description.contains("Şiddetli"))
        XCTAssertTrue(SimulationEffect.severe.description.contains("Çok şiddetli"))
    }
    
    // MARK: - Test SeededRandomGenerator
    func testSeededRandomGenerator() {
        // Given
        var generator = SeededRandomGenerator(seed: 42)
        
        // When
        let random1 = generator.nextDouble()
        let random2 = generator.nextDouble()
        
        // Then
        XCTAssertTrue(random1 >= 0.0 && random1 <= 1.0)
        XCTAssertTrue(random2 >= 0.0 && random2 <= 1.0)
        XCTAssertNotEqual(random1, random2)
        
        // Test same seed produces same sequence
        var generator2 = SeededRandomGenerator(seed: 42)
        let random3 = generator2.nextDouble()
        XCTAssertEqual(random3, random1, accuracy: 0.0001)
    }
    
    // MARK: - Test MonitoredLocation
    func testMonitoredLocationCreation() {
        // Given & When
        let location = MonitoredLocation(
            id: UUID(),
            name: "Test Location",
            latitude: 40.7589,
            longitude: 29.4315,
            notificationThreshold: 4.5
        )
        
        // Then
        XCTAssertEqual(location.name, "Test Location")
        XCTAssertEqual(location.latitude, 40.7589)
        XCTAssertEqual(location.longitude, 29.4315)
        XCTAssertEqual(location.notificationThreshold, 4.5)
    }
    
    // MARK: - Test MonitoredLocation Codable
    func testMonitoredLocationCodable() throws {
        // Given
        let location = MonitoredLocation(
            id: UUID(),
            name: "Test Location",
            latitude: 40.7589,
            longitude: 29.4315,
            notificationThreshold: 4.5
        )
        
        // When - Encode
        let encoder = JSONEncoder()
        let data = try encoder.encode(location)
        
        // Then - Decode
        let decoder = JSONDecoder()
        let decodedLocation = try decoder.decode(MonitoredLocation.self, from: data)
        
        XCTAssertEqual(location.name, decodedLocation.name)
        XCTAssertEqual(location.latitude, decodedLocation.latitude)
        XCTAssertEqual(location.longitude, decodedLocation.longitude)
        XCTAssertEqual(location.notificationThreshold, decodedLocation.notificationThreshold)
    }
    
    // MARK: - Test Simulation Effects Based on Magnitude
    func testSimulationEffectForMagnitude() {
        // Reset mock delegate for clean testing
        mockDelegate.reset()
        
        // Test light magnitude (< 4.0)
        viewModel.setSimulationMagnitude(3.5)
        viewModel.startSimulation()
        
        // Wait a moment for simulation to set up
        let expectation1 = expectation(description: "Light simulation")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            XCTAssertEqual(self.viewModel.simulationEffect, .light)
            expectation1.fulfill()
        }
        wait(for: [expectation1], timeout: 1.0)
        
        viewModel.stopSimulation()
        mockDelegate.reset()
        
        // Test moderate magnitude (4.0 <= x < 5.0)
        viewModel.setSimulationMagnitude(4.5)
        viewModel.startSimulation()
        
        let expectation2 = expectation(description: "Moderate simulation")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            XCTAssertEqual(self.viewModel.simulationEffect, .moderate)
            expectation2.fulfill()
        }
        wait(for: [expectation2], timeout: 1.0)
        
        viewModel.stopSimulation()
        mockDelegate.reset()
        
        // Test strong magnitude (5.0 <= x < 7.0)
        viewModel.setSimulationMagnitude(6.0)
        viewModel.startSimulation()
        
        let expectation3 = expectation(description: "Strong simulation")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            XCTAssertEqual(self.viewModel.simulationEffect, .strong)
            expectation3.fulfill()
        }
        wait(for: [expectation3], timeout: 1.0)
        
        viewModel.stopSimulation()
        mockDelegate.reset()
        
        // Test severe magnitude (>= 7.0)
        viewModel.setSimulationMagnitude(7.5)
        viewModel.startSimulation()
        
        let expectation4 = expectation(description: "Severe simulation")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            XCTAssertEqual(self.viewModel.simulationEffect, .severe)
            expectation4.fulfill()
        }
        wait(for: [expectation4], timeout: 1.0)
        
        viewModel.stopSimulation()
    }
    
    // MARK: - Test Simulation Timer
    func testSimulationTimer() {
        // Given
        let expectation = XCTestExpectation(description: "Simulation intensity updated")
        var intensityUpdated = false
        
        mockDelegate.onDidUpdateSimulationSettings = { magnitude, isActive, intensity, effect in
            if isActive && intensity > 0 && !intensityUpdated {
                intensityUpdated = true
                expectation.fulfill()
            }
        }
        
        // When
        viewModel.startSimulation()
        
        // Then
        wait(for: [expectation], timeout: 2.0)
        XCTAssertTrue(intensityUpdated)
        
        // Clean up
        viewModel.stopSimulation()
    }
    
    // MARK: - Test Risk Data Generation for Different Levels
    func testRiskDataGenerationForDifferentLevels() {
        // This test verifies that different risk levels generate different numbers of coordinates
        // We'll test indirectly by checking that coordinates are generated
        
        let expectation = XCTestExpectation(description: "Risk data generated")
        mockDelegate.onDidUpdateRiskData = { level, isLoading, coordinates in
            if !isLoading && !coordinates.isEmpty {
                expectation.fulfill()
            }
        }
        
        // When
        viewModel.loadRiskDataForCurrentLocation()
        
        // Then
        wait(for: [expectation], timeout: 3.0)
        XCTAssertFalse(viewModel.riskAreaCoordinates.isEmpty)
        
        // Verify coordinates are within reasonable range
        for coordinate in viewModel.riskAreaCoordinates {
            XCTAssertTrue(coordinate.latitude >= -90 && coordinate.latitude <= 90)
            XCTAssertTrue(coordinate.longitude >= -180 && coordinate.longitude <= 180)
        }
    }
}

// MARK: - Mock Delegate
class MockPersonalizedViewModelDelegate: PersonalizedViewModelDelegate {
    // Flags to track which methods were called
    var didUpdateNotificationSettingsCalled = false
    var didUpdateMagnitudeThresholdCalled = false
    var didUpdateMonitoredLocationsCalled = false
    var didUpdateAddingLocationStateCalled = false
    var didUpdateNewLocationCalled = false
    var didUpdateUserLocationCalled = false
    var didUpdateSimulationSettingsCalled = false
    var didUpdateRiskDataCalled = false
    
    // Storage for last received values
    var lastNotificationEnabled = false
    var lastMagnitudeThreshold: Double = 0.0
    var lastMonitoredLocations: [MonitoredLocation] = []
    var lastIsAdding = false
    var lastLocationName = ""
    var lastLocationCoordinate: CLLocationCoordinate2D?
    var lastUserLocation: CLLocationCoordinate2D?
    var lastSimulationMagnitude: Double = 0.0
    var lastSimulationIsActive = false
    var lastSimulationIntensity: Double = 0.0
    var lastSimulationEffect: SimulationEffect = .light
    var lastRiskLevel: RiskLevel = .unknown
    var lastRiskIsLoading = false
    var lastRiskCoordinates: [CLLocationCoordinate2D] = []
    
    // Closures for expectation testing
    var onDidUpdateRiskData: ((RiskLevel, Bool, [CLLocationCoordinate2D]) -> Void)?
    var onDidUpdateSimulationSettings: ((Double, Bool, Double, SimulationEffect) -> Void)?
    
    func reset() {
        didUpdateNotificationSettingsCalled = false
        didUpdateMagnitudeThresholdCalled = false
        didUpdateMonitoredLocationsCalled = false
        didUpdateAddingLocationStateCalled = false
        didUpdateNewLocationCalled = false
        didUpdateUserLocationCalled = false
        didUpdateSimulationSettingsCalled = false
        didUpdateRiskDataCalled = false
        
        lastNotificationEnabled = false
        lastMagnitudeThreshold = 0.0
        lastMonitoredLocations = []
        lastIsAdding = false
        lastLocationName = ""
        lastLocationCoordinate = nil
        lastUserLocation = nil
        lastSimulationMagnitude = 0.0
        lastSimulationIsActive = false
        lastSimulationIntensity = 0.0
        lastSimulationEffect = .light
        lastRiskLevel = .unknown
        lastRiskIsLoading = false
        lastRiskCoordinates = []
        
        onDidUpdateRiskData = nil
        onDidUpdateSimulationSettings = nil
    }
    
    func didUpdateNotificationSettings(enabled: Bool) {
        didUpdateNotificationSettingsCalled = true
        lastNotificationEnabled = enabled
    }
    
    func didUpdateMagnitudeThreshold(threshold: Double) {
        didUpdateMagnitudeThresholdCalled = true
        lastMagnitudeThreshold = threshold
    }
    
    func didUpdateMonitoredLocations(locations: [MonitoredLocation]) {
        didUpdateMonitoredLocationsCalled = true
        lastMonitoredLocations = locations
    }
    
    func didUpdateAddingLocationState(isAdding: Bool) {
        didUpdateAddingLocationStateCalled = true
        lastIsAdding = isAdding
    }
    
    func didUpdateNewLocation(name: String, coordinate: CLLocationCoordinate2D?) {
        didUpdateNewLocationCalled = true
        lastLocationName = name
        lastLocationCoordinate = coordinate
    }
    
    func didUpdateUserLocation(location: CLLocationCoordinate2D?) {
        didUpdateUserLocationCalled = true
        lastUserLocation = location
    }
    
    func didUpdateSimulationSettings(magnitude: Double, isActive: Bool, intensity: Double, effect: SimulationEffect) {
        didUpdateSimulationSettingsCalled = true
        lastSimulationMagnitude = magnitude
        lastSimulationIsActive = isActive
        lastSimulationIntensity = intensity
        lastSimulationEffect = effect
        onDidUpdateSimulationSettings?(magnitude, isActive, intensity, effect)
    }
    
    func didUpdateRiskData(level: RiskLevel, isLoading: Bool, coordinates: [CLLocationCoordinate2D]) {
        didUpdateRiskDataCalled = true
        lastRiskLevel = level
        lastRiskIsLoading = isLoading
        lastRiskCoordinates = coordinates
        onDidUpdateRiskData?(level, isLoading, coordinates)
    }
}
