# 15. Waze IPA Original Binary Build Feasibility & Repackaging Report

**Document ID:** `15_original_binary_repackaging.md`  
**Target Reference:** `waze.ipa` (v5.22.0, Build 1)  
**Main Binary:** `Payload/Waze.app/Waze` (ARM64 Mach-O, 141,425,424 bytes)  
**Main Binary SHA-256:** `0c40c247228439e2b75baca181569c75c144918561a8177e9399b183b5709d80`  
**Host Environment:** Arch Linux x86_64, Antigravity IDE, Ghidra 12.1.2, REA 6.5.0  
**Branch:** `research/original-ipa-packaging`  
**Date:** 2026-10-16  

---

## Executive Summary

This investigation evaluates two distinct technical pathways for working with the unencrypted Waze iOS application bundle:
1. **Approach 1 — Source Reconstruction:** Feasibility of recovering a compilable, complete original Xcode project from Ghidra and REA decompilation.
2. **Approach 2 — Original Binary Repackaging:** Feasibility of packaging the existing, unencrypted ARM64 Mach-O binaries, frameworks, extensions, and assets into a structurally valid IPA suitable for developer-managed signing and local hardware testing.

### Key Conclusions:
- **Approach 1 is IMPOSSIBLE from Static Analysis Alone:** The 141.42 MB stripped binary contains over 614,000 internal database symbols, hundreds of proprietary Google/Waze C++ monorepo dependencies (`//maps/mobile/waze/...`), Protobuf message definitions, and specialized build configurations. Decompiling assembly to high-level C pseudocode does not produce compilable, linkable original source code.
- **Approach 2 is TECHNICALLY VALID & VERIFIED:** The unencrypted application bundle (`cryptid=0`) was successfully audited, verified, and packaged into a structurally valid IPA (`Waze-repackaged.ipa`, 114,680,446 bytes / 109.37 MB) containing all 2,308 original assets, the main executable, Spotify framework, and two App Extensions.
- **Entitlement & Signing Constraints:** While the IPA is structurally valid, installing and running it on an iPhone requires developer-managed re-signing with an active Apple Developer provisioning profile. Core App Store capabilities that rely on Google-owned identifiers (CarPlay, Apple Push Notifications, Associated Domains, App Attest, and Keychain Sharing) cannot be transferred to an independent developer team.

---

## 1. PHASE A — Feasibility Assessment

### 1.1. Approach 1 — Source Reconstruction Feasibility

| Assessment Category | Empirical Status | Technical Findings |
|:---|:---:|:---|
| **Compilable Project Recovery** | **NOT FEASIBLE** | Ghidra and REA output decompiled C pseudocode intended for human analysis, not valid, compilable Objective-C++ or Swift source files. |
| **Missing Dependencies** | **CRITICAL BLOCKER** | Hundreds of internal monorepo modules (`WazeCore`, `WazeNavigationGuidance`, `WazeCarPlay`, `CAC...`) are compiled into a single monolithic binary. Source interfaces and header files are unavailable. |
| **Data Models & Schemas** | **PARTIALLY OBSERVED** | Protobuf messages can be identified by error strings, but original `.proto` definition files are missing. |
| **Build Configuration** | **MISSING** | Google internal Bazel/Blaze build rules, compiler flags, and link scripts are not present in release binaries. |
| **Summary** | **REJECTED** | Source reconstruction cannot yield a compilable original Waze application. No claim of original source recovery is made. |

### 1.2. Approach 2 — Original Binary Repackaging Feasibility

