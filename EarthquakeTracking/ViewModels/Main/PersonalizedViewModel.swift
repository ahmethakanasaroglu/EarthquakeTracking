import Foundation
import CoreLocation
import UserNotifications
import UIKit

protocol PersonalizedViewModelDelegate: AnyObject {
    func didUpdateNotificationSettings(enabled: Bool)
    func didUpdateMagnitudeThreshold(threshold: Double)
    func didUpdateMonitoredLocations(locations: [MonitoredLocation])
    func didUpdateAddingLocationState(isAdding: Bool)
    func didUpdateNewLocation(name: String, coordinate: CLLocationCoordinate2D?)
    func didUpdateUserLocation(location: CLLocationCoordinate2D?)
    func didUpdateSimulationSettings(magnitude: Double, isActive: Bool, intensity: Double, effect: SimulationEffect)
    func didUpdateRiskData(level: RiskLevel, isLoading: Bool, coordinates: [CLLocationCoordinate2D])
}

class PersonalizedViewModel: NSObject, CLLocationManagerDelegate {
    
    static let notificationSettingsChangedNotification = Notification.Name("notificationSettingsChangedNotification")
    static let magnitudeThresholdChangedNotification = Notification.Name("magnitudeThresholdChangedNotification")
    static let monitoredLocationsChangedNotification = Notification.Name("monitoredLocationsChangedNotification")
    static let addingLocationStateChangedNotification = Notification.Name("addingLocationStateChangedNotification")
    static let newLocationChangedNotification = Notification.Name("newLocationChangedNotification")
    static let userLocationChangedNotification = Notification.Name("userLocationChangedNotification")
    static let simulationSettingsChangedNotification = Notification.Name("simulationSettingsChangedNotification")
    static let riskDataChangedNotification = Notification.Name("riskDataChangedNotification")
    
    private(set) var enableNotifications = false {
        didSet {
            delegate?.didUpdateNotificationSettings(enabled: enableNotifications)
            NotificationCenter.default.post(
                name: PersonalizedViewModel.notificationSettingsChangedNotification,
                object: self,
                userInfo: ["enabled": enableNotifications]
            )
        }
    }
    
    private(set) var selectedMagnitudeThreshold: Double = 4.0 {
        didSet {
            delegate?.didUpdateMagnitudeThreshold(threshold: selectedMagnitudeThreshold)
            NotificationCenter.default.post(
                name: PersonalizedViewModel.magnitudeThresholdChangedNotification,
                object: self,
                userInfo: ["threshold": selectedMagnitudeThreshold]
            )
        }
    }
    
    private(set) var monitoredLocations: [MonitoredLocation] = [] {
        didSet {
            delegate?.didUpdateMonitoredLocations(locations: monitoredLocations)
            NotificationCenter.default.post(
                name: PersonalizedViewModel.monitoredLocationsChangedNotification,
                object: self,
                userInfo: ["locations": monitoredLocations]
            )
        }
    }
    
    private(set) var isAddingMonitoredLocation = false {
        didSet {
            delegate?.didUpdateAddingLocationState(isAdding: isAddingMonitoredLocation)
            NotificationCenter.default.post(
                name: PersonalizedViewModel.addingLocationStateChangedNotification,
                object: self,
                userInfo: ["isAdding": isAddingMonitoredLocation]
            )
        }
    }
    
    private(set) var newLocationName = "" {
        didSet {
            updateNewLocation()
        }
    }
    
    private(set) var newLocationCoordinate: CLLocationCoordinate2D? {
        didSet {
            updateNewLocation()
        }
    }
    
    private(set) var userLocation: CLLocationCoordinate2D? {
        didSet {
            delegate?.didUpdateUserLocation(location: userLocation)
            NotificationCenter.default.post(
                name: PersonalizedViewModel.userLocationChangedNotification,
                object: self,
                userInfo: ["location": userLocation as Any]
            )
        }
    }
    
