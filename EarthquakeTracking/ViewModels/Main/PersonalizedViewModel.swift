import Foundation
import Combine
import CoreLocation
import UserNotifications
import UIKit

class PersonalizedViewModel: ObservableObject {
    @Published var enableNotifications = false
    @Published var selectedMagnitudeThreshold: Double = 4.0
    @Published var monitoredLocations: [MonitoredLocation] = []
    @Published var isAddingMonitoredLocation = false
    @Published var newLocationName = ""
    @Published var newLocationCoordinate: CLLocationCoordinate2D?
    @Published var userLocation: CLLocationCoordinate2D?
    
    @Published var selectedSimulationMagnitude: Double = 5.0
    @Published var isSimulationActive = false
    @Published var simulationIntensity: Double = 0.0
    @Published var simulationEffect: SimulationEffect = .light
    
    @Published var isARScanActive = false
    @Published var currentScanStep = 0
    @Published var scanResults: [ScanResult] = []
    @Published var scanProgress: Float = 0.0
    
    @Published var riskLevelForCurrentLocation: RiskLevel = .unknown
    @Published var isLoadingRiskData = false
    @Published var riskAreaCoordinates: [CLLocationCoordinate2D] = []
    
    // Önbellek için yeni özellikler
    private var cachedRiskLevels: [String: RiskLevel] = [:]
    private var hasLoadedRiskData = false
    
    private var locationManager = CLLocationManager()
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        setupLocationManager()
        loadUserPreferences()
        requestNotificationAuthorization()
        
