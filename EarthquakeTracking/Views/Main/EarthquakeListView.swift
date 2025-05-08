import UIKit
import MapKit

class EarthquakeListViewController: UIViewController {
    
    private let viewModel = EarthquakeListViewModel()
    
    // MARK: - UI Elements
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
    
    private lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(ModernEarthquakeCell.self, forCellReuseIdentifier: "EarthquakeCell")
        tableView.estimatedRowHeight = 120
        tableView.rowHeight = UITableView.automaticDimension
        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear
        tableView.showsVerticalScrollIndicator = true
        tableView.contentInset = UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 0)
        return tableView
    }()
    
    private lazy var activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.hidesWhenStopped = true
        indicator.color = .white
        return indicator
    }()
    
    private lazy var refreshControl: UIRefreshControl = {
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(refreshData), for: .valueChanged)
        refreshControl.tintColor = .white
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
    
    private lazy var headerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = UIColor.white.withAlphaComponent(0.1)
        view.layer.cornerRadius = 16
        
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOffset = CGSize(width: 0, height: 4)
        view.layer.shadowRadius = 8
        view.layer.shadowOpacity = 0.3
        
        return view
    }()
    
    private lazy var headerIconView: UIImageView = {
        let imageView = UIImageView(image: UIImage(systemName: "waveform.path.ecg"))
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = .white
        return imageView
    }()
    
    private lazy var headerLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Son Depremler"
        label.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        label.textColor = .white
        label.numberOfLines = 2
        return label
    }()
    
    private lazy var headerDescriptionLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Türkiye ve çevresindeki son depremlerin listesi"
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = .white.withAlphaComponent(0.9)
        label.numberOfLines = 0
        return label
    }()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupBackground()
        setupUI()
        setupBindings()
        fetchEarthquakes()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        backgroundGradientLayer.frame = view.bounds
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupTabBarAppearance()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Setup
    private func setupBackground() {
        view.layer.insertSublayer(backgroundGradientLayer, at: 0)
    }
    
    private func setupUI() {
        title = "Depremler"
        view.backgroundColor = .clear
        
        tableView.refreshControl = refreshControl
        
        view.addSubview(headerView)
        headerView.addSubview(headerIconView)
        headerView.addSubview(headerLabel)
        headerView.addSubview(headerDescriptionLabel)
        
        view.addSubview(tableView)
        view.addSubview(activityIndicator)
        view.addSubview(emptyStateView)
        
        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            
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
            
            tableView.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 16),
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
        
        let sortButton = UIBarButtonItem(image: UIImage(systemName: "arrow.up.arrow.down"), style: .plain, target: self, action: #selector(showSortOptions))
        sortButton.tintColor = .white
        
        let mapButton = UIBarButtonItem(image: UIImage(systemName: "map"), style: .plain, target: self, action: #selector(showMap))
        mapButton.tintColor = .white
        
        navigationItem.rightBarButtonItems = [sortButton, mapButton]
    }
    
    private func setupTabBarAppearance() {
        if let tabBar = self.tabBarController?.tabBar {
            // Tab bar'ı koyu mavi yap
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            
            // Görseldeki koyu mavi renk
            appearance.backgroundColor = UIColor(red: 0.0/255.0, green: 20.0/255.0, blue: 40.0/255.0, alpha: 1.0)
            
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
    
    private func setupBindings() {
        viewModel.delegate = self
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleEarthquakesUpdated),
            name: EarthquakeListViewModel.earthquakesUpdatedNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleLoadingStateChanged(_:)),
            name: EarthquakeListViewModel.loadingStateChangedNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleErrorReceived(_:)),
            name: EarthquakeListViewModel.errorReceivedNotification,
            object: nil
        )
    }
    
    @objc private func handleEarthquakesUpdated() {
        DispatchQueue.main.async { [weak self] in
            self?.tableView.reloadData()
            self?.updateEmptyState(self?.viewModel.earthquakes.isEmpty ?? true)
        }
    }
    
    @objc private func handleLoadingStateChanged(_ notification: Notification) {
        if let isLoading = notification.userInfo?["isLoading"] as? Bool {
            DispatchQueue.main.async { [weak self] in
                if isLoading {
                    self?.activityIndicator.startAnimating()
                    self?.emptyStateView.isHidden = true
                } else {
                    self?.activityIndicator.stopAnimating()
                    self?.refreshControl.endRefreshing()
                }
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
            if let count = self?.viewModel.earthquakes.count, count > 0 {
                self?.tableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: true)
            }
        }
        
        let magnitudeAction = UIAlertAction(title: "Büyüklüğe Göre", style: .default) { [weak self] _ in
            self?.viewModel.sortByMagnitude()
        }
        
        let cancelAction = UIAlertAction(title: "İptal", style: .cancel)
        
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

// MARK: - EarthquakeListViewModelDelegate
extension EarthquakeListViewController: EarthquakeListViewModelDelegate {
    func didUpdateEarthquakes() {
        DispatchQueue.main.async { [weak self] in
            self?.tableView.reloadData()
            self?.updateEmptyState(self?.viewModel.earthquakes.isEmpty ?? true)
        }
    }
    
    func didChangeLoadingState(isLoading: Bool) {
        DispatchQueue.main.async { [weak self] in
            if isLoading {
                self?.activityIndicator.startAnimating()
                self?.emptyStateView.isHidden = true
            } else {
                self?.activityIndicator.stopAnimating()
                self?.refreshControl.endRefreshing()
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
        
        let selectedEarthquake = viewModel.earthquakes[indexPath.row]
        
        let mapViewController = EarthquakeMapViewController()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if let latitude = Double(selectedEarthquake.latitude),
               let longitude = Double(selectedEarthquake.longitude) {
                let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
                mapViewController.focusOnLocation(coordinate, earthquake: selectedEarthquake)
            }
        }
        
        navigationController?.pushViewController(mapViewController, animated: true)
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let detailsAction = UIContextualAction(style: .normal, title: "Detaylar") { [weak self] (_, _, completion) in
            self?.showEarthquakeDetails(self?.viewModel.earthquakes[indexPath.row])
            completion(true)
        }
        
        detailsAction.backgroundColor = UIColor(red: 0.0/255.0, green: 100.0/255.0, blue: 180.0/255.0, alpha: 1.0)
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
    private let magnitudeIconView = UIImageView()
    private let infoStackView = UIStackView()
    private let depthInfoView = UIView()
    private let depthLabel = UILabel()
    private let depthIconView = UIImageView()
    private let magnitudeInfoView = UIView()
    private let magnitudeValueLabel = UILabel()
    private let magnitudeIconView2 = UIImageView()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.backgroundColor = .white
        containerView.layer.cornerRadius = 16
        containerView.layer.shadowColor = UIColor.black.cgColor
        containerView.layer.shadowOffset = CGSize(width: 0, height: 2)
        containerView.layer.shadowRadius = 4
        containerView.layer.shadowOpacity = 0.1
        
        locationLabel.translatesAutoresizingMaskIntoConstraints = false
        locationLabel.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        locationLabel.textColor = UIColor(red: 0.0/255.0, green: 20.0/255.0, blue: 40.0/255.0, alpha: 1.0)
        locationLabel.numberOfLines = 2
        
        dateTimeLabel.translatesAutoresizingMaskIntoConstraints = false
        dateTimeLabel.font = UIFont.systemFont(ofSize: 14)
        dateTimeLabel.textColor = UIColor.darkGray
        
        magnitudeCircleView.translatesAutoresizingMaskIntoConstraints = false
        magnitudeCircleView.backgroundColor = UIColor(red: 65.0/255.0, green: 130.0/255.0, blue: 234.0/255.0, alpha: 1.0)
        magnitudeCircleView.layer.cornerRadius = 26
        magnitudeCircleView.layer.shadowColor = UIColor.black.cgColor
        magnitudeCircleView.layer.shadowOffset = CGSize(width: 0, height: 2)
        magnitudeCircleView.layer.shadowRadius = 4
        magnitudeCircleView.layer.shadowOpacity = 0.3
        
        magnitudeIconView.translatesAutoresizingMaskIntoConstraints = false
        magnitudeIconView.contentMode = .scaleAspectFit
        magnitudeIconView.image = UIImage(systemName: "waveform.path.ecg")
        magnitudeIconView.tintColor = .white
        
        infoStackView.translatesAutoresizingMaskIntoConstraints = false
        infoStackView.axis = .horizontal
        infoStackView.spacing = 16
        infoStackView.alignment = .center
        infoStackView.distribution = .fillEqually
        
        depthInfoView.translatesAutoresizingMaskIntoConstraints = false
        
        depthIconView.image = UIImage(systemName: "arrow.down")
        depthIconView.tintColor = UIColor.darkGray
        depthIconView.contentMode = .scaleAspectFit
        depthIconView.translatesAutoresizingMaskIntoConstraints = false
        
        depthLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        depthLabel.textColor = UIColor.darkGray
        depthLabel.translatesAutoresizingMaskIntoConstraints = false
        
        magnitudeInfoView.translatesAutoresizingMaskIntoConstraints = false
        
        magnitudeIconView2.image = UIImage(systemName: "waveform.path.ecg")
        magnitudeIconView2.tintColor = UIColor.darkGray
        magnitudeIconView2.contentMode = .scaleAspectFit
        magnitudeIconView2.translatesAutoresizingMaskIntoConstraints = false
        
        magnitudeValueLabel.font = UIFont.systemFont(ofSize: 16, weight: .bold)
        magnitudeValueLabel.textAlignment = .left
        magnitudeValueLabel.textColor = UIColor.darkGray
        magnitudeValueLabel.translatesAutoresizingMaskIntoConstraints = false
        
        magnitudeCircleView.addSubview(magnitudeIconView)
        
        depthInfoView.addSubview(depthIconView)
        depthInfoView.addSubview(depthLabel)
        
        magnitudeInfoView.addSubview(magnitudeIconView2)
        magnitudeInfoView.addSubview(magnitudeValueLabel)
        
        infoStackView.addArrangedSubview(depthInfoView)
        infoStackView.addArrangedSubview(magnitudeInfoView)
        
        containerView.addSubview(locationLabel)
        containerView.addSubview(dateTimeLabel)
        containerView.addSubview(magnitudeCircleView)
        containerView.addSubview(infoStackView)
        
        contentView.addSubview(containerView)
        
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            
            magnitudeCircleView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            magnitudeCircleView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            magnitudeCircleView.widthAnchor.constraint(equalToConstant: 52),
            magnitudeCircleView.heightAnchor.constraint(equalToConstant: 52),
            
            magnitudeIconView.centerXAnchor.constraint(equalTo: magnitudeCircleView.centerXAnchor),
            magnitudeIconView.centerYAnchor.constraint(equalTo: magnitudeCircleView.centerYAnchor),
            magnitudeIconView.widthAnchor.constraint(equalToConstant: 28),
            magnitudeIconView.heightAnchor.constraint(equalToConstant: 28),
            
            locationLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 16),
            locationLabel.leadingAnchor.constraint(equalTo: magnitudeCircleView.trailingAnchor, constant: 16),
            locationLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            
            dateTimeLabel.topAnchor.constraint(equalTo: locationLabel.bottomAnchor, constant: 8),
            dateTimeLabel.leadingAnchor.constraint(equalTo: magnitudeCircleView.trailingAnchor, constant: 16),
            dateTimeLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            
            infoStackView.topAnchor.constraint(equalTo: dateTimeLabel.bottomAnchor, constant: 12),
            infoStackView.leadingAnchor.constraint(equalTo: magnitudeCircleView.trailingAnchor, constant: 16),
            infoStackView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            infoStackView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -16),
            
            depthIconView.leadingAnchor.constraint(equalTo: depthInfoView.leadingAnchor),
            depthIconView.centerYAnchor.constraint(equalTo: depthInfoView.centerYAnchor),
            depthIconView.widthAnchor.constraint(equalToConstant: 16),
            depthIconView.heightAnchor.constraint(equalToConstant: 16),
            
            depthLabel.leadingAnchor.constraint(equalTo: depthIconView.trailingAnchor, constant: 8),
            depthLabel.centerYAnchor.constraint(equalTo: depthInfoView.centerYAnchor),
            depthLabel.trailingAnchor.constraint(equalTo: depthInfoView.trailingAnchor),
            
            magnitudeIconView2.leadingAnchor.constraint(equalTo: magnitudeInfoView.leadingAnchor),
            magnitudeIconView2.centerYAnchor.constraint(equalTo: magnitudeInfoView.centerYAnchor),
            magnitudeIconView2.widthAnchor.constraint(equalToConstant: 16),
            magnitudeIconView2.heightAnchor.constraint(equalToConstant: 16),
            
            magnitudeValueLabel.leadingAnchor.constraint(equalTo: magnitudeIconView2.trailingAnchor, constant: 8),
            magnitudeValueLabel.centerYAnchor.constraint(equalTo: magnitudeInfoView.centerYAnchor),
            magnitudeValueLabel.trailingAnchor.constraint(equalTo: magnitudeInfoView.trailingAnchor)
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
        
        // Update magnitude circle color based on magnitude
        if magValue >= 5.0 {
            magnitudeCircleView.backgroundColor = UIColor(red: 231.0/255.0, green: 76.0/255.0, blue: 60.0/255.0, alpha: 1.0) // Kırmızı
            magnitudeIconView.image = UIImage(systemName: "exclamationmark.triangle.fill")
            magnitudeValueLabel.textColor = UIColor(red: 231.0/255.0, green: 76.0/255.0, blue: 60.0/255.0, alpha: 1.0) // Kırmızı
        } else if magValue >= 4.0 {
            magnitudeCircleView.backgroundColor = UIColor(red: 230.0/255.0, green: 126.0/255.0, blue: 34.0/255.0, alpha: 1.0) // Turuncu
            magnitudeIconView.image = UIImage(systemName: "exclamationmark")
            magnitudeValueLabel.textColor = UIColor(red: 230.0/255.0, green: 126.0/255.0, blue: 34.0/255.0, alpha: 1.0) // Turuncu
        } else {
            magnitudeCircleView.backgroundColor = UIColor(red: 52.0/255.0, green: 152.0/255.0, blue: 219.0/255.0, alpha: 1.0) // Mavi
            magnitudeIconView.image = UIImage(systemName: "waveform.path.ecg")
            magnitudeValueLabel.textColor = UIColor(red: 52.0/255.0, green: 152.0/255.0, blue: 219.0/255.0, alpha: 1.0) // Mavi
        }
        
        // Hareketli animasyon
        magnitudeValueLabel.text = "\(magnitude) ML"
        depthLabel.text = "\(earthquake.depth_km) km"
        
        // Hafif bir cell animasyonu
        containerView.transform = CGAffineTransform(scaleX: 0.98, y: 0.98)
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseOut, animations: {
            self.containerView.transform = CGAffineTransform.identity
            self.containerView.alpha = 1.0
        })
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        containerView.alpha = 0.8
    }
}

