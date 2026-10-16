#include "RoutingEngine.hpp"
#include <algorithm>

namespace Waze {
namespace Routing {

RoutingEngine::RoutingEngine() {
    progress_.state = NavigationState::Idle;
}

void RoutingEngine::setRoute(const Route& route) {
    currentRoute_ = route;
    progress_ = NavigationProgress();
    if (!currentRoute_.geometry.empty()) {
        progress_.state = NavigationState::Navigating;
        progress_.distanceToDestinationMeters = currentRoute_.totalDistanceMeters;
        progress_.timeToDestinationSeconds = currentRoute_.totalDurationSeconds;
        if (!currentRoute_.steps.empty()) {
            progress_.nextManeuver = currentRoute_.steps[0].maneuver;
            progress_.nextInstruction = currentRoute_.steps[0].instruction;
            progress_.currentStreet = currentRoute_.steps[0].streetName;
            progress_.distanceToNextTurnMeters = currentRoute_.steps[0].distanceMeters;
        }
    } else {
        progress_.state = NavigationState::Idle;
    }
}

void RoutingEngine::stopNavigation() {
    currentRoute_ = Route();
    progress_ = NavigationProgress();
    progress_.state = NavigationState::Idle;
}

NavigationProgress RoutingEngine::updateLocation(const Geometry::Coordinate& location, double speedMetersPerSecond) {
    if (progress_.state == NavigationState::Idle || currentRoute_.geometry.empty()) {
        return progress_;
    }

    // 1. Check arrival at final coordinate
    const auto& coords = currentRoute_.geometry.coordinates();
    const auto& destination = coords.back();
    double distToDest = Geometry::haversineDistanceMeters(location, destination);

    if (distToDest <= arrivalThresholdMeters_) {
        progress_.state = NavigationState::Arrived;
        progress_.distanceToDestinationMeters = 0.0;
        progress_.distanceToNextTurnMeters = 0.0;
        progress_.timeToDestinationSeconds = 0.0;
        progress_.nextInstruction = "You have arrived at your destination";
        progress_.nextManeuver = Maneuver::Arrive;
        progress_.isOffRoute = false;
        progress_.snappedLocation = destination;
        return progress_;
    }

    // 2. Map-match to polyline
    Geometry::Coordinate snapped;
    double crossTrackDist = 0.0;
    size_t segIdx = 0;
    currentRoute_.geometry.findClosestPoint(location, snapped, crossTrackDist, segIdx);

    progress_.snappedLocation = snapped;

    // 3. Check off-route condition
    if (crossTrackDist > offRouteThresholdMeters_) {
        progress_.isOffRoute = true;
        progress_.state = NavigationState::Rerouting;
        progress_.nextInstruction = "Recalculating route...";
        return progress_;
    } else {
        progress_.isOffRoute = false;
        progress_.state = NavigationState::Navigating;
    }

    // 4. Compute remaining distance to destination
    double remainingDistance = Geometry::haversineDistanceMeters(snapped, coords[segIdx + 1]);
    for (size_t i = segIdx + 1; i + 1 < coords.size(); ++i) {
        remainingDistance += Geometry::haversineDistanceMeters(coords[i], coords[i + 1]);
    }
    progress_.distanceToDestinationMeters = remainingDistance;

    // 5. Compute estimated time remaining
    double avgSpeed = (speedMetersPerSecond > 5.0) ? speedMetersPerSecond : 13.88; // Default 50 km/h (13.88 m/s)
    progress_.timeToDestinationSeconds = remainingDistance / avgSpeed;

    // 6. Update maneuver step progress
    if (!currentRoute_.steps.empty()) {
        // Find which step corresponds to our current location
        size_t currentStep = progress_.currentStepIndex;
        while (currentStep + 1 < currentRoute_.steps.size()) {
            double distToStepEnd = Geometry::haversineDistanceMeters(snapped, currentRoute_.steps[currentStep].coordinate);
            if (distToStepEnd < 20.0) {
                // Advanced to next step
                currentStep++;
            } else {
                break;
            }
        }
        progress_.currentStepIndex = currentStep;

        const auto& step = currentRoute_.steps[currentStep];
        progress_.nextManeuver = step.maneuver;
        progress_.nextInstruction = step.instruction;
        progress_.currentStreet = step.streetName;
        progress_.distanceToNextTurnMeters = Geometry::haversineDistanceMeters(snapped, step.coordinate);
    }

    return progress_;
}

} // namespace Routing
} // namespace Waze
