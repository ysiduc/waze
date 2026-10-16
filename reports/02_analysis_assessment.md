# 02. Technical Environment & Analysis Capability Assessment

**Target Application:** Waze iOS (`com.waze.iphone` v5.22.0)  
**Host Platform:** Arch Linux x86_64  
**Tooling Environment:** REA (`rea-agents@6.5.0`), Ghidra 12.1.2-2, OpenJDK 27, Python 3.14.8  
**Report Type:** Tooling Verification & Technical Boundary Assessment  

---

## 1. Verified Inspection Scope

| Category | File Path / Identifier | Inspection Method | Key Result |
|---|---|---|---|
| **Archive Target** | `waze.ipa` | REA `open_binary`, `inspect_artifact` | Valid IPA archive; 2,436 entries cataloged |
| **Main Binary** | `Payload/Waze.app/Waze` | Python Mach-O parser, Ghidra 12.1.2 | ARM64 Mach-O `MH_EXECUTE`, `cryptid=0` |
| **Plugin Binary** | `NotificationExtension` | Ghidra 12.1.2 via REA | Disassembly and pseudocode verified |
| **Plugin Binary** | `WazeShareExtension` | Python Mach-O parser, `file` | ARM64 Mach-O `MH_EXECUTE`, `cryptid=0` |
| **Embedded Framework** | `SpotifyiOS` | Python Mach-O parser, `file` | ARM64 Mach-O `MH_DYLIB`, `cryptid=0` |
| **Configuration** | `Info.plist` | Python `plistlib` | Bundle ID, min iOS 16.0, URL schemes, background modes |
| **Security Entitlements** | Mach-O `LC_CODE_SIGNATURE` | Python binary slice | Extracted full XML entitlements (`carplay-maps`, etc.) |
| **Shaders** | `default.metallib` | `strings`, binary inspection | Apple Metal vertex and fragment shaders identified |
| **Metadata Sections** | `__objc_*`, `__swift5_*`, `__cstring` | Python section inspection | >103k C-strings, 6.9k Obj-C classes, 19.4k Swift strings |

---

## 2. Technical Limitations & Non-Inspected Elements

| Target Element | Intended Inspection | Blocker / Limitation | Root Cause |
|---|---|---|---|
| `Assets.car` (25.5 MB) & bundle `.car` files | Extract individual PNG/SVG assets | Host limitation (`unsupported_host`) | Apple compiled `.car` asset catalogs require macOS native `assetutil` or external extractor tool. |
| Native UI / Process Traces | Live runtime capture | Host limitation (`unsupported_host`) | iOS UI scenario capture and native trace tools require physical iOS hardware or macOS simulator. |
| Monolithic Full-Program Decompilation (`Waze` 141 MB) | Single-pass decompile of all 73 MB code | Resource & time budget | 141 MB ARM64 binary with tens of thousands of functions requires selective scoped analysis in Ghidra. |

---

## 3. REA (Reverse Engineer Anything) Integration Status

**Status: VERIFIED & OPERATIONAL**

- **MCP Server Connection:** Running via `rea-agents@6.5.0` within Antigravity IDE.
- **Provider Status:**
  - `rea-artifact-graph`: Operational. Successfully cataloged 2,282 nodes and 2,436 occurrences in `waze.ipa`.
  - `ghidra` analysis provider: Operational. Correctly bound to `/opt/ghidra` (version 12.1.2) with Java 27 OpenJDK.
  - `native-macos` provider: Correctly reports `unsupported_host` on Linux as designed.
- **Observed Operations Verified:**
  - `binary_session`: Returns complete provider status and health.
  - `open_binary`: Successfully mounts both archives (`format: "ipa"`) and Mach-O executables (`format: "mach-o"`).
  - `inspect_artifact`: Successfully inventories package hierarchy.
  - `list_segments`: Discovers memory blocks with permissions directly from Ghidra.
  - `list_procedures`: Enumerates analyzed functions and distinguishes thunks/externals.
  - `procedure_assembly`: Generates ARM64 assembly listings.
  - `procedure_pseudo_code`: Generates high-level decompiler pseudocode.
  - `close_binary`: Cleans up session and ephemeral Ghidra analysis databases safely.

---

## 4. Ghidra Integration Status

**Status: VERIFIED & OPERATIONAL**

- **Installation Directory:** `/opt/ghidra`
- **Ghidra Version:** `12.1.2` (Application properties build verified)
- **JVM Environment:** OpenJDK 27 (`/usr/lib/jvm/java-27-openjdk`)
- **Headless Analyzer:** `/opt/ghidra/support/analyzeHeadless`
- **Native Decompiler:** `/opt/ghidra/Features/Decompiler/os/linux_x86_64/decompile` (ELF x86_64 native decompiler executable)
- **Observed Environment Constraint:**
  - Ghidra's `NamingUtilities.checkName` rejects project paths where any directory element starts with a dot `.` (such as `.gemini`). Storing projects in non-dot directories (such as `/tmp/ghidra_proj`) completely circumvents this issue.
- **Analysis Performance:**
  - `NotificationExtension` (1.23 MB): Auto-analysis completed in under 100 seconds; decompilation of procedure `0x100004000` succeeded.
  - `Waze` Main Executable (141.4 MB): Headless import completed in 39.40s; symbol table of 614,321 entries generated; test batch of 20 functions decompiled with 100% success (average <15 ms per function).

---

## 5. Metadata Availability

While private non-exported C/C++ function symbols in the global symbol table are stripped (`Defined symbols: 1`), rich runtime metadata is fully intact:
1. **Objective-C Runtime Metadata:** 6,994 class names in `__objc_classname`, 5,677 registered class definitions in `__objc_classlist`, 1.15 MB of selector names in `__objc_methname`, and 487 KB in `__objc_methlist`.
2. **Swift 5 Runtime Reflection:** 19,404 property and type names in `__swift5_reflstr`, type descriptors in `__swift5_types`, and protocol records.
3. **Internal Google Source Hierarchy:** 103,458 C-string constants containing source assertion file paths (e.g. `third_party/waze/client/...`).

---

## 6. Recommended Next Steps for Authorized Research

1. **Scoped Protocol & State Machine Extraction:**
   - Map dependencies between navigation, location, and audio announcement modules using Objective-C selector references and Swift reflection metadata.
2. **Focused Ghidra Procedure Analysis:**
   - Run targeted decompilation queries on specific identified controllers (e.g., `NavigationGuidanceReducerBridge`, `AlternateRoutesStateMachineBridge`).
3. **Clean-Room Specification:**
   - If developing independent client interoperability, document data models, coordinate representations, and turn-event schemas derived from metadata to create independent, clean-room software designs.
