import UIKit
import MapKit

class NotificationSettingsViewController: UIViewController {
    
    // MARK: - Properties
    private let viewModel: PersonalizedViewModel
    
    // MARK: - UI Elements
    private lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
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
        label.text = "Deprem Uyarılarını Özelleştir"
        label.font = UIFont.systemFont(ofSize: 22, weight: .bold)
        label.textColor = .label
        return label
    }()
    
    private lazy var descriptionLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Sizin için önemli olan bölgelerdeki depremler hakkında bildirim alın. Belirli büyüklükteki depremler için uyarı alacaksınız."
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = .secondaryLabel
        label.numberOfLines = 0
        return label
    }()
    
    private lazy var notificationsSwitch: UISwitch = {
        let switchControl = UISwitch()
        switchControl.translatesAutoresizingMaskIntoConstraints = false
        switchControl.onTintColor = .systemBlue
        switchControl.addTarget(self, action: #selector(notificationSwitchChanged), for: .valueChanged)
        return switchControl
    }()
    
    private lazy var notificationsLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Deprem Bildirimleri"
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        label.textColor = .label
        return label
    }()
    
    private lazy var magnitudeSlider: UISlider = {
        let slider = UISlider()
        slider.translatesAutoresizingMaskIntoConstraints = false
        slider.minimumValue = 1.0
        slider.maximumValue = 7.0
        slider.value = Float(viewModel.selectedMagnitudeThreshold)
        slider.minimumTrackTintColor = .systemBlue
        slider.addTarget(self, action: #selector(magnitudeSliderChanged), for: .valueChanged)
        return slider
    }()
    
    private lazy var magnitudeValueLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = String(format: "%.1f", viewModel.selectedMagnitudeThreshold)
        label.font = UIFont.systemFont(ofSize: 16, weight: .bold)
        label.textColor = .systemBlue
        label.textAlignment = .center
        return label
    }()
    
    private lazy var magnitudeLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Minimum Büyüklük"
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        label.textColor = .label
        return label
    }()
    
    private lazy var locationsTableView: UITableView = {
        let tableView = UITableView()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.register(MonitoredLocationCell.self, forCellReuseIdentifier: "MonitoredLocationCell")
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .singleLine
        tableView.backgroundColor = .clear
        tableView.layer.cornerRadius = 8
        tableView.clipsToBounds = true
        tableView.isScrollEnabled = false
        return tableView
    }()
    
    private lazy var addLocationButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Yeni Konum Ekle", for: .normal)
        button.setImage(UIImage(systemName: "plus.circle.fill"), for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        button.backgroundColor = .systemGreen
        button.tintColor = .white
        button.layer.cornerRadius = 10
        button.contentEdgeInsets = UIEdgeInsets(top: 10, left: 16, bottom: 10, right: 16)
        button.addTarget(self, action: #selector(addNewLocation), for: .touchUpInside)
        return button
    }()
    
    private lazy var mapView: MKMapView = {
        let mapView = MKMapView()
        mapView.translatesAutoresizingMaskIntoConstraints = false
        mapView.layer.cornerRadius = 8
        mapView.isHidden = true
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(mapTapped(_:)))
        mapView.addGestureRecognizer(tapGesture)
        return mapView
    }()
    
    private lazy var locationNameTextField: UITextField = {
        let textField = UITextField()
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.placeholder = "Yer adı (örn. Ev, İş)"
        textField.borderStyle = .roundedRect
        textField.clearButtonMode = .whileEditing
        textField.isHidden = true
        return textField
    }()
    
    private lazy var confirmLocationButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Konumu Kaydet", for: .normal)
        button.setImage(UIImage(systemName: "checkmark.circle.fill"), for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        button.backgroundColor = .systemBlue
        button.tintColor = .white
        button.layer.cornerRadius = 10
        button.contentEdgeInsets = UIEdgeInsets(top: 10, left: 16, bottom: 10, right: 16)
        button.addTarget(self, action: #selector(confirmLocationSelection), for: .touchUpInside)
        button.isHidden = true
        return button
    }()
    
    private lazy var cancelLocationButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("İptal", for: .normal)
        button.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        button.backgroundColor = .systemRed
        button.tintColor = .white
        button.layer.cornerRadius = 10
        button.contentEdgeInsets = UIEdgeInsets(top: 10, left: 16, bottom: 10, right: 16)
        button.addTarget(self, action: #selector(cancelLocationSelection), for: .touchUpInside)
        button.isHidden = true
        return button
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
        updateUI()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Setup
    private func setupUI() {
        title = "Uyarı Ayarları"
        view.backgroundColor = .systemBackground
        
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        contentView.addSubview(headerLabel)
        contentView.addSubview(descriptionLabel)
        
        let notificationsSwitchStack = UIStackView(arrangedSubviews: [notificationsLabel, notificationsSwitch])
        notificationsSwitchStack.translatesAutoresizingMaskIntoConstraints = false
        notificationsSwitchStack.axis = .horizontal
        notificationsSwitchStack.spacing = 8
        notificationsSwitchStack.alignment = .center
        contentView.addSubview(notificationsSwitchStack)
        
        let magnitudeSliderStack = UIStackView(arrangedSubviews: [magnitudeLabel, magnitudeValueLabel])
        magnitudeSliderStack.translatesAutoresizingMaskIntoConstraints = false
        magnitudeSliderStack.axis = .horizontal
        magnitudeSliderStack.spacing = 8
        magnitudeSliderStack.alignment = .center
        contentView.addSubview(magnitudeSliderStack)
        contentView.addSubview(magnitudeSlider)
        
        let locationsLabel = UILabel()
        locationsLabel.translatesAutoresizingMaskIntoConstraints = false
        locationsLabel.text = "İzlenen Konumlar"
        locationsLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        locationsLabel.textColor = .label
        contentView.addSubview(locationsLabel)
        
        contentView.addSubview(locationsTableView)
        contentView.addSubview(addLocationButton)
        
        contentView.addSubview(mapView)
        contentView.addSubview(locationNameTextField)
        
        let locationButtonsStack = UIStackView(arrangedSubviews: [confirmLocationButton, cancelLocationButton])
        locationButtonsStack.translatesAutoresizingMaskIntoConstraints = false
        locationButtonsStack.axis = .horizontal
        locationButtonsStack.spacing = 16
        locationButtonsStack.distribution = .fillEqually
        contentView.addSubview(locationButtonsStack)
        
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
            
            descriptionLabel.topAnchor.constraint(equalTo: headerLabel.bottomAnchor, constant: 8),
            descriptionLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            descriptionLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            notificationsSwitchStack.topAnchor.constraint(equalTo: descriptionLabel.bottomAnchor, constant: 24),
            notificationsSwitchStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            notificationsSwitchStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            magnitudeSliderStack.topAnchor.constraint(equalTo: notificationsSwitchStack.bottomAnchor, constant: 24),
            magnitudeSliderStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            magnitudeSliderStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            magnitudeSlider.topAnchor.constraint(equalTo: magnitudeSliderStack.bottomAnchor, constant: 8),
            magnitudeSlider.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            magnitudeSlider.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            locationsLabel.topAnchor.constraint(equalTo: magnitudeSlider.bottomAnchor, constant: 24),
            locationsLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            locationsLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            locationsTableView.topAnchor.constraint(equalTo: locationsLabel.bottomAnchor, constant: 8),
            locationsTableView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            locationsTableView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            locationsTableView.heightAnchor.constraint(greaterThanOrEqualToConstant: 120),
            
            addLocationButton.topAnchor.constraint(equalTo: locationsTableView.bottomAnchor, constant: 16),
            addLocationButton.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            
            mapView.topAnchor.constraint(equalTo: addLocationButton.bottomAnchor, constant: 16),
            mapView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            mapView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            mapView.heightAnchor.constraint(equalToConstant: 200),
            
            locationNameTextField.topAnchor.constraint(equalTo: mapView.bottomAnchor, constant: 16),
            locationNameTextField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            locationNameTextField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            locationButtonsStack.topAnchor.constraint(equalTo: locationNameTextField.bottomAnchor, constant: 16),
            locationButtonsStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            locationButtonsStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            locationButtonsStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -24)
        ])
        
        locationsTableView.setContentHuggingPriority(.defaultLow, for: .vertical)
        locationsTableView.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
    }
    
    private func setupBindings() {

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleMonitoredLocationsUpdated),
            name: PersonalizedViewModel.monitoredLocationsChangedNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAddingLocationStateChanged(_:)),
            name: PersonalizedViewModel.addingLocationStateChangedNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleEnableNotificationsChanged(_:)),
            name: PersonalizedViewModel.notificationSettingsChangedNotification,
            object: nil
        )
    }
    
    @objc private func handleMonitoredLocationsUpdated() {
        DispatchQueue.main.async { [weak self] in
            self?.locationsTableView.reloadData()
            self?.updateMapWithLocations()
        }
    }
    
    @objc private func handleAddingLocationStateChanged(_ notification: Notification) {
        if let isAdding = notification.userInfo?["isAdding"] as? Bool {
            DispatchQueue.main.async { [weak self] in
                self?.updateAddLocationUI(isAdding: isAdding)
            }
        }
    }
    
    @objc private func handleEnableNotificationsChanged(_ notification: Notification) {
        if let isEnabled = notification.userInfo?["enabled"] as? Bool {
            DispatchQueue.main.async { [weak self] in
                self?.updateUIBasedOnNotificationState(isEnabled: isEnabled)
            }
        }
    }
    
    // MARK: - UI Updates
    
    private func updateUI() {
        notificationsSwitch.isOn = viewModel.enableNotifications
        magnitudeSlider.value = Float(viewModel.selectedMagnitudeThreshold)
        magnitudeValueLabel.text = String(format: "%.1f", viewModel.selectedMagnitudeThreshold)
        locationsTableView.reloadData()
        updateMapWithLocations()
        
        updateUIBasedOnNotificationState(isEnabled: viewModel.enableNotifications)
    }
    
    private func updateUIBasedOnNotificationState(isEnabled: Bool) {
        magnitudeSlider.isEnabled = isEnabled
        magnitudeValueLabel.alpha = isEnabled ? 1.0 : 0.5
        magnitudeLabel.alpha = isEnabled ? 1.0 : 0.5
        
        locationsTableView.alpha = isEnabled ? 1.0 : 0.5
        locationsTableView.isUserInteractionEnabled = isEnabled
        addLocationButton.isEnabled = isEnabled
        addLocationButton.alpha = isEnabled ? 1.0 : 0.5
        
        if !isEnabled {
            let noNotificationsLabel = UILabel()
            noNotificationsLabel.translatesAutoresizingMaskIntoConstraints = false
            noNotificationsLabel.text = "Deprem uyarıları için bildirimleri açmanız gerekiyor."
            noNotificationsLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
            noNotificationsLabel.textColor = .systemRed
            noNotificationsLabel.textAlignment = .center
            noNotificationsLabel.numberOfLines = 0
            
            for subview in contentView.subviews {
                if let label = subview as? UILabel, label.tag == 999 {
                    label.removeFromSuperview()
                }
            }
            
            noNotificationsLabel.tag = 999
            contentView.addSubview(noNotificationsLabel)
            
            NSLayoutConstraint.activate([
                noNotificationsLabel.topAnchor.constraint(equalTo: magnitudeSlider.topAnchor, constant: -8),
                noNotificationsLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
                noNotificationsLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16)
            ])
        } else {
            for subview in contentView.subviews {
                if let label = subview as? UILabel, label.tag == 999 {
                    label.removeFromSuperview()
                }
            }
        }
    }
    
    private func updateMapWithLocations() {
        mapView.removeAnnotations(mapView.annotations)
        
        let annotations = viewModel.monitoredLocations.map { location -> MKPointAnnotation in
            let annotation = MKPointAnnotation()
            annotation.coordinate = CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude)
            annotation.title = location.name
            return annotation
        }
        
        mapView.addAnnotations(annotations)
        
        if !viewModel.monitoredLocations.isEmpty {
            mapView.showAnnotations(annotations, animated: true)
        } else if let userLocation = viewModel.userLocation {
            let region = MKCoordinateRegion(center: userLocation, span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1))
            mapView.setRegion(region, animated: true)
        }
    }
    
    private func updateAddLocationUI(isAdding: Bool) {
        mapView.isHidden = !isAdding
        locationNameTextField.isHidden = !isAdding
        confirmLocationButton.isHidden = !isAdding
        cancelLocationButton.isHidden = !isAdding
        addLocationButton.isHidden = isAdding
        
        if isAdding {
            locationNameTextField.text = ""
            
            if let userLocation = viewModel.userLocation {
                let region = MKCoordinateRegion(center: userLocation, span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1))
                mapView.setRegion(region, animated: true)
                
                viewModel.setNewLocationCoordinate(userLocation)
                
                let annotation = MKPointAnnotation()
                annotation.coordinate = userLocation
                annotation.title = "Yeni Konum"
                mapView.addAnnotation(annotation)
            }
        }
    }
    
    // MARK: - Actions
    
    @objc private func notificationSwitchChanged(_ sender: UISwitch) {
        viewModel.setEnableNotifications(sender.isOn)
        viewModel.saveUserPreferences()
        
        updateUIBasedOnNotificationState(isEnabled: sender.isOn)
        
        if sender.isOn {
            viewModel.requestNotificationAuthorization()
        }
    }
    
    @objc private func magnitudeSliderChanged(_ sender: UISlider) {
        let value = Double(round(sender.value * 10) / 10) 
        viewModel.setMagnitudeThreshold(value)
        magnitudeValueLabel.text = String(format: "%.1f", value)
        viewModel.saveUserPreferences()
    }
    
    @objc private func addNewLocation() {
        viewModel.setIsAddingMonitoredLocation(true)
    }
    
    @objc private func mapTapped(_ gesture: UITapGestureRecognizer) {
        let point = gesture.location(in: mapView)
        let coordinate = mapView.convert(point, toCoordinateFrom: mapView)
        viewModel.setNewLocationCoordinate(coordinate)
        
        mapView.removeAnnotations(mapView.annotations)
        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinate
        annotation.title = "Yeni Konum"
        mapView.addAnnotation(annotation)
    }
    
    @objc private func confirmLocationSelection() {
        guard !locationNameTextField.text!.isEmpty, viewModel.newLocationCoordinate != nil else {
            // Show alert: name required
            let alert = UIAlertController(title: "Uyarı", message: "Lütfen konum için bir isim girin.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Tamam", style: .default))
            present(alert, animated: true)
            return
        }
        
        viewModel.setNewLocationName(locationNameTextField.text!)
        viewModel.addMonitoredLocation()
    }
    
    @objc private func cancelLocationSelection() {
        viewModel.resetNewLocationForm()
    }
}

