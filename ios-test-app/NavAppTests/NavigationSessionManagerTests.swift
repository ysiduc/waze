import XCTest
import CoreLocation
@testable import NavApp

final class NavigationSessionManagerTests: XCTestCase {
    func testRouteSelectionUpdatesMetrics() {
        let manager = NavigationSessionManager()
        let step = GuidanceStep(stepIndex: 0,
                                instruction: "Continue on highway",
                                distanceMeters: 10000,
                                maneuver: .straight,
                                coordinate: .init(latitude: 37.77, longitude: -122.41))
        let route = RouteModel(name: "Highway Route",
                               totalDistanceMeters: 10000,
                               totalExpectedTimeSeconds: 600,
                               steps: [step],
                               polylineCoordinates: [step.coordinate],
                               isPrimary: true)
        
        manager.availableRoutes = [route]
        manager.selectRoute(route)
        
        XCTAssertEqual(manager.selectedRoute?.name, "Highway Route")
        XCTAssertEqual(manager.metrics.remainingDistanceMeters, 10000)
        XCTAssertEqual(manager.metrics.remainingTimeSeconds, 600)
    }
    
    func testLocationUpdateAdvancesStep() {
        let manager = NavigationSessionManager()
        let step0Coord = CLLocationCoordinate2D(latitude: 37.77490, longitude: -122.41940)
        let step1Coord = CLLocationCoordinate2D(latitude: 37.77590, longitude: -122.41940)
        
        let step0 = GuidanceStep(stepIndex: 0, instruction: "Step 0", distanceMeters: 200, maneuver: .straight, coordinate: step0Coord)
        let step1 = GuidanceStep(stepIndex: 1, instruction: "Step 1", distanceMeters: 300, maneuver: .turnRight, coordinate: step1Coord)
        
        let route = RouteModel(name: "Multi-Step Route",
                               totalDistanceMeters: 500,
                               totalExpectedTimeSeconds: 120,
                               steps: [step0, step1],
                               polylineCoordinates: [step0Coord, step1Coord],
                               isPrimary: true)
        
        manager.availableRoutes = [route]
        manager.selectedRoute = route
        manager.startNavigation()
        
        XCTAssertEqual(manager.currentStepIndex, 0)
        
        // Simulate user arriving within 10 meters of step0 coordinate
        let closeLoc = LocationModel(coordinate: .init(latitude: 37.77491, longitude: -122.41941),
                                     horizontalAccuracy: 5,
                                     speedMps: 10)
        manager.processLocationUpdate(closeLoc)
        
        // Should advance to step 1
        XCTAssertEqual(manager.currentStepIndex, 1)
        XCTAssertEqual(manager.currentStep?.instruction, "Step 1")
    }
    
    func testDemoModeToggle() {
        let manager = NavigationSessionManager()
        XCTAssertFalse(manager.isDemoMode)
        manager.toggleDemoMode()
        XCTAssertTrue(manager.isDemoMode)
        manager.toggleDemoMode()
        XCTAssertFalse(manager.isDemoMode)
    }
}
