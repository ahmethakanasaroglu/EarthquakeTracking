import UIKit
import CoreLocation
import MapKit

class PersonalizedViewController: UIViewController {
    
    // MARK: - Properties
    private let viewModel = PersonalizedViewModel()
    private let locationManager = CLLocationManager()
    
    // Kart geçişleri için özellikler
    private var currentCardIndex = 0
    private var cards: [UIView] = []
    
    // MARK: - UI Elements
    private lazy var backgroundGradientLayer: CAGradientLayer = {
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = [
            UIColor(red: 100.0/255.0, green: 40.0/255.0, blue: 160.0/255.0, alpha: 1.0).cgColor, // Daha açık İndigo rengi üst
            UIColor(red: 70.0/255.0, green: 20.0/255.0, blue: 120.0/255.0, alpha: 1.0).cgColor   // Daha açık İndigo rengi alt
        ]
        gradientLayer.locations = [0.0, 1.0]
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 0.0)
        gradientLayer.endPoint = CGPoint(x: 0.5, y: 1.0)
        return gradientLayer
    }()
    
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
        view.backgroundColor = UIColor.white.withAlphaComponent(0.15)
        view.layer.cornerRadius = 16
        
        view.layer.shadowColor = UIColor.black.cgColor
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
    
    private lazy var cardScrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.isPagingEnabled = true
        scrollView.delegate = self
        scrollView.clipsToBounds = false
        return scrollView
    }()
    
    private lazy var cardContainer: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .clear
        view.clipsToBounds = false
        return view
    }()
    
    private lazy var pageControl: UIPageControl = {
        let pageControl = UIPageControl()
        pageControl.translatesAutoresizingMaskIntoConstraints = false
        pageControl.numberOfPages = 4
        pageControl.currentPage = 0
        pageControl.pageIndicatorTintColor = UIColor.white.withAlphaComponent(0.3)
        pageControl.currentPageIndicatorTintColor = .white
        pageControl.addTarget(self, action: #selector(pageControlTapped(_:)), for: .valueChanged)
        return pageControl
    }()
    
    private lazy var riskIndicatorView: RiskIndicatorView = {
        let view = RiskIndicatorView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupBackground()
        setupUI()
        setupLocationManager()
        setupBindings()
        setupNavigationBarAppearance()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        backgroundGradientLayer.frame = view.bounds
        
        // cardScrollView içeriğini ayarla
        let featuresCount = 4
        cardScrollView.contentSize = CGSize(
            width: cardScrollView.frame.width * CGFloat(featuresCount),
            height: cardScrollView.frame.height
        )
        
        // Kartları yerleştir
        positionCards()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewModel.loadRiskDataForCurrentLocation()
        
        // TabBar'ı indigo renge ayarla
        setupTabBarAppearance()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // TabBar'ı eski haline döndür
    }
    
    // MARK: - Setup
    private func setupBackground() {
        view.layer.insertSublayer(backgroundGradientLayer, at: 0)
    }
    
    private func setupNavigationBarAppearance() {
        if let navigationBar = self.navigationController?.navigationBar {
            let appearance = UINavigationBarAppearance()
            appearance.configureWithOpaqueBackground()
            
            // Daha açık turuncu navigasyon rengi
            appearance.backgroundColor = UIColor(red: 255.0/255.0, green: 165.0/255.0, blue: 0.0/255.0, alpha: 1.0)
            
            // Navigation bar öğeleri
            appearance.titleTextAttributes = [
                NSAttributedString.Key.foregroundColor: UIColor.white,
                NSAttributedString.Key.font: UIFont.systemFont(ofSize: 18, weight: .bold)
            ]
            
            navigationBar.standardAppearance = appearance
            navigationBar.scrollEdgeAppearance = appearance
            navigationBar.compactAppearance = appearance
            
            navigationBar.tintColor = .white
        }
    }
    
    private func setupUI() {
        title = "Kişiselleştirilmiş"
        view.backgroundColor = .clear
        
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        contentView.addSubview(headerView)
        headerView.addSubview(headerIconView)
        headerView.addSubview(headerLabel)
        headerView.addSubview(headerDescriptionLabel)
        
        contentView.addSubview(riskIndicatorView)
        contentView.addSubview(cardScrollView)
        contentView.addSubview(pageControl)
        
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
            
            riskIndicatorView.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 24),
            riskIndicatorView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            riskIndicatorView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            cardScrollView.topAnchor.constraint(equalTo: riskIndicatorView.bottomAnchor, constant: 24),
            cardScrollView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            cardScrollView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            cardScrollView.heightAnchor.constraint(equalToConstant: 350),
            
            pageControl.topAnchor.constraint(equalTo: cardScrollView.bottomAnchor, constant: 16),
            pageControl.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            pageControl.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -24)
        ])
        
        setupCards()
    }
    
    private func setupTabBarAppearance() {
        if let tabBar = self.tabBarController?.tabBar {
            // Tab bar'ı indigo yap
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            
            // Daha açık İndigo rengi
            appearance.backgroundColor = UIColor(red: 100.0/255.0, green: 40.0/255.0, blue: 160.0/255.0, alpha: 1.0)
            
            // Tab bar öğeleri
            let itemAppearance = UITabBarItemAppearance()
            
            // Normal durum renkleri
            itemAppearance.normal.iconColor = .white.withAlphaComponent(0.6)
            itemAppearance.normal.titleTextAttributes = [
                NSAttributedString.Key.foregroundColor: UIColor.white.withAlphaComponent(0.6)
            ]
            
            // Seçili durum renkleri
            itemAppearance.selected.iconColor = .white
            itemAppearance.selected.titleTextAttributes = [
                NSAttributedString.Key.foregroundColor: UIColor.white
            ]
            
            appearance.stackedLayoutAppearance = itemAppearance
            appearance.inlineLayoutAppearance = itemAppearance
            appearance.compactInlineLayoutAppearance = itemAppearance
            
            tabBar.standardAppearance = appearance
            
            if #available(iOS 15.0, *) {
                tabBar.scrollEdgeAppearance = appearance
            }
        }
    }
    
    private func resetTabBarAppearance() {
        if let tabBar = self.tabBarController?.tabBar {
            // Varsayılan tab bar görünümünü geri yükle
            tabBar.standardAppearance = UITabBarAppearance()
            
            if #available(iOS 15.0, *) {
                tabBar.scrollEdgeAppearance = tabBar.standardAppearance
            }
        }
    }
    
    private func setupCards() {
        // Kart özellikleri
        let features = [
            (title: "Kişiselleştirilmiş Uyarı Sistemi", description: "Önem verdiğiniz bölgeler için deprem uyarılarını özelleştirin.", icon: "bell.fill", color: "#3498db", action: #selector(openNotificationSettings)),
            (title: "Deprem Simülasyonu", description: "Farklı büyüklüklerdeki depremlerin etkilerini deneyimleyin.", icon: "waveform.path.ecg", color: "#9b59b6", action: #selector(openSimulation)),
            (title: "Deprem Analizi", description: "Depremlerin büyüklüğünü, sayısını, yoğunluğunu analiz edin", icon: "chart.line.uptrend.xyaxis", color: "#e74c3c", action: #selector(openStats)),
            (title: "Deprem Riski Tahmin Modeli", description: "Yapay zeka ile bölgenizdeki deprem riskini görüntüleyin.", icon: "map.fill", color: "#2ecc71", action: #selector(openRiskModel))
        ]
        
        // Kartları oluştur
        cards = []
        
        for (index, feature) in features.enumerated() {
            let card = createCardView(
                title: feature.title,
                description: feature.description,
                iconName: feature.icon,
                color: feature.color,
                action: feature.action
            )
            
            cardScrollView.addSubview(card)
            cards.append(card)
        }
    }
    
    private func positionCards() {
        let pageWidth = cardScrollView.frame.width
        let cardWidth = pageWidth - 60 // Her iki taraftan 30px boşluk
        
        for (index, card) in cards.enumerated() {
            // Kart boyutu ve pozisyonu
            let xPosition = (pageWidth * CGFloat(index)) + ((pageWidth - cardWidth) / 2)
            
            card.frame = CGRect(
                x: xPosition,
                y: 10,
                width: cardWidth,
                height: cardScrollView.frame.height - 20
            )
            
            // Köşe yuvarlama ve gölge ekle
            card.layer.cornerRadius = 20
            card.layer.shadowColor = UIColor.black.cgColor
            card.layer.shadowOpacity = 0.2
            card.layer.shadowOffset = CGSize(width: 0, height: 5)
            card.layer.shadowRadius = 10
        }
    }
    
    private func createCardView(title: String, description: String, iconName: String, color: String, action: Selector) -> UIView {
        let cardView = UIView()
        cardView.backgroundColor = .white
        
        // Dokunma algılayıcısı ekle
        let tapGesture = UITapGestureRecognizer(target: self, action: action)
        cardView.addGestureRecognizer(tapGesture)
        cardView.isUserInteractionEnabled = true
        
        // Renk çubuğu
        let colorView = UIView()
        colorView.translatesAutoresizingMaskIntoConstraints = false
        colorView.backgroundColor = hexToUIColor(hex: color)
        colorView.layer.cornerRadius = 20
        colorView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        
        // İkon arka planı
        let iconContainer = UIView()
        iconContainer.translatesAutoresizingMaskIntoConstraints = false
        iconContainer.backgroundColor = hexToUIColor(hex: color)
        iconContainer.layer.cornerRadius = 30
        
        // İkon
        let iconImageView = UIImageView(image: UIImage(systemName: iconName))
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.tintColor = .white
        
        // Başlık
        let titleLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = title
        titleLabel.font = UIFont.systemFont(ofSize: 22, weight: .bold)
        titleLabel.textColor = UIColor.darkGray
        titleLabel.numberOfLines = 2
        
        // Açıklama
        let descriptionLabel = UILabel()
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        descriptionLabel.text = description
        descriptionLabel.font = UIFont.systemFont(ofSize: 16)
        descriptionLabel.textColor = UIColor.gray
        descriptionLabel.numberOfLines = 0
        
        // İleri oku
        let arrowImageView = UIImageView(image: UIImage(systemName: "arrow.right.circle.fill"))
        arrowImageView.translatesAutoresizingMaskIntoConstraints = false
        arrowImageView.contentMode = .scaleAspectFit
        arrowImageView.tintColor = hexToUIColor(hex: color)
        
        // Hiyerarşi oluştur
        iconContainer.addSubview(iconImageView)
        cardView.addSubview(colorView)
        cardView.addSubview(iconContainer)
        cardView.addSubview(titleLabel)
        cardView.addSubview(descriptionLabel)
        cardView.addSubview(arrowImageView)
        
        // Constraint'leri ayarla
        NSLayoutConstraint.activate([
            colorView.topAnchor.constraint(equalTo: cardView.topAnchor),
            colorView.leadingAnchor.constraint(equalTo: cardView.leadingAnchor),
            colorView.trailingAnchor.constraint(equalTo: cardView.trailingAnchor),
            colorView.heightAnchor.constraint(equalToConstant: 100),
            
            iconContainer.centerYAnchor.constraint(equalTo: colorView.bottomAnchor),
            iconContainer.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 20),
            iconContainer.widthAnchor.constraint(equalToConstant: 60),
            iconContainer.heightAnchor.constraint(equalToConstant: 60),
            
            iconImageView.centerXAnchor.constraint(equalTo: iconContainer.centerXAnchor),
            iconImageView.centerYAnchor.constraint(equalTo: iconContainer.centerYAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 30),
            iconImageView.heightAnchor.constraint(equalToConstant: 30),
            
            titleLabel.topAnchor.constraint(equalTo: iconContainer.bottomAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -20),
            
            descriptionLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 12),
            descriptionLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 20),
            descriptionLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -20),
            
            arrowImageView.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -20),
            arrowImageView.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -20),
            arrowImageView.widthAnchor.constraint(equalToConstant: 30),
            arrowImageView.heightAnchor.constraint(equalToConstant: 30)
        ])
        
        return cardView
    }
    
    // Hex kodunu UIColor'a dönüştürme yardımcı fonksiyonu
    private func hexToUIColor(hex: String) -> UIColor {
        var cString: String = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        
        if cString.hasPrefix("#") {
            cString.remove(at: cString.startIndex)
        }
        
        if cString.count != 6 {
            return .gray
        }
        
        var rgbValue: UInt64 = 0
        Scanner(string: cString).scanHexInt64(&rgbValue)
        
        return UIColor(
            red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
            alpha: 1.0
        )
    }
    
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }
    
    private func setupBindings() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleRiskLevelUpdated(_:)),
            name: PersonalizedViewModel.riskDataChangedNotification,
            object: nil
        )
    }
    
    // MARK: - Card Animation & Scroll
    @objc private func pageControlTapped(_ sender: UIPageControl) {
        scrollToCard(at: sender.currentPage, animated: true)
    }
    
    private func scrollToCard(at index: Int, animated: Bool) {
        let pageWidth = cardScrollView.frame.width
        let contentOffsetX = CGFloat(index) * pageWidth
        
        cardScrollView.setContentOffset(CGPoint(x: contentOffsetX, y: 0), animated: animated)
    }
    
    // MARK: - Actions
    @objc private func handleRiskLevelUpdated(_ notification: Notification) {
        if let riskLevel = notification.userInfo?["level"] as? RiskLevel,
           let isLoading = notification.userInfo?["isLoading"] as? Bool {
            DispatchQueue.main.async { [weak self] in
                self?.riskIndicatorView.updateRiskLevel(riskLevel)
                self?.riskIndicatorView.setLoading(isLoading)
            }
        }
    }
    
    @objc private func openNotificationSettings() {
        let notificationVC = NotificationSettingsViewController(viewModel: viewModel)
        navigationController?.pushViewController(notificationVC, animated: true)
    }
    
    @objc private func openSimulation() {
        let simulationVC = EarthquakeSimulationViewController(viewModel: viewModel)
        navigationController?.pushViewController(simulationVC, animated: true)
    }
    
    @objc private func openStats() {
        let statSimulationVC = StatisticsViewController(viewModel: viewModel)
        navigationController?.pushViewController(statSimulationVC, animated: true)
    }
    
    @objc private func openRiskModel() {
        let riskModelVC = RiskModelViewController(viewModel: viewModel)
        navigationController?.pushViewController(riskModelVC, animated: true)
    }
}

