import Foundation
import MapKit

public class RoutingService {
    public init() {}
    
    public func calculateRoutes(from source: CLLocationCoordinate2D,
                                to destination: CLLocationCoordinate2D,
                                completion: @escaping (Result<[RouteModel], Error>) -> Void) {
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: source))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: destination))
        request.transportType = .automobile
        request.requestsAlternateRoutes = true
        
        let directions = MKDirections(request: request)
        directions.calculate { response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let response = response, !response.routes.isEmpty else {
                let noRouteErr = NSError(domain: "RoutingService", code: 404,
                                         userInfo: [NSLocalizedDescriptionKey: "No route found to destination."])
                completion(.failure(noRouteErr))
                return
            }
            
            var resultRoutes: [RouteModel] = []
            for (index, mkRoute) in response.routes.enumerated() {
                let name = index == 0 ? (mkRoute.name.isEmpty ? "Fastest Route" : mkRoute.name) : "Alternative \(index)"
                let routeModel = RouteModel.fromMKRoute(mkRoute, name: name, isPrimary: (index == 0))
                resultRoutes.append(routeModel)
            }
            completion(.success(resultRoutes))
        }
    }
}
