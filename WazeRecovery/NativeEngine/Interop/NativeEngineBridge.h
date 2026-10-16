#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, WZNativeManeuver) {
    WZNativeManeuverDepart = 0,
    WZNativeManeuverContinue = 1,
    WZNativeManeuverTurnLeft = 2,
    WZNativeManeuverTurnRight = 3,
    WZNativeManeuverSharpLeft = 4,
    WZNativeManeuverSharpRight = 5,
    WZNativeManeuverSlightLeft = 6,
    WZNativeManeuverSlightRight = 7,
    WZNativeManeuverUTurn = 8,
    WZNativeManeuverMerge = 9,
    WZNativeManeuverRoundabout = 10,
    WZNativeManeuverArrive = 11
};

typedef NS_ENUM(NSInteger, WZNativeNavState) {
    WZNativeNavStateIdle = 0,
    WZNativeNavStateRouting = 1,
    WZNativeNavStateNavigating = 2,
    WZNativeNavStateRerouting = 3,
    WZNativeNavStateArrived = 4
};

@interface WZNativeProgress : NSObject

@property (nonatomic, assign) WZNativeNavState state;
@property (nonatomic, assign) NSInteger currentStepIndex;
@property (nonatomic, assign) double distanceToNextTurnMeters;
@property (nonatomic, assign) double distanceToDestinationMeters;
@property (nonatomic, assign) double timeToDestinationSeconds;
@property (nonatomic, assign) BOOL isOffRoute;
@property (nonatomic, assign) CLLocationCoordinate2D snappedCoordinate;
@property (nonatomic, assign) WZNativeManeuver nextManeuver;
@property (nonatomic, copy) NSString *nextInstruction;
@property (nonatomic, copy) NSString *currentStreet;

@end

@interface WZNativeEngineBridge : NSObject

+ (instancetype)sharedBridge;

// Geodesy & Math
+ (double)distanceFrom:(CLLocationCoordinate2D)from to:(CLLocationCoordinate2D)to;
+ (double)bearingFrom:(CLLocationCoordinate2D)from to:(CLLocationCoordinate2D)to;
+ (NSArray<NSValue *> *)decodePolyline:(NSString *)encodedString;
+ (NSString *)encodePolyline:(NSArray<NSValue *> *)coordinates;

// Routing Session Management
- (void)startNavigationWithPolyline:(NSArray<NSValue *> *)coordinates
                       totalDistance:(double)totalDistanceMeters
                       totalDuration:(double)totalDurationSeconds;

- (void)stopNavigation;

- (WZNativeProgress *)updateLocation:(CLLocationCoordinate2D)location speed:(double)speed;

@end

NS_ASSUME_NONNULL_END
