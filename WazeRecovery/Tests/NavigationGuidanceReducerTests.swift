import Foundation

#if canImport(XCTest)
import XCTest

final class NavigationGuidanceReducerTests: XCTestCase, NavigationGuidanceReducerBridgeProtocol {
    private var lastState: WZNavigationState?

    func guidanceReducer(_ bridge: NavigationGuidanceReducerBridge, didUpdateState state: WZNavigationState) {
        self.lastState = state
    }

    func testSetRouteInitializesGuidance() {
        let reducer = NavigationGuidanceReducerBridge()
        reducer.delegate = self

        let step1 = WZRouteStep(maneuver: .depart, instruction: "Head East on Market St", streetName: "Market St", distanceMeters: 400.0, durationSeconds: 60.0, coordinate: WZCoordinate(latitude: 37.77, longitude: -122.41))
        let step2 = WZRouteStep(maneuver: .arrive, instruction: "Arrive at destination", streetName: "Destination", distanceMeters: 600.0, durationSeconds: 90.0, coordinate: WZCoordinate(latitude: 37.78, longitude: -122.40))

        let route = WZRoute(routeId: "test_01", summary: "Market St", totalDistanceMeters: 1000.0, totalDurationSeconds: 150.0, polylineCoordinates: [step1.coordinate, step2.coordinate], steps: [step1, step2])

        reducer.reduce(event: .setRoute(route: route))

        XCTAssertEqual(reducer.currentState.status, .navigating)
        XCTAssertEqual(reducer.currentState.currentInstruction, "Head East on Market St")
        XCTAssertEqual(reducer.currentState.currentManeuver, .depart)
        XCTAssertEqual(reducer.currentState.distanceToTurnMeters, 400.0)
    }

    func testTurnApproachingThreshold() {
        let reducer = NavigationGuidanceReducerBridge()
        reducer.delegate = self

        let step1 = WZRouteStep(maneuver: .turnRight, instruction: "Turn right onto 4th St", streetName: "4th St", distanceMeters: 120.0, durationSeconds: 20.0, coordinate: WZCoordinate(latitude: 37.77, longitude: -122.41))
        let route = WZRoute(routeId: "test_02", summary: "4th St", totalDistanceMeters: 500.0, totalDurationSeconds: 80.0, polylineCoordinates: [step1.coordinate], steps: [step1])

        reducer.reduce(event: .setRoute(route: route))
        XCTAssertTrue(reducer.currentState.isApproachingTurn) // < 150m
    }

    func testDestinationArrived() {
        let reducer = NavigationGuidanceReducerBridge()
        reducer.delegate = self

        reducer.reduce(event: .destinationArrived)
        XCTAssertEqual(reducer.currentState.status, .arrived)
        XCTAssertEqual(reducer.currentState.currentManeuver, .arrive)
        XCTAssertEqual(reducer.currentState.distanceToTurnMeters, 0.0)
    }
}
#endif
