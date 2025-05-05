import UIKit
import Combine
import MapKit

class EarthquakeListViewController: UIViewController {
    
    private let viewModel = EarthquakeListViewModel()
    private var cancellables = Set<AnyCancellable>()
    
    private lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(ModernEarthquakeCell.self, forCellReuseIdentifier: "EarthquakeCell")
        tableView.estimatedRowHeight = 120
        tableView.rowHeight = UITableView.automaticDimension
        tableView.separatorStyle = .none
        tableView.backgroundColor = AppTheme.backgroundColor
        return tableView
    }()
    
    private lazy var activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.hidesWhenStopped = true
        indicator.color = AppTheme.primaryColor
        return indicator
    }()
    
    private lazy var refreshControl: UIRefreshControl = {
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(refreshData), for: .valueChanged)
        refreshControl.tintColor = AppTheme.primaryColor
        return refreshControl
    }()
    
    private lazy var emptyStateView: EmptyStateView = {
        let view = EmptyStateView(
            image: UIImage(systemName: "magnifyingglass")!,
            title: "Deprem Verisi Bulunamadı",
            message: "Deprem verileri yüklenirken bir problem oluştu. Lütfen internet bağlantınızı kontrol edin ve tekrar deneyin."
        )
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isHidden = true
        return view
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupBindings()
        fetchEarthquakes()
    }
    
    private func setupUI() {
        title = "Depremler"
        view.backgroundColor = AppTheme.backgroundColor
        
        tableView.refreshControl = refreshControl
        
        view.addSubview(tableView)
        view.addSubview(activityIndicator)
        view.addSubview(emptyStateView)
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            
            emptyStateView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyStateView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            emptyStateView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            emptyStateView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40)
        ])
        
        // Add sort button to navigation bar
        let sortButton = UIBarButtonItem(image: UIImage(systemName: "arrow.up.arrow.down"), style: .plain, target: self, action: #selector(showSortOptions))
        
        // Add map button to navigation bar
        let mapButton = UIBarButtonItem(image: UIImage(systemName: "map"), style: .plain, target: self, action: #selector(showMap))
        
        navigationItem.rightBarButtonItems = [sortButton, mapButton]
    }
    
    private func setupBindings() {
        viewModel.$earthquakes
            .receive(on: DispatchQueue.main)
            .sink { [weak self] earthquakes in
                self?.tableView.reloadData()
                self?.updateEmptyState(earthquakes.isEmpty)
            }
            .store(in: &cancellables)
        
        viewModel.$isLoading
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isLoading in
                if isLoading {
                    self?.activityIndicator.startAnimating()
                    self?.emptyStateView.isHidden = true
                } else {
                    self?.activityIndicator.stopAnimating()
                    self?.refreshControl.endRefreshing()
                }
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
        // İlk yüklemede verileri otomatik olarak tarihe göre sırala
        viewModel.applySortOnLoad()
    }
    
    private func updateEmptyState(_ isEmpty: Bool) {
        emptyStateView.isHidden = !isEmpty || viewModel.isLoading
    }
    
    @objc private func refreshData() {
        fetchEarthquakes()
    }
    
    @objc private func showSortOptions() {
        let alertController = UIAlertController(title: "Sıralama", message: "Sıralama tipi seçin", preferredStyle: .actionSheet)
        
        let dateAction = UIAlertAction(title: "Tarihe Göre", style: .default) { [weak self] _ in
            self?.viewModel.sortByDate()
            self?.tableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: true)
        }
        
        let magnitudeAction = UIAlertAction(title: "Büyüklüğe Göre", style: .default) { [weak self] _ in
            self?.viewModel.sortByMagnitude()
        }
        
        let cancelAction = UIAlertAction(title: "İptal", style: .cancel)
        
        // Add icons to the actions
        dateAction.setValue(UIImage(systemName: "calendar"), forKey: "image")
        magnitudeAction.setValue(UIImage(systemName: "waveform.path.ecg"), forKey: "image")
        
        alertController.addAction(dateAction)
        alertController.addAction(magnitudeAction)
        alertController.addAction(cancelAction)
        
        if let popoverController = alertController.popoverPresentationController {
            popoverController.barButtonItem = navigationItem.rightBarButtonItems?.first
        }
        
        present(alertController, animated: true)
    }
    
    @objc private func showMap() {
        let mapViewController = EarthquakeMapViewController()
        navigationController?.pushViewController(mapViewController, animated: true)
    }
    
    private func showError(message: String) {
        let alertController = UIAlertController(title: "Hata", message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "Tamam", style: .default)
        alertController.addAction(okAction)
        present(alertController, animated: true)
    }
}

