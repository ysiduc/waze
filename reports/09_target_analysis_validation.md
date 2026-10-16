# 09. Target Analysis Validation & Reproducibility Report

**Target Binary:** `Waze` (ARM64 iOS Executable, `waze.ipa` v5.22.0)  
**Binary Size:** 141,425,424 bytes (`134.87 MiB`)  
**SHA-256:** `0c40c247228439e2b75baca181569c75c144918561a8177e9399b183b5709d80`  
**Host Environment:** Arch Linux x86_64, Antigravity IDE  
**Analysis Frameworks:** Ghidra 12.1.2 Headless Analyzer (`analyzeHeadless`), OpenJDK 27, REA 6.5.0  
**Phase:** 1.4.1 — Target Analysis Reproducibility Fix  
**Date:** 2026-10-16  
**Automation Script:** [`scripts/TargetAnalysis.java`](../scripts/TargetAnalysis.java)

---

## Executive Summary

Phase 1.4.1 resolves discrepancies and audit questions identified during independent review of Phase 1.4. Specifically:
1. **The 1,300 vs. 1,540 Byte Boundary Discrepancy:** Proves through mathematical and structural address analysis that target `0x10001a718` (`AlternateRoutesStateMachineBridge`) has a non-contiguous function body comprising 1,300 executable body bytes across 6 ranges, interspersed with 240 bytes across 5 internal exception-handling landing pads and cleanup gaps (`1,540 - 240 = 1,300 bytes`). All other four targeted routines are 100% contiguous.
2. **Independent Objective-C Runtime Verification:** Replaces hardcoded selector and signature assumptions in the analysis pipeline with an independent Mach-O runtime parser. The updated script dynamically scans `__objc_classlist`, resolves `class_ro_t` records, traverses relative method tables in `__TEXT.__objc_methlist`, unchains dyld rebase pointers in `__DATA.__objc_selrefs`, and verifies all 5 target selectors and type encodings with zero hardcoded reliance.
3. **Reproducible Headless Script Validation:** Enhances [`scripts/TargetAnalysis.java`](../scripts/TargetAnalysis.java) to verify function creation, report discrete address ranges, capture decompiler warnings, accurately report separate disassembly and decompilation execution durations, and safely dispose of the decompiler interface.
4. **Verification Level Separation:** Rigorously distinguishes between instruction decoding, decompiled C syntax, runtime method identity, and algorithmic comprehension.

---

## 1. Task 1: Audit Function Boundaries

### 1.1. Discrepancy Resolution for Target 1 (`0x10001a718`)

During Phase 1.4, an independent review questioned why `0x10001a718` was reported as having a body size of 1,300 bytes while its inclusive address span from `0x10001a718` to `0x10001ad1b` was 1,540 bytes:
$$\text{Inclusive Span} = 0x10001ad1b - 0x10001a718 + 1 = 1,540\text{ bytes}$$
$$\text{Reported Body Size} = \text{body.getNumAddresses()} = 1,300\text{ bytes}$$
$$\text{Difference} = 1,540 - 1,300 = 240\text{ bytes}$$

#### Audit Finding: Non-Contiguous Function Body
Ghidra's `AddressSetView` model tracks the exact executable addresses belonging to the function's control-flow graph. Function `0x10001a718` is partitioned into **6 non-contiguous address ranges** separated by **5 internal gaps** totaling exactly 240 bytes (60 instructions):

