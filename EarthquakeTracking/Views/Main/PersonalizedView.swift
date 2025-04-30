import UIKit
import Combine
import CoreLocation
import MapKit

class PersonalizedViewController: UIViewController {
    
    // MARK: - Properties
    private let viewModel = PersonalizedViewModel()
    private var cancellables = Set<AnyCancellable>()
    private let locationManager = CLLocationManager()
    
    // MARK: - UI Elements
    private lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsVerticalScrollIndicator = true
        scrollView.alwaysBounceVertical = true
        return scrollView
    }()
    
    private lazy var contentView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private lazy var headerLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Kişiselleştirilmiş Deprem Özellikleri"
        label.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        label.textColor = .label
        label.textAlignment = .center
        return label
    }()
    
    private lazy var sectionStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.spacing = 20
        stackView.distribution = .fill
        stackView.alignment = .fill
        return stackView
    }()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupLocationManager()
        setupBindings()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Risk data'sını yükle
        viewModel.loadRiskDataForCurrentLocation()
    }
    
    // MARK: - Setup
    private func setupUI() {
        title = "Kişiselleştirilmiş"
        view.backgroundColor = .systemBackground
        
        // Scroll View Hierarchy
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        // Content View Hierarchy
        contentView.addSubview(headerLabel)
        contentView.addSubview(sectionStackView)
        
        // Add AI Feature Sections
        sectionStackView.addArrangedSubview(createNotificationSection())
        sectionStackView.addArrangedSubview(createSimulationSection())
        sectionStackView.addArrangedSubview(createARScanSection())
        sectionStackView.addArrangedSubview(createRiskModelSection())
        
        // Setup Constraints
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            headerLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            headerLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            headerLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            sectionStackView.topAnchor.constraint(equalTo: headerLabel.bottomAnchor, constant: 24),
            sectionStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            sectionStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            sectionStackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -24)
        ])
    }
    
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }
    
    private func setupBindings() {
        // Deprem simülasyonu durumunu dinle
        viewModel.$isSimulationActive
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isActive in
                // Simülasyon durumunda UI güncellemesi
                self?.updateSimulationUI(isActive: isActive)
            }
            .store(in: &cancellables)
        
        // AR tarama durumunu dinle
        viewModel.$isARScanActive
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isActive in
                // AR taraması durumunda UI güncellemesi
                self?.updateARScanUI(isActive: isActive)
            }
            .store(in: &cancellables)
        
        // Risk model yükleme durumunu dinle
        viewModel.$isLoadingRiskData
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isLoading in
                // Risk model yüklenirken UI güncellemesi
                self?.updateRiskModelUI(isLoading: isLoading)
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Section Builders
    
    private func createNotificationSection() -> UIView {
        let sectionView = FeatureSectionView(
            title: "Kişiselleştirilmiş Uyarı Sistemi",
            icon: UIImage(systemName: "bell.fill"),
            description: "Önem verdiğiniz bölgeler için deprem uyarılarını özelleştirin. Ailenizin veya sevdiklerinizin yaşadığı bölgelerdeki depremlerden anında haberdar olun."
        )
        
        let openButton = UIButton(type: .system)
        openButton.translatesAutoresizingMaskIntoConstraints = false
        openButton.setTitle("Uyarıları Özelleştir", for: .normal)
        openButton.setImage(UIImage(systemName: "chevron.right"), for: .normal)
        openButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        openButton.backgroundColor = .systemBlue
        openButton.tintColor = .white
        openButton.layer.cornerRadius = 10
        openButton.contentEdgeInsets = UIEdgeInsets(top: 10, left: 16, bottom: 10, right: 16)
        openButton.addTarget(self, action: #selector(openNotificationSettings), for: .touchUpInside)
        
        sectionView.addActionButton(openButton)
        return sectionView
    }
    
    private func createSimulationSection() -> UIView {
        let sectionView = FeatureSectionView(
            title: "Deprem Simülasyonu",
            icon: UIImage(systemName: "waveform.path.ecg"),
            description: "Farklı büyüklüklerdeki depremlerin nasıl hissedileceğini deneyimleyin. Deprem anında neler yaşanabileceğini öğrenmek için güvenli bir simülasyon."
        )
        
        let openButton = UIButton(type: .system)
        openButton.translatesAutoresizingMaskIntoConstraints = false
        openButton.setTitle("Simülasyonu Başlat", for: .normal)
        openButton.setImage(UIImage(systemName: "chevron.right"), for: .normal)
        openButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        openButton.backgroundColor = .systemOrange
        openButton.tintColor = .white
        openButton.layer.cornerRadius = 10
        openButton.contentEdgeInsets = UIEdgeInsets(top: 10, left: 16, bottom: 10, right: 16)
        openButton.addTarget(self, action: #selector(openSimulation), for: .touchUpInside)
        
        sectionView.addActionButton(openButton)
        return sectionView
    }
    
    private func createARScanSection() -> UIView {
        let sectionView = FeatureSectionView(
            title: "AR Ev Güvenliği Taraması",
            icon: UIImage(systemName: "camera.viewfinder"),
            description: "Artırılmış gerçeklik teknolojisiyle evinizin depreme karşı güvenliğini tarayın. Potansiyel riskleri belirleyin ve güvenlik önerileri alın."
        )
        
        let openButton = UIButton(type: .system)
        openButton.translatesAutoresizingMaskIntoConstraints = false
        openButton.setTitle("AR Taramayı Başlat", for: .normal)
        openButton.setImage(UIImage(systemName: "chevron.right"), for: .normal)
        openButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        openButton.backgroundColor = .systemGreen
        openButton.tintColor = .white
        openButton.layer.cornerRadius = 10
        openButton.contentEdgeInsets = UIEdgeInsets(top: 10, left: 16, bottom: 10, right: 16)
        openButton.addTarget(self, action: #selector(openARScan), for: .touchUpInside)
        
        sectionView.addActionButton(openButton)
        return sectionView
    }
    
    private func createRiskModelSection() -> UIView {
        let sectionView = FeatureSectionView(
            title: "Deprem Riski Tahmin Modeli",
            icon: UIImage(systemName: "map.fill"),
            description: "Yapay zeka ile geçmiş deprem verilerini analiz ederek bölgelerin deprem riskini görüntüleyin. Bölgenizdeki deprem olasılığını tahmin eden gelişmiş model."
        )
        
        let openButton = UIButton(type: .system)
        openButton.translatesAutoresizingMaskIntoConstraints = false
        openButton.setTitle("Risk Haritasını Görüntüle", for: .normal)
        openButton.setImage(UIImage(systemName: "chevron.right"), for: .normal)
        openButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        openButton.backgroundColor = .systemPurple
        openButton.tintColor = .white
        openButton.layer.cornerRadius = 10
        openButton.contentEdgeInsets = UIEdgeInsets(top: 10, left: 16, bottom: 10, right: 16)
        openButton.addTarget(self, action: #selector(openRiskModel), for: .touchUpInside)
        
        sectionView.addActionButton(openButton)
        return sectionView
    }
    
    // MARK: - UI Update Methods
    
    private func updateSimulationUI(isActive: Bool) {
        // Simülasyon aktifliğine göre UI güncellemesi
    }
    
    private func updateARScanUI(isActive: Bool) {
        // AR tarama aktifliğine göre UI güncellemesi
    }
    
    private func updateRiskModelUI(isLoading: Bool) {
        // Risk model yüklenmesine göre UI güncellemesi
    }
    
    // MARK: - Action Methods
    
    @objc private func openNotificationSettings() {
        let notificationVC = NotificationSettingsViewController(viewModel: viewModel)
        navigationController?.pushViewController(notificationVC, animated: true)
    }
    
    @objc private func openSimulation() {
        let simulationVC = EarthquakeSimulationViewController(viewModel: viewModel)
        navigationController?.pushViewController(simulationVC, animated: true)
    }
    
    @objc private func openARScan() {
        let arScanVC = ARScanViewController(viewModel: viewModel)
        navigationController?.pushViewController(arScanVC, animated: true)
    }
    
    @objc private func openRiskModel() {
        let riskModelVC = RiskModelViewController(viewModel: viewModel)
        navigationController?.pushViewController(riskModelVC, animated: true)
    }
}

// MARK: - CLLocationManagerDelegate
extension PersonalizedViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        // ViewModel'e kullanıcı konumunu güncelle
        viewModel.userLocation = location.coordinate
        
        // Konumu aldıktan sonra sürekli güncellemeyi durdur (pil tasarrufu için)
        manager.stopUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Konum hatası: \(error.localizedDescription)")
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            manager.startUpdatingLocation()
        case .denied, .restricted:
            showLocationAlert()
        default:
            break
        }
    }
    
    private func showLocationAlert() {
        let alertController = UIAlertController(
            title: "Konum Erişimi Gerekli",
            message: "Size özel deprem uyarıları ve risk tahminleri için konum erişimine izin vermeniz gerekiyor.",
            preferredStyle: .alert
        )
        
        let settingsAction = UIAlertAction(title: "Ayarlar", style: .default) { _ in
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }
        }
        
        let cancelAction = UIAlertAction(title: "İptal", style: .cancel, handler: nil)
        
        alertController.addAction(settingsAction)
        alertController.addAction(cancelAction)
        
        present(alertController, animated: true, completion: nil)
    }
}

