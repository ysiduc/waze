# 01. iOS IPA Structure & Packaging Analysis

**Target Artifact:** `waze.ipa` (iOS Application Package)  
**Host Environment:** Arch Linux x86_64  
**Integrity Policy:** Read-only inspection of original artifact; all inspection performed on extracted working copy  
**Compliance Note:** Analysis is strictly static and educational; zero proprietary assets or binary files are redistributed  

---

## 1. Archive & Package Verification

| Metric | Measured Value | Verification Method |
|---|---|---|
| **Archive File** | `waze.ipa` | Local filesystem path |
| **File Size** | 114,712,520 bytes (~109.40 MiB / 114.71 MB) | System stat utility |
| **SHA-256 Digest** | `78c54a3db510c7d2142baeb13dd773c2f7774a3e4d99fb9a4cc966941086a158` | Standard sha256sum |
| **Format** | Standard ZIP / iOS Application Package (IPA) | REA `inspect_artifact` |
| **Archive Entry Count** | 2,435 occurrences (2,309 files, 126 directories) | Archive entry audit |
| **Payload Directory** | `Payload/` | Canonical iOS IPA layout |
| **Application Bundle** | `Payload/Waze.app` | Root iOS bundle |
| **Decryption Marker** | `Payload/decrypt.day` | Present in dump (contains marker `und3fined`) |

---

## 2. Application Bundle Metadata (`Info.plist`)

Extracted and validated from `Payload/Waze.app/Info.plist`:

| Parameter | Value | Technical Context |
|---|---|---|
| **Bundle Identifier** | `com.waze.iphone` | Canonical App Store bundle ID |
| **Display Name** | `Waze` | User-facing title |
| **Short Version** | `5.22.0` | Semantic marketing release |
| **Bundle Version** | `1` | Internal build revision |
| **Minimum OS Version** | `16.0` | Target deployment constraint |
| **Target SDK** | `26.4.0` (Darwin platform 2) | Compiled with Apple iOS SDK |
| **Device Family** | `[1, 2]` | Universal binary supporting iPhone (`1`) and iPad (`2`) |
| **Required Capabilities** | `arm64` | Pure 64-bit ARM architecture |
| **Background Modes** | `audio`<br>`external-accessory`<br>`fetch`<br>`location`<br>`remote-notification` | Background GPS tracking, turn-by-turn voice prompts, and vehicle accessory integration |
| **Transport Security** | `NSAppTransportSecurity: None` | Standard Apple networking configuration |

### Registered URL Schemes
The application declares handling for the following custom URL schemes:
- `waze`: Standard deep-linking scheme (e.g., `waze://?ll=...`)
- `wazeapi`: Primary external integration scheme
- `wazeapi2`: Extended API integration scheme
- `wazespotify`: Embedded Spotify audio streaming scheme
- `geo-navigation`: Generic geographic navigation integration
- `com.waze.iphone`: Application bundle scheme
- Google OAuth URL schemes:
  - `com.googleusercontent.apps.1005457359603-jo7ffs7snngbe76afbu2qt7egpgv9oka`
  - `com.googleusercontent.apps.2371140425-cuqdf8f2jqb45km4po28or3sf9msds68`

### Privacy & Hardware Usage Declarations
- `NSBluetoothAlwaysUsageDescription` / `NSBluetoothPeripheralUsageDescription`: Bluetooth accessory pairing and beacon-based tunnel navigation.
- `NSLocationAlwaysAndWhenInUseUsageDescription` / `NSLocationAlwaysUsageDescription`: Continuous GPS navigation and route computation.
- `NSMotionUsageDescription`: Motion coprocessor queries for automatic parking location detection.
- `NSSpeechRecognitionUsageDescription` / `NSMicrophoneUsageDescription`: Voice commands and hands-free hazard reporting.
- `NSExternalAccessory`: Accessory protocol support for vehicle infotainment and head units.

---

## 3. Binary Executables Inventory

Inside the extracted `Waze.app` bundle, exactly four Mach-O binary targets were discovered:

| Binary Relative Path | Size | Mach-O Type | Architecture | CryptID |
|---|---|---|---|---|
| `Waze` (Main binary) | 141,425,424 B (~141.4 MB) | `MH_EXECUTE` | `arm64` | `0` (Decrypted) |
| `Frameworks/SpotifyiOS.framework/SpotifyiOS` | 371,024 B (~371 KB) | `MH_DYLIB` | `arm64` | `0` (Decrypted) |
| `PlugIns/NotificationExtension.appex/NotificationExtension` | 1,227,216 B (~1.23 MB) | `MH_EXECUTE` | `arm64` | `0` (Decrypted) |
| `PlugIns/WazeShareExtension.appex/WazeShareExtension` | 1,226,624 B (~1.23 MB) | `MH_EXECUTE` | `arm64` | `0` (Decrypted) |

