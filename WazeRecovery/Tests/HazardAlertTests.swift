import Foundation

#if canImport(XCTest)
import XCTest

final class HazardAlertTests: XCTestCase {
    func testHazardAlertCreation() {
        let alert = WZHazardAlert(
            type: .police,
            coordinate: WZCoordinate(latitude: 37.7795, longitude: -122.4135),
            title: "Police report",
            subtitle: "Speed trap"
        )

        XCTAssertEqual(alert.type, .police)
        XCTAssertEqual(alert.title, "Police report")
        XCTAssertTrue(alert.isConfirmed)
    }

    func testSpatialAlertQuery() {
        let service = AlertReportingService()
        // Query near downtown SF (37.7749, -122.4194) within 5km
        let center = WZCoordinate(latitude: 37.7749, longitude: -122.4194)
        let alerts = service.alerts(near: center, radiusMeters: 5000.0)

        XCTAssertFalse(alerts.isEmpty)
        XCTAssertTrue(alerts.contains(where: { $0.type == .police }))
    }

    func testUserHazardReporting() {
        let service = AlertReportingService()
        let customCoord = WZCoordinate(latitude: 37.7800, longitude: -122.4200)

        let reported = service.reportHazard(
            type: .accident,
            coordinate: customCoord,
            title: "Minor fender bender",
            subtitle: "Left lane"
        )

        XCTAssertEqual(reported.type, .accident)
        XCTAssertFalse(reported.isConfirmed)

        let nearby = service.alerts(near: customCoord, radiusMeters: 100.0)
        XCTAssertTrue(nearby.contains(where: { $0.id == reported.id }))
    }
}
#endif