// MARK: - UITableViewDelegate, UITableViewDataSource
extension NotificationSettingsViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return max(viewModel.monitoredLocations.count, 1)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MonitoredLocationCell", for: indexPath) as! MonitoredLocationCell
        
        if viewModel.monitoredLocations.isEmpty {
            cell.configure(with: nil)
        } else {
            let location = viewModel.monitoredLocations[indexPath.row]
            cell.configure(with: location)
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return !viewModel.monitoredLocations.isEmpty
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete && !viewModel.monitoredLocations.isEmpty {
            viewModel.removeMonitoredLocation(at: indexPath.row)
        }
    }
}

// MARK: - MonitoredLocationCell
class MonitoredLocationCell: UITableViewCell {
    
    private let nameLabel = UILabel()
    private let coordinateLabel = UILabel()
    private let thresholdLabel = UILabel()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        nameLabel.textColor = .label
        
        coordinateLabel.translatesAutoresizingMaskIntoConstraints = false
        coordinateLabel.font = UIFont.systemFont(ofSize: 12)
        coordinateLabel.textColor = .secondaryLabel
        
        thresholdLabel.translatesAutoresizingMaskIntoConstraints = false
        thresholdLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        thresholdLabel.textColor = .systemBlue
        thresholdLabel.textAlignment = .right
        
