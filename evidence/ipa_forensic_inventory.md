# IPA Forensic Inventory & Provenance Ledger

**Target Archive:** `/home/ysiduc/Downloads/waze.ipa`  
**Archive Dimensions:** `114,712,520 bytes` (~114.71 MB / 109.40 MiB)  
**SHA-256 Checksum:** `78c54a3db510c7d2142baeb13dd773c2f7774a3e4d99fb9a4cc966941086a158`  
**Total Entries:** `2,435 archive members`  
**Application Version:** `5.22.0 (Build 1)`  
**Minimum iOS Version:** `16.0`  

---

## 1. Archive Structure & High-Level Breakdown

| Category | Count | Typical Location | Provenance / Recovery Strategy |
|:---|:---:|:---|:---|
| **Main Executable** | 1 | `Payload/Waze.app/Waze` | 141.42 MB unencrypted ARM64 Mach-O (`cryptid=0`). Disassembled and analyzed via REA/Ghidra. Architecture and classes reconstructed in native Swift/C++. |
| **Embedded Frameworks** | 1 | `Frameworks/SpotifyiOS.framework` | Proprietary third-party audio integration. Replaced with clean protocol interface. |
| **App Extensions (`.appex`)** | 2 | `PlugIns/NotificationExtension.appex`<br>`PlugIns/WazeShareExtension.appex` | Sandboxed extensions. Notification extension analyzed for push telemetry; isolated behind protocols. |
| **Module Resource Bundles** | 29 | `Payload/Waze.app/*.bundle` | Internal Google/Waze modular UI and feature packages. Reveal original monorepo module boundaries. |
| **GPU Metal Shaders** | 1 | `Payload/Waze.app/default.metallib` | 67,042-byte Metal library (`BlurVertexShader`, `SimpleTextureVertexShader`, etc.). Reconstructed as Metal shader source files (`.metal`). |
| **Compiled NIBs** | 58 | `Payload/Waze.app/*.nib` | Legacy interface definitions. Reconstructed as native programmatic UIKit and SwiftUI view layouts. |
| **Lottie JSON Animations** | 75 | `Payload/Waze.app/*.json` | UI vectors and state animations (e.g. `alt_routes_fte_animation_*.json`). Can be preserved or referenced for authentic UI reconstruction. |
| **Raster Assets (PNG/JPG)** | 1,779 | `Payload/Waze.app/*.png` | UI icons, turn symbols, lane guidance indicators, hazard alert icons (`AlertSeperator`, `Arrow`, `AddressBar`, `ac_search_icon`). |
| **Localization Tables** | 56 | `Payload/Waze.app/*.lproj` | Multi-language strings (`af.lproj` through `zh-Hant.lproj`). |
| **Security Certificates** | 1 | `gRPCCertificates.bundle/roots.pem` | Standard TLS trust roots for external gRPC endpoints. |

---

## 2. Monorepo Feature Module Mapping

The 29 internal `.bundle` packages establish the modular architecture used by the original engineering team:

| Original Resource Bundle | Corresponding Architecture Subsystem | Reconstructed Target Module |
|:---|:---|:---|
| `waze_WazeSplashImplementation.bundle` | Application Startup & Splash | `WazeRecovery/App/Lifecycle/` |
| `waze_WazeOnboardingImplementation.bundle` | Welcome, Login & Guest Session Flow | `WazeRecovery/Sources/UI/Welcome/` |
| `waze_WazeMainScreenImplementation.bundle` | Primary Map Canvas & Window Orchestration | `WazeRecovery/Sources/UI/MainCanvas/` |
| `waze_WazeMapOverlay.bundle` | Speedometer, Hazard Pins, User Marker | `WazeRecovery/Sources/UI/Overlays/` |
| `waze_WazeSearchImplementation.bundle` | Destination Search, Autocomplete | `WazeRecovery/Sources/Search/` |
| `waze_WazeSearchResultsUI.bundle` | Search Results List & Destination Cards | `WazeRecovery/Sources/UI/Search/` |
| `waze_WazeAlternateRoutesImplementation.bundle` | Alternative Routes State Machine | `WazeRecovery/Sources/Routing/` |
| `waze_WazeTripOverviewImplementation.bundle` | ETA Bar, Route Summary | `WazeRecovery/Sources/UI/RoutePreview/` |
| `waze_WazeAlertReportUIImplementation.bundle` | Hazard Reporting Flow | `WazeRecovery/Sources/UI/Alerts/` |
| `waze_WazeCarPlayImplementation.bundle` | Apple CarPlay Template Integration | `WazeRecovery/Sources/CarPlay/` |
| `waze_WazeCommonUI.bundle` & `waze_WazeUIKit.bundle` | Shared Theme, Typography, Buttons | `WazeRecovery/Sources/UI/Common/` |

---

## 3. Original Binary Metadata & Entitlement Inventory

```
Mach-O Type:               MH_EXECUTE (Mach-O 64-bit executable)
Target CPU Architecture:   CPU_TYPE_ARM64 (Subtype 0)
Binary Size:               141,425,424 bytes
Mach-O UUID:               4556fa71-0a76-3117-b160-07139913ce8d
Encryption Status:         LC_ENCRYPTION_INFO_64 cryptid = 0 (Unencrypted)
Original Bundle ID:        com.waze.iphone
Original Team ID:          4Z5238C58P (AppIdentifierPrefix: UM5AE5Q8GC)
Deployment Target:         iOS 16.0 (MinimumOSVersion)
Main Entry Point:          0x1001fb7f8 (invokes UIApplicationMain(@"WazeApp"))
```

---

## 4. Reconstructability & Provenance Assessment

| Component | Status | Recovery / Reconstruction Method |
|:---|:---:|:---|
| **Application Lifecycle & Entry** | **RECONSTRUCTED** | Implemented in `WazeApp.swift` / `AppDelegate.swift` replicating `UIApplicationMain` and `SceneDelegate` hierarchy. |
| **Geometry & Spatial Math** | **RECONSTRUCTED** | Implemented in C++ (`NativeEngine/Geometry/`) providing exact WGS84 geodesic distance, polyline decoding, and bearing calculation. |
| **Routing State Machine** | **RECONSTRUCTED** | Implemented in `AlternateRoutesStateMachineBridge.swift` and C++ `RoutingEngine.hpp` modeling `CurrentRouteUpdate`, `RerouteSuggestion`, and polling cadence. |
| **Navigation Guidance Reducer** | **RECONSTRUCTED** | Implemented in `NavigationGuidanceReducerBridge.swift` modeling unidirectional Redux state transitions (`distanceToTurn`, maneuvers, speedometer). |
| **Location Telemetry** | **RECONSTRUCTED** | Implemented in `WZWazeLocationServiceBridge.swift` wrapping `CoreLocation` and generating `WSVLocationSpeed` models. |
| **Map Rendering Pipeline** | **RECONSTRUCTED** | Implemented in `MainCanvasViewHolder.swift` and Metal shaders (`CanvasRenderer.metal`) replicating viewport projection and tile line styles. |
| **Authentic User Interface** | **RECONSTRUCTED** | Authentic programmatic UI replicating Waze color palette, typography, welcome screen, search drawer, route preview, and turn banners. |
| **Proprietary Google Backends** | **ISOLATED (MOCK/TEST)** | Waze production routing shard and OAuth endpoints isolated behind `RoutingServiceProtocol` with deterministic test fixtures. |
