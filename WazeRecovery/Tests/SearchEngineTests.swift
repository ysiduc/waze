import Foundation
#if canImport(XCTest)
import XCTest

final class SearchEngineTests: XCTestCase {
    func testSearchByCategoryAndText() {
        let engine = SearchEngine()
        
        let gasResults = engine.search(query: "", category: .gas)
        XCTAssertFalse(gasResults.isEmpty)
        XCTAssertTrue(gasResults.allSatisfy { $0.category == "gas" })
        
        let queryResults = engine.search(query: "Chevron", category: .all)
        XCTAssertEqual(queryResults.first?.title, "Chevron")
    }

    func testSpatialSortingNearestFirst() {
        let engine = SearchEngine()
        // Coordinates near Mission & 8th (close to Shell at 390 8th St, 37.7725, -122.4095)
        let userLocation = WZCoordinate(latitude: 37.7726, longitude: -122.4094)
        
        let gasStations = engine.search(query: "", category: .gas, near: userLocation)
        XCTAssertFalse(gasStations.isEmpty)
        // First station should be Shell (closest)
        XCTAssertEqual(gasStations.first?.title, "Shell")
    }

    func testRecentSearchesHistory() {
        let engine = SearchEngine()
        let destination = WZDestination(title: "Test Dest", subtitle: "123 Test St", coordinate: WZCoordinate(latitude: 37.7, longitude: -122.4))
        
        engine.addRecentSearch(destination)
        XCTAssertEqual(engine.recents.first?.id, destination.id)
    }
}
#endif
