# Empirical Function Verification Results (Phase 1.4 & 1.4.1)

**Target Binary:** `Waze` (ARM64 iOS Executable, `waze.ipa` v5.22.0)  
**Binary Size:** 141,425,424 bytes (`0x86e0df0`, `134.87 MiB`)  
**SHA-256:** `0c40c247228439e2b75baca181569c75c144918561a8177e9399b183b5709d80`  
**Analysis Engine:** Ghidra 12.1.2 Headless Analyzer (`analyzeHeadless`) & REA 6.5.0  
**Verification Date:** 2026-10-16  
**Host Environment:** Arch Linux x86_64, OpenJDK 27  
**Automation Script:** [`scripts/TargetAnalysis.java`](../scripts/TargetAnalysis.java)

---

## 1. Function Verification Summary Table

All virtual addresses are based on Mach-O 64-bit load base `0x100000000`.

| Virtual Address | Owning Class | Independently Verified Selector | Type Signature | Inclusive Address Span | Body Bytes (Span) | Inst Count | CFG Blocks | Contiguous? | Decomp Time | Warnings | Status |
|:---|:---|:---|:---|:---|:---:|:---:|:---:|:---:|:---:|:---:|:---:|
| `0x10001a718` | `AlternateRoutesStateMachineBridge` | `applyRouteUpdateWithRouteUpdateProtos:` | `v24@0:8@16` | `0x10001a718` - `0x10001ad1b` | 1,300 B (1,540 B) | 325 | 43 | NO (6 ranges, 5 gaps) | 244 ms | 2 | **VERIFIED** |
| `0x1000d4b08` | `MainCanvasViewHolder` | `init` | `@16@0:8` | `0x1000d4b08` - `0x1000d4beb` | 228 B (228 B) | 57 | 3 | YES (1 range, 0 gaps) | 16 ms | 0 | **VERIFIED** |
| `0x1000d4c6c` | `MainCanvasViewHolder` | `makeGenericCanvasActivator` | `@16@0:8` | `0x1000d4c6c` - `0x1000d4cab` | 64 B (64 B) | 16 | 1 | YES (1 range, 0 gaps) | 7 ms | 2 | **VERIFIED** |
| `0x100102264` | `NavigationGuidanceReducerBridge` | `distanceToCrossSegmentWith:` | `q24@0:8q16` | `0x100102264` - `0x1001023eb` | 392 B (392 B) | 98 | 20 | YES (1 range, 0 gaps) | 30 ms | 0 | **VERIFIED** |
| `0x1000a1d28` | `WZWazeLocationServiceBridge` | `currentSpeed` | `@16@0:8` | `0x1000a1d28` - `0x1000a1d7f` | 88 B (88 B) | 22 | 5 | YES (1 range, 0 gaps) | 7 ms | 2 | **VERIFIED** |

**Verification Totals:**
- Total Target Routines: 5 / 5 (100.0%)
- Disassembly Succeeded: 5 / 5 (100.0%)
- Function Models Established: 5 / 5 (100.0%)
- Objective-C Metadata Independently Verified: 5 / 5 (100.0%)
- Decompilation Succeeded: 5 / 5 (100.0%)
- Total Compiled ARM64 Executable Body: 2,072 bytes (518 instructions) across 72 basic blocks
- Objective-C Metadata Index Time: 348 ms (30,279 methods indexed)
- Total Decompilation Execution Time: 304 ms (average 60.8 ms/function)

---

## 2. Independent Verification Levels

To prevent over-claiming or conflating syntactic decompilation with algorithmic proof, four separate verification levels are maintained:

1. **Level 1 — Successfully Decoded Instructions:**
   Every 32-bit ARM64 opcode within the function body is disassembled into valid, standard mnemonic instructions without undefined instruction traps or decoding gaps.
2. **Level 2 — Decompiled Functions:**
   Ghidra's decompiler finishes AST construction, high-level C pseudocode recovery, and parameter reconstruction (`decompileCompleted() == true`) within the execution budget, logging any decompiler warning pragmas.
3. **Level 3 — Correctly Identified Runtime Methods:**
   Owning class name, selector name, and method type encodings are confirmed by reading Mach-O 64-bit runtime structures (`__objc_classlist`, `class_ro_t`, relative method tables in `__objc_methlist`, and chained fixup references in `__objc_selrefs`), rather than echoing hardcoded literals.
4. **Level 4 — Understood Algorithmic Behavior:**
   Control-flow structures, call graphs, assertions, logging strings, and state transformations are traced and mapped to the application's domain logic.

---

## 3. Function Boundary Audit & The 1,300 vs. 1,540 Byte Discrepancy

### 3.1. Mathematical Root Cause Analysis (`0x10001a718`)

