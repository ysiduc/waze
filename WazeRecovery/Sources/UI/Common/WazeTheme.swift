import UIKit

/// Reconstructed Waze design system tokens, typography, and color palette.
public struct WazeTheme {
    // Colors
    public static let cyan = UIColor(red: 0.20, green: 0.80, blue: 1.00, alpha: 1.00) // #33CCFF
    public static let darkBlue = UIColor(red: 0.17, green: 0.23, blue: 0.29, alpha: 1.00) // #2B3B4B
    public static let canvasGrey = UIColor(red: 0.95, green: 0.96, blue: 0.97, alpha: 1.00) // #F2F4F7
    public static let surfaceWhite = UIColor.white
    public static let alertRed = UIColor(red: 1.00, green: 0.23, blue: 0.19, alpha: 1.00) // #FF3B30
    public static let warningYellow = UIColor(red: 1.00, green: 0.80, blue: 0.00, alpha: 1.00) // #FFCC00
    public static let trafficGreen = UIColor(red: 0.20, green: 0.78, blue: 0.35, alpha: 1.00) // #34C759
    public static let textPrimary = UIColor(red: 0.10, green: 0.13, blue: 0.17, alpha: 1.00)
    public static let textSecondary = UIColor(red: 0.50, green: 0.55, blue: 0.60, alpha: 1.00)

    // Typography
    public static func titleFont(size: CGFloat = 22) -> UIFont {
        if let desc = UIFont.systemFont(ofSize: size, weight: .bold).fontDescriptor.withDesign(.rounded) {
            return UIFont(descriptor: desc, size: size)
        }
        return UIFont.boldSystemFont(ofSize: size)
    }

    public static func headlineFont(size: CGFloat = 17) -> UIFont {
        if let desc = UIFont.systemFont(ofSize: size, weight: .semibold).fontDescriptor.withDesign(.rounded) {
            return UIFont(descriptor: desc, size: size)
        }
        return UIFont.systemFont(ofSize: size, weight: .semibold)
    }

    public static func bodyFont(size: CGFloat = 15) -> UIFont {
        return UIFont.systemFont(ofSize: size, weight: .regular)
    }

    public static func captionFont(size: CGFloat = 12) -> UIFont {
        return UIFont.systemFont(ofSize: size, weight: .medium)
    }
}