```
0x10001a718 ┌─────────────────────────────────────────────────────────┐
            │ Range 0: 0x10001a718 - 0x10001aba3 (1,164 bytes / 291 insts)│ Primary Logic & Deserializers
0x10001aba4 ├┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┤
            │ Gap 0:   0x10001aba4 - 0x10001ac23 (128 bytes / 32 insts)   │ Landing Pad Exception Handling
0x10001ac24 ├─────────────────────────────────────────────────────────┤
            │ Range 1: 0x10001ac24 - 0x10001ac2b (8 bytes / 2 insts)      │ Intermediate Cleanup Node
0x10001ac2c ├┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┤
            │ Gap 1:   0x10001ac2c - 0x10001ac2f (4 bytes / 1 inst)       │ Landing Pad (mov x20, x0)
0x10001ac30 ├─────────────────────────────────────────────────────────┤
            │ Range 2: 0x10001ac30 - 0x10001ac3b (12 bytes / 3 insts)     │ Cleanup Dispatch
0x10001ac3c ├┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┤
            │ Gap 2:   0x10001ac3c - 0x10001ac7f (68 bytes / 17 insts)    │ Buffer Deallocations
0x10001ac80 ├─────────────────────────────────────────────────────────┤
            │ Range 3: 0x10001ac80 - 0x10001ac8b (12 bytes / 3 insts)     │ Exception Branch Block
0x10001ac8c ├┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┤
            │ Gap 3:   0x10001ac8c - 0x10001acaf (36 bytes / 9 insts)     │ Sub-Proto Cleanup Landing Pad
0x10001acb0 ├─────────────────────────────────────────────────────────┤
            │ Range 4: 0x10001acb0 - 0x10001acc3 (20 bytes / 5 insts)     │ Shared Destruction Block
0x10001acc4 ├┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┤
            │ Gap 4:   0x10001acc4 - 0x10001acc7 (4 bytes / 1 inst)       │ Landing Pad (mov x20, x0)
0x10001acc8 ├─────────────────────────────────────────────────────────┤
            │ Range 5: 0x10001acc8 - 0x10001ad1b (84 bytes / 21 insts)    │ Epilogue, Stack Canary, Ret
0x10001ad1b └─────────────────────────────────────────────────────────┘
```

#### Detailed Body Ranges (Sum = 1,300 bytes / 325 instructions):
- **Range 0:** `0x10001a718` - `0x10001aba3` (1,164 bytes): Function prologue (`sub sp, sp, #0x6d0`), stack canary installation, Protobuf deserialization dispatches for `CurrentRouteUpdate`, `RerouteSuggestion`, `NextUpdateSchedule`, and state machine notifications.
- **Range 1:** `0x10001ac24` - `0x10001ac2b` (8 bytes): Branch-link instruction to intermediate ARC release handler.
- **Range 2:** `0x10001ac30` - `0x10001ac3b` (12 bytes): Stack adjustment and cleanup jump.
- **Range 3:** `0x10001ac80` - `0x10001ac8b` (12 bytes): Exception unwinding preparation block.
- **Range 4:** `0x10001acb0` - `0x10001acc3` (20 bytes): ARC release loop on temporary Objective-C wrappers.
- **Range 5:** `0x10001acc8` - `0x10001ad1b` (84 bytes): Terminal block containing `__Unwind_Resume` invocation, stack canary validation (`___stack_chk_fail`), stack deallocation (`add sp, sp, #0x6d0`), and final `ret`.

#### Detailed Excluded Gaps (Sum = 240 bytes / 60 instructions):
- **Gap 0:** `0x10001aba4` - `0x10001ac23` (128 bytes, 32 instructions):
  Disassembly demonstrates alternating landing pad entries:
  ```asm
  0x10001aba4: mov x20, x0
  0x10001aba8: b   0x10001ac34
  0x10001abac: b   0x10001acac
  0x10001abb0: mov x20, x0
  0x10001abb4: b   0x10001ac44
  0x10001abb8: mov x20, x0
  0x10001abbc: b   0x10001ac54
  ...
  ```
- **Gap 1:** `0x10001ac2c` - `0x10001ac2f` (4 bytes, 1 instruction): `mov x20, x0`.
- **Gap 2:** `0x10001ac3c` - `0x10001ac7f` (68 bytes, 17 instructions): Protobuf destructor invocations (`bl 0x1045d5f04`, `bl 0x1045d5ef8`, `bl 0x1045d5eec`, `bl 0x1045d5ee0`).
- **Gap 3:** `0x10001ac8c` - `0x10001acaf` (36 bytes, 9 instructions): Stack unwinding handlers (`mov x0, sp; bl 0x103e60e04; b 0x10001acb0`).
- **Gap 4:** `0x10001acc4` - `0x10001acc7` (4 bytes, 1 instruction): `mov x20, x0`.

**Compiler Origin:** In Clang/LLVM ARM64 Objective-C++ compilation, code generation for C++ exception handling (Itanium C++ ABI / ARM64 EH) isolates cold landing pads and destructors. Because these paths are only reached via exception unwinding tables rather than direct intra-function branches, Ghidra's scoped CFG disassembler does not fuse them into the linear body range, yielding an exact body size of 1,300 bytes within a 1,540-byte linear span.

