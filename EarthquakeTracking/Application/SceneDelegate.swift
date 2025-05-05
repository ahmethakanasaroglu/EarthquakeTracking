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
        
        // Set the splash screen as the initial screen
        let splashViewController = SplashViewController()
        window?.rootViewController = splashViewController
        
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
        
        // Mevcut tab bar'a yeni bir sekme eklemek
        let aiExtensionsViewController = AIExtensionsViewController()
        let aiNavigationController = UINavigationController(rootViewController: aiExtensionsViewController)
        aiNavigationController.tabBarItem = UITabBarItem(title: "AI Eklentileri", image: UIImage(systemName: "brain"), tag: 2)
        
        // Set the tab bar items
        tabBarController.viewControllers = [listNavigationController, personalizedNavigationController, aiNavigationController]
        
        // Apply the navigation appearance to each navigation controller
        configureNavigationBarAppearance(for: listNavigationController)
        configureNavigationBarAppearance(for: personalizedNavigationController)
        configureNavigationBarAppearance(for: aiNavigationController)
        
        // Set the tab bar controller as the root view controller
        window?.rootViewController = tabBarController
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

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
    }
}