    private(set) var selectedSimulationMagnitude: Double = 5.0 {
        didSet {
            updateSimulationSettings()
        }
    }
    
    private(set) var isSimulationActive = false {
        didSet {
            updateSimulationSettings()
        }
    }
    
    private(set) var simulationIntensity: Double = 0.0 {
        didSet {
            updateSimulationSettings()
        }
    }
    
    private(set) var simulationEffect: SimulationEffect = .light {
        didSet {
            updateSimulationSettings()
        }
    }
    
    private(set) var riskLevelForCurrentLocation: RiskLevel = .unknown {
        didSet {
            updateRiskData()
        }
    }
    
    private(set) var isLoadingRiskData = false {
        didSet {
            updateRiskData()
        }
    }
    
    private(set) var riskAreaCoordinates: [CLLocationCoordinate2D] = [] {
        didSet {
            updateRiskData()
        }
    }
    
    private var cachedRiskLevels: [String: RiskLevel] = [:]
    private var hasLoadedRiskData = false
    
    private var locationManager = CLLocationManager()
    private var simulationTimer: Timer?
    
    weak var delegate: PersonalizedViewModelDelegate?
    
    override init() {
        super.init()
        setupLocationManager()
        loadUserPreferences()
        requestNotificationAuthorization()
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(clearCachedData),
            name: UIApplication.didFinishLaunchingNotification,
            object: nil
        )
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        simulationTimer?.invalidate()
    }
    
    private func updateNewLocation() {
        delegate?.didUpdateNewLocation(name: newLocationName, coordinate: newLocationCoordinate)
        NotificationCenter.default.post(
            name: PersonalizedViewModel.newLocationChangedNotification,
            object: self,
            userInfo: [
                "name": newLocationName,
                "coordinate": newLocationCoordinate as Any
            ]
        )
    }
    
    private func updateSimulationSettings() {
        delegate?.didUpdateSimulationSettings(
            magnitude: selectedSimulationMagnitude,
            isActive: isSimulationActive,
            intensity: simulationIntensity,
            effect: simulationEffect
        )
        NotificationCenter.default.post(
            name: PersonalizedViewModel.simulationSettingsChangedNotification,
            object: self,
            userInfo: [
                "magnitude": selectedSimulationMagnitude,
                "isActive": isSimulationActive,
                "intensity": simulationIntensity,
                "effect": simulationEffect
            ]
        )
    }
    
    
    private func updateRiskData() {
        delegate?.didUpdateRiskData(
            level: riskLevelForCurrentLocation,
            isLoading: isLoadingRiskData,
            coordinates: riskAreaCoordinates
        )
        NotificationCenter.default.post(
            name: PersonalizedViewModel.riskDataChangedNotification,
            object: self,
            userInfo: [
                "level": riskLevelForCurrentLocation,
                "isLoading": isLoadingRiskData,
                "coordinates": riskAreaCoordinates
            ]
        )
    }
    
    @objc private func clearCachedData() {
        cachedRiskLevels.removeAll()
        hasLoadedRiskData = false
    }
    
    // MARK: - Ortak İşlemler
    
    private func setupLocationManager() {
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 100
        locationManager.delegate = self
        
        userLocation = CLLocationCoordinate2D(latitude: 39.9334, longitude: 32.8597)
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last {
            userLocation = location.coordinate
        }
    }
    
    private func loadUserPreferences() {
        let defaults = UserDefaults.standard
        enableNotifications = defaults.bool(forKey: "enableNotifications")
        selectedMagnitudeThreshold = defaults.double(forKey: "magnitudeThreshold")
        if selectedMagnitudeThreshold == 0 {
            selectedMagnitudeThreshold = 4.0
        }
        
        if let savedLocations = defaults.object(forKey: "monitoredLocations") as? Data {
            let decoder = JSONDecoder()
            if let loadedLocations = try? decoder.decode([MonitoredLocation].self, from: savedLocations) {
                monitoredLocations = loadedLocations
            }
        }
    }
    
    func saveUserPreferences() {
        let defaults = UserDefaults.standard
        defaults.set(enableNotifications, forKey: "enableNotifications")
        defaults.set(selectedMagnitudeThreshold, forKey: "magnitudeThreshold")
        
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(monitoredLocations) {
            defaults.set(encoded, forKey: "monitoredLocations")
        }
    }
    
    // MARK: - Kişiselleştirilmiş Uyarı Sistemi
    
    func setEnableNotifications(_ enable: Bool) {
        enableNotifications = enable
        saveUserPreferences()
    }
    
    func setMagnitudeThreshold(_ threshold: Double) {
        selectedMagnitudeThreshold = threshold
        saveUserPreferences()
    }
    
    func requestNotificationAuthorization() {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            DispatchQueue.main.async {
                if granted {
                    self.enableNotifications = true
                    self.saveUserPreferences()
                } else if let error = error {
                    print("Bildirim izni hatası: \(error.localizedDescription)")
                }
            }
        }
    }
    
    func setIsAddingMonitoredLocation(_ isAdding: Bool) {
        isAddingMonitoredLocation = isAdding
    }
    
    func setNewLocationName(_ name: String) {
        newLocationName = name
    }
    
    func setNewLocationCoordinate(_ coordinate: CLLocationCoordinate2D?) {
        newLocationCoordinate = coordinate
    }
    
    func addMonitoredLocation() {
        guard !newLocationName.isEmpty, let coordinate = newLocationCoordinate else {
            return
        }
        
        let newLocation = MonitoredLocation(
            id: UUID(),
            name: newLocationName,
            latitude: coordinate.latitude,
            longitude: coordinate.longitude,
            notificationThreshold: selectedMagnitudeThreshold
        )
        
        monitoredLocations.append(newLocation)
        saveUserPreferences()
        resetNewLocationForm()
    }
    
    func removeMonitoredLocation(at index: Int) {
        if monitoredLocations.indices.contains(index) {
            monitoredLocations.remove(at: index)
            saveUserPreferences()
        }
    }
    
    func resetNewLocationForm() {
        newLocationName = ""
        newLocationCoordinate = nil
        isAddingMonitoredLocation = false
    }
    
    // MARK: - Deprem Simülasyonu
    
    func setSimulationMagnitude(_ magnitude: Double) {
        selectedSimulationMagnitude = magnitude
    }
    
    func startSimulation() {
        isSimulationActive = true
        simulateEarthquake()
    }
    
    func stopSimulation() {
        isSimulationActive = false
        simulationIntensity = 0.0
        simulationTimer?.invalidate()
        simulationTimer = nil
    }
    
    private func simulateEarthquake() {
        let simulationDuration = 15.0
        let startTime = Date()
        
        let maxIntensity = selectedSimulationMagnitude / 10.0 * 2.0
        
        if selectedSimulationMagnitude >= 7.0 {
            simulationEffect = .severe
        } else if selectedSimulationMagnitude >= 5.0 {
            simulationEffect = .strong
        } else if selectedSimulationMagnitude >= 4.0 {
            simulationEffect = .moderate
        } else {
            simulationEffect = .light
        }
        
        simulationTimer?.invalidate()
        simulationTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] timer in
            guard let self = self, self.isSimulationActive else {
                timer.invalidate()
                return
            }
            
            let elapsedTime = Date().timeIntervalSince(startTime)
            if elapsedTime > simulationDuration {
                self.stopSimulation()
                return
            }
            
            let baseFrequency = 0.5 + (self.selectedSimulationMagnitude - 3.0) * 0.3
            let progress = elapsedTime / simulationDuration
            
            let sinValue = sin(elapsedTime * baseFrequency * 2 * .pi)
            
            let randomNoise = Double.random(in: -0.3...0.3)
            
            let timeDecay = 1.0 - pow(progress, 2)
            
            self.simulationIntensity = (sinValue + randomNoise) * maxIntensity * timeDecay
        }
    }
 
    // MARK: - Risk Tahmin Modeli
    
    func loadRiskDataForCurrentLocation() {
        guard let location = userLocation else { return }
        
        if hasLoadedRiskData {
            return
        }
        
        let locationKey = "\(location.latitude),\(location.longitude)"
        if let cachedRisk = cachedRiskLevels[locationKey] {
            self.riskLevelForCurrentLocation = cachedRisk
            self.generateRiskAreaCoordinates(aroundLocation: location)
            return
        }
        
        isLoadingRiskData = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            guard let self = self else { return }
            
            let locationSeed = abs(location.latitude * 1000).truncatingRemainder(dividingBy: 3)
            let riskLevel: RiskLevel
            
            if locationSeed < 1 {
                riskLevel = .low
            } else if locationSeed < 2 {
                riskLevel = .medium
            } else {
                riskLevel = .high
            }
            
            self.riskLevelForCurrentLocation = riskLevel
            
            self.cachedRiskLevels[locationKey] = riskLevel
            self.hasLoadedRiskData = true
            
            self.generateRiskAreaCoordinates(aroundLocation: location)
            
            self.isLoadingRiskData = false
        }
    }
    
    private func generateRiskAreaCoordinates(aroundLocation location: CLLocationCoordinate2D) {
        riskAreaCoordinates = []
        
        let radiusInDegrees = 0.05
        
        var pointCount: Int
        
        switch riskLevelForCurrentLocation {
        case .high:
            pointCount = 40
        case .medium:
            pointCount = 25
        case .low:
            pointCount = 15
        case .unknown:
            pointCount = 10
        }
        
        let seed = Int(location.latitude * 1000) + Int(location.longitude * 1000)
        var randomGenerator = SeededRandomGenerator(seed: seed)
        
        for _ in 0..<pointCount {
            let randomLat = randomGenerator.nextDouble() * radiusInDegrees * 2 - radiusInDegrees
            let randomLon = randomGenerator.nextDouble() * radiusInDegrees * 2 - radiusInDegrees
            
            let newLat = location.latitude + randomLat
            let newLon = location.longitude + randomLon
            
            riskAreaCoordinates.append(CLLocationCoordinate2D(latitude: newLat, longitude: newLon))
        }
    }
    
}

