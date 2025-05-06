import UIKit
import Combine

class StatisticsViewController: UIViewController {
    
    // MARK: - Properties
    private let viewModel: PersonalizedViewModel
    private var earthquakeViewModel = EarthquakeListViewModel()
    private var cancellables = Set<AnyCancellable>()
    
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    
    private let headerView = UIView()
    private let headerLabel = UILabel()
    private let headerDescriptionLabel = UILabel()
    
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
    
    private var regionCountData: [(region: String, count: Int)] = []
    private var magnitudeDistributionData: [(range: String, count: Int)] = []
    private var depthDistributionData: [(range: String, count: Int)] = []
    private var timelineData: [(date: String, count: Int)] = []
    
    // MARK: - Initialization
    init(viewModel: PersonalizedViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
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
    
    // MARK: - Setup Methods
    private func setupUI() {
        title = "Deprem İstatistikleri"
        view.backgroundColor = AppTheme.backgroundColor
        
        // ScrollView setup
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        
        // Header setup
        headerView.translatesAutoresizingMaskIntoConstraints = false
        headerView.backgroundColor = AppTheme.primaryColor
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
        
        // Chart containers setup
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
        
        // Activity Indicator
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        activityIndicator.color = AppTheme.primaryColor
        activityIndicator.hidesWhenStopped = true
        activityIndicator.startAnimating()
        
        // Add views to hierarchy
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        contentView.addSubview(headerView)
        headerView.addSubview(headerLabel)
        headerView.addSubview(headerDescriptionLabel)
        
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
        
        // Setup constraints
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
            
            regionChartContainerView.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 16),
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
    }
    
    private func setupBindings() {
        earthquakeViewModel.$earthquakes
            .receive(on: DispatchQueue.main)
            .sink { [weak self] earthquakes in
                guard let self = self, !earthquakes.isEmpty else { return }
                self.processEarthquakeData(earthquakes)
                self.createCharts()
                self.activityIndicator.stopAnimating()
            }
            .store(in: &cancellables)
        
        earthquakeViewModel.$isLoading
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isLoading in
                if isLoading {
                    self?.activityIndicator.startAnimating()
                } else {
                    self?.activityIndicator.stopAnimating()
                }
            }
            .store(in: &cancellables)
        