### FairPlay DRM Status
Each binary was inspected via Mach-O load commands `LC_ENCRYPTION_INFO` (`0x21`) and `LC_ENCRYPTION_INFO_64` (`0x2C`):
- **Result:** In all 4 executables, `cryptid = 0`.
- **Significance:** The executables are unencrypted. Disassembly and static analysis engines can map and decompile machine instructions and data sections without runtime DRM decryption.

---

## 4. Main Executable Mach-O Architecture (`Waze`)

### Header Properties
- **Magic:** `0xcffaedfe` (`MH_MAGIC_64` in host little-endian)
- **CPU Type:** `0x0100000c` (`CPU_TYPE_ARM64`)
- **CPU Subtype:** `0` (`CPU_SUBTYPE_ARM64_ALL`)
- **File Type:** `2` (`MH_EXECUTE`)
- **Load Commands:** 117 commands totaling 13,088 bytes
- **Flags:** `0x00a10085` (`NOUNDEFS | DYLDLINK | TWOLEVEL | BINDS_TO_WEAK | PIE | HAS_TLV_DESCRIPTORS`)
- **Binary UUID:** `4556fa71-0a76-3117-b160-07139913ce8d`

### Memory Segments

| Segment | Sections | VM Address | VM Size | File Offset | File Size | Description |
|---|---|---|---|---|---|---|
| `__PAGEZERO` | 0 | `0x0` | `0x100000000` (4 GB) | `0x0` | `0x0` | Null-pointer trap |
| `__TEXT` | 28 | `0x100000000` | `0x7a14000` (~122 MB) | `0x0` | `0x7a14000` | Native ARM64 code, strings, Swift/Obj-C metadata |
| `__DATA_CONST` | 15 | `0x107a14000` | `0x30c000` (~3.0 MB) | `0x7a14000` | `0x30c000` | GOT, Class lists, CFStrings |
| `__DATA` | 14 | `0x107d20000` | `0xa68000` (~10.4 MB) | `0x7d20000` | `0x560000` | Objective-C runtime storage, globals, BSS |
| `__LINKEDIT` | 0 | `0x108788000` | `0x460000` (~4.4 MB) | `0x8280000` | `0x45fb10` | Symbol tables, code signatures |

#### Key Subsections in `__TEXT`
- `__text`: Virtual `0x100004000` – `0x1045cebb4` (73.1 MB of ARM64 native machine instructions).
- `__objc_methname`: 1,150,773 bytes of Objective-C method selector names.
- `__objc_classname`: 350,475 bytes of Objective-C class names (6,994 unique classes discovered).
- `__objc_methtype`: 322,153 bytes of method type signatures.
- `__cstring`: 3,616,074 bytes (103,458 string constants, containing Google internal repo paths).
- `__swift5_reflstr`: 396,529 bytes (19,404 Swift reflection property/field names).
- `__swift5_typeref`: 580,296 bytes of Swift type metadata descriptors.
- `__swift5_fieldmd`: 331,188 bytes of Swift field metadata.

---

## 5. Embedded Frameworks & Extensions

### Embedded Frameworks
- `Frameworks/SpotifyiOS.framework`: Embedded dynamic framework for third-party Spotify audio control.

### App Extensions (`PlugIns`)
1. **`NotificationExtension.appex`**: iOS `UserNotifications` service extension for handling rich push notifications, parsing custom payload attachments, and pre-rendering alerts.
2. **`WazeShareExtension.appex`**: iOS Share extension for sharing coordinates, routes, and ETAs from system share sheets.

---

## 6. Resource Bundles & Graphics

- **Asset Catalogs (`.car`):** 25 `.car` files (primary `Assets.car` at 25.5 MB, and 24 modular feature asset catalogs inside `.bundle` directories).
- **Modular Bundles (29 total):** Internal feature modularity (e.g., `waze_WazeCarPlayImplementation.bundle`, `waze_WazeAlertReportUIImplementation.bundle`, `waze_WazeAlternateRoutesImplementation.bundle`, `gRPCCertificates.bundle`).
- **Metal Shader Library:** `default.metallib` (67,042 bytes) containing compiled Apple Metal GPU shaders (`BlurVertexShader`, `BlurFragmentShader`, `SimpleTextureVertexShader`, `SimpleTextureFragmentShader`).
- **UI Views & Animations:** 58 compiled `.nib` views, 1 `LaunchScreen.storyboardc`, and 75 Lottie `.json` animation configuration files.

---

## 7. Security Entitlements

Extracted from Mach-O `LC_CODE_SIGNATURE` SuperBlob (`0x8383840`):
- `com.apple.developer.carplay-maps`: `true`
- `com.apple.developer.navigation-app`: `true`
- `com.apple.external-accessory.wireless-configuration`: `true`
- `application-identifier`: `UM5AE5Q8GC.com.waze.iphone`
- `com.apple.developer.team-identifier`: `4Z5238C58P`
- `aps-environment`: `production`
- `keychain-access-groups`: `UM5AE5Q8GC.com.waze.iphone`, `UM5AE5Q8GC.com.waze.iphone.shared`
- `associated-domains`: `applinks:waze.com`, `applinks:*.waze.com`
