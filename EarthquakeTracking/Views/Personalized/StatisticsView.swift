import UIKit

class StatisticsViewController: UIViewController {
    
    // MARK: - Properties
    private var earthquakeViewModel = EarthquakeListViewModel()
    private var viewComponents: [UIView] = []
    
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    
    private let headerView = UIView()
    private let headerLabel = UILabel()
    private let headerDescriptionLabel = UILabel()
    
    private let summaryView = UIView()
    private let summaryStatsStackView = UIStackView()
    
    private let regionChartContainerView = UIView()
    private let regionChartTitleLabel = UILabel()
    private let regionChartView = UIView()
    
    private let magnitudeChartContainerView = UIView()
    private let magnitudeChartTitleLabel = UILabel()
    private let magnitudeChartView = UIView()
    
    private let depthDistributionChartContainerView = UIView()
    private let depthChartTitleLabel = UILabel()
    private let depthChartView = UIView()
    
    private let timelineChartContainerView = UIView()
    private let timelineChartTitleLabel = UILabel()
    private let timelineChartView = UIView()
    
    private let activityIndicator = UIActivityIndicatorView(style: .large)
    
    // MARK: - Data Properties
    private var regionCountData: [(region: String, count: Int)] = []
    private var magnitudeDistributionData: [(range: String, count: Int)] = []
    private var depthDistributionData: [(range: String, count: Int)] = []
    private var timelineData: [(date: String, count: Int)] = []
    
    private var totalEarthquakes: Int = 0
    private var averageMagnitude: Double = 0
    private var maxMagnitude: Double = 0
    private var averageDepth: Double = 0
    private var mostActiveRegion: String = ""
    
