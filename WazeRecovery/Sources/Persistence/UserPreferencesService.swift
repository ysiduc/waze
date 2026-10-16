import Foundation

/// Reconstructed local settings and preferences store.
public final class UserPreferencesService {
    public static let shared = UserPreferencesService()

    private let defaults = UserDefaults.standard

    private enum Keys {
        static let isGuestMode = "waze_recovery_is_guest_mode"
        static let guestSessionId = "waze_recovery_guest_session_id"
        static let hasCompletedOnboarding = "waze_recovery_completed_onboarding"
        static let speedUnitsMetric = "waze_recovery_speed_units_metric"
        static let avoidTolls = "waze_recovery_avoid_tolls"
        static let avoidFreeways = "waze_recovery_avoid_freeways"
    }

    public var isGuestMode: Bool {
        get { defaults.bool(forKey: Keys.isGuestMode) }
        set { defaults.set(newValue, forKey: Keys.isGuestMode) }
    }

    public var guestSessionId: String? {
        get { defaults.string(forKey: Keys.guestSessionId) }
        set { defaults.set(newValue, forKey: Keys.guestSessionId) }
    }

    public var hasCompletedOnboarding: Bool {
        get { defaults.bool(forKey: Keys.hasCompletedOnboarding) }
        set { defaults.set(newValue, forKey: Keys.hasCompletedOnboarding) }
    }

    public var isSpeedUnitsMetric: Bool {
        get { defaults.object(forKey: Keys.speedUnitsMetric) as? Bool ?? true }
        set { defaults.set(newValue, forKey: Keys.speedUnitsMetric) }
    }

    public var avoidTolls: Bool {
        get { defaults.bool(forKey: Keys.avoidTolls) }
        set { defaults.set(newValue, forKey: Keys.avoidTolls) }
    }

    public var avoidFreeways: Bool {
        get { defaults.bool(forKey: Keys.avoidFreeways) }
        set { defaults.set(newValue, forKey: Keys.avoidFreeways) }
    }

    /// Initializes an anonymous guest session token.
    public func startGuestSession() -> String {
        let sessionId = UUID().uuidString
        self.isGuestMode = true
        self.guestSessionId = sessionId
        self.hasCompletedOnboarding = true
        KeychainStorageService.shared.setString(sessionId, forKey: "waze_guest_session_token")
        return sessionId
    }

    /// Resets all session data.
    public func resetSession() {
        self.isGuestMode = false
        self.guestSessionId = nil
        KeychainStorageService.shared.delete(forKey: "waze_guest_session_token")
    }
}
