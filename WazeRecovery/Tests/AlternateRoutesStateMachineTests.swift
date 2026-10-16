import Foundation

#if canImport(XCTest)
import XCTest

final class AlternateRoutesStateMachineTests: XCTestCase, AlternateRoutesStateMachineBridgeProtocol {
    private var lastCurrentRoute: WZRoute?
    private var lastSuggestedRoute: WZRoute?
    private var lastTimeSaved: Double = 0.0

    func stateMachine(_ bridge: AlternateRoutesStateMachineBridge, didUpdateCurrentRoute route: WZRoute) {
        self.lastCurrentRoute = route
    }

    func stateMachine(_ bridge: AlternateRoutesStateMachineBridge, didSuggestReroute alternativeRoute: WZRoute, timeSavedSeconds: Double) {
        self.lastSuggestedRoute = alternativeRoute
        self.lastTimeSaved = timeSavedSeconds
    }

    func stateMachine(_ bridge: AlternateRoutesStateMachineBridge, didUpdateScheduleInterval seconds: TimeInterval) {}

    func testParseRoutingUpdateTriggersTransitions() {
        let bridge = AlternateRoutesStateMachineBridge()
        bridge.delegate = self

        let primary = WZRoute(routeId: "primary", summary: "Main St", totalDistanceMeters: 5000.0, totalDurationSeconds: 600.0, polylineCoordinates: [], steps: [])
        let alternative = WZRoute(routeId: "alt", summary: "Highway", totalDistanceMeters: 6000.0, totalDurationSeconds: 480.0, polylineCoordinates: [], steps: [], isAlternative: true) // Saves 120s (2 min)

        bridge.parseRoutingUpdateResponse(
            currentRouteUpdate: primary,
            rerouteSuggestion: alternative,
            nextUpdateScheduleSeconds: 30.0
        )

        XCTAssertEqual(lastCurrentRoute?.routeId, "primary")
        XCTAssertEqual(lastSuggestedRoute?.routeId, "alt")
        XCTAssertEqual(lastTimeSaved, 120.0)

        // Select the alternative route
        let selected = bridge.selectAlternativeRoute(at: 0)
        XCTAssertEqual(selected?.routeId, "alt")
        XCTAssertEqual(bridge.currentRoute?.routeId, "alt")
        XCTAssertEqual(bridge.alternativeRoutes.count, 0)
    }
}
#endif
