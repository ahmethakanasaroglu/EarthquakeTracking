import Foundation
import MapKit

protocol EarthquakeMapViewModelDelegate: AnyObject {
    func didUpdateEarthquakes()
    func didSelectEarthquake(_ earthquake: Earthquake?)
    func didChangeLoadingState(isLoading: Bool)
    func didReceiveError(message: String?)
}

class EarthquakeMapViewModel {

    static let earthquakesUpdatedNotification = Notification.Name("mapViewModelEarthquakesUpdatedNotification")
    static let earthquakeSelectedNotification = Notification.Name("earthquakeSelectedNotification")
    static let loadingStateChangedNotification = Notification.Name("mapLoadingStateChangedNotification")
    static let errorReceivedNotification = Notification.Name("mapErrorReceivedNotification")
    
    private(set) var earthquakes: [Earthquake] = []
    private(set) var selectedEarthquake: Earthquake? {
        didSet {
            delegate?.didSelectEarthquake(selectedEarthquake)
            NotificationCenter.default.post(
                name: EarthquakeMapViewModel.earthquakeSelectedNotification,
                object: self,
                userInfo: ["selectedEarthquake": selectedEarthquake as Any]
            )
        }
    }
    private(set) var isLoading: Bool = false {
        didSet {
            delegate?.didChangeLoadingState(isLoading: isLoading)
            NotificationCenter.default.post(
                name: EarthquakeMapViewModel.loadingStateChangedNotification,
                object: self,
                userInfo: ["isLoading": isLoading]
            )
        }
    }
    private(set) var errorMessage: String? = nil {
        didSet {
            delegate?.didReceiveError(message: errorMessage)
            NotificationCenter.default.post(
                name: EarthquakeMapViewModel.errorReceivedNotification,
                object: self,
                userInfo: ["errorMessage": errorMessage as Any]
            )
        }
    }
    private(set) var minMagnitudeFilter: Double = 0.0
    
    weak var delegate: EarthquakeMapViewModelDelegate?
    
    private let networkManager = NetworkManager()
    private var allEarthquakes: [Earthquake] = []
    
    init() {
        setupBindings()
    }
    
