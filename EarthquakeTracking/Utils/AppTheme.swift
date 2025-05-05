import UIKit

struct AppTheme {
    // MARK: - Primary Colors
    static let primaryColor = UIColor(red: 0/255, green: 101/255, blue: 163/255, alpha: 1) // Deep Blue
    static let primaryLightColor = UIColor(red: 41/255, green: 128/255, blue: 185/255, alpha: 1) // Medium Blue
    
    // MARK: - Secondary Colors
    static let secondaryColor = UIColor(red: 231/255, green: 76/255, blue: 60/255, alpha: 1) // Warning Red
    static let accentColor = UIColor(red: 241/255, green: 196/255, blue: 15/255, alpha: 1) // Alert Yellow
    
    // MARK: - Background Colors
    static let backgroundColor = UIColor(red: 247/255, green: 250/255, blue: 252/255, alpha: 1) // Light Blue-Gray Background
    static let secondaryBackgroundColor = UIColor(red: 241/255, green: 245/255, blue: 249/255, alpha: 1) // Lighter Gray-Blue
    static let tertiaryBackgroundColor = UIColor(red: 235/255, green: 243/255, blue: 250/255, alpha: 1) // Light Blue Background
    
    // MARK: - Gradient Colors
    static let gradientStartColor = UIColor(red: 229/255, green: 239/255, blue: 245/255, alpha: 1)
    static let gradientEndColor = UIColor(red: 242/255, green: 249/255, blue: 251/255, alpha: 1)
    
    // MARK: - Text Colors
    static let titleTextColor = UIColor(red: 10/255, green: 24/255, blue: 50/255, alpha: 1) // Dark Blue-Gray
    static let bodyTextColor = UIColor(red: 71/255, green: 85/255, blue: 105/255, alpha: 1) // Medium Gray-Blue
    static let lightTextColor = UIColor(red: 148/255, green: 163/255, blue: 184/255, alpha: 1) // Light Gray-Blue
    
    // MARK: - Status Colors
    static let successColor = UIColor(red: 46/255, green: 204/255, blue: 113/255, alpha: 1) // Green
    static let warningColor = accentColor
    static let errorColor = secondaryColor
    
    // MARK: - Magnitude Colors (for earthquake magnitude visualization)
    static func magnitudeColor(for magnitude: Double) -> UIColor {
        switch magnitude {
        case 0..<3.0:
            return successColor
        case 3.0..<5.0:
            return UIColor(red: 241/255, green: 196/255, blue: 15/255, alpha: 1) // Yellow
        case 5.0..<6.0:
            return UIColor(red: 230/255, green: 126/255, blue: 34/255, alpha: 1) // Orange
        case 6.0...:
            return UIColor(red: 231/255, green: 76/255, blue: 60/255, alpha: 1) // Red
        default:
            return bodyTextColor
        }
    }
    
    // MARK: - UI Element Styles
    static func applyButtonStyle(to button: UIButton, style: ButtonStyle = .primary) {
        button.layer.cornerRadius = 12
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        
        switch style {
        case .primary:
            button.backgroundColor = primaryColor
            button.setTitleColor(.white, for: .normal)
            
            // Add subtle inner shadow for depth
            button.layer.shadowColor = UIColor.black.withAlphaComponent(0.1).cgColor
            button.layer.shadowOffset = CGSize(width: 0, height: 1)
            button.layer.shadowRadius = 2
            button.layer.shadowOpacity = 1
            button.layer.masksToBounds = false
        case .secondary:
            button.backgroundColor = .clear
            button.setTitleColor(primaryColor, for: .normal)
            button.layer.borderWidth = 1
            button.layer.borderColor = primaryColor.cgColor
        case .accent:
            button.backgroundColor = accentColor
            button.setTitleColor(.black, for: .normal)
        case .danger:
            button.backgroundColor = secondaryColor
            button.setTitleColor(.white, for: .normal)
        }
        
        button.contentEdgeInsets = UIEdgeInsets(top: 12, left: 20, bottom: 12, right: 20)
    }
    
    static func applyCardStyle(to view: UIView) {
        view.backgroundColor = .white
        view.layer.cornerRadius = 16
        view.layer.shadowColor = UIColor(red: 0/255, green: 0/255, blue: 0/255, alpha: 0.05).cgColor
        view.layer.shadowOffset = CGSize(width: 0, height: 4)
        view.layer.shadowRadius = 8
        view.layer.shadowOpacity = 1
        
        // Add subtle border for better definition
        view.layer.borderWidth = 1
        view.layer.borderColor = UIColor(red: 226/255, green: 232/255, blue: 240/255, alpha: 0.6).cgColor
    }
    
    // MARK: - Background Gradient
    static func applyBackgroundGradient(to view: UIView) {
        // Remove existing gradient layers
        view.layer.sublayers?.removeAll(where: { $0 is CAGradientLayer })
        
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = [
            gradientStartColor.cgColor,
            gradientEndColor.cgColor
        ]
        gradientLayer.locations = [0.0, 1.0]
        gradientLayer.startPoint = CGPoint(x: 0.0, y: 0.0)
        gradientLayer.endPoint = CGPoint(x: 1.0, y: 1.0)
        gradientLayer.frame = view.bounds
        
        view.layer.insertSublayer(gradientLayer, at: 0)
    }
    
    // MARK: - Nav Bar and Tab Bar Styling
    static func configureNavigationBarAppearance() -> UINavigationBarAppearance {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = primaryColor
        appearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
        
        // Add subtle shadow
        appearance.shadowColor = UIColor.black.withAlphaComponent(0.1)
        
        return appearance
    }
    
    static func configureTabBarAppearance() -> UITabBarAppearance {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .white
        
        // Add subtle shadow to top
        appearance.shadowColor = UIColor.black.withAlphaComponent(0.03)
        appearance.shadowImage = createShadowImage()
        
        // Configure selected icon and title colors
        let selected = UITabBarItemAppearance()
        selected.normal.iconColor = primaryColor
        selected.normal.titleTextAttributes = [NSAttributedString.Key.foregroundColor: primaryColor]
        
        // Configure unselected icon and title colors
        let unselected = UITabBarItemAppearance()
        unselected.normal.iconColor = lightTextColor
        unselected.normal.titleTextAttributes = [NSAttributedString.Key.foregroundColor: lightTextColor]
        
        appearance.stackedLayoutAppearance = selected
        appearance.inlineLayoutAppearance = selected
        appearance.compactInlineLayoutAppearance = selected
        
        return appearance
    }
    
    private static func createShadowImage() -> UIImage {
        let rect = CGRect(x: 0, y: 0, width: 1, height: 1)
        UIGraphicsBeginImageContext(rect.size)
        
        if let context = UIGraphicsGetCurrentContext() {
            let colors = [
                UIColor.black.withAlphaComponent(0.05).cgColor,
                UIColor.clear.cgColor
            ]
            
            let colorSpace = CGColorSpaceCreateDeviceRGB()
            let colorLocations: [CGFloat] = [0.0, 1.0]
            
            if let gradient = CGGradient(colorsSpace: colorSpace, colors: colors as CFArray, locations: colorLocations) {
                context.drawLinearGradient(gradient, start: CGPoint(x: 0, y: 0), end: CGPoint(x: 0, y: 1), options: [])
            }
        }
        
        let image = UIGraphicsGetImageFromCurrentImageContext() ?? UIImage()
        UIGraphicsEndImageContext()
        
        return image
    }
}

enum ButtonStyle {
    case primary
    case secondary
    case accent
    case danger
}
