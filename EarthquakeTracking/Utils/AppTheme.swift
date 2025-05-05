import UIKit

struct AppTheme {
    // MARK: - Primary Colors
    static let primaryColor = UIColor(red: 0/255, green: 101/255, blue: 163/255, alpha: 1) // Deep Blue
    static let primaryLightColor = UIColor(red: 41/255, green: 128/255, blue: 185/255, alpha: 1) // Medium Blue
    
    // MARK: - Secondary Colors
    static let secondaryColor = UIColor(red: 231/255, green: 76/255, blue: 60/255, alpha: 1) // Warning Red
    static let accentColor = UIColor(red: 241/255, green: 196/255, blue: 15/255, alpha: 1) // Alert Yellow
    
    // MARK: - Background Colors
    static let backgroundColor = UIColor.systemBackground
    static let secondaryBackgroundColor = UIColor.secondarySystemBackground
    static let tertiaryBackgroundColor = UIColor(red: 235/255, green: 243/255, blue: 250/255, alpha: 1) // Light Blue Background
    
    // MARK: - Text Colors
    static let titleTextColor = UIColor.label
    static let bodyTextColor = UIColor.secondaryLabel
    static let lightTextColor = UIColor.tertiaryLabel
    
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
        view.backgroundColor = backgroundColor
        view.layer.cornerRadius = 16
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOffset = CGSize(width: 0, height: 2)
        view.layer.shadowRadius = 6
        view.layer.shadowOpacity = 0.1
    }
    
    // MARK: - Nav Bar and Tab Bar Styling
    static func configureNavigationBarAppearance() -> UINavigationBarAppearance {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = primaryColor
        appearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
        
        return appearance
    }
    
    static func configureTabBarAppearance() -> UITabBarAppearance {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = backgroundColor
        
        // Configure selected icon and title colors
        let selected = UITabBarItemAppearance()
        selected.normal.iconColor = primaryColor
        selected.normal.titleTextAttributes = [NSAttributedString.Key.foregroundColor: primaryColor]
        
        appearance.stackedLayoutAppearance = selected
        
        return appearance
    }
}

enum ButtonStyle {
    case primary
    case secondary
    case accent
    case danger
}
