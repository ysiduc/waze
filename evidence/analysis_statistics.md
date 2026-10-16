# Analysis Statistics & Quantitative Metrics

This document compiles all quantitative benchmarks, file metrics, and metadata statistics captured during static analysis of `waze.ipa` on Arch Linux.

---

## 1. Artifact & Binary Dimensions

| File Identifier | Size (Bytes) | Size (Human) | SHA-256 Digest | Format |
|---|---|---|---|---|
| `waze.ipa` (Archive) | 115,221,416 | 109.88 MB | `78c54a3db510c7d2142baeb13dd773c2f7774a3e4d99fb9a4cc966941086a158` | ZIP / IPA archive |
| `Waze` (Main Binary) | 141,425,424 | 141.42 MB / 134.87 MiB | `0c40c247228439e2b75baca181569c75c144918561a8177e9399b183b5709d80` | Mach-O 64-bit ARM64 |
| `NotificationExtension` | 1,227,216 | 1.23 MB / 1.17 MiB | `4b2985714dbbbc9a583eb983c1f4638bfd641d37df6b83027b93bcca2caa5330` | Mach-O 64-bit ARM64 |
| `WazeShareExtension` | 1,226,624 | 1.23 MB / 1.17 MiB | `5df1434ea011d3aa33166eb8bf8ff9b18b4ce0bfa9da137a892701b2a47f4469` | Mach-O 64-bit ARM64 |
| `SpotifyiOS.framework` | 371,024 | 371.02 KB / 362 KiB | `eb7a150a88b20247738ee714bfa10061e869719ea238e8cb5542a3cfb4d75d27` | Mach-O 64-bit dylib |
| `Assets.car` | 25,496,376 | 25.50 MB / 24.32 MiB | `a03e33adcdddf4e64f777ee3fdf96eb7d4f9bf3ae90977d24268153c301d248b` | Compiled Asset Catalog |
| `default.metallib` | 67,042 | 67.04 KB / 65.47 KiB | `c09548a3ab5a06e40d6d5eb7f76652eb6bc3203f5ad67ffb4fb5587d49868be5` | Compiled Metal Shaders |

---

## 2. Main Binary Mach-O Memory Segments

| Segment Name | VM Address Base | Virtual Size | File Offset | File Size | Section Count |
|---|---|---|---|---|---|
| `__PAGEZERO` | `0x000000000` | 4,294,967,296 (4 GB) | `0x0` | 0 B | 0 |
| `__TEXT` | `0x100000000` | 128,008,192 (~122 MB) | `0x0` | 128,008,192 B | 28 |
| `__DATA_CONST` | `0x107a14000` | 3,194,880 (~3.05 MB) | `0x7a14000` | 3,194,880 B | 15 |
| `__DATA` | `0x107d20000` | 10,911,744 (~10.41 MB) | `0x7d20000` | 5,636,096 B | 14 |
| `__LINKEDIT` | `0x108788000` | 4,587,520 (~4.38 MB) | `0x8280000` | 4,586,256 B | 0 |

---

## 3. Metadata & Section Metrics

| Metadata Category | Section / Resource | Count / Metric | Size in Bytes |
|---|---|---|---|
| **Native Code** | `__TEXT.__text` | ARM64 machine instructions | 73,182,132 B (~73.18 MB) |
| **Objective-C Classes** | `__TEXT.__objc_classname` | 6,994 class name strings | 350,475 B (~350.5 KB) |
| **Registered Classes** | `__DATA_CONST.__objc_classlist` | 5,677 class pointers | 45,416 B (~45.4 KB) |
| **Method Selectors** | `__TEXT.__objc_methname` | Selector name strings | 1,150,773 B (~1.15 MB) |
| **Method Dispatch Lists** | `__TEXT.__objc_methlist` | Relative method tables | 487,084 B (~487.1 KB) |
| **Swift Reflection Strings** | `__TEXT.__swift5_reflstr` | 19,404 property/field strings | 396,529 B (~396.5 KB) |
| **Swift Type Descriptors** | `__TEXT.__swift5_types` | Type descriptors | 23,660 B (~23.7 KB) |
| **C-String Literals** | `__TEXT.__cstring` | 103,458 string constants | 3,616,074 B (~3.62 MB) |
| **Linked Dylibs** | `LC_LOAD_DYLIB` | 95 frameworks / libraries | N/A |
| **Load Commands** | Mach-O Header | 117 load commands | 13,088 B |

---

## 4. Ghidra Headless Analyzer Benchmarks & Symbol Auditing

| Benchmark Metric | Measured Result | Technical Explanation |
|---|---|---|
| **Import Duration (Waze 141 MB)** | 39.400 seconds | Raw Mach-O import using `/opt/ghidra/support/analyzeHeadless`. |
| **Target Loader** | `AARCH64:LE:64:AppleSilicon:swift` | Ghidra Apple Silicon Swift loader specification. |
| **Raw Mach-O Symbols (`LC_SYMTAB`)** | **5,098 symbols** | Mach-O header table: 5,096 dynamic imports, 1 defined, 1 local. Production binary is stripped. |
| **Ghidra Database Labels** | **614,321 labels** | Internal Ghidra `SymbolTable` index covering data labels (`DAT_`), thunks (`PTR_`), strings (`s_`), and metadata. |
| **Initial Identified Procedures** | **5,681 procedures** | Only dynamic stubs (`__stubs`, `__objc_stubs`) and entry point created on import with `-noanalysis`. |
| **Test Decompilation Batch Size** | 20 procedures | Sample batch evaluated in `WazeAnalysisScript.java`. |
| **Decompilation Success Rate** | 20 / 20 (100%) | 19 external library stubs (`__stubs`) + 1 entry routine (`entry`). |
| **Benchmark Generalizability** | **Limited / Scoped** | Succeeded on 1-to-3 instruction library stubs; cannot be generalized to the entire 73.18 MB codebase. |
| **Average Decompilation Duration** | ~11.5 ms per function | Measured on test batch (ranges from 4 ms to 212 ms). |
| **Targeted Procedure Batch** | 6 custom procedures | Evaluated in `TargetDecompileScript.java` (`0x1001fb7f8`, `0x10001a718`, `0x1000d4b08`, etc.). |
