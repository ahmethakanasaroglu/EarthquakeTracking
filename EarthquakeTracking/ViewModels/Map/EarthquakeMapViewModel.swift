import Foundation
import MapKit
import Combine

class EarthquakeMapViewModel: ObservableObject {
    @Published var earthquakes: [Earthquake] = []
    @Published var selectedEarthquake: Earthquake?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    
    private var cancellables = Set<AnyCancellable>()
    private let networkManager = NetworkManager()
    
    init() {
        setupBindings()
    }
    
    private func setupBindings() {
        networkManager.$earthquakes
            .receive(on: DispatchQueue.main)
            .sink { [weak self] earthquakes in
                self?.earthquakes = earthquakes
                self?.isLoading = false
            }
            .store(in: &cancellables)
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
        
        if magnitude >= 5.0 {
            return .systemRed
        } else if magnitude >= 4.0 {
            return .systemOrange
        } else if magnitude >= 3.0 {
            return .systemYellow
        } else {
            return .systemGreen
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
