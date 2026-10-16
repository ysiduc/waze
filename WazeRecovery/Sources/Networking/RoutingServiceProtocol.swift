import Foundation

/// Clean interface isolating Waze routing services.
public protocol RoutingServiceProtocol {
    func calculateRoutes(from origin: WZCoordinate,
                         to destination: WZCoordinate,
                         completion: @escaping (Result<[WZRoute], Error>) -> Void)
}

public enum RoutingError: Error {
    case noRouteFound
    case networkUnavailable
    case invalidCoordinates
}
