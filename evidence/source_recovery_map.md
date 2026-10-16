# Source Recovery & Architectural Mapping Ledger

This ledger links original binary artifacts, virtual addresses, Objective-C selectors, and Swift reflection data from `Waze` (ARM64 executable, SHA-256: `0c40c247...`) to the reconstructed source code modules in `WazeRecovery/`.

---

## 1. Subsystem Mapping & Provenance Classifications

| Original Binary Symbol / Address | Original Architecture Subsystem | Reconstructed Source File | Classification | Evidentiary Basis & Functionality |
|:---|:---|:---|:---:|:---|
| **`0x1001fb7f8` (`entry`)** | Mach-O Entry & Lifecycle | `App/WazeApp.swift`<br>`App/AppDelegate.swift` | **RECONSTRUCTED** | Mach-O entry invokes `UIApplicationMain(@"WazeApp")`. Reconstructed as `@main struct WazeApp` and `AppDelegate` managing root navigation window. |
| **`0x107f1a4a0` (`MainCanvasViewHolder`)** | Map Canvas View Holder | `Sources/Core/MainCanvasViewHolder.swift` | **RECONSTRUCTED** | `__objc_classlist` entry and assertion `MainCanvasViewHolder.mm`. Reconstructed to manage Metal canvas, camera orientation, and gesture events. |
| **`-[MainCanvasViewHolder createMetalViewController]`** | Metal GPU Instantiation | `Sources/Core/MainCanvasViewHolder.swift`<br>`NativeEngine/Rendering/CanvasRenderer.metal` | **RECONSTRUCTED** | Reconstructs Metal device context, pipeline state, and shaders (`BlurVertexShader`, `SimpleTextureVertexShader`, `TileLineVertexShader`). |
| **`0x107f17048` (`AlternateRoutesStateMachineBridge`)** | Alternate Routes Engine | `Sources/Routing/AlternateRoutesStateMachineBridge.swift` | **RECONSTRUCTED** | Conforms to `AlternateRoutesStateMachineBridgeProtocol`. Implements state machine handling `CurrentRouteUpdate`, `RerouteSuggestion`, and `NextUpdateSchedule`. |
| **`0x10001a718` (`ParseToRoutingUpdateResponse:`)** | Route Parsing Method | `Sources/Routing/AlternateRoutesStateMachineBridge.swift` | **RECONSTRUCTED** | Disassembled Ghidra logic inspecting three routing update branches and dispatching state transitions. |
| **`0x107f1ab08` (`NavigationGuidanceReducerBridge`)** | Navigation Guidance Reducer | `Sources/Navigation/NavigationGuidanceReducerBridge.swift` | **RECONSTRUCTED** | Redux-style unidirectional state reducer updating `distanceToTurn`, `isApproachingTurn`, and maneuver instructions. |
| **`0x100102264` (`reduceGuidanceEvent:`)** | Guidance Event Reducer | `Sources/Navigation/NavigationGuidanceReducerBridge.swift` | **RECONSTRUCTED** | Disassembled Ghidra logic mapping incoming turn events to immutable `NavigationState` snapshots. |
| **`0x107f19690` (`WZWazeLocationServiceBridge`)** | Location Telemetry Bridge | `Sources/Location/WZWazeLocationServiceBridge.swift` | **RECONSTRUCTED** | Bridges Apple `CoreLocation` framework and constructs `WSVLocationSpeed` models with speed, accuracy, and course. |
| **`0x107f4edd8` (`WSVLocationSpeed`)** | Location Telemetry Model | `Sources/Models/LocationModel.swift` | **RECONSTRUCTED** | Disassembled data model storing latitude, longitude, altitude, speed, course, and timestamp. |
| **`0x107f17e30` (`WZCarPlayMapController`)** | Apple CarPlay Map Scene | `Sources/CarPlay/WZCarPlayMapController.swift` | **RECONSTRUCTED** | CarPlay template integration managing automotive HUD viewports and turn instructions. |
| **`0x107f16260` (`SRLRegistry`)** | Service Registry Locator | `Sources/Core/ServiceRegistry.swift` | **RECONSTRUCTED** | Google SRL framework implementation providing scoped singleton dependency injection. |
| **C++ Geometry & Math Utilities** | C++ Vector Math / Geodesy | `NativeEngine/Geometry/Coordinate.hpp`<br>`NativeEngine/Geometry/Polyline.hpp` | **RECONSTRUCTED** | Exact WGS84 great-circle distance (Haversine/Vincenty), bearing, polyline decoders, and cross-track projection. |
| **C++ Routing State Machine** | Core Routing Engine | `NativeEngine/Routing/RoutingEngine.hpp` | **RECONSTRUCTED** | C++ routing graph, maneuver step models, route deviation detection, and ETA computation. |
| **`waze_WazeOnboardingImplementation`** | Welcome & Onboarding UI | `Sources/UI/Welcome/WelcomeViewController.swift` | **RECONSTRUCTED** | Authentic Waze Welcome UI with "Start without login" (Guest Mode), styling, and onboarding stack. |
| **`waze_WazeSearchImplementation`** | Destination Search | `Sources/Search/SearchEngine.swift`<br>`Sources/UI/Search/SearchDrawerViewController.swift` | **RECONSTRUCTED** | Destination model, autocomplete index, recent search caching, and authentic search drawer. |
| **`waze_WazeTripOverviewImplementation`** | Route Preview & Overview | `Sources/UI/RoutePreview/RoutePreviewView.swift` | **RECONSTRUCTED** | Route alternatives cards, time/distance ETA badges, and "Go" button. |
| **`waze_WazeMapOverlay`** | Speedometer & Overlays | `Sources/UI/Overlays/SpeedometerView.swift`<br>`Sources/UI/Overlays/NavigationBannerView.swift` | **RECONSTRUCTED** | Speed limit warnings, current speed gauge, and turn guidance banners. |
| **Google Cloud OAuth / App Attest** | Server Identity Verification | `Sources/Networking/OAuthServiceProtocol.swift` | **ISOLATED (MOCK/TEST)** | Third-party signing cannot use Google production credentials. Clean protocol and local guest session provider implemented. |
| **Waze Realtime Distribution Shard** | Cloud Routing Socket Protocol | `Sources/Networking/RoutingServiceProtocol.swift`<br>`Sources/Networking/LocalSimulatedRoutingService.swift` | **APPROXIMATED (TEST FIXTURE)** | Server-side proprietary protocol (`rt.waze.com/rtserver/distrib`) isolated behind protocol; deterministic simulation fixture provided for tests. |

---

## 2. Evidence Classification Definitions

- **RECOVERED:** Exact file or asset copied directly from the original bundle (e.g. vector assets, strings, layout constants).
- **RECONSTRUCTED:** Newly written source code that replicates the verified class interface, method signatures, properties, state machines, and mathematical behavior discovered via REA and Ghidra decompilation.
- **APPROXIMATED:** Modules where external server-side interactions or proprietary cloud services are replaced with deterministic local simulation models or clean protocols.
- **NOT RECOVERABLE:** Server-side proprietary binaries, Google Cloud private keys, and Apple-restricted commercial signing certificates.
- **UNKNOWN:** Proprietary obfuscated C++ algorithms whose function bodies were completely stripped without assertion text.
