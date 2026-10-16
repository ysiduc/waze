# Waze iOS Reconstruction Progress Ledger (Phase 3.1)

**Last Updated:** October 17, 2026  
**Active Branch:** `reconstruction/waze-source-recovery`  
**Target Original Binary:** `Payload/Waze.app/Waze` (`0c40c247228439e2b75baca181569c75c144918561a8177e9399b183b5709d80`, 141,425,424 bytes)  
**Target Original IPA:** `/home/ysiduc/Downloads/waze.ipa` (`78c54a3db510c7d2142baeb13dd773c2f7774a3e4d99fb9a4cc966941086a158`, 114,712,520 bytes)  

---

## 1. Subsystem Audit Summary

| Subsystem ID | Application Subsystem | File Count | Classification | Realness Level | Test Coverage |
|:---|:---|:---:|:---:|:---:|:---:|
| **SUB-01** | Application Lifecycle & Bootstrap | 4 | **RECONSTRUCTED** | Real Native | Manual / CI Verified |
| **SUB-02** | Dependency Management (`SRLRegistry`) | 1 | **RECONSTRUCTED** | Real Native | Unit Tested |
| **SUB-03** | Main Map UI & Chrome | 4 | **RECONSTRUCTED** | Real Native | UI Verified |
| **SUB-04** | Map Rendering Architecture | 3 | **APPROXIMATED** | Simplified Math | Unit Tested |
| **SUB-05** | GPS & Location Tracking | 2 | **RECONSTRUCTED** | Real Native | Mocked Fixtures |
| **SUB-06** | Search & Destination Models | 3 | **APPROXIMATED** | Local Mocked | UI Interactive |
| **SUB-07** | Routing & Route Alternatives | 3 | **RECONSTRUCTED** | Real Logic | Unit Tested |
| **SUB-08** | Turn-by-Turn Guidance | 4 | **RECONSTRUCTED** | Real Native | Unit Tested |
| **SUB-09** | Navigation State & Off-Route Engine | 3 | **RECONSTRUCTED** | Real Algorithm | Unit Tested |
| **SUB-10** | Traffic & Hazard Reporting | 0 | **MISSING** *(Target for Phase 3.1)* | Not Implemented | None |
| **SUB-11** | Persistence & Keychain Storage | 2 | **RECONSTRUCTED** | Real Native | Unit Tested |
| **SUB-12** | Authentication & Session | 1 | **APPROXIMATED** | Client Shell | UI Interactive |
| **SUB-13** | Network Protocols & Services | 2 | **MOCKED** | Test Double | Mocked |
| **SUB-14** | App Extensions & CarPlay | 1 | **STUB** | Stub | None |
| **SUB-15** | Settings, Restrictions & Preferences | 1 | **APPROXIMATED** | Data Only | Unit Tested |

---

## 2. Source File Inventory & Classification

