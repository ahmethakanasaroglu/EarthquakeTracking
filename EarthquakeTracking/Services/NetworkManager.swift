import Foundation

// NetworkManager için delegate protokolü
protocol NetworkManagerDelegate: AnyObject {
    func didUpdateEarthquakes(_ earthquakes: [Earthquake])
}

class NetworkManager {
    // Bildirim ismi
    static let earthquakesUpdatedNotification = Notification.Name("earthquakesUpdatedNotification")
    
    // Deprem verileri
    private(set) var earthquakes: [Earthquake] = []
    
    // Delegate referansı
    weak var delegate: NetworkManagerDelegate?
    
    func loadData() {
        EarthquakeService.shared.fetchEarthquakes { [weak self] data in
            DispatchQueue.main.async {
                let fetchedEarthquakes = data ?? []
                self?.earthquakes = fetchedEarthquakes
                
                // Delegate ile bildir
                self?.delegate?.didUpdateEarthquakes(fetchedEarthquakes)
                
                // Notification ile bildir
                NotificationCenter.default.post(
                    name: NetworkManager.earthquakesUpdatedNotification,
                    object: self,
                    userInfo: ["earthquakes": fetchedEarthquakes]
                )
            }
        }
    }
}
