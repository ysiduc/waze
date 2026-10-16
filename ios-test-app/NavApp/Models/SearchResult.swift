import Foundation
import CoreLocation
import MapKit

public struct SearchResult: Identifiable, Equatable {
    public let id: UUID
    public let title: String
    public let subtitle: String
    public let coordinate: CLLocationCoordinate2D
    
    public init(id: UUID = UUID(), title: String, subtitle: String, coordinate: CLLocationCoordinate2D) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.coordinate = coordinate
    }
    
    public static func fromMKMapItem(_ item: MKMapItem) -> SearchResult {
        let title = item.name ?? "Unknown Location"
        let subtitle = item.placemark.title ?? ""
        return SearchResult(title: title, subtitle: subtitle, coordinate: item.placemark.coordinate)
    }
    
    public static func == (lhs: SearchResult, rhs: SearchResult) -> Bool {
        return lhs.id == rhs.id &&
               lhs.title == rhs.title &&
               lhs.subtitle == rhs.subtitle &&
               lhs.coordinate.latitude == rhs.coordinate.latitude &&
               lhs.coordinate.longitude == rhs.coordinate.longitude
    }
}
