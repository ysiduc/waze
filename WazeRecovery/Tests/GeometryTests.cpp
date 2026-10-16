#include "../NativeEngine/Geometry/Coordinate.hpp"
#include "../NativeEngine/Geometry/Polyline.hpp"
#include <cassert>
#include <cmath>
#include <iostream>

using namespace Waze::Geometry;

void testCoordinateValidation() {
    Coordinate valid(37.7749, -122.4194);
    assert(valid.isValid());

    Coordinate invalidLat(95.0, 0.0);
    assert(!invalidLat.isValid());

    Coordinate invalidLon(0.0, 190.0);
    assert(!invalidLon.isValid());

    std::cout << "[PASS] Coordinate Validation" << std::endl;
}

void testHaversineDistance() {
    // SF to Oakland (~12.8 km / 12,800m)
    Coordinate sf(37.7749, -122.4194);
    Coordinate oakland(37.8044, -122.2712);

    double dist = haversineDistanceMeters(sf, oakland);
    assert(dist > 12000.0 && dist < 14000.0);

    // Distance to self is 0
    assert(haversineDistanceMeters(sf, sf) == 0.0);

    std::cout << "[PASS] Haversine Distance: " << dist << "m" << std::endl;
}

void testBearingCalculation() {
    Coordinate start(0.0, 0.0);
    Coordinate north(1.0, 0.0);
    Coordinate east(0.0, 1.0);

    double bNorth = calculateInitialBearing(start, north);
    assert(std::fabs(bNorth - 0.0) < 1e-3);

    double bEast = calculateInitialBearing(start, east);
    assert(std::fabs(bEast - 90.0) < 1e-3);

    std::cout << "[PASS] Bearing Calculation" << std::endl;
}

void testPolylineEncodeDecode() {
    // Standard Google polyline example
    // (38.5, -120.2), (40.7, -120.95), (43.252, -126.453) -> "_p~iF~ps|U_ulLnnqC_mqNvxq`@"
    std::string encoded = "_p~iF~ps|U_ulLnnqC_mqNvxq`@";
    Polyline poly = Polyline::decode(encoded);

    assert(poly.size() == 3);
    assert(std::fabs(poly.at(0).latitude - 38.5) < 1e-4);
    assert(std::fabs(poly.at(0).longitude - (-120.2)) < 1e-4);

    std::string reencoded = poly.encode();
    assert(reencoded == encoded);

    std::cout << "[PASS] Polyline Encode/Decode Roundtrip: " << reencoded << std::endl;
}

void testClosestPointOnPolyline() {
    std::vector<Coordinate> coords = {
        Coordinate(0.0, 0.0),
        Coordinate(0.0, 1.0),
        Coordinate(0.0, 2.0)
    };
    Polyline poly(coords);

    Coordinate query(0.1, 0.5); // Slightly north of the middle of first segment
    Coordinate closest;
    double dist = 0.0;
    size_t segIdx = 0;

    poly.findClosestPoint(query, closest, dist, segIdx);

    assert(segIdx == 0);
    assert(std::fabs(closest.latitude - 0.0) < 1e-3);
    assert(std::fabs(closest.longitude - 0.5) < 1e-2);
    assert(dist > 10000.0 && dist < 12000.0); // ~0.1 deg lat = ~11.1 km

    std::cout << "[PASS] Polyline Closest Point" << std::endl;
}

void testBoundingBox() {
    BoundingBox box(37.0, -123.0, 38.0, -122.0);
    Coordinate inside(37.5, -122.5);
    Coordinate outside(36.9, -122.5);

    assert(box.contains(inside));
    assert(!box.contains(outside));

    BoundingBox overlapping(37.5, -122.5, 38.5, -121.5);
    assert(box.intersects(overlapping));

    box.expandToInclude(outside);
    assert(box.contains(outside));

    std::cout << "[PASS] Bounding Box Intersection & Containment" << std::endl;
}

void testMercatorTileConversion() {
    // San Francisco coordinate at zoom 15
    Coordinate sf(37.7749, -122.4194);
    TileCoordinate tile = latLonToTile(sf, 15);

    assert(tile.zoom == 15);
    assert(tile.x > 0 && tile.x < (1 << 15));
    assert(tile.y > 0 && tile.y < (1 << 15));

    Coordinate nw = tileToLatLon(tile.x, tile.y, 15);
    assert(nw.isValid());
    BoundingBox bounds = tileBounds(tile.x, tile.y, 15);
    assert(bounds.contains(sf));

    std::cout << "[PASS] Spherical Mercator Tile Conversion (Z15: X=" << tile.x << ", Y=" << tile.y << ")" << std::endl;
}

int main() {
    std::cout << "--- Running Geometry & Polyline C++ Unit Tests ---" << std::endl;
    testCoordinateValidation();
    testHaversineDistance();
    testBearingCalculation();
    testPolylineEncodeDecode();
    testClosestPointOnPolyline();
    testBoundingBox();
    testMercatorTileConversion();
    std::cout << "All 7 Geometry unit tests PASSED successfully." << std::endl;
    return 0;
}

