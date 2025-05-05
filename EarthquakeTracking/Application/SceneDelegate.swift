import UIKit
import MapKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    
    var window: UIWindow?
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        
        // Create window with the correct windowScene
        window = UIWindow(windowScene: windowScene)
        
        // Set the splash screen as the initial screen
        let splashViewController = SplashViewController()
        window?.rootViewController = splashViewController
        
        // Make the window visible
        window?.makeKeyAndVisible()
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
        
        // Mevcut tab bar'a yeni bir sekme eklemek
        let aiExtensionsViewController = AIExtensionsViewController()
        let aiNavigationController = UINavigationController(rootViewController: aiExtensionsViewController)
        aiNavigationController.tabBarItem = UITabBarItem(title: "AI Eklentileri", image: UIImage(systemName: "brain"), tag: 2)
        
        // Set the tab bar items
        tabBarController.viewControllers = [listNavigationController, personalizedNavigationController, aiNavigationController]
        
        // Set the navigation appearance
        configureNavigationBarAppearance(for: listNavigationController)
        configureNavigationBarAppearance(for: personalizedNavigationController)
        configureNavigationBarAppearance(for: aiNavigationController)
        
        // Configure tab bar appearance
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithOpaqueBackground()
        tabBarAppearance.backgroundColor = .systemBackground
        
        tabBarController.tabBar.standardAppearance = tabBarAppearance
        if #available(iOS 15.0, *) {
            tabBarController.tabBar.scrollEdgeAppearance = tabBarAppearance
        }
        
        // Set the tab bar controller as the root view controller
        window?.rootViewController = tabBarController
    }
    
    private func configureNavigationBarAppearance(for navigationController: UINavigationController) {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .systemBackground
        appearance.titleTextAttributes = [.foregroundColor: UIColor.label]
        
        navigationController.navigationBar.standardAppearance = appearance
        navigationController.navigationBar.scrollEdgeAppearance = appearance
        navigationController.navigationBar.tintColor = .systemBlue
    }
}
