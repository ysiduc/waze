# 16. Final IPA Package Integrity & Equivalence Audit Report

**Document ID:** `16_final_ipa_integrity.md`  
**Reference Original IPA:** `/home/ysiduc/Downloads/waze.ipa`  
**Existing Repackaged IPA (v1):** `/home/ysiduc/.gemini/antigravity-ide/scratch/waze-analysis/repackaged/Waze-repackaged.ipa`  
**Final Repackaged IPA (v2):** `/home/ysiduc/.gemini/antigravity-ide/scratch/waze-analysis/repackaged/Waze-repackaged-v2.ipa`  
**Main Binary:** `Payload/Waze.app/Waze` (ARM64 Mach-O, 141,425,424 bytes)  
**Main Binary SHA-256:** `0c40c247228439e2b75baca181569c75c144918561a8177e9399b183b5709d80`  
**Host Environment:** Arch Linux x86_64, Antigravity IDE, Python 3.14.8, GNU Binutils 2.47  
**Branch:** `research/original-ipa-packaging`  
**Date:** 2026-10-16  

---

## Executive Summary

This report concludes the final packaging integrity and archive equivalence verification for the Waze iOS application bundle prior to user-managed developer signing and testing. 

### Key Findings & Verification Ledger:
1. **Original IPA Identity Resolved:** Direct measurements (`stat` and `sha256sum`) confirm the original `waze.ipa` size is **`114,712,520 bytes`** (~114.71 MB / 109.40 MiB) with SHA-256 `78c54a3db510c7d2142baeb13dd773c2f7774a3e4d99fb9a4cc966941086a158`. The historical reference of `115,221,416 bytes` was identified as an erroneous measurement in early research records and has been corrected across all affected repository reports.
2. **ZIP Metadata & Hierarchy Preservation:** The packaging tool [`scripts/repackage_and_validate.py`](../scripts/repackage_and_validate.py) was updated to preserve complete POSIX attributes (`stat.S_IFREG`, `stat.S_IFDIR`), standard directory entries (`Payload/`, `Payload/Waze.app/`, and all 124 internal bundle subdirectories), executable bits (`0o100755`), file timestamps, and compression types.
3. **Reproducible Equivalence Verification:** An independent verification tool [`scripts/verify_ipa_equivalence.py`](../scripts/verify_ipa_equivalence.py) audited all archive entries. The final local archive (`Waze-repackaged-v2.ipa`) matches the original application bundle with:
   - **0 SHA-256 mismatches** across all 2,308 application files (100% bit-exact).
   - **0 file mode/permission differences** (`0o100755`, `0o100644`, `0o040755` matched).
   - **0 compression method differences** (1,025 `ZIP_STORED` and 1,283 `ZIP_DEFLATED` matched).
   - **Exact uncompressed application payload:** `224,010,478 bytes` in both archives.
   - The only entry in `waze.ipa` omitted from the repackaged archive is `Payload/decrypt.day` (a 9-byte external decryption dumping artifact containing `und3fined` located outside `Payload/Waze.app`).
4. **CI Workflow Audit:** The GitHub Actions workflow is strictly partitioned: in public CI, it executes synthetic structure tests using mock headers and does **NOT** process real binaries, produce real Waze IPAs, or upload IPA artifacts.
5. **Installation Status:** iPhone installation and runtime functionality remain **UNVERIFIED** pending physical device hardware testing.

---

## 1. Task 1 — Original IPA Identity Resolution

Direct measurement executed against `/home/ysiduc/Downloads/waze.ipa`:

```bash
$ stat -c "%s bytes" /home/ysiduc/Downloads/waze.ipa
114712520 bytes

$ sha256sum /home/ysiduc/Downloads/waze.ipa
78c54a3db510c7d2142baeb13dd773c2f7774a3e4d99fb9a4cc966941086a158  /home/ysiduc/Downloads/waze.ipa
```

### Discrepancy Reconciliation:
- **Historical Error:** Previous reports `reports/01_ipa_structure.md`, `evidence/analysis_statistics.md`, and `evidence/reproducibility_manifest.md` referenced `115,221,416 bytes` alongside the SHA-256 `78c54a3db510c7d2142baeb13dd773c2f7774a3e4d99fb9a4cc966941086a158`.
- **Root Cause:** `115,221,416 bytes` was an unverified, copied measurement from an initial transfer log.
- **Resolution:** All repository references have been corrected to `114,712,520 bytes`.

---

## 2. Task 2 & 4 — ZIP Metadata Preservation & Repackaging