| Component | Preservation Status | Verification Method |
|:---|:---:|:---|
| **Main Executable (`Waze`)** | **PRESERVED 100% (Bit-Exact)** | 141,425,424 bytes, ARM64 Mach-O, `cryptid=0`, SHA-256: `0c40c247...` |
| **Embedded Frameworks** | **PRESERVED 100%** | `Frameworks/SpotifyiOS.framework/SpotifyiOS` (371,024 bytes, `cryptid=0`) |
| **App Extensions (PlugIns)** | **PRESERVED 100%** | `NotificationExtension.appex` (1.23 MB) & `WazeShareExtension.appex` (1.23 MB), both `cryptid=0` |
| **Application Resources** | **PRESERVED 100%** | 2,308 files including `Assets.car`, NIBs, localizations (`*.lproj`), animations, and sounds |
| **Summary** | **FEASIBLE & VERIFIED** | Repackaging preserves the original binary architecture without bytecode patching or code injection. |

---

## 2. PHASE B — Bundle Hierarchy & Entitlements Audit

### 2.1. Executable & Extension Architecture

The application bundle contains four distinct Mach-O 64-bit ARM64 binaries:

```
Payload/Waze.app/
├── Waze                                  (Main Executable, 141.42 MB, cryptid=0)
├── Frameworks/
│   └── SpotifyiOS.framework/SpotifyiOS   (Dynamic Framework, 371 KB, cryptid=0)
└── PlugIns/
    ├── NotificationExtension.appex/
    │   └── NotificationExtension         (App Extension, 1.23 MB, cryptid=0)
    └── WazeShareExtension.appex/
        └── WazeShareExtension            (App Extension, 1.23 MB, cryptid=0)
```

### 2.2. Entitlement Portability Audit

By parsing the `CSSLOT_ENTITLEMENTS` slot in the embedded code signature superblobs, the original entitlement configuration was audited:

```xml
<dict>
    <key>application-identifier</key>
    <string>UM5AE5Q8GC.com.waze.iphone</string>
    <key>com.apple.developer.team-identifier</key>
    <string>4Z5238C58P</string>
    <key>com.apple.developer.carplay-maps</key>
    <true/>
    <key>com.apple.developer.navigation-app</key>
    <true/>
    <key>aps-environment</key>
    <string>production</string>
    <key>com.apple.developer.devicecheck.appattest-environment</key>
    <string>production</string>
    <key>keychain-access-groups</key>
    <array>
        <string>UM5AE5Q8GC.com.waze.iphone</string>
        <string>UM5AE5Q8GC.com.waze.iphone.shared</string>
    </array>
    <key>com.apple.security.application-groups</key>
    <array>
        <string>group.com.waze.iphone.RealtimeOfflineSharingDefaults</string>
    </array>
    <key>com.apple.developer.associated-domains</key>
    <array>
        <string>applinks:waze.com</string>
        <string>applinks:*.waze.com</string>
    </array>
    <key>inter-app-audio</key>
    <true/>
</dict>
```

#### Transferability Matrix for Independent Developers:

| Entitlement Key | Availability to Independent Developer | Impact on Re-signed Application |
|:---|:---:|:---|
| `application-identifier` | **BLOCKED** | Must be changed to developer's own bundle ID (e.g. `com.developer.waze`). |
| `com.apple.developer.carplay-maps` | **RESTRICTED** | Requires an approved Apple Developer Special Entitlement. If omitted, CarPlay interface will not launch. |
| `aps-environment` | **BLOCKED** | APNs push notifications route through Apple to Google servers. Cannot function under third-party team ID. |
| `com.apple.developer.devicecheck.appattest-environment` | **BLOCKED** | Hardware app attestation fails when team ID does not match Google's backend registry. |
| `keychain-access-groups` | **MODIFIED** | Must be re-keyed with the new developer team prefix, or keychain queries will fail. |
| `com.apple.security.application-groups` | **MODIFIED** | Must be re-registered under developer's team ID across main app and both extensions. |
| `com.apple.developer.associated-domains` | **INACTIVE** | Universal links (`waze.com`) require domain association files hosted on Google servers. |
| `inter-app-audio` | **AVAILABLE** | Standard developer audio session entitlement. |

---

## 3. PHASE C — Packaging & Validation Workflow