// MARK: - Feature Section View
class FeatureSectionView: UIView {
    
    private let titleLabel = UILabel()
    private let iconImageView = UIImageView()
    private let descriptionLabel = UILabel()
    private let actionStackView = UIStackView()
    
    init(title: String, icon: UIImage?, description: String) {
        super.init(frame: .zero)
        setupUI()
        configure(title: title, icon: icon, description: description)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        // Container View
        self.backgroundColor = .secondarySystemBackground
        self.layer.cornerRadius = 12
        self.clipsToBounds = true
        
        // Icon Image View
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.tintColor = .systemBlue
        
        // Title Label
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        titleLabel.textColor = .label
        titleLabel.numberOfLines = 1
        
        // Description Label
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        descriptionLabel.font = UIFont.systemFont(ofSize: 14)
        descriptionLabel.textColor = .secondaryLabel
        descriptionLabel.numberOfLines = 0
        
        // Action Stack View
        actionStackView.translatesAutoresizingMaskIntoConstraints = false
        actionStackView.axis = .horizontal
        actionStackView.alignment = .trailing
        actionStackView.distribution = .fill
        actionStackView.spacing = 10
        
        // Header Stack (Icon + Title)
        let headerStack = UIStackView(arrangedSubviews: [iconImageView, titleLabel])
        headerStack.translatesAutoresizingMaskIntoConstraints = false
        headerStack.axis = .horizontal
        headerStack.spacing = 8
        headerStack.alignment = .center
        
        // Content Stack
        let contentStack = UIStackView(arrangedSubviews: [headerStack, descriptionLabel, actionStackView])
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        contentStack.axis = .vertical
        contentStack.spacing = 12
        contentStack.alignment = .fill
        
        // Add to view hierarchy
        addSubview(contentStack)
        
        // Constraints
        NSLayoutConstraint.activate([
            contentStack.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            contentStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            contentStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            contentStack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -16),
            
            iconImageView.widthAnchor.constraint(equalToConstant: 24),
            iconImageView.heightAnchor.constraint(equalToConstant: 24)
        ])
    }
    
    private func configure(title: String, icon: UIImage?, description: String) {
        titleLabel.text = title
        iconImageView.image = icon
        descriptionLabel.text = description
    }
    
    func addActionButton(_ button: UIButton) {
        actionStackView.addArrangedSubview(button)
    }
}
