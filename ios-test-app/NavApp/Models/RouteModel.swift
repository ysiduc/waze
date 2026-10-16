import Foundation
import MapKit

public struct RouteModel: Identifiable, Equatable {
    public let id: UUID
    public let name: String
    public let totalDistanceMeters: Double
    public let totalExpectedTimeSeconds: TimeInterval
    public let steps: [GuidanceStep]
    public let polylineCoordinates: [CLLocationCoordinate2D]
    public let isPrimary: Bool
    
    public init(id: UUID = UUID(),
                name: String,
                totalDistanceMeters: Double,
                totalExpectedTimeSeconds: TimeInterval,
                steps: [GuidanceStep],
                polylineCoordinates: [CLLocationCoordinate2D],
                isPrimary: Bool = true) {
        self.id = id
        self.name = name
        self.totalDistanceMeters = totalDistanceMeters
        self.totalExpectedTimeSeconds = totalExpectedTimeSeconds
        self.steps = steps
        self.polylineCoordinates = polylineCoordinates
        self.isPrimary = isPrimary
    }
    
    public static func fromMKRoute(_ route: MKRoute, name: String, isPrimary: Bool) -> RouteModel {
        var steps: [GuidanceStep] = []
        for (idx, step) in route.steps.enumerated() {
            guard !step.instructions.isEmpty else { continue }
            let maneuver = ManeuverType.fromInstruction(step.instructions)
            steps.append(GuidanceStep(
                stepIndex: idx,
                instruction: step.instructions,
                distanceMeters: step.distance,
                maneuver: maneuver,
                coordinate: step.polyline.coordinate
            ))
        }
        
        let pointCount = route.polyline.pointCount
        var coords = [CLLocationCoordinate2D](repeating: kCLLocationCoordinate2DInvalid, count: pointCount)
        route.polyline.getCoordinates(&coords, range: NSRange(location: 0, length: pointCount))
        
        return RouteModel(
            name: name,
            totalDistanceMeters: route.distance,
            totalExpectedTimeSeconds: route.expectedTravelTime,
            steps: steps,
            polylineCoordinates: coords,
            isPrimary: isPrimary
        )
    }
    
    public static func == (lhs: RouteModel, rhs: RouteModel) -> Bool {
        return lhs.id == rhs.id &&
               lhs.name == rhs.name &&
               lhs.totalDistanceMeters == rhs.totalDistanceMeters &&
               lhs.totalExpectedTimeSeconds == rhs.totalExpectedTimeSeconds &&
               lhs.isPrimary == rhs.isPrimary &&
               lhs.steps == rhs.steps
    }
}
