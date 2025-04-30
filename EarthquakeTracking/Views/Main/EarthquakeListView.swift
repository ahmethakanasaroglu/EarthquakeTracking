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
        tableView.register(EarthquakeCell.self, forCellReuseIdentifier: "EarthquakeCell")
        tableView.estimatedRowHeight = 100
        tableView.rowHeight = UITableView.automaticDimension
        return tableView
    }()
    
    private lazy var activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.hidesWhenStopped = true
        return indicator
    }()
    
    private lazy var refreshControl: UIRefreshControl = {
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(refreshData), for: .valueChanged)
        return refreshControl
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupBindings()
        fetchEarthquakes()
    }
    
    private func setupUI() {
        title = "Depremler"
        view.backgroundColor = .systemBackground
        
        tableView.refreshControl = refreshControl
        
        view.addSubview(tableView)
        view.addSubview(activityIndicator)
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
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
            .sink { [weak self] _ in
                self?.tableView.reloadData()
            }
            .store(in: &cancellables)
        
        viewModel.$isLoading
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isLoading in
                if isLoading {
                    self?.activityIndicator.startAnimating()
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
        
        alertController.addAction(dateAction)
        alertController.addAction(magnitudeAction)
        alertController.addAction(cancelAction)
        
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
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "EarthquakeCell", for: indexPath) as? EarthquakeCell else {
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
}

// MARK: - EarthquakeCell
class EarthquakeCell: UITableViewCell {
    
    private let locationLabel = UILabel()
    private let dateTimeLabel = UILabel()
    private let magnitudeLabel = UILabel()
    private let depthLabel = UILabel()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        locationLabel.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        locationLabel.numberOfLines = 0
        
        dateTimeLabel.font = UIFont.systemFont(ofSize: 14)
        dateTimeLabel.textColor = .secondaryLabel
        
        magnitudeLabel.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        
        depthLabel.font = UIFont.systemFont(ofSize: 14)
        depthLabel.textColor = .systemRed
        
        let stackView = UIStackView(arrangedSubviews: [
            locationLabel,
            dateTimeLabel,
            createInfoStackView()
        ])
        stackView.axis = .vertical
        stackView.spacing = 8
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        contentView.addSubview(stackView)
        
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            stackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12)
        ])
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
    
    func configure(with earthquake: Earthquake) {
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
    }
}
