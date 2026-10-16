import XCTest
@testable import NavApp

final class NavigationStateTests: XCTestCase {
    func testInitialStatusIsIdle() {
        let manager = NavigationSessionManager()
        XCTAssertEqual(manager.status, .idle)
        XCTAssertNil(manager.selectedRoute)
        XCTAssertTrue(manager.availableRoutes.isEmpty)
        XCTAssertNil(manager.currentStep)
        XCTAssertEqual(manager.currentStepIndex, 0)
    }
    
    func testStartAndStopNavigation() {
        let manager = NavigationSessionManager()
        let step = GuidanceStep(stepIndex: 0,
                                instruction: "Turn right onto Market St",
                                distanceMeters: 250,
                                maneuver: .turnRight,
                                coordinate: .init(latitude: 37.7749, longitude: -122.4194))
        let route = RouteModel(name: "Test Route",
                               totalDistanceMeters: 5000,
                               totalExpectedTimeSeconds: 600,
                               steps: [step],
                               polylineCoordinates: [step.coordinate],
                               isPrimary: true)
        
        manager.availableRoutes = [route]
        manager.selectedRoute = route
        manager.startNavigation()
        
        XCTAssertEqual(manager.status, .navigating)
        XCTAssertEqual(manager.currentStepIndex, 0)
        XCTAssertEqual(manager.currentStep?.instruction, "Turn right onto Market St")
        XCTAssertEqual(manager.metrics.remainingDistanceMeters, 5000)
        
        manager.stopNavigation()
        XCTAssertEqual(manager.status, .idle)
        XCTAssertNil(manager.selectedRoute)
        XCTAssertNil(manager.currentStep)
    }
}