### 2.1. Metadata Deficiencies in Repackaged v1:
- Missing 126 explicit directory placeholder records (`Payload/`, `Payload/Waze.app/`, etc.).
- External attributes stored permissions without POSIX file type bits (`0o755` instead of `0o100755`; `0o644` instead of `0o100644`).
- Uniform deflation (`compresslevel=6`) applied to all files, whereas the original bundle preserved 1,025 pre-compressed assets (PNG, audio) uncompressed (`ZIP_STORED`) for iOS memory-mapping performance.

### 2.2. Archive Writer Improvements (`scripts/repackage_and_validate.py`):
1. **Explicit Directory Entries:** Emits all 126 bundle directories with `create_system = 3` (UNIX), `compress_type = ZIP_STORED`, and mode `(stat.S_IFDIR | 0o755) << 16` (`0o040755`).
2. **POSIX File Type Preservation:** Applies `st.st_mode` directly (or `stat.S_IFREG | mode`) with `create_system = 3`. Executables retain `0o100755` and regular files retain `0o100644`.
3. **Compression Type Alignment:** Supports `--reference-ipa` to mirror exact `ZIP_STORED` vs `ZIP_DEFLATED` distribution from the original package.
4. **Timestamp Preservation:** Retains original file and directory modification dates.

### 2.3. Local Generation of `Waze-repackaged-v2.ipa`:
Executed without overwriting either existing archive:
```bash
python3 scripts/repackage_and_validate.py \
  --app-dir /home/ysiduc/.gemini/antigravity-ide/scratch/waze-analysis/extracted/Payload/Waze.app \
  --output-ipa /home/ysiduc/.gemini/antigravity-ide/scratch/waze-analysis/repackaged/Waze-repackaged-v2.ipa \
  --reference-ipa /home/ysiduc/Downloads/waze.ipa
```
- **Output Path:** `/home/ysiduc/.gemini/antigravity-ide/scratch/waze-analysis/repackaged/Waze-repackaged-v2.ipa`
- **Output Size:** `114,694,185 bytes` (109.38 MB / 109.38 MiB)
- **Output SHA-256:** `5fad80d7a2c798659e262567e248e38e58eaf00423a04e697aad7a16bc9e3a51`
- **Entries Count:** 2,434 entries (126 directories + 2,308 application files)
- **Integrity Status:** `zipfile.testzip()` passed with 0 errors.

---

## 3. Task 3 — Reproducible Equivalence Comparison

Executed independent verification script [`scripts/verify_ipa_equivalence.py`](../scripts/verify_ipa_equivalence.py):

```bash
python3 scripts/verify_ipa_equivalence.py \
  --original-ipa /home/ysiduc/Downloads/waze.ipa \
  --repackaged-ipa /home/ysiduc/.gemini/antigravity-ide/scratch/waze-analysis/repackaged/Waze-repackaged-v2.ipa \
  --json-output evidence/ipa_equivalence_report.json \
  --md-output evidence/ipa_equivalence_report.md
```

### Comparative Metrics:

| Property | Original `waze.ipa` | Repackaged `Waze-repackaged-v2.ipa` | Determination |
|:---|:---|:---|:---:|
| **Archive File Size** | 114,712,520 bytes | 114,694,185 bytes | Difference: 18,335 bytes |
| **Archive SHA-256** | `78c54a3db510c7d2...` | `5fad80d7a2c79865...` | Distinct Archives |
| **Archive Integrity** | `testzip()` PASSED | `testzip()` PASSED | **PASS** |
| **Total Entries** | 2,435 | 2,434 | 1 non-app file omitted |
| **Directory Entries** | 126 | 126 | **IDENTICAL** |
| **File Entries** | 2,309 | 2,308 | 1 non-app file omitted |
| **Symlink Count** | 0 | 0 | **IDENTICAL (0)** |
| **App Payload Uncompressed** | **224,010,478 bytes** | **224,010,478 bytes** | **EXACT MATCH** |
| **File SHA-256 Mismatches** | — | **0 mismatches** (2,308 / 2,308) | **100% BIT-EXACT** |
| **File Size Mismatches** | — | **0 mismatches** | **IDENTICAL** |
| **Permission Mode Diffs** | — | **0 differences** | **IDENTICAL** |
| **Compression Mode Diffs** | — | **0 differences** | **IDENTICAL** |

### Mach-O Target Integrity:

