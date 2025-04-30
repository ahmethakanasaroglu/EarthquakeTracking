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
        return map
    }()
    
    private lazy var activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.hidesWhenStopped = true
        return indicator
    }()
    
    private lazy var popupView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .systemBackground
        view.layer.cornerRadius = 12
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = 0.3
        view.layer.shadowOffset = CGSize(width: 0, height: 2)
        view.layer.shadowRadius = 4
        view.isHidden = true
        return view
    }()
    
    private lazy var popupStackView: UIStackView = {
        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.spacing = 8
        stack.alignment = .leading
        stack.distribution = .fill
        return stack
    }()
    
    private lazy var locationLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        label.numberOfLines = 0
        return label
    }()
    
    private lazy var dateTimeLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = .secondaryLabel
        return label
    }()
    
    private lazy var magnitudeLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        return label
    }()
    
    private lazy var depthLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = .secondaryLabel
        return label
    }()
    
    private lazy var closeButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        button.tintColor = .secondaryLabel
        button.addTarget(self, action: #selector(closePopup), for: .touchUpInside)
        return button
    }()
    
    private lazy var detailsButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Detaylar", for: .normal)
        button.setImage(UIImage(systemName: "info.circle"), for: .normal)
        button.tintColor = .systemBlue
        button.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        button.addTarget(self, action: #selector(showDetails), for: .touchUpInside)
        return button
    }()
    
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
        view.backgroundColor = .systemBackground
        
        view.addSubview(mapView)
        view.addSubview(activityIndicator)
        view.addSubview(popupView)
        
        popupView.addSubview(popupStackView)
        popupView.addSubview(closeButton)
        
        popupStackView.addArrangedSubview(locationLabel)
        popupStackView.addArrangedSubview(dateTimeLabel)
        
        let infoStack = createInfoStackView()
        popupStackView.addArrangedSubview(infoStack)
        popupStackView.addArrangedSubview(detailsButton)
        
        NSLayoutConstraint.activate([
            mapView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            mapView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            mapView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            mapView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            
            popupView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            popupView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            popupView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            
            popupStackView.topAnchor.constraint(equalTo: popupView.topAnchor, constant: 16),
            popupStackView.leadingAnchor.constraint(equalTo: popupView.leadingAnchor, constant: 16),
            popupStackView.trailingAnchor.constraint(equalTo: closeButton.leadingAnchor, constant: -8),
            popupStackView.bottomAnchor.constraint(equalTo: popupView.bottomAnchor, constant: -16),
            
            closeButton.topAnchor.constraint(equalTo: popupView.topAnchor, constant: 12),
            closeButton.trailingAnchor.constraint(equalTo: popupView.trailingAnchor, constant: -12),
            closeButton.widthAnchor.constraint(equalToConstant: 24),
            closeButton.heightAnchor.constraint(equalToConstant: 24)
        ])
        
        let refreshButton = UIBarButtonItem(barButtonSystemItem: .refresh, target: self, action: #selector(refreshData))
        navigationItem.rightBarButtonItem = refreshButton
    }
    
    private func createInfoStackView() -> UIStackView {
        let magnitudeStack = UIStackView(arrangedSubviews: [
            createIconLabel(iconName: "waveform.path.ecg", text: "Büyüklük:"),
            magnitudeLabel
        ])
        magnitudeStack.spacing = 4
        
        let depthStack = UIStackView(arrangedSubviews: [
            createIconLabel(iconName: "arrow.down", text: "Derinlik:"),
            depthLabel
        ])
        depthStack.spacing = 4
        
        let infoStack = UIStackView(arrangedSubviews: [magnitudeStack, depthStack])
        infoStack.distribution = .fillEqually
        infoStack.spacing = 12
        
        return infoStack
    }
    
    private func createIconLabel(iconName: String, text: String) -> UIStackView {
        let imageView = UIImageView(image: UIImage(systemName: iconName))
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = .secondaryLabel
        
        let label = UILabel()
        label.text = text
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = .secondaryLabel
        
        let stack = UIStackView(arrangedSubviews: [imageView, label])
        stack.spacing = 4
        stack.alignment = .center
        
        NSLayoutConstraint.activate([
            imageView.widthAnchor.constraint(equalToConstant: 16),
            imageView.heightAnchor.constraint(equalToConstant: 16)
        ])
        
        return stack
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
        if let ml = Double(earthquake.ml), ml > 0 {
            magnitude = String(format: "%.1f", ml)
        } else if let mw = Double(earthquake.mw), mw > 0 {
            magnitude = String(format: "%.1f", mw)
        } else if let md = Double(earthquake.md), md > 0 {
            magnitude = String(format: "%.1f", md)
        } else {
            magnitude = "N/A"
        }
        
        if let magValue = Double(magnitude) {
            if magValue >= 5.0 {
                magnitudeLabel.textColor = .systemRed
            } else if magValue >= 4.0 {
                magnitudeLabel.textColor = .systemOrange
            } else {
                magnitudeLabel.textColor = .systemGreen
            }
        } else {
            magnitudeLabel.textColor = .label
        }
        
        magnitudeLabel.text = magnitude
        depthLabel.text = "\(earthquake.depth_km) km"
        
        popupView.isHidden = false
        popupView.alpha = 0
        
        UIView.animate(withDuration: 0.3) {
            self.popupView.alpha = 1.0
        }
    }
    
    @objc private func refreshData() {
        fetchEarthquakes()
    }
    
    @objc private func closePopup() {
        UIView.animate(withDuration: 0.3) {
            self.popupView.alpha = 0.0
        } completion: { _ in
            self.popupView.isHidden = true
        }
    }
    
    @objc private func showDetails() {

        guard let earthquake = viewModel.selectedEarthquake else { return }
        
        let alertController = UIAlertController(title: earthquake.location, message: """
            Tarih: \(earthquake.date)
            Saat: \(earthquake.time)
            Enlem: \(earthquake.latitude)
            Boylam: \(earthquake.longitude)
            Derinlik: \(earthquake.depth_km) km
            ML: \(earthquake.ml)
            MW: \(earthquake.mw)
            MD: \(earthquake.md)
            """, preferredStyle: .alert)
        
        let okAction = UIAlertAction(title: "Tamam", style: .default)
        alertController.addAction(okAction)
        
        present(alertController, animated: true)
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
            
            annotationView?.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
            UIView.animate(withDuration: 0.3) {
                annotationView?.transform = CGAffineTransform.identity
            }
        } else {
            annotationView?.annotation = annotation
        }
        
        annotationView?.markerTintColor = viewModel.getColor(for: annotation.earthquake)
        
        let magnitude = viewModel.getMagnitude(for: annotation.earthquake)
        if magnitude >= 5.0 {
            annotationView?.glyphImage = UIImage(systemName: "exclamationmark.triangle.fill")
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
