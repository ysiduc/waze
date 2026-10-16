#include "../NativeEngine/Routing/RoutingEngine.hpp"
#include <cassert>
#include <iostream>

using namespace Waze::Routing;
using namespace Waze::Geometry;

void testRoutingLifecycle() {
    RoutingEngine engine;
    assert(engine.currentState() == NavigationState::Idle);

    Route route;
    route.routeId = "test_route";
    route.totalDistanceMeters = 1000.0;
    route.totalDurationSeconds = 120.0;

    std::vector<Coordinate> coords = {
        Coordinate(37.7749, -122.4194),
        Coordinate(37.7790, -122.4194),
        Coordinate(37.7850, -122.4194)
    };
    route.geometry = Polyline(coords);

    ManeuverStep step1;
    step1.maneuver = Maneuver::Depart;
    step1.instruction = "Head North on 9th St";
    step1.coordinate = coords[1];
    step1.distanceMeters = 500.0;
    route.steps.push_back(step1);

    ManeuverStep step2;
    step2.maneuver = Maneuver::Arrive;
    step2.instruction = "Arrive at destination";
    step2.coordinate = coords[2];
    step2.distanceMeters = 500.0;
    route.steps.push_back(step2);

    engine.setRoute(route);
    assert(engine.currentState() == NavigationState::Navigating);

    // Update location along route
    NavigationProgress p1 = engine.updateLocation(Coordinate(37.7750, -122.4194), 10.0);
    assert(p1.state == NavigationState::Navigating);
    assert(!p1.isOffRoute);
    assert(p1.distanceToDestinationMeters > 0.0);

    // Update location off-route (> 35m off track)
    NavigationProgress pOff = engine.updateLocation(Coordinate(37.7750, -122.4100), 10.0);
    assert(pOff.isOffRoute);
    assert(pOff.state == NavigationState::Rerouting);

    // Update location at destination (within 25m)
    NavigationProgress pArrived = engine.updateLocation(Coordinate(37.7850, -122.4194), 5.0);
    assert(pArrived.state == NavigationState::Arrived);
    assert(pArrived.nextManeuver == Maneuver::Arrive);

    // Stop navigation
    engine.stopNavigation();
    assert(engine.currentState() == NavigationState::Idle);

    std::cout << "[PASS] Routing Engine Lifecycle, Off-Route Detection & Arrival" << std::endl;
}

void testDynamicManeuverGeneration() {
    // L-shaped route: Go North, turn East (Right turn 90 deg)
    std::vector<Coordinate> coords = {
        Coordinate(37.7700, -122.4194),
        Coordinate(37.7750, -122.4194), // heading 0 (North)
        Coordinate(37.7750, -122.4140)  // heading 90 (East) -> Turn Right!
    };
    Polyline poly(coords);

    auto steps = RoutingEngine::generateStepsFromPolyline(poly);

    assert(steps.size() >= 3);
    assert(steps[0].maneuver == Maneuver::Depart);
    assert(steps[1].maneuver == Maneuver::TurnRight);
    assert(steps.back().maneuver == Maneuver::Arrive);

    std::cout << "[PASS] Dynamic Turn Maneuver Generation (Depart -> TurnRight -> Arrive)" << std::endl;
}

int main() {
    std::cout << "--- Running Routing Engine C++ Unit Tests ---" << std::endl;
    testRoutingLifecycle();
    testDynamicManeuverGeneration();
    std::cout << "All Routing Engine unit tests PASSED successfully." << std::endl;
    return 0;
}

