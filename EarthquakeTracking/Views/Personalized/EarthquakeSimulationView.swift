import UIKit
import AVFoundation

class EarthquakeSimulationViewController: UIViewController {
    
    // MARK: - Properties
    private let viewModel: PersonalizedViewModel
    private var animationTimer: Timer?
    private var audioPlayer: AVAudioPlayer?
    
    // MARK: - UI Elements
    private lazy var headerLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Deprem Simülasyonu"
        label.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        label.textColor = .label
        label.textAlignment = .center
        return label
    }()
    
    private lazy var descriptionLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Farklı büyüklüklerdeki depremlerin nasıl hissedilebileceğini deneyimleyin. Bu simülasyon, gerçek deprem verilerine dayanarak titreşim ve ses efektleri oluşturur."
        label.font = UIFont.systemFont(ofSize: 16)
        label.textColor = .secondaryLabel
        label.numberOfLines = 0
        label.textAlignment = .center
        return label
    }()
    
    private lazy var magnitudeSlider: UISlider = {
        let slider = UISlider()
        slider.translatesAutoresizingMaskIntoConstraints = false
        slider.minimumValue = 3.0
        slider.maximumValue = 8.0
        slider.value = Float(viewModel.selectedSimulationMagnitude)
        slider.minimumTrackTintColor = .systemBlue
        slider.addTarget(self, action: #selector(magnitudeSliderChanged), for: .valueChanged)
        return slider
    }()
    
    private lazy var magnitudeValueLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = String(format: "M %.1f", viewModel.selectedSimulationMagnitude)
        label.font = UIFont.systemFont(ofSize: 36, weight: .bold)
        label.textColor = getMagnitudeColor(viewModel.selectedSimulationMagnitude)
        label.textAlignment = .center
        return label
    }()
    
    private lazy var magnitudeDescriptionLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = getMagnitudeDescription(viewModel.selectedSimulationMagnitude)
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = .secondaryLabel
        label.numberOfLines = 0
        label.textAlignment = .center
        return label
    }()
    
    private lazy var effectLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Beklenen Etkiler:"
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        label.textColor = .label
        return label
    }()
    
    private lazy var effectDescriptionLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = viewModel.simulationEffect.description
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = .secondaryLabel
        label.numberOfLines = 0
        return label
    }()
    
    private lazy var startSimulationButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Simülasyonu Başlat", for: .normal)
        button.setImage(UIImage(systemName: "play.fill"), for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        button.backgroundColor = .systemGreen
        button.tintColor = .white
        button.layer.cornerRadius = 20
        button.contentEdgeInsets = UIEdgeInsets(top: 12, left: 20, bottom: 12, right: 20)
        button.addTarget(self, action: #selector(toggleSimulation), for: .touchUpInside)
        return button
    }()
    
    private lazy var simulationImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        imageView.image = UIImage(systemName: "waveform.path.ecg")
        imageView.tintColor = .systemGray
        return imageView
    }()
    
    private lazy var loadingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.hidesWhenStopped = true
        return indicator
    }()
    
    // MARK: - Notification constants
    private let simulationActiveChangedNotification = PersonalizedViewModel.simulationSettingsChangedNotification
    static let simulationActiveChangedNotification = Notification.Name("simulationActiveChangedNotification")
    static let simulationIntensityChangedNotification = Notification.Name("simulationIntensityChangedNotification")
    static let simulationEffectChangedNotification = Notification.Name("simulationEffectChangedNotification")
    
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
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        viewModel.stopSimulation()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Setup
    private func setupUI() {
        title = "Deprem Simülasyonu"
        view.backgroundColor = .systemBackground
        
        view.addSubview(headerLabel)
        view.addSubview(descriptionLabel)
        view.addSubview(magnitudeValueLabel)
        view.addSubview(magnitudeSlider)
        view.addSubview(magnitudeDescriptionLabel)
        view.addSubview(effectLabel)
        view.addSubview(effectDescriptionLabel)
        view.addSubview(simulationImageView)
        view.addSubview(startSimulationButton)
        view.addSubview(loadingIndicator)
        
        NSLayoutConstraint.activate([
            headerLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            headerLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            headerLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            descriptionLabel.topAnchor.constraint(equalTo: headerLabel.bottomAnchor, constant: 16),
            descriptionLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            descriptionLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            magnitudeValueLabel.topAnchor.constraint(equalTo: descriptionLabel.bottomAnchor, constant: 30),
            magnitudeValueLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            magnitudeSlider.topAnchor.constraint(equalTo: magnitudeValueLabel.bottomAnchor, constant: 16),
            magnitudeSlider.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            magnitudeSlider.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
            
            magnitudeDescriptionLabel.topAnchor.constraint(equalTo: magnitudeSlider.bottomAnchor, constant: 16),
            magnitudeDescriptionLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            magnitudeDescriptionLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            effectLabel.topAnchor.constraint(equalTo: magnitudeDescriptionLabel.bottomAnchor, constant: 24),
            effectLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            effectLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            effectDescriptionLabel.topAnchor.constraint(equalTo: effectLabel.bottomAnchor, constant: 8),
            effectDescriptionLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            effectDescriptionLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            simulationImageView.topAnchor.constraint(equalTo: effectDescriptionLabel.bottomAnchor, constant: 30),
            simulationImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            simulationImageView.widthAnchor.constraint(equalToConstant: 200),
            simulationImageView.heightAnchor.constraint(equalToConstant: 100),
            
            startSimulationButton.topAnchor.constraint(equalTo: simulationImageView.bottomAnchor, constant: 30),
            startSimulationButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    private func setupBindings() {

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleSimulationSettingsChanged(_:)),
            name: PersonalizedViewModel.simulationSettingsChangedNotification,
            object: nil
        )
    }
    
    @objc private func handleSimulationSettingsChanged(_ notification: Notification) {
        guard let userInfo = notification.userInfo else { return }
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            if let isActive = userInfo["isActive"] as? Bool {
                self.updateUIForSimulationState(isActive: isActive)
            }
            
            if let magnitude = userInfo["magnitude"] as? Double {
                self.magnitudeValueLabel.text = String(format: "M %.1f", magnitude)
                self.magnitudeValueLabel.textColor = self.getMagnitudeColor(magnitude)
                self.magnitudeDescriptionLabel.text = self.getMagnitudeDescription(magnitude)
                self.magnitudeSlider.value = Float(magnitude)
            }
            
            if let intensity = userInfo["intensity"] as? Double {
                self.applySimulationEffect(intensity: intensity)
            }
            
            if let effect = userInfo["effect"] as? SimulationEffect {
                self.effectDescriptionLabel.text = effect.description
            }
        }
    }
    
    // MARK: - UI Updates
    
    private func updateUIForSimulationState(isActive: Bool) {
        if isActive {
            startSimulationButton.setTitle("Simülasyonu Durdur", for: .normal)
            startSimulationButton.setImage(UIImage(systemName: "stop.fill"), for: .normal)
            startSimulationButton.backgroundColor = .systemRed
            
            magnitudeSlider.isEnabled = false
            
            startEarthquakeAnimation()
            
        } else {
            startSimulationButton.setTitle("Simülasyonu Başlat", for: .normal)
            startSimulationButton.setImage(UIImage(systemName: "play.fill"), for: .normal)
            startSimulationButton.backgroundColor = .systemGreen
            
            magnitudeSlider.isEnabled = true
            
            stopEarthquakeAnimation()
        }
    }
    
    private func updateMagnitudeDisplay() {
        let magnitude = viewModel.selectedSimulationMagnitude
        magnitudeValueLabel.text = String(format: "M %.1f", magnitude)
        magnitudeValueLabel.textColor = getMagnitudeColor(magnitude)
        magnitudeDescriptionLabel.text = getMagnitudeDescription(magnitude)
    }
    
    // MARK: - Actions
    
    @objc private func magnitudeSliderChanged(_ sender: UISlider) {
        let magnitude = Double(round(sender.value * 10) / 10)
        viewModel.setSimulationMagnitude(magnitude)
        updateMagnitudeDisplay()
    }
    
    @objc private func toggleSimulation() {
        if viewModel.isSimulationActive {
            viewModel.stopSimulation()
        } else {
            viewModel.startSimulation()
        }
    }
    
    // MARK: - Simulation Effects
    
    private func applySimulationEffect(intensity: Double) {

        let translation = CGAffineTransform(translationX: intensity * 10, y: 0)
        
        UIView.animate(withDuration: 0.1, delay: 0, options: .allowUserInteraction) {
            self.view.transform = translation
        }
        
        if abs(intensity) > 0.7 {
            let heavyFeedback = UIImpactFeedbackGenerator(style: .heavy)
            heavyFeedback.impactOccurred()
        } else if abs(intensity) > 0.3 {
            let mediumFeedback = UIImpactFeedbackGenerator(style: .medium)
            mediumFeedback.impactOccurred()
        } else if abs(intensity) > 0.1 {
            let lightFeedback = UIImpactFeedbackGenerator(style: .light)
            lightFeedback.impactOccurred()
        }
    }
    
    private func startEarthquakeAnimation() {
        animationTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            let intensity = self.viewModel.simulationIntensity
            let scale = 1.0 + abs(intensity) * 0.05
            
            UIView.animate(withDuration: 0.1) {
                self.simulationImageView.transform = CGAffineTransform(scaleX: scale, y: scale)
                    .concatenating(CGAffineTransform(translationX: intensity * 5, y: intensity * 3))
                
                self.simulationImageView.tintColor = abs(intensity) > 0.5 ? .systemRed :
                abs(intensity) > 0.3 ? .systemOrange : .systemBlue
            }
        }
    }
    
    private func stopEarthquakeAnimation() {
        animationTimer?.invalidate()
        animationTimer = nil
        
        UIView.animate(withDuration: 0.3) {
            self.simulationImageView.transform = .identity
            self.simulationImageView.tintColor = .systemGray
            self.view.transform = .identity
        }
    }
    
    
    // MARK: - Helper Methods
    
    private func getMagnitudeColor(_ magnitude: Double) -> UIColor {
        switch magnitude {
        case 7.0...: return .systemRed
        case 5.0..<7.0: return .systemOrange
        case 4.0..<5.0: return .systemYellow
        default: return .systemGreen
        }
    }
    
    private func getMagnitudeDescription(_ magnitude: Double) -> String {
        switch magnitude {
        case 7.0...:
            return "Yıkıcı şiddette deprem. Büyük yapısal hasarlar, can kayıpları olabilir."
        case 6.0..<7.0:
            return "Şiddetli deprem. Geniş alanlarda hasar ve yaralanmalar olabilir."
        case 5.0..<6.0:
            return "Orta-güçlü deprem. Yapılarda hafif hasar görülebilir."
        case 4.0..<5.0:
            return "Hafif deprem. Hissedilir, ancak genellikle hasar vermez."
        default:
            return "Çok hafif deprem. Çoğu kişi tarafından hissedilmeyebilir."
        }
    }
}
