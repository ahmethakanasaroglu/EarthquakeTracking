import UIKit
import MapKit
import Combine

class EarthquakeMapViewController: UIViewController {
    
    private let viewModel = EarthquakeMapViewModel()
    private var cancellables = Set<AnyCancellable>()
    
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
        indicator.color = AppTheme.primaryColor
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
        view.backgroundColor = AppTheme.primaryColor
        view.layer.cornerRadius = 25
        view.layer.shadowColor = AppTheme.primaryColor.cgColor
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
        button.tintColor = AppTheme.primaryColor
        button.backgroundColor = AppTheme.backgroundColor.withAlphaComponent(0.9)
        button.layer.cornerRadius = 20
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOpacity = 0.2
        button.layer.shadowOffset = CGSize(width: 0, height: 2)
        button.layer.shadowRadius = 4
        button.addTarget(self, action: #selector(changeMapType), for: .touchUpInside)
        return button
    }()
    
    private lazy var clusterSwitch: UISwitch = {
        let switchControl = UISwitch()
        switchControl.translatesAutoresizingMaskIntoConstraints = false
        switchControl.onTintColor = AppTheme.primaryColor
        switchControl.addTarget(self, action: #selector(toggleClustering), for: .valueChanged)
        return switchControl
    }()
    
    private lazy var clusterLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Depremleri Grupla"
        label.font = UIFont.systemFont(ofSize: 12)
        label.textColor = AppTheme.titleTextColor
        return label
    }()
    
    private lazy var clusterControlView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = AppTheme.backgroundColor.withAlphaComponent(0.9)
        view.layer.cornerRadius = 16
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = 0.2
        view.layer.shadowOffset = CGSize(width: 0, height: 2)
        view.layer.shadowRadius = 4
        
        view.addSubview(clusterSwitch)
        view.addSubview(clusterLabel)
        