// MARK: - UIScrollViewDelegate
extension PersonalizedViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let pageWidth = scrollView.frame.size.width
        let currentPage = Int((scrollView.contentOffset.x + pageWidth / 2) / pageWidth)
        
        if pageControl.currentPage != currentPage && currentPage >= 0 && currentPage < cards.count {
            pageControl.currentPage = currentPage
            currentCardIndex = currentPage
        }
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        // Kaydırma bittiğinde aktif kartı güncelle
        let pageWidth = scrollView.frame.size.width
        let currentPage = Int(scrollView.contentOffset.x / pageWidth)
        
        if currentPage >= 0 && currentPage < cards.count {
            currentCardIndex = currentPage
            pageControl.currentPage = currentPage
        }
    }
}

// MARK: - CLLocationManagerDelegate
extension PersonalizedViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        viewModel.locationManager(manager, didUpdateLocations: locations)
        
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
        backgroundColor = UIColor.white.withAlphaComponent(0.15)
        layer.cornerRadius = 20
        
        containerView.translatesAutoresizingMaskIntoConstraints = false
        
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = "Bölge Deprem Riski"
        titleLabel.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        titleLabel.textColor = .white
        
        riskLabel.translatesAutoresizingMaskIntoConstraints = false
        riskLabel.text = "Hesaplanıyor..."
        riskLabel.font = UIFont.systemFont(ofSize: 20, weight: .bold)
        riskLabel.textColor = .white
        
        riskBar.translatesAutoresizingMaskIntoConstraints = false
        riskBar.progressTintColor = .white
        riskBar.trackTintColor = UIColor.white.withAlphaComponent(0.3)
        riskBar.progress = 0.5
        riskBar.layer.cornerRadius = 4
        riskBar.clipsToBounds = true
        
        locationIconView.translatesAutoresizingMaskIntoConstraints = false
        locationIconView.image = UIImage(systemName: "location.circle.fill")
        locationIconView.contentMode = .scaleAspectFit
        locationIconView.tintColor = .white
        
        locationLabel.translatesAutoresizingMaskIntoConstraints = false
        locationLabel.text = "Şu anki konumunuz"
        locationLabel.font = UIFont.systemFont(ofSize: 14)
        locationLabel.textColor = .white.withAlphaComponent(0.8)
        
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        activityIndicator.hidesWhenStopped = true
        activityIndicator.color = .white
        activityIndicator.startAnimating()
        
        addSubview(containerView)
        containerView.addSubview(titleLabel)
        containerView.addSubview(riskLabel)
        containerView.addSubview(riskBar)
        containerView.addSubview(locationIconView)
        containerView.addSubview(locationLabel)
        containerView.addSubview(activityIndicator)
        
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
        
        switch riskLevel {
        case .high:
            riskLabel.textColor = UIColor(red: 1.0, green: 0.4, blue: 0.4, alpha: 1.0) // Açık kırmızı
            riskBar.progressTintColor = UIColor(red: 1.0, green: 0.4, blue: 0.4, alpha: 1.0)
            riskBar.progress = 0.9
        case .medium:
            riskLabel.textColor = UIColor(red: 1.0, green: 0.8, blue: 0.0, alpha: 1.0) // Sarı
            riskBar.progressTintColor = UIColor(red: 1.0, green: 0.8, blue: 0.0, alpha: 1.0)
            riskBar.progress = 0.6
        case .low:
            riskLabel.textColor = UIColor(red: 0.3, green: 0.8, blue: 0.3, alpha: 1.0) // Açık yeşil
            riskBar.progressTintColor = UIColor(red: 0.3, green: 0.8, blue: 0.3, alpha: 1.0)
            riskBar.progress = 0.3
        case .unknown:
            riskLabel.textColor = .white
            riskBar.progressTintColor = .white
            riskBar.progress = 0.1
        }
        
        UIView.animate(withDuration: 0.5) {
            self.layoutIfNeeded()
        }
    }
    
    func setLoading(_ isLoading: Bool) {
        if isLoading {
            activityIndicator.startAnimating()
            riskLabel.text = "Hesaplanıyor..."
            riskLabel.textColor = .white
        } else {
            activityIndicator.stopAnimating()
        }
    }
}
