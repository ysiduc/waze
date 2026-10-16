import XCTest
import CoreLocation
@testable import NavApp

final class LocationModelTests: XCTestCase {
    func testSpeedConversion() {
        let loc = LocationModel(coordinate: .init(latitude: 37.77, longitude: -122.41),
                                altitude: 10,
                                horizontalAccuracy: 5,
                                speedMps: 20.0, // 20 m/s = 72 km/h
                                course: 90)
        XCTAssertEqual(loc.speedKph, 72.0, accuracy: 0.1)
        XCTAssertEqual(loc.speedMph, 44.73, accuracy: 0.1)
        XCTAssertTrue(loc.isValid)
    }
    
    func testInvalidAccuracy() {
        let badLoc = LocationModel(coordinate: .init(latitude: 0, longitude: 0),
                                  horizontalAccuracy: -1)
        XCTAssertFalse(badLoc.isValid)
        
        let inaccurateLoc = LocationModel(coordinate: .init(latitude: 0, longitude: 0),
                                         horizontalAccuracy: 150)
        XCTAssertFalse(inaccurateLoc.isValid)
    }
}
