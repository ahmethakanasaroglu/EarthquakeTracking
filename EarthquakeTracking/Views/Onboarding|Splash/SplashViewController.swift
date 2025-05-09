import UIKit

class SplashViewController: UIViewController {
    
    // MARK: - Properties
    private let logoContainerView = UIView()
    private let logoImageView = UIImageView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let waveView = WaveAnimationView()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        startAnimations()
    }
    
    // MARK: - Setup
    private func setupUI() {
        view.backgroundColor = AppTheme.backgroundColor
        
        waveView.translatesAutoresizingMaskIntoConstraints = false
        waveView.backgroundColor = .clear
        waveView.waveColor = AppTheme.indigoColor.withAlphaComponent(0.6)
        waveView.secondaryWaveColor = AppTheme.indigoLightColor.withAlphaComponent(0.4)
        view.addSubview(waveView)
        
        logoContainerView.translatesAutoresizingMaskIntoConstraints = false
        logoContainerView.backgroundColor = AppTheme.indigoColor
        logoContainerView.layer.cornerRadius = 50
        logoContainerView.clipsToBounds = true
        logoContainerView.alpha = 0
        view.addSubview(logoContainerView)
        
        logoImageView.translatesAutoresizingMaskIntoConstraints = false
        logoImageView.contentMode = .scaleAspectFit
        logoImageView.image = UIImage(systemName: "waveform.path.ecg")
        logoImageView.tintColor = .white
        logoContainerView.addSubview(logoImageView)
        
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = "DEPREM"
        titleLabel.font = UIFont.systemFont(ofSize: 42, weight: .heavy)
        titleLabel.textColor = AppTheme.indigoColor
        titleLabel.textAlignment = .center
        titleLabel.alpha = 0
        view.addSubview(titleLabel)
        
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.text = "Deprem Bilgileri ve Kişisel Güvenlik Asistanınız"
        subtitleLabel.numberOfLines = 2
        subtitleLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        subtitleLabel.textColor = AppTheme.bodyTextColor
        subtitleLabel.textAlignment = .center
        subtitleLabel.alpha = 0
        view.addSubview(subtitleLabel)
        
        NSLayoutConstraint.activate([

            waveView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            waveView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            waveView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            waveView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.5),
            
            logoContainerView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            logoContainerView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -60),
            logoContainerView.widthAnchor.constraint(equalToConstant: 100),
            logoContainerView.heightAnchor.constraint(equalToConstant: 100),
            
            logoImageView.centerXAnchor.constraint(equalTo: logoContainerView.centerXAnchor),
            logoImageView.centerYAnchor.constraint(equalTo: logoContainerView.centerYAnchor),
            logoImageView.widthAnchor.constraint(equalToConstant: 60),
            logoImageView.heightAnchor.constraint(equalToConstant: 60),
            
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            titleLabel.topAnchor.constraint(equalTo: logoContainerView.bottomAnchor, constant: 40),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            subtitleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 16),
            subtitleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            subtitleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40)
        ])
    }
    
    // MARK: - Animations
    private func startAnimations() {

        waveView.startAnimation()
        
        UIView.animate(withDuration: 0.8, delay: 0.3, options: [.curveEaseOut]) {
            self.logoContainerView.alpha = 1.0
            self.logoContainerView.transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
        } completion: { _ in
            UIView.animate(withDuration: 0.2) {
                self.logoContainerView.transform = CGAffineTransform.identity
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            self.addPulseEffect(to: self.logoContainerView)
        }
        
        UIView.animate(withDuration: 0.8, delay: 0.8, options: [.curveEaseOut]) {
            self.titleLabel.alpha = 1.0
            self.titleLabel.transform = CGAffineTransform(translationX: 0, y: -10)
        }
        
        UIView.animate(withDuration: 0.8, delay: 1.0, options: [.curveEaseOut]) {
            self.subtitleLabel.alpha = 1.0
        } completion: { _ in

            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                self.navigateToNextScreen()
            }
        }
    }
    
    private func addPulseEffect(to view: UIView) {
        let pulse = CASpringAnimation(keyPath: "transform.scale")
        pulse.duration = 0.8
        pulse.fromValue = 1.0
        pulse.toValue = 1.12
        pulse.autoreverses = true
        pulse.repeatCount = 1
        pulse.initialVelocity = 0.5
        pulse.damping = 0.8
        
        view.layer.add(pulse, forKey: "pulse")
    }
    
    // MARK: - Navigation
    private func navigateToNextScreen() {

        let defaults = UserDefaults.standard
        let hasSeenOnboarding = defaults.bool(forKey: "hasSeenOnboarding")
        
        if !hasSeenOnboarding {

            let onboardingVC = OnboardingViewController()
            onboardingVC.modalPresentationStyle = .fullScreen
            onboardingVC.modalTransitionStyle = .crossDissolve
            present(onboardingVC, animated: true)
        } else {

            transitionToMainInterface()
        }
    }
    
    private func transitionToMainInterface() {

        let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene
        let sceneDelegate = windowScene?.delegate as? SceneDelegate
        sceneDelegate?.setupMainInterface(in: windowScene!)
    }
}

// MARK: - Wave Animation View
class WaveAnimationView: UIView {
    var waveColor = UIColor.blue.withAlphaComponent(0.4)
    var secondaryWaveColor = UIColor.blue.withAlphaComponent(0.4)
    
    private var displayLink: CADisplayLink?
    private var startTime: CFTimeInterval = 0
    
    private let firstWaveLayer = CAShapeLayer()
    private let secondWaveLayer = CAShapeLayer()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayers()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupLayers()
    }
    
    private func setupLayers() {
        firstWaveLayer.fillColor = waveColor.cgColor
        layer.addSublayer(firstWaveLayer)
        
        secondWaveLayer.fillColor = secondaryWaveColor.cgColor
        layer.addSublayer(secondWaveLayer)
    }
    
    func startAnimation() {
        startTime = CACurrentMediaTime()
        
        displayLink = CADisplayLink(target: self, selector: #selector(updateAnimation))
        displayLink?.add(to: .main, forMode: .common)
    }
    
    @objc private func updateAnimation() {
        let elapsed = CACurrentMediaTime() - startTime
        
        let width = bounds.width
        let height = bounds.height
        
        let firstWavePath = createWavePath(
            width: width,
            height: height,
            amplitude: height * 0.05,
            wavelength: width * 0.8,
            phase: elapsed * 2
        )
        
        let secondWavePath = createWavePath(
            width: width,
            height: height,
            amplitude: height * 0.035,
            wavelength: width,
            phase: elapsed * 1.5
        )
        
        firstWaveLayer.path = firstWavePath.cgPath
        secondWaveLayer.path = secondWavePath.cgPath
    }
    
    private func createWavePath(width: CGFloat, height: CGFloat, amplitude: CGFloat, wavelength: CGFloat, phase: CFTimeInterval) -> UIBezierPath {
        let path = UIBezierPath()
        
        let midHeight = height * 0.7
        
        path.move(to: CGPoint(x: 0, y: height))
        path.addLine(to: CGPoint(x: 0, y: midHeight))
        
        var x: CGFloat = 0
        while x <= width {
            let y = midHeight + amplitude * sin((2 * .pi * x / wavelength) + phase)
            path.addLine(to: CGPoint(x: x, y: y))
            x += 1
        }
        
        path.addLine(to: CGPoint(x: width, y: height))
        path.close()
        
        return path
    }
    
    deinit {
        displayLink?.invalidate()
    }
}
