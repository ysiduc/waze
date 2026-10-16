import Foundation
import CoreLocation

/// Destination search item model reconstructed from Waze Search Implementation bundle.
public struct WZDestination: Identifiable, Codable, Equatable {
    public let id: String
    public let title: String
    public let subtitle: String
    public let coordinate: WZCoordinate
    public let category: String
    public let isFavorite: Bool

    public init(id: String = UUID().uuidString,
                title: String,
                subtitle: String,
                coordinate: WZCoordinate,
                category: String = "general",
                isFavorite: Bool = false) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.coordinate = coordinate
        self.category = category
        self.isFavorite = isFavorite
    }
}