    private func setupBindings() {

        networkManager.delegate = self
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleEarthquakesUpdated(_:)),
            name: NetworkManager.earthquakesUpdatedNotification,
            object: nil
        )
    }
    
    @objc private func handleEarthquakesUpdated(_ notification: Notification) {
        if let earthquakes = notification.userInfo?["earthquakes"] as? [Earthquake] {
            allEarthquakes = earthquakes
            applyFilters()
            isLoading = false
        }
    }
    
    func fetchEarthquakes() {
        isLoading = true
        errorMessage = nil
        networkManager.loadData()
    }
    
    func getAnnotations() -> [EarthquakeAnnotation] {
        var annotations: [EarthquakeAnnotation] = []
        
        for earthquake in earthquakes {
            if let latitude = Double(earthquake.latitude),
               let longitude = Double(earthquake.longitude) {
                
                let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
                let annotation = EarthquakeAnnotation(coordinate: coordinate, earthquake: earthquake)
                
                if let selectedEarthquake = selectedEarthquake {
                    if annotation.matchesEarthquake(selectedEarthquake) {
                        annotation.isSelected = true
                    }
                }
                
                annotations.append(annotation)
            }
        }
        
        return annotations
    }
    
    func selectEarthquake(_ annotation: EarthquakeAnnotation) {
        selectedEarthquake = annotation.earthquake
    }
    
    func getMagnitude(for earthquake: Earthquake) -> Double {
        if let ml = Double(earthquake.ml), ml > 0 {
            return ml
        } else if let mw = Double(earthquake.mw), mw > 0 {
            return mw
        } else if let md = Double(earthquake.md), md > 0 {
            return md
        }
        return 0
    }
    
    func getColor(for earthquake: Earthquake) -> UIColor {
        let magnitude = getMagnitude(for: earthquake)
        
        if magnitude >= 6.0 {
            return UIColor(red: 1.0, green: 0.0, blue: 0.0, alpha: 1.0) // Kırmızı
        } else if magnitude >= 5.0 {
            return UIColor(red: 1.0, green: 0.4, blue: 0.0, alpha: 1.0) // Koyu turuncu
        } else if magnitude >= 4.0 {
            return UIColor(red: 0.9, green: 0.6, blue: 0.0, alpha: 1.0) // Turuncu
        } else if magnitude >= 3.0 {
            return UIColor(red: 0.8, green: 0.8, blue: 0.0, alpha: 1.0) // Sarı
        } else if magnitude >= 2.0 {
            return UIColor(red: 0.6, green: 0.8, blue: 0.0, alpha: 1.0) // Lime yeşil
        } else {
            return UIColor(red: 0.0, green: 0.7, blue: 0.0, alpha: 1.0) // Yeşil
        }
    }
    
    func getMarkerScale(for earthquake: Earthquake) -> CGFloat {
        let magnitude = getMagnitude(for: earthquake)
        
        if magnitude >= 6.0 {
            return 1.4
        } else if magnitude >= 5.0 {
            return 1.2
        } else if magnitude >= 4.0 {
            return 1.1
        } else if magnitude >= 3.0 {
            return 1.0
        } else if magnitude >= 2.0 {
            return 0.9
        } else {
            return 0.8
        }
    }
    
    func getMarkerIcon(for earthquake: Earthquake) -> UIImage? {
        let magnitude = getMagnitude(for: earthquake)
        
        if magnitude >= 5.0 {
            return UIImage(systemName: "exclamationmark.triangle.fill")
        } else if magnitude >= 4.0 {
            return UIImage(systemName: "exclamationmark")
        } else {
            return UIImage(systemName: "waveform.path.ecg")
        }
    }
    
    func getCenterCoordinate() -> CLLocationCoordinate2D? {
        if let firstEarthquake = earthquakes.first,
           let latitude = Double(firstEarthquake.latitude),
           let longitude = Double(firstEarthquake.longitude) {
            return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        }
        
        return CLLocationCoordinate2D(latitude: 39.0, longitude: 35.0)
    }
    
    func getInitialSpan() -> MKCoordinateSpan {
        if earthquakes.count <= 1 {
            return MKCoordinateSpan(latitudeDelta: 10, longitudeDelta: 10)
        }
        
        var minLat = 90.0
        var maxLat = -90.0
        var minLong = 180.0
        var maxLong = -180.0
        
        for earthquake in earthquakes {
            if let latitude = Double(earthquake.latitude),
               let longitude = Double(earthquake.longitude) {
                minLat = min(minLat, latitude)
                maxLat = max(maxLat, latitude)
                minLong = min(minLong, longitude)
                maxLong = max(maxLong, longitude)
            }
        }
        
        let latDelta = (maxLat - minLat) * 1.5
        let longDelta = (maxLong - minLong) * 1.5
        
        return MKCoordinateSpan(latitudeDelta: max(5, latDelta), longitudeDelta: max(5, longDelta))
    }
    
    func filterByMagnitude(minMagnitude: Double) {
        minMagnitudeFilter = minMagnitude
        applyFilters()
    }
    
    func clearSelectedEarthquake() {
        selectedEarthquake = nil
    }
    
    private func applyFilters() {
        earthquakes = allEarthquakes.filter { earthquake in
            let magnitude = getMagnitude(for: earthquake)
            return magnitude >= minMagnitudeFilter
        }
        
        delegate?.didUpdateEarthquakes()
        NotificationCenter.default.post(
            name: EarthquakeMapViewModel.earthquakesUpdatedNotification,
            object: self
        )
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - NetworkManagerDelegate
extension EarthquakeMapViewModel: NetworkManagerDelegate {
    func didUpdateEarthquakes(_ earthquakes: [Earthquake]) {
        allEarthquakes = earthquakes
        applyFilters()
        isLoading = false
    }
}

class EarthquakeAnnotation: NSObject, MKAnnotation {
    let coordinate: CLLocationCoordinate2D
    let earthquake: Earthquake
    var isSelected: Bool = false
    
    var title: String? {
        return earthquake.location
    }
    
    var subtitle: String? {
        let magnitude: String
        if let ml = Double(earthquake.ml), ml > 0 {
            magnitude = String(format: "%.1f", ml)
        } else if let mw = Double(earthquake.mw), mw > 0 {
            magnitude = String(format: "%.1f", mw)
        } else if let md = Double(earthquake.md), md > 0 {
            magnitude = String(format: "%.1f", md)
        } else {
            magnitude = "N/A"
        }
        
        return "Büyüklük: \(magnitude) - Derinlik: \(earthquake.depth_km) km"
    }
    
    init(coordinate: CLLocationCoordinate2D, earthquake: Earthquake) {
        self.coordinate = coordinate
        self.earthquake = earthquake
        super.init()
    }
    
    func matchesEarthquake(_ earthquake: Earthquake) -> Bool {
        if let lat1 = Double(self.earthquake.latitude),
           let lon1 = Double(self.earthquake.longitude),
           let lat2 = Double(earthquake.latitude),
           let lon2 = Double(earthquake.longitude) {
            
            let latMatches = abs(lat1 - lat2) < 0.0001
            let lonMatches = abs(lon1 - lon2) < 0.0001
            
            return latMatches && lonMatches
        }
        
        return self.earthquake.date == earthquake.date &&
               self.earthquake.time == earthquake.time &&
               self.earthquake.location == earthquake.location
    }
}
