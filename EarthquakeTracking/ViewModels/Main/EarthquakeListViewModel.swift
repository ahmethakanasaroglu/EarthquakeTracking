import Foundation
import Combine

class EarthquakeListViewModel: ObservableObject {
    @Published var earthquakes: [Earthquake] = []
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
    
    func sortByDate() {

        earthquakes.sort {
            guard let date1 = dateFormatter.date(from: $0.date),
                  let date2 = dateFormatter.date(from: $1.date) else {
                return false
            }
            
            if Calendar.current.isDate(date1, inSameDayAs: date2) {
                return $0.time > $1.time
            }
            
            return date1 > date2
        }
    }
    
    func sortByMagnitude() {
        earthquakes.sort {
            guard let mag1 = Double($0.ml),
                  let mag2 = Double($1.ml) else {
                return false
            }
            return mag1 > mag2
        }
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }
    
    func applySortOnLoad() {
        sortByDate()
    }

}
