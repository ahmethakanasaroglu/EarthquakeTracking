import Foundation

protocol NetworkManagerDelegate: AnyObject {
    func didUpdateEarthquakes(_ earthquakes: [Earthquake])
}

class NetworkManager {

    static let earthquakesUpdatedNotification = Notification.Name("earthquakesUpdatedNotification")
    
    private(set) var earthquakes: [Earthquake] = []
    
    weak var delegate: NetworkManagerDelegate?
    
    func loadData() {
        EarthquakeService.shared.fetchEarthquakes { [weak self] data in
            DispatchQueue.main.async {
                let fetchedEarthquakes = data ?? []
                self?.earthquakes = fetchedEarthquakes
                
                self?.delegate?.didUpdateEarthquakes(fetchedEarthquakes)
                
                NotificationCenter.default.post(
                    name: NetworkManager.earthquakesUpdatedNotification,
                    object: self,
                    userInfo: ["earthquakes": fetchedEarthquakes]
                )
            }
        }
    }
}
