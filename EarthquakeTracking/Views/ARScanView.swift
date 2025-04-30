import UIKit
import Combine
import ARKit

class ARScanViewController: UIViewController {
    
    // MARK: - Properties
    private let viewModel: PersonalizedViewModel
    private var cancellables = Set<AnyCancellable>()
    private var arSession: ARSession?
    
    // MARK: - UI Elements
    private lazy var arSceneView: ARSCNView = {
        let sceneView = ARSCNView()
        sceneView.translatesAutoresizingMaskIntoConstraints = false
        sceneView.delegate = self
        sceneView.session.delegate = self
        sceneView.automaticallyUpdatesLighting = true
        sceneView.autoenablesDefaultLighting = true
        return sceneView
    }()
    
    private lazy var overlayView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        view.isHidden = true
        return view
    }()
    
    private lazy var instructionLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Evinizdeki depremlerde risk oluşturabilecek eşyaları tarayın"
        label.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        label.textColor = .white
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()
    
    private lazy var stepInstructionLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Kamerayı kitaplık ve raflara doğrultun"
        label.font = UIFont.systemFont(ofSize: 16)
        label.textColor = .white
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()
    
    private lazy var progressView: UIProgressView = {
        let progress = UIProgressView(progressViewStyle: .bar)
        progress.translatesAutoresizingMaskIntoConstraints = false
        progress.progress = 0
        progress.progressTintColor = .systemGreen
        progress.trackTintColor = UIColor.lightGray.withAlphaComponent(0.5)
        progress.layer.cornerRadius = 4
        progress.clipsToBounds = true
        return progress
    }()
    
    private lazy var nextButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("İleri", for: .normal)
        button.setImage(UIImage(systemName: "arrow.right.circle.fill"), for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        button.backgroundColor = .systemGreen
        button.tintColor = .white
        button.layer.cornerRadius = 16
        button.contentEdgeInsets = UIEdgeInsets(top: 10, left: 20, bottom: 10, right: 20)
        button.addTarget(self, action: #selector(nextButtonTapped), for: .touchUpInside)
        return button
    }()
    
    private lazy var cancelButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("İptal", for: .normal)
        button.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        button.backgroundColor = .systemRed
        button.tintColor = .white
        button.layer.cornerRadius = 16
        button.contentEdgeInsets = UIEdgeInsets(top: 10, left: 20, bottom: 10, right: 20)
        button.addTarget(self, action: #selector(cancelButtonTapped), for: .touchUpInside)
        return button
    }()
    
    private lazy var scanAreaImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        imageView.image = UIImage(systemName: "viewfinder")
        imageView.tintColor = .white
        return imageView
    }()
    
    private lazy var resultsContainerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .systemBackground
        view.layer.cornerRadius = 16
        view.isHidden = true
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = 0.3
        view.layer.shadowOffset = CGSize(width: 0, height: 5)
        view.layer.shadowRadius = 10
        return view
    }()
    
    private lazy var resultsHeaderLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Tarama Sonuçları"
        label.font = UIFont.systemFont(ofSize: 20, weight: .bold)
        label.textColor = .label
        label.textAlignment = .center
        return label
    }()
    
    private lazy var resultsTableView: UITableView = {
        let tableView = UITableView()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.register(ARScanResultCell.self, forCellReuseIdentifier: "ARScanResultCell")
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear
        tableView.showsVerticalScrollIndicator = false
        return tableView
    }()
    
    private lazy var doneButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Tamamlandı", for: .normal)
        button.setImage(UIImage(systemName: "checkmark.circle.fill"), for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        button.backgroundColor = .systemBlue
        button.tintColor = .white
        button.layer.cornerRadius = 16
        button.contentEdgeInsets = UIEdgeInsets(top: 10, left: 20, bottom: 10, right: 20)
        button.addTarget(self, action: #selector(doneButtonTapped), for: .touchUpInside)
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
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // AR Deneyimi başlat
        startARExperience()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // AR Deneyimini durdur
        arSceneView.session.pause()
        viewModel.stopARScan()
    }
    
    // MARK: - Setup
    private func setupUI() {
        title = "AR Güvenlik Taraması"
        view.backgroundColor = .black
        
        // Ana görünümleri ekle
        view.addSubview(arSceneView)
        view.addSubview(overlayView)
        
        // Tarama arayüzü elemanlarını ekle
        overlayView.addSubview(instructionLabel)
        overlayView.addSubview(stepInstructionLabel)
        overlayView.addSubview(progressView)
        overlayView.addSubview(scanAreaImageView)
        
        let buttonStackView = UIStackView(arrangedSubviews: [cancelButton, nextButton])
        buttonStackView.translatesAutoresizingMaskIntoConstraints = false
        buttonStackView.axis = .horizontal
        buttonStackView.distribution = .fillEqually
        buttonStackView.spacing = 16
        overlayView.addSubview(buttonStackView)
        
        // Sonuç görünümü ekle
        view.addSubview(resultsContainerView)
        resultsContainerView.addSubview(resultsHeaderLabel)
        resultsContainerView.addSubview(resultsTableView)
        resultsContainerView.addSubview(doneButton)
        
        // Constraint'leri ayarla
        NSLayoutConstraint.activate([
            // AR Sahne Görünümü
            arSceneView.topAnchor.constraint(equalTo: view.topAnchor),
            arSceneView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            arSceneView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            arSceneView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // Kaplama Görünümü
            overlayView.topAnchor.constraint(equalTo: view.topAnchor),
            overlayView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            overlayView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            overlayView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // Talimat Etiketi
            instructionLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            instructionLabel.leadingAnchor.constraint(equalTo: overlayView.leadingAnchor, constant: 20),
            instructionLabel.trailingAnchor.constraint(equalTo: overlayView.trailingAnchor, constant: -20),
            
            // Adım Talimatı
            stepInstructionLabel.topAnchor.constraint(equalTo: instructionLabel.bottomAnchor, constant: 16),
            stepInstructionLabel.leadingAnchor.constraint(equalTo: overlayView.leadingAnchor, constant: 20),
            stepInstructionLabel.trailingAnchor.constraint(equalTo: overlayView.trailingAnchor, constant: -20),
            
            // İlerleme Çubuğu
            progressView.topAnchor.constraint(equalTo: stepInstructionLabel.bottomAnchor, constant: 16),
            progressView.leadingAnchor.constraint(equalTo: overlayView.leadingAnchor, constant: 40),
            progressView.trailingAnchor.constraint(equalTo: overlayView.trailingAnchor, constant: -40),
            progressView.heightAnchor.constraint(equalToConstant: 8),
            
            // Tarama Alanı Görüntüsü
            scanAreaImageView.centerXAnchor.constraint(equalTo: overlayView.centerXAnchor),
            scanAreaImageView.centerYAnchor.constraint(equalTo: overlayView.centerYAnchor),
            scanAreaImageView.widthAnchor.constraint(equalToConstant: 150),
            scanAreaImageView.heightAnchor.constraint(equalToConstant: 150),
            
            // Buton Yığını
            buttonStackView.leadingAnchor.constraint(equalTo: overlayView.leadingAnchor, constant: 40),
            buttonStackView.trailingAnchor.constraint(equalTo: overlayView.trailingAnchor, constant: -40),
            buttonStackView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            
            // Sonuçlar Görünümü
            resultsContainerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            resultsContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            resultsContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            resultsContainerView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            
            // Sonuçlar Başlığı
            resultsHeaderLabel.topAnchor.constraint(equalTo: resultsContainerView.topAnchor, constant: 16),
            resultsHeaderLabel.leadingAnchor.constraint(equalTo: resultsContainerView.leadingAnchor, constant: 16),
            resultsHeaderLabel.trailingAnchor.constraint(equalTo: resultsContainerView.trailingAnchor, constant: -16),
            
            // Sonuçlar Tablosu
            resultsTableView.topAnchor.constraint(equalTo: resultsHeaderLabel.bottomAnchor, constant: 16),
            resultsTableView.leadingAnchor.constraint(equalTo: resultsContainerView.leadingAnchor, constant: 16),
            resultsTableView.trailingAnchor.constraint(equalTo: resultsContainerView.trailingAnchor, constant: -16),
            resultsTableView.bottomAnchor.constraint(equalTo: doneButton.topAnchor, constant: -16),
            
            // Tamamlandı Butonu
            doneButton.leadingAnchor.constraint(equalTo: resultsContainerView.leadingAnchor, constant: 16),
            doneButton.trailingAnchor.constraint(equalTo: resultsContainerView.trailingAnchor, constant: -16),
            doneButton.bottomAnchor.constraint(equalTo: resultsContainerView.bottomAnchor, constant: -16),
            doneButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    private func setupBindings() {
        // AR tarama adımını güncelle
        viewModel.$currentScanStep
            .receive(on: DispatchQueue.main)
            .sink { [weak self] step in
                self?.updateScanStep(step: step)
            }
            .store(in: &cancellables)
        
        // İlerleme çubuğunu güncelle
        viewModel.$scanProgress
            .receive(on: DispatchQueue.main)
            .sink { [weak self] progress in
                self?.progressView.setProgress(progress, animated: true)
            }
            .store(in: &cancellables)
        
        // Tarama sonuçlarını güncelle
        viewModel.$scanResults
            .receive(on: DispatchQueue.main)
            .sink { [weak self] results in
                if !results.isEmpty {
                    self?.showScanResults()
                }
            }
            .store(in: &cancellables)
        
        // Tarama aktif durumunu güncelle
        viewModel.$isARScanActive
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isActive in
                self?.updateScanningState(isActive: isActive)
            }
            .store(in: &cancellables)
    }
    
    // MARK: - AR Experience
    private func startARExperience() {
        // AR deneyimi için gerekli izinlerin kontrolü ve başlatılması
        guard ARWorldTrackingConfiguration.isSupported else {
            showARNotSupportedAlert()
            return
        }
        
        // AR konfigürasyonu oluştur
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal, .vertical]
        
        // Ortam ışığının tahmin edilmesini etkinleştir
        configuration.isLightEstimationEnabled = true
        
        // AR oturumunu başlat
        arSceneView.session.run(configuration)
        
        // Taramayı başlat
        viewModel.startARScan()
        overlayView.isHidden = false
    }
    
    private func updateScanStep(step: Int) {
        // Güncel tarama adımını güncelle
        if let currentStep = viewModel.currentScanStepInfo {
            stepInstructionLabel.text = currentStep.description
            
            // Tarama alanı görüntüsünü güncelleyelim (gerçek bir uygulamada, farklı adımlar için farklı görüntüler olabilir)
            switch currentStep.id {
            case 1: // Kitaplık ve Raflar
                scanAreaImageView.image = UIImage(systemName: "square.stack.3d.up")
            case 2: // Cam Eşyalar
                scanAreaImageView.image = UIImage(systemName: "cup.and.saucer")
            case 3: // Ağır Mobilyalar
                scanAreaImageView.image = UIImage(systemName: "cabinet")
            case 4: // Elektrik Kabloları
                scanAreaImageView.image = UIImage(systemName: "bolt")
            default:
                scanAreaImageView.image = UIImage(systemName: "viewfinder")
            }
        }
    }
    
    private func updateScanningState(isActive: Bool) {
        if isActive {
            // Tarama başladığında gerekli işlemler
            overlayView.isHidden = false
            resultsContainerView.isHidden = true
        } else {
            // Tarama bittiğinde sonuçları gösterme
            if !viewModel.scanResults.isEmpty {
                showScanResults()
            }
        }
    }
    
    private func showScanResults() {
        // AR görünümü ve tarama arayüzünü gizle
        overlayView.isHidden = true
        
        // Sonuçları tabloya yükle ve göster
        resultsTableView.reloadData()
        resultsContainerView.isHidden = false
        
        // Animasyonla göster
        resultsContainerView.alpha = 0
        UIView.animate(withDuration: 0.3) {
            self.resultsContainerView.alpha = 1
        }
    }
    
    // MARK: - Actions
    
    @objc private func nextButtonTapped() {
        viewModel.advanceToNextScanStep()
    }
    
    @objc private func cancelButtonTapped() {
        viewModel.stopARScan()
        navigationController?.popViewController(animated: true)
    }
    
    @objc private func doneButtonTapped() {
        navigationController?.popViewController(animated: true)
    }
    
    // MARK: - Helper Methods
    
    private func showARNotSupportedAlert() {
        let alert = UIAlertController(
            title: "AR Desteklenmiyor",
            message: "Cihazınız Artırılmış Gerçeklik özelliklerini desteklemiyor.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Tamam", style: .default) { _ in
            self.navigationController?.popViewController(animated: true)
        })
        present(alert, animated: true)
    }
}