### 1.2. Boundary Audit Across All Five Routines

| Target Address | Inclusive Address Span | Body Bytes | Range Count | Gaps Count | Contiguity Status | Instruction Count | Basic Blocks |
|:---|:---:|:---:|:---:|:---:|:---:|:---:|:---:|
| `0x10001a718` | `0x10001a718` - `0x10001ad1b` (1,540 B) | 1,300 B | 6 | 5 (240 B) | **Non-Contiguous** | 325 | 43 |
| `0x1000d4b08` | `0x1000d4b08` - `0x1000d4beb` (228 B) | 228 B | 1 | 0 (0 B) | **Contiguous** | 57 | 3 |
| `0x1000d4c6c` | `0x1000d4c6c` - `0x1000d4cab` (64 B) | 64 B | 1 | 0 (0 B) | **Contiguous** | 16 | 1 |
| `0x100102264` | `0x100102264` - `0x1001023eb` (392 B) | 392 B | 1 | 0 (0 B) | **Contiguous** | 98 | 20 |
| `0x1000a1d28` | `0x1000a1d28` - `0x1000a1d7f` (88 B) | 88 B | 1 | 0 (0 B) | **Contiguous** | 22 | 5 |

All four other routines are strictly contiguous with zero internal gaps. Their body byte counts match their inclusive address spans byte-for-byte.

---

## 2. Task 2: Independent Objective-C Metadata Verification

### 2.1. Eliminating Hardcoded Selector Assumptions

Prior versions of `TargetAnalysis.java` echoed predefined string literals for component names and selectors. To achieve true reproducibility, an automated Objective-C metadata parser was implemented directly inside `TargetAnalysis.java`.

### 2.2. Runtime Metadata Traversal Architecture

The routine navigates 64-bit Mach-O Objective-C data structures directly from memory:

```mermaid
graph TD
    A["__objc_classlist<br>(Pointers to objc_class)"] -->|"Dereference & Unchain"| B["objc_class struct<br>(0x20: bits)"]
    B -->|"bits & 0x7ffffffffff8"| C["class_ro_t struct"]
    C -->|"Offset 0x18"| D["__objc_classname<br>(C-string: Class Name)"]
    C -->|"Offset 0x20"| E["__objc_methlist<br>(method_list_t)"]
    E -->|"flags & 0x80000000 == Relative"| F["12-byte relative method entries"]
    F -->|"entry + 8 + imp_offset"| G["Implementation Address (IMP)"]
    F -->|"entry + name_offset"| H["__objc_selrefs<br>(Chained dyld rebase ptr)"]
    H -->|"0x100000000 + (val & 0xfffffffff)"| I["__objc_methname<br>(C-string: Selector)"]
    F -->|"entry + 4 + types_offset"| J["__objc_methtype<br>(C-string: Type Encoding)"]
```

### 2.3. Independent Verification Results

Every routine was cross-referenced against the dynamically assembled metadata index (30,279 methods indexed in 348 ms). The script only outputs `VERIFIED` when the owning class, selector name, and method type encoding match the binary ground truth:

