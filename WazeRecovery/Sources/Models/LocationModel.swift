import Foundation
import CoreLocation

/// Reconstructed from WSVLocationSpeed model (0x107f4edd8) in Waze ARM64 executable.
/// Encapsulates raw GPS telemetry and normalized sensor state.
public final class WSVLocationSpeed: NSObject, Codable {
    public let latitude: Double
    public let longitude: Double
    public let altitude: Double
    public let speedMetersPerSecond: Double
    public let courseDegrees: Double
    public let horizontalAccuracy: Double
    public let timestamp: Date

    public init(latitude: Double,
                longitude: Double,
                altitude: Double = 0.0,
                speedMetersPerSecond: Double = 0.0,
                courseDegrees: Double = 0.0,
                horizontalAccuracy: Double = 5.0,
                timestamp: Date = Date()) {
        self.latitude = latitude
        self.longitude = longitude
        self.altitude = altitude
        self.speedMetersPerSecond = max(0.0, speedMetersPerSecond)
        self.courseDegrees = courseDegrees
        self.horizontalAccuracy = horizontalAccuracy
        self.timestamp = timestamp
        super.init()
    }

    public convenience init(clLocation: CLLocation) {
        self.init(latitude: clLocation.coordinate.latitude,
                  longitude: clLocation.coordinate.longitude,
                  altitude: clLocation.altitude,
                  speedMetersPerSecond: clLocation.speed,
                  courseDegrees: clLocation.course,
                  horizontalAccuracy: clLocation.horizontalAccuracy,
                  timestamp: clLocation.timestamp)
    }

    /// Speed converted to kilometers per hour (km/h) for Waze speedometer.
    public var speedKmPerHour: Double {
        speedMetersPerSecond * 3.6
    }

    /// Speed converted to miles per hour (mph).
    public var speedMilesPerHour: Double {
        speedMetersPerSecond * 2.23694
    }

    public var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}
