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
    
    private lazy var headerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = AppTheme.primaryColor
        view.layer.cornerRadius = 16
        
        // Add shadow
        view.layer.shadowColor = AppTheme.primaryColor.cgColor
        view.layer.shadowOffset = CGSize(width: 0, height: 4)
        view.layer.shadowRadius = 8
        view.layer.shadowOpacity = 0.3
        
        return view
    }()
    
    private lazy var headerIconView: UIImageView = {
        let imageView = UIImageView(image: UIImage(systemName: "person.fill.viewfinder"))
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = .white
        return imageView
    }()
    
    private lazy var headerLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Kişiselleştirilmiş Deprem Özellikleri"
        label.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        label.textColor = .white
        label.numberOfLines = 2
        return label
    }()
    
    private lazy var headerDescriptionLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Size ve konumunuza özel deprem bilgileri ve uyarılar alın."
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = .white.withAlphaComponent(0.9)
        label.numberOfLines = 0
        return label
    }()
    
    private lazy var featuresContainerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .clear
        return view
    }()
    
    private lazy var riskIndicatorView: RiskIndicatorView = {
        let view = RiskIndicatorView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
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
        view.backgroundColor = AppTheme.backgroundColor
        
        // Scroll View Hierarchy
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        // Content View Hierarchy
        contentView.addSubview(headerView)
        headerView.addSubview(headerIconView)
        headerView.addSubview(headerLabel)
        headerView.addSubview(headerDescriptionLabel)
        
        contentView.addSubview(riskIndicatorView)
        contentView.addSubview(featuresContainerView)
        
        // Setup Features
        setupFeatures()
        
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
            
            // Header View
            headerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            headerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            headerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            headerIconView.topAnchor.constraint(equalTo: headerView.topAnchor, constant: 20),
            headerIconView.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 20),
            headerIconView.widthAnchor.constraint(equalToConstant: 40),
            headerIconView.heightAnchor.constraint(equalToConstant: 40),
            
            headerLabel.topAnchor.constraint(equalTo: headerView.topAnchor, constant: 20),
            headerLabel.leadingAnchor.constraint(equalTo: headerIconView.trailingAnchor, constant: 16),
            headerLabel.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -20),
            
            headerDescriptionLabel.topAnchor.constraint(equalTo: headerLabel.bottomAnchor, constant: 8),
            headerDescriptionLabel.leadingAnchor.constraint(equalTo: headerIconView.trailingAnchor, constant: 16),
            headerDescriptionLabel.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -20),
            headerDescriptionLabel.bottomAnchor.constraint(equalTo: headerView.bottomAnchor, constant: -20),
            
            // Risk Indicator View
            riskIndicatorView.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 24),
            riskIndicatorView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            riskIndicatorView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            // Features Container
            featuresContainerView.topAnchor.constraint(equalTo: riskIndicatorView.bottomAnchor, constant: 24),
            featuresContainerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            featuresContainerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            featuresContainerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -24)
        ])
    }
    
    private func setupFeatures() {
        let featuresStackView = UIStackView()
        featuresStackView.translatesAutoresizingMaskIntoConstraints = false
        featuresStackView.axis = .vertical
        featuresStackView.spacing = 20
        featuresStackView.distribution = .fill
        featuresStackView.alignment = .fill
        
        featuresContainerView.addSubview(featuresStackView)
        
        NSLayoutConstraint.activate([
            featuresStackView.topAnchor.constraint(equalTo: featuresContainerView.topAnchor),
            featuresStackView.leadingAnchor.constraint(equalTo: featuresContainerView.leadingAnchor),
            featuresStackView.trailingAnchor.constraint(equalTo: featuresContainerView.trailingAnchor),
            featuresStackView.bottomAnchor.constraint(equalTo: featuresContainerView.bottomAnchor)
        ])
        
        // Feature 1: Notification Settings
        let notificationFeature = createFeatureCard(
            title: "Kişiselleştirilmiş Uyarı Sistemi",
            description: "Önem verdiğiniz bölgeler için deprem uyarılarını özelleştirin.",
            iconName: "bell.fill",
            color: AppTheme.primaryColor,
            action: #selector(openNotificationSettings)
        )
        
        // Feature 2: Earthquake Simulation
        let simulationFeature = createFeatureCard(
            title: "Deprem Simülasyonu",
            description: "Farklı büyüklüklerdeki depremlerin etkilerini deneyimleyin.",
            iconName: "waveform.path.ecg",
            color: AppTheme.secondaryColor,
            action: #selector(openSimulation)
        )
        
        // Feature 3: AR Home Safety Scan
        let arScanFeature = createFeatureCard(
            title: "AR Ev Güvenliği Taraması",
            description: "Artırılmış gerçeklik ile evinizin deprem güvenliğini analiz edin.",
            iconName: "camera.viewfinder",
            color: AppTheme.accentColor,
            action: #selector(openARScan)
        )
        
        // Feature 4: Risk Model
        let riskModelFeature = createFeatureCard(
            title: "Deprem Riski Tahmin Modeli",
            description: "Yapay zeka ile bölgenizdeki deprem riskini görüntüleyin.",
            iconName: "map.fill",
            color: AppTheme.primaryLightColor,
            action: #selector(openRiskModel)
        )
        
        // Add features to stack view
        featuresStackView.addArrangedSubview(notificationFeature)
        featuresStackView.addArrangedSubview(simulationFeature)
        featuresStackView.addArrangedSubview(arScanFeature)
        featuresStackView.addArrangedSubview(riskModelFeature)
    }
    
    private func createFeatureCard(title: String, description: String, iconName: String, color: UIColor, action: Selector) -> UIView {
        let cardView = UIView()
        cardView.translatesAutoresizingMaskIntoConstraints = false
        AppTheme.applyCardStyle(to: cardView)
        
        // Make the entire card clickable
        let tapGesture = UITapGestureRecognizer(target: self, action: action)
        cardView.addGestureRecognizer(tapGesture)
        cardView.isUserInteractionEnabled = true
        
        // Icon container
        let iconContainer = UIView()
        iconContainer.translatesAutoresizingMaskIntoConstraints = false
        iconContainer.backgroundColor = color
        iconContainer.layer.cornerRadius = 25
        
        // Add shadow to icon
        iconContainer.layer.shadowColor = color.cgColor
        iconContainer.layer.shadowOffset = CGSize(width: 0, height: 3)
        iconContainer.layer.shadowRadius = 5
        iconContainer.layer.shadowOpacity = 0.4
        
        // Icon
        let iconImageView = UIImageView(image: UIImage(systemName: iconName))
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.tintColor = .white
        
        // Title
        let titleLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = title
        titleLabel.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        titleLabel.textColor = AppTheme.titleTextColor
        
        // Description
        let descriptionLabel = UILabel()
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        descriptionLabel.text = description
        descriptionLabel.font = UIFont.systemFont(ofSize: 14)
        descriptionLabel.textColor = AppTheme.bodyTextColor
        descriptionLabel.numberOfLines = 0
        
        // Arrow indicator
        let arrowImageView = UIImageView(image: UIImage(systemName: "chevron.right"))
        arrowImageView.translatesAutoresizingMaskIntoConstraints = false
        arrowImageView.contentMode = .scaleAspectFit
        arrowImageView.tintColor = color
        
        // Add views to hierarchy
        iconContainer.addSubview(iconImageView)
        cardView.addSubview(iconContainer)
        cardView.addSubview(titleLabel)
        cardView.addSubview(descriptionLabel)
        cardView.addSubview(arrowImageView)
        
        // Set constraints
        NSLayoutConstraint.activate([
            cardView.heightAnchor.constraint(greaterThanOrEqualToConstant: 100),
            
            iconContainer.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 16),
            iconContainer.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 16),
            iconContainer.widthAnchor.constraint(equalToConstant: 50),
            iconContainer.heightAnchor.constraint(equalToConstant: 50),
            
            iconImageView.centerXAnchor.constraint(equalTo: iconContainer.centerXAnchor),
            iconImageView.centerYAnchor.constraint(equalTo: iconContainer.centerYAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 24),
            iconImageView.heightAnchor.constraint(equalToConstant: 24),
            
            titleLabel.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: iconContainer.trailingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: arrowImageView.leadingAnchor, constant: -8),
            
            descriptionLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            descriptionLabel.leadingAnchor.constraint(equalTo: iconContainer.trailingAnchor, constant: 16),
            descriptionLabel.trailingAnchor.constraint(equalTo: arrowImageView.leadingAnchor, constant: -8),
            descriptionLabel.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -16),
            
            arrowImageView.centerYAnchor.constraint(equalTo: cardView.centerYAnchor),
            arrowImageView.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -16),
            arrowImageView.widthAnchor.constraint(equalToConstant: 16),
            arrowImageView.heightAnchor.constraint(equalToConstant: 16)
        ])
        
        return cardView
    }
    
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }
    
    private func setupBindings() {
        // Risk level changes
        viewModel.$riskLevelForCurrentLocation
            .receive(on: DispatchQueue.main)
            .sink { [weak self] riskLevel in
                self?.riskIndicatorView.updateRiskLevel(riskLevel)
            }
            .store(in: &cancellables)
        
        // Loading state
        viewModel.$isLoadingRiskData
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isLoading in
                self?.riskIndicatorView.setLoading(isLoading)
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Actions
    @objc private func openNotificationSettings() {
        let notificationVC = NotificationSettingsViewController(viewModel: viewModel)
        navigationController?.pushViewController(notificationVC, animated: true)
    }
    
    @objc private func openSimulation() {
        let simulationVC = EarthquakeSimulationViewController(viewModel: viewModel)
        navigationController?.pushViewController(simulationVC, animated: true)
    }
    
    @objc private func openARScan() {
        let arSimulationVC = ARRealObjectSimulationViewController(viewModel: viewModel)
        navigationController?.pushViewController(arSimulationVC, animated: true)
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

// MARK: - RiskIndicatorView
class RiskIndicatorView: UIView {
    
    private let containerView = UIView()
    private let titleLabel = UILabel()
    private let riskLabel = UILabel()
    private let riskBar = UIProgressView()
    private let locationIconView = UIImageView()
    private let locationLabel = UILabel()
    private let activityIndicator = UIActivityIndicatorView(style: .medium)
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupView() {
        AppTheme.applyCardStyle(to: self)
        backgroundColor = AppTheme.backgroundColor
        
        // Container
        containerView.translatesAutoresizingMaskIntoConstraints = false
        
        // Title
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = "Bölge Deprem Riski"
        titleLabel.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        titleLabel.textColor = AppTheme.titleTextColor
        
        // Risk Label
        riskLabel.translatesAutoresizingMaskIntoConstraints = false
        riskLabel.text = "Hesaplanıyor..."
        riskLabel.font = UIFont.systemFont(ofSize: 20, weight: .bold)
        riskLabel.textColor = AppTheme.bodyTextColor
        
        // Risk Bar
        riskBar.translatesAutoresizingMaskIntoConstraints = false
        riskBar.progressTintColor = AppTheme.primaryColor
        riskBar.trackTintColor = UIColor.systemGray5
        riskBar.progress = 0.5
        riskBar.layer.cornerRadius = 4
        riskBar.clipsToBounds = true
        
        // Location Icon
        locationIconView.translatesAutoresizingMaskIntoConstraints = false
        locationIconView.image = UIImage(systemName: "location.circle.fill")
        locationIconView.contentMode = .scaleAspectFit
        locationIconView.tintColor = AppTheme.primaryColor
        
        // Location Label
        locationLabel.translatesAutoresizingMaskIntoConstraints = false
        locationLabel.text = "Şu anki konumunuz"
        locationLabel.font = UIFont.systemFont(ofSize: 14)
        locationLabel.textColor = AppTheme.bodyTextColor
        
        // Activity Indicator
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        activityIndicator.hidesWhenStopped = true
        activityIndicator.color = AppTheme.primaryColor
        activityIndicator.startAnimating()
        
        // Add to hierarchy
        addSubview(containerView)
        containerView.addSubview(titleLabel)
        containerView.addSubview(riskLabel)
        containerView.addSubview(riskBar)
        containerView.addSubview(locationIconView)
        containerView.addSubview(locationLabel)
        containerView.addSubview(activityIndicator)
        
        // Set constraints
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            containerView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            containerView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            containerView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -16),
            
            titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            
            riskLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 16),
            riskLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            riskLabel.trailingAnchor.constraint(equalTo: activityIndicator.leadingAnchor, constant: -8),
            
            activityIndicator.centerYAnchor.constraint(equalTo: riskLabel.centerYAnchor),
            activityIndicator.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            activityIndicator.widthAnchor.constraint(equalToConstant: 20),
            activityIndicator.heightAnchor.constraint(equalToConstant: 20),
            
            riskBar.topAnchor.constraint(equalTo: riskLabel.bottomAnchor, constant: 16),
            riskBar.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            riskBar.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            riskBar.heightAnchor.constraint(equalToConstant: 8),
            
            locationIconView.topAnchor.constraint(equalTo: riskBar.bottomAnchor, constant: 16),
            locationIconView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            locationIconView.widthAnchor.constraint(equalToConstant: 16),
            locationIconView.heightAnchor.constraint(equalToConstant: 16),
            
            locationLabel.centerYAnchor.constraint(equalTo: locationIconView.centerYAnchor),
            locationLabel.leadingAnchor.constraint(equalTo: locationIconView.trailingAnchor, constant: 8),
            locationLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            locationLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])
    }
    
    func updateRiskLevel(_ riskLevel: RiskLevel) {
        riskLabel.text = riskLevel.rawValue
        
        // Set color and progress based on risk level
        switch riskLevel {
        case .high:
            riskLabel.textColor = AppTheme.errorColor
            riskBar.progressTintColor = AppTheme.errorColor
            riskBar.progress = 0.9
        case .medium:
            riskLabel.textColor = AppTheme.warningColor
            riskBar.progressTintColor = AppTheme.warningColor
            riskBar.progress = 0.6
        case .low:
            riskLabel.textColor = AppTheme.successColor
            riskBar.progressTintColor = AppTheme.successColor
            riskBar.progress = 0.3
        case .unknown:
            riskLabel.textColor = AppTheme.bodyTextColor
            riskBar.progressTintColor = AppTheme.bodyTextColor
            riskBar.progress = 0.1
        }
        
        // Animate progress change
        UIView.animate(withDuration: 0.5) {
            self.layoutIfNeeded()
        }
    }
    
    func setLoading(_ isLoading: Bool) {
        if isLoading {
            activityIndicator.startAnimating()
            riskLabel.text = "Hesaplanıyor..."
            riskLabel.textColor = AppTheme.bodyTextColor
        } else {
            activityIndicator.stopAnimating()
        }
    }
}
