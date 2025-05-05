import UIKit
import MapKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        
        // Set up UIAppearance for global styles
        setupAppAppearance()
        
        // Create window with the correct windowScene
        window = UIWindow(windowScene: windowScene)
        
        // Check if user has seen onboarding
        if UserDefaults.standard.bool(forKey: "hasSeenOnboarding") {
            // User has seen onboarding, so go directly to main interface
            setupMainInterface(in: windowScene)
        } else {
            // User hasn't seen onboarding, show splash screen first
            let splashViewController = SplashViewController()
            window?.rootViewController = splashViewController
        }
        
        // Make the window visible
        window?.makeKeyAndVisible()
    }
    
    // Set up global UI appearance
    private func setupAppAppearance() {
        // Navigation bar appearance
        let navBarAppearance = AppTheme.configureNavigationBarAppearance()
        UINavigationBar.appearance().standardAppearance = navBarAppearance
        UINavigationBar.appearance().compactAppearance = navBarAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navBarAppearance
        UINavigationBar.appearance().tintColor = .white // Navigation bar items color
        
        // Tab bar appearance
        let tabBarAppearance = AppTheme.configureTabBarAppearance()
        UITabBar.appearance().standardAppearance = tabBarAppearance
        if #available(iOS 15.0, *) {
            UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
        }
        UITabBar.appearance().tintColor = AppTheme.primaryColor
        
        // Other global styles
        UISwitch.appearance().onTintColor = AppTheme.primaryColor
        UISlider.appearance().tintColor = AppTheme.primaryColor
        UISegmentedControl.appearance().selectedSegmentTintColor = AppTheme.primaryColor
        UISegmentedControl.appearance().setTitleTextAttributes([.foregroundColor: UIColor.white], for: .selected)
    }
    
    // This method is called from the SplashViewController or OnboardingViewController
    func setupMainInterface(in windowScene: UIWindowScene) {
        // Create the tab bar controller
        let tabBarController = UITabBarController()
        
        // Create the earthquake list view controller
        let earthquakeListViewController = EarthquakeListViewController()
        let listNavigationController = UINavigationController(rootViewController: earthquakeListViewController)
        listNavigationController.tabBarItem = UITabBarItem(title: "Depremler", image: UIImage(systemName: "list.bullet"), tag: 0)
        
        // Create the AI powered view controller
        let personalizedViewController = PersonalizedViewController()
        let personalizedNavigationController = UINavigationController(rootViewController: personalizedViewController)
        personalizedNavigationController.tabBarItem = UITabBarItem(title: "Kişiselleştirilmiş", image: UIImage(systemName: "person.fill.viewfinder"), tag: 1)
        
        // Create AI extensions view controller
        let aiExtensionsViewController = AIExtensionsViewController()
        let aiNavigationController = UINavigationController(rootViewController: aiExtensionsViewController)
        aiNavigationController.tabBarItem = UITabBarItem(title: "AI Eklentileri", image: UIImage(systemName: "brain"), tag: 2)
        
        // Set the tab bar items
        tabBarController.viewControllers = [listNavigationController, personalizedNavigationController, aiNavigationController]
        
        // Apply the navigation appearance to each navigation controller
        configureNavigationBarAppearance(for: listNavigationController)
        configureNavigationBarAppearance(for: personalizedNavigationController)
        configureNavigationBarAppearance(for: aiNavigationController)
        
        // Set the tab bar controller as the root view controller using main thread
        DispatchQueue.main.async {
            self.window?.rootViewController = tabBarController
            // Add transition animation
            let transition = CATransition()
            transition.type = .fade
            transition.duration = 0.3
            self.window?.layer.add(transition, forKey: nil)
        }
    }
    
    private func configureNavigationBarAppearance(for navigationController: UINavigationController) {
        let appearance = AppTheme.configureNavigationBarAppearance()
        navigationController.navigationBar.standardAppearance = appearance
        navigationController.navigationBar.scrollEdgeAppearance = appearance
        navigationController.navigationBar.compactAppearance = appearance
        navigationController.navigationBar.tintColor = .white
        
        // Make navigation bar use large titles
        navigationController.navigationBar.prefersLargeTitles = true
    }
}