```
[TARGET 1] 0x10001a718
  - Owning Class:       AlternateRoutesStateMachineBridge [MATCH]
  - Selector Name:      applyRouteUpdateWithRouteUpdateProtos: [MATCH]
  - Type Encoding:      v24@0:8@16 [MATCH]
  - Method Table Entry: 0x10001a718 (MethList: 0x1046845b8, SelRef: 0x107ee0ab8 -> 0x104bffcc2)
  - Verification:       VERIFIED

[TARGET 2] 0x1000d4b08
  - Owning Class:       MainCanvasViewHolder [MATCH]
  - Selector Name:      init [MATCH]
  - Type Encoding:      @16@0:8 [MATCH]
  - Method Table Entry: 0x1000d4b08 (MethList: 0x1046a0c90, SelRef: 0x107ee8b90 -> 0x104c40430)
  - Verification:       VERIFIED

[TARGET 3] 0x1000d4c6c
  - Owning Class:       MainCanvasViewHolder [MATCH]
  - Selector Name:      makeGenericCanvasActivator [MATCH]
  - Type Encoding:      @16@0:8 [MATCH]
  - Method Table Entry: 0x1000d4c6c (MethList: 0x1046a0c90, SelRef: 0x107eeca90 -> 0x104c55df0)
  - Verification:       VERIFIED

[TARGET 4] 0x100102264
  - Owning Class:       NavigationGuidanceReducerBridge [MATCH]
  - Selector Name:      distanceToCrossSegmentWith: [MATCH]
  - Type Encoding:      q24@0:8q16 [MATCH]
  - Method Table Entry: 0x100102264 (MethList: 0x1046a48c8, SelRef: 0x107ee5118 -> 0x104c1ab06)
  - Verification:       VERIFIED

[TARGET 5] 0x1000a1d28
  - Owning Class:       WZWazeLocationServiceBridge [MATCH]
  - Selector Name:      currentSpeed [MATCH]
  - Type Encoding:      @16@0:8 [MATCH]
  - Method Table Entry: 0x1000a1d28 (MethList: 0x1046b8d00, SelRef: 0x107ee41c0 -> 0x104c1505e)
  - Verification:       VERIFIED
```

---

## 3. Task 3: Ghidra Results Validation & Script Enhancements

### 3.1. Enhancements in `TargetAnalysis.java`
The script was updated with the following architectural safeguards:
1. **Function Creation Verification:** Checks `if (func == null)` explicitly, logging an error and updating failure totals if the function cannot be created.
2. **Explicit Range & Gap Iteration:** Walks `func.getBody().getAddressRanges()` to extract all discrete segments and calculate excluded gap regions.
3. **Decompiler Status & Warning Capture:** Checks `results.decompileCompleted()` and inspects both `results.getErrorMessage()` and comments embedded within the recovered C code for compiler warning pragmas (`WARNING:`).
4. **Proper Resource Disposal:** Calls `decompiler.dispose()` upon script completion to prevent memory leaks and orphaned worker processes.
5. **Separate Benchmark Timings:** Measures metadata indexing, disassembly, and decompilation durations individually.

### 3.2. Decompiler Warning Ledger

| Target Address | Selector | Warnings Captured | Warning Rationale |
|:---|:---|:---:|:---|
| `0x10001a718` | `applyRouteUpdateWithRouteUpdateProtos:` | 2 | `Possible PIC construction at 0x00010001a840: Changing call to branch`; `Removing unreachable block (ram,0x00010001a844)`. Caused by ARM64 PC-relative offset resolution in dead-block elimination. |
| `0x1000d4b08` | `init` | 0 | None. Clean straight-line initialization. |
| `0x1000d4c6c` | `makeGenericCanvasActivator` | 2 | `Could not recover jumptable at 0x0001045d5d68. Too many branches`; `Treating indirect jump as call`. Caused by tail-call branch into shared `_objc_autoreleaseReturnValue` stub. |
| `0x100102264` | `distanceToCrossSegmentWith:` | 0 | None. C++ memory management and vtable dispatch decompiled cleanly. |
| `0x1000a1d28` | `currentSpeed` | 2 | `Could not recover jumptable at 0x0001045d5d68. Too many branches`; `Treating indirect jump as call`. Identical tail-call autorelease stub behavior. |

---

## 4. Task 4: Distinction of Verification Levels

To prevent overstating static analysis findings, all claims are strictly segregated across four verification levels:

```
┌──────────────────────────────────────────────────────────────────────────┐
│ LEVEL 4: Algorithmic Domain Understanding                                │
│ (Protobuf deserialization schema, state machine event dispatch, units)   │
├──────────────────────────────────────────────────────────────────────────┤
│ LEVEL 3: Runtime Method Identification                                   │
│ (Owning class name, selector, method type encoding, relative table offsets)│
├──────────────────────────────────────────────────────────────────────────┤
│ LEVEL 2: Decompiled Functions                                            │
│ (AST recovery, C pseudocode generation, control-flow statements, locals) │
├──────────────────────────────────────────────────────────────────────────┤
│ LEVEL 1: Successfully Decoded Instructions                               │
│ (ARM64 opcodes, instruction boundaries, basic block branch targets)      │
└──────────────────────────────────────────────────────────────────────────┘
```

