# Tooling Verification & Environment Configuration

This document records the exact configuration, environment variables, versions, and validation results for the reverse engineering tooling deployed on Arch Linux.

---

## 1. REA (Reverse Engineer Anything) Setup

- **REA Agent Version:** `6.5.0` (`rea-agents@6.5.0`)
- **Protocol Version:** `2026-07-28`
- **Tool Inventory:** 207 MCP tools registered
- **Active Providers Verified:**
  - `rea-artifact-graph` (v1): Used for safe, non-extractive archive and container inventory (`inspect_artifact`, `open_binary`).
  - `ghidra` (v12.1.2): Headless binary analysis engine.
  - `rea-dotnet-static` (v1): Operational for PE/CLI inspections.
- **Provider Status Reporting (`binary_session`):**
  Successfully validated provider capability trees, ephemeral project management, and session lifecycle controls.

---

## 2. Ghidra Analysis Engine

- **Installation Directory:** `/opt/ghidra`
- **Package Version:** `ghidra 12.1.2-2` (Arch Linux official package)
- **Application Build Version:** `12.1.2` (Verified compatible build 12.1.4)
- **Headless Analyzer:** `/opt/ghidra/support/analyzeHeadless`
- **Native Decompiler:** `/opt/ghidra/Ghidra/Features/Decompiler/os/linux_x86_64/decompile` (ELF 64-bit x86-64 native executable)
- **Java Runtime Environment:**
  - **Runtime:** OpenJDK 64-Bit Server VM (build 27)
  - **Java Home:** `/usr/lib/jvm/java-27-openjdk`
  - **Version String:** `27 2026-09-15`

### Discovered Environment Constraint & Resolution
- **Constraint Observed:**
  When invoking Ghidra Headless with a project path located under `/home/ysiduc/.gemini/...`, the analysis aborted with:
  ```text
  java.lang.IllegalArgumentException: Path element starting with '.' is not permitted
  ```
- **Root Cause:**
  Ghidra's `NamingUtilities.checkName()` method strictly forbids any path segment starting with a dot `.` in local project directories to ensure project portability across filesystems.
- **Resolution:**
  Directing the project storage directory to `/tmp/ghidra_proj/WazeTest` resolved the path check completely while leaving the source binary in its existing read-only location.

---

## 3. Host System & Supporting Tooling

- **Operating System:** Arch Linux x86_64 (Linux kernel 6.x)
- **Python Version:** Python 3.14.8 (`/usr/bin/python3`)
  - Modules used: `plistlib`, `struct`, `zipfile`, `hashlib`, `os`, `sys`, `json`, `glob`
- **Binary Utilities:** GNU Binutils 2.47-4 (`objdump`, `readelf`, `nm`, `strings`, `file`)
- **Compression Utilities:** Info-ZIP `unzip` 6.00
- **Version Control:** Git 2.4x and GitHub CLI (`gh` 2.x) with active keyring authentication for user `ysiduc`