    // MARK: - Initialization
    init(viewModel: PersonalizedViewModel) {
        super.init(nibName: nil, bundle: nil)
        // Bu constructor viewModel'i kullanmıyor, sadece uyumluluk için burada
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupBindings()
        fetchEarthquakeData()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if !activityIndicator.isAnimating {
            animateViewComponents()
        } else {
            
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(animateAfterDataLoaded),
                name: EarthquakeListViewModel.earthquakesUpdatedNotification,
                object: nil
            )
        }
    }
    
    @objc private func animateAfterDataLoaded() {
        
        NotificationCenter.default.removeObserver(
            self,
            name: EarthquakeListViewModel.earthquakesUpdatedNotification,
            object: nil
        )
        
        // Ana thread'de animasyonu başlat
        DispatchQueue.main.async { [weak self] in
            self?.animateViewComponents()
        }
    }
    
    private func animateViewComponents() {
        
        for (index, component) in viewComponents.enumerated() {
            
            let delay = Double(index) * 0.15
            
            UIView.animate(withDuration: 0.6, delay: delay, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.5, options: [], animations: {
                component.alpha = 1.0
                component.transform = .identity
            }, completion: nil)
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Setup Methods
    private func setupUI() {
        title = "Deprem İstatistikleri"
        view.backgroundColor = AppTheme.backgroundColor
        
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        
        headerView.translatesAutoresizingMaskIntoConstraints = false
        headerView.backgroundColor = AppTheme.indigoColor
        headerView.layer.cornerRadius = 16
        
        headerLabel.translatesAutoresizingMaskIntoConstraints = false
        headerLabel.text = "Deprem Veri Analizi"
        headerLabel.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        headerLabel.textColor = .white
        
        headerDescriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        headerDescriptionLabel.text = "Türkiye'deki son depremlerin bölgesel ve büyüklük dağılımı istatistikleri"
        headerDescriptionLabel.font = UIFont.systemFont(ofSize: 14)
        headerDescriptionLabel.textColor = .white.withAlphaComponent(0.9)
        headerDescriptionLabel.numberOfLines = 0
        
        summaryView.translatesAutoresizingMaskIntoConstraints = false
        AppTheme.applyCardStyle(to: summaryView)
        
        summaryStatsStackView.translatesAutoresizingMaskIntoConstraints = false
        summaryStatsStackView.axis = .horizontal
        summaryStatsStackView.distribution = .fillEqually
        summaryStatsStackView.spacing = 10
        
        regionChartContainerView.translatesAutoresizingMaskIntoConstraints = false
        AppTheme.applyCardStyle(to: regionChartContainerView)
        
        regionChartTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        regionChartTitleLabel.text = "Bölgesel Deprem Dağılımı"
        regionChartTitleLabel.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        regionChartTitleLabel.textColor = AppTheme.titleTextColor
        
        regionChartView.translatesAutoresizingMaskIntoConstraints = false
        regionChartView.backgroundColor = .white
        
        magnitudeChartContainerView.translatesAutoresizingMaskIntoConstraints = false
        AppTheme.applyCardStyle(to: magnitudeChartContainerView)
        
        magnitudeChartTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        magnitudeChartTitleLabel.text = "Deprem Büyüklüğü Dağılımı"
        magnitudeChartTitleLabel.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        magnitudeChartTitleLabel.textColor = AppTheme.titleTextColor
        
        magnitudeChartView.translatesAutoresizingMaskIntoConstraints = false
        magnitudeChartView.backgroundColor = .white
        
        depthDistributionChartContainerView.translatesAutoresizingMaskIntoConstraints = false
        AppTheme.applyCardStyle(to: depthDistributionChartContainerView)
        
        depthChartTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        depthChartTitleLabel.text = "Deprem Derinliği Dağılımı"
        depthChartTitleLabel.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        depthChartTitleLabel.textColor = AppTheme.titleTextColor
        
        depthChartView.translatesAutoresizingMaskIntoConstraints = false
        depthChartView.backgroundColor = .white
        
        timelineChartContainerView.translatesAutoresizingMaskIntoConstraints = false
        AppTheme.applyCardStyle(to: timelineChartContainerView)
        
        timelineChartTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        timelineChartTitleLabel.text = "Zamana Göre Deprem Aktivitesi"
        timelineChartTitleLabel.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        timelineChartTitleLabel.textColor = AppTheme.titleTextColor
        
        timelineChartView.translatesAutoresizingMaskIntoConstraints = false
        timelineChartView.backgroundColor = .white
        
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        activityIndicator.color = AppTheme.indigoColor
        activityIndicator.hidesWhenStopped = true
        activityIndicator.startAnimating()
        
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        contentView.addSubview(headerView)
        headerView.addSubview(headerLabel)
        headerView.addSubview(headerDescriptionLabel)
        
        contentView.addSubview(summaryView)
        summaryView.addSubview(summaryStatsStackView)
        
        contentView.addSubview(regionChartContainerView)
        regionChartContainerView.addSubview(regionChartTitleLabel)
        regionChartContainerView.addSubview(regionChartView)
        
        contentView.addSubview(magnitudeChartContainerView)
        magnitudeChartContainerView.addSubview(magnitudeChartTitleLabel)
        magnitudeChartContainerView.addSubview(magnitudeChartView)
        
        contentView.addSubview(depthDistributionChartContainerView)
        depthDistributionChartContainerView.addSubview(depthChartTitleLabel)
        depthDistributionChartContainerView.addSubview(depthChartView)
        
        contentView.addSubview(timelineChartContainerView)
        timelineChartContainerView.addSubview(timelineChartTitleLabel)
        timelineChartContainerView.addSubview(timelineChartView)
        
        view.addSubview(activityIndicator)
        
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
            
            headerLabel.topAnchor.constraint(equalTo: headerView.topAnchor, constant: 16),
            headerLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 16),
            headerLabel.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -16),
            
            headerDescriptionLabel.topAnchor.constraint(equalTo: headerLabel.bottomAnchor, constant: 8),
            headerDescriptionLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 16),
            headerDescriptionLabel.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -16),
            headerDescriptionLabel.bottomAnchor.constraint(equalTo: headerView.bottomAnchor, constant: -16),
            
            summaryView.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 16),
            summaryView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            summaryView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            summaryStatsStackView.topAnchor.constraint(equalTo: summaryView.topAnchor, constant: 16),
            summaryStatsStackView.leadingAnchor.constraint(equalTo: summaryView.leadingAnchor, constant: 16),
            summaryStatsStackView.trailingAnchor.constraint(equalTo: summaryView.trailingAnchor, constant: -16),
            summaryStatsStackView.bottomAnchor.constraint(equalTo: summaryView.bottomAnchor, constant: -16),
            
            regionChartContainerView.topAnchor.constraint(equalTo: summaryView.bottomAnchor, constant: 16),
            regionChartContainerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            regionChartContainerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            regionChartContainerView.heightAnchor.constraint(equalToConstant: 350),
            
            regionChartTitleLabel.topAnchor.constraint(equalTo: regionChartContainerView.topAnchor, constant: 16),
            regionChartTitleLabel.leadingAnchor.constraint(equalTo: regionChartContainerView.leadingAnchor, constant: 16),
            regionChartTitleLabel.trailingAnchor.constraint(equalTo: regionChartContainerView.trailingAnchor, constant: -16),
            
            regionChartView.topAnchor.constraint(equalTo: regionChartTitleLabel.bottomAnchor, constant: 16),
            regionChartView.leadingAnchor.constraint(equalTo: regionChartContainerView.leadingAnchor, constant: 16),
            regionChartView.trailingAnchor.constraint(equalTo: regionChartContainerView.trailingAnchor, constant: -16),
            regionChartView.bottomAnchor.constraint(equalTo: regionChartContainerView.bottomAnchor, constant: -16),
            
            magnitudeChartContainerView.topAnchor.constraint(equalTo: regionChartContainerView.bottomAnchor, constant: 16),
            magnitudeChartContainerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            magnitudeChartContainerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            magnitudeChartContainerView.heightAnchor.constraint(equalToConstant: 350),
            
            magnitudeChartTitleLabel.topAnchor.constraint(equalTo: magnitudeChartContainerView.topAnchor, constant: 16),
            magnitudeChartTitleLabel.leadingAnchor.constraint(equalTo: magnitudeChartContainerView.leadingAnchor, constant: 16),
            magnitudeChartTitleLabel.trailingAnchor.constraint(equalTo: magnitudeChartContainerView.trailingAnchor, constant: -16),
            
            magnitudeChartView.topAnchor.constraint(equalTo: magnitudeChartTitleLabel.bottomAnchor, constant: 16),
            magnitudeChartView.leadingAnchor.constraint(equalTo: magnitudeChartContainerView.leadingAnchor, constant: 16),
            magnitudeChartView.trailingAnchor.constraint(equalTo: magnitudeChartContainerView.trailingAnchor, constant: -16),
            magnitudeChartView.bottomAnchor.constraint(equalTo: magnitudeChartContainerView.bottomAnchor, constant: -16),
            
            depthDistributionChartContainerView.topAnchor.constraint(equalTo: magnitudeChartContainerView.bottomAnchor, constant: 16),
            depthDistributionChartContainerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            depthDistributionChartContainerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            depthDistributionChartContainerView.heightAnchor.constraint(equalToConstant: 350),
            
            depthChartTitleLabel.topAnchor.constraint(equalTo: depthDistributionChartContainerView.topAnchor, constant: 16),
            depthChartTitleLabel.leadingAnchor.constraint(equalTo: depthDistributionChartContainerView.leadingAnchor, constant: 16),
            depthChartTitleLabel.trailingAnchor.constraint(equalTo: depthDistributionChartContainerView.trailingAnchor, constant: -16),
            
            depthChartView.topAnchor.constraint(equalTo: depthChartTitleLabel.bottomAnchor, constant: 16),
            depthChartView.leadingAnchor.constraint(equalTo: depthDistributionChartContainerView.leadingAnchor, constant: 16),
            depthChartView.trailingAnchor.constraint(equalTo: depthDistributionChartContainerView.trailingAnchor, constant: -16),
            depthChartView.bottomAnchor.constraint(equalTo: depthDistributionChartContainerView.bottomAnchor, constant: -16),
            
            timelineChartContainerView.topAnchor.constraint(equalTo: depthDistributionChartContainerView.bottomAnchor, constant: 16),
            timelineChartContainerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            timelineChartContainerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            timelineChartContainerView.heightAnchor.constraint(equalToConstant: 350),
            timelineChartContainerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16),
            
            timelineChartTitleLabel.topAnchor.constraint(equalTo: timelineChartContainerView.topAnchor, constant: 16),
            timelineChartTitleLabel.leadingAnchor.constraint(equalTo: timelineChartContainerView.leadingAnchor, constant: 16),
            timelineChartTitleLabel.trailingAnchor.constraint(equalTo: timelineChartContainerView.trailingAnchor, constant: -16),
            
            timelineChartView.topAnchor.constraint(equalTo: timelineChartTitleLabel.bottomAnchor, constant: 16),
            timelineChartView.leadingAnchor.constraint(equalTo: timelineChartContainerView.leadingAnchor, constant: 16),
            timelineChartView.trailingAnchor.constraint(equalTo: timelineChartContainerView.trailingAnchor, constant: -16),
            timelineChartView.bottomAnchor.constraint(equalTo: timelineChartContainerView.bottomAnchor, constant: -16),
            
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        
        viewComponents = [
            headerView,
            summaryView,
            regionChartContainerView,
            magnitudeChartContainerView,
            depthDistributionChartContainerView,
            timelineChartContainerView
        ]
        
        for component in viewComponents {
            component.alpha = 0
            
            component.transform = CGAffineTransform(translationX: 0, y: -50)
        }
    }
    
    private func setupBindings() {
        
        earthquakeViewModel.delegate = self
        
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
            guard let self = self, !self.earthquakeViewModel.earthquakes.isEmpty else { return }
            self.processEarthquakeData(self.earthquakeViewModel.earthquakes)
            self.createSummaryStats()
            self.createCharts()
            self.activityIndicator.stopAnimating()
            
            if self.isViewLoaded && self.view.window != nil {
                self.animateViewComponents()
            }
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
    
    @objc private func handleErrorReceived(_ notification: Notification) {
        if let errorMessage = notification.userInfo?["errorMessage"] as? String {
            DispatchQueue.main.async { [weak self] in
                self?.showError(message: errorMessage)
            }
        }
    }
    
    private func fetchEarthquakeData() {
        earthquakeViewModel.fetchEarthquakes()
    }
    
    // MARK: - Data Processing
    private func processEarthquakeData(_ earthquakes: [Earthquake]) {
        
        totalEarthquakes = earthquakes.count
        var regionCounts: [String: Int] = [:]
        var magnitudeCounts: [String: Int] = [:]
        var depthCounts: [String: Int] = [:]
        var dateCounts: [String: Int] = [:]
        var totalMagnitude: Double = 0
        var totalDepth: Double = 0
        
        for earthquake in earthquakes {
            
            let locationComponents = earthquake.location.components(separatedBy: "-")
            let region = locationComponents.first?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "Diğer"
            regionCounts[region, default: 0] += 1
            
            let magnitude = getMagnitude(for: earthquake)
            totalMagnitude += magnitude
            maxMagnitude = max(maxMagnitude, magnitude)
            
            let magnitudeRange = getMagnitudeRange(for: magnitude)
            magnitudeCounts[magnitudeRange, default: 0] += 1
            
            let depth = Double(earthquake.depth_km) ?? 0
            totalDepth += depth
            
            let depthRange = getDepthRange(for: depth)
            depthCounts[depthRange, default: 0] += 1
            
            let date = earthquake.date
            dateCounts[date, default: 0] += 1
        }
        
        if totalEarthquakes > 0 {
            averageMagnitude = totalMagnitude / Double(totalEarthquakes)
            averageDepth = totalDepth / Double(totalEarthquakes)
        }
        
        if let topRegion = regionCounts.max(by: { $0.value < $1.value }) {
            mostActiveRegion = topRegion.key
        }
        
        regionCountData = regionCounts
            .sorted(by: { $0.value > $1.value })
            .prefix(10)
            .map { ($0.key, $0.value) }
        
        let magnitudeRanges = ["0-1.9", "2-2.9", "3-3.9", "4-4.9", "5-5.9", "6+"]
        magnitudeDistributionData = magnitudeRanges.map { range in
            (range, magnitudeCounts[range] ?? 0)
        }
        
        let depthRanges = ["0-5 km", "5-10 km", "10-20 km", "20-50 km", "50+ km"]
        depthDistributionData = depthRanges.map { range in
            (range, depthCounts[range] ?? 0)
        }
        
        timelineData = dateCounts.map { ($0.key, $0.value) }
            .sorted(by: { date1, date2 in
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy.MM.dd"
                guard let date1Obj = formatter.date(from: date1.date),
                      let date2Obj = formatter.date(from: date2.date) else {
                    return false
                }
                return date1Obj < date2Obj
            })
    }
    
    private func getMagnitude(for earthquake: Earthquake) -> Double {
        if let ml = Double(earthquake.ml), ml > 0 {
            return ml
        } else if let mw = Double(earthquake.mw), mw > 0 {
            return mw
        } else if let md = Double(earthquake.md), md > 0 {
            return md
        }
        return 0.0
    }
    
    private func getMagnitudeRange(for magnitude: Double) -> String {
        switch magnitude {
        case 0..<2:
            return "0-1.9"
        case 2..<3:
            return "2-2.9"
        case 3..<4:
            return "3-3.9"
        case 4..<5:
            return "4-4.9"
        case 5..<6:
            return "5-5.9"
        default:
            return "6+"
        }
    }
    
    private func getDepthRange(for depth: Double) -> String {
        switch depth {
        case 0..<5:
            return "0-5 km"
        case 5..<10:
            return "5-10 km"
        case 10..<20:
            return "10-20 km"
        case 20..<50:
            return "20-50 km"
        default:
            return "50+ km"
        }
    }
    
    // MARK: - Summary Statistics
    private func createSummaryStats() {
        
        summaryStatsStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        let totalQuakesView = createStatView(title: "Toplam Deprem", value: "\(totalEarthquakes)")
        let avgMagnitudeView = createStatView(title: "Ortalama Büyüklük", value: String(format: "%.1f", averageMagnitude))
        let maxMagnitudeView = createStatView(title: "En Büyük Deprem", value: String(format: "%.1f", maxMagnitude))
        let avgDepthView = createStatView(title: "Ortalama Derinlik", value: String(format: "%.1f", averageDepth))
        let activeRegionView = createStatView(title: "En Aktif Bölge", value: mostActiveRegion)
        
        summaryStatsStackView.addArrangedSubview(totalQuakesView)
        summaryStatsStackView.addArrangedSubview(avgMagnitudeView)
        summaryStatsStackView.addArrangedSubview(maxMagnitudeView)
        summaryStatsStackView.addArrangedSubview(avgDepthView)
        summaryStatsStackView.addArrangedSubview(activeRegionView)
    }
    
    private func createStatView(title: String, value: String) -> UIView {
        let containerView = UIView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.spacing = 4
        
        let valueLabel = UILabel()
        valueLabel.translatesAutoresizingMaskIntoConstraints = false
        valueLabel.text = value
        valueLabel.font = UIFont.systemFont(ofSize: 20, weight: .bold)
        valueLabel.textColor = AppTheme.indigoColor
        valueLabel.textAlignment = .center
        
        let titleLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = title
        titleLabel.font = UIFont.systemFont(ofSize: 12)
        titleLabel.textColor = AppTheme.bodyTextColor
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 2
        
        stackView.addArrangedSubview(valueLabel)
        stackView.addArrangedSubview(titleLabel)
        containerView.addSubview(stackView)
        
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: containerView.topAnchor),
            stackView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])
        
        return containerView
    }
    
    // MARK: - Chart Creation
    private func createCharts() {
        createRegionBarChart()
        createMagnitudePieChart()
        createDepthBarChart()
        createTimelineChart()
    }
    
    private func createRegionBarChart() {
        
        regionChartView.subviews.forEach { $0.removeFromSuperview() }
        
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.spacing = 8
        stackView.distribution = .fillEqually
        
        regionChartView.addSubview(stackView)
        
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: regionChartView.topAnchor, constant: 8),
            stackView.leadingAnchor.constraint(equalTo: regionChartView.leadingAnchor, constant: 8),
            stackView.trailingAnchor.constraint(equalTo: regionChartView.trailingAnchor, constant: -8),
            stackView.bottomAnchor.constraint(equalTo: regionChartView.bottomAnchor, constant: -8)
        ])
        
        for (index, data) in regionCountData.prefix(7).enumerated() {
            let barView = createBarView(title: data.region, value: data.count, maxValue: regionCountData.first?.count ?? 100, color: AppTheme.indigoColor)
            stackView.addArrangedSubview(barView)
        }
    }
    
    private func createMagnitudePieChart() {
        
        magnitudeChartView.subviews.forEach { $0.removeFromSuperview() }
        
        let legendStackView = UIStackView()
        legendStackView.translatesAutoresizingMaskIntoConstraints = false
        legendStackView.axis = .vertical
        legendStackView.spacing = 8
        legendStackView.distribution = .fillEqually
        
        magnitudeChartView.addSubview(legendStackView)
        
        NSLayoutConstraint.activate([
            legendStackView.centerYAnchor.constraint(equalTo: magnitudeChartView.centerYAnchor),
            legendStackView.leadingAnchor.constraint(equalTo: magnitudeChartView.leadingAnchor, constant: 16),
            legendStackView.trailingAnchor.constraint(equalTo: magnitudeChartView.trailingAnchor, constant: -16),
            legendStackView.heightAnchor.constraint(equalToConstant: 200)
        ])
        
        let colors = [
            UIColor(red: 0.0, green: 0.7, blue: 0.0, alpha: 1.0), // 0-1.9: Yeşil
            UIColor(red: 0.6, green: 0.8, blue: 0.0, alpha: 1.0), // 2-2.9: Lime yeş
            UIColor(red: 0.8, green: 0.8, blue: 0.0, alpha: 1.0), // 3-3.9: Sarı
            UIColor(red: 0.9, green: 0.6, blue: 0.0, alpha: 1.0), // 4-4.9: Turuncu
            UIColor(red: 1.0, green: 0.4, blue: 0.0, alpha: 1.0), // 5-5.9: Koyu turuncu
            UIColor(red: 1.0, green: 0.0, blue: 0.0, alpha: 1.0)  // 6+: Kırmızı
        ]
        
        for (index, data) in magnitudeDistributionData.enumerated() {
            if index < colors.count {
                let colorLegendView = createColorLegendView(title: "\(data.range): \(data.count) deprem", color: colors[index])
                legendStackView.addArrangedSubview(colorLegendView)
            }
        }
        
        let pieView = UIView()
        pieView.translatesAutoresizingMaskIntoConstraints = false
        magnitudeChartView.addSubview(pieView)
        
        NSLayoutConstraint.activate([
            pieView.topAnchor.constraint(equalTo: magnitudeChartView.topAnchor, constant: 16),
            pieView.leadingAnchor.constraint(equalTo: magnitudeChartView.leadingAnchor, constant: 16),
            pieView.heightAnchor.constraint(equalToConstant: 44),
            pieView.widthAnchor.constraint(equalToConstant: magnitudeChartView.bounds.width - 32)
        ])
        
        let totalCount = magnitudeDistributionData.reduce(0) { $0 + $1.count }
        var currentX: CGFloat = 0
        
        for (index, data) in magnitudeDistributionData.enumerated() {
            if index < colors.count && totalCount > 0 {
                let ratio = CGFloat(data.count) / CGFloat(totalCount)
                let width = ratio * (magnitudeChartView.bounds.width - 32)
                
                let segmentView = UIView(frame: CGRect(x: currentX, y: 0, width: width, height: 44))
                segmentView.backgroundColor = colors[index]
                
                if index == 0 {
                    
                    segmentView.layer.cornerRadius = 8
                    segmentView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMinXMaxYCorner]
                } else if index == colors.count - 1 || index == magnitudeDistributionData.count - 1 {
                    
                    segmentView.layer.cornerRadius = 8
                    segmentView.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMaxXMaxYCorner]
                }
                
                pieView.addSubview(segmentView)
                currentX += width
            }
        }
    }
    
    private func createDepthBarChart() {
        
        depthChartView.subviews.forEach { $0.removeFromSuperview() }
        
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.spacing = 16
        stackView.distribution = .fillEqually
        
        depthChartView.addSubview(stackView)
        
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: depthChartView.topAnchor, constant: 16),
            stackView.leadingAnchor.constraint(equalTo: depthChartView.leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: depthChartView.trailingAnchor, constant: -16),
            stackView.bottomAnchor.constraint(equalTo: depthChartView.bottomAnchor, constant: -16)
        ])
        
        let maxDepthCount = depthDistributionData.map { $0.count }.max() ?? 100
        
        for data in depthDistributionData {
            let barView = createBarView(title: data.range, value: data.count, maxValue: maxDepthCount, color: AppTheme.secondaryColor)
            stackView.addArrangedSubview(barView)
        }
    }
    
    private func createTimelineChart() {
        
        timelineChartView.subviews.forEach { $0.removeFromSuperview() }
        
        let timelineStackView = UIStackView()
        timelineStackView.translatesAutoresizingMaskIntoConstraints = false
        timelineStackView.axis = .vertical
        timelineStackView.spacing = 8
        timelineStackView.distribution = .fill
        
        timelineChartView.addSubview(timelineStackView)
        
        NSLayoutConstraint.activate([
            timelineStackView.topAnchor.constraint(equalTo: timelineChartView.topAnchor, constant: 16),
            timelineStackView.leadingAnchor.constraint(equalTo: timelineChartView.leadingAnchor, constant: 16),
            timelineStackView.trailingAnchor.constraint(equalTo: timelineChartView.trailingAnchor, constant: -16),
            timelineStackView.bottomAnchor.constraint(equalTo: timelineChartView.bottomAnchor, constant: -16)
        ])
        
        let summaryLabel = UILabel()
        summaryLabel.translatesAutoresizingMaskIntoConstraints = false
        summaryLabel.text = "Son \(timelineData.count) günde toplam \(timelineData.reduce(0) { $0 + $1.count }) deprem gerçekleşti."
        summaryLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        summaryLabel.textColor = AppTheme.titleTextColor
        summaryLabel.textAlignment = .center
        summaryLabel.numberOfLines = 0
        
        timelineStackView.addArrangedSubview(summaryLabel)
        
        let timelineDataView = UIView()
        timelineDataView.translatesAutoresizingMaskIntoConstraints = false
        timelineDataView.backgroundColor = AppTheme.backgroundColor
        timelineDataView.layer.cornerRadius = 8
        
        timelineStackView.addArrangedSubview(timelineDataView)
        
        let maxTimeLineHeight: CGFloat = 180
        timelineDataView.heightAnchor.constraint(equalToConstant: maxTimeLineHeight).isActive = true
        
        let recentTimelineData = Array(timelineData.suffix(min(7, timelineData.count)))
        
        if !recentTimelineData.isEmpty {
            let maxCount = recentTimelineData.map { $0.count }.max() ?? 1
            
            let dataStackView = UIStackView()
            dataStackView.translatesAutoresizingMaskIntoConstraints = false
            dataStackView.axis = .horizontal
            dataStackView.distribution = .fillEqually
            dataStackView.spacing = 4
            
            timelineDataView.addSubview(dataStackView)
            
            NSLayoutConstraint.activate([
                dataStackView.leadingAnchor.constraint(equalTo: timelineDataView.leadingAnchor, constant: 8),
                dataStackView.trailingAnchor.constraint(equalTo: timelineDataView.trailingAnchor, constant: -8),
                dataStackView.bottomAnchor.constraint(equalTo: timelineDataView.bottomAnchor, constant: -24),
                dataStackView.topAnchor.constraint(equalTo: timelineDataView.topAnchor, constant: 8)
            ])
            
            for data in recentTimelineData {
                let barView = UIView()
                barView.translatesAutoresizingMaskIntoConstraints = false
                
                let dateLabel = UILabel()
                dateLabel.translatesAutoresizingMaskIntoConstraints = false
                dateLabel.text = formatDate(data.date)
                dateLabel.font = UIFont.systemFont(ofSize: 10)
                dateLabel.textColor = AppTheme.bodyTextColor
                dateLabel.textAlignment = .center
                
                let barFillView = UIView()
                barFillView.translatesAutoresizingMaskIntoConstraints = false
                barFillView.backgroundColor = AppTheme.accentColor
                barFillView.layer.cornerRadius = 4
                
                let countLabel = UILabel()
                countLabel.translatesAutoresizingMaskIntoConstraints = false
                countLabel.text = "\(data.count)"
                countLabel.font = UIFont.systemFont(ofSize: 12, weight: .bold)
                countLabel.textColor = .white
                countLabel.textAlignment = .center
                
                barView.addSubview(dateLabel)
                barView.addSubview(barFillView)
                barFillView.addSubview(countLabel)
                
                dataStackView.addArrangedSubview(barView)
                
                let barHeight = CGFloat(data.count) / CGFloat(maxCount) * (maxTimeLineHeight - 40)
                
                NSLayoutConstraint.activate([
                    dateLabel.bottomAnchor.constraint(equalTo: barView.bottomAnchor),
                    dateLabel.leadingAnchor.constraint(equalTo: barView.leadingAnchor),
                    dateLabel.trailingAnchor.constraint(equalTo: barView.trailingAnchor),
                    dateLabel.heightAnchor.constraint(equalToConstant: 20),
                    
                    barFillView.bottomAnchor.constraint(equalTo: dateLabel.topAnchor, constant: -4),
                    barFillView.centerXAnchor.constraint(equalTo: barView.centerXAnchor),
                    barFillView.widthAnchor.constraint(equalTo: barView.widthAnchor, multiplier: 0.6),
                    barFillView.heightAnchor.constraint(equalToConstant: max(30, barHeight)),
                    
                    countLabel.centerXAnchor.constraint(equalTo: barFillView.centerXAnchor),
                    countLabel.centerYAnchor.constraint(equalTo: barFillView.centerYAnchor)
                ])
            }
        }
    }
    
    // MARK: - Helper Methods
    private func createBarView(title: String, value: Int, maxValue: Int, color: UIColor) -> UIView {
        let barView = UIView()
        barView.translatesAutoresizingMaskIntoConstraints = false
        
        let titleLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = title
        titleLabel.font = UIFont.systemFont(ofSize: 14)
        titleLabel.textColor = AppTheme.bodyTextColor
        
        let barContainerView = UIView()
        barContainerView.translatesAutoresizingMaskIntoConstraints = false
        barContainerView.backgroundColor = UIColor.systemGray6
        barContainerView.layer.cornerRadius = 4
        
        let barFillView = UIView()
        barFillView.translatesAutoresizingMaskIntoConstraints = false
        barFillView.backgroundColor = color
        barFillView.layer.cornerRadius = 4
        
        let valueBackground = UIView()
        valueBackground.translatesAutoresizingMaskIntoConstraints = false
        valueBackground.backgroundColor = color.withAlphaComponent(0.9)
        valueBackground.layer.cornerRadius = 10
        
        let valueLabel = UILabel()
        valueLabel.translatesAutoresizingMaskIntoConstraints = false
        valueLabel.text = "\(value)"
        valueLabel.font = UIFont.systemFont(ofSize: 12, weight: .bold)
        valueLabel.textColor = .white
        valueLabel.textAlignment = .center
        
        barView.addSubview(titleLabel)
        barView.addSubview(barContainerView)
        barContainerView.addSubview(barFillView)
        
        let fillWidth = value > 0 ? CGFloat(value) / CGFloat(maxValue) : 0.01
        
        if fillWidth < 0.15 {
            
            barView.addSubview(valueBackground)
            valueBackground.addSubview(valueLabel)
            
            NSLayoutConstraint.activate([
                valueBackground.leadingAnchor.constraint(equalTo: barFillView.trailingAnchor, constant: 4),
                valueBackground.centerYAnchor.constraint(equalTo: barFillView.centerYAnchor),
                valueBackground.heightAnchor.constraint(equalToConstant: 20),
                valueBackground.widthAnchor.constraint(greaterThanOrEqualToConstant: 36),
                
                valueLabel.topAnchor.constraint(equalTo: valueBackground.topAnchor),
                valueLabel.leadingAnchor.constraint(equalTo: valueBackground.leadingAnchor, constant: 6),
                valueLabel.trailingAnchor.constraint(equalTo: valueBackground.trailingAnchor, constant: -6),
                valueLabel.bottomAnchor.constraint(equalTo: valueBackground.bottomAnchor)
            ])
        } else {
            
            barFillView.addSubview(valueLabel)
            
            NSLayoutConstraint.activate([
                valueLabel.centerYAnchor.constraint(equalTo: barFillView.centerYAnchor),
                valueLabel.trailingAnchor.constraint(equalTo: barFillView.trailingAnchor, constant: -8),
            ])
        }
        
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: barView.leadingAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: barView.centerYAnchor),
            titleLabel.widthAnchor.constraint(equalTo: barView.widthAnchor, multiplier: 0.4),
            
            barContainerView.leadingAnchor.constraint(equalTo: titleLabel.trailingAnchor, constant: 8),
            barContainerView.trailingAnchor.constraint(equalTo: barView.trailingAnchor),
            barContainerView.centerYAnchor.constraint(equalTo: barView.centerYAnchor),
            barContainerView.heightAnchor.constraint(equalToConstant: 24),
            
            barFillView.leadingAnchor.constraint(equalTo: barContainerView.leadingAnchor),
            barFillView.widthAnchor.constraint(equalTo: barContainerView.widthAnchor, multiplier: fillWidth),
            barFillView.topAnchor.constraint(equalTo: barContainerView.topAnchor),
            barFillView.bottomAnchor.constraint(equalTo: barContainerView.bottomAnchor)
        ])
        
        return barView
    }
    
    private func createColorLegendView(title: String, color: UIColor) -> UIView {
        let legendView = UIView()
        legendView.translatesAutoresizingMaskIntoConstraints = false
        
        let colorView = UIView()
        colorView.translatesAutoresizingMaskIntoConstraints = false
        colorView.backgroundColor = color
        colorView.layer.cornerRadius = 8
        
        let titleLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = title
        titleLabel.font = UIFont.systemFont(ofSize: 14)
        titleLabel.textColor = AppTheme.bodyTextColor
        titleLabel.numberOfLines = 0
        
        legendView.addSubview(colorView)
        legendView.addSubview(titleLabel)
        
        NSLayoutConstraint.activate([
            colorView.leadingAnchor.constraint(equalTo: legendView.leadingAnchor),
            colorView.centerYAnchor.constraint(equalTo: legendView.centerYAnchor),
            colorView.widthAnchor.constraint(equalToConstant: 16),
            colorView.heightAnchor.constraint(equalToConstant: 16),
            
            titleLabel.leadingAnchor.constraint(equalTo: colorView.trailingAnchor, constant: 8),
            titleLabel.trailingAnchor.constraint(equalTo: legendView.trailingAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: legendView.centerYAnchor)
        ])
        
        return legendView
    }
    
    private func formatDate(_ dateString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy.MM.dd"
        
        if let date = formatter.date(from: dateString) {
            formatter.dateFormat = "dd.MM"
            return formatter.string(from: date)
        }
        
        return dateString
    }
    
    // MARK: - Error Handling
    private func showError(message: String) {
        let alertController = UIAlertController(title: "Hata", message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "Tamam", style: .default)
        alertController.addAction(okAction)
        present(alertController, animated: true)
    }
}

// MARK: - EarthquakeListViewModelDelegate
extension StatisticsViewController: EarthquakeListViewModelDelegate {
    func didUpdateEarthquakes() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self, !self.earthquakeViewModel.earthquakes.isEmpty else { return }
            self.processEarthquakeData(self.earthquakeViewModel.earthquakes)
            self.createSummaryStats()
            self.createCharts()
            self.activityIndicator.stopAnimating()
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
