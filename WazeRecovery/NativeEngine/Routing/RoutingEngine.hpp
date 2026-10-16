#ifndef WAZE_RECOVERY_ROUTING_ENGINE_HPP
#define WAZE_RECOVERY_ROUTING_ENGINE_HPP

#include "../Geometry/Coordinate.hpp"
#include "../Geometry/Polyline.hpp"
#include <vector>
#include <string>
#include <memory>

namespace Waze {
namespace Routing {

enum class Maneuver {
    Depart = 0,
    Continue = 1,
    TurnLeft = 2,
    TurnRight = 3,
    SharpLeft = 4,
    SharpRight = 5,
    SlightLeft = 6,
    SlightRight = 7,
    UTurn = 8,
    Merge = 9,
    Roundabout = 10,
    Arrive = 11
};

struct ManeuverStep {
    Maneuver maneuver;
    std::string instruction;
    std::string streetName;
    double distanceMeters;
    double durationSeconds;
    Geometry::Coordinate coordinate;

    ManeuverStep()
        : maneuver(Maneuver::Continue),
          distanceMeters(0.0),
          durationSeconds(0.0) {}
};

struct Route {
    std::string routeId;
    std::string summary;
    double totalDistanceMeters;
    double totalDurationSeconds;
    Geometry::Polyline geometry;
    std::vector<ManeuverStep> steps;
    bool isAlternative;

    Route()
        : totalDistanceMeters(0.0),
          totalDurationSeconds(0.0),
          isAlternative(false) {}
};

enum class NavigationState {
    Idle = 0,
    Routing = 1,
    Navigating = 2,
    Rerouting = 3,
    Arrived = 4
};

struct NavigationProgress {
    NavigationState state;
    size_t currentStepIndex;
    double distanceToNextTurnMeters;
    double distanceToDestinationMeters;
    double timeToDestinationSeconds;
    bool isOffRoute;
    Geometry::Coordinate snappedLocation;
    Maneuver nextManeuver;
    std::string nextInstruction;
    std::string currentStreet;

    NavigationProgress()
        : state(NavigationState::Idle),
          currentStepIndex(0),
          distanceToNextTurnMeters(0.0),
          distanceToDestinationMeters(0.0),
          timeToDestinationSeconds(0.0),
          isOffRoute(false),
          nextManeuver(Maneuver::Continue) {}
};

class RoutingEngine {
public:
    RoutingEngine();
    ~RoutingEngine() = default;

    /**
     * Sets active navigation route.
     */
    void setRoute(const Route& route);

    /**
     * Clears route and resets navigation progress.
     */
    void stopNavigation();

    /**
     * Ingests current GPS fix and updates progress.
     */
    NavigationProgress updateLocation(const Geometry::Coordinate& location, double speedMetersPerSecond = 0.0);

    /**
     * Thresholds configuration.
     */
    void setOffRouteThresholdMeters(double threshold) { offRouteThresholdMeters_ = threshold; }
    void setArrivalThresholdMeters(double threshold) { arrivalThresholdMeters_ = threshold; }

    /**
     * Generates realistic turn maneuver steps from an arbitrary polyline
     * based on segment bearing changes and segment lengths.
     */
    static std::vector<ManeuverStep> generateStepsFromPolyline(const Geometry::Polyline& polyline);

    const Route& currentRoute() const { return currentRoute_; }
    NavigationState currentState() const { return progress_.state; }

private:
    Route currentRoute_;
    NavigationProgress progress_;
    double offRouteThresholdMeters_{35.0};
    double arrivalThresholdMeters_{25.0};
};

} // namespace Routing
} // namespace Waze

#endif // WAZE_RECOVERY_ROUTING_ENGINE_HPP
