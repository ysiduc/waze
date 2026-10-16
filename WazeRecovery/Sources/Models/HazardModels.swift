import Foundation
import CoreLocation

/// Reconstructed from Waze hazard and incident reporting models:
/// AlertReportButtonData, HazardAlert, TrafficJam, PoliceAlert, SpeedCamera.
public enum WZHazardType: String, CaseIterable, Codable {
    case police = "police"
    case accident = "accident"
    case trafficJam = "traffic_jam"
    case hazardOnRoad = "hazard_on_road"
    case speedCamera = "speed_camera"
    case roadClosure = "road_closure"

    public var displayName: String {
        switch self {
        case .police: return "Police"
        case .accident: return "Accident"
        case .trafficJam: return "Traffic Jam"
        case .hazardOnRoad: return "Hazard on Road"
        case .speedCamera: return "Speed Camera"
        case .roadClosure: return "Closure"
        }
    }

    public var iconName: String {
        switch self {
        case .police: return "shield.fill"
        case .accident: return "car.2.fill"
        case .trafficJam: return "hourglass"
        case .hazardOnRoad: return "exclamationmark.triangle.fill"
        case .speedCamera: return "camera.fill"
        case .roadClosure: return "nosign"
        }
    }
}

public enum WZTrafficSeverity: String, Codable {
    case light = "light"
    case moderate = "moderate"
    case heavy = "heavy"
    case standstill = "standstill"
}

/// Represents an authentic crowdsourced Waze alert along the road network.
public struct WZHazardAlert: Identifiable, Codable {
    public let id: String
    public let type: WZHazardType
    public let coordinate: WZCoordinate
    public let title: String
    public let subtitle: String
    public let reportedAt: Date
    public var upvotes: Int
    public var isConfirmed: Bool
    public var speedLimitKmh: Double?
    public var severity: WZTrafficSeverity?

    public init(id: String = UUID().uuidString,
                type: WZHazardType,
                coordinate: WZCoordinate,
                title: String,
                subtitle: String = "",
                reportedAt: Date = Date(),
                upvotes: Int = 1,
                isConfirmed: Bool = true,
                speedLimitKmh: Double? = nil,
                severity: WZTrafficSeverity? = nil) {
        self.id = id
        self.type = type
        self.coordinate = coordinate
        self.title = title
        self.subtitle = subtitle
        self.reportedAt = reportedAt
        self.upvotes = upvotes
        self.isConfirmed = isConfirmed
        self.speedLimitKmh = speedLimitKmh
        self.severity = severity
    }
}

/// Represents an active proximity warning raised to the driver.
public struct WZAlertWarning: Equatable {
    public let alert: WZHazardAlert
    public let distanceMeters: Double
    public let message: String

    public static func == (lhs: WZAlertWarning, rhs: WZAlertWarning) -> Bool {
        return lhs.alert.id == rhs.alert.id && abs(lhs.distanceMeters - rhs.distanceMeters) < 1.0
    }
}
