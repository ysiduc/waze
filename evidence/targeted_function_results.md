# Empirical Function Verification Results (Phase 1.4)

**Target Binary:** `Waze` (ARM64 iOS Executable, `waze.ipa` v5.22.0)  
**Binary Size:** 141,425,424 bytes (`0x86e0df0`)  
**SHA-256:** `0c40c247228439e2b75baca181569c75c144918561a8177e9399b183b5709d80`  
**Analysis Engine:** Ghidra 12.1.2 Headless Analyzer (`analyzeHeadless`) & REA 6.5.0  
**Verification Date:** 2026-10-16  
**Host Environment:** Arch Linux x86_64, OpenJDK 27  

---

## 1. Function Verification Summary Table

| Virtual Address | Component / Class | Verified Runtime Selector | Type Signature | Span (Start - End) | Size (Bytes) | Inst Count | CFG Blocks | Calls (Dir/Ind) | Decomp Time | Status |
|:---|:---|:---|:---|:---|:---:|:---:|:---:|:---:|:---:|:---:|
| `0x10001a718` | `AlternateRoutesStateMachineBridge` | `applyRouteUpdateWithRouteUpdateProtos:` | `v24@0:8@16` | `0x10001a718` - `0x10001ad1b` | 1,300 B | 325 | 43 | 95 / 4 | 228 ms | **VERIFIED** |
| `0x1000d4b08` | `MainCanvasViewHolder` | `init` | `@16@0:8` | `0x1000d4b08` - `0x1000d4beb` | 228 B | 57 | 3 | 13 / 0 | 15 ms | **VERIFIED** |
| `0x1000d4c6c` | `MainCanvasViewHolder` | `makeGenericCanvasActivator` | `@16@0:8` | `0x1000d4c6c` - `0x1000d4cab` | 64 B | 16 | 1 | 3 / 0 | 7 ms | **VERIFIED** |
| `0x100102264` | `NavigationGuidanceReducerBridge` | `distanceToCrossSegmentWith:` | `q24@0:8q16` | `0x100102264` - `0x1001023eb` | 392 B | 98 | 20 | 9 / 3 | 21 ms | **VERIFIED** |
| `0x1000a1d28` | `WZWazeLocationServiceBridge` | `currentSpeed` | `@16@0:8` | `0x1000a1d28` - `0x1000a1d7f` | 88 B | 22 | 5 | 4 / 0 | 5 ms | **VERIFIED** |

**Benchmark Total:** 5 targeted application functions, 2,072 bytes of compiled ARM64 code, 518 instructions, 72 basic blocks, 100% decompilation success in 276 ms total (average 55.2 ms/function).

---

## 2. Detailed Function Analysis

### 2.1. `AlternateRoutesStateMachineBridge::applyRouteUpdateWithRouteUpdateProtos:`

- **Address:** `0x10001a718`
- **Memory Section:** `__TEXT.__text` (Flags: Read, Execute)
- **Verified Boundaries:**
  - Entry: `0x10001a718` (`sub sp, sp, #0x6d0`)
  - Exit: `0x10001ad18` (`ret`)
  - Span: `0x10001a718` - `0x10001ad1b` (1,300 bytes, exactly 325 32-bit ARM64 instructions)
- **Objective-C Runtime Binding:**
  - Method list address: `0x1046845b8` (relative method list in `__TEXT.__objc_methlist`)
  - Owning Class: `AlternateRoutesStateMachineBridge` (class struct at `0x107f17048`, `class_ro_t` at `0x107d233c8`)
  - Selector: `applyRouteUpdateWithRouteUpdateProtos:` (selref `0x107ee0ab8` -> `0x104bffcc2`)
  - Type Encoding: `v24@0:8@16` (void return, frame 24, self at 0, _cmd at 8, proto object at 16)
- **Control-Flow Graph (CFG):**
  - Basic Blocks: 43
  - Branching Structure: 3 distinct sequential conditional blocks parsing distinct sub-proto fields from the incoming protobuf wrapper.
  - Exception Handling: Contains landing pad invoking `__Unwind_Resume` (`0x10001accc`) and cleanup branches.
