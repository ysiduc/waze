#ifndef WAZE_RECOVERY_COORDINATE_HPP
#define WAZE_RECOVERY_COORDINATE_HPP

#include <cmath>
#include <string>

namespace Waze {
namespace Geometry {

/**
 * Represents a geographical WGS84 coordinate (latitude, longitude, altitude).
 * Reconstructed from C++ spatial routines in Waze ARM64 core engine.
 */
struct Coordinate {
    double latitude;   // Degrees [-90.0, 90.0]
    double longitude;  // Degrees [-180.0, 180.0]
    double altitude;   // Meters above sea level

    Coordinate() : latitude(0.0), longitude(0.0), altitude(0.0) {}
    Coordinate(double lat, double lon, double alt = 0.0)
        : latitude(lat), longitude(lon), altitude(alt) {}

    bool isValid() const {
        return latitude >= -90.0 && latitude <= 90.0 &&
               longitude >= -180.0 && longitude <= 180.0;
    }

    bool operator==(const Coordinate& other) const {
        const double eps = 1e-7;
        return std::fabs(latitude - other.latitude) < eps &&
               std::fabs(longitude - other.longitude) < eps;
    }

    bool operator!=(const Coordinate& other) const {
        return !(*this == other);
    }
};

/**
 * Calculates great-circle distance between two coordinates in meters using the Haversine formula.
 */
double haversineDistanceMeters(const Coordinate& c1, const Coordinate& c2);

/**
 * Calculates initial bearing from c1 to c2 in degrees [0, 360).
 */
double calculateInitialBearing(const Coordinate& c1, const Coordinate& c2);

/**
 * Calculates destination point given starting coordinate, distance (meters), and bearing (degrees).
 */
Coordinate calculateDestination(const Coordinate& start, double distanceMeters, double bearingDegrees);

/**
 * Calculates cross-track distance from point P to geodesic line between start and end.
 * Returns signed distance in meters (positive = right of track, negative = left of track).
 */
double crossTrackDistanceMeters(const Coordinate& point, const Coordinate& lineStart, const Coordinate& lineEnd);

/**
 * Calculates along-track distance from lineStart towards lineEnd to the projection of point P.
 */
double alongTrackDistanceMeters(const Coordinate& point, const Coordinate& lineStart, const Coordinate& lineEnd);

} // namespace Geometry
} // namespace Waze

#endif // WAZE_RECOVERY_COORDINATE_HPP
