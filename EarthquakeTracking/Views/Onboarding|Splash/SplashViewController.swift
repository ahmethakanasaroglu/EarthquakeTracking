import UIKit

class SplashViewController: UIViewController {
    
    // MARK: - Properties
    private let logoImageView = UIImageView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let pulseView = UIView()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        animateViews()
    }
    
    // MARK: - Setup
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        // Pulse view (animated background circle)
        pulseView.translatesAutoresizingMaskIntoConstraints = false
        pulseView.backgroundColor = UIColor.systemIndigo.withAlphaComponent(0.1)
        pulseView.layer.cornerRadius = 150
        pulseView.alpha = 0
        view.addSubview(pulseView)
        
        // Logo setup
        logoImageView.translatesAutoresizingMaskIntoConstraints = false
        logoImageView.contentMode = .scaleAspectFit
        logoImageView.image = UIImage(systemName: "waveform.path.ecg")
        logoImageView.tintColor = .systemIndigo
        logoImageView.alpha = 0
        view.addSubview(logoImageView)
        
        // Title setup
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = "Deprem"
        titleLabel.font = UIFont.systemFont(ofSize: 42, weight: .bold)
        titleLabel.textColor = .label
        titleLabel.textAlignment = .center
        titleLabel.alpha = 0
        view.addSubview(titleLabel)
        
        // Subtitle setup
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.text = "Deprem bilgileri ve kişisel güvenlik asistanınız"
        subtitleLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        subtitleLabel.textColor = .secondaryLabel
        subtitleLabel.textAlignment = .center
        subtitleLabel.alpha = 0
        view.addSubview(subtitleLabel)
        
        // Layout constraints
        NSLayoutConstraint.activate([
            pulseView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            pulseView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            pulseView.widthAnchor.constraint(equalToConstant: 300),
            pulseView.heightAnchor.constraint(equalToConstant: 300),
            
            logoImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            logoImageView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -40),
            logoImageView.widthAnchor.constraint(equalToConstant: 120),
            logoImageView.heightAnchor.constraint(equalToConstant: 120),
            
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            titleLabel.topAnchor.constraint(equalTo: logoImageView.bottomAnchor, constant: 24),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            subtitleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 16),
            subtitleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            subtitleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
        ])
    }
    
    // MARK: - Animations
    private func animateViews() {
        // Pulse view animation
        UIView.animate(withDuration: 0.8, delay: 0.0, options: [.curveEaseOut]) {
            self.pulseView.alpha = 1.0
            self.pulseView.transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
        }
        
        // Logo animation
        UIView.animate(withDuration: 0.7, delay: 0.3, options: [.curveEaseOut]) {
            self.logoImageView.alpha = 1.0
            self.logoImageView.transform = CGAffineTransform(translationX: 0, y: -10)
        }
        
        // Title animation
        UIView.animate(withDuration: 0.7, delay: 0.5, options: [.curveEaseOut]) {
            self.titleLabel.alpha = 1.0
        }
        
        // Subtitle animation
        UIView.animate(withDuration: 0.7, delay: 0.7, options: [.curveEaseOut]) {
            self.subtitleLabel.alpha = 1.0
        } completion: { _ in
            // After all animations complete, delay and then check if we need to show onboarding
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                self.navigateToNextScreen()
            }
        }
    }
    
    // MARK: - Navigation
    private func navigateToNextScreen() {
        // Check if this is the first launch
        let defaults = UserDefaults.standard
        let hasSeenOnboarding = defaults.bool(forKey: "hasSeenOnboarding")
        
        if !hasSeenOnboarding {
            // First time launching the app - show onboarding
            let onboardingVC = OnboardingViewController()
            onboardingVC.modalPresentationStyle = .fullScreen
            onboardingVC.modalTransitionStyle = .crossDissolve
            present(onboardingVC, animated: true)
        } else {
            // Not the first time - go directly to main interface
            transitionToMainInterface()
        }
    }
    
    private func transitionToMainInterface() {
        // Create the tab bar controller (copied from your SceneDelegate)
        let tabBarController = UITabBarController()
        
        // Create the earthquake list view controller
        let earthquakeListViewController = EarthquakeListViewController()
        let listNavigationController = UINavigationController(rootViewController: earthquakeListViewController)
        listNavigationController.tabBarItem = UITabBarItem(title: "Depremler", image: UIImage(systemName: "list.bullet"), tag: 0)
        
        // Create the AI powered view controller
        let personalizedViewController = PersonalizedViewController()
        let personalizedNavigationController = UINavigationController(rootViewController: personalizedViewController)
        personalizedNavigationController.tabBarItem = UITabBarItem(title: "Kişiselleştirilmiş", image: UIImage(systemName: "person.fill.viewfinder"), tag: 1)
        
        // AI Extensions view controller
        let aiExtensionsViewController = AIExtensionsViewController()
        let aiNavigationController = UINavigationController(rootViewController: aiExtensionsViewController)
        aiNavigationController.tabBarItem = UITabBarItem(title: "AI Eklentileri", image: UIImage(systemName: "brain"), tag: 2)
        
        // Set the tab bar items
        tabBarController.viewControllers = [listNavigationController, personalizedNavigationController, aiNavigationController]
        
        // Configure tab bar appearance
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithOpaqueBackground()
        tabBarAppearance.backgroundColor = .systemBackground
        
        tabBarController.tabBar.standardAppearance = tabBarAppearance
        if #available(iOS 15.0, *) {
            tabBarController.tabBar.scrollEdgeAppearance = tabBarAppearance
        }
        
        // Animate transition to main interface
        UIView.transition(with: UIApplication.shared.windows.first!,
                          duration: 0.5,
                          options: .transitionCrossDissolve,
                          animations: {
            UIApplication.shared.windows.first?.rootViewController = tabBarController
        })
    }
}
