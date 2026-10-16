import Foundation
import CoreLocation

// MARK: - Core Common Types

/// Geodesic point in WGS84 coordinate system.
public struct WZCoordinate: Equatable, Hashable, Codable {
    public var latitude: Double
    public var longitude: Double
    public var altitude: Double

    public init(latitude: Double, longitude: Double, altitude: Double = 0.0) {
        self.latitude = latitude
        self.longitude = longitude
        self.altitude = altitude
    }

    public var clCoordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    public init(clCoordinate: CLLocationCoordinate2D, altitude: Double = 0.0) {
        self.latitude = clCoordinate.latitude
        self.longitude = clCoordinate.longitude
        self.altitude = altitude
    }
}

/// Great-circle distance in meters between two coordinates.
public func haversineDistance(from: WZCoordinate, to: WZCoordinate) -> Double {
    let r = 6371008.8 // Earth radius in meters
    let lat1 = from.latitude * .pi / 180.0
    let lon1 = from.longitude * .pi / 180.0
    let lat2 = to.latitude * .pi / 180.0
    let lon2 = to.longitude * .pi / 180.0

    let dLat = lat2 - lat1
    let dLon = lon2 - lon1

    let a = sin(dLat / 2) * sin(dLat / 2) +
            cos(lat1) * cos(lat2) * sin(dLon / 2) * sin(dLon / 2)
    let c = 2 * atan2(sqrt(a), sqrt(1 - a))
    return r * c
}

/// Initial bearing from source to destination coordinate in degrees [0, 360).
public func initialBearing(from: WZCoordinate, to: WZCoordinate) -> Double {
    let lat1 = from.latitude * .pi / 180.0
    let lat2 = to.latitude * .pi / 180.0
    let dLon = (to.longitude - from.longitude) * .pi / 180.0

    let y = sin(dLon) * cos(lat2)
    let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon)

    let radians = atan2(y, x)
    let degrees = radians * 180.0 / .pi
    return fmod(degrees + 360.0, 360.0)
}
