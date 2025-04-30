import Foundation

class NetworkManager: ObservableObject {
    @Published var earthquakes: [Earthquake] = []

    func loadData() {
        EarthquakeService.shared.fetchEarthquakes { [weak self] data in
            DispatchQueue.main.async {
                self?.earthquakes = data ?? []
            }
        }
    }
}
