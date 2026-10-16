import Foundation
import CoreLocation

/// Represents a single maneuver step along a route.
public struct WZRouteStep: Codable, Equatable {
    public let maneuver: WZManeuverType
    public let instruction: String
    public let streetName: String
    public let distanceMeters: Double
    public let durationSeconds: Double
    public let coordinate: WZCoordinate

    public init(maneuver: WZManeuverType,
                instruction: String,
                streetName: String,
                distanceMeters: Double,
                durationSeconds: Double,
                coordinate: WZCoordinate) {
        self.maneuver = maneuver
        self.instruction = instruction
        self.streetName = streetName
        self.distanceMeters = distanceMeters
        self.durationSeconds = durationSeconds
        self.coordinate = coordinate
    }
}

/// Reconstructed from RoutingServiceRoute model in Waze ARM64 executable.
public struct WZRoute: Codable, Equatable, Identifiable {
    public var id: String { routeId }
    public let routeId: String
    public let summary: String
    public let totalDistanceMeters: Double
    public let totalDurationSeconds: Double
    public let polylineCoordinates: [WZCoordinate]
    public let steps: [WZRouteStep]
    public let isAlternative: Bool
    public let viaDescription: String

    public init(routeId: String,
                summary: String,
                totalDistanceMeters: Double,
                totalDurationSeconds: Double,
                polylineCoordinates: [WZCoordinate],
                steps: [WZRouteStep],
                isAlternative: Bool = false,
                viaDescription: String = "") {
        self.routeId = routeId
        self.summary = summary
        self.totalDistanceMeters = totalDistanceMeters
        self.totalDurationSeconds = totalDurationSeconds
        self.polylineCoordinates = polylineCoordinates
        self.steps = steps
        self.isAlternative = isAlternative
        self.viaDescription = viaDescription
    }

    /// Formatted ETA string (e.g. "18 min").
    public var formattedDuration: String {
        let minutes = Int(ceil(totalDurationSeconds / 60.0))
        if minutes >= 60 {
            let hours = minutes / 60
            let remMin = minutes % 60
            return "\(hours) hr \(remMin) min"
        } else {
            return "\(max(1, minutes)) min"
        }
    }

    /// Formatted distance string (e.g. "5.4 km" or "3.2 mi").
    public var formattedDistanceKm: String {
        let km = totalDistanceMeters / 1000.0
        return String(format: "%.1f km", km)
    }

    /// Estimated arrival time based on current time.
    public var estimatedArrivalDate: Date {
        Date().addingTimeInterval(totalDurationSeconds)
    }

    public var formattedArrivalTime: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: estimatedArrivalDate)
    }
}
