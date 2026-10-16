import Foundation

/// Deterministic, offline routing fixture service providing verified turn-by-turn routes for testing.
public final class LocalSimulatedRoutingService: RoutingServiceProtocol {
    public static let shared = LocalSimulatedRoutingService()

    public init() {}

    public func calculateRoutes(from origin: WZCoordinate,
                                to destination: WZCoordinate,
                                completion: @escaping (Result<[WZRoute], Error>) -> Void) {
        // Generate primary route and alternative route between origin and destination
        let directDist = haversineDistance(from: origin, to: destination)
        guard directDist > 10.0 else {
            completion(.failure(RoutingError.invalidCoordinates))
            return
        }

        // Interpolate waypoints
        let stepsCount = 10
        var polyline1: [WZCoordinate] = []
        var polyline2: [WZCoordinate] = []

        for i in 0...stepsCount {
            let t = Double(i) / Double(stepsCount)
            let lat1 = origin.latitude + (destination.latitude - origin.latitude) * t
            let lon1 = origin.longitude + (destination.longitude - origin.longitude) * t
            polyline1.append(WZCoordinate(latitude: lat1, longitude: lon1))

            // Alternative route bends slightly east/west
            let lat2 = lat1 + sin(t * .pi) * 0.005
            let lon2 = lon1 + sin(t * .pi) * 0.008
            polyline2.append(WZCoordinate(latitude: lat2, longitude: lon2))
        }

        let route1Distance = directDist * 1.15
        let route1Duration = route1Distance / 12.0 // ~43 km/h average city speed

        let steps1: [WZRouteStep] = [
            WZRouteStep(maneuver: .depart, instruction: "Head northeast on Main St", streetName: "Main St", distanceMeters: route1Distance * 0.25, durationSeconds: route1Duration * 0.25, coordinate: polyline1[2]),
            WZRouteStep(maneuver: .turnRight, instruction: "Turn right onto Grand Ave", streetName: "Grand Ave", distanceMeters: route1Distance * 0.35, durationSeconds: route1Duration * 0.35, coordinate: polyline1[5]),
            WZRouteStep(maneuver: .turnLeft, instruction: "Turn left onto Market Blvd", streetName: "Market Blvd", distanceMeters: route1Distance * 0.30, durationSeconds: route1Duration * 0.30, coordinate: polyline1[8]),
            WZRouteStep(maneuver: .arrive, instruction: "Arrive at destination on the right", streetName: "Destination Way", distanceMeters: route1Distance * 0.10, durationSeconds: route1Duration * 0.10, coordinate: polyline1.last!)
        ]

        let primaryRoute = WZRoute(
            routeId: "waze_route_primary",
            summary: "Via Grand Ave (Fastest)",
            totalDistanceMeters: route1Distance,
            totalDurationSeconds: route1Duration,
            polylineCoordinates: polyline1,
            steps: steps1,
            isAlternative: false,
            viaDescription: "Main St & Grand Ave"
        )

        let route2Distance = directDist * 1.30
        let route2Duration = route2Distance / 11.0

        let steps2: [WZRouteStep] = [
            WZRouteStep(maneuver: .depart, instruction: "Head north on Pine St", streetName: "Pine St", distanceMeters: route2Distance * 0.4, durationSeconds: route2Duration * 0.4, coordinate: polyline2[3]),
            WZRouteStep(maneuver: .turnRight, instruction: "Turn right onto Express Pkwy", streetName: "Express Pkwy", distanceMeters: route2Distance * 0.5, durationSeconds: route2Duration * 0.5, coordinate: polyline2[7]),
            WZRouteStep(maneuver: .arrive, instruction: "Arrive at destination", streetName: "Destination Way", distanceMeters: route2Distance * 0.1, durationSeconds: route2Duration * 0.1, coordinate: polyline2.last!)
        ]

        let altRoute = WZRoute(
            routeId: "waze_route_alt",
            summary: "Via Express Pkwy (+4 min)",
            totalDistanceMeters: route2Distance,
            totalDurationSeconds: route2Duration,
            polylineCoordinates: polyline2,
            steps: steps2,
            isAlternative: true,
            viaDescription: "Pine St & Express Pkwy"
        )

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            completion(.success([primaryRoute, altRoute]))
        }
    }
}
