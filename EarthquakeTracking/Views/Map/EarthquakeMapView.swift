import UIKit
import MapKit

class EarthquakeMapViewController: UIViewController {
    
    private let viewModel = EarthquakeMapViewModel()
    
    private var tapGestureRecognizer: UITapGestureRecognizer!
    
    private lazy var mapView: MKMapView = {
        let map = MKMapView()
        map.translatesAutoresizingMaskIntoConstraints = false
        map.delegate = self
        map.showsUserLocation = true
        map.showsCompass = true
        map.showsScale = true
        return map
    }()
    
    private lazy var activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.hidesWhenStopped = true
        indicator.color = AppTheme.indigoColor
        return indicator
    }()
    
    private lazy var popupView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = AppTheme.backgroundColor
        view.layer.cornerRadius = 16
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = 0.2
        view.layer.shadowOffset = CGSize(width: 0, height: 2)
        view.layer.shadowRadius = 8
        view.isHidden = true
        return view
    }()
    
    private lazy var closeButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        button.tintColor = AppTheme.bodyTextColor
        button.addTarget(self, action: #selector(closePopup), for: .touchUpInside)
        return button
    }()
    
    private lazy var magnitudeCircleView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = AppTheme.indigoColor
        view.layer.cornerRadius = 25
        view.layer.shadowColor = AppTheme.indigoColor.cgColor
        view.layer.shadowOffset = CGSize(width: 0, height: 2)
        view.layer.shadowRadius = 4
        view.layer.shadowOpacity = 0.3
        return view
    }()
    
    private lazy var magnitudeLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        label.textColor = .white
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var locationLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        label.textColor = AppTheme.titleTextColor
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var dateTimeLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = AppTheme.bodyTextColor
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var depthInfoView: InfoRowView = {
        let view = InfoRowView(iconName: "arrow.down", title: "Derinlik")
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private lazy var coordinatesInfoView: InfoRowView = {
        let view = InfoRowView(iconName: "location", title: "Koordinatlar")
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private lazy var detailsButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Detaylar", for: .normal)
        button.setImage(UIImage(systemName: "info.circle"), for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        AppTheme.applyButtonStyle(to: button, style: .secondary)
        button.addTarget(self, action: #selector(showDetails), for: .touchUpInside)
        return button
    }()
    
    private lazy var mapTypeButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(UIImage(systemName: "map"), for: .normal)
        button.tintColor = AppTheme.indigoColor
        button.backgroundColor = AppTheme.backgroundColor.withAlphaComponent(0.9)
        button.layer.cornerRadius = 20
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOpacity = 0.2
        button.layer.shadowOffset = CGSize(width: 0, height: 2)
        button.layer.shadowRadius = 4
        button.addTarget(self, action: #selector(changeMapType), for: .touchUpInside)
        return button
    }()
    
    private lazy var legendView: EarthquakeMagnitudeLegendView = {
        let view = EarthquakeMagnitudeLegendView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.layer.cornerRadius = 8
        view.clipsToBounds = true
        view.alpha = 0.9
        return view
    }()
    
    private lazy var filterButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(UIImage(systemName: "line.horizontal.3.decrease.circle.fill"), for: .normal)
        button.tintColor = AppTheme.indigoColor
        button.backgroundColor = AppTheme.backgroundColor.withAlphaComponent(0.9)
        button.layer.cornerRadius = 20
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOpacity = 0.2
        button.layer.shadowOffset = CGSize(width: 0, height: 2)
        button.layer.shadowRadius = 4
        button.addTarget(self, action: #selector(showFilterOptions), for: .touchUpInside)
        return button
    }()
    
    private var popupBottomConstraint: NSLayoutConstraint?
    private var popupCenterXConstraint: NSLayoutConstraint?
    private var selectedAnnotationView: MKAnnotationView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupBindings()
        setupGestureRecognizers()
        fetchEarthquakes()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    func focusOnLocation(_ coordinate: CLLocationCoordinate2D, earthquake: Earthquake) {
        if viewModel.earthquakes.isEmpty {
            viewModel.fetchEarthquakes()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
                self?.performFocusOnEarthquake(coordinate, earthquake: earthquake)
            }
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                self?.performFocusOnEarthquake(coordinate, earthquake: earthquake)
            }
        }
    }
    
    private func performFocusOnEarthquake(_ coordinate: CLLocationCoordinate2D, earthquake: Earthquake) {
        // Haritayı deprem konumuna odakla
        let region = MKCoordinateRegion(center: coordinate, span: MKCoordinateSpan(latitudeDelta: 0.2, longitudeDelta: 0.2))
        mapView.setRegion(region, animated: true)
        
        var targetAnnotation: EarthquakeAnnotation? = nil
        
        // Deprem için mevcut annotation'ı bul
        for annotation in mapView.annotations {
            if let earthquakeAnnotation = annotation as? EarthquakeAnnotation {
                if abs(earthquakeAnnotation.coordinate.latitude - coordinate.latitude) < 0.00001 &&
                    abs(earthquakeAnnotation.coordinate.longitude - coordinate.longitude) < 0.00001 {
                    targetAnnotation = earthquakeAnnotation
                    break
                }
            }
        }
        
        // Eğer annotation yoksa, yeni bir tane oluştur
        if targetAnnotation == nil {
            targetAnnotation = EarthquakeAnnotation(coordinate: coordinate, earthquake: earthquake)
            mapView.addAnnotation(targetAnnotation!)
        }
        
        if let annotation = targetAnnotation {
            resetAllAnnotations()
            
            NotificationCenter.default.post(
                name: Notification.Name("clearSelectedEarthquakeNotification"),
                object: self
            )
            annotation.isSelected = true
            
            // Deprem modeldeki seçili deprem olarak kaydedilmeli
            viewModel.selectEarthquake(annotation)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
                guard let self = self else { return }
                
                if let annotationView = self.mapView.view(for: annotation) {
                    self.highlightSelectedAnnotation(annotationView)
                    self.selectedAnnotationView = annotationView
                    
                    // Popup'ı hemen göster - bu satır çok önemli!
                    if let earthquake = self.viewModel.selectedEarthquake {
                        self.updatePopupView(with: earthquake)
                        
                        // Popup'ın konumunu annotation'a göre ayarla
                        if let selectedView = self.selectedAnnotationView {
                            self.positionPopupRelativeToAnnotation(selectedView)
                        }
                    }
                }
            }
        }
    }
    
    private func resetAllAnnotations() {
        for annotation in mapView.annotations {
            if let view = mapView.view(for: annotation) as? MKMarkerAnnotationView,
               let earthquakeAnnotation = annotation as? EarthquakeAnnotation {
                
                view.transform = CGAffineTransform.identity
                view.markerTintColor = viewModel.getColor(for: earthquakeAnnotation.earthquake)
                view.layer.zPosition = 0
                
                view.layer.shadowOpacity = 0
                
                let magnitude = viewModel.getMagnitude(for: earthquakeAnnotation.earthquake)
                if magnitude >= 5.0 {
                    view.glyphImage = UIImage(systemName: "exclamationmark.triangle.fill")
                } else if magnitude >= 4.0 {
                    view.glyphImage = UIImage(systemName: "exclamationmark")
                } else {
                    view.glyphImage = UIImage(systemName: "waveform.path.ecg")
                }
                view.glyphTintColor = .white
            }
        }
    }
    
    private func highlightAnnotationView(_ view: MKAnnotationView) {
        UIView.animate(withDuration: 0.3) {
            view.transform = CGAffineTransform(scaleX: 1.5, y: 1.5)
        }
        
        let pulseAnimation = CABasicAnimation(keyPath: "transform.scale")
        pulseAnimation.duration = 0.5
        pulseAnimation.fromValue = 1.0
        pulseAnimation.toValue = 1.1
        pulseAnimation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        pulseAnimation.autoreverses = true
        pulseAnimation.repeatCount = 2
        view.layer.add(pulseAnimation, forKey: "pulse")
        
        view.layer.zPosition = 100
        
        if let markerView = view as? MKMarkerAnnotationView {
            markerView.glyphTintColor = .white
            markerView.layer.shadowColor = UIColor.white.cgColor
            markerView.layer.shadowOpacity = 0.8
            markerView.layer.shadowRadius = 5
            markerView.layer.shadowOffset = CGSize.zero
        }
    }
    
    private func highlightSelectedAnnotation(_ view: MKAnnotationView) {
        UIView.animate(withDuration: 0.3) {
            view.transform = CGAffineTransform(scaleX: 2.0, y: 2.0)
        }
        
        let pulseAnimation = CABasicAnimation(keyPath: "transform.scale")
        pulseAnimation.duration = 0.8
        pulseAnimation.fromValue = 1.8
        pulseAnimation.toValue = 2.2
        pulseAnimation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        pulseAnimation.autoreverses = true
        pulseAnimation.repeatCount = 3
        view.layer.add(pulseAnimation, forKey: "pulse")
        
        view.layer.zPosition = 1000
        
        if let markerView = view as? MKMarkerAnnotationView {
            markerView.glyphImage = UIImage(systemName: "target")
            markerView.glyphTintColor = .white
            
            markerView.markerTintColor = UIColor.systemRed
            
            markerView.layer.shadowColor = UIColor.white.cgColor
            markerView.layer.shadowOpacity = 1.0
            markerView.layer.shadowRadius = 8
            markerView.layer.shadowOffset = CGSize.zero
        }
    }
    
    private func setupGestureRecognizers() {
        tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleMapTap(_:)))
        tapGestureRecognizer.delegate = self
        mapView.addGestureRecognizer(tapGestureRecognizer)
    }
    
    @objc private func handleMapTap(_ gestureRecognizer: UITapGestureRecognizer) {
        let touchPoint = gestureRecognizer.location(in: mapView)
        let touchCoordinate = mapView.convert(touchPoint, toCoordinateFrom: mapView)
        
        let touchedAnnotations = mapView.annotations.filter { annotation in
            guard let annotationView = mapView.view(for: annotation) else { return false }
            let annotationPoint = mapView.convert(annotation.coordinate, toPointTo: mapView)
            let distance = sqrt(pow(touchPoint.x - annotationPoint.x, 2) + pow(touchPoint.y - annotationPoint.y, 2))
            return distance < 30
        }
        
        if touchedAnnotations.isEmpty && !popupView.isHidden {
            closePopup()
        }
    }
    
    private func setupUI() {
        title = "Deprem Haritası"
        view.backgroundColor = AppTheme.backgroundColor
        
        view.addSubview(mapView)
        view.addSubview(activityIndicator)
        view.addSubview(popupView)
        view.addSubview(mapTypeButton)
        view.addSubview(legendView)
        view.addSubview(filterButton)
        
        popupView.addSubview(closeButton)
        popupView.addSubview(magnitudeCircleView)
        magnitudeCircleView.addSubview(magnitudeLabel)
        popupView.addSubview(locationLabel)
        popupView.addSubview(dateTimeLabel)
        popupView.addSubview(depthInfoView)
        popupView.addSubview(coordinatesInfoView)
        popupView.addSubview(detailsButton)
        
        NSLayoutConstraint.activate([
            mapView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            mapView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            mapView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            mapView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            
            mapTypeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            mapTypeButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            mapTypeButton.widthAnchor.constraint(equalToConstant: 40),
            mapTypeButton.heightAnchor.constraint(equalToConstant: 40),
            
            legendView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            legendView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            legendView.widthAnchor.constraint(equalToConstant: 160),
            
            filterButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            filterButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            filterButton.widthAnchor.constraint(equalToConstant: 40),
            filterButton.heightAnchor.constraint(equalToConstant: 40),
        ])
        
        popupView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(popupView)
        
        popupBottomConstraint = popupView.bottomAnchor.constraint(equalTo: legendView.topAnchor, constant: -16)
        popupCenterXConstraint = popupView.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        
        NSLayoutConstraint.activate([
            popupView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            popupView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            popupBottomConstraint!,
            
            closeButton.topAnchor.constraint(equalTo: popupView.topAnchor, constant: 12),
            closeButton.trailingAnchor.constraint(equalTo: popupView.trailingAnchor, constant: -12),
            closeButton.widthAnchor.constraint(equalToConstant: 24),
            closeButton.heightAnchor.constraint(equalToConstant: 24),
            
            magnitudeCircleView.leadingAnchor.constraint(equalTo: popupView.leadingAnchor, constant: 16),
            magnitudeCircleView.topAnchor.constraint(equalTo: popupView.topAnchor, constant: 16),
            magnitudeCircleView.widthAnchor.constraint(equalToConstant: 50),
            magnitudeCircleView.heightAnchor.constraint(equalToConstant: 50),
            
            magnitudeLabel.centerXAnchor.constraint(equalTo: magnitudeCircleView.centerXAnchor),
            magnitudeLabel.centerYAnchor.constraint(equalTo: magnitudeCircleView.centerYAnchor),
            
            locationLabel.topAnchor.constraint(equalTo: popupView.topAnchor, constant: 16),
            locationLabel.leadingAnchor.constraint(equalTo: magnitudeCircleView.trailingAnchor, constant: 16),
            locationLabel.trailingAnchor.constraint(equalTo: closeButton.leadingAnchor, constant: -8),
            
            dateTimeLabel.topAnchor.constraint(equalTo: locationLabel.bottomAnchor, constant: 8),
            dateTimeLabel.leadingAnchor.constraint(equalTo: magnitudeCircleView.trailingAnchor, constant: 16),
            dateTimeLabel.trailingAnchor.constraint(equalTo: closeButton.leadingAnchor, constant: -8),
            
            depthInfoView.topAnchor.constraint(equalTo: dateTimeLabel.bottomAnchor, constant: 16),
            depthInfoView.leadingAnchor.constraint(equalTo: popupView.leadingAnchor, constant: 16),
            depthInfoView.trailingAnchor.constraint(equalTo: popupView.centerXAnchor, constant: -8),
            
            coordinatesInfoView.topAnchor.constraint(equalTo: dateTimeLabel.bottomAnchor, constant: 16),
            coordinatesInfoView.leadingAnchor.constraint(equalTo: popupView.centerXAnchor, constant: 8),
            coordinatesInfoView.trailingAnchor.constraint(equalTo: popupView.trailingAnchor, constant: -16),
            
            detailsButton.topAnchor.constraint(equalTo: depthInfoView.bottomAnchor, constant: 16),
            detailsButton.centerXAnchor.constraint(equalTo: popupView.centerXAnchor),
            detailsButton.bottomAnchor.constraint(equalTo: popupView.bottomAnchor, constant: -16)
        ])
        
        let refreshButton = UIBarButtonItem(image: UIImage(systemName: "arrow.clockwise"), style: .plain, target: self, action: #selector(refreshData))
        navigationItem.rightBarButtonItem = refreshButton
    }
    
    private func setupBindings() {
        viewModel.delegate = self
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleEarthquakesUpdated),
            name: EarthquakeMapViewModel.earthquakesUpdatedNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleLoadingStateChanged(_:)),
            name: EarthquakeMapViewModel.loadingStateChangedNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleEarthquakeSelected(_:)),
            name: EarthquakeMapViewModel.earthquakeSelectedNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleErrorReceived(_:)),
            name: EarthquakeMapViewModel.errorReceivedNotification,
            object: nil
        )
    }
    
    @objc private func handleEarthquakesUpdated() {
        DispatchQueue.main.async { [weak self] in
            self?.updateMapAnnotations()
            self?.closePopup()
        }
    }
    
    @objc private func handleLoadingStateChanged(_ notification: Notification) {
        if let isLoading = notification.userInfo?["isLoading"] as? Bool {
            DispatchQueue.main.async { [weak self] in
                if isLoading {
                    self?.activityIndicator.startAnimating()
                } else {
                    self?.activityIndicator.stopAnimating()
                }
            }
        }
    }
    
    @objc private func handleEarthquakeSelected(_ notification: Notification) {
        if let earthquake = notification.userInfo?["selectedEarthquake"] as? Earthquake {
            DispatchQueue.main.async { [weak self] in
                self?.updatePopupView(with: earthquake)
            }
        }
    }
    
    @objc private func handleErrorReceived(_ notification: Notification) {
        if let errorMessage = notification.userInfo?["errorMessage"] as? String {
            DispatchQueue.main.async { [weak self] in
                self?.showError(message: errorMessage)
            }
        }
    }
    
    private func fetchEarthquakes() {
        viewModel.fetchEarthquakes()
    }
    
    private func updateMapAnnotations() {
        let existingAnnotations = mapView.annotations.filter { !($0 is MKUserLocation) }
        mapView.removeAnnotations(existingAnnotations)
        
        let annotations = viewModel.getAnnotations()
        mapView.addAnnotations(annotations)
        
        if let centerCoordinate = viewModel.getCenterCoordinate() {
            let span = viewModel.getInitialSpan()
            let region = MKCoordinateRegion(center: centerCoordinate, span: span)
            mapView.setRegion(region, animated: true)
        }
    }
    
    private func updatePopupView(with earthquake: Earthquake) {
        locationLabel.text = earthquake.location
        dateTimeLabel.text = "\(earthquake.date) \(earthquake.time)"
        
        let magnitude: String
        var magValue: Double = 0.0
        
        if let ml = Double(earthquake.ml), ml > 0 {
            magnitude = String(format: "%.1f", ml)
            magValue = ml
        } else if let mw = Double(earthquake.mw), mw > 0 {
            magnitude = String(format: "%.1f", mw)
            magValue = mw
        } else if let md = Double(earthquake.md), md > 0 {
            magnitude = String(format: "%.1f", md)
            magValue = md
        } else {
            magnitude = "N/A"
        }
        
        magnitudeLabel.text = magnitude
        magnitudeCircleView.backgroundColor = viewModel.getColor(for: earthquake)
        
        depthInfoView.setValue("\(earthquake.depth_km) km")
        
        coordinatesInfoView.setValue("\(earthquake.latitude.prefix(6)), \(earthquake.longitude.prefix(6))")
        
        if let selectedView = selectedAnnotationView {
            positionPopupRelativeToAnnotation(selectedView)
        }
        
        showPopupWithAnimation()
    }
    
    private func positionPopupRelativeToAnnotation(_ annotationView: MKAnnotationView) {
        let annotationPoint = mapView.convert(annotationView.annotation!.coordinate, toPointTo: view)
        
        let annotationHeight = annotationView.frame.height * annotationView.transform.a
        
        popupBottomConstraint?.isActive = false
        popupBottomConstraint = popupView.bottomAnchor.constraint(equalTo: view.topAnchor, constant: annotationPoint.y - annotationHeight)
        popupBottomConstraint?.isActive = true
        
        popupCenterXConstraint?.isActive = false
        
        let screenWidth = view.frame.width
        let screenCenter = screenWidth / 2
        
        if annotationPoint.x < screenCenter - 50 {
            popupCenterXConstraint = popupView.centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: 50)
        } else if annotationPoint.x > screenCenter + 50 {
            popupCenterXConstraint = popupView.centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: -50)
        } else {
            popupCenterXConstraint = popupView.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        }
        
        popupCenterXConstraint?.isActive = true
        
        let legendViewTop = legendView.frame.minY
        let estimatedPopupHeight = 200
        
        if let constraint = popupBottomConstraint, constraint.constant + CGFloat(estimatedPopupHeight) > legendViewTop {
            popupBottomConstraint?.constant = legendViewTop - CGFloat(estimatedPopupHeight) - 20
        }
        
        view.layoutIfNeeded()
    }
    
    private func showPopupWithAnimation() {
        popupView.isHidden = false
        popupView.alpha = 0
        popupView.transform = CGAffineTransform(rotationAngle: 30)
        
        UIView.animate(withDuration: 0.3) {
            self.popupView.alpha = 1.0
            self.popupView.transform = CGAffineTransform.identity
        }
    }
    
    @objc private func refreshData() {
        closePopup()
        fetchEarthquakes()
    }
    
    @objc private func closePopup() {
        UIView.animate(withDuration: 0.3) {
            self.popupView.alpha = 0.0
            self.popupView.transform = CGAffineTransform(rotationAngle: 30)
        } completion: { _ in
            self.popupView.isHidden = true
            // Seçili annotation'ı sıfırla
            self.viewModel.clearSelectedEarthquake()
            self.selectedAnnotationView = nil
            self.resetAllAnnotations()
        }
    }
    
    @objc private func changeMapType() {
        let actionSheet = UIAlertController(title: "Harita Tipi", message: "Bir harita tipi seçin", preferredStyle: .actionSheet)
        
        let standardAction = UIAlertAction(title: "Standart", style: .default) { [weak self] _ in
            self?.mapView.mapType = .standard
        }
        
        let satelliteAction = UIAlertAction(title: "Uydu", style: .default) { [weak self] _ in
            self?.mapView.mapType = .satellite
        }
        
        let hybridAction = UIAlertAction(title: "Hibrit", style: .default) { [weak self] _ in
            self?.mapView.mapType = .hybrid
        }
        
        let cancelAction = UIAlertAction(title: "İptal", style: .cancel)
        
        actionSheet.addAction(standardAction)
        actionSheet.addAction(satelliteAction)
        actionSheet.addAction(hybridAction)
        actionSheet.addAction(cancelAction)
        
        if let popoverController = actionSheet.popoverPresentationController {
            popoverController.sourceView = mapTypeButton
            popoverController.sourceRect = mapTypeButton.bounds
        }
        
        present(actionSheet, animated: true)
    }
    
    @objc private func showFilterOptions() {
        let alertController = UIAlertController(title: "Deprem Filtresi", message: "Gösterilecek depremleri filtreleyin", preferredStyle: .actionSheet)
        
        let allAction = UIAlertAction(title: "Tümü", style: .default) { [weak self] _ in
            self?.viewModel.filterByMagnitude(minMagnitude: 0.0)
            self?.closePopup()
        }
        
        let magnitude2Action = UIAlertAction(title: "Büyüklük >= 2.0", style: .default) { [weak self] _ in
            self?.viewModel.filterByMagnitude(minMagnitude: 2.0)
            self?.closePopup()
        }
        
        let magnitude3Action = UIAlertAction(title: "Büyüklük >= 3.0", style: .default) { [weak self] _ in
            self?.viewModel.filterByMagnitude(minMagnitude: 3.0)
            self?.closePopup()
        }
        
        let magnitude4Action = UIAlertAction(title: "Büyüklük >= 4.0", style: .default) { [weak self] _ in
            self?.viewModel.filterByMagnitude(minMagnitude: 4.0)
            self?.closePopup()
        }
        
        let magnitude5Action = UIAlertAction(title: "Büyüklük >= 5.0", style: .default) { [weak self] _ in
            self?.viewModel.filterByMagnitude(minMagnitude: 5.0)
            self?.closePopup()
        }
        
        let cancelAction = UIAlertAction(title: "İptal", style: .cancel)
        
        allAction.setValue(UIImage(systemName: "list.bullet"), forKey: "image")
        magnitude2Action.setValue(UIImage(systemName: "circle.fill"), forKey: "image")
        magnitude3Action.setValue(UIImage(systemName: "circle.fill"), forKey: "image")
        magnitude4Action.setValue(UIImage(systemName: "circle.fill"), forKey: "image")
        magnitude5Action.setValue(UIImage(systemName: "circle.fill"), forKey: "image")
        
        alertController.addAction(allAction)
        alertController.addAction(magnitude2Action)
        alertController.addAction(magnitude3Action)
        alertController.addAction(magnitude4Action)
        alertController.addAction(magnitude5Action)
        alertController.addAction(cancelAction)
        
        if let popoverController = alertController.popoverPresentationController {
            popoverController.sourceView = filterButton
            popoverController.sourceRect = filterButton.bounds
        }
        
        present(alertController, animated: true)
    }
    
    @objc private func showDetails() {
        guard let earthquake = viewModel.selectedEarthquake else { return }
        
        let detailsVC = EarthquakeDetailsViewController(earthquake: earthquake)
        navigationController?.pushViewController(detailsVC, animated: true)
    }
    
    private func showError(message: String) {
        let alertController = UIAlertController(title: "Hata", message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "Tamam", style: .default)
        alertController.addAction(okAction)
        present(alertController, animated: true)
    }
}