// MARK: - Veri Modelleri

struct MonitoredLocation: Codable, Identifiable {
    let id: UUID
    var name: String
    var latitude: Double
    var longitude: Double
    var notificationThreshold: Double
}


enum RiskLevel: String, Codable {
    case unknown = "Bilinmiyor"
    case low = "Düşük"
    case medium = "Orta"
    case high = "Yüksek"
    
    var color: UIColor {
        switch self {
        case .unknown: return .systemGray
        case .low: return .systemGreen
        case .medium: return .systemOrange
        case .high: return .systemRed
        }
    }
}

enum SimulationEffect {
    case light
    case moderate
    case strong
    case severe
    
    var description: String {
        switch self {
        case .light: return "Hafif sallanma, asılı eşyalar hareket edebilir."
        case .moderate: return "Orta şiddette sarsıntı, mobilyalar hareket edebilir."
        case .strong: return "Şiddetli sarsıntı, ayakta durmak zorlaşır, eşyalar düşebilir."
        case .severe: return "Çok şiddetli sarsıntı, ayakta durmak imkansızlaşır, yapısal hasarlar oluşabilir."
        }
    }
}

// MARK: - Rasgele sayı üreticisi (her konum için sabit risk değerleri üretmek için)
struct SeededRandomGenerator {
    private var seed: Int
    
    init(seed: Int) {
        self.seed = seed
    }
    
    mutating func nextDouble() -> Double {
        
        seed = (seed * 1103515245 + 12345) & 0x7FFFFFFF
        return Double(seed) / Double(0x7FFFFFFF)
    }
}
