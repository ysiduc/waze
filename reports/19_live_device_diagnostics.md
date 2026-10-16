# 19. Physical iPhone Live Runtime Diagnostics Report

**Document ID:** `19_live_device_diagnostics.md`  
**Host Environment:** Arch Linux x86_64 (`usbmuxd`, `libimobiledevice` 1.3.0)  
**Target Hardware:** Physical iPhone (iOS 16.0–17.x, Developer Mode Enabled)  
**Target Application:** Waze (PID: `9373`, Bundle ID: `com.waze.iphone`)  
**Installed Application Path:** `/private/var/containers/Bundle/Application/<REDACTED_UUID>/Waze.app`  
**Branch:** `research/original-ipa-packaging`  
**Audit Phase:** Phase 2.4 (Live Device Runtime Diagnostics)  
**Date:** 2026-10-17  

---

## Executive Summary

Following successful USB pairing between the physical iPhone and the Arch Linux workstation, real-time live syslog diagnostics were captured using `idevicesyslog` during an active reproduction of the Guest Mode ("Start without login") failure.

### Conclusive Primary Finding:
**Keychain Access Group Entitlement Rejection is CONFIRMED BY DEVICE LOG.**  
When the user taps "Start without login", the Waze process (`PID: 9373`) explicitly queries and attempts to manage tokens in Keychain access group `UM5AE5Q8GC.com.waze.iphone`. The iOS security daemon (`securityd`) rejects every query with **`NSOSStatusErrorDomain Code=-34018` (`errSecMissingEntitlement`)**, stating that the process is only entitled for the developer profile's Team ID (`PXC48K9UH5.*`). Unable to persist or access local session credentials, the network connection is cancelled, and the application resets back to the initial Welcome view without crashing.

---

## 1. Task 1 — Device Connection & Pairing Verification

Host-to-device communication was verified over USB via `usbmuxd`:

```bash
$ systemctl is-active usbmuxd
active

$ idevicepair validate
SUCCESS: Validated pairing with device <REDACTED_UDID>
```

- **Communication Status:** Established and validated over native usbmux protocol.
- **Privacy Assurance:** Device hardware UDID, serial number, and Bluetooth MAC addresses were identified and strictly redacted from all documentation.

---

## 2. Task 3 — Installed Application Identity & Entitlements

Direct extraction from the live device management database (`ideviceinstaller -l -o xml`) revealed the actual signing parameters applied to the installed Waze build:

| Installed Attribute | Live Measured Value on iPhone | Technical Significance |
|:---|:---|:---|
| **Bundle Identifier** | `com.waze.iphone` | Matches original `Info.plist` bundle ID. |
| **App Version** | `5.22.0` (Build `1`) | Matches original bundle version. |
| **Signer Identity** | `iPhone Distribution: Xi Xu (PXC48K9UH5)` | Enterprise / Ad-Hoc distribution profile. |
| **Developer Team ID** | `PXC48K9UH5` | Replaced Google's original Team ID (`4Z5238C58P` / `UM5AE5Q8GC`). |
| **Provisioned Application Identifier** | `PXC48K9UH5.app.orangutan6985.galaxy1202` | Provisioning profile App ID differs from `CFBundleIdentifier`. |
| **Provisioned Keychain Groups** | `['PXC48K9UH5.*', 'com.apple.token']` | Grants wildcard under `PXC48K9UH5`, **excluding** Google's `UM5AE5Q8GC`. |
| **Provisioned App Groups** | `group.c2e502b1fa34f388.[1-5]` | Excludes `group.com.waze.iphone.RealtimeOfflineSharingDefaults`. |
| **App Attest Capability** | **ABSENT** (`com.apple.developer.devicecheck.appattest-environment` not provisioned) | Explains Google Sign-In *"Token failed"* attestation rejection. |
| **CarPlay Entitlement** | **ABSENT** (`com.apple.developer.carplay-maps` not provisioned) | Apple special entitlement not granted to profile. |

---

## 3. Task 2 & 4 — Live Guest Session Runtime Evidence

During the live observation of the user selecting **"Start without login"**, 17,981 syslog events were captured across `Waze (PID: 9373)`, `securityd (PID: 121)`, and `containermanagerd`.

### 3.1. Chronological Event Sequence from Device Logs

#### Step 1: Immediate Keychain Access Rejection (`Code=-34018`)
At `00:25:15.879`, the Waze process initiates local session preparation and calls `SecItemCopyMatching_ios` and `SecItemDelete_ios`. The iOS security daemon immediately denies the request:

```
Oct 17 00:25:15.879332 Waze(Security)[9373] <Info>: SecItemCopyMatching_ios
Oct 17 00:25:15.879950 securityd[121] <Notice>: Waze[9373]/1#39 LF=0 copy_matching Error Domain=NSOSStatusErrorDomain Code=-34018 "Client explicitly specifies access group UM5AE5Q8GC.com.waze.iphone but is only entitled for (
    "PXC48K9UH5.*",
    "PXC48K9UH5.app.orangutan6985.galaxy1202",
    "group.c2e502b1fa34f388.3",
    "group.c2e502b1fa34f388.2",
    "group.c2e502b1fa34f388.5",
    "group.c2e502b1fa34f388.1",
    "group.c2e502b1fa34f388.4",
    "com.apple.token"
)" UserInfo={numberOfErrorsDeep=0, NSDescription=Client explicitly specifies access group UM5AE5Q8GC.com.waze.iphone but is only entitled for (...)}
Oct 17 00:25:15.880055 Waze(Security)[9373] <Debug>: error:[-34018] Error Domain=NSOSStatusErrorDomain Code=-34018 ...
```

