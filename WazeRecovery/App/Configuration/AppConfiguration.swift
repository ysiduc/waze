import Foundation

/// Reconstructed application configuration and feature flags.
public struct AppConfiguration {
    public static let appName = "Waze"
    public static let appVersion = "5.22.0"
    public static let buildNumber = "1"
    public static let bundleIdentifier = "com.waze.iphone"

    // Feature Flags (reconstructed from Swift reflection feature managers)
    public static var isAlternativeRoutesEnabled: Bool = true
    public static var isEcoRoutesEnabled: Bool = true
    public static var isCarPlayEnabled: Bool = true
    public static var isSpeedometerEnabled: Bool = true
    public static var isOfflineRoutingEnabled: Bool = true
}
