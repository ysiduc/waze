import Foundation

public enum NavigationStatus: String, Equatable {
    case idle
    case searching
    case previewingRoute
    case navigating
    case rerouting
    case arrived
}

public struct NavigationMetrics: Equatable {
    public var remainingDistanceMeters: Double
    public var remainingTimeSeconds: TimeInterval
    public var estimatedArrivalTime: Date
    public var currentSpeedKph: Double
    
    public init(remainingDistanceMeters: Double = 0,
                remainingTimeSeconds: TimeInterval = 0,
                estimatedArrivalTime: Date = Date(),
                currentSpeedKph: Double = 0) {
        self.remainingDistanceMeters = remainingDistanceMeters
        self.remainingTimeSeconds = remainingTimeSeconds
        self.estimatedArrivalTime = estimatedArrivalTime
        self.currentSpeedKph = currentSpeedKph
    }
}
