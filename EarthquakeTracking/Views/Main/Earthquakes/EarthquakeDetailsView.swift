import Foundation
import MapKit

class EarthquakeDetailsViewController: UIViewController {
    
    private let earthquake: Earthquake
    private var mapInitialTransform: CGAffineTransform!
    private let mapView = MKMapView()
    private let contentView = UIView()
    private lazy var backgroundGradientLayer: CAGradientLayer = {
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = [
            UIColor(red: 0.0/255.0, green: 20.0/255.0, blue: 40.0/255.0, alpha: 1.0).cgColor,
            UIColor(red: 0.0/255.0, green: 40.0/255.0, blue: 80.0/255.0, alpha: 1.0).cgColor
        ]
        gradientLayer.locations = [0.0, 1.0]
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 0.0)
        gradientLayer.endPoint = CGPoint(x: 0.5, y: 1.0)
        return gradientLayer
    }()
    
    init(earthquake: Earthquake) {
        self.earthquake = earthquake
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupNavigationBarAppearance()
        mapView.alpha = 0
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        backgroundGradientLayer.frame = view.bounds
        
        // Haritanın animasyon için başlangıç transform'unu ayarlıyoruz
        // viewDidLayoutSubviews içinde yapıyoruz çünkü burada haritanın boyutları belli oluyor
        if mapInitialTransform == nil {
            // Haritayı başlangıçta ekranın dışında (solunda) ve küçültülmüş olarak konumlandır
            mapInitialTransform = CGAffineTransform(translationX: -mapView.bounds.width, y: 0)
                .scaledBy(x: 0.8, y: 0.8)
            mapView.transform = mapInitialTransform
        }
    }
    
    private func setupNavigationBarAppearance() {
        if let navigationBar = self.navigationController?.navigationBar {
            // AppTheme'den navigation bar görünümünü al
            let appearance = AppTheme.configureNavigationBarAppearance()
            navigationBar.standardAppearance = appearance
            navigationBar.scrollEdgeAppearance = appearance
            navigationBar.compactAppearance = appearance
            
            navigationBar.tintColor = .white
        }
    }
    
    private func setupUI() {
        title = "Deprem Detayları"
        view.backgroundColor = .clear
        view.layer.insertSublayer(backgroundGradientLayer, at: 0)
        
        mapView.translatesAutoresizingMaskIntoConstraints = false
        mapView.layer.cornerRadius = 16
        mapView.clipsToBounds = true
        view.addSubview(mapView)
        
        // Content view ayarları (mevcut kodlar)
        contentView.translatesAutoresizingMaskIntoConstraints = false
        contentView.backgroundColor = UIColor(red: 0.0/255.0, green: 30.0/255.0, blue: 60.0/255.0, alpha: 1.0)
        contentView.layer.cornerRadius = 24
        contentView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        contentView.layer.shadowColor = UIColor.black.cgColor
        contentView.layer.shadowOffset = CGSize(width: 0, height: -4)
        contentView.layer.shadowRadius = 6
        contentView.layer.shadowOpacity = 0.2
        view.addSubview(contentView)
        
        // Mevcut constraint'ler
        NSLayoutConstraint.activate([
            mapView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            mapView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            mapView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            mapView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.3),
            
            contentView.topAnchor.constraint(equalTo: mapView.bottomAnchor, constant: 16),
            contentView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        setupContentView()
        
        // Harita üzerinde konum gösterme (mevcut kod)
        if let latitude = Double(earthquake.latitude),
           let longitude = Double(earthquake.longitude) {
            let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            let region = MKCoordinateRegion(center: coordinate, span: MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5))
            mapView.setRegion(region, animated: false) // Başlangıçta animasyonsuz ayarla
            
            let annotation = MKPointAnnotation()
            annotation.coordinate = coordinate
            annotation.title = earthquake.location
            mapView.addAnnotation(annotation)
        }
    }
    
    private func setupContentView() {
        
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(scrollView)
        
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.spacing = 20
        stackView.alignment = .fill
        stackView.distribution = .fill
        scrollView.addSubview(stackView)
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 30),
            scrollView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            
            stackView.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 16),
            stackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -20),
            stackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -20),
            stackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -40)
        ])
        
        // Kartları oluştur ama stack view'a hemen ekleme
        let sectionViews = createSectionViews()
        
        // viewDidAppear'da çağrılacak animasyon için sectionViews'ı sakla
        self.sectionViews = sectionViews
        
        // Animasyon için sectionViews'ları stack view'a ekliyoruz
        for view in sectionViews {
            stackView.addArrangedSubview(view)
            // Başlangıçta görünmez ve sağdan dışarıda olacak
            view.alpha = 0
            view.transform = CGAffineTransform(translationX: view.bounds.width, y: -50)
        }
    }
    
    private var sectionViews: [UIView] = []
    
    private func createSectionViews() -> [UIView] {
        var views: [UIView] = []
        
        let locationView = createSectionView(
            sectionTitle: "Konum",
            content: earthquake.location,
            imageName: "mappin.and.ellipse"
        )
        views.append(locationView)
        
        let dateTimeView = createSectionView(
            sectionTitle: "Tarih ve Saat",
            content: "\(earthquake.date) \(earthquake.time)",
            imageName: "calendar"
        )
        views.append(dateTimeView)
        
        let coordinatesView = createSectionView(
            sectionTitle: "Koordinatlar",
            content: "Enlem: \(earthquake.latitude)\nBoylam: \(earthquake.longitude)",
            imageName: "location.circle"
        )
        views.append(coordinatesView)
        
        let magnitudeValue = getMagnitudeValue()
        let magnitudeString = String(format: "ML: %.1f", magnitudeValue)
        
        let magnitudeView = createSectionView(
            sectionTitle: "Büyüklük",
            content: magnitudeString,
            imageName: "waveform.path.ecg",
            detailsColor: getMagnitudeColor(for: magnitudeValue)
        )
        views.append(magnitudeView)
        
        let depthView = createSectionView(
            sectionTitle: "Derinlik",
            content: "\(earthquake.depth_km) km",
            imageName: "arrow.down.circle"
        )
        views.append(depthView)
        
        let infoView = createInformationView()
        views.append(infoView)
        
        return views
    }
    
    private func createSectionView(sectionTitle: String, content: String, imageName: String, detailsColor: UIColor? = nil) -> UIView {
        
        let sectionView = UIView()
        sectionView.translatesAutoresizingMaskIntoConstraints = false
        sectionView.backgroundColor = UIColor.white
        sectionView.layer.cornerRadius = 16
        
        let iconView = UIImageView(image: UIImage(systemName: imageName))
        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.contentMode = .scaleAspectFit
        iconView.tintColor = .darkGray
        
        let titleLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = sectionTitle
        titleLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        titleLabel.textColor = UIColor.darkGray
        
        let contentLabel = UILabel()
        contentLabel.translatesAutoresizingMaskIntoConstraints = false
        contentLabel.text = content
        contentLabel.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        contentLabel.textColor = detailsColor ?? UIColor.darkText
        contentLabel.numberOfLines = 0
        
        sectionView.addSubview(iconView)
        sectionView.addSubview(titleLabel)
        sectionView.addSubview(contentLabel)
        
        NSLayoutConstraint.activate([
            iconView.topAnchor.constraint(equalTo: sectionView.topAnchor, constant: 16),
            iconView.leadingAnchor.constraint(equalTo: sectionView.leadingAnchor, constant: 16),
            iconView.widthAnchor.constraint(equalToConstant: 26),
            iconView.heightAnchor.constraint(equalToConstant: 26),
            
            titleLabel.centerYAnchor.constraint(equalTo: iconView.centerYAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(equalTo: sectionView.trailingAnchor, constant: -16),
            
            contentLabel.topAnchor.constraint(equalTo: iconView.bottomAnchor, constant: 12),
            contentLabel.leadingAnchor.constraint(equalTo: sectionView.leadingAnchor, constant: 16),
            contentLabel.trailingAnchor.constraint(equalTo: sectionView.trailingAnchor, constant: -16),
            contentLabel.bottomAnchor.constraint(equalTo: sectionView.bottomAnchor, constant: -16)
        ])
        
        return sectionView
    }
    
    private func createInformationView() -> UIView {
        let infoView = UIView()
        infoView.translatesAutoresizingMaskIntoConstraints = false
        infoView.backgroundColor = UIColor(red: 255.0/255.0, green: 165.0/255.0, blue: 0.0/255.0, alpha: 0.3) // Turuncu bilgi kartı
        infoView.layer.cornerRadius = 16
        
        let infoIcon = UIImageView(image: UIImage(systemName: "info.circle.fill"))
        infoIcon.translatesAutoresizingMaskIntoConstraints = false
        infoIcon.contentMode = .scaleAspectFit
        infoIcon.tintColor = .white
        
        let infoTitle = UILabel()
        infoTitle.translatesAutoresizingMaskIntoConstraints = false
        infoTitle.text = "Büyüklük Ölçeği Hakkında"
        infoTitle.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        infoTitle.textColor = .white
        
        let infoContent = UILabel()
        infoContent.translatesAutoresizingMaskIntoConstraints = false
        infoContent.text = "Richter ölçeği (ML): Deprem büyüklüğünün logaritmik ölçeğidir. Her 1.0 değerindeki artış, yaklaşık 10 kat daha fazla sarsıntı genliği ve 32 kat daha fazla enerji anlamına gelir.\n\n3.0 altı: Genellikle hissedilmez\n3.0-3.9: Hafif hissedilir\n4.0-4.9: Orta şiddette, eşyalar sallanabilir\n5.0-5.9: Hasar verebilir\n6.0+: Önemli hasar potansiyeli"
        infoContent.font = UIFont.systemFont(ofSize: 14)
        infoContent.textColor = .white.withAlphaComponent(0.9)
        infoContent.numberOfLines = 0
        
        infoView.addSubview(infoIcon)
        infoView.addSubview(infoTitle)
        infoView.addSubview(infoContent)
        
        NSLayoutConstraint.activate([
            infoIcon.topAnchor.constraint(equalTo: infoView.topAnchor, constant: 16),
            infoIcon.leadingAnchor.constraint(equalTo: infoView.leadingAnchor, constant: 16),
            infoIcon.widthAnchor.constraint(equalToConstant: 24),
            infoIcon.heightAnchor.constraint(equalToConstant: 24),
            
            infoTitle.centerYAnchor.constraint(equalTo: infoIcon.centerYAnchor),
            infoTitle.leadingAnchor.constraint(equalTo: infoIcon.trailingAnchor, constant: 12),
            infoTitle.trailingAnchor.constraint(equalTo: infoView.trailingAnchor, constant: -16),
            
            infoContent.topAnchor.constraint(equalTo: infoIcon.bottomAnchor, constant: 12),
            infoContent.leadingAnchor.constraint(equalTo: infoView.leadingAnchor, constant: 16),
            infoContent.trailingAnchor.constraint(equalTo: infoView.trailingAnchor, constant: -16),
            infoContent.bottomAnchor.constraint(equalTo: infoView.bottomAnchor, constant: -16)
        ])
        
        return infoView
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Önce harita animasyonunu başlat, sonra diğer kartları göster
        animateMapView {
            // Harita animasyonu tamamlandıktan sonra diğer kartları göster
            self.animateSectionViews()
        }
    }
    
    private func animateMapView(completion: @escaping () -> Void) {
        // Haritanın bölgesini animasyonlu gösterme
        if let latitude = Double(earthquake.latitude),
           let longitude = Double(earthquake.longitude) {
            let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            let region = MKCoordinateRegion(center: coordinate, span: MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5))
            
            // Önce haritayı görünür yap (ama hala transform uygulanmış durumda)
            UIView.animate(withDuration: 0.3, animations: {
                self.mapView.alpha = 1.0
            }, completion: { _ in
                // Sonra haritayı normal konumuna getir
                UIView.animate(withDuration: 0.7, delay: 0.1, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.5, options: [], animations: {
                    self.mapView.transform = .identity
                }, completion: { _ in
                    // Harita normal konumuna geldikten sonra bölgeyi animasyonlu göster
                    self.mapView.setRegion(region, animated: true)
                    
                    // Bölge animasyonu için biraz zaman ver ve sonra completion'ı çağır
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        completion()
                    }
                })
            })
        } else {
            // Eğer koordinat yoksa direkt haritayı göster ve completion'ı çağır
            UIView.animate(withDuration: 0.7, delay: 0.1, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.5, options: [], animations: {
                self.mapView.alpha = 1.0
                self.mapView.transform = .identity
            }, completion: { _ in
                completion()
            })
        }
    }
    
    private func animateSectionViews() {
        // Her bir görünümü sırayla anime et
        for (index, view) in sectionViews.enumerated() {
            // Animasyon gecikmesini hesapla (her kart için biraz daha uzun)
            let delay = Double(index) * 0.15
            
            UIView.animate(withDuration: 0.5, delay: delay, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.7, options: [], animations: {
                view.alpha = 1.0
                view.transform = .identity
            }, completion: nil)
        }
    }
    
    private func getMagnitudeColor(for magnitude: Double) -> UIColor {
        if magnitude >= 5.0 {
            return UIColor(red: 1.0, green: 0.4, blue: 0.4, alpha: 1.0) // Açık kırmızı
        } else if magnitude >= 4.0 {
            return UIColor(red: 1.0, green: 0.8, blue: 0.0, alpha: 1.0) // Sarı
        } else {
            return UIColor(red: 255.0/255.0, green: 165.0/255.0, blue: 0.0/255.0, alpha: 1.0) // Turuncu - önceden yeşildi
        }
    }
    
    private func addSectionToStackView(stackView: UIStackView, sectionTitle: String, content: String, imageName: String, detailsColor: UIColor? = nil) {
        
        let sectionView = UIView()
        sectionView.translatesAutoresizingMaskIntoConstraints = false
        sectionView.backgroundColor = UIColor.white
        sectionView.layer.cornerRadius = 16
        
        let iconView = UIImageView(image: UIImage(systemName: imageName))
        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.contentMode = .scaleAspectFit
        iconView.tintColor = .darkGray
        
        let titleLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = sectionTitle
        titleLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        titleLabel.textColor = UIColor.darkGray
        
        let contentLabel = UILabel()
        contentLabel.translatesAutoresizingMaskIntoConstraints = false
        contentLabel.text = content
        contentLabel.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        contentLabel.textColor = detailsColor ?? UIColor.darkText
        contentLabel.numberOfLines = 0
        
        sectionView.addSubview(iconView)
        sectionView.addSubview(titleLabel)
        sectionView.addSubview(contentLabel)
        
        NSLayoutConstraint.activate([
            iconView.topAnchor.constraint(equalTo: sectionView.topAnchor, constant: 16),
            iconView.leadingAnchor.constraint(equalTo: sectionView.leadingAnchor, constant: 16),
            iconView.widthAnchor.constraint(equalToConstant: 26),
            iconView.heightAnchor.constraint(equalToConstant: 26),
            
            titleLabel.centerYAnchor.constraint(equalTo: iconView.centerYAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(equalTo: sectionView.trailingAnchor, constant: -16),
            
            contentLabel.topAnchor.constraint(equalTo: iconView.bottomAnchor, constant: 12),
            contentLabel.leadingAnchor.constraint(equalTo: sectionView.leadingAnchor, constant: 16),
            contentLabel.trailingAnchor.constraint(equalTo: sectionView.trailingAnchor, constant: -16),
            contentLabel.bottomAnchor.constraint(equalTo: sectionView.bottomAnchor, constant: -16)
        ])
        
        stackView.addArrangedSubview(sectionView)
    }
    
    private func addInformationSection(stackView: UIStackView) {
        
        let infoView = UIView()
        infoView.translatesAutoresizingMaskIntoConstraints = false
        infoView.backgroundColor = UIColor(red: 255.0/255.0, green: 165.0/255.0, blue: 0.0/255.0, alpha: 0.3) // Turuncu bilgi kartı
        infoView.layer.cornerRadius = 16
        
        let infoIcon = UIImageView(image: UIImage(systemName: "info.circle.fill"))
        infoIcon.translatesAutoresizingMaskIntoConstraints = false
        infoIcon.contentMode = .scaleAspectFit
        infoIcon.tintColor = .white
        
        let infoTitle = UILabel()
        infoTitle.translatesAutoresizingMaskIntoConstraints = false
        infoTitle.text = "Büyüklük Ölçeği Hakkında"
        infoTitle.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        infoTitle.textColor = .white
        
        let infoContent = UILabel()
        infoContent.translatesAutoresizingMaskIntoConstraints = false
        infoContent.text = "Richter ölçeği (ML): Deprem büyüklüğünün logaritmik ölçeğidir. Her 1.0 değerindeki artış, yaklaşık 10 kat daha fazla sarsıntı genliği ve 32 kat daha fazla enerji anlamına gelir.\n\n3.0 altı: Genellikle hissedilmez\n3.0-3.9: Hafif hissedilir\n4.0-4.9: Orta şiddette, eşyalar sallanabilir\n5.0-5.9: Hasar verebilir\n6.0+: Önemli hasar potansiyeli"
        infoContent.font = UIFont.systemFont(ofSize: 14)
        infoContent.textColor = .white.withAlphaComponent(0.9)
        infoContent.numberOfLines = 0
        
        infoView.addSubview(infoIcon)
        infoView.addSubview(infoTitle)
        infoView.addSubview(infoContent)
        
        NSLayoutConstraint.activate([
            infoIcon.topAnchor.constraint(equalTo: infoView.topAnchor, constant: 16),
            infoIcon.leadingAnchor.constraint(equalTo: infoView.leadingAnchor, constant: 16),
            infoIcon.widthAnchor.constraint(equalToConstant: 24),
            infoIcon.heightAnchor.constraint(equalToConstant: 24),
            
            infoTitle.centerYAnchor.constraint(equalTo: infoIcon.centerYAnchor),
            infoTitle.leadingAnchor.constraint(equalTo: infoIcon.trailingAnchor, constant: 12),
            infoTitle.trailingAnchor.constraint(equalTo: infoView.trailingAnchor, constant: -16),
            
            infoContent.topAnchor.constraint(equalTo: infoIcon.bottomAnchor, constant: 12),
            infoContent.leadingAnchor.constraint(equalTo: infoView.leadingAnchor, constant: 16),
            infoContent.trailingAnchor.constraint(equalTo: infoView.trailingAnchor, constant: -16),
            infoContent.bottomAnchor.constraint(equalTo: infoView.bottomAnchor, constant: -16)
        ])
        
        let spacer = UIView()
        spacer.translatesAutoresizingMaskIntoConstraints = false
        spacer.heightAnchor.constraint(equalToConstant: 16).isActive = true
        
        stackView.addArrangedSubview(spacer)
        stackView.addArrangedSubview(infoView)
    }
    
    private func getMagnitudeValue() -> Double {
        if let ml = Double(earthquake.ml), ml > 0 {
            return ml
        } else if let mw = Double(earthquake.mw), mw > 0 {
            return mw
        } else if let md = Double(earthquake.md), md > 0 {
            return md
        }
        return 0.0
    }
}
