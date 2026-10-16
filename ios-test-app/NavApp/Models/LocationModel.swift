import Foundation
import CoreLocation

public struct LocationModel: Equatable {
    public let coordinate: CLLocationCoordinate2D
    public let altitude: Double
    public let horizontalAccuracy: Double
    public let speedMps: Double
    public let course: Double
    public let timestamp: Date
    
    public var speedKph: Double {
        return speedMps > 0 ? (speedMps * 3.6) : 0
    }
    
    public var speedMph: Double {
        return speedMps > 0 ? (speedMps * 2.23694) : 0
    }
    
    public var isValid: Bool {
        return horizontalAccuracy >= 0 && horizontalAccuracy <= 100
    }
    
    public init(coordinate: CLLocationCoordinate2D,
                altitude: Double = 0,
                horizontalAccuracy: Double = 5,
                speedMps: Double = 0,
                course: Double = 0,
                timestamp: Date = Date()) {
        self.coordinate = coordinate
        self.altitude = altitude
        self.horizontalAccuracy = horizontalAccuracy
        self.speedMps = speedMps
        self.course = course
        self.timestamp = timestamp
    }
    
    public static func fromCLLocation(_ location: CLLocation) -> LocationModel {
        return LocationModel(
            coordinate: location.coordinate,
            altitude: location.altitude,
            horizontalAccuracy: location.horizontalAccuracy,
            speedMps: max(0, location.speed),
            course: location.course,
            timestamp: location.timestamp
        )
    }
    
    public static func == (lhs: LocationModel, rhs: LocationModel) -> Bool {
        return lhs.coordinate.latitude == rhs.coordinate.latitude &&
               lhs.coordinate.longitude == rhs.coordinate.longitude &&
               lhs.speedMps == rhs.speedMps &&
               lhs.course == rhs.course &&
               lhs.horizontalAccuracy == rhs.horizontalAccuracy
    }
}