// MARK: - EarthquakeDetailsViewController
class EarthquakeDetailsViewController: UIViewController {
    
    private let earthquake: Earthquake
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
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        backgroundGradientLayer.frame = view.bounds
    }
    
    private func setupUI() {
        title = "Deprem Detayları"
        view.backgroundColor = .clear
        view.layer.insertSublayer(backgroundGradientLayer, at: 0)
        
        mapView.translatesAutoresizingMaskIntoConstraints = false
        mapView.layer.cornerRadius = 16
        mapView.clipsToBounds = true
        view.addSubview(mapView)
        
        contentView.translatesAutoresizingMaskIntoConstraints = false
        contentView.backgroundColor = UIColor(red: 0.0/255.0, green: 30.0/255.0, blue: 60.0/255.0, alpha: 1.0)
        contentView.layer.cornerRadius = 24
        contentView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        contentView.layer.shadowColor = UIColor.black.cgColor
        contentView.layer.shadowOffset = CGSize(width: 0, height: -4)
        contentView.layer.shadowRadius = 6
        contentView.layer.shadowOpacity = 0.2
        view.addSubview(contentView)
        
        setupContentView()
        
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
        
        NSLayoutConstraint.activate([
            mapView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            mapView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            mapView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            mapView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.4),
            
            contentView.topAnchor.constraint(equalTo: mapView.bottomAnchor, constant: -20),
            contentView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
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
        
        addSectionToStackView(
            stackView: stackView,
            sectionTitle: "Konum",
            content: earthquake.location,
            imageName: "mappin.and.ellipse"
        )
        
        addSectionToStackView(
            stackView: stackView,
            sectionTitle: "Tarih ve Saat",
            content: "\(earthquake.date) \(earthquake.time)",
            imageName: "calendar"
        )
        
        addSectionToStackView(
            stackView: stackView,
            sectionTitle: "Koordinatlar",
            content: "Enlem: \(earthquake.latitude)\nBoylam: \(earthquake.longitude)",
            imageName: "location.circle"
        )
        
        let magnitudeValue = getMagnitudeValue()
        let magnitudeString = String(format: "ML: %.1f", magnitudeValue)
        
        addSectionToStackView(
            stackView: stackView,
            sectionTitle: "Büyüklük",
            content: magnitudeString,
            imageName: "waveform.path.ecg",
            detailsColor: getMagnitudeColor(for: magnitudeValue)
        )
        
        addSectionToStackView(
            stackView: stackView,
            sectionTitle: "Derinlik",
            content: "\(earthquake.depth_km) km",
            imageName: "arrow.down.circle"
        )
        
        addInformationSection(stackView: stackView)
    }
    
    private func getMagnitudeColor(for magnitude: Double) -> UIColor {
        if magnitude >= 5.0 {
            return UIColor(red: 1.0, green: 0.4, blue: 0.4, alpha: 1.0) // Açık kırmızı
        } else if magnitude >= 4.0 {
            return UIColor(red: 1.0, green: 0.8, blue: 0.0, alpha: 1.0) // Sarı
        } else {
            return UIColor(red: 0.3, green: 0.8, blue: 0.3, alpha: 1.0) // Açık yeşil
        }
    }
    
    private func addSectionToStackView(stackView: UIStackView, sectionTitle: String, content: String, imageName: String, detailsColor: UIColor? = nil) {
        
        let sectionView = UIView()
        sectionView.translatesAutoresizingMaskIntoConstraints = false
        sectionView.backgroundColor = UIColor.white.withAlphaComponent(0.1)
        sectionView.layer.cornerRadius = 16
        
        let iconView = UIImageView(image: UIImage(systemName: imageName))
        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.contentMode = .scaleAspectFit
        iconView.tintColor = .white
        
        let titleLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = sectionTitle
        titleLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        titleLabel.textColor = .white.withAlphaComponent(0.8)
        
        let contentLabel = UILabel()
        contentLabel.translatesAutoresizingMaskIntoConstraints = false
        contentLabel.text = content
        contentLabel.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        contentLabel.textColor = detailsColor ?? .white
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
        infoView.backgroundColor = UIColor(red: 0.0/255.0, green: 60.0/255.0, blue: 120.0/255.0, alpha: 0.5)
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
        
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.backgroundColor = UIColor.white.withAlphaComponent(0.1)
        containerView.layer.cornerRadius = 16
        
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        imageView.image = image
        imageView.tintColor = .white
        
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = title
        titleLabel.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        titleLabel.textColor = .white
        titleLabel.textAlignment = .center
        
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        messageLabel.text = message
        messageLabel.font = UIFont.systemFont(ofSize: 14)
        messageLabel.textColor = .white.withAlphaComponent(0.9)
        messageLabel.textAlignment = .center
        messageLabel.numberOfLines = 0
        
        containerView.addSubview(imageView)
        containerView.addSubview(titleLabel)
        containerView.addSubview(messageLabel)
        addSubview(containerView)
        
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
