import Foundation
import Combine

class EarthquakeListViewModel: ObservableObject {
    @Published var earthquakes: [Earthquake] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    
    private var cancellables = Set<AnyCancellable>()
    private let networkManager = NetworkManager()
    private var allEarthquakes: [Earthquake] = []
    private var currentMinMagnitude: Double = 0.0
    private var currentSortOrder: SortOrder = .date
    
    enum SortOrder {
        case date
        case magnitude
    }
    
    init() {
        setupBindings()
    }
    
    private func setupBindings() {
        networkManager.$earthquakes
            .receive(on: DispatchQueue.main)
            .sink { [weak self] earthquakes in
                self?.allEarthquakes = earthquakes
                self?.applyFiltersAndSort()
                self?.isLoading = false
            }
            .store(in: &cancellables)
    }
    
    func fetchEarthquakes() {
        isLoading = true
        errorMessage = nil
        networkManager.loadData()
    }
    
    // Varsayılan olarak tarihe göre sırala
    func applySortOnLoad() {
        sortByDate()
    }
    
    // Tarihe göre sırala (en yeni en üstte)
    func sortByDate() {
        currentSortOrder = .date
        applyFiltersAndSort()
    }
    
    // Büyüklüğe göre sırala (büyükten küçüğe)
    func sortByMagnitude() {
        currentSortOrder = .magnitude
        applyFiltersAndSort()
    }
    
    // Belirli bir büyüklüğün üzerindeki depremleri filtrele
    func filterByMagnitude(minMagnitude: Double) {
        currentMinMagnitude = minMagnitude
        applyFiltersAndSort()
    }
    
    // Filtre ve sıralama işlemlerini uygula
    private func applyFiltersAndSort() {
        // Önce filtreleme işlemi
        var filteredEarthquakes = allEarthquakes.filter { earthquake in
            let magnitude = getMagnitudeValue(for: earthquake)
            return magnitude >= currentMinMagnitude
        }
        
        // Sonra sıralama işlemi
        switch currentSortOrder {
        case .date:
            // Tarihe göre sırala (en yeni en üstte)
            filteredEarthquakes.sort { lhs, rhs in
                let lhsDate = createDateFromStrings(date: lhs.date, time: lhs.time)
                let rhsDate = createDateFromStrings(date: rhs.date, time: rhs.time)
                return lhsDate > rhsDate
            }
        case .magnitude:
            // Büyüklüğe göre sırala (en büyük en üstte)
            filteredEarthquakes.sort { lhs, rhs in
                let lhsMagnitude = getMagnitudeValue(for: lhs)
                let rhsMagnitude = getMagnitudeValue(for: rhs)
                return lhsMagnitude > rhsMagnitude
            }
        }
        
        // Sonuçları yayınla
        self.earthquakes = filteredEarthquakes
    }
    
    // Deprem büyüklüğünü hesapla (ML, MW veya MD)
    private func getMagnitudeValue(for earthquake: Earthquake) -> Double {
        if let ml = Double(earthquake.ml), ml > 0 {
            return ml
        } else if let mw = Double(earthquake.mw), mw > 0 {
            return mw
        } else if let md = Double(earthquake.md), md > 0 {
            return md
        }
        return 0.0
    }
    
    // Tarih ve zaman stringlerinden Date objesi oluştur
    private func createDateFromStrings(date: String, time: String) -> Date {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy.MM.dd HH:mm:ss"
        
        if let date = dateFormatter.date(from: "\(date) \(time)") {
            return date
        }
        return Date.distantPast
    }
}