// MARK: - EarthquakeMapViewModelDelegate
extension EarthquakeMapViewController: EarthquakeMapViewModelDelegate {
    func didUpdateEarthquakes() {
        DispatchQueue.main.async { [weak self] in
            self?.updateMapAnnotations()
            self?.closePopup()
        }
    }
    
    func didSelectEarthquake(_ earthquake: Earthquake?) {
        if let earthquake = earthquake {
            DispatchQueue.main.async { [weak self] in
                self?.updatePopupView(with: earthquake)
            }
        }
    }
    
    func didChangeLoadingState(isLoading: Bool) {
        DispatchQueue.main.async { [weak self] in
            if isLoading {
                self?.activityIndicator.startAnimating()
            } else {
                self?.activityIndicator.stopAnimating()
            }
        }
    }
    
    func didReceiveError(message: String?) {
        if let errorMessage = message {
            DispatchQueue.main.async { [weak self] in
                self?.showError(message: errorMessage)
            }
        }
    }
}

// MARK: - MKMapViewDelegate
extension EarthquakeMapViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        // Kullanıcı konumu için varsayılan görünümü kullan
        if annotation is MKUserLocation {
            return nil
        }
        
        // Deprem annotation'ı için özel görünüm oluştur
        if let earthquakeAnnotation = annotation as? EarthquakeAnnotation {
            let identifier = "EarthquakeAnnotation"
            var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKMarkerAnnotationView
            
            if annotationView == nil {
                annotationView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                annotationView?.canShowCallout = false
                
                // Yeni eklenen annotation'a animasyon uygula
                annotationView?.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
                UIView.animate(withDuration: 0.3) {
                    annotationView?.transform = CGAffineTransform.identity
                }
            } else {
                annotationView?.annotation = annotation
            }
            
            // Büyüklüğe göre renk ve boyut ayarla
            let magnitude = viewModel.getMagnitude(for: earthquakeAnnotation.earthquake)
            annotationView?.markerTintColor = viewModel.getColor(for: earthquakeAnnotation.earthquake)
            
            // Magnitude bazlı ölçeklendirme
            let scale = viewModel.getMarkerScale(for: earthquakeAnnotation.earthquake)
            annotationView?.transform = CGAffineTransform(scaleX: scale, y: scale)
            
            // Büyüklüğe göre ikon belirleme
            if magnitude >= 5.0 {
                annotationView?.glyphImage = UIImage(systemName: "exclamationmark.triangle.fill")
            } else if magnitude >= 4.0 {
                annotationView?.glyphImage = UIImage(systemName: "exclamationmark")
            } else {
                annotationView?.glyphImage = UIImage(systemName: "waveform.path.ecg")
                annotationView?.glyphTintColor = .white
            }
            
            // Özel işaretleme ekle - seçilmiş annotation ise farklı bir görünüm uygula
            if let selectedEarthquake = viewModel.selectedEarthquake,
               earthquakeAnnotation.matchesEarthquake(selectedEarthquake) {
                
                annotationView?.markerTintColor = UIColor.systemPurple
                annotationView?.glyphImage = UIImage(systemName: "target")
                annotationView?.glyphTintColor = .white
                annotationView?.transform = CGAffineTransform(scaleX: 2.0, y: 2.0)
                annotationView?.layer.zPosition = 1000
            }
            
            return annotationView
        }
        
        return nil
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        // MapKit tarafından bir annotation seçildiğinde, bizim özel tıklama davranışımızı kullan
        if let annotation = view.annotation as? EarthquakeAnnotation {
            // Seçili annotation'ı resetle
            mapView.deselectAnnotation(annotation, animated: false)
            
            // Zaten seçili mi kontrol et
            let isAlreadySelected = (viewModel.selectedEarthquake != nil &&
                                     annotation.matchesEarthquake(viewModel.selectedEarthquake!))
            
            if isAlreadySelected && !popupView.isHidden {
                // Aynı annotation'a tekrar tıklandıysa popup'ı kapat
                closePopup()
            } else {
                // Yeni bir annotation'a tıklandıysa veya popup kapalıysa, vurgula ve popup'ı göster
                resetAllAnnotations()
                annotation.isSelected = true
                highlightSelectedAnnotation(view)
                selectedAnnotationView = view
                viewModel.selectEarthquake(annotation)
            }
        }
    }
    
    // Haritada region değiştiğinde çağrılır - ek bilgi olarak
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        // Harita bölgesi değiştiğinde tüm annotation'ların doğru boyut ve konumda olmasını sağla
        for annotation in mapView.annotations {
            if let view = mapView.view(for: annotation) as? MKMarkerAnnotationView,
               let earthquakeAnnotation = annotation as? EarthquakeAnnotation {
                
                if earthquakeAnnotation.isSelected {
                    highlightSelectedAnnotation(view)
                } else {
                    let scale = viewModel.getMarkerScale(for: earthquakeAnnotation.earthquake)
                    view.transform = CGAffineTransform(scaleX: scale, y: scale)
                }
            }
        }
    }
}

