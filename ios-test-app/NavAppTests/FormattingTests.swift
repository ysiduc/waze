import XCTest
@testable import NavApp

final class FormattingTests: XCTestCase {
    func testDistanceFormattingMeters() {
        XCTAssertEqual(NavigationFormatters.formatDistance(350), "350 m")
        XCTAssertEqual(NavigationFormatters.formatDistance(999), "999 m")
    }
    
    func testDistanceFormattingKilometers() {
        XCTAssertEqual(NavigationFormatters.formatDistance(1000), "1.0 km")
        XCTAssertEqual(NavigationFormatters.formatDistance(15400), "15.4 km")
    }
    
    func testDurationFormattingMinutes() {
        XCTAssertEqual(NavigationFormatters.formatDuration(180), "3 min")
        XCTAssertEqual(NavigationFormatters.formatDuration(1200), "20 min")
    }
    
    func testDurationFormattingHoursAndMinutes() {
        XCTAssertEqual(NavigationFormatters.formatDuration(3660), "1 hr 1 min")
        XCTAssertEqual(NavigationFormatters.formatDuration(7200), "2 hr 0 min")
    }
    
    func testSpeedFormatting() {
        XCTAssertEqual(NavigationFormatters.formatSpeed(0), "0 km/h")
        XCTAssertEqual(NavigationFormatters.formatSpeed(65.4), "65 km/h")
    }
}