- **Embedded Assertions & Logging Strings:**
  - File: `"AlternateRoutesStateMachineBridge.mm"`
  - Internal C++ Method Name: `"ParseToRoutingUpdateResponse"`
  - Error 1 (line 30 / `0x1e`): `"Failed to parse CurrentRouteUpdate"`
  - Error 2 (line 39 / `0x27`): `"Failed to parse RerouteSuggestion"`
  - Error 3 (line 48 / `0x30`): `"Failed to parse NextUpdateSchedule"`
- **Call Relationships:**
  - Direct Calls (95):
    - Runtime Memory & Retention: `_bzero`, `_objc_retain_x19`, `_objc_release_x19`, `_objc_retainAutoreleasedReturnValue`, `___stack_chk_fail`.
    - Protobuf Deserialization: `0x103e5e994` (`CurrentRouteUpdate`), `0x103e60c38` (`RerouteSuggestion`), `0x103f35db0` (`NextUpdateSchedule`).
    - Sub-Handlers: `0x10001ad1c` (adjacent handler for reroute suggestions), `0x10001ad68` (next update schedule handler), `0x10001ae10` (finalization).
    - State Machine Dispatch: `0x100f8e148` (bridge context accessor), `0x100f8e75c` (event emitter).
  - Indirect Calls (4): Virtual C++ calls `blr x9` and `blr x8` dispatched through the active state machine context pointer.
- **Decompilation Quality:**
  - Clean C control structure recovered: stack buffers allocated, sub-proto existence verified, parsed objects forwarded to internal C++ state machine, ARC releases cleanly paired.

---

### 2.2. `MainCanvasViewHolder::init`

- **Address:** `0x1000d4b08`
- **Memory Section:** `__TEXT.__text` (Flags: Read, Execute)
- **Verified Boundaries:**
  - Entry: `0x1000d4b08` (`sub sp, sp, #0x50`)
  - Exit: `0x1000d4be8` (`ret`)
  - Span: `0x1000d4b08` - `0x1000d4beb` (228 bytes, 57 ARM64 instructions)
- **Objective-C Runtime Binding:**
  - Method list address: `0x1046a0c90` (relative method list in `__TEXT.__objc_methlist`)
  - Owning Class: `MainCanvasViewHolder` (class struct at `0x107f1a4a0`, `class_ro_t` at `0x107d376a0`)
  - Selector: `init` (selref `0x107ee8b90` -> `0x104c40430`)
  - Type Encoding: `@16@0:8` (returns object instance, self at 0, _cmd at 8)
- **Control-Flow Graph (CFG):**
  - Basic Blocks: 3
  - Branching: Straight-line initialization with a single nil-check conditional on the `super init` return value (`if (self != nil)`).
- **Call Relationships:**
  - Direct Calls (13):
    - `0x1000d4b3c`: `BL _objc_msgSendSuper2` (invoking `-[NSObject init]`)
    - `0x1000d4b54`: `BL _objc_alloc`
    - `0x1000d4b64`: `BL 0x10460f060` (viewport observer registration)
    - `0x1000d4b78`: `BL 0x10460f020` (canvas bounds observer registration)
    - `0x1000d4b90`: `BL _objc_alloc_init` (`PTR_PTR_107f0b1c0`)
    - `0x1000d4bcc`: `BL 0x1045eafa0` (canvas lifecycle delegate notification)
  - Indirect Calls: 0
- **Internal State Mutation:**
  - Stores the newly configured canvas viewport controller into instance variable offset `self + 0x28` (`*(undefined **)((long)puVar1 + 0x28) = puVar2`).
- **Decompilation Quality:**
  - 100% decompiled in 15 ms. Perfect Objective-C initialization idiom recovered.

---

### 2.3. `MainCanvasViewHolder::makeGenericCanvasActivator`

- **Address:** `0x1000d4c6c`
- **Memory Section:** `__TEXT.__text` (Flags: Read, Execute)
- **Verified Boundaries:**
  - Entry: `0x1000d4c6c` (`stp x20, x19, [sp, #-0x20]!`)
  - Exit: `0x1000d4ca8` (`b _objc_autoreleaseReturnValue` tail-call)
  - Span: `0x1000d4c6c` - `0x1000d4cab` (64 bytes, 16 ARM64 instructions)