// MARK: - UIGestureRecognizerDelegate
extension EarthquakeMapViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        // PopupView veya içindeki herhangi bir elemana dokunulduğunda tap gesture'ı engelle
        if let touchView = touch.view, touchView == popupView || touchView.isDescendant(of: popupView) {
            return false
        }
        
        // MapView dışında bir yere dokunulduğunda tap gesture'ı engelle
        return touch.view == mapView
    }
}

// MARK: - InfoRowView
class InfoRowView: UIView {
    
    private let iconImageView = UIImageView()
    private let titleLabel = UILabel()
    private let valueLabel = UILabel()
    
    init(iconName: String, title: String) {
        super.init(frame: .zero)
        setupView(iconName: iconName, title: title)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupView(iconName: String, title: String) {
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.image = UIImage(systemName: iconName)
        iconImageView.tintColor = AppTheme.indigoColor
        
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = title + ":"
        titleLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        titleLabel.textColor = AppTheme.bodyTextColor
        
        valueLabel.translatesAutoresizingMaskIntoConstraints = false
        valueLabel.text = "—"
        valueLabel.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        valueLabel.textColor = AppTheme.titleTextColor
        
        addSubview(iconImageView)
        addSubview(titleLabel)
        addSubview(valueLabel)
        
        NSLayoutConstraint.activate([
            iconImageView.leadingAnchor.constraint(equalTo: leadingAnchor),
            iconImageView.centerYAnchor.constraint(equalTo: centerYAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 20),
            iconImageView.heightAnchor.constraint(equalToConstant: 20),
            
            titleLabel.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: 8),
            titleLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            
            valueLabel.leadingAnchor.constraint(equalTo: titleLabel.trailingAnchor, constant: 4),
            valueLabel.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor),
            valueLabel.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }
    
    func setValue(_ value: String) {
        valueLabel.text = value
    }
}

// MARK: - EarthquakeMagnitudeLegendView
class EarthquakeMagnitudeLegendView: UIView {
    
