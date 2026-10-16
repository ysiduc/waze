# Reproducibility Manifest & Audit Verification Procedures

**Target Artifact:** Waze iOS v5.22.0 (`waze.ipa`)  
**Audit Date:** 2026-10-16  
**Auditor:** Independent Technical Audit (Phase 1.3)  
**Host System:** Arch Linux x86_64, Linux kernel 6.x  
**Security Notice:** All verification commands operate strictly in read-only mode on authorized local copies. No application binaries, proprietary assets, or credentials are published.

---

## 1. Environment & Toolchain Prerequisites

To replicate all findings in this research repository, configure the following local environment:

| Tool | Required Version | Verification Command | Expected Output |
|:---|:---|:---|:---|
| **Python** | 3.12+ (tested on 3.14.8) | `python3 --version` | `Python 3.14.8` |
| **Ghidra** | 12.1.2 or 12.1.4 | `/opt/ghidra/support/analyzeHeadless --help` | Headless Analyzer banner |
| **Java Runtime** | OpenJDK 21 or 27 | `java -version` | `openjdk version "27"` |
| **GNU Binutils** | 2.40+ | `objdump --version` | `GNU objdump (GNU Binutils) 2.4x` |
| **Git / GitHub CLI**| Git 2.40+, gh 2.40+ | `gh --version` | `gh version 2.x` |

---

## 2. Artifact Verification Commands & Checksums

### A. Archive Verification
```bash
# Compute SHA-256 of original IPA
sha256sum waze.ipa
# Expected: 78c54a3db510c7d2142baeb13dd773c2f7774a3e4d99fb9a4cc966941086a158

# Verify byte-exact size
stat -c "%s bytes" waze.ipa
# Expected: 114712520 bytes (~109.40 MiB / 114.71 MB)

# Verify archive integrity and entry count
unzip -l waze.ipa | tail -n 1
# Expected: 2435 files (2309 files, 126 directories)
```

### B. Main Executable Verification (`Payload/Waze.app/Waze`)
```bash
# Verify byte-exact size
stat -c "%s bytes" extracted/Payload/Waze.app/Waze
# Expected: 141425424 bytes (~141.42 MB)

# Compute SHA-256 checksum
sha256sum extracted/Payload/Waze.app/Waze
# Expected: 0c40c247228439e2b75baca181569c75c144918561a8177e9399b183b5709d80

# Verify Mach-O format and flags
file extracted/Payload/Waze.app/Waze
# Expected: Mach-O 64-bit arm64 executable, flags:<NOUNDEFS|DYLDLINK|TWOLEVEL|BINDS_TO_WEAK|PIE|HAS_TLV_DESCRIPTORS>
```

### C. Related Artifacts & Component Dimensions
```bash
# Check NotificationExtension size & hash
stat -c "%s bytes" extracted/Payload/Waze.app/PlugIns/NotificationExtension.appex/NotificationExtension
# Expected: 1227216 bytes (~1.23 MB)
sha256sum extracted/Payload/Waze.app/PlugIns/NotificationExtension.appex/NotificationExtension
# Expected: 4b2985714dbbbc9a583eb983c1f4638bfd641d37df6b83027b93bcca2caa5330

# Check WazeShareExtension size & hash
stat -c "%s bytes" extracted/Payload/Waze.app/PlugIns/WazeShareExtension.appex/WazeShareExtension
# Expected: 1226624 bytes (~1.23 MB)

# Check SpotifyiOS framework size & hash
stat -c "%s bytes" extracted/Payload/Waze.app/Frameworks/SpotifyiOS.framework/SpotifyiOS
# Expected: 371024 bytes (~371 KB)

# Check Assets.car size & hash
stat -c "%s bytes" extracted/Payload/Waze.app/Assets.car
# Expected: 25496376 bytes (~25.5 MB)

# Check default.metallib size & hash
stat -c "%s bytes" extracted/Payload/Waze.app/default.metallib
# Expected: 67042 bytes (~67 KB)
```

---

## 3. Mach-O Header & Load Command Extraction Script

To inspect Mach-O headers, UUID, encryption status, and symbol tables without third-party dependencies, execute this self-contained Python script:

```python
import struct, uuid, os

binary_path = "extracted/Payload/Waze.app/Waze"
with open(binary_path, "rb") as f:
    header = f.read(32)
    magic, cputype, cpusubtype, filetype, ncmds, sizeofcmds, flags, reserved = struct.unpack("<IIIIIIII", header)
    print(f"Magic: {hex(magic)} (MH_MAGIC_64)")
    print(f"CPUType: {hex(cputype)} (ARM64)")
    print(f"FileType: {hex(filetype)} (MH_EXECUTE)")
    print(f"ncmds: {ncmds}, sizeofcmds: {sizeofcmds}, flags: {hex(flags)}")

    # Parse load commands
    offset = 32
    f.seek(offset)
    for _ in range(ncmds):
        cmd_data = f.read(8)
        cmd, cmdsize = struct.unpack("<II", cmd_data)
        cmd_body = f.read(cmdsize - 8)
        if cmd == 0x1b:  # LC_UUID
            print("LC_UUID:", str(uuid.UUID(bytes=cmd_body[:16])))
        elif cmd == 0x2c:  # LC_ENCRYPTION_INFO_64
            cryptoff, cryptsize, cryptid = struct.unpack("<III", cmd_body[:12])
            print(f"LC_ENCRYPTION_INFO_64: cryptoff={hex(cryptoff)}, cryptsize={hex(cryptsize)}, cryptid={cryptid}")
        elif cmd == 0x2:  # LC_SYMTAB
            symoff, nsyms, stroff, strsize = struct.unpack("<IIII", cmd_body[:16])
            print(f"LC_SYMTAB: nsyms={nsyms}, symoff={hex(symoff)}, strsize={strsize}")
        elif cmd == 0xb:  # LC_DYSYMTAB
            fields = struct.unpack("<IIIIII", cmd_body[:24])
            print(f"LC_DYSYMTAB: nlocalsym={fields[1]}, nextdefsym={fields[3]}, nundefsym={fields[5]}")
```

### Verified Output
```text
Magic: 0xfeedfacf (MH_MAGIC_64)
CPUType: 0x100000c (ARM64)
FileType: 0x2 (MH_EXECUTE)
ncmds: 117, sizeofcmds: 13088, flags: 0xa10085
LC_UUID: 4556fa71-0a76-3117-b160-07139913ce8d
LC_ENCRYPTION_INFO_64: cryptoff=0x4000, cryptsize=0x7a0c000, cryptid=0
LC_SYMTAB: nsyms=5098, symoff=0x8332818, strsize=211216
LC_DYSYMTAB: nlocalsym=1, nextdefsym=1, nundefsym=5096
```

---

## 4. Info.plist & Metadata Extraction Script

```python
import plistlib

with open("extracted/Payload/Waze.app/Info.plist", "rb") as f:
    pl = plistlib.load(f)
    print("CFBundleIdentifier:", pl.get("CFBundleIdentifier"))
    print("CFBundleShortVersionString:", pl.get("CFBundleShortVersionString"))
    print("MinimumOSVersion:", pl.get("MinimumOSVersion"))
    print("UIDeviceFamily:", pl.get("UIDeviceFamily"))
```

### Verified Output
```text
CFBundleIdentifier: com.waze.iphone
CFBundleShortVersionString: 5.22.0
MinimumOSVersion: 16.0
UIDeviceFamily: [1, 2]
```

---

## 5. Ghidra Headless Analyzer Replication

### Workaround for Leading-Dot Project Paths
Ghidra's `NamingUtilities.checkName` rejects project paths with leading dots (e.g., `.gemini`). Use `/tmp/ghidra_proj` as the project destination.

### Step 1: Headless Import (without auto-analysis)
```bash
mkdir -p /tmp/ghidra_proj
/opt/ghidra/support/analyzeHeadless /tmp/ghidra_proj WazeTest \
    -import extracted/Payload/Waze.app/Waze \
    -noanalysis \
    -overwrite
```
*Expected Result:* Completes in ~35–45 seconds. Log reports `INFO REPORT: Import succeeded`.

### Step 2: Running Target Verification Script
Create a Ghidra Java script `/tmp/ghidra_scripts/TargetDecompileScript.java` targeting specific addresses:
- `0x1001fb7f8` (`entry`)
- `0x10001a718` (`AlternateRoutesStateMachineBridge::ParseToRoutingUpdateResponse`)
- `0x1000d4b08` (`MainCanvasViewHolder::init`)
- `0x1000d4c6c` (`MainCanvasViewHolder::createMetalViewController`)
- `0x100102264` (`NavigationGuidanceReducerBridge::method`)
- `0x1000a1d28` (`WZWazeLocationServiceBridge::method`)

Run the script via Ghidra headless:
```bash
/opt/ghidra/support/analyzeHeadless /tmp/ghidra_proj WazeTest \
    -process Waze \
    -scriptPath /tmp/ghidra_scripts \
    -postScript TargetDecompileScript.java \
    -noanalysis \
    -readOnly
```
*Expected Result:* Disassembles and decompiles the 6 targeted procedures without errors.
