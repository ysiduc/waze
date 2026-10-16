# Developer Signing & Local Sideloading Guide for Repackaged Waze IPA

**Target Package:** `Waze-repackaged.ipa`  
**Application Identity:** `com.waze.iphone` (requires team substitution for sideloading)  
**Target Architecture:** ARM64 (iOS 16.0+)  

---

## 1. Why User-Managed Signing is Required

The repackaged IPA contains the unencrypted, original ARM64 application binary and resources from `waze.ipa`. However, iOS enforces strict kernel-level code signature verification:

1. **Missing Provisioning Profile:** Production App Store IPAs do not contain `embedded.mobileprovision` because FairPlay / App Store signatures are verified directly by Apple's public key root.
2. **Team Identifier Mismatch:** The original signature is tied to Waze Mobile Ltd. (`4Z5238C58P` / `UM5AE5Q8GC`). An independent developer cannot sign using Apple's official App Store certificate.
3. **Local Testing Requirement:** To run on a physical iPhone, the app must be re-signed with your own Apple Developer Certificate (Personal, Development, or Ad-Hoc Enterprise) and paired with an active mobile provisioning profile.

---

## 2. Recommended Sideloading Workflows

### Method A: Automated Sideloading via Sideloadly (Easiest)

[Sideloadly](https://sideloadly.io/) automatically handles bundle identifier substitution, App Extension synchronizing, and mobile provisioning profile generation for non-jailbroken iPhones:

1. Connect your iPhone to your workstation via USB and trust the computer.
2. Launch Sideloadly and drag `Waze-repackaged.ipa` into the interface.
3. Enter your Apple ID (used to generate a free 7-day personal development certificate).
4. Under **Advanced Options**:
   - Check **"Change bundle ID"** $\to$ set to a unique ID (e.g. `com.yourname.waze`).
   - Check **"Remove unsupported extensions"** if your provisioning profile does not support App Extensions.
5. Click **Start** to sign and install the application directly onto your connected iPhone.
6. On your iPhone: Go to **Settings $\to$ General $\to$ VPN & Device Management** $\to$ Trust your developer account certificate.
7. Enable **Developer Mode** under **Settings $\to$ Privacy & Security $\to$ Developer Mode** (iOS 16+).

---

### Method B: Manual CLI Re-Signing on macOS (`codesign`)

For developers with an active Apple Developer Program membership and an explicit Wildcard or Ad-Hoc provisioning profile:

```bash
# 1. Unzip the repackaged IPA
unzip -q Waze-repackaged.ipa -d repackaged_temp
cd repackaged_temp/Payload/Waze.app

# 2. Copy your valid provisioning profile
cp /path/to/your.mobileprovision embedded.mobileprovision

# 3. Extract your developer entitlements from the profile
security cms -D -i embedded.mobileprovision > profile.plist
/usr/libexec/PlistBuddy -x -c 'Print :Entitlements' profile.plist > entitlements.plist

# 4. Remove the old App Store code signature
rm -rf _CodeSignature

# 5. Sign embedded frameworks
codesign -f -s "Apple Development: Your Name (XXXXXXXXXX)" \
    --timestamp=none \
    Frameworks/SpotifyiOS.framework

# 6. Sign embedded app extensions (must match extension provisioning profiles)
# If no extension profile exists, delete the PlugIns folder to prevent launch crashes:
# rm -rf PlugIns/
codesign -f -s "Apple Development: Your Name (XXXXXXXXXX)" \
    --entitlements entitlements.plist \
    --timestamp=none \
    PlugIns/NotificationExtension.appex

codesign -f -s "Apple Development: Your Name (XXXXXXXXXX)" \
    --entitlements entitlements.plist \
    --timestamp=none \
    PlugIns/WazeShareExtension.appex

# 7. Sign the main application executable
codesign -f -s "Apple Development: Your Name (XXXXXXXXXX)" \
    --entitlements entitlements.plist \
    --timestamp=none \
    .

# 8. Re-archive the signed IPA
cd ../..
zip -qr9 Waze-signed-test.ipa Payload/
```

---

## 3. Anticipated Runtime Behaviors & Functional Limitations

When running an independently re-signed Waze IPA on a physical iPhone:

1. **Local Navigation & GPS:**
   - Real-time CoreLocation tracking and map rendering operate locally.
   - The UI canvas will launch without crashing.
2. **Server-Dependent Services:**
   - **Google/Waze Authentication:** If the backend uses App Attest (`com.apple.developer.devicecheck.appattest-environment`), requests from an altered team ID may be rejected.
   - **Live Hazard Alerts:** Push notifications will not be received.
   - **CarPlay:** The application will not appear on Apple CarPlay vehicle screens unless Apple has granted your developer team the `com.apple.developer.carplay-maps` entitlement.
