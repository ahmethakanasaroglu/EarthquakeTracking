import Foundation

protocol EarthquakeListViewModelDelegate: AnyObject {
    func didUpdateEarthquakes()
    func didChangeLoadingState(isLoading: Bool)
    func didReceiveError(message: String?)
}

class EarthquakeListViewModel {

    static let earthquakesUpdatedNotification = Notification.Name("viewModelEarthquakesUpdatedNotification")
    static let loadingStateChangedNotification = Notification.Name("loadingStateChangedNotification")
    static let errorReceivedNotification = Notification.Name("errorReceivedNotification")
    
    private(set) var earthquakes: [Earthquake] = []
    private(set) var isLoading: Bool = false {
        didSet {
            delegate?.didChangeLoadingState(isLoading: isLoading)
            NotificationCenter.default.post(
                name: EarthquakeListViewModel.loadingStateChangedNotification,
                object: self,
                userInfo: ["isLoading": isLoading]
            )
        }
    }
    private(set) var errorMessage: String? = nil {
        didSet {
            delegate?.didReceiveError(message: errorMessage)
            NotificationCenter.default.post(
                name: EarthquakeListViewModel.errorReceivedNotification,
                object: self,
                userInfo: ["errorMessage": errorMessage as Any]
            )
        }
    }
    
    weak var delegate: EarthquakeListViewModelDelegate?
    
    private let networkManager = NetworkManager()
    var allEarthquakes: [Earthquake] = []
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
            applyFiltersAndSort()
            isLoading = false
        }
    }
    
    func fetchEarthquakes() {
        isLoading = true
        errorMessage = nil
        networkManager.loadData()
    }
    
    func applySortOnLoad() {
        sortByDate()
    }
    
    func sortByDate() {
        currentSortOrder = .date
        applyFiltersAndSort()
    }
    
    func sortByMagnitude() {
        currentSortOrder = .magnitude
        applyFiltersAndSort()
    }
    
    func filterByMagnitude(minMagnitude: Double) {
        currentMinMagnitude = minMagnitude
        applyFiltersAndSort()
    }
    
    private func applyFiltersAndSort() {

        var filteredEarthquakes = allEarthquakes.filter { earthquake in
            let magnitude = getMagnitudeValue(for: earthquake)
            return magnitude >= currentMinMagnitude
        }
        
        switch currentSortOrder {
        case .date:

            filteredEarthquakes.sort { lhs, rhs in
                let lhsDate = createDateFromStrings(date: lhs.date, time: lhs.time)
                let rhsDate = createDateFromStrings(date: rhs.date, time: rhs.time)
                return lhsDate > rhsDate
            }
        case .magnitude:

            filteredEarthquakes.sort { lhs, rhs in
                let lhsMagnitude = getMagnitudeValue(for: lhs)
                let rhsMagnitude = getMagnitudeValue(for: rhs)
                return lhsMagnitude > rhsMagnitude
            }
        }
        
        self.earthquakes = filteredEarthquakes
        
        delegate?.didUpdateEarthquakes()
        NotificationCenter.default.post(
            name: EarthquakeListViewModel.earthquakesUpdatedNotification,
            object: self
        )
    }
    
    func getMagnitudeValue(for earthquake: Earthquake) -> Double {
        if let ml = Double(earthquake.ml), ml > 0 {
            return ml
        } else if let mw = Double(earthquake.mw), mw > 0 {
            return mw
        } else if let md = Double(earthquake.md), md > 0 {
            return md
        }
        return 0.0
    }
    
    func createDateFromStrings(date: String, time: String) -> Date {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy.MM.dd HH:mm:ss"
        
        if let date = dateFormatter.date(from: "\(date) \(time)") {
            return date
        }
        return Date.distantPast
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - NetworkManagerDelegate
extension EarthquakeListViewModel: NetworkManagerDelegate {
    func didUpdateEarthquakes(_ earthquakes: [Earthquake]) {
        allEarthquakes = earthquakes
        applyFiltersAndSort()
        isLoading = false
    }
}
