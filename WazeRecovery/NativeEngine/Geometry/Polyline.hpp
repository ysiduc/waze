#ifndef WAZE_RECOVERY_POLYLINE_HPP
#define WAZE_RECOVERY_POLYLINE_HPP

#include "Coordinate.hpp"
#include <vector>
#include <string>

namespace Waze {
namespace Geometry {

/**
 * Represents a sequence of coordinates forming a route or map segment.
 * Reconstructed from Waze C++ route polyline processing engine.
 */
class Polyline {
public:
    Polyline() = default;
    explicit Polyline(const std::vector<Coordinate>& coordinates) : coordinates_(coordinates) {}

    void addCoordinate(const Coordinate& coord) {
        coordinates_.push_back(coord);
    }

    const std::vector<Coordinate>& coordinates() const {
        return coordinates_;
    }

    size_t size() const {
        return coordinates_.size();
    }

    bool empty() const {
        return coordinates_.empty();
    }

    const Coordinate& at(size_t index) const {
        return coordinates_.at(index);
    }

    void clear() {
        coordinates_.clear();
    }

    /**
     * Calculates total length of the polyline in meters.
     */
    double totalLengthMeters() const;

    /**
     * Finds the closest point on this polyline to a given GPS coordinate.
     * Outputs:
     * - closestPoint: Closest coordinate on the segment
     * - minDistanceMeters: Distance from point to closest point
     * - segmentIndex: Index of the segment [0, size - 2]
     */
    void findClosestPoint(const Coordinate& point,
                          Coordinate& outClosestPoint,
                          double& outMinDistanceMeters,
                          size_t& outSegmentIndex) const;

    /**
     * Decodes a Google Encoded Polyline algorithm string (precision 1e5).
     */
    static Polyline decode(const std::string& encodedString);

    /**
     * Encodes this polyline to an Encoded Polyline string (precision 1e5).
     */
    std::string encode() const;

private:
    std::vector<Coordinate> coordinates_;
};

} // namespace Geometry
} // namespace Waze

#endif // WAZE_RECOVERY_POLYLINE_HPP
