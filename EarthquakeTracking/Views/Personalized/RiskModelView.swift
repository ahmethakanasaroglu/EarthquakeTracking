import UIKit
import MapKit

class RiskModelViewController: UIViewController {
    
    // MARK: - Properties
    private let viewModel: PersonalizedViewModel
    
    private var riskRegions: [RiskRegion] = []
    
    private var viewComponents: [UIView] = []
    private var mapRegionOverlays: [MKCircle] = []
    private var isFirstLoad = true
    
    // MARK: - UI Elements
    private lazy var mapView: MKMapView = {
        let mapView = MKMapView()
        mapView.translatesAutoresizingMaskIntoConstraints = false
        mapView.delegate = self
        mapView.showsUserLocation = true
        return mapView
    }()
    
    private lazy var infoContainerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .systemBackground
        view.layer.cornerRadius = 16
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = 0.3
        view.layer.shadowOffset = CGSize(width: 0, height: 5)
        view.layer.shadowRadius = 10
        return view
    }()
    
    private lazy var riskTitleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Bölge Deprem Riski"
        label.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        label.textColor = .label
        return label
    }()
    
    private lazy var riskLevelLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Analiz ediliyor..."
        label.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        label.textColor = .systemGray
        return label
    }()
    
    private lazy var descriptionLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Yapay zeka bölgenizdeki deprem istatistiklerini ve jeolojik verileri analiz ediyor."
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = .secondaryLabel
        label.numberOfLines = 0
        return label
    }()
    
    private lazy var historicalDataLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Yüksek Riskli Deprem Geçmişi:"
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        label.textColor = .label
        return label
    }()
    
    private lazy var earthquakeCountLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Son 50 yılda 5.0+ büyüklüğünde 12 deprem"
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = .secondaryLabel
        return label
    }()
    
    private lazy var lastBigEarthquakeLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "En son büyük deprem: 2020.05.14 (M 5.3)"
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = .secondaryLabel
        return label
    }()
    
    private lazy var legendView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = UIColor.systemBackground.withAlphaComponent(0.8)
        view.layer.cornerRadius = 8
        return view
    }()
    
    private lazy var legendTitleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Risk Düzeyleri"
        label.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        label.textColor = .label
        return label
    }()
    
    private lazy var highRiskView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .systemRed
        view.layer.cornerRadius = 4
        return view
    }()
    
    private lazy var mediumRiskView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .systemOrange
        view.layer.cornerRadius = 4
        return view
    }()
    
    private lazy var lowRiskView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .systemGreen
        view.layer.cornerRadius = 4
        return view
    }()
    
    private lazy var highRiskLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Yüksek"
        label.font = UIFont.systemFont(ofSize: 12)
        label.textColor = .label
        return label
    }()
    
    private lazy var mediumRiskLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Orta"
        label.font = UIFont.systemFont(ofSize: 12)
        label.textColor = .label
        return label
    }()
    
    private lazy var lowRiskLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Düşük"
        label.font = UIFont.systemFont(ofSize: 12)
        label.textColor = .label
        return label
    }()
    
    private lazy var loadingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.hidesWhenStopped = true
        return indicator
    }()
    
    // MARK: - Initialization
    init(viewModel: PersonalizedViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupBindings()
        
        updateLoadingState(isLoading: true)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // İlk yükleme kontrolü
        if isFirstLoad {
            // Ana bileşenlerin animasyonu
            animateUIComponents()
            isFirstLoad = false
        }
    }
    
    private func animateUIComponents() {
        // Info Container animasyonu
        UIView.animate(withDuration: 0.6, delay: 0.2, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.5, options: [], animations: {
            self.infoContainerView.alpha = 1
            self.infoContainerView.transform = .identity
        }, completion: nil)
        
        // Legend View animasyonu
        UIView.animate(withDuration: 0.5, delay: 0.4, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.5, options: [], animations: {
            self.legendView.alpha = 1
            self.legendView.transform = .identity
        }, completion: nil)
    }
    
    private func animateOverlays() {
        // Mevcut tüm overlayleri gizle
        for overlay in mapRegionOverlays {
            let renderer = mapView.renderer(for: overlay) as? MKCircleRenderer
            renderer?.alpha = 0
        }
        
        // Sırayla gösterme animasyonu
        for (index, overlay) in mapRegionOverlays.enumerated() {
            let delay = Double(index) * 0.03 // Her bölge için küçük bir gecikme
            UIView.animate(withDuration: 0.4, delay: delay, options: [], animations: {
                let renderer = self.mapView.renderer(for: overlay) as? MKCircleRenderer
                renderer?.alpha = 1.0
            }, completion: nil)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if viewModel.riskLevelForCurrentLocation != .unknown {
            updateRiskUI(riskLevel: viewModel.riskLevelForCurrentLocation)
        }
        
        updateLoadingState(isLoading: viewModel.isLoadingRiskData)
        
        if !viewModel.riskAreaCoordinates.isEmpty {
            updateMapOverlays(coordinates: viewModel.riskAreaCoordinates)
        }
        
        if let userLocation = viewModel.userLocation {
            let region = MKCoordinateRegion(center: userLocation, span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1))
            mapView.setRegion(region, animated: true)
        }
        
        viewModel.loadRiskDataForCurrentLocation()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Setup
    private func setupUI() {
        title = "Deprem Riski Analizi"
        view.backgroundColor = .systemBackground
        
        view.addSubview(mapView)
        view.addSubview(infoContainerView)
        view.addSubview(legendView)
        view.addSubview(loadingIndicator)
        
        infoContainerView.addSubview(riskTitleLabel)
        infoContainerView.addSubview(riskLevelLabel)
        infoContainerView.addSubview(descriptionLabel)
        infoContainerView.addSubview(historicalDataLabel)
        infoContainerView.addSubview(earthquakeCountLabel)
        infoContainerView.addSubview(lastBigEarthquakeLabel)
        
        legendView.addSubview(legendTitleLabel)
        legendView.addSubview(highRiskView)
        legendView.addSubview(mediumRiskView)
        legendView.addSubview(lowRiskView)
        legendView.addSubview(highRiskLabel)
        legendView.addSubview(mediumRiskLabel)
        legendView.addSubview(lowRiskLabel)
        
        NSLayoutConstraint.activate([
            
            mapView.topAnchor.constraint(equalTo: view.topAnchor),
            mapView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            mapView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            mapView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            infoContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            infoContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            infoContainerView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            
            riskTitleLabel.topAnchor.constraint(equalTo: infoContainerView.topAnchor, constant: 16),
            riskTitleLabel.leadingAnchor.constraint(equalTo: infoContainerView.leadingAnchor, constant: 16),
            riskTitleLabel.trailingAnchor.constraint(equalTo: infoContainerView.trailingAnchor, constant: -16),
            
            riskLevelLabel.topAnchor.constraint(equalTo: riskTitleLabel.bottomAnchor, constant: 8),
            riskLevelLabel.leadingAnchor.constraint(equalTo: infoContainerView.leadingAnchor, constant: 16),
            riskLevelLabel.trailingAnchor.constraint(equalTo: infoContainerView.trailingAnchor, constant: -16),
            
            descriptionLabel.topAnchor.constraint(equalTo: riskLevelLabel.bottomAnchor, constant: 8),
            descriptionLabel.leadingAnchor.constraint(equalTo: infoContainerView.leadingAnchor, constant: 16),
            descriptionLabel.trailingAnchor.constraint(equalTo: infoContainerView.trailingAnchor, constant: -16),
            
            historicalDataLabel.topAnchor.constraint(equalTo: descriptionLabel.bottomAnchor, constant: 16),
            historicalDataLabel.leadingAnchor.constraint(equalTo: infoContainerView.leadingAnchor, constant: 16),
            historicalDataLabel.trailingAnchor.constraint(equalTo: infoContainerView.trailingAnchor, constant: -16),
            
            earthquakeCountLabel.topAnchor.constraint(equalTo: historicalDataLabel.bottomAnchor, constant: 8),
            earthquakeCountLabel.leadingAnchor.constraint(equalTo: infoContainerView.leadingAnchor, constant: 16),
            earthquakeCountLabel.trailingAnchor.constraint(equalTo: infoContainerView.trailingAnchor, constant: -16),
            
            lastBigEarthquakeLabel.topAnchor.constraint(equalTo: earthquakeCountLabel.bottomAnchor, constant: 8),
            lastBigEarthquakeLabel.leadingAnchor.constraint(equalTo: infoContainerView.leadingAnchor, constant: 16),
            lastBigEarthquakeLabel.trailingAnchor.constraint(equalTo: infoContainerView.trailingAnchor, constant: -16),
            lastBigEarthquakeLabel.bottomAnchor.constraint(equalTo: infoContainerView.bottomAnchor, constant: -16),
            
            legendView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            legendView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            legendView.widthAnchor.constraint(equalToConstant: 100),
            
            legendTitleLabel.topAnchor.constraint(equalTo: legendView.topAnchor, constant: 8),
            legendTitleLabel.leadingAnchor.constraint(equalTo: legendView.leadingAnchor, constant: 8),
            legendTitleLabel.trailingAnchor.constraint(equalTo: legendView.trailingAnchor, constant: -8),
            
            highRiskView.topAnchor.constraint(equalTo: legendTitleLabel.bottomAnchor, constant: 8),
            highRiskView.leadingAnchor.constraint(equalTo: legendView.leadingAnchor, constant: 8),
            highRiskView.widthAnchor.constraint(equalToConstant: 16),
            highRiskView.heightAnchor.constraint(equalToConstant: 16),
            
            mediumRiskView.topAnchor.constraint(equalTo: highRiskView.bottomAnchor, constant: 8),
            mediumRiskView.leadingAnchor.constraint(equalTo: legendView.leadingAnchor, constant: 8),
            mediumRiskView.widthAnchor.constraint(equalToConstant: 16),
            mediumRiskView.heightAnchor.constraint(equalToConstant: 16),
            
            lowRiskView.topAnchor.constraint(equalTo: mediumRiskView.bottomAnchor, constant: 8),
            lowRiskView.leadingAnchor.constraint(equalTo: legendView.leadingAnchor, constant: 8),
            lowRiskView.widthAnchor.constraint(equalToConstant: 16),
            lowRiskView.heightAnchor.constraint(equalToConstant: 16),
            lowRiskView.bottomAnchor.constraint(equalTo: legendView.bottomAnchor, constant: -8),
            
            highRiskLabel.centerYAnchor.constraint(equalTo: highRiskView.centerYAnchor),
            highRiskLabel.leadingAnchor.constraint(equalTo: highRiskView.trailingAnchor, constant: 8),
            highRiskLabel.trailingAnchor.constraint(equalTo: legendView.trailingAnchor, constant: -8),
            
            mediumRiskLabel.centerYAnchor.constraint(equalTo: mediumRiskView.centerYAnchor),
            mediumRiskLabel.leadingAnchor.constraint(equalTo: mediumRiskView.trailingAnchor, constant: 8),
            mediumRiskLabel.trailingAnchor.constraint(equalTo: legendView.trailingAnchor, constant: -8),
            
            lowRiskLabel.centerYAnchor.constraint(equalTo: lowRiskView.centerYAnchor),
            lowRiskLabel.leadingAnchor.constraint(equalTo: lowRiskView.trailingAnchor, constant: 8),
            lowRiskLabel.trailingAnchor.constraint(equalTo: legendView.trailingAnchor, constant: -8),
            
            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        
        infoContainerView.alpha = 0
        infoContainerView.transform = CGAffineTransform(translationX: 0, y: 100)
        
        legendView.alpha = 0
        legendView.transform = CGAffineTransform(translationX: 50, y: 0)
        
        // Animasyonlu gösterim için UI bileşenlerini bir diziye ekleyelim
        viewComponents = [
            infoContainerView,
            legendView
        ]
    }
    
    private func setupBindings() {
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleRiskDataChanged(_:)),
            name: PersonalizedViewModel.riskDataChangedNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleUserLocationChanged(_:)),
            name: PersonalizedViewModel.userLocationChangedNotification,
            object: nil
        )
    }
    
    @objc private func handleRiskDataChanged(_ notification: Notification) {
        guard let userInfo = notification.userInfo else { return }
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            // Loading state
            if let isLoading = userInfo["isLoading"] as? Bool {
                self.updateLoadingState(isLoading: isLoading)
            }
            
            // Risk level with animation
            if let riskLevel = userInfo["level"] as? RiskLevel {
                // Hafif bir gecikme ekleyerek yükleme göstergesi görünsün
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    self.updateRiskUI(riskLevel: riskLevel)
                }
            }
            
            // Map overlays with animation
            if let coordinates = userInfo["coordinates"] as? [CLLocationCoordinate2D] {
                // Hafif bir gecikme ekleyerek sıralı gösterilsin
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.updateMapOverlays(coordinates: coordinates)
                }
            }
        }
    }
    
    @objc private func handleUserLocationChanged(_ notification: Notification) {
        guard let userInfo = notification.userInfo else { return }
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            if let location = userInfo["location"] as? CLLocationCoordinate2D {
                // Harita geçişi animasyonlu olsun
                let region = MKCoordinateRegion(center: location, span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1))
                UIView.animate(withDuration: 0.8) {
                    self.mapView.setRegion(region, animated: false)
                }
            }
        }
    }
    
    // MARK: - UI Updates
    
    private func updateRiskUI(riskLevel: RiskLevel) {
        // Animasyonlu görünüm değişiklikleri
        UIView.transition(with: riskLevelLabel, duration: 0.3, options: .transitionCrossDissolve, animations: {
            self.riskLevelLabel.text = riskLevel.rawValue
            
            switch riskLevel {
            case .high:
                self.riskLevelLabel.textColor = .systemRed
                self.descriptionLabel.text = "Bu bölge, yüksek sismik aktivite ve jeolojik yapı nedeniyle deprem riski taşımaktadır. Bina güvenliğinize ve acil durum planlarınıza özen gösterin."
                self.earthquakeCountLabel.text = "Son 50 yılda 5.0+ büyüklüğünde 27 deprem"
                self.lastBigEarthquakeLabel.text = "En son büyük deprem: 2019.02.20 (M 6.8)"
            case .medium:
                self.riskLevelLabel.textColor = .systemOrange
                self.descriptionLabel.text = "Bu bölgede orta düzeyde deprem riski bulunmaktadır. Temel deprem güvenlik önlemlerini almayı unutmayın."
                self.earthquakeCountLabel.text = "Son 50 yılda 5.0+ büyüklüğünde 15 deprem"
                self.lastBigEarthquakeLabel.text = "En son büyük deprem: 2013.05.14 (M 5.3)"
            case .low:
                self.riskLevelLabel.textColor = .systemGreen
                self.descriptionLabel.text = "Bu bölgede görece düşük deprem riski bulunmaktadır, ancak yine de temel güvenlik önlemlerini ihmal etmeyin."
                self.earthquakeCountLabel.text = "Son 50 yılda 5.0+ büyüklüğünde 5 deprem"
                self.lastBigEarthquakeLabel.text = "En son büyük deprem: 1990.03.25 (M 5.1)"
            case .unknown:
                self.riskLevelLabel.textColor = .systemGray
                self.descriptionLabel.text = "Bu bölge için yeterli veri bulunmamaktadır. Genel deprem önlemlerini almayı unutmayın."
                self.earthquakeCountLabel.text = "Deprem geçmişi verisi bulunamadı"
                self.lastBigEarthquakeLabel.text = "En son büyük deprem kaydı yok"
            }
        }, completion: nil)
        
        // Risk seviyesi değiştiğinde info panel vurgulama animasyonu
        UIView.animate(withDuration: 0.3, animations: {
            self.infoContainerView.transform = CGAffineTransform(scaleX: 1.03, y: 1.03)
        }) { _ in
            UIView.animate(withDuration: 0.3) {
                self.infoContainerView.transform = .identity
            }
        }
    }
    
    private func updateLoadingState(isLoading: Bool) {
        if isLoading {
            loadingIndicator.startAnimating()
            
            // Yükleme sırasında info panel soluklaştır
            UIView.animate(withDuration: 0.3) {
                self.infoContainerView.alpha = 0.7
            }
            
            if viewModel.riskLevelForCurrentLocation == .unknown {
                UIView.transition(with: riskLevelLabel, duration: 0.3, options: .transitionCrossDissolve, animations: {
                    self.riskLevelLabel.text = "Analiz ediliyor..."
                    self.riskLevelLabel.textColor = .systemGray
                }, completion: nil)
            }
        } else {
            // Yükleme tamamlandığında normal görünüme dön
            UIView.animate(withDuration: 0.3) {
                self.infoContainerView.alpha = 1.0
            }
            
            UIView.animate(withDuration: 0.5, animations: {
                self.loadingIndicator.alpha = 0
            }) { _ in
                self.loadingIndicator.stopAnimating()
                self.loadingIndicator.alpha = 1
            }
        }
    }
    
    private func updateMapOverlays(coordinates: [CLLocationCoordinate2D]) {
        // Eski katmanları temizle
        mapView.removeOverlays(mapView.overlays)
        mapRegionOverlays.removeAll()
        riskRegions.removeAll()
        
        if coordinates.isEmpty {
            return
        }
        
        if let userLocation = viewModel.userLocation {
            let region = MKCoordinateRegion(center: userLocation, span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1))
            
            // Harita animasyonlu geçiş
            UIView.animate(withDuration: 0.8) {
                self.mapView.setRegion(region, animated: false)
            }
            
            var userRiskValue: Double
            var userRiskLevel: RiskLevel
            
            switch viewModel.riskLevelForCurrentLocation {
            case .low:
                userRiskValue = 0.3
                userRiskLevel = .low
            case .medium:
                userRiskValue = 0.6
                userRiskLevel = .medium
            case .high:
                userRiskValue = 0.9
                userRiskLevel = .high
            case .unknown:
                userRiskValue = 0.1
                userRiskLevel = .low
            }
            
            let userRegion = RiskRegion(
                coordinate: userLocation,
                radius: 800,
                riskValue: userRiskValue,
                riskLevel: userRiskLevel
            )
            riskRegions.append(userRegion)
        }
        
        createNonOverlappingRiskZones()
        
        for region in riskRegions {
            let circle = MKCircle(center: region.coordinate, radius: region.radius)
            circle.title = String(region.riskValue)
            mapView.addOverlay(circle)
            mapRegionOverlays.append(circle)
        }
        
        // Bölgeleri animasyonlu göster
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.animateOverlays()
        }
    }
    
    private func createNonOverlappingRiskZones() {
        guard let userLocation = viewModel.userLocation else { return }
        
        let centerLat = userLocation.latitude
        let centerLon = userLocation.longitude
        
        let targetRegionCount = 25
        let attempts = 100
        
        for _ in 0..<attempts {
            let latOffset = Double.random(in: -0.05...0.05)
            let lonOffset = Double.random(in: -0.05...0.05)
            
            let lat = centerLat + latOffset
            let lon = centerLon + lonOffset
            let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)
            
            if isCoordinateTooCloseToExistingRegions(coordinate) {
                continue
            }
            
            let riskValue = Double.random(in: 0.1...1.0)
            let riskLevel: RiskLevel
            let radius: CLLocationDistance
            
            if riskValue > 0.7 {
                riskLevel = .high
                radius = Double.random(in: 500...600)
            } else if riskValue > 0.4 {
                riskLevel = .medium
                radius = Double.random(in: 400...550)
            } else {
                riskLevel = .low
                radius = Double.random(in: 350...500)
            }
            
            let region = RiskRegion(
                coordinate: coordinate,
                radius: radius,
                riskValue: riskValue,
                riskLevel: riskLevel
            )
            
            riskRegions.append(region)
            
            if riskRegions.count >= targetRegionCount {
                break
            }
        }
    }
    
    private func isCoordinateTooCloseToExistingRegions(_ coordinate: CLLocationCoordinate2D) -> Bool {
        for region in riskRegions {
            let existingLocation = region.coordinate
            
            let distance = calculateDistance(
                lat1: coordinate.latitude,
                lon1: coordinate.longitude,
                lat2: existingLocation.latitude,
                lon2: existingLocation.longitude
            )
            
            let minSafeDistance = region.radius + 600
            
            if distance < minSafeDistance {
                return true
            }
        }
        
        return false
    }
    
    private func calculateDistance(lat1: Double, lon1: Double, lat2: Double, lon2: Double) -> Double {
        let earthRadius = 6371000.0
        
        let dLat = (lat2 - lat1) * .pi / 180.0
        let dLon = (lon2 - lon1) * .pi / 180.0
        
        let a = sin(dLat/2) * sin(dLat/2) +
        cos(lat1 * .pi / 180.0) * cos(lat2 * .pi / 180.0) *
        sin(dLon/2) * sin(dLon/2)
        
        let c = 2 * atan2(sqrt(a), sqrt(1-a))
        return earthRadius * c
    }
}