    private let titleLabel = UILabel()
    private let stackView = UIStackView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        backgroundColor = UIColor.white.withAlphaComponent(0.9)
        
        // Title Label
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = "Deprem Büyüklüğü"
        titleLabel.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        titleLabel.textColor = AppTheme.titleTextColor
        
        // Stack View
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.spacing = 4
        stackView.alignment = .fill
        stackView.distribution = .fillEqually
        
        // Add subviews
        addSubview(titleLabel)
        addSubview(stackView)
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            
            stackView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8)
        ])
        
        // Add magnitude levels to stack view
        addMagnitudeLevel(color: UIColor(red: 0.0, green: 0.7, blue: 0.0, alpha: 1.0), text: "< 2.0")
        addMagnitudeLevel(color: UIColor(red: 0.6, green: 0.8, blue: 0.0, alpha: 1.0), text: "2.0 - 2.9")
        addMagnitudeLevel(color: UIColor(red: 0.8, green: 0.8, blue: 0.0, alpha: 1.0), text: "3.0 - 3.9")
        addMagnitudeLevel(color: UIColor(red: 0.9, green: 0.6, blue: 0.0, alpha: 1.0), text: "4.0 - 4.9")
        addMagnitudeLevel(color: UIColor(red: 1.0, green: 0.4, blue: 0.0, alpha: 1.0), text: "5.0 - 5.9")
        addMagnitudeLevel(color: UIColor(red: 1.0, green: 0.0, blue: 0.0, alpha: 1.0), text: "≥ 6.0")
    }
    
    private func addMagnitudeLevel(color: UIColor, text: String) {
        let rowView = UIView()
        rowView.translatesAutoresizingMaskIntoConstraints = false
        
        let colorView = UIView()
        colorView.translatesAutoresizingMaskIntoConstraints = false
        colorView.backgroundColor = color
        colorView.layer.cornerRadius = 6
        
        let textLabel = UILabel()
        textLabel.translatesAutoresizingMaskIntoConstraints = false
        textLabel.text = text
        textLabel.font = UIFont.systemFont(ofSize: 12)
        textLabel.textColor = AppTheme.bodyTextColor
        
        rowView.addSubview(colorView)
        rowView.addSubview(textLabel)
        
        NSLayoutConstraint.activate([
            colorView.leadingAnchor.constraint(equalTo: rowView.leadingAnchor),
            colorView.centerYAnchor.constraint(equalTo: rowView.centerYAnchor),
            colorView.widthAnchor.constraint(equalToConstant: 12),
            colorView.heightAnchor.constraint(equalToConstant: 12),
            
            textLabel.leadingAnchor.constraint(equalTo: colorView.trailingAnchor, constant: 8),
            textLabel.centerYAnchor.constraint(equalTo: rowView.centerYAnchor),
            textLabel.trailingAnchor.constraint(equalTo: rowView.trailingAnchor),
            
            rowView.heightAnchor.constraint(equalToConstant: 16)
        ])
        
        stackView.addArrangedSubview(rowView)
    }
}
