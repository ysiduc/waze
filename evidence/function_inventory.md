# Function Inventory: Target Subsystems & Key Procedures

This document records representative functions identified and verified across the core subsystems of `Waze` (ARM64 executable). All virtual addresses correspond to the standard Mach-O load address base `0x100000000`.

---

## 1. Application Lifecycle & Startup

### `entry`
- **Virtual Address:** `0x1001fb7f8`
- **Associated Module:** Startup / Application Initialization
- **Behavioral Summary:** Sets up the root Objective-C autorelease pool, loads the application configuration class reference, and invokes `_UIApplicationMain`. Resolves the principal class and application delegate name to `@"WazeApp"`.
- **Type of Evidence:** Ghidra Headless Decompilation & Symbol Table entry (`entry`).
- **Confidence Level:** VERIFIED (High)
- **Cross-Reference Summary:** Referenced from External Mach-O Entry Point and `0x1087c4dc7` (DATA).

### `SRLMemoizingScope::init`
- **Virtual Address:** `0x100004000` (in `NotificationExtension` / Shared Core)
- **Associated Module:** Service Registry Locator (Dependency Injection)
- **Behavioral Summary:** Initializes the service registry memory cache structure, allocating a memoized instance map and binding synchronization barriers.
- **Type of Evidence:** Ghidra Disassembly & Decompiler Listing.
- **Confidence Level:** VERIFIED (High)
- **Cross-Reference Summary:** Target of class selector `init` in `SRLMemoizingScope`.

---

## 2. Route Guidance & State Machines

### `AlternateRoutesStateMachineBridge::ParseToRoutingUpdateResponse:`
- **Virtual Address:** `0x10001a718`
- **Associated Module:** `AlternateRoutesStateMachineBridge` (`third_party/waze/.../AlternativeRoutes`)
- **Behavioral Summary:** Parses routing update responses from server telemetry. Inspects three response structures: `CurrentRouteUpdate`, `RerouteSuggestion`, and `NextUpdateSchedule`. Triggers state machine transitions when alternative routes are recommended.
- **Type of Evidence:** Ghidra Decompiler Listing and embedded assertion strings referencing `AlternateRoutesStateMachineBridge.mm`.
- **Confidence Level:** VERIFIED (High)
- **Cross-Reference Summary:** Referenced from `__objc_methlist` and data address `0x1087c0dcc`.

### `AlternateRoutesStateMachineBridge::method_1ad1c`
- **Virtual Address:** `0x10001ad1c`
- **Associated Module:** `AlternateRoutesStateMachineBridge`
- **Behavioral Summary:** Sub-handler for parsing reroute suggestions, converting raw coordinate streams into turn points and alternate route geometry buffers.
- **Type of Evidence:** Direct call graph descendant from `0x10001a718`.
- **Confidence Level:** VERIFIED (High)
- **Cross-Reference Summary:** Called conditionally from `0x10001a718` when reroute suggestion payload is present.

---

## 3. Map Canvas & Graphics Rendering

### `MainCanvasViewHolder::init`
- **Virtual Address:** `0x1000d4b08`
- **Associated Module:** `MainCanvasViewHolder` (`third_party/waze/.../PrimaryMapViewHolder`)
- **Behavioral Summary:** Initializes the primary map canvas view holder. Calls `super init`, instantiates canvas viewport observers, and prepares Metal canvas delegate hooks.
- **Type of Evidence:** Ghidra Decompiler Listing and Objective-C method dispatch table.
- **Confidence Level:** VERIFIED (High)
- **Cross-Reference Summary:** Referenced from `__objc_methlist` entry for `MainCanvasViewHolder` and `0x1087c2767` (DATA).

### `MainCanvasViewHolder::createMetalViewController`
- **Virtual Address:** Mapped via selector `createMetalViewController`
- **Associated Module:** `MainCanvasViewHolder`
- **Behavioral Summary:** Instantiates and configures a `MetalViewController` backed by Apple Metal device context and shader pipelines from `default.metallib`.
- **Type of Evidence:** Objective-C selector references, C-string assertion `-[MainCanvasViewHolder createMetalViewController]`.
- **Confidence Level:** VERIFIED (High)
- **Cross-Reference Summary:** Referenced by `MainCanvasViewHolder` canvas lifecycle setup.

### `MainCanvasViewHolder::createCanvasWithPlatformService:`
- **Virtual Address:** `0x1000d4c6c`
- **Associated Module:** `MainCanvasViewHolder`
- **Behavioral Summary:** Allocates platform-specific map viewport canvas structures, passing platform configuration parameters and returning an autoreleased canvas instance.
- **Type of Evidence:** Ghidra Decompiler Listing and selector reference table.
- **Confidence Level:** VERIFIED (High)
- **Cross-Reference Summary:** Referenced from `0x1087c276b` (DATA).

---

## 4. Navigation Guidance Reducer

### `NavigationGuidanceReducerBridge::reduceGuidanceEvent:`
- **Virtual Address:** `0x100102264`
- **Associated Module:** `NavigationGuidanceReducerBridge`
- **Behavioral Summary:** Redux-style reducer that takes current guidance state and an incoming guidance event, dispatching to internal C++ state reducers (`func_0x000100f60cc8`), freeing transient event buffers, and returning updated navigation state flags.
- **Type of Evidence:** Ghidra Decompiler Listing, conformance to `NavigationGuidanceReducerBridgeProtocol`.
- **Confidence Level:** VERIFIED (High)
- **Cross-Reference Summary:** Referenced from `__objc_methlist` and `0x1087c2e49` (DATA).

---

## 5. Location Services & Sensor Bridging

### `WZWazeLocationServiceBridge::dispatchLocationUpdate:`
- **Virtual Address:** `0x1000a1d28`
- **Associated Module:** `WZWazeLocationServiceBridge`
- **Behavioral Summary:** Receives raw sensor callbacks, verifies active location tracking state, extracts double-precision coordinates (latitude, longitude), and allocates a `WSVLocationSpeed` bridge transfer object.
- **Type of Evidence:** Ghidra Decompiler Listing, resolution of referenced class `WSVLocationSpeed`.
- **Confidence Level:** VERIFIED (High)
- **Cross-Reference Summary:** Referenced from `__objc_methlist` and `0x1087c1f7b` (DATA).