- **Objective-C Runtime Binding:**
  - Method list address: `0x1046a0c90` (same method list as `MainCanvasViewHolder::init`)
  - Owning Class: `MainCanvasViewHolder` (`0x107f1a4a0`)
  - Selector: `makeGenericCanvasActivator` (selref `0x107eeca90` -> `0x104c55df0`)
  - Type Encoding: `@16@0:8`
- **Control-Flow Graph (CFG):**
  - Basic Blocks: 1 (pure straight-line factory routine)
- **Allocated Class Object:**
  - Class reference `PTR_PTR_107f0aa20` resolves via chained fixup to `0x107f1a680` (`GenericCanvasActivator`).
- **Call Relationships:**
  - Direct Calls (3):
    - `0x1000d4c84`: `BL _objc_alloc` (allocates `GenericCanvasActivator`)
    - `0x1000d4c90`: `BL 0x10460e360` (extracts platform rendering service from `self`)
    - `0x1000d4c9c`: `BL 0x1046046e0` (initializes activator with platform context)
  - Terminal Exit: Tail-call to `_objc_autoreleaseReturnValue`.
  - Indirect Calls: 0
- **Decompilation Quality:**
  - 100% decompiled in 7 ms. Unambiguous factory method returning an autoreleased activator.

---

### 2.4. `NavigationGuidanceReducerBridge::distanceToCrossSegmentWith:`

- **Address:** `0x100102264`
- **Memory Section:** `__TEXT.__text` (Flags: Read, Execute)
- **Verified Boundaries:**
  - Entry: `0x100102264` (`sub sp, sp, #0x180`)
  - Exit: `0x1001023e8` (`ret`)
  - Span: `0x100102264` - `0x1001023eb` (392 bytes, 98 ARM64 instructions)
- **Objective-C Runtime Binding:**
  - Method list address: `0x1046a48c8`
  - Owning Class: `NavigationGuidanceReducerBridge` (class struct at `0x107f1ab08`, `class_ro_t` at `0x107d395b0`)
  - Selector: `distanceToCrossSegmentWith:` (selref `0x107ee5118` -> `0x104c1ab06`)
  - Type Encoding: `q24@0:8q16` (returns 64-bit integer `long long`, self at 0, _cmd at 8, segment ID at 16)
- **Control-Flow Graph (CFG):**
  - Basic Blocks: 20
  - Branching: Multiple conditional validation branches evaluating segment flags (`uStack_50 & 1`), checking calculation results, and unwinding dynamically allocated geometry arrays.
- **Call Relationships:**
  - Direct Calls (9):
    - `0x100102284`: `BL 0x100f60cc8` (acquires guidance engine singleton / context)
    - `0x100102318`, `0x100102334`, `0x100102350`, `0x100102368`: `BL __ZdlPvm` (`operator delete(void*, unsigned long)`)
    - `0x10010237c`: `BL 0x100102608` (segment vector cleanup)
    - `0x100102388`: `BL 0x1001026c0` (coordinate array cleanup)
    - `0x100102398`: `BL 0x100102764` (turn point cleanup)
    - `0x1001023d0`: `BL __ZNSt3__119__shared_weak_count14__release_weakEv`
  - Indirect Calls (3):
    - `0x1001022cc`: `blr x9` (C++ vtable call `*plStack_48 + 0xa8`: segment intersection test)
    - `0x1001022e8`: `blr x8` (C++ vtable call `*plStack_48 + 0xe8`: distance computation)
    - `0x1001023c8`: `blr x8` (C++ virtual destructor on engine handle)
- **Decompilation Quality:**
  - 100% decompiled in 21 ms. Full C++ interop lifecycle cleanly recovered, including atomic reference decrement loop (`ExclusiveMonitorPass` / `ExclusiveMonitorsStatus`).

---

### 2.5. `WZWazeLocationServiceBridge::currentSpeed`

- **Address:** `0x1000a1d28`
- **Memory Section:** `__TEXT.__text` (Flags: Read, Execute)
- **Verified Boundaries:**
  - Entry: `0x1000a1d28` (`stp x20, x19, [sp, #-0x20]!`)
  - Exit: `0x1000a1d7c` (`b _objc_autoreleaseReturnValue` tail-call)
  - Span: `0x1000a1d28` - `0x1000a1d7f` (88 bytes, 22 ARM64 instructions)