A non-destructive Python packaging pipeline was created at [`scripts/repackage_and_validate.py`](../scripts/repackage_and_validate.py):

```bash
python3 scripts/repackage_and_validate.py \
    --app-dir /path/to/Payload/Waze.app \
    --output-ipa /path/to/Waze-repackaged.ipa
```

### Empirical Repackaging Metrics:
- **Input Uncompressed Size:** 224,010,478 bytes (213.63 MB)
- **Total Files Archived:** 2,308 files
- **Output IPA Size:** 114,680,446 bytes (109.37 MB)
- **Output IPA SHA-256:** `e97dae2d7887b6582bd5d0e7955c86dbd72bc40f3ca1525072527ca5769918e7`
- **ZIP File Integrity:** Passed (`zipfile.testzip()` verified with 0 CRC mismatches)
- **ARM64 Byte Preservation:** 100% bit-exact match with original unencrypted executable (`0c40c247...`)

---

## 4. PHASE D — Output Verification & Analysis Ledger

### Structured Responses to Core Audit Questions:

1. **Was original Waze source code reconstructed?**  
   **NO.** Static reverse engineering does not recover original compilable source code or build scripts.
2. **Was the original Mach-O preserved?**  
   **YES.** The original 141.42 MB unencrypted ARM64 binary (`0c40c247...`) was preserved without modifying a single instruction.
3. **Was a structurally valid IPA created?**  
   **YES.** `Waze-repackaged.ipa` (109.37 MB) contains the complete `Payload/Waze.app` hierarchy and passes ZIP structural validation.
4. **Is the output a recompiled app or a repackaged binary?**  
   **Repackaged binary.** It is an archive of the original unencrypted executable and assets.
5. **What is the output IPA size?**  
   **114,680,446 bytes** (~109.37 MB).
6. **Which Waze components remain intact?**  
   All 2,308 files: main executable, `SpotifyiOS.framework`, `NotificationExtension.appex`, `WazeShareExtension.appex`, NIBs, localizations, and assets.
7. **What signing requirements remain?**  
   The IPA currently retains the revoked/App Store distribution signature (`_CodeSignature/CodeResources`). To install on an iOS device, it **must be re-signed** using an active Apple Developer certificate (Development or Ad-Hoc) along with an `embedded.mobileprovision` file.
8. **Are required entitlements available to an independent developer?**  
   **NO.** Several core entitlements (`com.apple.developer.carplay-maps`, Google-team App Groups, App Attest, and APNs push environments) cannot be issued to an arbitrary developer account.
9. **Can the IPA be expected to install on an iPhone?**  
   **YES, under developer sideloading tools** (e.g., AltStore, Sideloadly, or `codesign + ldid`), provided the bundle identifier is re-keyed to the developer's team and an active provisioning profile is embedded.
10. **Which App Store functions might fail after independent signing?**  
    - **Push Notifications (APNs):** Server-side token mismatch.
    - **CarPlay Head-Unit Rendering:** Unless Apple approves the CarPlay entitlement for the test certificate.
    - **App Attest & DeviceCheck:** Backend verification against Google servers may reject the altered certificate hash.
    - **Universal Links (`waze.com`):** Domain ownership verification fails.
    - **Shared App Extensions:** If bundle identifiers and App Groups are not synchronized across all three targets.
11. **What testing is required to verify actual functionality?**  
    A physical iPhone field test running iOS 16.0–17.x with sideloading tools to verify whether local GPS tracking, offline routing cache, and local UI rendering operate when severed from Google cloud authentication.

---

## 5. Artifact & Repository Index

- Repackaging Automation Script: [`scripts/repackage_and_validate.py`](../scripts/repackage_and_validate.py)
- Packaging CI Workflow: [`.github/workflows/validate-repackaging.yml`](../.github/workflows/validate-repackaging.yml)
- User Signing & Sideloading Guide: [`docs/signing_and_sideloading_guide.md`](../docs/signing_and_sideloading_guide.md)