        earthquakeViewModel.$errorMessage
            .receive(on: DispatchQueue.main)
            .compactMap { $0 }
            .sink { [weak self] message in
                self?.showError(message: message)
            }
            .store(in: &cancellables)
    }
    
    private func fetchEarthquakeData() {
        earthquakeViewModel.fetchEarthquakes()
    }
    
    // MARK: - Data Processing
    private func processEarthquakeData(_ earthquakes: [Earthquake]) {
        // Process region data (extract city/region from location)
        var regionCounts: [String: Int] = [:]
        var magnitudeCounts: [String: Int] = [:]
        var depthCounts: [String: Int] = [:]
        var dateCounts: [String: Int] = [:]
        
        for earthquake in earthquakes {
            // Extract region (first part of location string)
            let locationComponents = earthquake.location.components(separatedBy: "-")
            let region = locationComponents.first?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "Diğer"
            regionCounts[region, default: 0] += 1
            
            // Process magnitude data
            let magnitude = getMagnitude(for: earthquake)
            let magnitudeRange = getMagnitudeRange(for: magnitude)
            magnitudeCounts[magnitudeRange, default: 0] += 1
            
            // Process depth data
            let depth = Double(earthquake.depth_km) ?? 0
            let depthRange = getDepthRange(for: depth)
            depthCounts[depthRange, default: 0] += 1
            
            // Process date for timeline
            let date = earthquake.date
            dateCounts[date, default: 0] += 1
        }
        
        // Convert dictionaries to arrays and sort
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
        
        // Sort dates chronologically
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
    
    // MARK: - Chart Creation
    private func createCharts() {
        createRegionBarChart()
        createMagnitudePieChart()
        createDepthBarChart()
        createTimelineChart()
    }
    
    private func createRegionBarChart() {
        // Templ grafikler için hazırlık, gerçek grafikler Charts kütüphanesi ile yapılacak
        let chartView = UIView()
        chartView.translatesAutoresizingMaskIntoConstraints = false
        chartView.backgroundColor = .white
        
        regionChartView.addSubview(chartView)
        
        NSLayoutConstraint.activate([
            chartView.topAnchor.constraint(equalTo: regionChartView.topAnchor),
            chartView.leadingAnchor.constraint(equalTo: regionChartView.leadingAnchor),
            chartView.trailingAnchor.constraint(equalTo: regionChartView.trailingAnchor),
            chartView.bottomAnchor.constraint(equalTo: regionChartView.bottomAnchor)
        ])
        
        // Basit bölgesel dağılım gösterimi
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.spacing = 8
        stackView.distribution = .fillEqually
        
        chartView.addSubview(stackView)
        
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: chartView.topAnchor, constant: 8),
            stackView.leadingAnchor.constraint(equalTo: chartView.leadingAnchor, constant: 8),
            stackView.trailingAnchor.constraint(equalTo: chartView.trailingAnchor, constant: -8),
            stackView.bottomAnchor.constraint(equalTo: chartView.bottomAnchor, constant: -8)
        ])
        
        // Bölgeler için basit gösterim
        for (index, data) in regionCountData.prefix(7).enumerated() {
            let barView = createBarView(title: data.region, value: data.count, maxValue: regionCountData.first?.count ?? 100, color: AppTheme.primaryColor)
            stackView.addArrangedSubview(barView)
        }
    }
    
    private func createMagnitudePieChart() {
        // Temsili pasta grafiği
        let chartView = UIView()
        chartView.translatesAutoresizingMaskIntoConstraints = false
        chartView.backgroundColor = .white
        
        magnitudeChartView.addSubview(chartView)
        
        NSLayoutConstraint.activate([
            chartView.topAnchor.constraint(equalTo: magnitudeChartView.topAnchor),
            chartView.leadingAnchor.constraint(equalTo: magnitudeChartView.leadingAnchor),
            chartView.trailingAnchor.constraint(equalTo: magnitudeChartView.trailingAnchor),
            chartView.bottomAnchor.constraint(equalTo: magnitudeChartView.bottomAnchor)
        ])
        
        // Basit büyüklük dağılımı gösterimi
        let legendStackView = UIStackView()
        legendStackView.translatesAutoresizingMaskIntoConstraints = false
        legendStackView.axis = .vertical
        legendStackView.spacing = 8
        legendStackView.distribution = .fillEqually
        
        chartView.addSubview(legendStackView)
        
        NSLayoutConstraint.activate([
            legendStackView.centerYAnchor.constraint(equalTo: chartView.centerYAnchor),
            legendStackView.leadingAnchor.constraint(equalTo: chartView.leadingAnchor, constant: 16),
            legendStackView.trailingAnchor.constraint(equalTo: chartView.trailingAnchor, constant: -16),
            legendStackView.heightAnchor.constraint(equalToConstant: 200)
        ])
        
        // Büyüklük aralıkları için renk gösterimi
        let colors = [
            UIColor(red: 0.0, green: 0.7, blue: 0.0, alpha: 1.0), // 0-1.9: Yeşil
            UIColor(red: 0.6, green: 0.8, blue: 0.0, alpha: 1.0), // 2-2.9: Lime yeşil
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
    }
    
    private func createDepthBarChart() {
        // Temsili derinlik dağılımı
        let chartView = UIView()
        chartView.translatesAutoresizingMaskIntoConstraints = false
        chartView.backgroundColor = .white
        
        depthChartView.addSubview(chartView)
        
        NSLayoutConstraint.activate([
            chartView.topAnchor.constraint(equalTo: depthChartView.topAnchor),
            chartView.leadingAnchor.constraint(equalTo: depthChartView.leadingAnchor),
            chartView.trailingAnchor.constraint(equalTo: depthChartView.trailingAnchor),
            chartView.bottomAnchor.constraint(equalTo: depthChartView.bottomAnchor)
        ])
        
        // Basit derinlik dağılımı gösterimi
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.spacing = 16
        stackView.distribution = .fillEqually
        
        chartView.addSubview(stackView)
        
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: chartView.topAnchor, constant: 16),
            stackView.leadingAnchor.constraint(equalTo: chartView.leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: chartView.trailingAnchor, constant: -16),
            stackView.bottomAnchor.constraint(equalTo: chartView.bottomAnchor, constant: -16)
        ])
        
        // Derinlik aralıkları için barlar
        let maxDepthCount = depthDistributionData.map { $0.count }.max() ?? 100
        
        for data in depthDistributionData {
            let barView = createBarView(title: data.range, value: data.count, maxValue: maxDepthCount, color: AppTheme.secondaryColor)
            stackView.addArrangedSubview(barView)
        }
    }
    
    private func createTimelineChart() {
        // Temsili zaman çizelgesi
        let chartView = UIView()
        chartView.translatesAutoresizingMaskIntoConstraints = false
        chartView.backgroundColor = .white
        
        timelineChartView.addSubview(chartView)
        
        NSLayoutConstraint.activate([
            chartView.topAnchor.constraint(equalTo: timelineChartView.topAnchor),
            chartView.leadingAnchor.constraint(equalTo: timelineChartView.leadingAnchor),
            chartView.trailingAnchor.constraint(equalTo: timelineChartView.trailingAnchor),
            chartView.bottomAnchor.constraint(equalTo: timelineChartView.bottomAnchor)
        ])
        
        // Basit zaman çizelgesi gösterimi
        let timelineStackView = UIStackView()
        timelineStackView.translatesAutoresizingMaskIntoConstraints = false
        timelineStackView.axis = .vertical
        timelineStackView.spacing = 8
        timelineStackView.distribution = .fill
        
        chartView.addSubview(timelineStackView)
        
        NSLayoutConstraint.activate([
            timelineStackView.topAnchor.constraint(equalTo: chartView.topAnchor, constant: 16),
            timelineStackView.leadingAnchor.constraint(equalTo: chartView.leadingAnchor, constant: 16),
            timelineStackView.trailingAnchor.constraint(equalTo: chartView.trailingAnchor, constant: -16),
            timelineStackView.bottomAnchor.constraint(equalTo: chartView.bottomAnchor, constant: -16)
        ])
        
        // Tarih bazlı aktivite özeti
        let summaryLabel = UILabel()
        summaryLabel.translatesAutoresizingMaskIntoConstraints = false
        summaryLabel.text = "Son \(timelineData.count) günde toplam \(timelineData.reduce(0) { $0 + $1.count }) deprem gerçekleşti."
        summaryLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        summaryLabel.textColor = AppTheme.titleTextColor
        summaryLabel.textAlignment = .center
        summaryLabel.numberOfLines = 0
        
        timelineStackView.addArrangedSubview(summaryLabel)
        
        // Çizgi grafiği görsel temsili
        let timelineDataView = UIView()
        timelineDataView.translatesAutoresizingMaskIntoConstraints = false
        timelineDataView.backgroundColor = AppTheme.backgroundColor
        timelineDataView.layer.cornerRadius = 8
        
        timelineStackView.addArrangedSubview(timelineDataView)
        
        let maxTimeLineHeight: CGFloat = 180
        timelineDataView.heightAnchor.constraint(equalToConstant: maxTimeLineHeight).isActive = true
        
        // Son 7 günün verilerini göster veya tüm günleri, hangisi daha azsa
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
        
        let valueLabel = UILabel()
        valueLabel.translatesAutoresizingMaskIntoConstraints = false
        valueLabel.text = "\(value)"
        valueLabel.font = UIFont.systemFont(ofSize: 12, weight: .bold)
        valueLabel.textColor = .white
        valueLabel.textAlignment = .right
        
        barView.addSubview(titleLabel)
        barView.addSubview(barContainerView)
        barContainerView.addSubview(barFillView)
        barFillView.addSubview(valueLabel)
        
        // Calculate width based on max value
        let fillWidth = value > 0 ? CGFloat(value) / CGFloat(maxValue) : 0.01
        
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
            barFillView.bottomAnchor.constraint(equalTo: barContainerView.bottomAnchor),
            
            valueLabel.trailingAnchor.constraint(equalTo: barFillView.trailingAnchor, constant: -8),
            valueLabel.centerYAnchor.constraint(equalTo: barFillView.centerYAnchor)
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
