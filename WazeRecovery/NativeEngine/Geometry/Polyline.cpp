#include "Polyline.hpp"
#include <algorithm>
#include <sstream>
#include <cstdint>

namespace Waze {
namespace Geometry {

double Polyline::totalLengthMeters() const {
    if (coordinates_.size() < 2) {
        return 0.0;
    }

    double total = 0.0;
    for (size_t i = 0; i + 1 < coordinates_.size(); ++i) {
        total += haversineDistanceMeters(coordinates_[i], coordinates_[i + 1]);
    }
    return total;
}

void Polyline::findClosestPoint(const Coordinate& point,
                                Coordinate& outClosestPoint,
                                double& outMinDistanceMeters,
                                size_t& outSegmentIndex) const {
    if (coordinates_.empty()) {
        outClosestPoint = point;
        outMinDistanceMeters = 0.0;
        outSegmentIndex = 0;
        return;
    }

    if (coordinates_.size() == 1) {
        outClosestPoint = coordinates_[0];
        outMinDistanceMeters = haversineDistanceMeters(point, coordinates_[0]);
        outSegmentIndex = 0;
        return;
    }

    outMinDistanceMeters = 1e9;
    outSegmentIndex = 0;

    for (size_t i = 0; i + 1 < coordinates_.size(); ++i) {
        const Coordinate& start = coordinates_[i];
        const Coordinate& end = coordinates_[i + 1];

        double segLen = haversineDistanceMeters(start, end);
        if (segLen < 1e-3) {
            double d = haversineDistanceMeters(point, start);
            if (d < outMinDistanceMeters) {
                outMinDistanceMeters = d;
                outClosestPoint = start;
                outSegmentIndex = i;
            }
            continue;
        }

        double along = alongTrackDistanceMeters(point, start, end);
        Coordinate candidate;
        if (along <= 0.0) {
            candidate = start;
        } else if (along >= segLen) {
            candidate = end;
        } else {
            double bearing = calculateInitialBearing(start, end);
            candidate = calculateDestination(start, along, bearing);
        }

        double dist = haversineDistanceMeters(point, candidate);
        if (dist < outMinDistanceMeters) {
            outMinDistanceMeters = dist;
            outClosestPoint = candidate;
            outSegmentIndex = i;
        }
    }
}

Polyline Polyline::decode(const std::string& encoded) {
    std::vector<Coordinate> coords;
    size_t index = 0;
    size_t len = encoded.length();
    int lat = 0;
    int lng = 0;

    while (index < len) {
        int b;
        int shift = 0;
        int result = 0;
        do {
            if (index >= len) break;
            b = encoded[index++] - 63;
            result |= (b & 0x1f) << shift;
            shift += 5;
        } while (b >= 0x20);

        int dlat = ((result & 1) ? ~(result >> 1) : (result >> 1));
        lat += dlat;

        shift = 0;
        result = 0;
        do {
            if (index >= len) break;
            b = encoded[index++] - 63;
            result |= (b & 0x1f) << shift;
            shift += 5;
        } while (b >= 0x20);

        int dlng = ((result & 1) ? ~(result >> 1) : (result >> 1));
        lng += dlng;

        coords.emplace_back(lat * 1e-5, lng * 1e-5);
    }

    return Polyline(coords);
}

static void encodeValue(int value, std::string& out) {
    value = (value < 0) ? ~(value << 1) : (value << 1);
    while (value >= 0x20) {
        out.push_back(static_cast<char>((0x20 | (value & 0x1f)) + 63));
        value >>= 5;
    }
    out.push_back(static_cast<char>(value + 63));
}

std::string Polyline::encode() const {
    std::string result;
    int prevLat = 0;
    int prevLng = 0;

    for (const auto& coord : coordinates_) {
        int curLat = static_cast<int>(std::round(coord.latitude * 1e5));
        int curLng = static_cast<int>(std::round(coord.longitude * 1e5));

        encodeValue(curLat - prevLat, result);
        encodeValue(curLng - prevLng, result);

        prevLat = curLat;
        prevLng = curLng;
    }

    return result;
}

} // namespace Geometry
} // namespace Waze
