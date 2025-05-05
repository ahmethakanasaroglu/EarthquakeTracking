import UIKit
import MapKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    
    var window: UIWindow?
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        
        setupAppAppearance()
        
        window = UIWindow(windowScene: windowScene)
        
        let splashViewController = SplashViewController()
        window?.rootViewController = splashViewController
        
        window?.makeKeyAndVisible()
    }
    
    private func setupAppAppearance() {

        let navBarAppearance = AppTheme.configureNavigationBarAppearance()
        UINavigationBar.appearance().standardAppearance = navBarAppearance
        UINavigationBar.appearance().compactAppearance = navBarAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navBarAppearance
        UINavigationBar.appearance().tintColor = .white
        
        let tabBarAppearance = AppTheme.configureTabBarAppearance()
        UITabBar.appearance().standardAppearance = tabBarAppearance
        if #available(iOS 15.0, *) {
            UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
        }
        UITabBar.appearance().tintColor = AppTheme.primaryColor
        
        UISwitch.appearance().onTintColor = AppTheme.primaryColor
        UISlider.appearance().tintColor = AppTheme.primaryColor
        UISegmentedControl.appearance().selectedSegmentTintColor = AppTheme.primaryColor
        UISegmentedControl.appearance().setTitleTextAttributes([.foregroundColor: UIColor.white], for: .selected)
    }
    
    func setupMainInterface(in windowScene: UIWindowScene) {

        let tabBarController = UITabBarController()
        

        let earthquakeListViewController = EarthquakeListViewController()
        let listNavigationController = UINavigationController(rootViewController: earthquakeListViewController)
        listNavigationController.tabBarItem = UITabBarItem(title: "Depremler", image: UIImage(systemName: "list.bullet"), tag: 0)
        

        let personalizedViewController = PersonalizedViewController()
        let personalizedNavigationController = UINavigationController(rootViewController: personalizedViewController)
        personalizedNavigationController.tabBarItem = UITabBarItem(title: "Kişiselleştirilmiş", image: UIImage(systemName: "person.fill.viewfinder"), tag: 1)
        

        let aiExtensionsViewController = AIExtensionsViewController()
        let aiNavigationController = UINavigationController(rootViewController: aiExtensionsViewController)
        aiNavigationController.tabBarItem = UITabBarItem(title: "AI Eklentileri", image: UIImage(systemName: "brain"), tag: 2)
        

        tabBarController.viewControllers = [listNavigationController, personalizedNavigationController, aiNavigationController]
        

        configureNavigationBarAppearance(for: listNavigationController)
        configureNavigationBarAppearance(for: personalizedNavigationController)
        configureNavigationBarAppearance(for: aiNavigationController)
        

        DispatchQueue.main.async {
            UIView.transition(with: self.window!, duration: 0.3, options: .transitionCrossDissolve, animations: {
                self.window?.rootViewController = tabBarController
            }, completion: nil)
        }
    }
    
    private func configureNavigationBarAppearance(for navigationController: UINavigationController) {
        let appearance = AppTheme.configureNavigationBarAppearance()
        navigationController.navigationBar.standardAppearance = appearance
        navigationController.navigationBar.scrollEdgeAppearance = appearance
        navigationController.navigationBar.compactAppearance = appearance
        navigationController.navigationBar.tintColor = .white
        

        navigationController.navigationBar.prefersLargeTitles = true
    }
}
