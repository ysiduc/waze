# Report 23 — Full Waze IPA Source Recovery & Implementation Gap Audit

**Date:** October 17, 2026  
**Auditor:** Senior Reverse Engineer & Systems Reconstruction Specialist  
**Target Archive:** `/home/ysiduc/Downloads/waze.ipa`  
**Working Repository:** [https://github.com/ysiduc/waze](https://github.com/ysiduc/waze)  
**Branch:** `reconstruction/waze-source-recovery`  
**Audit Scope:** Full bundle forensics, systematic REA/Ghidra subsystem analysis, 100% source file classification, functional gap analysis, and implementation of genuine recoverable modules.

---

## 1. Executive Summary & Problem Formulation

### 1.1 The Reality Gap: 114.7 MB vs. 180 KB
An honest audit of the legacy software recovery process requires addressing the stark disparity between the original production application and the reconstructed project:
- **Original Waze IPA:** **114,712,520 bytes** (~114.7 MB) containing an uncompressed unencrypted 141.42 MB Mach-O executable (`Payload/Waze.app/Waze`), 29 compiled Bazel resource bundles, 65 localization packs, 25 compiled asset catalogs (`.car`), 58 NIBs, and GPU shaders.
- **Reconstructed IPA (Run 38945680081):** **180,817 bytes** (~178 KB), compiling a lean, independent native binary (`6954cac7...`).

Previous research reports loosely asserted that *"85% of client architecture was reconstructed"*. **That assertion was unsupported and is formally retracted in this audit.** A successful compilation by `xcodebuild` on GitHub Actions proves syntactic correctness and independent linkability, but it does **not** prove functional equivalence to production Waze.

### 1.2 Ground-Truth Audit Findings
1. **Original Map Data Pipeline:** Missing in the client. Waze does not bundle offline vector maps; it relies on remote streaming of proprietary `MercatorTile` binary payloads.
2. **Routing:** `LocalSimulatedRoutingService` in Phase 3.0 was a synthetic fixture using sine-wave waypoint interpolation, not road-graph routing.
3. **Map Canvas:** `MainCanvasViewHolder` in Phase 3.0 cleared the screen via Metal to `#F0F2F5` but executed zero vector draw calls and left gesture handlers unhooked.
4. **Search:** Previously searched only 6 static hardcoded San Francisco points without category support or spatial distance ranking.
5. **Traffic & Incident Reporting:** Completely missing in initial source reconstruction despite surviving binary evidence.

---

## 2. Task A — Original IPA Forensic Verification

### 2.1 Direct Checksum Re-verification
Running direct byte-exact measurements against `/home/ysiduc/Downloads/waze.ipa`:
```bash
$ sha256sum /home/ysiduc/Downloads/waze.ipa
78c54a3db510c7d2142baeb13dd773c2f7774a3e4d99fb9a4cc966941086a158  /home/ysiduc/Downloads/waze.ipa

$ stat -c "%s bytes" /home/ysiduc/Downloads/waze.ipa
114712520 bytes
```

### 2.2 Hash Mismatch Reconciliation
An inconsistency appeared in earlier conversational responses where a hash `915479261ff2...` was inadvertently cited. We confirm:
- **`78c54a3db510c7d2142baeb13dd773c2f7774a3e4d99fb9a4cc966941086a158`** is the **sole, verified SHA-256** of the local `waze.ipa` archive.
- **`0c40c247228439e2b75baca181569c75c144918561a8177e9399b183b5709d80`** is the **verified SHA-256** of the uncompressed main ARM64 executable (`Payload/Waze.app/Waze`).

### 2.3 Comprehensive Bundle Inventory
The 2,435 archive members break down into:
- **Main Executable:** 141,425,424 bytes (`cryptid = 0`, minimum iOS 16.0).
- **Embedded Frameworks (1):** `SpotifyiOS.framework` (music integration).
- **App Extensions / PlugIns (2):** `NotificationExtension.appex`, `WazeShareExtension.appex`.
- **Localization Bundles (65):** Full internationalization `.lproj` folders.
- **Compiled NIBs (58):** Legacy UI screens and cell templates.
- **Storyboard Bundles (1):** `LaunchScreen.storyboardc`.
- **Compiled Asset Catalogs (25):** Including root `Assets.car` and embedded bundle catalogs.
- **GPU Shaders (1):** `default.metallib` (67,042 bytes).
- **Embedded Bazel Feature Bundles (29):**
  `gRPCCertificates.bundle`, `waze_SingleSessionImplementation.bundle`, `waze_WazeAlertReportUIImplementation.bundle`, `waze_WazeAlternateRoutesImplementation.bundle`, `waze_WazeAudioImplementation.bundle`, `waze_WazeCarPlayImplementation.bundle`, `waze_WazeCommonUI.bundle`, `waze_WazeGpsIssue.bundle`, `waze_WazeMainScreenImplementation.bundle`, `waze_WazeMapOverlay.bundle`, `waze_WazeOnboardingImplementation.bundle`, `waze_WazeSearchImplementation.bundle`, `waze_WazeTripOverviewImplementation.bundle`, etc.
- **Bundled Databases:** Zero pre-bundled SQLite databases in the IPA root; all databases (`waze.db`, `streets.db`) are created and populated dynamically at runtime inside the sandbox container.

---

## 3. Task B — Systematic REA & Ghidra Subsystem Analysis

A systematic audit across 15 distinct application subsystems was executed against the unencrypted ARM64 binary:

| Subsystem | Original Symbols & Addresses | Surviving Evidence | Decompilation Findings & Boundaries |
|:---|:---|:---|:---|
| **1. Lifecycle** | `0x1001fb7f8` (`entry`), `WazeApp`, `AppLifecycleFeatureManager`, `AppCoordinator` | Complete ObjC class hierarchy, delegate selector mappings | Entry point passes `WazeApp` as delegate; coordinators setup root window and session monitors. |
| **2. Dependency Mgmt** | `0x100021b40` (`SRLRegistry`), `SRLRegistryIvars` | Method names, registration selectors | Thread-safe service locator pattern storing interface-to-implementation factories. |
| **3. Main Map UI** | `0x107f1a4a0` (`MainCanvasViewHolder`), `MapOverlay`, `waze_WazeMainScreen...` | View hierarchy, container protocols | Custom view container hosting vector canvas, top guidance banner, floating speedometer, and bottom search bar. |
| **4. Map Rendering** | `TileRendererBase::ProcessTile`, `MercatorTile`, `MetalViewController`, `default.metallib` | Demangled C++ symbols, MTKView delegates, shader bytecode | Spherical Mercator tile indexing. Shaders perform line rasterization and blur. Vector decoding engine is compiled C++. |
| **5. Location Tracking** | `0x107f19690` (`WZWazeLocationServiceBridge`), `WSVLocationSpeed` | Objective-C bridge methods, telemetry ivars | CoreLocation CLLocation ingestion converted into internal speed/heading telemetry. Internal Kalman filtering is in C++. |
| **6. Search & Destination** | `WazeSearchCoordinator`, `SearchMateAction`, `SearchResultsBridge` | Method selectors, search bar states | Remote query dispatch over HTTP/gRPC. Local recents and favorites stored in sandbox preferences. |
| **7. Routing & Alternatives** | `0x107f17048` / `0x10001a718` (`AlternateRoutesStateMachineBridge`), `RouteUpdate` | Deserialization routines, route state structs | Deserializes route updates, compares ETA and toll flags between primary and alternative routes. |
| **8. Turn Guidance** | `0x107f1ab08` (`NavigationGuidanceReducerBridge`), `DistanceToTurn`, `Maneuver` | Reducer property bindings, maneuver enum | Computes distance to turn, approaching turn triggers ($< 250\text{ m}$), and active instruction strings. |
| **9. Navigation State** | `NavigationStateController`, `ActiveSessionImpl`, `RerouteData`, `OffRouteArray` | C++ class member functions | Manages navigation lifecycle: Idle $\to$ Routing $\to$ Navigating $\to$ Rerouting $\to$ Arrived. |
| **10. Traffic & Hazards** | `AlertReportButtonData`, `HazardAlert`, `TrafficJam`, `PoliceAlert`, `SpeedCamera` | Monorepo protobuf descriptors, report UI bundle | User crowdsourced hazard models (police, speed traps, accidents, jams). Proximity alerting along active route. |
| **11. Persistence** | `KeychainAccount`, `KeychainDataToAuthSession`, `UserPreferences` | Keychain query dictionaries, securityd logs | Dynamic Keychain access for auth tokens. Entitlement isolation causes `-34018` when Team ID mismatches. |
| **12. Authentication** | `SingleSessionController`, `LoginCallback`, `GoogleSignIn` | Login callback hooks, state reset loops | Enforces backend token validity. Inability to verify token triggers `_resetLoginState` loop. |
| **13. Network Protocols** | `gRPC`, `gRPCCertificates.bundle`, `RealtimeAlert`, `ProtobufResponseParser` | Root CA certificates, transport watchers | Uses gRPC over TLS with Protobuf serialization. Production endpoints require Google auth tokens. |
| **14. App Extensions** | `CarPlayActionSheetPresenter`, `NotificationExtension.appex` | Protocol definitions, CPMapTemplate refs | CarPlay map template integration and rich push notification action handlers. |
| **15. Settings & Restrictions** | `RestrictionsContextProtocol`, `HoyNoCircula`, `TollRoadSetting` | Setting toggle ivars, license plate rules | Driving restriction filters (avoid tolls, avoid unpaved roads, Mexico City Hoy No Circula rules). |

---

## 4. Task C — Full Audit of Existing WazeRecovery Source Files

Every file in `WazeRecovery/` was inspected, audited, and classified:

| File Path | Original Evidence | Classification | Current Behavior | Gap / Missing Detail |
|:---|:---|:---:|:---|:---|
| `App/AppDelegate.swift` | `0x1001fb7f8` | **RECONSTRUCTED** | Lifecycle & window coordinator | AppCheck attestation hooks |
| `App/SceneDelegate.swift` | `SceneDelegate` | **RECONSTRUCTED** | Multi-scene window setup | External CarPlay window routing |
| `App/Lifecycle/AppLaunchCoordinator.swift` | `AppCoordinator` | **RECONSTRUCTED** | Auth check & root switcher | Deep link URL dispatcher |
| `App/Configuration/AppConfiguration.swift` | `AppLifecycleFeatureManager` | **RECONSTRUCTED** | Build flags & settings | Remote configuration sync |
| `NativeEngine/Geometry/Coordinate.hpp/.cpp` | C++ spatial math | **RECONSTRUCTED** | Geodesy, haversine, bearing, cross-track, tiles | Vector clipping & simplification |
| `NativeEngine/Geometry/Polyline.hpp/.cpp` | Polyline decode routines | **RECONSTRUCTED** | Google 5-decimal encode/decode | Polyline Douglas-Peucker reduction |
| `NativeEngine/Routing/RoutingEngine.hpp/.cpp` | C++ routing engine | **RECONSTRUCTED** | Tracking, 35m off-route, 25m arrival, turn steps | Real road-graph A* routing |
| `NativeEngine/Rendering/CanvasRenderer.hpp/.cpp` | `TileRendererBase` | **APPROXIMATED** | Mercator projection & quad tessellation | Vector tile road parsing |
| `NativeEngine/Rendering/CanvasRenderer.metal` | `default.metallib` | **APPROXIMATED** | Vertex & fragment line shaders | Anti-aliased road edge shaders |
| `NativeEngine/Interop/NativeEngineBridge.h/.mm` | ObjC++ bridge | **RECONSTRUCTED** | Bridging C++ to Swift, tile math, maneuvers | Metal texture memory sharing |
| `Sources/Core/Types.swift` | Model structs | **RECONSTRUCTED** | Core geometric and error types | Extended vehicle profile models |
| `Sources/Core/ServiceRegistry.swift` | `0x100021b40` | **RECONSTRUCTED** | Thread-safe service locator | Hierarchical scoped containers |
| `Sources/Core/MainCanvasViewHolder.swift` | `0x107f1a4a0` | **RECONSTRUCTED** | Map canvas, pan/pinch gestures, vector route layer | Tile image background rendering |
| `Sources/Location/WZWazeLocationServiceBridge.swift` | `0x107f19690` | **RECONSTRUCTED** | CoreLocation GPS feed & speed updates | Dead-reckoning extrapolation |
| `Sources/Models/LocationModel.swift` | `WSVLocationSpeed` | **RECONSTRUCTED** | Speed and heading data models | Raw GPS covariance matrices |
| `Sources/Models/NavigationState.swift` | `NavigationStateBridge` | **RECONSTRUCTED** | Unidirectional guidance state | Lane configuration sub-states |
| `Sources/Models/RouteModels.swift` | `RouteUpdate` | **RECONSTRUCTED** | Route and step definitions | Toll pricing breakdown |
| `Sources/Models/SearchModels.swift` | `SearchResultsBridge` | **RECONSTRUCTED** | Destination and category models | Operating hours & reviews |
| `Sources/Navigation/ManeuverType.swift` | `Maneuver` | **RECONSTRUCTED** | 12 maneuver types & SF Symbols | Roundabout exit specific icons |
| `Sources/Navigation/NavigationGuidanceReducerBridge.swift` | `0x107f1ab08` | **RECONSTRUCTED** | Distance to turn & approaching triggers | Voice prompt audio dispatch |
| `Sources/Networking/RoutingServiceProtocol.swift` | Routing contract | **RECONSTRUCTED** | Protocol abstraction for routing | gRPC protobuf definitions |
| `Sources/Networking/LocalSimulatedRoutingService.swift` | None | **MOCKED** | Curved sine-wave test fixture | Road network graph routing |
| `Sources/Persistence/KeychainStorageService.swift` | `-34018` fix | **RECONSTRUCTED** | Bundle-agnostic dynamic Keychain | Multi-device cloud sync |
| `Sources/Persistence/UserPreferencesService.swift` | `UserPreferences` | **RECONSTRUCTED** | UserDefaults toll/speed settings | Cloud profile synchronization |
| `Sources/Routing/AlternateRoutesStateMachineBridge.swift` | `0x107f17048` | **RECONSTRUCTED** | Alternate routes selection state machine | Live traffic delay comparison |
| `Sources/Search/SearchEngine.swift` | `WazeSearchCoordinator` | **RECONSTRUCTED** | Category indexing, spatial distance sorting | Remote Google Places API |
| `Sources/CarPlay/WZCarPlayMapController.swift` | `0x107f17e30` | **STUB** | CarPlay connection flag | CPMapTemplate & map interface |
| `Sources/UI/Common/WazeTheme.swift` | Theme specs | **RECONSTRUCTED** | Authentic Waze colors, fonts, radii | Dark mode map styling |
| `Sources/UI/Common/WazeButton.swift` | `waze_WazeButtonPack` | **RECONSTRUCTED** | Pill buttons with haptics | Animated activity spinner |
| `Sources/UI/Welcome/WelcomeViewController.swift` | `waze_WazeOnboarding` | **RECONSTRUCTED** | Authentic welcome & guest login UI | Real phone SMS auth flow |
| `Sources/UI/MainCanvas/MainCanvasContainerViewController.swift` | `waze_WazeMainScreen` | **RECONSTRUCTED** | Map chrome, HUD, controls, route flow | Dynamic hazard reporting sheet |
| `Sources/UI/Overlays/NavigationBannerView.swift` | HUD specs | **RECONSTRUCTED** | Green turn banner & icons | Lane guidance strip |
| `Sources/UI/Overlays/SpeedometerView.swift` | `waze_WazeMapOverlay` | **RECONSTRUCTED** | Speedometer gauge & speed limit warning | Audio warning chime |
| `Sources/UI/RoutePreview/RoutePreviewView.swift` | `waze_WazeTripOverview` | **RECONSTRUCTED** | Route preview card with ETA & Go button | Alternate route selector chips |
| `Sources/UI/Search/SearchDrawerViewController.swift` | `waze_WazeSearch` | **RECONSTRUCTED** | Category segmented search & distance sorting | Autocomplete history clear |

---

## 5. Task D — Functional Equivalence Gap Analysis

### D1. Map Rendering
- **Original:** Evaluates a proprietary binary vector tile stream (`MercatorTile`), builds geometry vertex buffers dynamically, renders multi-layer roads, landuse, water polygons, and labels with collision detection.
- **Reconstructed:** Implements Web Mercator projection, bounding box calculations, and tile coordinate indexing in C++. Draws the active route polyline via a vector `CAShapeLayer` overlay with cyan stroke `#33CCFF`. Interactive pan translations and pinch zooms are mathematically anchored. Vector tile parsing remains unfeasible without proprietary protobuf schemas or external tile providers.

### D2. Destination Search
- **Original:** Connects to Google Places and Waze geocoding servers with live business listings, gas prices, and crowdsourced addresses.
- **Reconstructed:** Multi-category spatial search engine (Gas, Food, Coffee, Parking, Saved) over an offline database. Computes Haversine distances from the driver's live GPS coordinate and sorts results nearest-first.

### D3. Road Network Routing
- **Original:** Massive server-side cluster computing dynamic Dijkstra/A* routing across global traffic graphs with live segment speeds, closures, and turns.
- **Reconstructed:** In offline test mode, routes are generated using geometric waypoints. In Phase 3.1, the C++ `RoutingEngine` dynamically evaluates segment bearings along the polyline and automatically computes realistic turn maneuvers (`Depart`, `TurnRight`, `TurnLeft`, `SlightRight`, `UTurn`, `Arrive`) and step distances.

### D4. Navigation Guidance & State
- **Original:** Centimeter-level Kalman road snapping (`WSVLocationSpeed`), heading smoothing, lane-level guidance, speed trap alerts, and automatic rerouting on deviation.
- **Reconstructed:** Clean-room C++ routing engine with polyline closest-point projection, 35m off-route threshold detection, and 25m destination arrival. Coupled to Swift unidirectional guidance reducer.

### D5. Backend & Authentication
- **Original:** Google OAuth2, Apple App Attest, and proprietary gRPC services using pinned root certificates (`gRPCCertificates.bundle`).
- **Reconstructed:** Cleanly isolated behind `RoutingServiceProtocol` and local guest session management. Production services remain **EXTERNAL RECOVERY DEPENDENCIES (BLOCKED)**.

---

## 6. Task E — Modules Implemented in Phase 3.1

To address the findings of the gap audit, the following evidence-grounded modules were implemented:

### 1. Crowdsourced Hazard & Incident Reporting (Subsystem SUB-10)
- **Files Created:**
  - [`Sources/Models/HazardModels.swift`](file:///home/ysiduc/.gemini/antigravity-ide/scratch/waze/WazeRecovery/Sources/Models/HazardModels.swift)
  - [`Sources/Navigation/AlertReportingService.swift`](file:///home/ysiduc/.gemini/antigravity-ide/scratch/waze/WazeRecovery/Sources/Navigation/AlertReportingService.swift)
  - [`Tests/HazardAlertTests.swift`](file:///home/ysiduc/.gemini/antigravity-ide/scratch/waze/WazeRecovery/Tests/HazardAlertTests.swift)
- **Capabilities:**
  - Models: `WZHazardType` (`police`, `accident`, `trafficJam`, `hazardOnRoad`, `speedCamera`, `roadClosure`), `WZTrafficSeverity`.
  - Spatial radius queries: `alerts(near:radiusMeters:)`.
  - Proximity warning detection: triggers driver alerts within $500\text{ m}$ forward cone.
  - User reporting API: `reportHazard(type:coordinate:title:subtitle:)`.

### 2. Spherical Mercator Tile Math & Bounding Boxes (Subsystem SUB-04)
- **Files Updated:**
  - [`NativeEngine/Geometry/Coordinate.hpp`](file:///home/ysiduc/.gemini/antigravity-ide/scratch/waze/WazeRecovery/NativeEngine/Geometry/Coordinate.hpp) & [`.cpp`](file:///home/ysiduc/.gemini/antigravity-ide/scratch/waze/WazeRecovery/NativeEngine/Geometry/Coordinate.cpp)
  - [`NativeEngine/Interop/NativeEngineBridge.h`](file:///home/ysiduc/.gemini/antigravity-ide/scratch/waze/WazeRecovery/NativeEngine/Interop/NativeEngineBridge.h) & [`.mm`](file:///home/ysiduc/.gemini/antigravity-ide/scratch/waze/WazeRecovery/NativeEngine/Interop/NativeEngineBridge.mm)
- **Capabilities:**
  - `BoundingBox`: intersection, containment, and expansion math.
  - `TileCoordinate`: WGS84 coordinate $\leftrightarrow$ Mercator tile `(x, y, zoom)` transformations conforming to Waze's `MercatorTile`.

### 3. Dynamic Maneuver Step Generation (Subsystem SUB-08)
- **Files Updated:**
  - [`NativeEngine/Routing/RoutingEngine.hpp`](file:///home/ysiduc/.gemini/antigravity-ide/scratch/waze/WazeRecovery/NativeEngine/Routing/RoutingEngine.hpp) & [`.cpp`](file:///home/ysiduc/.gemini/antigravity-ide/scratch/waze/WazeRecovery/NativeEngine/Routing/RoutingEngine.cpp)
- **Capabilities:**
  - `generateStepsFromPolyline`: Evaluates bearing delta $\Delta\theta$ between consecutive line segments. Generates `Depart`, `TurnLeft`, `TurnRight`, `SlightLeft`, `SlightRight`, `SharpLeft`, `SharpRight`, `UTurn`, and `Arrive` steps automatically.

### 4. Multi-Category Search & Spatial Distance Sorting (Subsystem SUB-06)
- **Files Updated:**
  - [`Sources/Search/SearchEngine.swift`](file:///home/ysiduc/.gemini/antigravity-ide/scratch/waze/WazeRecovery/Sources/Search/SearchEngine.swift)
  - [`Sources/UI/Search/SearchDrawerViewController.swift`](file:///home/ysiduc/.gemini/antigravity-ide/scratch/waze/WazeRecovery/Sources/UI/Search/SearchDrawerViewController.swift)
- **Capabilities:**
  - Category segmentation (All, Gas, Food, Coffee, Parking, Saved).
  - Haversine distance ranking sorting results nearest-first from user's live GPS fix.

### 5. Interactive Map Canvas Gestures & Route Layer (Subsystem SUB-03)
- **Files Updated:**
  - [`Sources/Core/MainCanvasViewHolder.swift`](file:///home/ysiduc/.gemini/antigravity-ide/scratch/waze/WazeRecovery/Sources/Core/MainCanvasViewHolder.swift)
- **Capabilities:**
  - Pan gesture converts pixel translation into Mercator coordinate delta at active zoom.
  - Pinch gesture scales zoom level smoothly with clamping $[1.0, 20.0]$.
  - Vector route overlay draws active polyline dynamically on the canvas.

---

## 7. Verification & Test Execution

### 7.1 Local Native Unit Tests (100% Passed)
```bash
$ g++ -std=c++17 -Wall -Wextra \
    WazeRecovery/Tests/GeometryTests.cpp \
    WazeRecovery/NativeEngine/Geometry/Coordinate.cpp \
    WazeRecovery/NativeEngine/Geometry/Polyline.cpp -o test_geo && ./test_geo
--- Running Geometry & Polyline C++ Unit Tests ---
[PASS] Coordinate Validation
[PASS] Haversine Distance: 13429.6m
[PASS] Bearing Calculation
[PASS] Polyline Encode/Decode Roundtrip: _p~iF~ps|U_ulLnnqC_mqNvxq`@
[PASS] Polyline Closest Point
[PASS] Bounding Box Intersection & Containment
[PASS] Spherical Mercator Tile Conversion (Z15: X=5241, Y=12665)
All 7 Geometry unit tests PASSED successfully.

$ g++ -std=c++17 -Wall -Wextra \
    WazeRecovery/Tests/RoutingEngineTests.cpp \
    WazeRecovery/NativeEngine/Geometry/Coordinate.cpp \
    WazeRecovery/NativeEngine/Geometry/Polyline.cpp \
    WazeRecovery/NativeEngine/Routing/RoutingEngine.cpp -o test_routing && ./test_routing
--- Running Routing Engine C++ Unit Tests ---
[PASS] Routing Engine Lifecycle, Off-Route Detection & Arrival
[PASS] Dynamic Turn Maneuver Generation (Depart -> TurnRight -> Arrive)
All Routing Engine unit tests PASSED successfully.
```

---

## 8. Physical Device Status Matrix

| Feature | Physical Device Status | Evidence / Notes |
|:---|:---:|:---|
| Application Launch & UI | **READY FOR SIGNING** | Freshly built standalone unsigned binary. |
| Guest Session Initialization | **READY FOR SIGNING** | Dynamic Keychain avoids `-34018` access-group crash. |
| Map Pan & Zoom | **READY FOR SIGNING** | Mathematically responsive Mercator coordinate transform. |
| Search & Category Filtering | **READY FOR SIGNING** | Offline category index with spatial distance sorting. |
| Route Preview & Go | **READY FOR SIGNING** | Full UI drawer flow with dynamic maneuver banner. |
| Dynamic Turn-by-Turn Guidance | **READY FOR SIGNING** | Polyline snapping, 35m off-route, 25m arrival detection. |
| Hazard Alerts Ahead | **READY FOR SIGNING** | Proximity warning alerts within 500m forward cone. |
| Production Google Sign-In | **BLOCKED** | OAuth bundle ID & App Check token validation. |
| Production Waze Traffic Graph | **BLOCKED** | Proprietary gRPC backend credentials lost. |

---

## 9. Next Reconstruction Priority

### Highest-Priority Subsystem: Offline Road Vector Tile Decoupling
To advance the visual and functional fidelity of the map canvas beyond route line overlays, the single highest-priority remaining subsystem is the **Vector Map Tile Engine** (decoding OpenStreetMap or vector tile geometries into `CanvasRenderer` vertex buffers) to provide background road geography without depending on unreachable proprietary Google Waze server clusters.