During Phase 1.4 review, an apparent discrepancy was noted for `0x10001a718`:
- Start Address: `0x10001a718`
- End Address: `0x10001ad1b`
- Inclusive Address Span: `0x10001ad1b - 0x10001a718 + 1` = **1,540 bytes**
- Function Body Byte Count: **1,300 bytes** (`body.getNumAddresses()`)

**Audit Finding:** The function body is **non-contiguous**. The 240-byte difference (`1,540 - 1,300 = 240 bytes`) consists of five internal code gaps excluded from the primary function body by the compiler and Ghidra's CFG model.

#### Body Address Ranges (6 Ranges = 1,300 bytes / 325 instructions):
1. **Range 0:** `0x10001a718` - `0x10001aba3` (1,164 bytes, 291 instructions) — Function prologue, Protobuf deserialization dispatch, state machine calls.
2. **Range 1:** `0x10001ac24` - `0x10001ac2b` (8 bytes, 2 instructions) — Intermediate cleanup block.
3. **Range 2:** `0x10001ac30` - `0x10001ac3b` (12 bytes, 3 instructions) — Cleanup dispatch.
4. **Range 3:** `0x10001ac80` - `0x10001ac8b` (12 bytes, 3 instructions) — Exception handling branch block.
5. **Range 4:** `0x10001acb0` - `0x10001acc3` (20 bytes, 5 instructions) — Shared object destruction block.
6. **Range 5:** `0x10001acc8` - `0x10001ad1b` (84 bytes, 21 instructions) — Unwind resume (`__Unwind_Resume`), stack canary verification (`___stack_chk_fail`), epilogue, and `ret`.

$$\text{Total Body Bytes} = 1164 + 8 + 12 + 12 + 20 + 84 = 1,300\text{ bytes}$$

#### Excluded Gaps (5 Gaps = 240 bytes / 60 instructions):
1. **Gap 0:** `0x10001aba4` - `0x10001ac23` (128 bytes, 32 instructions)
2. **Gap 1:** `0x10001ac2c` - `0x10001ac2f` (4 bytes, 1 instruction)
3. **Gap 2:** `0x10001ac3c` - `0x10001ac7f` (68 bytes, 17 instructions)
4. **Gap 3:** `0x10001ac8c` - `0x10001acaf` (36 bytes, 9 instructions)
5. **Gap 4:** `0x10001acc4` - `0x10001acc7` (4 bytes, 1 instruction)

$$\text{Total Gap Bytes} = 128 + 4 + 68 + 36 + 4 = 240\text{ bytes}$$
$$\text{Total Span} = 1,300\text{ body bytes} + 240\text{ gap bytes} = 1,540\text{ bytes}$$

#### Gap Instruction Content:
Disassembly of the gap regions reveals that they contain C++/Objective-C++ exception landing pads and cold cleanup sequences:
- `mov x20, x0`: Saves exception pointer into callee-saved register `x20`.
- Destructor invocations: Calls to `0x1045d5f04`, `0x1045d5ef8`, `0x1045d5eec`, `0x1045d5ee0`, and `0x103e60e04` to clean up stack-allocated Protobuf message buffers.
- Branches: Direct jumps to shared cleanup nodes at `0x10001acac` and `0x10001acb0`.

Under Clang/LLVM optimization for ARM64, exception landing pads and cold cleanup paths are scheduled at the function tail with non-contiguous control flow, resulting in distinct basic block clusters that Ghidra isolates into non-contiguous ranges.

### 3.2. Boundary Audit Across All Five Targets

| Function Address | Inclusive Address Span | Body Bytes | Gaps | Contiguous? | Adjacent Next Entry |
|:---|:---:|:---:|:---:|:---:|:---|
| `0x10001a718` | 1,540 B | 1,300 B | 5 (240 B) | **NO** | `0x10001ad1c` (`sub_10001ad1c`) |
| `0x1000d4b08` | 228 B | 228 B | 0 (0 B) | **YES** | `0x1000d4bec` (`sub_1000d4bec`) |
| `0x1000d4c6c` | 64 B | 64 B | 0 (0 B) | **YES** | `0x1000d4cac` (`makeWazeMapCanvasActivator`) |
| `0x100102264` | 392 B | 392 B | 0 (0 B) | **YES** | `0x1001023ec` (`sub_1001023ec`) |
| `0x1000a1d28` | 88 B | 88 B | 0 (0 B) | **YES** | `0x1000a1d80` (`currentLocation`) |

---

## 4. Independent Objective-C Metadata Resolution

Rather than relying on hardcoded strings, [`scripts/TargetAnalysis.java`](../scripts/TargetAnalysis.java) dynamically walks Mach-O 64-bit runtime structures:

1. **Class Walking (`__objc_classlist`):**
   Reads array of pointers to `objc_class` structs in `__objc_data`.
   For each class, reads `class_ro_t` pointer from `bits & 0x7ffffffffff8L`.
   Extracts `name` string from `__objc_classname` and `baseMethodList` pointer from `__objc_const` / `__objc_methlist`.
