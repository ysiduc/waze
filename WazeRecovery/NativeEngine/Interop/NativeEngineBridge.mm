#import "NativeEngineBridge.h"
#include "../Geometry/Coordinate.hpp"
#include "../Geometry/Polyline.hpp"
#include "../Routing/RoutingEngine.hpp"

@implementation WZNativeProgress
@end

@implementation WZNativeTile
@end

@implementation WZNativeStep
@end

@interface WZNativeEngineBridge () {
    std::unique_ptr<Waze::Routing::RoutingEngine> _routingEngine;
}
@end

@implementation WZNativeEngineBridge

+ (instancetype)sharedBridge {
    static WZNativeEngineBridge *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[WZNativeEngineBridge alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _routingEngine = std::make_unique<Waze::Routing::RoutingEngine>();
    }
    return self;
}

+ (double)distanceFrom:(CLLocationCoordinate2D)from to:(CLLocationCoordinate2D)to {
    Waze::Geometry::Coordinate c1(from.latitude, from.longitude);
    Waze::Geometry::Coordinate c2(to.latitude, to.longitude);
    return Waze::Geometry::haversineDistanceMeters(c1, c2);
}

+ (double)bearingFrom:(CLLocationCoordinate2D)from to:(CLLocationCoordinate2D)to {
    Waze::Geometry::Coordinate c1(from.latitude, from.longitude);
    Waze::Geometry::Coordinate c2(to.latitude, to.longitude);
    return Waze::Geometry::calculateInitialBearing(c1, c2);
}

+ (NSArray<NSValue *> *)decodePolyline:(NSString *)encodedString {
    if (!encodedString || [encodedString length] == 0) {
        return @[];
    }
    std::string str([encodedString UTF8String]);
    Waze::Geometry::Polyline poly = Waze::Geometry::Polyline::decode(str);

    NSMutableArray<NSValue *> *result = [NSMutableArray arrayWithCapacity:poly.size()];
    for (const auto& c : poly.coordinates()) {
        CLLocationCoordinate2D coord = CLLocationCoordinate2DMake(c.latitude, c.longitude);
        [result addObject:[NSValue valueWithBytes:&coord objCType:@encode(CLLocationCoordinate2D)]];
    }
    return [result copy];
}

+ (NSString *)encodePolyline:(NSArray<NSValue *> *)coordinates {
    if (!coordinates || [coordinates count] == 0) {
        return @"";
    }
    std::vector<Waze::Geometry::Coordinate> coords;
    coords.reserve([coordinates count]);

    for (NSValue *val in coordinates) {
        CLLocationCoordinate2D coord;
        [val getValue:&coord];
        coords.emplace_back(coord.latitude, coord.longitude);
    }

    Waze::Geometry::Polyline poly(coords);
    std::string encoded = poly.encode();
    return [NSString stringWithUTF8String:encoded.c_str()];
}

+ (WZNativeTile *)tileForCoordinate:(CLLocationCoordinate2D)coord zoom:(NSInteger)zoom {
    Waze::Geometry::Coordinate c(coord.latitude, coord.longitude);
    Waze::Geometry::TileCoordinate tc = Waze::Geometry::latLonToTile(c, static_cast<int>(zoom));

    WZNativeTile *tile = [[WZNativeTile alloc] init];
    tile.x = tc.x;
    tile.y = tc.y;
    tile.zoom = tc.zoom;
    return tile;
}

+ (CLLocationCoordinate2D)coordinateForTileX:(NSInteger)x y:(NSInteger)y zoom:(NSInteger)zoom {
    Waze::Geometry::Coordinate c = Waze::Geometry::tileToLatLon(static_cast<int>(x), static_cast<int>(y), static_cast<int>(zoom));
    return CLLocationCoordinate2DMake(c.latitude, c.longitude);
}

+ (NSArray<WZNativeStep *> *)generateManeuversForPolyline:(NSArray<NSValue *> *)coordinates {
    if (!coordinates || [coordinates count] < 2) {
        return @[];
    }
    std::vector<Waze::Geometry::Coordinate> coords;
    coords.reserve([coordinates count]);
    for (NSValue *val in coordinates) {
        CLLocationCoordinate2D coord;
        [val getValue:&coord];
        coords.emplace_back(coord.latitude, coord.longitude);
    }
    Waze::Geometry::Polyline poly(coords);
    auto steps = Waze::Routing::RoutingEngine::generateStepsFromPolyline(poly);

    NSMutableArray<WZNativeStep *> *result = [NSMutableArray arrayWithCapacity:steps.size()];
    for (const auto& s : steps) {
        WZNativeStep *step = [[WZNativeStep alloc] init];
        step.maneuver = static_cast<WZNativeManeuver>(s.maneuver);
        step.instruction = [NSString stringWithUTF8String:s.instruction.c_str()];
        step.streetName = [NSString stringWithUTF8String:s.streetName.c_str()];
        step.distanceMeters = s.distanceMeters;
        step.durationSeconds = s.durationSeconds;
        step.coordinate = CLLocationCoordinate2DMake(s.coordinate.latitude, s.coordinate.longitude);
        [result addObject:step];
    }
    return [result copy];
}

- (void)startNavigationWithPolyline:(NSArray<NSValue *> *)coordinates
                       totalDistance:(double)totalDistanceMeters
                       totalDuration:(double)totalDurationSeconds {
    std::vector<Waze::Geometry::Coordinate> coords;
    coords.reserve([coordinates count]);

    for (NSValue *val in coordinates) {
        CLLocationCoordinate2D coord;
        [val getValue:&coord];
        coords.emplace_back(coord.latitude, coord.longitude);
    }

    Waze::Routing::Route route;
    route.routeId = "recovered_route_001";
    route.summary = "Reconstructed Waze Route";
    route.totalDistanceMeters = totalDistanceMeters;
    route.totalDurationSeconds = totalDurationSeconds;
    route.geometry = Waze::Geometry::Polyline(coords);
    route.steps = Waze::Routing::RoutingEngine::generateStepsFromPolyline(route.geometry);

    _routingEngine->setRoute(route);
}

- (void)stopNavigation {
    _routingEngine->stopNavigation();
}

- (WZNativeProgress *)updateLocation:(CLLocationCoordinate2D)location speed:(double)speed {
    Waze::Geometry::Coordinate coord(location.latitude, location.longitude);
    Waze::Routing::NavigationProgress p = _routingEngine->updateLocation(coord, speed);

    WZNativeProgress *progress = [[WZNativeProgress alloc] init];
    progress.state = static_cast<WZNativeNavState>(p.state);
    progress.currentStepIndex = p.currentStepIndex;
    progress.distanceToNextTurnMeters = p.distanceToNextTurnMeters;
    progress.distanceToDestinationMeters = p.distanceToDestinationMeters;
    progress.timeToDestinationSeconds = p.timeToDestinationSeconds;
    progress.isOffRoute = p.isOffRoute;
    progress.snappedCoordinate = CLLocationCoordinate2DMake(p.snappedLocation.latitude, p.snappedLocation.longitude);
    progress.nextManeuver = static_cast<WZNativeManeuver>(p.nextManeuver);
    progress.nextInstruction = [NSString stringWithUTF8String:p.nextInstruction.c_str()];
    progress.currentStreet = [NSString stringWithUTF8String:p.currentStreet.c_str()];

    return progress;
}

@end