// MARK: - UITableViewDataSource
extension EarthquakeListViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.earthquakes.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "EarthquakeCell", for: indexPath) as? ModernEarthquakeCell else {
            return UITableViewCell()
        }
        
        let earthquake = viewModel.earthquakes[indexPath.row]
        cell.configure(with: earthquake)
        return cell
    }
}

// MARK: - UITableViewDelegate
extension EarthquakeListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        // Get selected earthquake
        let selectedEarthquake = viewModel.earthquakes[indexPath.row]
        
        // Show earthquake on map with zoom to its location
        let mapViewController = EarthquakeMapViewController()
        
        // Pass the selected earthquake to focus on
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            // Using a small delay to make sure map is loaded
            if let latitude = Double(selectedEarthquake.latitude),
               let longitude = Double(selectedEarthquake.longitude) {
                let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
                mapViewController.focusOnLocation(coordinate, earthquake: selectedEarthquake)
            }
        }
        
        navigationController?.pushViewController(mapViewController, animated: true)
    }
    
    // Add swipe action for details
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let detailsAction = UIContextualAction(style: .normal, title: "Detaylar") { [weak self] (_, _, completion) in
            // Show details for the earthquake
            self?.showEarthquakeDetails(self?.viewModel.earthquakes[indexPath.row])
            completion(true)
        }
        
        detailsAction.backgroundColor = AppTheme.primaryLightColor
        detailsAction.image = UIImage(systemName: "info.circle")
        
        return UISwipeActionsConfiguration(actions: [detailsAction])
    }
    
    private func showEarthquakeDetails(_ earthquake: Earthquake?) {
        guard let earthquake = earthquake else { return }
        
        let detailsVC = EarthquakeDetailsViewController(earthquake: earthquake)
        navigationController?.pushViewController(detailsVC, animated: true)
    }
}

// MARK: - ModernEarthquakeCell
class ModernEarthquakeCell: UITableViewCell {
    
    private let containerView = UIView()
    private let locationLabel = UILabel()
    private let dateTimeLabel = UILabel()
    private let magnitudeCircleView = UIView()
    private let magnitudeLabel = UILabel()
    private let infoStackView = UIStackView()
    private let mapPreviewImageView = UIImageView()
    private let depthLabel = UILabel()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        selectionStyle = .default
        backgroundColor = .clear
        
        // Container View
        containerView.translatesAutoresizingMaskIntoConstraints = false
        AppTheme.applyCardStyle(to: containerView)
        containerView.layer.shadowOpacity = 0.1
        
        // Location Label
        locationLabel.translatesAutoresizingMaskIntoConstraints = false
        locationLabel.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        locationLabel.textColor = AppTheme.titleTextColor
        locationLabel.numberOfLines = 2
        
        // Date Time Label
        dateTimeLabel.translatesAutoresizingMaskIntoConstraints = false
        dateTimeLabel.font = UIFont.systemFont(ofSize: 14)
        dateTimeLabel.textColor = AppTheme.bodyTextColor
        
        // Magnitude Circle View
        magnitudeCircleView.translatesAutoresizingMaskIntoConstraints = false
        magnitudeCircleView.backgroundColor = AppTheme.primaryColor
        magnitudeCircleView.layer.cornerRadius = 26
        magnitudeCircleView.layer.shadowColor = AppTheme.primaryColor.cgColor
        magnitudeCircleView.layer.shadowOffset = CGSize(width: 0, height: 2)
        magnitudeCircleView.layer.shadowRadius = 4
        magnitudeCircleView.layer.shadowOpacity = 0.3
        