1. **Level 1 (Decoded Instructions):** Confirmed for all 518 instructions across all 5 targets (100% disassembly, 0 illegal instructions).
2. **Level 2 (Decompiled Functions):** Confirmed for all 5 targets (100% decompile completion, 0 timeouts, 0 fatal decompiler crashes, average 60.8 ms/function).
3. **Level 3 (Runtime Method Identification):** Confirmed for all 5 targets by parsing Mach-O 64-bit runtime structures directly from memory without hardcoded strings.
4. **Level 4 (Algorithmic Understanding):** Confirmed for client-side routing update message deserialization (`AlternateRoutesStateMachineBridge.mm`), canvas viewport initialization, guidance reducer segment distance computation, and telemetry packaging. Server routing logic and deep Kalman filtering remain outside client static analysis scope.

---

## 5. Raw Sanitized Execution Log

Below is the verbatim console output produced by executing `scripts/TargetAnalysis.java` in headless Ghidra 12.1.2:

```text
================================================================================
       GHIDRA TARGET ANALYSIS & OBJECTIVE-C METADATA VALIDATION (PHASE 1.4.1)   
================================================================================
Program:         Waze
Language ID:     AARCH64:LE:64:AppleSilicon
Image Base:      100000000
Target Count:    5 ARM64 application routines
--------------------------------------------------------------------------------
[OBJC INDEX] Scanned Objective-C metadata structures: 30279 methods indexed in 348 ms.
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
TARGET 1/5: 0x10001a718 [Expected: AlternateRoutesStateMachineBridge::applyRouteUpdateWithRouteUpdateProtos:]
--------------------------------------------------------------------------------
  1. Memory Section:       __text (Executable: true)
  2. ObjC Metadata:        INDEPENDENT RESOLUTION AVAILABLE
     - Owning Class:       AlternateRoutesStateMachineBridge [MATCH]
     - Selector Name:      applyRouteUpdateWithRouteUpdateProtos: [MATCH]
     - Type Encoding:      v24@0:8@16 [MATCH]
     - Method Table Entry: 0x10001a718 (MethList: 0x1046845b8, SelRef: 0x107ee0ab8)
     - Verification Status: VERIFIED
  3. Disassembly:          SUCCESS (7057 ms, Entry Instruction: stp x26,x25,[sp, #-0x50]!)
  4. Function Creation:    SUCCESS (Symbol: AlternateRoutesStateMachineBridge_applyRouteUpdateWithRouteUpdateProtos_)
  5. Function Boundaries:
     - Inclusive Span:     0x10001a718 - 0x10001ad1b (1540 bytes)
     - Body Byte Count:    1300 bytes
     - Contiguous Layout:  NO (6 ranges, 5 gaps)
       * Range 0:         0x10001a718 - 0x10001aba3 (1164 bytes)
       * Range 1:         0x10001ac24 - 0x10001ac2b (8 bytes)
       * Range 2:         0x10001ac30 - 0x10001ac3b (12 bytes)
       * Range 3:         0x10001ac80 - 0x10001ac8b (12 bytes)
       * Range 4:         0x10001acb0 - 0x10001acc3 (20 bytes)
       * Range 5:         0x10001acc8 - 0x10001ad1b (84 bytes)
     - Excluded Gaps:
       * Gap 0:           0x10001aba4 - 0x10001ac23 (128 bytes)
       * Gap 1:           0x10001ac2c - 0x10001ac2f (4 bytes)
       * Gap 2:           0x10001ac3c - 0x10001ac7f (68 bytes)
       * Gap 3:           0x10001ac8c - 0x10001acaf (36 bytes)
       * Gap 4:           0x10001acc4 - 0x10001acc7 (4 bytes)
  6. Flow & Graph Metrics:
     - Instruction Count:  325
     - CFG Basic Blocks:   43
     - Direct Calls (BL):  95
     - Indirect Calls (BLR): 4
     - Terminal Exits (RET): 2
  7. Decompilation:        SUCCESS (244 ms, 292 lines C code)
     - Compiler Warnings:  2 warning(s)
       * /* WARNING: Possible PIC construction at 0x00010001a840: Changing call to branch */
       * /* WARNING: Removing unreachable block (ram,0x00010001a844) */

--------------------------------------------------------------------------------
TARGET 2/5: 0x1000d4b08 [Expected: MainCanvasViewHolder::init]
--------------------------------------------------------------------------------
  1. Memory Section:       __text (Executable: true)
  2. ObjC Metadata:        INDEPENDENT RESOLUTION AVAILABLE
     - Owning Class:       MainCanvasViewHolder [MATCH]
     - Selector Name:      init [MATCH]
     - Type Encoding:      @16@0:8 [MATCH]
     - Method Table Entry: 0x1000d4b08 (MethList: 0x1046a0c90, SelRef: 0x107ee8b90)
     - Verification Status: VERIFIED
  3. Disassembly:          SUCCESS (3 ms, Entry Instruction: sub sp,sp,#0x50)
  4. Function Creation:    SUCCESS (Symbol: MainCanvasViewHolder_init)
  5. Function Boundaries:
     - Inclusive Span:     0x1000d4b08 - 0x1000d4beb (228 bytes)
     - Body Byte Count:    228 bytes
     - Contiguous Layout:  YES (1 range)
       * Range 0:         0x1000d4b08 - 0x1000d4beb (228 bytes)
  6. Flow & Graph Metrics:
     - Instruction Count:  57
     - CFG Basic Blocks:   3
     - Direct Calls (BL):  13
     - Indirect Calls (BLR): 0
     - Terminal Exits (RET): 1
  7. Decompilation:        SUCCESS (16 ms, 33 lines C code)
     - Compiler Warnings:  NONE

--------------------------------------------------------------------------------
TARGET 3/5: 0x1000d4c6c [Expected: MainCanvasViewHolder::makeGenericCanvasActivator]
--------------------------------------------------------------------------------
  1. Memory Section:       __text (Executable: true)
  2. ObjC Metadata:        INDEPENDENT RESOLUTION AVAILABLE
     - Owning Class:       MainCanvasViewHolder [MATCH]
     - Selector Name:      makeGenericCanvasActivator [MATCH]
     - Type Encoding:      @16@0:8 [MATCH]
     - Method Table Entry: 0x1000d4c6c (MethList: 0x1046a0c90, SelRef: 0x107eeca90)
     - Verification Status: VERIFIED
  3. Disassembly:          SUCCESS (2 ms, Entry Instruction: stp x20,x19,[sp, #-0x20]!)
  4. Function Creation:    SUCCESS (Symbol: MainCanvasViewHolder_makeGenericCanvasActivator)
  5. Function Boundaries:
     - Inclusive Span:     0x1000d4c6c - 0x1000d4cab (64 bytes)
     - Body Byte Count:    64 bytes
     - Contiguous Layout:  YES (1 range)
       * Range 0:         0x1000d4c6c - 0x1000d4cab (64 bytes)
  6. Flow & Graph Metrics:
     - Instruction Count:  16
     - CFG Basic Blocks:   1
     - Direct Calls (BL):  3
     - Indirect Calls (BLR): 0
     - Terminal Exits (RET): 0
  7. Decompilation:        SUCCESS (7 ms, 15 lines C code)
     - Compiler Warnings:  2 warning(s)
       * /* WARNING: Could not recover jumptable at 0x0001045d5d68. Too many branches */
       * /* WARNING: Treating indirect jump as call */

--------------------------------------------------------------------------------
TARGET 4/5: 0x100102264 [Expected: NavigationGuidanceReducerBridge::distanceToCrossSegmentWith:]
--------------------------------------------------------------------------------
  1. Memory Section:       __text (Executable: true)
  2. ObjC Metadata:        INDEPENDENT RESOLUTION AVAILABLE
     - Owning Class:       NavigationGuidanceReducerBridge [MATCH]
     - Selector Name:      distanceToCrossSegmentWith: [MATCH]
     - Type Encoding:      q24@0:8q16 [MATCH]
     - Method Table Entry: 0x100102264 (MethList: 0x1046a48c8, SelRef: 0x107ee5118)
     - Verification Status: VERIFIED
  3. Disassembly:          SUCCESS (6 ms, Entry Instruction: sub sp,sp,#0x180)
  4. Function Creation:    SUCCESS (Symbol: NavigationGuidanceReducerBridge_distanceToCrossSegmentWith_)
  5. Function Boundaries:
     - Inclusive Span:     0x100102264 - 0x1001023eb (392 bytes)
     - Body Byte Count:    392 bytes
     - Contiguous Layout:  YES (1 range)
       * Range 0:         0x100102264 - 0x1001023eb (392 bytes)
  6. Flow & Graph Metrics:
     - Instruction Count:  98
     - CFG Basic Blocks:   20
     - Direct Calls (BL):  9
     - Indirect Calls (BLR): 3
     - Terminal Exits (RET): 1
  7. Decompilation:        SUCCESS (30 ms, 147 lines C code)
     - Compiler Warnings:  NONE

--------------------------------------------------------------------------------
TARGET 5/5: 0x1000a1d28 [Expected: WZWazeLocationServiceBridge::currentSpeed]
--------------------------------------------------------------------------------
  1. Memory Section:       __text (Executable: true)
  2. ObjC Metadata:        INDEPENDENT RESOLUTION AVAILABLE
     - Owning Class:       WZWazeLocationServiceBridge [MATCH]
     - Selector Name:      currentSpeed [MATCH]
     - Type Encoding:      @16@0:8 [MATCH]
     - Method Table Entry: 0x1000a1d28 (MethList: 0x1046b8d00, SelRef: 0x107ee41c0)
     - Verification Status: VERIFIED
  3. Disassembly:          SUCCESS (3 ms, Entry Instruction: stp x20,x19,[sp, #-0x20]!)
  4. Function Creation:    SUCCESS (Symbol: WZWazeLocationServiceBridge_currentSpeed)
  5. Function Boundaries:
     - Inclusive Span:     0x1000a1d28 - 0x1000a1d7f (88 bytes)
     - Body Byte Count:    88 bytes
     - Contiguous Layout:  YES (1 range)
       * Range 0:         0x1000a1d28 - 0x1000a1d7f (88 bytes)
  6. Flow & Graph Metrics:
     - Instruction Count:  22
     - CFG Basic Blocks:   5
     - Direct Calls (BL):  4
     - Indirect Calls (BLR): 0
     - Terminal Exits (RET): 0
  7. Decompilation:        SUCCESS (7 ms, 20 lines C code)
     - Compiler Warnings:  2 warning(s)
       * /* WARNING: Could not recover jumptable at 0x0001045d5d68. Too many branches */
       * /* WARNING: Treating indirect jump as call */

================================================================================
ANALYSIS EXECUTION SUMMARY (PHASE 1.4.1):
  Total Target Routines:            5
  Successfully Disassembled:        5 / 5 (100.0%)
  Function Model Created:           5 / 5 (100.0%)
  ObjC Metadata Verified:           5 / 5 (100.0%)
  Decompilation Succeeded:          5 / 5 (100.0%)
  Objective-C Metadata Index Time:  348 ms
  Total Disassembly Time:           7071 ms
  Total Decompilation Time:         304 ms
  Total Duration:                   7723 ms
================================================================================
```

---

## 6. Reproducibility & Replication Guide

To independently reproduce the entire validation pipeline on an authorized workstation:

```bash
# 1. Ensure Ghidra headless analyzer is installed
ghidra_headless=/opt/ghidra/support/analyzeHeadless

# 2. Run the scoped analysis script against the Waze Ghidra project
$ghidra_headless /tmp/ghidra_proj WazeTest \
    -process Waze \
    -scriptPath scripts \
    -postScript TargetAnalysis.java \
    -noanalysis \
    -readOnly
```

### Verification Criteria Checklist:
- [x] Objective-C method indexing scans 30,000+ methods dynamically from memory.
- [x] All 5 routines output `ObjC Metadata: INDEPENDENT RESOLUTION AVAILABLE` and `VERIFIED`.
- [x] Function `0x10001a718` shows 1,300 body bytes, 1,540 span, 6 ranges, and 5 gaps (240 bytes).
- [x] Functions `0x1000d4b08`, `0x1000d4c6c`, `0x100102264`, `0x1000a1d28` report contiguous layout (1 range, 0 gaps).
- [x] All 5 functions achieve `Decompilation: SUCCESS` with `decompiler.dispose()` executed cleanly.
