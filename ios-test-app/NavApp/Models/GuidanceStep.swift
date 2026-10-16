import Foundation
import CoreLocation

public struct GuidanceStep: Identifiable, Equatable {
    public let id: UUID
    public let stepIndex: Int
    public let instruction: String
    public let distanceMeters: Double
    public let maneuver: ManeuverType
    public let coordinate: CLLocationCoordinate2D
    
    public init(id: UUID = UUID(),
                stepIndex: Int,
                instruction: String,
                distanceMeters: Double,
                maneuver: ManeuverType,
                coordinate: CLLocationCoordinate2D) {
        self.id = id
        self.stepIndex = stepIndex
        self.instruction = instruction
        self.distanceMeters = distanceMeters
        self.maneuver = maneuver
        self.coordinate = coordinate
    }
    
    public static func == (lhs: GuidanceStep, rhs: GuidanceStep) -> Bool {
        return lhs.id == rhs.id &&
               lhs.stepIndex == rhs.stepIndex &&
               lhs.instruction == rhs.instruction &&
               lhs.distanceMeters == rhs.distanceMeters &&
               lhs.maneuver == rhs.maneuver &&
               lhs.coordinate.latitude == rhs.coordinate.latitude &&
               lhs.coordinate.longitude == rhs.coordinate.longitude
    }
}