        // Magnitude Label
        magnitudeLabel.translatesAutoresizingMaskIntoConstraints = false
        magnitudeLabel.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        magnitudeLabel.textColor = .white
        magnitudeLabel.textAlignment = .center
        
        // Info Stack View
        infoStackView.translatesAutoresizingMaskIntoConstraints = false
        infoStackView.axis = .horizontal
        infoStackView.spacing = 8
        infoStackView.alignment = .center
        
        // Depth Label
        depthLabel.translatesAutoresizingMaskIntoConstraints = false
        depthLabel.font = UIFont.systemFont(ofSize: 14)
        depthLabel.textColor = AppTheme.bodyTextColor
        
        // Map Preview Image
        mapPreviewImageView.translatesAutoresizingMaskIntoConstraints = false
        mapPreviewImageView.contentMode = .scaleAspectFill
        mapPreviewImageView.layer.cornerRadius = 6
        mapPreviewImageView.clipsToBounds = true
        mapPreviewImageView.image = UIImage(systemName: "mappin.circle.fill")
        mapPreviewImageView.tintColor = AppTheme.primaryColor
        mapPreviewImageView.backgroundColor = AppTheme.tertiaryBackgroundColor
        
        // Add depth to info stack view
        let depthIconView = UIImageView(image: UIImage(systemName: "arrow.down"))
        depthIconView.tintColor = AppTheme.primaryColor
        depthIconView.contentMode = .scaleAspectFit
        depthIconView.widthAnchor.constraint(equalToConstant: 14).isActive = true
        depthIconView.heightAnchor.constraint(equalToConstant: 14).isActive = true
        
        let depthStack = UIStackView(arrangedSubviews: [depthIconView, depthLabel])
        depthStack.spacing = 4
        depthStack.alignment = .center
        
        infoStackView.addArrangedSubview(depthStack)
        
        // Add subviews to container
        containerView.addSubview(mapPreviewImageView)
        containerView.addSubview(locationLabel)
        containerView.addSubview(dateTimeLabel)
        containerView.addSubview(magnitudeCircleView)
        magnitudeCircleView.addSubview(magnitudeLabel)
        containerView.addSubview(infoStackView)
        
        // Add container to content view
        contentView.addSubview(containerView)
        
        // Setup constraints
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            
            magnitudeCircleView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            magnitudeCircleView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            magnitudeCircleView.widthAnchor.constraint(equalToConstant: 52),
            magnitudeCircleView.heightAnchor.constraint(equalToConstant: 52),
            
            magnitudeLabel.centerXAnchor.constraint(equalTo: magnitudeCircleView.centerXAnchor),
            magnitudeLabel.centerYAnchor.constraint(equalTo: magnitudeCircleView.centerYAnchor),
            
            locationLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 16),
            locationLabel.leadingAnchor.constraint(equalTo: magnitudeCircleView.trailingAnchor, constant: 16),
            locationLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            
            dateTimeLabel.topAnchor.constraint(equalTo: locationLabel.bottomAnchor, constant: 8),
            dateTimeLabel.leadingAnchor.constraint(equalTo: magnitudeCircleView.trailingAnchor, constant: 16),
            dateTimeLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            
            infoStackView.topAnchor.constraint(equalTo: dateTimeLabel.bottomAnchor, constant: 8),
            infoStackView.leadingAnchor.constraint(equalTo: magnitudeCircleView.trailingAnchor, constant: 16),
            infoStackView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            infoStackView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -16)
        ])
    }
    
    func configure(with earthquake: Earthquake) {
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
        
        // Make larger magnitudes appear larger
        if magValue >= 5.0 {
            magnitudeLabel.font = UIFont.systemFont(ofSize: 20, weight: .heavy)
        } else {
            magnitudeLabel.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        }
        
        depthLabel.text = "\(earthquake.depth_km) km"
        
        // Add subtle animation
        containerView.transform = CGAffineTransform(scaleX: 0.98, y: 0.98)
        UIView.animate(withDuration: 0.2) {
            self.containerView.transform = CGAffineTransform.identity
        }
    }
}

// MARK: - EarthquakeDetailsViewController
class EarthquakeDetailsViewController: UIViewController {
    
