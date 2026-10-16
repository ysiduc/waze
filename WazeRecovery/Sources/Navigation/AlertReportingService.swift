import Foundation
import CoreLocation

public protocol AlertReportingServiceDelegate: AnyObject {
    func alertReportingService(_ service: AlertReportingService, didRaiseWarning warning: WZAlertWarning)
    func alertReportingService(_ service: AlertReportingService, didDismissWarning warning: WZAlertWarning)
}

/// Service managing spatial alerts, proximity hazard warnings, and community incident reports.
/// Reconstructed from AlertReportButtonData & HazardAlert subsystems in Waze ARM64 executable.
public final class AlertReportingService {
    public static let shared = AlertReportingService()

    public weak var delegate: AlertReportingServiceDelegate?

    private var activeAlerts: [WZHazardAlert] = []
    private var currentWarning: WZAlertWarning?
    private let warningRadiusMeters: Double = 500.0 // Warn 500m before hazard

    public init() {
        populateDefaultSanFranciscoHazards()
    }

    private func populateDefaultSanFranciscoHazards() {
        activeAlerts = [
            WZHazardAlert(
                type: .police,
                coordinate: WZCoordinate(latitude: 37.7795, longitude: -122.4135),
                title: "Police reported ahead",
                subtitle: "Market St & 7th St",
                upvotes: 14
            ),
            WZHazardAlert(
                type: .speedCamera,
                coordinate: WZCoordinate(latitude: 37.7850, longitude: -122.4080),
                title: "Speed camera (45 km/h)",
                subtitle: "Mission St",
                upvotes: 42,
                speedLimitKmh: 45.0
            ),
            WZHazardAlert(
                type: .hazardOnRoad,
                coordinate: WZCoordinate(latitude: 37.7910, longitude: -122.4020),
                title: "Object on road",
                subtitle: "Right lane blocked",
                upvotes: 8
            ),
            WZHazardAlert(
                type: .trafficJam,
                coordinate: WZCoordinate(latitude: 37.8000, longitude: -122.4100),
                title: "Heavy traffic jam",
                subtitle: "Average speed 12 km/h",
                upvotes: 27,
                severity: .heavy
            )
        ]
    }

    /// Spatial query: returns all hazards within radiusMeters of coordinate.
    public func alerts(near center: WZCoordinate, radiusMeters: Double = 2000.0) -> [WZHazardAlert] {
        return activeAlerts.filter { alert in
            let dist = haversineDistance(from: center, to: alert.coordinate)
            return dist <= radiusMeters
        }
    }

    /// Submits a user-reported hazard incident.
    public func reportHazard(type: WZHazardType, coordinate: WZCoordinate, title: String, subtitle: String = "") -> WZHazardAlert {
        let alert = WZHazardAlert(
            type: type,
            coordinate: coordinate,
            title: title,
            subtitle: subtitle,
            reportedAt: Date(),
            upvotes: 1,
            isConfirmed: false
        )
        activeAlerts.append(alert)
        return alert
    }

    /// Evaluates current position and heading along route to trigger or dismiss proximity warnings.
    public func updateLocation(_ location: WZCoordinate, headingDegrees: Double = 0.0) -> WZAlertWarning? {
        // Find nearest alert ahead
        var nearestAlert: WZHazardAlert?
        var nearestDist = Double.greatestFiniteMagnitude

        for alert in activeAlerts {
            let dist = haversineDistance(from: location, to: alert.coordinate)

            if dist <= warningRadiusMeters && dist < nearestDist {
                // Check if alert is roughly in the direction of travel
                let bearingToAlert = initialBearing(from: location, to: alert.coordinate)
                let angleDiff = abs(bearingToAlert - headingDegrees)
                let normDiff = min(angleDiff, 360.0 - angleDiff)

                // If moving and alert is within 90 degrees forward cone, or if stationary
                if headingDegrees == 0.0 || normDiff < 90.0 {
                    nearestDist = dist
                    nearestAlert = alert
                }
            }
        }

        if let alert = nearestAlert {
            let warning = WZAlertWarning(
                alert: alert,
                distanceMeters: nearestDist,
                message: "\(alert.title) in \(Int(nearestDist))m"
            )
            if currentWarning != warning {
                currentWarning = warning
                delegate?.alertReportingService(self, didRaiseWarning: warning)
            }
            return warning
        } else {
            if let old = currentWarning {
                currentWarning = nil
                delegate?.alertReportingService(self, didDismissWarning: old)
            }
            return nil
        }
    }
}