// MARK: - ARSCNViewDelegate
extension ARScanViewController: ARSCNViewDelegate, ARSessionDelegate {
    func session(_ session: ARSession, didFailWithError error: Error) {
        // AR oturumu hata verdiğinde
        let alert = UIAlertController(
            title: "AR Oturumu Hatası",
            message: "AR taraması başlatılamadı: \(error.localizedDescription)",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Tamam", style: .default) { _ in
            self.navigationController?.popViewController(animated: true)
        })
        present(alert, animated: true)
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // AR oturumu kesintiye uğradığında
        print("AR oturumu kesintiye uğradı")
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // AR oturumu kesintisi bittiğinde
        print("AR oturumu kesintisi sona erdi")
    }
}

// MARK: - UITableViewDelegate, UITableViewDataSource
extension ARScanViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.scanResults.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ARScanResultCell", for: indexPath) as! ARScanResultCell
        let result = viewModel.scanResults[indexPath.row]
        cell.configure(with: result)
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 100
    }
}

// MARK: - ARScanResultCell
class ARScanResultCell: UITableViewCell {
    
    private let containerView = UIView()
    private let titleLabel = UILabel()
    private let recommendationLabel = UILabel()
    private let riskIndicator = UIView()
    private let riskLabel = UILabel()
    
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
        