    private let earthquake: Earthquake
    private let mapView = MKMapView()
    private let contentView = UIView()
    
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
    }
    
    private func setupUI() {
        title = "Deprem Detayları"
        view.backgroundColor = AppTheme.backgroundColor
        
        // Map View
        mapView.translatesAutoresizingMaskIntoConstraints = false
        mapView.layer.cornerRadius = 16
        mapView.clipsToBounds = true
        view.addSubview(mapView)
        
        // Content View (will contain all the earthquake details)
        contentView.translatesAutoresizingMaskIntoConstraints = false
        contentView.backgroundColor = AppTheme.backgroundColor
        contentView.layer.cornerRadius = 16
        contentView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        contentView.layer.shadowColor = UIColor.black.cgColor
        contentView.layer.shadowOffset = CGSize(width: 0, height: -4)
        contentView.layer.shadowRadius = 6
        contentView.layer.shadowOpacity = 0.1
        view.addSubview(contentView)
        
        // Add details to the content view
        setupContentView()
        
        // Add the earthquake pin to the map
        if let latitude = Double(earthquake.latitude),
           let longitude = Double(earthquake.longitude) {
            let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            let region = MKCoordinateRegion(center: coordinate, span: MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5))
            mapView.setRegion(region, animated: true)
            
            let annotation = MKPointAnnotation()
            annotation.coordinate = coordinate
            annotation.title = earthquake.location
            mapView.addAnnotation(annotation)
        }
        
        // Setup constraints
        NSLayoutConstraint.activate([
            mapView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            mapView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            mapView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            mapView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.4),
            
            contentView.topAnchor.constraint(equalTo: mapView.bottomAnchor, constant: -20),
            contentView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func setupContentView() {
        // Create a scrollable content view for details
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
        
        // Add location information with a header
        addSectionToStackView(
            stackView: stackView,
            sectionTitle: "Konum",
            content: earthquake.location,
            imageName: "mappin.and.ellipse"
        )
        
        // Add date and time information
        addSectionToStackView(
            stackView: stackView,
            sectionTitle: "Tarih ve Saat",
            content: "\(earthquake.date) \(earthquake.time)",
            imageName: "calendar"
        )
        
        // Add coordinates
        addSectionToStackView(
            stackView: stackView,
            sectionTitle: "Koordinatlar",
            content: "Enlem: \(earthquake.latitude)\nBoylam: \(earthquake.longitude)",
            imageName: "location.circle"
        )
        
        // Add magnitude information
        let magnitudeValue = getMagnitudeValue()
        let magnitudeString = String(format: "ML: %.1f", magnitudeValue)
        
        addSectionToStackView(
            stackView: stackView,
            sectionTitle: "Büyüklük",
            content: magnitudeString,
            imageName: "waveform.path.ecg",
            detailsColor: AppTheme.magnitudeColor(for: magnitudeValue)
        )
        
        // Add depth information
        addSectionToStackView(
            stackView: stackView,
            sectionTitle: "Derinlik",
            content: "\(earthquake.depth_km) km",
            imageName: "arrow.down.circle"
        )
        
        // Add a bottom section with explanation about earthquake magnitudes
        addInformationSection(stackView: stackView)
    }
    
    private func addSectionToStackView(stackView: UIStackView, sectionTitle: String, content: String, imageName: String, detailsColor: UIColor? = nil) {
        // Create section container
        let sectionView = UIView()
        sectionView.translatesAutoresizingMaskIntoConstraints = false
        sectionView.backgroundColor = AppTheme.secondaryBackgroundColor
        sectionView.layer.cornerRadius = 12
        
        // Section icon
        let iconView = UIImageView(image: UIImage(systemName: imageName))
        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.contentMode = .scaleAspectFit
        iconView.tintColor = AppTheme.primaryColor
        
        // Section title
        let titleLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = sectionTitle
        titleLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        titleLabel.textColor = AppTheme.bodyTextColor
        
        // Section content
        let contentLabel = UILabel()
        contentLabel.translatesAutoresizingMaskIntoConstraints = false
        contentLabel.text = content
        contentLabel.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        contentLabel.textColor = detailsColor ?? AppTheme.titleTextColor
        contentLabel.numberOfLines = 0
        
        // Add views to section container
        sectionView.addSubview(iconView)
        sectionView.addSubview(titleLabel)
        sectionView.addSubview(contentLabel)
        
        // Set constraints
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
        
        // Add to stack view
        stackView.addArrangedSubview(sectionView)
    }
    
    private func addInformationSection(stackView: UIStackView) {
        // Information card
        let infoView = UIView()
        infoView.translatesAutoresizingMaskIntoConstraints = false
        infoView.backgroundColor = AppTheme.tertiaryBackgroundColor
        infoView.layer.cornerRadius = 12
        
        // Information icon
        let infoIcon = UIImageView(image: UIImage(systemName: "info.circle.fill"))
        infoIcon.translatesAutoresizingMaskIntoConstraints = false
        infoIcon.contentMode = .scaleAspectFit
        infoIcon.tintColor = AppTheme.primaryColor
        
        // Information title
        let infoTitle = UILabel()
        infoTitle.translatesAutoresizingMaskIntoConstraints = false
        infoTitle.text = "Büyüklük Ölçeği Hakkında"
        infoTitle.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        infoTitle.textColor = AppTheme.primaryColor
        
        // Information content
        let infoContent = UILabel()
        infoContent.translatesAutoresizingMaskIntoConstraints = false
        infoContent.text = "Richter ölçeği (ML): Deprem büyüklüğünün logaritmik ölçeğidir. Her 1.0 değerindeki artış, yaklaşık 10 kat daha fazla sarsıntı genliği ve 32 kat daha fazla enerji anlamına gelir.\n\n3.0 altı: Genellikle hissedilmez\n3.0-3.9: Hafif hissedilir\n4.0-4.9: Orta şiddette, eşyalar sallanabilir\n5.0-5.9: Hasar verebilir\n6.0+: Önemli hasar potansiyeli"
        infoContent.font = UIFont.systemFont(ofSize: 14)
        infoContent.textColor = AppTheme.bodyTextColor
        infoContent.numberOfLines = 0
        
        // Add views to info container
        infoView.addSubview(infoIcon)
        infoView.addSubview(infoTitle)
        infoView.addSubview(infoContent)
        
        // Set constraints
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
        
        // Add to stack view with some spacing
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

// MARK: - EmptyStateView
class EmptyStateView: UIView {
    
    private let imageView = UIImageView()
    private let titleLabel = UILabel()
    private let messageLabel = UILabel()
    private let containerView = UIView()
    
    init(image: UIImage, title: String, message: String) {
        super.init(frame: .zero)
        setupView(image: image, title: title, message: message)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupView(image: UIImage, title: String, message: String) {
        // Container view
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.backgroundColor = AppTheme.secondaryBackgroundColor
        containerView.layer.cornerRadius = 16
        
        // Image view
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        imageView.image = image
        imageView.tintColor = AppTheme.primaryColor
        
        // Title label
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = title
        titleLabel.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        titleLabel.textColor = AppTheme.titleTextColor
        titleLabel.textAlignment = .center
        
        // Message label
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        messageLabel.text = message
        messageLabel.font = UIFont.systemFont(ofSize: 14)
        messageLabel.textColor = AppTheme.bodyTextColor
        messageLabel.textAlignment = .center
        messageLabel.numberOfLines = 0
        
        // Add subviews
        containerView.addSubview(imageView)
        containerView.addSubview(titleLabel)
        containerView.addSubview(messageLabel)
        addSubview(containerView)
        
        // Setup constraints
        NSLayoutConstraint.activate([
            containerView.centerXAnchor.constraint(equalTo: centerXAnchor),
            containerView.centerYAnchor.constraint(equalTo: centerYAnchor),
            containerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: trailingAnchor),
            
            imageView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 30),
            imageView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            imageView.widthAnchor.constraint(equalToConstant: 60),
            imageView.heightAnchor.constraint(equalToConstant: 60),
            
            titleLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            
            messageLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            messageLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            messageLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            messageLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -30)
        ])
    }
}
