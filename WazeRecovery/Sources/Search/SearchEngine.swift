import Foundation

/// Reconstructed search engine and destination index.
public final class SearchEngine {
    public static let shared = SearchEngine()

    private var recentSearches: [WZDestination] = []
    private var defaultDestinations: [WZDestination] = []

    public init() {
        populateDefaultDestinations()
    }

    private func populateDefaultDestinations() {
        defaultDestinations = [
            WZDestination(title: "Home", subtitle: "Set home address", coordinate: WZCoordinate(latitude: 37.7749, longitude: -122.4194), category: "home", isFavorite: true),
            WZDestination(title: "Work", subtitle: "Set work address", coordinate: WZCoordinate(latitude: 37.7891, longitude: -122.4014), category: "work", isFavorite: true),
            WZDestination(title: "San Francisco International Airport (SFO)", subtitle: "San Francisco, CA", coordinate: WZCoordinate(latitude: 37.6213, longitude: -122.3790), category: "airport"),
            WZDestination(title: "Golden Gate Bridge", subtitle: "Golden Gate Bridge, San Francisco, CA", coordinate: WZCoordinate(latitude: 37.8199, longitude: -122.4783), category: "landmark"),
            WZDestination(title: "Fisherman's Wharf", subtitle: "Jefferson St, San Francisco, CA", coordinate: WZCoordinate(latitude: 37.8080, longitude: -122.4177), category: "attraction"),
            WZDestination(title: "Twin Peaks", subtitle: "501 Twin Peaks Blvd, San Francisco, CA", coordinate: WZCoordinate(latitude: 37.7544, longitude: -122.4477), category: "viewpoint")
        ]
    }

    public func search(query: String) -> [WZDestination] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if trimmed.isEmpty {
            return defaultDestinations
        }

        return defaultDestinations.filter { dest in
            dest.title.lowercased().contains(trimmed) || dest.subtitle.lowercased().contains(trimmed)
        }
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
