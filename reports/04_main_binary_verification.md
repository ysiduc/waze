# 04. Waze Main Executable Analysis Verification

**Target Executable:** `Payload/Waze.app/Waze` (Main Application Binary)  
**Host Environment:** Arch Linux x86_64, Antigravity IDE  
**Analysis Engines:** REA (`rea-agents@6.5.0`), Ghidra 12.1.2-2, OpenJDK 27, Python 3.14.8  
**Verification Status:** PASS (All verification criteria met)  

---

## 1. Executive Summary Table

| Check | Result | Evidence |
|---|---|---|
| **Main executable imported** | **PASS** | Imported into Ghidra project `/tmp/ghidra_proj/WazeTest` in 39.40s. Recognized as Mach-O 64-bit ARM64 (`AARCH64:LE:64:AppleSilicon:swift`). |
| **Functions identified** | **PASS** | Ghidra identified 5,681 initial procedure symbols; total symbol table count is 614,321 across 141.4 MB image. Target functions created and mapped at exact virtual addresses. |
| **Pseudocode generated** | **PASS** | Decompiled 20 representative functions with 100% success (0 failures). Disassembly and structured C pseudocode verified for lifecycle, navigation, map canvas, and location services. |
| **Cross-references found** | **PASS** | Verified data and code cross-references (XREFs) to entry points, strings, and method implementations (e.g. `entry` from `0x1087c4dc7`, `target_10001a718` from `0x1087c0dcc`). |
| **Architecture findings supported** | **PASS** | Concrete technical evidence verified for `MainCanvasViewHolder`, `NavigationGuidanceReducerBridge`, and `AlternateRoutesStateMachineBridge` via runtime metadata, C-string assertions, and decompiled logic. |

---

## 2. Main Binary Verification Facts

- **Path:** `Payload/Waze.app/Waze`
- **File Size:** `141,425,424` bytes (~141.42 MB)
- **SHA-256 Digest:** `0c40c247228439e2b75baca181569c75c144918561a8177e9399b183b5709d80`
- **Mach-O Format:** 64-bit Mach-O executable (`MH_EXECUTE`)
- **CPU Architecture:** `CPU_TYPE_ARM64` (`0x0100000c`), Subtype `0`
- **Encryption:** `LC_ENCRYPTION_INFO_64` has `cryptid = 0` (unencrypted / decrypted)
- **Load Commands:** 117 load commands totaling 13,088 bytes
- **Linked Dynamic Libraries:** 95 frameworks and dylibs (including `SpotifyiOS.framework`, `MapKit`, `CarPlay`, `CoreLocation`, `Metal`, `SwiftUI`, `Combine`, `AVFoundation`)
- **Metadata Inventory:**
  - 25 Objective-C metadata sections (6,994 classes in `__objc_classname`, 5,677 classes in `__objc_classlist`, 1.15 MB in `__objc_methname`, 487 KB in `__objc_methlist`).
  - 13 Swift metadata sections (19,404 property/field strings in `__swift5_reflstr`, type records in `__swift5_types`, protocol conformances).
  - 103,458 C-string constants in `__cstring` (3.62 MB).

---

## 3. Ghidra Headless Analyzer Benchmarks

1. **Path Restriction Workaround:**
   Ghidra's internal path validation (`NamingUtilities.checkName`) explicitly rejects project paths where any directory element starts with a dot `.` (such as `.gemini`). Storing the project in `/tmp/ghidra_proj/WazeTest` completely resolved this limitation without modifying the binary.

2. **Performance Metrics:**
   - **Import Duration:** 39.400 seconds.
   - **Language / Loader:** Apple Silicon ARM64 Swift (`AARCH64:LE:64:AppleSilicon:swift`).
   - **Total Symbol Count:** 614,321 symbols mapped in Ghidra's symbol table.
   - **Identified Initial Procedures:** 5,681 functions.
   - **Decompilation Performance Batch:**
     - Tested Functions: 20
     - Succeeded: 20 (100%)
     - Failed / Timed Out: 0 (0%)
     - Decompilation time per function: 4 ms to 212 ms (average <15 ms).

---

## 4. Representative Component Analysis

### Component 1: Application Lifecycle Entry Point
- **Address:** `0x1001fb7f8` (`entry`)
- **Associated Module:** Application Startup / Main
- **Behavioral Analysis:**
  Sets up the top-level Objective-C autorelease pool, loads the application configuration class reference, and calls `_UIApplicationMain`. The constant string passed as both principal class and delegate was resolved to `"WazeApp"`.
- **Confidence:** VERIFIED (High)
- **Cross-References:** `from Entry Point (EXTERNAL)`, `from 0x1087c4dc7 (DATA)`.

### Component 2: Route Guidance & Update Handling
- **Address:** `0x10001a718`
- **Associated Class:** `AlternateRoutesStateMachineBridge`
- **Behavioral Analysis:**
  Implements `ParseToRoutingUpdateResponse:`. Contains logging assertions referencing `AlternateRoutesStateMachineBridge.mm` and validates three distinct response structures received from routing services: `CurrentRouteUpdate`, `RerouteSuggestion`, and `NextUpdateSchedule`.
- **Confidence:** VERIFIED (High)
- **Cross-References:** `from 0x1087c0dcc (DATA)`.

### Component 3: Map Canvas UI View Holder
- **Address:** `0x1000d4b08`
- **Associated Class:** `MainCanvasViewHolder`
- **Behavioral Analysis:**
  Implements the primary map canvas container initialization (`init`). Dispatches initialization to `super`, binds canvas viewport delegates, and sets up Metal view controller observers.
- **Confidence:** VERIFIED (High)
- **Cross-References:** `from 0x1087c2767 (DATA)`.

### Component 4: Location Service & Coordinate Dispatch
- **Address:** `0x1000a1d28`
- **Associated Class:** `WZWazeLocationServiceBridge`
- **Behavioral Analysis:**
  Queries location telemetry from core services, extracts latitude/longitude coordinates as double-precision floating point numbers, and instantiates a `WSVLocationSpeed` bridge object for UI consumption.
- **Confidence:** VERIFIED (High)
- **Cross-References:** `from 0x1087c1f7b (DATA)`.

---

## 5. Architectural Findings & Verified Roles

1. **`MainCanvasViewHolder` (Address: `0x107f1a4a0`):**
   - Actual Objective-C class registered in `__objc_classlist` with 24 methods.
   - Source evidence: `third_party/waze/client/waze/src/iphone/Source/Map/PrimaryMapViewHolder/MainCanvasViewHolder.mm`.
   - Role: Core container managing the Apple Metal graphics canvas (`createMetalViewController`) and map viewport changes.

2. **`NavigationGuidanceReducerBridge` (Address: `0x107f1ab08`):**
   - Actual Objective-C class conforming to Swift protocol `_TtP95third_party_waze_client_ios_modules_WazeNavigationGuidance_WazeNavigationGuidanceImplementation39NavigationGuidanceReducerBridgeProtocol_`.
   - Role: State reducer bridge connecting modern Swift UI guidance with the lower-level navigation guidance state machine.

3. **`AlternateRoutesStateMachineBridge` (Address: `0x107f17048`):**
   - Actual Objective-C class with protocol `AlternateRoutesStateMachineBridgeProtocol`.
   - Source evidence: `third_party/waze/client/waze/src/iphone/Source/AlternativeRoutes/AlternateRoutesStateMachineBridge.mm`.
   - Role: State machine coordinator handling alternative route suggestions, rerouting triggers, and schedule intervals.
