import XCTest
import CoreLocation
@testable import NavApp

final class RouteModelTests: XCTestCase {
    func testManeuverTypeDetection() {
        XCTAssertEqual(ManeuverType.fromInstruction("Turn left on Main St"), .turnLeft)
        XCTAssertEqual(ManeuverType.fromInstruction("Turn right onto 5th Ave"), .turnRight)
        XCTAssertEqual(ManeuverType.fromInstruction("Slight left onto expressway"), .slightLeft)
        XCTAssertEqual(ManeuverType.fromInstruction("Make a U-turn"), .uTurn)
        XCTAssertEqual(ManeuverType.fromInstruction("Take the roundabout"), .enterRoundabout)
        XCTAssertEqual(ManeuverType.fromInstruction("You have arrived at your destination"), .arrive)
        XCTAssertEqual(ManeuverType.fromInstruction("Continue straight for 2 miles"), .straight)
    }
    
    func testRouteModelInitialization() {
        let step1 = GuidanceStep(stepIndex: 0,
                                 instruction: "Head north",
                                 distanceMeters: 500,
                                 maneuver: .straight,
                                 coordinate: .init(latitude: 37.77, longitude: -122.41))
        let step2 = GuidanceStep(stepIndex: 1,
                                 instruction: "Arrive at destination",
                                 distanceMeters: 0,
                                 maneuver: .arrive,
                                 coordinate: .init(latitude: 37.78, longitude: -122.40))
        
        let route = RouteModel(name: "Primary Route",
                               totalDistanceMeters: 1200,
                               totalExpectedTimeSeconds: 300,
                               steps: [step1, step2],
                               polylineCoordinates: [step1.coordinate, step2.coordinate],
                               isPrimary: true)
        
        XCTAssertEqual(route.name, "Primary Route")
        XCTAssertEqual(route.steps.count, 2)
        XCTAssertTrue(route.isPrimary)
        XCTAssertEqual(route.steps[0].instruction, "Head north")
        XCTAssertEqual(route.steps[1].maneuver, .arrive)
    }
}
