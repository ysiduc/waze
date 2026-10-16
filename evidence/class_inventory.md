# Class Inventory: Architectural Classes & Modules

This document details key architectural classes verified through static inspection of Objective-C metadata (`__DATA_CONST.__objc_classlist`, `__TEXT.__objc_classname`) and C-string assertion tables in `Waze` (ARM64 executable).

---

## 1. Primary Verified Classes

| Class Name | Virtual Address | Protocol / Superclass | Source Path (from Assertions) | Architectural Role |
|---|---|---|---|---|
| **`MainCanvasViewHolder`** | `0x107f1a4a0` | `NSObject` | `third_party/waze/.../PrimaryMapViewHolder/MainCanvasViewHolder.mm` | Primary container for the vector map canvas on iOS; instantiates Metal view controller. |
| **`AlternateRoutesStateMachineBridge`** | `0x107f17048` | `AlternateRoutesStateMachineBridgeProtocol` | `third_party/waze/.../AlternativeRoutes/AlternateRoutesStateMachineBridge.mm` | Coordinates state transitions for alternative routes, reroute triggers, and poll intervals. |
| **`NavigationGuidanceReducerBridge`** | `0x107f1ab08` | `NavigationGuidanceReducerBridgeProtocol` | Swift module bridge | Unidirectional reducer mapping guidance events into navigation state snapshots. |
| **`WZWazeLocationServiceBridge`** | `0x107f19690` | `NSObject` | Location telemetry bridge | Bridges iOS `CoreLocation` updates and creates `WSVLocationSpeed` telemetry models. |
| **`WSVLocationSpeed`** | `0x107f4edd8` | `NSObject` | Telemetry model | Transfer object containing latitude, longitude, and velocity data. |
| **`WZCarPlayMapController`** | `0x107f17e30` | `NSObject` | CarPlay integration | Manages Apple CarPlay template displays, CarPlay canvas viewports, and automotive HUD. |
| **`SRLMemoizingScope`** | `0x107f16260` | `NSObject` | Google SRL framework | Implements service registry scoping and memoized singleton resolution. |
| **`SRLRegistry`** | Mapped in metadata | `NSObject` | Google SRL framework | Service Locator Registry used throughout Google iOS client applications. |
| **`RoutingServiceRoute`** | Mapped in metadata | `NSObject` | Routing core | Encapsulates route segments, maneuvers, turn points, and distance models. |
| **`NavigationSession`** | Mapped in metadata | `NSObject` | Navigation lifecycle | Manages active turn-by-turn guidance sessions and destination states. |

---

## 2. Verified Protocol Interfaces

1. **`AlternateRoutesStateMachineBridgeProtocol`:**
   - Declares state machine transition triggers and routing update notification callbacks.
2. **`NavigationGuidanceReducerBridgeProtocol`:**
   - Full Swift Mangled Name: `_TtP95third_party_waze_client_ios_modules_WazeNavigationGuidance_WazeNavigationGuidanceImplementation39NavigationGuidanceReducerBridgeProtocol_`
   - Defines unidirectional event reduction interface between C++ core navigation and Swift guidance UI.
3. **`MainCanvasViewHolderDelegate` / `MapBridgeViewController`:**
   - Defines viewport resizing, bounds change strategies (`mainCanvasBridge:didChangeMapBoundsStrategy:`), and camera orientation updates.

---

## 3. Swift Reflection Type Mapping

Representative types verified in `__TEXT.__swift5_reflstr` (396.5 KB):
- **`alternativeRoutesFeatureManager`**: Manages UI state and comparisons for alternate routes.
- **`ecoRoutesFeatureManager`**: Handles fuel-efficient / eco-routing options.
- **`navigationGuidanceFeatureManager`**: Manages active turn banners and maneuver countdowns.
- **`locationFeatureManager`**: Coordinates location permission state and sensor health.
- **`etaUIFeatureManager`**: Controls ETA bar, remaining distance, and destination arrival widgets.
- **`mapOverlayFeatureManager`**: Manages speed camera alerts, hazard icons, and user pins overlaid on the map.