2. **Relative Method List Parsing (`__objc_methlist`):**
   Decodes `flags_or_entsize` (`0x8000000c`) and `count`.
   Each 12-byte relative entry is decoded via relative offsets:
   - `name_offset`: Address of selref = `entry_addr + name_offset`
   - `types_offset`: Address of type string = `entry_addr + 4 + types_offset`
   - `imp_offset`: Address of implementation = `entry_addr + 8 + imp_offset`
3. **Chained Fixup Resolution (`__objc_selrefs`):**
   Reads 64-bit pointer in `__objc_selrefs`. Unchains modern dyld rebase pointer:
   $$\text{target\_addr} = 0x100000000 + (\text{raw\_val} \ \& \ 0xfffffffff)$$
   Reads null-terminated selector string in `__TEXT.__objc_methname`.

### Empirical Resolution Evidence:

```
[TARGET 1] 0x10001a718
  - Owning Class:       AlternateRoutesStateMachineBridge
  - Selector Name:      applyRouteUpdateWithRouteUpdateProtos:
  - Type Encoding:      v24@0:8@16
  - Method Table Entry: 0x10001a718 (MethList: 0x1046845b8, SelRef: 0x107ee0ab8 -> 0x104bffcc2)
  - Verification:       VERIFIED

[TARGET 2] 0x1000d4b08
  - Owning Class:       MainCanvasViewHolder
  - Selector Name:      init
  - Type Encoding:      @16@0:8
  - Method Table Entry: 0x1000d4b08 (MethList: 0x1046a0c90, SelRef: 0x107ee8b90 -> 0x104c40430)
  - Verification:       VERIFIED

[TARGET 3] 0x1000d4c6c
  - Owning Class:       MainCanvasViewHolder
  - Selector Name:      makeGenericCanvasActivator
  - Type Encoding:      @16@0:8
  - Method Table Entry: 0x1000d4c6c (MethList: 0x1046a0c90, SelRef: 0x107eeca90 -> 0x104c55df0)
  - Verification:       VERIFIED

[TARGET 4] 0x100102264
  - Owning Class:       NavigationGuidanceReducerBridge
  - Selector Name:      distanceToCrossSegmentWith:
  - Type Encoding:      q24@0:8q16
  - Method Table Entry: 0x100102264 (MethList: 0x1046a48c8, SelRef: 0x107ee5118 -> 0x104c1ab06)
  - Verification:       VERIFIED

[TARGET 5] 0x1000a1d28
  - Owning Class:       WZWazeLocationServiceBridge
  - Selector Name:      currentSpeed
  - Type Encoding:      @16@0:8
  - Method Table Entry: 0x1000a1d28 (MethList: 0x1046b8d00, SelRef: 0x107ee41c0 -> 0x104c1505e)
  - Verification:       VERIFIED
```

---

## 5. Decompiler Execution Details & Compiler Warnings

| Address | Selector | Duration | Output Lines | Warnings | Warning Text |
|:---|:---|:---:|:---:|:---:|:---|
| `0x10001a718` | `applyRouteUpdateWithRouteUpdateProtos:` | 244 ms | 292 | 2 | `Possible PIC construction at 0x00010001a840: Changing call to branch`; `Removing unreachable block (ram,0x00010001a844)` |
| `0x1000d4b08` | `init` | 16 ms | 33 | 0 | `NONE` |
| `0x1000d4c6c` | `makeGenericCanvasActivator` | 7 ms | 15 | 2 | `Could not recover jumptable at 0x0001045d5d68. Too many branches`; `Treating indirect jump as call` |
| `0x100102264` | `distanceToCrossSegmentWith:` | 30 ms | 147 | 0 | `NONE` |
| `0x1000a1d28` | `currentSpeed` | 7 ms | 20 | 2 | `Could not recover jumptable at 0x0001045d5d68. Too many branches`; `Treating indirect jump as call` |

### Note on Warnings:
- The PIC warning at `0x10001a840` is an ARM64 PC-relative offset normalization in Ghidra's AST simplifier.
- The jumptable warnings in routines `0x1000d4c6c` and `0x1000a1d28` refer to the shared external tail-call dispatcher at `0x1045d5d68` (`_objc_autoreleaseReturnValue` stub), which decompiles cleanly as an indirect tail-call call/return.

---

## 6. Reproducibility

Execute the independent validation script directly inside the headless Ghidra environment:

```bash
/opt/ghidra/support/analyzeHeadless /tmp/ghidra_proj WazeTest \
    -process Waze \
    -scriptPath scripts \
    -postScript TargetAnalysis.java \
    -noanalysis \
    -readOnly
```

Complete execution log is preserved in [`reports/09_target_analysis_validation.md`](../reports/09_target_analysis_validation.md).
