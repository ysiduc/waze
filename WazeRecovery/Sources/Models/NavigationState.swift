import Foundation

public enum WZNavigationStatus: String, Codable {
    case idle = "idle"
    case routePlanning = "route_planning"
    case navigating = "navigating"
    case rerouting = "rerouting"
    case arrived = "arrived"
}

/// Navigation guidance state model containing properties verified in Swift reflection (__swift5_reflstr):
/// - distanceToTurn
/// - isApproachingTurn
/// - showSpeedometer
public struct WZNavigationState: Equatable, Codable {
    public var status: WZNavigationStatus
    public var activeRoute: WZRoute?
    public var currentStepIndex: Int
    public var distanceToTurnMeters: Double
    public var isApproachingTurn: Bool
    public var currentManeuver: WZManeuverType
    public var currentInstruction: String
    public var currentStreetName: String
    public var remainingDistanceMeters: Double
    public var remainingDurationSeconds: Double
    public var showSpeedometer: Bool
    public var currentSpeedKmH: Double
    public var speedLimitKmH: Double?

    public init(status: WZNavigationStatus = .idle,
                activeRoute: WZRoute? = nil,
                currentStepIndex: Int = 0,
                distanceToTurnMeters: Double = 0.0,
                isApproachingTurn: Bool = false,
                currentManeuver: WZManeuverType = .depart,
                currentInstruction: String = "",
                currentStreetName: String = "",
                remainingDistanceMeters: Double = 0.0,
                remainingDurationSeconds: Double = 0.0,
                showSpeedometer: Bool = true,
                currentSpeedKmH: Double = 0.0,
                speedLimitKmH: Double? = 60.0) {
        self.status = status
        self.activeRoute = activeRoute
        self.currentStepIndex = currentStepIndex
        self.distanceToTurnMeters = distanceToTurnMeters
        self.isApproachingTurn = isApproachingTurn
        self.currentManeuver = currentManeuver
        self.currentInstruction = currentInstruction
        self.currentStreetName = currentStreetName
        self.remainingDistanceMeters = remainingDistanceMeters
        self.remainingDurationSeconds = remainingDurationSeconds
        self.showSpeedometer = showSpeedometer
        self.currentSpeedKmH = currentSpeedKmH
        self.speedLimitKmH = speedLimitKmH
    }

    /// Formatted turn distance (e.g. "500 m" or "1.2 km").
    public var formattedDistanceToTurn: String {
        if distanceToTurnMeters >= 1000.0 {
            return String(format: "%.1f km", distanceToTurnMeters / 1000.0)
        } else {
            return "\(Int(distanceToTurnMeters)) m"
        }
    }
}
