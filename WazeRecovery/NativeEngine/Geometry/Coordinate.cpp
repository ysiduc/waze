#include "Coordinate.hpp"

namespace Waze {
namespace Geometry {

static constexpr double kEarthRadiusMeters = 6371008.8; // Mean Earth radius in meters
static constexpr double kPi = 3.14159265358979323846;

static inline double degreesToRadians(double degrees) {
    return degrees * (kPi / 180.0);
}

static inline double radiansToDegrees(double radians) {
    return radians * (180.0 / kPi);
}

double haversineDistanceMeters(const Coordinate& c1, const Coordinate& c2) {
    if (!c1.isValid() || !c2.isValid()) {
        return 0.0;
    }

    double lat1 = degreesToRadians(c1.latitude);
    double lon1 = degreesToRadians(c1.longitude);
    double lat2 = degreesToRadians(c2.latitude);
    double lon2 = degreesToRadians(c2.longitude);

    double dLat = lat2 - lat1;
    double dLon = lon2 - lon1;

    double sinDlatHalf = std::sin(dLat / 2.0);
    double sinDlonHalf = std::sin(dLon / 2.0);

    double a = sinDlatHalf * sinDlatHalf +
               std::cos(lat1) * std::cos(lat2) * sinDlonHalf * sinDlonHalf;

    double c = 2.0 * std::atan2(std::sqrt(a), std::sqrt(1.0 - a));

    return kEarthRadiusMeters * c;
}

double calculateInitialBearing(const Coordinate& c1, const Coordinate& c2) {
    if (!c1.isValid() || !c2.isValid()) {
        return 0.0;
    }

    double lat1 = degreesToRadians(c1.latitude);
    double lat2 = degreesToRadians(c2.latitude);
    double dLon = degreesToRadians(c2.longitude - c1.longitude);

    double y = std::sin(dLon) * std::cos(lat2);
    double x = std::cos(lat1) * std::sin(lat2) -
               std::sin(lat1) * std::cos(lat2) * std::cos(dLon);

    double bearing = radiansToDegrees(std::atan2(y, x));
    // Normalize to [0, 360)
    return std::fmod(bearing + 360.0, 360.0);
}

Coordinate calculateDestination(const Coordinate& start, double distanceMeters, double bearingDegrees) {
    if (!start.isValid()) {
        return start;
    }

    double angularDist = distanceMeters / kEarthRadiusMeters;
    double bearingRad = degreesToRadians(bearingDegrees);

    double lat1 = degreesToRadians(start.latitude);
    double lon1 = degreesToRadians(start.longitude);

    double lat2 = std::asin(std::sin(lat1) * std::cos(angularDist) +
                            std::cos(lat1) * std::sin(angularDist) * std::cos(bearingRad));

    double lon2 = lon1 + std::atan2(std::sin(bearingRad) * std::sin(angularDist) * std::cos(lat1),
                                    std::cos(angularDist) - std::sin(lat1) * std::sin(lat2));

    // Normalize lon2 to [-180, 180]
    double lon2Deg = radiansToDegrees(lon2);
    lon2Deg = std::fmod(lon2Deg + 540.0, 360.0) - 180.0;

    return Coordinate(radiansToDegrees(lat2), lon2Deg, start.altitude);
}

double crossTrackDistanceMeters(const Coordinate& point, const Coordinate& lineStart, const Coordinate& lineEnd) {
    double distStartToPoint = haversineDistanceMeters(lineStart, point) / kEarthRadiusMeters;
    double bearingStartToPoint = degreesToRadians(calculateInitialBearing(lineStart, point));
    double bearingStartToEnd = degreesToRadians(calculateInitialBearing(lineStart, lineEnd));

    double crossTrackRad = std::asin(std::sin(distStartToPoint) * std::sin(bearingStartToPoint - bearingStartToEnd));
    return crossTrackRad * kEarthRadiusMeters;
}

double alongTrackDistanceMeters(const Coordinate& point, const Coordinate& lineStart, const Coordinate& lineEnd) {
    double distStartToPoint = haversineDistanceMeters(lineStart, point) / kEarthRadiusMeters;
    double crossTrackRad = crossTrackDistanceMeters(point, lineStart, lineEnd) / kEarthRadiusMeters;

    double alongTrackRad = std::acos(std::cos(distStartToPoint) / std::cos(crossTrackRad));
    return alongTrackRad * kEarthRadiusMeters;
}

} // namespace Geometry
} // namespace Waze