        // Container View
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.backgroundColor = .secondarySystemBackground
        containerView.layer.cornerRadius = 12
        containerView.clipsToBounds = true
        
        // Title Label
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        titleLabel.textColor = .label
        
        // Recommendation Label
        recommendationLabel.translatesAutoresizingMaskIntoConstraints = false
        recommendationLabel.font = UIFont.systemFont(ofSize: 14)
        recommendationLabel.textColor = .secondaryLabel
        recommendationLabel.numberOfLines = 0
        
        // Risk Indicator
        riskIndicator.translatesAutoresizingMaskIntoConstraints = false
        riskIndicator.layer.cornerRadius = 6
        
        // Risk Label
        riskLabel.translatesAutoresizingMaskIntoConstraints = false
        riskLabel.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        riskLabel.textColor = .white
        riskLabel.textAlignment = .center
        
        // Add subviews
        contentView.addSubview(containerView)
        containerView.addSubview(titleLabel)
        containerView.addSubview(recommendationLabel)
        containerView.addSubview(riskIndicator)
        riskIndicator.addSubview(riskLabel)
        
        // Setup constraints
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            
            titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 12),
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: riskIndicator.leadingAnchor, constant: -8),
            
            recommendationLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            recommendationLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            recommendationLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            recommendationLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -12),
            
            riskIndicator.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 12),
            riskIndicator.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            riskIndicator.widthAnchor.constraint(equalToConstant: 60),
            riskIndicator.heightAnchor.constraint(equalToConstant: 26),
            
            riskLabel.topAnchor.constraint(equalTo: riskIndicator.topAnchor),
            riskLabel.leadingAnchor.constraint(equalTo: riskIndicator.leadingAnchor),
            riskLabel.trailingAnchor.constraint(equalTo: riskIndicator.trailingAnchor),
            riskLabel.bottomAnchor.constraint(equalTo: riskIndicator.bottomAnchor)
        ])
    }
    
    func configure(with result: ScanResult) {
        titleLabel.text = result.title
        recommendationLabel.text = result.recommendation
        
        // Risk seviyesine göre arka plan rengini ayarla
        switch result.riskLevel {
        case .high:
            riskIndicator.backgroundColor = .systemRed
            riskLabel.text = "Yüksek"
        case .medium:
            riskIndicator.backgroundColor = .systemOrange
            riskLabel.text = "Orta"
        case .low:
            riskIndicator.backgroundColor = .systemGreen
            riskLabel.text = "Düşük"
        case .unknown:
            riskIndicator.backgroundColor = .systemGray
            riskLabel.text = "Bilinmiyor"
        }
    }
}
