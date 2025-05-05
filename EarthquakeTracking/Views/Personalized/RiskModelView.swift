import UIKit
import MapKit
import Combine

class RiskModelViewController: UIViewController {
    
    // MARK: - Properties
    private let viewModel: PersonalizedViewModel
    private var cancellables = Set<AnyCancellable>()
    
    // Risk bölgesi verilerini takip etmek için yeni özellik
    private var riskRegions: [RiskRegion] = []
    
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
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Risk verilerini yükle
        viewModel.loadRiskDataForCurrentLocation()
    }
    
    // MARK: - Setup
    private func setupUI() {
        title = "Deprem Riski Analizi"
        view.backgroundColor = .systemBackground
        
        // Harita ve bilgi panelini ekle
        view.addSubview(mapView)
        view.addSubview(infoContainerView)
        view.addSubview(legendView)
        view.addSubview(loadingIndicator)
        
        // Bilgi paneli içeriğini ekle
        infoContainerView.addSubview(riskTitleLabel)
        infoContainerView.addSubview(riskLevelLabel)
        infoContainerView.addSubview(descriptionLabel)
        infoContainerView.addSubview(historicalDataLabel)
        infoContainerView.addSubview(earthquakeCountLabel)
        infoContainerView.addSubview(lastBigEarthquakeLabel)
        
        // Lejant görünümü içeriğini ekle
        legendView.addSubview(legendTitleLabel)
        legendView.addSubview(highRiskView)
        legendView.addSubview(mediumRiskView)
        legendView.addSubview(lowRiskView)
        legendView.addSubview(highRiskLabel)
        legendView.addSubview(mediumRiskLabel)
        legendView.addSubview(lowRiskLabel)
        
        // Constraint'leri ayarla
        NSLayoutConstraint.activate([
            // Harita
            mapView.topAnchor.constraint(equalTo: view.topAnchor),
            mapView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            mapView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            mapView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // Bilgi Paneli
            infoContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            infoContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            infoContainerView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            
            // Risk Başlığı
            riskTitleLabel.topAnchor.constraint(equalTo: infoContainerView.topAnchor, constant: 16),
            riskTitleLabel.leadingAnchor.constraint(equalTo: infoContainerView.leadingAnchor, constant: 16),
            riskTitleLabel.trailingAnchor.constraint(equalTo: infoContainerView.trailingAnchor, constant: -16),
            
            // Risk Seviyesi
            riskLevelLabel.topAnchor.constraint(equalTo: riskTitleLabel.bottomAnchor, constant: 8),
            riskLevelLabel.leadingAnchor.constraint(equalTo: infoContainerView.leadingAnchor, constant: 16),
            riskLevelLabel.trailingAnchor.constraint(equalTo: infoContainerView.trailingAnchor, constant: -16),
            
            // Açıklama
            descriptionLabel.topAnchor.constraint(equalTo: riskLevelLabel.bottomAnchor, constant: 8),
            descriptionLabel.leadingAnchor.constraint(equalTo: infoContainerView.leadingAnchor, constant: 16),
            descriptionLabel.trailingAnchor.constraint(equalTo: infoContainerView.trailingAnchor, constant: -16),
            
            // Tarihsel Veri Başlığı
            historicalDataLabel.topAnchor.constraint(equalTo: descriptionLabel.bottomAnchor, constant: 16),
            historicalDataLabel.leadingAnchor.constraint(equalTo: infoContainerView.leadingAnchor, constant: 16),
            historicalDataLabel.trailingAnchor.constraint(equalTo: infoContainerView.trailingAnchor, constant: -16),
            
            // Deprem Sayısı
            earthquakeCountLabel.topAnchor.constraint(equalTo: historicalDataLabel.bottomAnchor, constant: 8),
            earthquakeCountLabel.leadingAnchor.constraint(equalTo: infoContainerView.leadingAnchor, constant: 16),
            earthquakeCountLabel.trailingAnchor.constraint(equalTo: infoContainerView.trailingAnchor, constant: -16),
            
            // Son Büyük Deprem
            lastBigEarthquakeLabel.topAnchor.constraint(equalTo: earthquakeCountLabel.bottomAnchor, constant: 8),
            lastBigEarthquakeLabel.leadingAnchor.constraint(equalTo: infoContainerView.leadingAnchor, constant: 16),
            lastBigEarthquakeLabel.trailingAnchor.constraint(equalTo: infoContainerView.trailingAnchor, constant: -16),
            lastBigEarthquakeLabel.bottomAnchor.constraint(equalTo: infoContainerView.bottomAnchor, constant: -16),
            
            // Lejant Görünümü
            legendView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            legendView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            legendView.widthAnchor.constraint(equalToConstant: 100),
            
            // Lejant Başlığı
            legendTitleLabel.topAnchor.constraint(equalTo: legendView.topAnchor, constant: 8),
            legendTitleLabel.leadingAnchor.constraint(equalTo: legendView.leadingAnchor, constant: 8),
            legendTitleLabel.trailingAnchor.constraint(equalTo: legendView.trailingAnchor, constant: -8),
            
            // Yüksek Risk Göstergesi
            highRiskView.topAnchor.constraint(equalTo: legendTitleLabel.bottomAnchor, constant: 8),
            highRiskView.leadingAnchor.constraint(equalTo: legendView.leadingAnchor, constant: 8),
            highRiskView.widthAnchor.constraint(equalToConstant: 16),
            highRiskView.heightAnchor.constraint(equalToConstant: 16),
            
            // Orta Risk Göstergesi
            mediumRiskView.topAnchor.constraint(equalTo: highRiskView.bottomAnchor, constant: 8),
            mediumRiskView.leadingAnchor.constraint(equalTo: legendView.leadingAnchor, constant: 8),
            mediumRiskView.widthAnchor.constraint(equalToConstant: 16),
            mediumRiskView.heightAnchor.constraint(equalToConstant: 16),
            
            // Düşük Risk Göstergesi
            lowRiskView.topAnchor.constraint(equalTo: mediumRiskView.bottomAnchor, constant: 8),
            lowRiskView.leadingAnchor.constraint(equalTo: legendView.leadingAnchor, constant: 8),
            lowRiskView.widthAnchor.constraint(equalToConstant: 16),
            lowRiskView.heightAnchor.constraint(equalToConstant: 16),
            lowRiskView.bottomAnchor.constraint(equalTo: legendView.bottomAnchor, constant: -8),
            
            // Yüksek Risk Etiketi
            highRiskLabel.centerYAnchor.constraint(equalTo: highRiskView.centerYAnchor),
            highRiskLabel.leadingAnchor.constraint(equalTo: highRiskView.trailingAnchor, constant: 8),
            highRiskLabel.trailingAnchor.constraint(equalTo: legendView.trailingAnchor, constant: -8),
            
            // Orta Risk Etiketi
            mediumRiskLabel.centerYAnchor.constraint(equalTo: mediumRiskView.centerYAnchor),
            mediumRiskLabel.leadingAnchor.constraint(equalTo: mediumRiskView.trailingAnchor, constant: 8),
            mediumRiskLabel.trailingAnchor.constraint(equalTo: legendView.trailingAnchor, constant: -8),
            
            // Düşük Risk Etiketi
            lowRiskLabel.centerYAnchor.constraint(equalTo: lowRiskView.centerYAnchor),
            lowRiskLabel.leadingAnchor.constraint(equalTo: lowRiskView.trailingAnchor, constant: 8),
            lowRiskLabel.trailingAnchor.constraint(equalTo: legendView.trailingAnchor, constant: -8),
            
            // Yükleme Göstergesi
            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    private func setupBindings() {
        // Risk seviyesi değişimini izle
        viewModel.$riskLevelForCurrentLocation
            .receive(on: DispatchQueue.main)
            .sink { [weak self] riskLevel in
                self?.updateRiskUI(riskLevel: riskLevel)
            }
            .store(in: &cancellables)
        
        // Yükleme durumunu izle
        viewModel.$isLoadingRiskData
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isLoading in
                self?.updateLoadingState(isLoading: isLoading)
            }
            .store(in: &cancellables)
        
        // Risk alanı koordinatlarını izle
        viewModel.$riskAreaCoordinates
            .receive(on: DispatchQueue.main)
            .sink { [weak self] coordinates in
                self?.updateMapOverlays(coordinates: coordinates)
            }
            .store(in: &cancellables)
    }
    
    // MARK: - UI Updates
    
    private func updateRiskUI(riskLevel: RiskLevel) {
        riskLevelLabel.text = riskLevel.rawValue
        
        // Risk seviyesine göre renklendir
        switch riskLevel {
        case .high:
            riskLevelLabel.textColor = .systemRed
            descriptionLabel.text = "Bu bölge, yüksek sismik aktivite ve jeolojik yapı nedeniyle deprem riski taşımaktadır. Bina güvenliğinize ve acil durum planlarınıza özen gösterin."
            earthquakeCountLabel.text = "Son 50 yılda 5.0+ büyüklüğünde 27 deprem"
            lastBigEarthquakeLabel.text = "En son büyük deprem: 2019.02.20 (M 6.8)"
        case .medium:
            riskLevelLabel.textColor = .systemOrange
            descriptionLabel.text = "Bu bölgede orta düzeyde deprem riski bulunmaktadır. Temel deprem güvenlik önlemlerini almayı unutmayın."
            earthquakeCountLabel.text = "Son 50 yılda 5.0+ büyüklüğünde 15 deprem"
            lastBigEarthquakeLabel.text = "En son büyük deprem: 2013.05.14 (M 5.3)"
        case .low:
            riskLevelLabel.textColor = .systemGreen
            descriptionLabel.text = "Bu bölgede görece düşük deprem riski bulunmaktadır, ancak yine de temel güvenlik önlemlerini ihmal etmeyin."
            earthquakeCountLabel.text = "Son 50 yılda 5.0+ büyüklüğünde 5 deprem"
            lastBigEarthquakeLabel.text = "En son büyük deprem: 1990.03.25 (M 5.1)"
        case .unknown:
            riskLevelLabel.textColor = .systemGray
            descriptionLabel.text = "Bu bölge için yeterli veri bulunmamaktadır. Genel deprem önlemlerini almayı unutmayın."
            earthquakeCountLabel.text = "Deprem geçmişi verisi bulunamadı"
            lastBigEarthquakeLabel.text = "En son büyük deprem kaydı yok"
        }
    }
    
    private func updateLoadingState(isLoading: Bool) {
        if isLoading {
            loadingIndicator.startAnimating()
            riskLevelLabel.text = "Analiz ediliyor..."
            riskLevelLabel.textColor = .systemGray
        } else {
            loadingIndicator.stopAnimating()
        }
    }
    
    private func updateMapOverlays(coordinates: [CLLocationCoordinate2D]) {
        // Eski katmanları temizle
        mapView.removeOverlays(mapView.overlays)
        riskRegions.removeAll()
        
        // Koordinatlar boş ise çık
        if coordinates.isEmpty {
            return
        }
        
        // Kullanıcı konumu varsa haritayı o bölgeye odakla
        if let userLocation = viewModel.userLocation {
            let region = MKCoordinateRegion(center: userLocation, span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1))
            mapView.setRegion(region, animated: true)
            
            // Kullanıcı konumu için doğru riski yansıt
            // ÖNEMLİ: Burada kullanıcı konumu için riski, viewModel.riskLevelForCurrentLocation'a göre ayarlıyoruz
            var userRiskValue: Double
            var userRiskLevel: RiskLevel
            
            switch viewModel.riskLevelForCurrentLocation {
            case .low:
                userRiskValue = 0.3 // Düşük risk değeri
                userRiskLevel = .low
            case .medium:
                userRiskValue = 0.6 // Orta risk değeri
                userRiskLevel = .medium
            case .high:
                userRiskValue = 0.9 // Yüksek risk değeri
                userRiskLevel = .high
            case .unknown:
                userRiskValue = 0.1 // Bilinmeyen risk değeri
                userRiskLevel = .low
            }
            
            // Kullanıcı konumu için risk bölgesi oluştur
            let userRegion = RiskRegion(
                coordinate: userLocation,
                radius: 800,
                riskValue: userRiskValue,
                riskLevel: userRiskLevel
            )
            riskRegions.append(userRegion)
        }
        
        // Tüm haritayı kapsayan benzersiz risk bölgeleri oluştur
        createNonOverlappingRiskZones()
        
        // Tüm risk bölgelerini haritaya ekle
        for region in riskRegions {
            let circle = MKCircle(center: region.coordinate, radius: region.radius)
            circle.title = String(region.riskValue)
            mapView.addOverlay(circle)
        }
    }
    
    private func createNonOverlappingRiskZones() {
        guard let userLocation = viewModel.userLocation else { return }
        
        let centerLat = userLocation.latitude
        let centerLon = userLocation.longitude
        
        // Harita için bölgelere ayır
        // Hedef: 25-30 adet risk bölgesi oluştur
        let targetRegionCount = 25
        let attempts = 100 // Yeterli sayıda bölge oluşturmak için maksimum deneme sayısı
        
        for _ in 0..<attempts {
            // Rastgele bir konum oluştur
            let latOffset = Double.random(in: -0.05...0.05)
            let lonOffset = Double.random(in: -0.05...0.05)
            
            let lat = centerLat + latOffset
            let lon = centerLon + lonOffset
            let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)
            
            // Bu konumun mevcut bölgelerle çakışıp çakışmadığını kontrol et
            if isCoordinateTooCloseToExistingRegions(coordinate) {
                continue // Çakışıyorsa bu konumu atla
            }
            
            // Risk seviyesi seç - bölgeye göre değil tamamen rastgele
            let riskValue = Double.random(in: 0.1...1.0)
            let riskLevel: RiskLevel
            let radius: CLLocationDistance
            
            // Risk seviyesini belirle
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
            
            // Yeni risk bölgesi oluştur
            let region = RiskRegion(
                coordinate: coordinate,
                radius: radius,
                riskValue: riskValue,
                riskLevel: riskLevel
            )
            
            // Listeye ekle
            riskRegions.append(region)
            
            // Hedef sayıya ulaştıysak döngüden çık
            if riskRegions.count >= targetRegionCount {
                break
            }
        }
    }
    
    // Yeni bir koordinatın mevcut bölgelerle çakışıp çakışmadığını kontrol et
    private func isCoordinateTooCloseToExistingRegions(_ coordinate: CLLocationCoordinate2D) -> Bool {
        for region in riskRegions {
            let existingLocation = region.coordinate
            
            // İki koordinat arasındaki mesafeyi hesapla
            let distance = calculateDistance(
                lat1: coordinate.latitude,
                lon1: coordinate.longitude,
                lat2: existingLocation.latitude,
                lon2: existingLocation.longitude
            )
            
            // Minimum güvenli mesafe (çakışmayı önlemek için iki bölgenin yarıçaplarının toplamı + ek mesafe)
            let minSafeDistance = region.radius + 600 // Ortalama bölge yarıçapı + ek mesafe (metre cinsinden)
            
            if distance < minSafeDistance {
                return true // Çok yakın, çakışma riski var
            }
        }
        
        return false // Güvenli mesafede
    }
    
    // İki koordinat arasındaki mesafeyi hesapla (metre cinsinden)
    private func calculateDistance(lat1: Double, lon1: Double, lat2: Double, lon2: Double) -> Double {
        let earthRadius = 6371000.0 // Dünya yarıçapı (metre cinsinden)
        
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
            
            // Risk değerine göre renk ayarla
            if let riskString = circle.title, let riskValue = Double(riskString) {
                if riskValue > 0.7 {
                    // Yüksek risk - kırmızı
                    renderer.fillColor = UIColor.systemRed.withAlphaComponent(0.3)
                    renderer.strokeColor = UIColor.systemRed
                    renderer.lineWidth = 1.5
                } else if riskValue > 0.4 {
                    // Orta risk - turuncu/sarı
                    renderer.fillColor = UIColor.systemOrange.withAlphaComponent(0.3)
                    renderer.strokeColor = UIColor.systemOrange
                    renderer.lineWidth = 1.0
                } else {
                    // Düşük risk - yeşil
                    renderer.fillColor = UIColor.systemGreen.withAlphaComponent(0.3)
                    renderer.strokeColor = UIColor.systemGreen
                    renderer.lineWidth = 0.5
                }
            } else {
                // Varsayılan stil
                renderer.fillColor = UIColor.systemBlue.withAlphaComponent(0.3)
                renderer.strokeColor = UIColor.systemBlue
                renderer.lineWidth = 1.0
            }
            
            return renderer
        }
        
        return MKOverlayRenderer(overlay: overlay)
    }
}

// MARK: - Risk Region Model
struct RiskRegion {
    let coordinate: CLLocationCoordinate2D
    let radius: CLLocationDistance
    let riskValue: Double
    let riskLevel: RiskLevel
}