        contentView.addSubview(nameLabel)
        contentView.addSubview(coordinateLabel)
        contentView.addSubview(thresholdLabel)
        
        NSLayoutConstraint.activate([
            nameLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            nameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            nameLabel.trailingAnchor.constraint(equalTo: thresholdLabel.leadingAnchor, constant: -8),
            
            coordinateLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 4),
            coordinateLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            coordinateLabel.trailingAnchor.constraint(equalTo: thresholdLabel.leadingAnchor, constant: -8),
            coordinateLabel.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -8),
            
            thresholdLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            thresholdLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            thresholdLabel.widthAnchor.constraint(equalToConstant: 60)
        ])
    }
    
    func configure(with location: MonitoredLocation?) {
        if let location = location {
            nameLabel.text = location.name
            coordinateLabel.text = String(format: "%.4f, %.4f", location.latitude, location.longitude)
            thresholdLabel.text = String(format: "M %.1f+", location.notificationThreshold)
            
            nameLabel.textColor = .label
            coordinateLabel.isHidden = false
            thresholdLabel.isHidden = false
            self.selectionStyle = .default
        } else {
            nameLabel.text = "Henüz izlenen konum yok"
            nameLabel.textColor = .secondaryLabel
            coordinateLabel.isHidden = true
            thresholdLabel.isHidden = true
            self.selectionStyle = .none
        }
    }
}