| File Path | Original Binary Evidence | Classification | Implemented Behavior | Remaining Gap |
|:---|:---|:---:|:---|:---|
| `App/AppDelegate.swift` | `0x1001fb7f8` (`WazeApp`) | **RECONSTRUCTED** | Application lifecycle & coordinator launch | AppCheck attestation initialization |
| `App/SceneDelegate.swift` | `SceneDelegate` | **RECONSTRUCTED** | Multi-window UIWindowScene setup | External display scene handling |
| `App/Lifecycle/AppLaunchCoordinator.swift` | `AppCoordinator` | **RECONSTRUCTED** | Auth check & navigation root switcher | Deep link URL route dispatch |
| `App/Configuration/AppConfiguration.swift` | `AppLifecycleFeatureManager` | **RECONSTRUCTED** | Build flags & environment configuration | Remote feature flag sync |
| `NativeEngine/Geometry/Coordinate.hpp/.cpp` | C++ spatial math routines | **RECONSTRUCTED** | WGS84 geodesy, haversine, bearing, cross-track | Slippy map tile coordinate math |
| `NativeEngine/Geometry/Polyline.hpp/.cpp` | Polyline encoding routines | **RECONSTRUCTED** | Google 5-decimal polyline decode/encode | Polyline simplification (RDP) |
| `NativeEngine/Routing/RoutingEngine.hpp/.cpp` | C++ Monorepo routing engine | **RECONSTRUCTED** | Step tracking, 35m off-route, 25m arrival | Bearing-based maneuver generation |
| `NativeEngine/Rendering/CanvasRenderer.hpp/.cpp` | `TileRendererBase` / `MercatorTile` | **APPROXIMATED** | Spherical Mercator project & quad tessellation | Vector tile decoding & rendering |
| `NativeEngine/Rendering/CanvasRenderer.metal` | `default.metallib` | **APPROXIMATED** | Metal vertex & fragment line shaders | Anti-aliased road edge shaders |
| `NativeEngine/Interop/NativeEngineBridge.h/.mm` | ObjC++ bridge layer | **RECONSTRUCTED** | Bridging C++ routing/geodesy to Swift | Exposing camera & tile projection |
| `Sources/Core/Types.swift` | Model structs | **RECONSTRUCTED** | Coordinates, bounding box, errors | Extended route metadata |
| `Sources/Core/ServiceRegistry.swift` | `0x100021b40` (`SRLRegistry`) | **RECONSTRUCTED** | Thread-safe service locator pattern | Hierarchical scoping |
| `Sources/Core/MainCanvasViewHolder.swift` | `0x107f1a4a0` (`MainCanvasViewHolder`) | **APPROXIMATED** | MTKView container & gesture recognizers | Pan camera displacement & drawing |
| `Sources/Location/WZWazeLocationServiceBridge.swift` | `0x107f19690` (`WZWazeLocationServiceBridge`) | **RECONSTRUCTED** | CoreLocation GPS feed & speed calculations | Dead-reckoning tunnel projection |
| `Sources/Models/LocationModel.swift` | `WSVLocationSpeed` | **RECONSTRUCTED** | Speed and heading data structures | Raw GPS accuracy filters |
| `Sources/Models/NavigationState.swift` | `NavigationStateBridge` | **RECONSTRUCTED** | Unidirectional navigation state | Lane-specific guidance states |
| `Sources/Models/RouteModels.swift` | `RouteUpdate` | **RECONSTRUCTED** | Route and maneuver step models | Toll road cost structures |
| `Sources/Models/SearchModels.swift` | `SearchResultsBridge` | **RECONSTRUCTED** | Destination and search result models | Rich POI metadata (phone, hours) |
| `Sources/Navigation/ManeuverType.swift` | `Maneuver` symbols | **RECONSTRUCTED** | 12 maneuver types & SF Symbol mappings | Complex multi-exit roundabout icons |
| `Sources/Navigation/NavigationGuidanceReducerBridge.swift` | `0x107f1ab08` (`NavigationGuidanceReducerBridge`) | **RECONSTRUCTED** | Distance to turn & approaching turn triggers | Dynamic lane configuration |
| `Sources/Networking/RoutingServiceProtocol.swift` | Routing interface | **RECONSTRUCTED** | Service protocol for route calculations | gRPC client protocol buffers |
| `Sources/Networking/LocalSimulatedRoutingService.swift` | None | **MOCKED** | Curved sine-wave synthetic route fixture | Real road-network graph routing |
| `Sources/Persistence/KeychainStorageService.swift` | `securityd` log error `-34018` | **RECONSTRUCTED** | Bundle-agnostic Keychain & guest fallback | Multi-account keychain synchronization |
| `Sources/Persistence/UserPreferencesService.swift` | `UserPreferences` | **RECONSTRUCTED** | UserDefaults toll/speed settings | Cloud preference synchronization |
| `Sources/Routing/AlternateRoutesStateMachineBridge.swift` | `0x107f17048` | **RECONSTRUCTED** | Alternate routes selection state machine | Dynamic traffic delay comparison |
| `Sources/Search/SearchEngine.swift` | `WazeSearchCoordinator` | **APPROXIMATED** | Local destination filter & recents list | Category search & spatial indexing |
| `Sources/CarPlay/WZCarPlayMapController.swift` | `0x107f17e30` | **STUB** | CarPlay connection flag | CPMapTemplate & navigation session |
| `Sources/UI/Common/WazeTheme.swift` | Visual theme specs | **RECONSTRUCTED** | Authentic Waze colors, fonts, cornerradii | Dynamic dark mode map palette |
| `Sources/UI/Common/WazeButton.swift` | `waze_WazeButtonPack...` | **RECONSTRUCTED** | Pill buttons with haptic feedback | Animated loading spinners |
| `Sources/UI/Welcome/WelcomeViewController.swift` | `waze_WazeOnboarding...` | **RECONSTRUCTED** | Authentic Waze welcome & guest login UI | Phone number OAuth login flow |
| `Sources/UI/MainCanvas/MainCanvasContainerViewController.swift` | `waze_WazeMainScreen...` | **RECONSTRUCTED** | Map container with zoom/recenter controls | Floating hazard reporting button |
| `Sources/UI/Overlays/NavigationBannerView.swift` | Navigation HUD | **RECONSTRUCTED** | Green turn instruction banner & icons | Lane guidance strip & sub-steps |
| `Sources/UI/Overlays/SpeedometerView.swift` | `waze_WazeMapOverlay.bundle` | **RECONSTRUCTED** | Circular speedometer & speed limit warning | Custom sound alert on speed violation |
| `Sources/UI/RoutePreview/RoutePreviewView.swift` | `waze_WazeTripOverview...` | **RECONSTRUCTED** | Route summary card with ETA & Go button | Alternate route selection carousel |
| `Sources/UI/Search/SearchDrawerViewController.swift` | `waze_WazeSearch...` | **RECONSTRUCTED** | Pull-up search sheet with search bar | Category grid (Gas, Food, Coffee) |
