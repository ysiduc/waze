# Analysis Statistics & Quantitative Metrics

This document compiles all quantitative benchmarks, file metrics, and metadata statistics captured during static analysis of `waze.ipa` on Arch Linux.

---

## 1. Artifact & Binary Dimensions

| File Identifier | Size (Bytes) | Size (Human) | SHA-256 Digest | Format |
|---|---|---|---|---|
| `waze.ipa` (Archive) | 115,221,416 | 109.88 MB | `78c54a3db510c7d2142baeb13dd773c2f7774a3e4d99fb9a4cc966941086a158` | ZIP / IPA archive |
| `Waze` (Main Binary) | 141,425,424 | 141.42 MB | `0c40c247228439e2b75baca181569c75c144918561a8177e9399b183b5709d80` | Mach-O 64-bit ARM64 |
| `NotificationExtension` | 1,227,216 | 1.23 MB | `4b2985714dbbbc9a583eb983c1f4638bfd641d37df6b83027b93bcca2caa5330` | Mach-O 64-bit ARM64 |
| `WazeShareExtension` | 1,226,624 | 1.23 MB | `e6191c0e3579fa0c6550269bf1bb23ea515d68d1ea00995faea9787c93608796` | Mach-O 64-bit ARM64 |
| `SpotifyiOS.framework` | 371,024 | 371.02 KB | `a908a8d16790bcfc70a8039c27b03a891823ebdfdaecde5c2cf788fb7c34ce28` | Mach-O 64-bit dylib |

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

## 4. Ghidra Headless Analyzer Benchmarks

| Benchmark Metric | Measured Result |
|---|---|
| **Import Duration (Waze 141 MB)** | 39.400 seconds |
| **Target Loader** | Apple Silicon ARM64 Swift (`AARCH64:LE:64:AppleSilicon:swift`) |
| **Total Program Symbols** | 614,321 symbols |
| **Initial Identified Procedures** | 5,681 procedures |
| **Test Decompilation Batch Size** | 20 representative procedures |
| **Decompilation Success Rate** | 20 / 20 (100%) |
| **Decompilation Failure Rate** | 0 / 20 (0%) |
| **Average Decompilation Duration** | ~11.5 ms per function |
| **Shortest Decompilation** | 4 ms (`_$s10Foundation10URLRequestV15timeoutIntervalSdvs`) |
| **Longest Decompilation** | 212 ms (`entry` / `_UIApplicationMain`) |
