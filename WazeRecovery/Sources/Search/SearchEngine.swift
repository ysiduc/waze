import Foundation
import CoreLocation

/// Categories matching Waze quick-search category buttons (Gas, Food, Parking, Coffee).
public enum WZSearchCategory: String, CaseIterable {
    case all = "all"
    case gas = "gas"
    case food = "food"
    case coffee = "coffee"
    case parking = "parking"
    case favorites = "favorites"

    public var displayName: String {
        switch self {
        case .all: return "All"
        case .gas: return "Gas Stations"
        case .food: return "Food & Dining"
        case .coffee: return "Coffee"
        case .parking: return "Parking"
        case .favorites: return "Favorites"
        }
    }
}

/// Reconstructed search engine and destination index with spatial distance sorting.
/// Reconstructed from WazeSearchCoordinator & SearchResultsBridge in Waze ARM64 executable.
public final class SearchEngine {
    public static let shared = SearchEngine()

    private var recentSearches: [WZDestination] = []
    private var poiDatabase: [WZDestination] = []

    public init() {
        populateDatabase()
    }

    private func populateDatabase() {
        poiDatabase = [
            // Favorites & Home/Work
            WZDestination(title: "Home", subtitle: "Market St, San Francisco, CA", coordinate: WZCoordinate(latitude: 37.7749, longitude: -122.4194), category: "favorites", isFavorite: true),
            WZDestination(title: "Work", subtitle: "Financial District, San Francisco, CA", coordinate: WZCoordinate(latitude: 37.7891, longitude: -122.4014), category: "favorites", isFavorite: true),

            // Gas Stations
            WZDestination(title: "Chevron", subtitle: "1298 Howard St, San Francisco", coordinate: WZCoordinate(latitude: 37.7758, longitude: -122.4140), category: "gas"),
            WZDestination(title: "Shell", subtitle: "390 8th St, San Francisco", coordinate: WZCoordinate(latitude: 37.7725, longitude: -122.4095), category: "gas"),
            WZDestination(title: "Mobil", subtitle: "1201 Fell St, San Francisco", coordinate: WZCoordinate(latitude: 37.7740, longitude: -122.4385), category: "gas"),

            // Food & Dining
            WZDestination(title: "In-N-Out Burger", subtitle: "333 Jefferson St, San Francisco", coordinate: WZCoordinate(latitude: 37.8078, longitude: -122.4180), category: "food"),
            WZDestination(title: "Tartine Bakery", subtitle: "600 Guerrero St, San Francisco", coordinate: WZCoordinate(latitude: 37.7614, longitude: -122.4241), category: "food"),
            WZDestination(title: "The Slanted Door", subtitle: "1 Ferry Bldg, San Francisco", coordinate: WZCoordinate(latitude: 37.7958, longitude: -122.3938), category: "food"),

            // Coffee
            WZDestination(title: "Blue Bottle Coffee", subtitle: "66 Mint St, San Francisco", coordinate: WZCoordinate(latitude: 37.7825, longitude: -122.4076), category: "coffee"),
            WZDestination(title: "Philz Coffee", subtitle: "201 Berry St, San Francisco", coordinate: WZCoordinate(latitude: 37.7766, longitude: -122.3942), category: "coffee"),
            WZDestination(title: "Sightglass Coffee", subtitle: "270 7th St, San Francisco", coordinate: WZCoordinate(latitude: 37.7769, longitude: -122.4085), category: "coffee"),

            // Parking
            WZDestination(title: "Fifth & Mission Garage", subtitle: "833 Mission St, San Francisco", coordinate: WZCoordinate(latitude: 37.7827, longitude: -122.4055), category: "parking"),
            WZDestination(title: "Sutter-Stockton Garage", subtitle: "444 Stockton St, San Francisco", coordinate: WZCoordinate(latitude: 37.7901, longitude: -122.4068), category: "parking"),

            // Landmarks & Airports
            WZDestination(title: "San Francisco International Airport (SFO)", subtitle: "San Francisco, CA", coordinate: WZCoordinate(latitude: 37.6213, longitude: -122.3790), category: "all"),
            WZDestination(title: "Golden Gate Bridge", subtitle: "Golden Gate Bridge, San Francisco, CA", coordinate: WZCoordinate(latitude: 37.8199, longitude: -122.4783), category: "all"),
            WZDestination(title: "Fisherman's Wharf", subtitle: "Jefferson St, San Francisco, CA", coordinate: WZCoordinate(latitude: 37.8080, longitude: -122.4177), category: "all"),
            WZDestination(title: "Twin Peaks Viewpoint", subtitle: "501 Twin Peaks Blvd, San Francisco, CA", coordinate: WZCoordinate(latitude: 37.7544, longitude: -122.4477), category: "all")
        ]
    }

    /// Searches POIs matching query text and optional category filter, sorted by distance from userLocation.
    public func search(query: String,
                       category: WZSearchCategory = .all,
                       near userLocation: WZCoordinate? = nil) -> [WZDestination] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        var results = poiDatabase.filter { dest in
            let matchesCategory: Bool
            if category == .all {
                matchesCategory = true
            } else if category == .favorites {
                matchesCategory = dest.isFavorite
            } else {
                matchesCategory = dest.category == category.rawValue
            }

            if !matchesCategory {
                return false
            }

            if trimmed.isEmpty {
                return true
            }

            return dest.title.lowercased().contains(trimmed) || dest.subtitle.lowercased().contains(trimmed)
        }

        // Sort by spatial distance if user coordinate is provided
        if let loc = userLocation {
            let locCL = CLLocationCoordinate2D(latitude: loc.latitude, longitude: loc.longitude)
            results.sort { d1, d2 in
                let c1 = CLLocationCoordinate2D(latitude: d1.coordinate.latitude, longitude: d1.coordinate.longitude)
                let c2 = CLLocationCoordinate2D(latitude: d2.coordinate.latitude, longitude: d2.coordinate.longitude)
                let dist1 = WZNativeEngineBridge.distance(from: locCL, to: c1)
                let dist2 = WZNativeEngineBridge.distance(from: locCL, to: c2)
                return dist1 < dist2
            }
        }

        return results
    }

    public func addRecentSearch(_ destination: WZDestination) {
        recentSearches.removeAll { $0.id == destination.id }
        recentSearches.insert(destination, at: 0)
        if recentSearches.count > 10 {
            recentSearches.removeLast()
        }
    }

    public var recents: [WZDestination] {
        recentSearches
    }
}