        NSLayoutConstraint.activate([
            clusterSwitch.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            clusterSwitch.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10),
            
            clusterLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            clusterLabel.leadingAnchor.constraint(equalTo: clusterSwitch.trailingAnchor, constant: 8),
            clusterLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10)
        ])
        
        return view
    }()
    
    private var isClusteringEnabled = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupBindings()
        setupGestureRecognizers()
        fetchEarthquakes()
    }
    
    func focusOnLocation(_ coordinate: CLLocationCoordinate2D, earthquake: Earthquake) {
        if viewModel.earthquakes.isEmpty {
            viewModel.fetchEarthquakes()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.performFocusOnEarthquake(coordinate, earthquake: earthquake)
            }
        } else {
            performFocusOnEarthquake(coordinate, earthquake: earthquake)
        }
    }
    
    private func performFocusOnEarthquake(_ coordinate: CLLocationCoordinate2D, earthquake: Earthquake) {
        let region = MKCoordinateRegion(center: coordinate, span: MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5))
        mapView.setRegion(region, animated: true)
        
        var targetAnnotation: EarthquakeAnnotation? = nil
        
        for annotation in mapView.annotations {
            if let earthquakeAnnotation = annotation as? EarthquakeAnnotation {
                if abs(earthquakeAnnotation.coordinate.latitude - coordinate.latitude) < 0.00001 &&
                   abs(earthquakeAnnotation.coordinate.longitude - coordinate.longitude) < 0.00001 {
                    targetAnnotation = earthquakeAnnotation
                    break
                }
            }
        }
        
        if let annotation = targetAnnotation {
            resetAllAnnotations()
            
            mapView.selectAnnotation(annotation, animated: true)
            viewModel.selectedEarthquake = annotation.earthquake
            
            if let annotationView = mapView.view(for: annotation) {
                highlightAnnotationView(annotationView)
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
    
    private func setupGestureRecognizers() {
        tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleMapTap(_:)))
        tapGestureRecognizer.delegate = self
        mapView.addGestureRecognizer(tapGestureRecognizer)
    }
    
    @objc private func handleMapTap(_ gestureRecognizer: UITapGestureRecognizer) {
        if !popupView.isHidden {
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
        view.addSubview(clusterControlView)
        
        // Popup View Hierarchy
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
            
            // Map Controls
            mapTypeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            mapTypeButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            mapTypeButton.widthAnchor.constraint(equalToConstant: 40),
            mapTypeButton.heightAnchor.constraint(equalToConstant: 40),
            
            clusterControlView.topAnchor.constraint(equalTo: mapTypeButton.bottomAnchor, constant: 16),
            clusterControlView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            clusterControlView.heightAnchor.constraint(equalToConstant: 40),
            
            // Popup View
            popupView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            popupView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            popupView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            
            // Close Button
            closeButton.topAnchor.constraint(equalTo: popupView.topAnchor, constant: 12),
            closeButton.trailingAnchor.constraint(equalTo: popupView.trailingAnchor, constant: -12),
            closeButton.widthAnchor.constraint(equalToConstant: 24),
            closeButton.heightAnchor.constraint(equalToConstant: 24),
            
            // Magnitude Circle
            magnitudeCircleView.leadingAnchor.constraint(equalTo: popupView.leadingAnchor, constant: 16),
            magnitudeCircleView.topAnchor.constraint(equalTo: popupView.topAnchor, constant: 16),
            magnitudeCircleView.widthAnchor.constraint(equalToConstant: 50),
            magnitudeCircleView.heightAnchor.constraint(equalToConstant: 50),
            
            magnitudeLabel.centerXAnchor.constraint(equalTo: magnitudeCircleView.centerXAnchor),
            magnitudeLabel.centerYAnchor.constraint(equalTo: magnitudeCircleView.centerYAnchor),
            
            // Location Label
            locationLabel.topAnchor.constraint(equalTo: popupView.topAnchor, constant: 16),
            locationLabel.leadingAnchor.constraint(equalTo: magnitudeCircleView.trailingAnchor, constant: 16),
            locationLabel.trailingAnchor.constraint(equalTo: closeButton.leadingAnchor, constant: -8),
            
            // Date Time Label
            dateTimeLabel.topAnchor.constraint(equalTo: locationLabel.bottomAnchor, constant: 8),
            dateTimeLabel.leadingAnchor.constraint(equalTo: magnitudeCircleView.trailingAnchor, constant: 16),
            dateTimeLabel.trailingAnchor.constraint(equalTo: closeButton.leadingAnchor, constant: -8),
            
            // Depth Info View
            depthInfoView.topAnchor.constraint(equalTo: dateTimeLabel.bottomAnchor, constant: 16),
            depthInfoView.leadingAnchor.constraint(equalTo: popupView.leadingAnchor, constant: 16),
            depthInfoView.trailingAnchor.constraint(equalTo: popupView.centerXAnchor, constant: -8),
            
            // Coordinates Info View
            coordinatesInfoView.topAnchor.constraint(equalTo: dateTimeLabel.bottomAnchor, constant: 16),
            coordinatesInfoView.leadingAnchor.constraint(equalTo: popupView.centerXAnchor, constant: 8),
            coordinatesInfoView.trailingAnchor.constraint(equalTo: popupView.trailingAnchor, constant: -16),
            
            // Details Button
            detailsButton.topAnchor.constraint(equalTo: depthInfoView.bottomAnchor, constant: 16),
            detailsButton.centerXAnchor.constraint(equalTo: popupView.centerXAnchor),
            detailsButton.bottomAnchor.constraint(equalTo: popupView.bottomAnchor, constant: -16)
        ])
        
        let refreshButton = UIBarButtonItem(image: UIImage(systemName: "arrow.clockwise"), style: .plain, target: self, action: #selector(refreshData))
        navigationItem.rightBarButtonItem = refreshButton
    }
    
    private func setupBindings() {
        viewModel.$earthquakes
            .receive(on: DispatchQueue.main)
            .sink { [weak self] earthquakes in
                self?.updateMapAnnotations()
            }
            .store(in: &cancellables)
        
        viewModel.$isLoading
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isLoading in
                if isLoading {
                    self?.activityIndicator.startAnimating()
                } else {
                    self?.activityIndicator.stopAnimating()
                }
            }
            .store(in: &cancellables)
        
        viewModel.$selectedEarthquake
            .receive(on: DispatchQueue.main)
            .compactMap { $0 }
            .sink { [weak self] earthquake in
                self?.updatePopupView(with: earthquake)
            }
            .store(in: &cancellables)
        
        viewModel.$errorMessage
            .receive(on: DispatchQueue.main)
            .compactMap { $0 }
            .sink { [weak self] message in
                self?.showError(message: message)
            }
            .store(in: &cancellables)
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
        magnitudeCircleView.backgroundColor = AppTheme.magnitudeColor(for: magValue)
        
        // Update depth info
        depthInfoView.setValue("\(earthquake.depth_km) km")
        
        // Update coordinates info
        coordinatesInfoView.setValue("\(earthquake.latitude.prefix(6)), \(earthquake.longitude.prefix(6))")
        
        // Show popup with animation
        popupView.isHidden = false
        popupView.alpha = 0
        popupView.transform = CGAffineTransform(rotationAngle: 50)
        
        UIView.animate(withDuration: 0.3) {
            self.popupView.alpha = 1.0
            self.popupView.transform = CGAffineTransform.identity
        }
    }
    
    @objc private func refreshData() {
        fetchEarthquakes()
    }
    
    @objc private func closePopup() {
        UIView.animate(withDuration: 0.3) {
            self.popupView.alpha = 0.0
            self.popupView.transform = CGAffineTransform(rotationAngle: 50)
        } completion: { _ in
            self.popupView.isHidden = true
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
    
    @objc private func toggleClustering(_ sender: UISwitch) {
        isClusteringEnabled = sender.isOn
        updateMapAnnotations()
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

// MARK: - MKMapViewDelegate
extension EarthquakeMapViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        guard let annotation = annotation as? EarthquakeAnnotation else {
            return nil
        }
        
        let identifier = "EarthquakeAnnotation"
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKMarkerAnnotationView
        
        if annotationView == nil {
            annotationView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            annotationView?.canShowCallout = false
            
            // Add fade-in animation
            annotationView?.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
            UIView.animate(withDuration: 0.3) {
                annotationView?.transform = CGAffineTransform.identity
            }
        } else {
            annotationView?.annotation = annotation
        }
        
        // Style the marker based on magnitude
        let magnitude = viewModel.getMagnitude(for: annotation.earthquake)
        annotationView?.markerTintColor = AppTheme.magnitudeColor(for: magnitude)
        
        // Add a custom glyph for high magnitude earthquakes
        if magnitude >= 5.0 {
            annotationView?.glyphImage = UIImage(systemName: "exclamationmark.triangle.fill")
        } else if magnitude >= 4.0 {
            annotationView?.glyphImage = UIImage(systemName: "exclamationmark")
        } else {
            annotationView?.glyphImage = nil
            annotationView?.glyphText = String(format: "%.1f", magnitude)
        }
        
        if annotation.isSelected {
            highlightAnnotationView(annotationView!)
        }
        
        return annotationView
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        if let annotation = view.annotation as? EarthquakeAnnotation {
            resetAllAnnotations()
            annotation.isSelected = true
            highlightAnnotationView(view)
            viewModel.selectEarthquake(annotation)
            mapView.setCenter(annotation.coordinate, animated: true)
        }
    }
}

// MARK: - UIGestureRecognizerDelegate
extension EarthquakeMapViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
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
        // Icon
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.image = UIImage(systemName: iconName)
        iconImageView.tintColor = AppTheme.primaryColor
        
        // Title
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = title + ":"
        titleLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        titleLabel.textColor = AppTheme.bodyTextColor
        
        // Value
        valueLabel.translatesAutoresizingMaskIntoConstraints = false
        valueLabel.text = "—"
        valueLabel.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        valueLabel.textColor = AppTheme.titleTextColor
        
        // Add subviews
        addSubview(iconImageView)
        addSubview(titleLabel)
        addSubview(valueLabel)
        
        // Set constraints
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