        // Uygulama ilk açıldığında önbelleği temizle
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(clearCachedData),
            name: UIApplication.didFinishLaunchingNotification,
            object: nil
        )
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc private func clearCachedData() {
        // Uygulama her başlatıldığında önbelleği temizle
        cachedRiskLevels.removeAll()
        hasLoadedRiskData = false
    }
    
    // MARK: - Ortak İşlemler
    
    private func setupLocationManager() {
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 100 // 100 metrede bir konum güncellemesi al
        locationManager.delegate = nil // Delegate ViewModel içinde değil UIKit tarafında ayarlanacak
        
        userLocation = CLLocationCoordinate2D(latitude: 39.9334, longitude: 32.8597)
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
    
    func startSimulation() {
        isSimulationActive = true
        simulateEarthquake()
    }
    
    func stopSimulation() {
        isSimulationActive = false
        simulationIntensity = 0.0
    }
    
    private func simulateEarthquake() {
        
        let simulationDuration = 15.0 // 15 saniye süren bir simülasyon
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
        
        Timer.publish(every: 0.1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self, self.isSimulationActive else { return }
                
                let elapsedTime = Date().timeIntervalSince(startTime)
                if elapsedTime > simulationDuration {
                    self.stopSimulation()
                    return
                }
                
                let baseFrequency = 0.5 + (self.selectedSimulationMagnitude - 3.0) * 0.3 // Büyüklük arttıkça frekans artar
                let progress = elapsedTime / simulationDuration
                
                let sinValue = sin(elapsedTime * baseFrequency * 2 * .pi)
                
                let randomNoise = Double.random(in: -0.3...0.3)
                
                let timeDecay = 1.0 - pow(progress, 2)
                
                self.simulationIntensity = (sinValue + randomNoise) * maxIntensity * timeDecay
            }
            .store(in: &cancellables)
    }
    
    // MARK: - AR Ev Güvenliği Taraması
    
    func startARScan() {
        isARScanActive = true
        currentScanStep = 0
        scanResults = []
        scanProgress = 0.0
        
        advanceToNextScanStep()
    }
    
    func stopARScan() {
        isARScanActive = false
    }
    
    func advanceToNextScanStep() {
        currentScanStep += 1
        
        if currentScanStep > scanSteps.count {
            completeScan()
            return
        }
        
        scanProgress = Float(currentScanStep) / Float(scanSteps.count)
    }
    
    private func completeScan() {
        scanResults = [
            ScanResult(id: UUID(), title: "Kitaplık", riskLevel: .high, recommendation: "Kitaplığı duvara sabitleyin."),
            ScanResult(id: UUID(), title: "Cam Eşyalar", riskLevel: .medium, recommendation: "Camları alçak raflara taşıyın veya sabitleyin."),
            ScanResult(id: UUID(), title: "Elektrik Kabloları", riskLevel: .low, recommendation: "Uzatma kablolarını toplayarak düzenleyin.")
        ]
        
        stopARScan()
    }
    
    // MARK: - Risk Tahmin Modeli
    
    func loadRiskDataForCurrentLocation() {
        guard let location = userLocation else { return }
        
        // Eğer veri zaten yüklendiyse, tekrar yükleme
        if hasLoadedRiskData {
            return
        }
        
        // Konum için önbellekte veri var mı kontrol et
        let locationKey = "\(location.latitude),\(location.longitude)"
        if let cachedRisk = cachedRiskLevels[locationKey] {
            self.riskLevelForCurrentLocation = cachedRisk
            self.generateRiskAreaCoordinates(aroundLocation: location)
            return
        }
        
        // Yoksa yeni veri yükle
        isLoadingRiskData = true
        
        // Simüle edilmiş veri yükleme gecikmesi (gerçek bir API çağrısını simüle etmek için)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            guard let self = self else { return }
            
            // Tutarlı bir risk seviyesi için konumun enlem değerini kullan
            // Bu, aynı konum için her zaman aynı risk değerini üretecektir
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
            
            // Önbelleğe ekle
            self.cachedRiskLevels[locationKey] = riskLevel
            self.hasLoadedRiskData = true
            
            // Risk bölgesi koordinatlarını oluştur
            self.generateRiskAreaCoordinates(aroundLocation: location)
            
            self.isLoadingRiskData = false
        }
    }
    
    private func generateRiskAreaCoordinates(aroundLocation location: CLLocationCoordinate2D) {
        riskAreaCoordinates = []
        
        // Rastgele noktalar için kullanılacak yarıçap (derece olarak)
        let radiusInDegrees = 0.05 // Yaklaşık 5 km
        
        // Risk seviyesine bağlı olarak nokta yoğunluğunu ayarla
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
        
        // Risk seviyesine göre rastgele noktalar oluştur
        let seed = Int(location.latitude * 1000) + Int(location.longitude * 1000)
        var randomGenerator = SeededRandomGenerator(seed: seed)
        
        for _ in 0..<pointCount {
            // -1 ile 1 arasında rastgele değerler
            let randomLat = randomGenerator.nextDouble() * radiusInDegrees * 2 - radiusInDegrees
            let randomLon = randomGenerator.nextDouble() * radiusInDegrees * 2 - radiusInDegrees
            
            let newLat = location.latitude + randomLat
            let newLon = location.longitude + randomLon
            
            riskAreaCoordinates.append(CLLocationCoordinate2D(latitude: newLat, longitude: newLon))
        }
    }
    
    // MARK: - Yardımcı Veri Modelleri ve Sabitler
    
    var scanSteps: [ScanStep] {
        return [
            ScanStep(id: 1, title: "Kitaplık ve Raflar", description: "Kamerayı kitaplık ve yüksek raflara doğrultun."),
            ScanStep(id: 2, title: "Cam Eşyalar", description: "Kamerayı cam eşyaların bulunduğu alanlara doğrultun."),
            ScanStep(id: 3, title: "Ağır Mobilyalar", description: "Kamerayı ağır mobilyalara doğrultun."),
            ScanStep(id: 4, title: "Elektrik Kabloları", description: "Kamerayı elektrik kablolarının olduğu alanlara doğrultun.")
        ]
    }
    
    var currentScanStepInfo: ScanStep? {
        guard currentScanStep > 0 && currentScanStep <= scanSteps.count else { return nil }
        return scanSteps[currentScanStep - 1]
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

struct ScanStep: Identifiable {
    let id: Int
    let title: String
    let description: String
}

struct ScanResult: Identifiable {
    let id: UUID
    let title: String
    let riskLevel: RiskLevel
    let recommendation: String
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
        // Basit bir linear congruential üreteci
        seed = (seed * 1103515245 + 12345) & 0x7FFFFFFF
        return Double(seed) / Double(0x7FFFFFFF)
    }
}