- **Objective-C Runtime Binding:**
  - Method list address: `0x1046b8d00`
  - Owning Class: `WZWazeLocationServiceBridge` (class struct at `0x107f19690`, `class_ro_t` at `0x107d321f0`)
  - Selector: `currentSpeed` (selref `0x107ee41c0` -> `0x104c1505e`)
  - Type Encoding: `@16@0:8` (returns speed telemetry transfer object)
- **Control-Flow Graph (CFG):**
  - Basic Blocks: 5
  - Branching: Checks location tracking state (`param_1 != 0`), verifies telemetry validity (`lVar1 != 0`), constructs transfer object, and returns `nil` if tracking is inactive.
- **Telemetry Extraction Logic:**
  - Reads 32-bit integer speed telemetry at `*(int *)(lVar1 + 0xc)` and accuracy/bearing at `*(int *)(lVar1 + 0x34)`.
  - Converts both to IEEE 754 double precision (`(double)*(int *)(...)`).
  - Calls initializer `func_0x000104604360` with double parameters.
- **Call Relationships:**
  - Direct Calls (4):
    - `0x1000a1d34`: `BL 0x100e538d8` (checks location service authorization)
    - `0x1000a1d40`: `BL 0x100e54d30` (fetches active GPS telemetry record)
    - `0x1000a1d54`: `BL _objc_alloc`
    - `0x1000a1d68`: `BL 0x104604360` (invokes speed object initializer)
  - Terminal Exit: Tail-call to `_objc_autoreleaseReturnValue`.
  - Indirect Calls: 0
- **Decompilation Quality:**
  - 100% decompiled in 5 ms. Exact telemetry fields and object construction validated.

---

## 3. Discrepancy & Verification Ledger: REA vs. Direct Ghidra

| Domain | Prior / Inferred Claim (Phase 1.2-1.3) | Verified Ground Truth (Phase 1.4 Scoped Analysis) | Empirical Proof |
|:---|:---|:---|:---|
| **`0x10001a718` Selector** | `ParseToRoutingUpdateResponse:` | **`applyRouteUpdateWithRouteUpdateProtos:`** | Method struct `0x1046845c0` in `__TEXT.__objc_methlist` binds selref `0x107ee0ab8` -> `0x104bffcc2`. `ParseToRoutingUpdateResponse` is the internal C++ log string. |
| **`0x1000d4c6c` Selector** | `createCanvasWithPlatformService:` | **`makeGenericCanvasActivator`** | Method struct `0x1046a0cbc` in `__TEXT.__objc_methlist` binds selref `0x107eeca90` -> `0x104c55df0`. Instantiates `GenericCanvasActivator`. |
| **`0x100102264` Selector** | `reduceGuidanceEvent:` | **`distanceToCrossSegmentWith:`** | Method struct `0x1046a48d0` in `__TEXT.__objc_methlist` binds selref `0x107ee5118` -> `0x104c1ab06`. Type signature is `q24@0:8q16`. |
| **`0x1000a1d28` Selector** | `dispatchLocationUpdate:` | **`currentSpeed`** | Method struct `0x1046b8d08` in `__TEXT.__objc_methlist` binds selref `0x107ee41c0` -> `0x104c1505e`. Returns speed transfer object. |
| **Ghidra Analysis Scalability** | Only import stubs verified (19 stubs + 1 entry) | **100% success on complex routines (up to 1,300 B, 43 basic blocks, 95 calls)** | All 5 complex routines decompiled without a single decompiler error, timeout, or crash. |
| **Analysis Performance** | Feared multi-hour freeze on 141 MB binary | **276 ms total execution time** | Scoped analysis without full-program auto-analysis bypassed all performance bottlenecks. |
| **REA Headless Integration** | Expected single-command execution | **Timed out (3m) during whole-binary auto-analysis** | REA default Ghidra bridge lacks `-noanalysis` scoping for large binaries, whereas direct Ghidra headless scripts execute instantly. |