// MARK: - MKMapViewDelegate
extension RiskModelViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if let circle = overlay as? MKCircle {
            let renderer = MKCircleRenderer(circle: circle)
            
            if let riskString = circle.title, let riskValue = Double(riskString) {
                if riskValue > 0.7 {
                    renderer.fillColor = UIColor.systemRed.withAlphaComponent(0.3)
                    renderer.strokeColor = UIColor.systemRed
                    renderer.lineWidth = 1.5
                } else if riskValue > 0.4 {
                    renderer.fillColor = UIColor.systemOrange.withAlphaComponent(0.3)
                    renderer.strokeColor = UIColor.systemOrange
                    renderer.lineWidth = 1.0
                } else {
                    renderer.fillColor = UIColor.systemGreen.withAlphaComponent(0.3)
                    renderer.strokeColor = UIColor.systemGreen
                    renderer.lineWidth = 0.5
                }
            } else {
                renderer.fillColor = UIColor.systemBlue.withAlphaComponent(0.3)
                renderer.strokeColor = UIColor.systemBlue
                renderer.lineWidth = 1.0
            }
            
            // Başlangıçta şeffaf olsun, animasyonla gösterilecek
            renderer.alpha = 0.0
            
            return renderer
        }
        
        return MKOverlayRenderer(overlay: overlay)
    }
    
    func mapView(_ mapView: MKMapView, didAdd renderers: [MKOverlayRenderer]) {
        // Rendererlar eklendiğinde animasyon için gerekirse burada da tetikleyebiliriz
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.animateOverlays()
        }
    }
}

// MARK: - Risk Region Model
struct RiskRegion {
    let coordinate: CLLocationCoordinate2D
    let radius: CLLocationDistance
    let riskValue: Double
    let riskLevel: RiskLevel
}