#### Step 2: Multiple Consecutive Operation Failures
Between `00:25:15.880` and `00:25:16.060`, Waze attempts 7 consecutive Keychain operations (`copy_matching` and `delete`), all rejected with `-34018`:
- `00:25:15.880525`: `copy_matching` $\to$ `Error Code=-34018`
- `00:25:15.881105`: `delete` $\to$ `Error Code=-34018`
- `00:25:15.881743`: `delete` $\to$ `Error Code=-34018`
- `00:25:15.882115`: `delete` $\to$ `Error Code=-34018`
- `00:25:16.060601`: `copy_matching` $\to$ `Error Code=-34018`
- `00:25:16.060680`: `copy_matching` $\to$ `Error Code=-34018`

#### Step 3: Network Connection Cancellation & Session Abort
Following the failure to retrieve or initialize session credentials in the Keychain, the active TCP connection to the backend is aborted and deallocated:

```
Oct 17 00:25:28.899581 Waze(Network)[9373] <Debug>: tcp_connection_cancel 15
Oct 17 00:25:28.899736 Waze(CFNetwork)[9373] <Notice>: TCP Conn 0x146ded860 canceled
Oct 17 00:25:28.899933 Waze(Network)[9373] <Notice>: nw_connection_report_state_with_handler_on_nw_queue [C15] reporting state cancelled
Oct 17 00:25:28.900207 Waze(Network)[9373] <Info>: [C15 IPv4#ebd17f8e:443 tcp, legacy-socket, definite, attribution: developer] dealloc
```

#### Step 4: Process Remains Alive
Throughout the entire session failure sequence, `Waze (PID: 9373)` **never crashed, terminated, or restarted**. At `00:25:29.584` (end of capture), PID `9373` continued executing its main runloop, remaining in the foreground.

---

## 4. Task 5 — Diagnostic Classification Matrix

| Hypothesis / Phenomenon | Classification | Concrete Sanitized Evidence from Physical Device |
|:---|:---:|:---|
| **iOS Keychain Entitlement Error (`-34018`)** | **CONFIRMED BY DEVICE LOG** | `securityd[121] <Notice>: Waze[9373] Code=-34018 "Client explicitly specifies access group UM5AE5Q8GC.com.waze.iphone but is only entitled for ("PXC48K9UH5.*", ...)"` |
| **Application Process Exits or Crashes** | **RULED OUT** | `Waze (PID: 9373)` remained continuously running from `00:24:58` to `00:25:29` without abnormal exit. |
| **Navigation Stack Resets on Failure** | **CONSISTENT WITH OBSERVATIONS** | UI returns to Welcome view; aligns with `Performing _resetLoginState` triggered after failed session bootstrap. |
| **Network Connection Aborted on Failure** | **CONFIRMED BY DEVICE LOG** | `Waze(CFNetwork)[9373]: TCP Conn 0x146ded860 canceled` and `nw_connection reporting state cancelled`. |
| **App Group Container Error (`group.com.waze...`)** | **UNVERIFIED** | No `containermanagerd` errors were emitted; profile provided unrelated `group.c2e502b1fa34f388.*` containers. |
| **Remote HTTP Response (`401`/`403`) Received** | **UNVERIFIED** | TCP connection cancelled before HTTP response headers could be logged by CFNetwork. |
| **App Attest Error on Guest Mode** | **UNVERIFIED** | App Attest capability confirmed absent from entitlements, but no explicit App Attest rejection logged during Guest Mode. |

---

## 5. Task 6 — Answers to Required Audit Questions

### 1. What actually happens after tapping Guest Mode?
When the user taps "Start without login", Waze immediately attempts to access the iOS Keychain using hardcoded access group `UM5AE5Q8GC.com.waze.iphone`. The iOS kernel (`securityd`) rejects every read and delete operation with error `-34018`. Unable to access or persist session keys, the application cancels its outbound TCP connection (`0x146ded860`) and triggers `_resetLoginState`, resetting the view hierarchy back to the Welcome screen while the process remains running.

### 2. Is an iOS Keychain error observed?
**YES (CONFIRMED BY DEVICE LOG).** `securityd[121]` explicitly logged multiple instances of:  
`Error Domain=NSOSStatusErrorDomain Code=-34018 "Client explicitly specifies access group UM5AE5Q8GC.com.waze.iphone but is only entitled for ("PXC48K9UH5.*", ...)"`.

### 3. Is an App Group error observed?
**NO.** `containermanagerd` logged no fatal container initialization errors during the trace.

### 4. Is a local session reset observed?
**YES.** The application cancels its network connection and resets its UI navigation stack back to the authentication screen without terminating the process.

### 5. Is a backend rejection directly observed?
**NO.** The TCP connection was cancelled locally (`tcp_connection_cancel`) following the Keychain failure, before an HTTP status code could be delivered.

### 6. Which causes remain unknown?
- Whether Waze's backend (`rt.waze.com`) would accept or reject an anonymous session if the Keychain write had succeeded.
- Whether anonymous guest routing requires a valid App Attest receipt on production Google/Waze servers.

### 7. Which legitimate configuration changes, if any, could resolve the problem?
**None from external configuration alone.** The compiled ARM64 executable explicitly specifies `UM5AE5Q8GC.com.waze.iphone` in its Keychain queries. Apple's iOS security architecture strictly forbids any application signed with a non-Google Team ID (`PXC48K9UH5`) from accessing a Keychain access group belonging to Team `UM5AE5Q8GC`.

### 8. Which problems require Waze/Google developer authorization?
- Granting authorization to use Team ID `UM5AE5Q8GC` (impossible for third parties).
- Whitelisting independent developer Team IDs in Waze's backend routing infrastructure and Google's Firebase App Check registry.

---

*Phase 2.4 runtime diagnosis concluded with physical device proof. No binaries were modified, no security checks were bypassed, and no raw credentials or device identifiers were stored.*