| Mach-O Binary Path | Architecture | Encryption | Original SHA-256 | Repackaged SHA-256 | Bit-Exact Match |
|:---|:---:|:---:|:---:|:---:|:---:|
| `Payload/Waze.app/Waze` | ARM64 | `cryptid=0` | `0c40c2472284...` | `0c40c2472284...` | **YES (PASS)** |
| `.../SpotifyiOS.framework/SpotifyiOS` | ARM64 | `cryptid=0` | `eb7a150a88b2...` | `eb7a150a88b2...` | **YES (PASS)** |
| `.../NotificationExtension` | ARM64 | `cryptid=0` | `4b2985714dbb...` | `4b2985714dbb...` | **YES (PASS)** |
| `.../WazeShareExtension` | ARM64 | `cryptid=0` | `5df1434ea011...` | `5df1434ea011...` | **YES (PASS)** |

### Honest Accounting of Remaining Structural Difference:
- The original archive contains exactly one entry not present in the repackaged archive: `Payload/decrypt.day` (size: 9 bytes, contents: `und3fined`). This file is an artifact created by the decryption dumping utility and is not part of the `Waze.app` iOS application bundle. Omitting it from `Waze-repackaged-v2.ipa` results in a clean, standard iOS bundle hierarchy.

---

## 4. Task 5 — GitHub Actions CI Audit

| Audit Question | Verified Determination | Technical Basis |
|:---|:---:|:---|
| **Does the workflow run synthetic tests?** | **YES** | In default runs without inputs, it executes `MODE: SYNTHETIC STRUCTURE VALIDATION`, testing script syntax, ZIP traversal, and header parsing against mock bundles. |
| **Does it use the real application bundle?** | **NO** | Proprietary Waze binaries and assets are strictly excluded from the GitHub repository. Real bundle mode executes only if an authorized private URL is explicitly provided via `bundle_source_url`. |
| **Does it produce a real IPA?** | **NO** | In default runs, it produces `Synthetic-validation.ipa` (a mock test archive). It does not produce a real Waze IPA in public CI. |
| **Does it upload an IPA artifact?** | **NO** | The workflow only uploads `reports_output/CI_PACKAGE_VALIDATION_REPORT.md`. It does **not** upload any IPA files as build artifacts. |

> [!IMPORTANT]
> A successful GitHub Actions run in public CI validates only the packaging script logic and bundle structure rules; it does **not** signify that a real Waze IPA was generated or verified in CI. Real IPA packaging and verification must be conducted in the local Arch Linux research environment where original assets reside.

---

## 5. Remaining Signing & Installation Blockers

1. **Unprovisioned App Store Code Signature:**  
   The repackaged IPA retains Google's original App Store distribution signature and lacks `embedded.mobileprovision`. iOS kernel-level security daemon `installd` strictly rejects this package on stock devices.
2. **Re-Signing Prerequisite:**  
   To test on an iPhone, the user must apply a personal or development certificate (e.g. via Sideloadly or `codesign`), replace the bundle ID with a unique developer-owned ID, and embed a matching provisioning profile.
3. **Restricted Entitlements:**  
   - `com.apple.developer.carplay-maps`: Requires an approved Apple Developer Special Entitlement.
   - `aps-environment`: Production push notifications fail due to team ID token mismatch.
   - `com.apple.developer.devicecheck.appattest-environment`: Backend device attestation rejects non-Google signing teams.
   - App Groups & Keychain Groups: Must be re-keyed or stripped, or multi-target extension verification will fail.
4. **Physical Device Installation Verdict:**  
   **UNVERIFIED.** In accordance with strict audit standards, device installation and runtime behavior cannot be marked as PASS until confirmed on a physical iPhone.

---

## 6. Deliverable Artifacts Index

- Repackaging Automation Tool: [`scripts/repackage_and_validate.py`](../scripts/repackage_and_validate.py)
- Equivalence Verification Tool: [`scripts/verify_ipa_equivalence.py`](../scripts/verify_ipa_equivalence.py)
- Machine-Readable JSON Comparison: [`evidence/ipa_equivalence_report.json`](../evidence/ipa_equivalence_report.json)
- Markdown Comparison Summary: [`evidence/ipa_equivalence_report.md`](../evidence/ipa_equivalence_report.md)
- User Signing & Sideloading Guide: [`docs/signing_and_sideloading_guide.md`](../docs/signing_and_sideloading_guide.md)
- GitHub Actions CI Workflow: [`.github/workflows/validate-repackaging.yml`](../.github/workflows/validate-repackaging.yml)
