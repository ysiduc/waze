#!/usr/bin/env python3
"""
Waze iOS Application Repackaging & Structure Validation Tool
-------------------------------------------------------------
Audits Mach-O binaries, frameworks, app extensions, entitlements,
and bundle hierarchies. Preserves original unencrypted binaries
without instruction modification or code injection, and packages
a structurally valid IPA for user-managed signing and local testing.
"""

import os
import sys
import struct
import plistlib
import zipfile
import hashlib
import argparse
import json
from typing import Dict, List, Any, Optional

def compute_sha256(filepath: str) -> str:
    hasher = hashlib.sha256()
    with open(filepath, 'rb') as f:
        while chunk := f.read(65536):
            hasher.update(chunk)
    return hasher.hexdigest()

def inspect_macho(bin_path: str) -> Dict[str, Any]:
    """Inspects a Mach-O binary for architecture, encryption, and code signatures."""
    if not os.path.exists(bin_path):
        return {"error": "File not found"}
    
    file_size = os.path.getsize(bin_path)
    sha256 = compute_sha256(bin_path)
    
    with open(bin_path, 'rb') as f:
        header = f.read(32)
        if len(header) < 32:
            return {"error": "Header too small"}
        
        magic, cputype, cpusubtype, filetype, ncmds, sizeofcmds, flags, reserved = struct.unpack('<IIIIIIII', header)
        is_arm64 = (cputype == 0x0100000c) # CPU_TYPE_ARM64
        
        cmd_data = f.read(sizeofcmds)
        offset = 0
        cryptid = None
        sig_offset = None
        sig_size = None
        
        for _ in range(ncmds):
            if offset + 8 > len(cmd_data):
                break
            cmd, cmdsize = struct.unpack('<II', cmd_data[offset:offset+8])
            if cmd == 0x2c: # LC_ENCRYPTION_INFO_64
                _, _, cryptid = struct.unpack('<III', cmd_data[offset+8:offset+20])
            elif cmd == 0x1d: # LC_CODE_SIGNATURE
                sig_offset, sig_size = struct.unpack('<II', cmd_data[offset+8:offset+16])
            offset += cmdsize
        
        entitlements_xml = None
        if sig_offset and sig_size:
            f.seek(sig_offset)
            sig_blob = f.read(sig_size)
            if len(sig_blob) >= 12:
                sig_magic, sig_len, count = struct.unpack('>III', sig_blob[:12])
                if sig_magic == 0xfade0cc0: # CSMAGIC_EMBEDDED_SIGNATURE
                    for i in range(count):
                        slot_type, slot_off = struct.unpack('>II', sig_blob[12+i*8:12+(i+1)*8])
                        if slot_type == 5: # CSSLOT_ENTITLEMENTS
                            ent_magic, ent_len = struct.unpack('>II', sig_blob[slot_off:slot_off+8])
                            ent_bytes = sig_blob[slot_off+8:slot_off+ent_len]
                            entitlements_xml = ent_bytes.decode('utf-8', errors='replace')
                            break

    return {
        "file_name": os.path.basename(bin_path),
        "size_bytes": file_size,
        "sha256": sha256,
        "magic": f"0x{magic:08x}",
        "is_arm64": is_arm64,
        "cryptid": cryptid,
        "is_unencrypted": (cryptid == 0),
        "has_code_signature": (sig_offset is not None),
        "entitlements_xml": entitlements_xml
    }

def audit_bundle(app_dir: str) -> Dict[str, Any]:
    """Audits the full Waze.app bundle structure and dependencies."""
    if not os.path.isdir(app_dir):
        raise ValueError(f"Application bundle not found: {app_dir}")
    
    # 1. Main Executable
    main_bin = os.path.join(app_dir, "Waze")
    main_macho = inspect_macho(main_bin)
    
    # 2. Info.plist
    info_plist_path = os.path.join(app_dir, "Info.plist")
    info_dict = {}
    if os.path.exists(info_plist_path):
        with open(info_plist_path, "rb") as f:
            info_dict = plistlib.load(f)
    
    # 3. Embedded Frameworks
    frameworks = []
    fw_dir = os.path.join(app_dir, "Frameworks")
    if os.path.exists(fw_dir):
        for fw_name in sorted(os.listdir(fw_dir)):
            if fw_name.endswith(".framework"):
                base = fw_name[:-len(".framework")]
                bin_path = os.path.join(fw_dir, fw_name, base)
                frameworks.append({
                    "framework_name": fw_name,
                    "macho": inspect_macho(bin_path)
                })
    
    # 4. App Extensions (PlugIns)
    extensions = []
    plugins_dir = os.path.join(app_dir, "PlugIns")
    if os.path.exists(plugins_dir):
        for ex_name in sorted(os.listdir(plugins_dir)):
            if ex_name.endswith(".appex"):
                base = ex_name[:-len(".appex")]
                bin_path = os.path.join(plugins_dir, ex_name, base)
                plist_path = os.path.join(plugins_dir, ex_name, "Info.plist")
                ex_info = {}
                if os.path.exists(plist_path):
                    with open(plist_path, "rb") as f:
                        ex_info = plistlib.load(f)
                extensions.append({
                    "extension_name": ex_name,
                    "bundle_id": ex_info.get("CFBundleIdentifier"),
                    "macho": inspect_macho(bin_path)
                })
    
    # 5. Resources and Signatures
    has_code_resources = os.path.exists(os.path.join(app_dir, "_CodeSignature", "CodeResources"))
    has_mobileprovision = os.path.exists(os.path.join(app_dir, "embedded.mobileprovision"))
    has_assets_car = os.path.exists(os.path.join(app_dir, "Assets.car"))
    
    # File count and total size
    total_files = 0
    total_bytes = 0
    for root, _, files in os.walk(app_dir):
        for file in files:
            total_files += 1
            total_bytes += os.path.getsize(os.path.join(root, file))
    
    return {
        "app_directory": app_dir,
        "bundle_identifier": info_dict.get("CFBundleIdentifier"),
        "version": info_dict.get("CFBundleShortVersionString"),
        "build_version": info_dict.get("CFBundleVersion"),
        "min_os_version": info_dict.get("MinimumOSVersion"),
        "background_modes": info_dict.get("UIBackgroundModes", []),
        "total_files": total_files,
        "total_uncompressed_bytes": total_bytes,
        "main_executable": main_macho,
        "frameworks": frameworks,
        "extensions": extensions,
        "has_code_resources": has_code_resources,
        "has_embedded_mobileprovision": has_mobileprovision,
        "has_assets_car": has_assets_car
    }

def package_ipa(app_dir: str, output_ipa_path: str, verbose: bool = True) -> Dict[str, Any]:
    """Packages the Waze.app directory into a standard, structurally valid IPA."""
    os.makedirs(os.path.dirname(os.path.abspath(output_ipa_path)), exist_ok=True)
    
    parent_dir = os.path.dirname(os.path.abspath(app_dir))
    app_folder_name = os.path.basename(os.path.abspath(app_dir))
    
    if verbose:
        print(f"Creating IPA archive: {output_ipa_path}...")
    
    entries_count = 0
    with zipfile.ZipFile(output_ipa_path, 'w', compression=zipfile.ZIP_DEFLATED, compresslevel=6) as zipf:
        for root, dirs, files in os.walk(app_dir):
            for file in sorted(files):
                full_path = os.path.join(root, file)
                rel_path = os.path.relpath(full_path, parent_dir)
                archive_name = f"Payload/{rel_path}"
                
                # Set permissions: 0755 for executables/binaries, 0644 for regular files
                is_exec = os.access(full_path, os.X_OK) or file == "Waze" or file.endswith(".dylib")
                perm = 0o755 if is_exec else 0o644
                
                zinfo = zipfile.ZipInfo.from_file(full_path, arcname=archive_name)
                zinfo.external_attr = perm << 16
                zinfo.compress_type = zipfile.ZIP_DEFLATED
                
                with open(full_path, 'rb') as src:
                    zipf.writestr(zinfo, src.read())
                entries_count += 1
                
                if verbose and entries_count % 500 == 0:
                    print(f"  Archived {entries_count} files...")
    
    # Verify ZIP integrity
    if verbose:
        print("Verifying output ZIP integrity...")
    with zipfile.ZipFile(output_ipa_path, 'r') as zipf:
        corrupted = zipf.testzip()
        if corrupted:
            raise RuntimeError(f"Corrupted entry detected in output IPA: {corrupted}")
    
    ipa_size = os.path.getsize(output_ipa_path)
    ipa_sha256 = compute_sha256(output_ipa_path)
    
    if verbose:
        print(f"IPA successfully created: {ipa_size} bytes ({ipa_size / (1024*1024):.2f} MB)")
        print(f"SHA-256: {ipa_sha256}")
    
    return {
        "output_ipa_path": output_ipa_path,
        "size_bytes": ipa_size,
        "sha256": ipa_sha256,
        "entry_count": entries_count,
        "integrity_verified": (corrupted is None)
    }

def main():
    parser = argparse.ArgumentParser(description="Waze iOS Repackaging & Validation Tool")
    parser.add_argument("--app-dir", default="/home/ysiduc/.gemini/antigravity-ide/scratch/waze-analysis/extracted/Payload/Waze.app",
                        help="Path to unencrypted Waze.app directory")
    parser.add_argument("--output-ipa", default="/home/ysiduc/.gemini/antigravity-ide/scratch/waze-analysis/repackaged/Waze-repackaged.ipa",
                        help="Destination path for repackaged IPA")
    parser.add_argument("--validate-only", action="store_true",
                        help="Perform bundle structure and entitlement audit without writing IPA")
    parser.add_argument("--json", action="store_true",
                        help="Output audit results as JSON")
    args = parser.parse_args()

    print("================================================================================")
    print("      WAZE ORIGINAL BINARY REPACKAGING & VALIDATION PIPELINE                    ")
    print("================================================================================")

    audit_res = audit_bundle(args.app_dir)
    print(f"Bundle ID:         {audit_res['bundle_identifier']}")
    print(f"App Version:       {audit_res['version']} (Build {audit_res['build_version']})")
    print(f"Minimum iOS:       {audit_res['min_os_version']}")
    print(f"Total Files:       {audit_res['total_files']} files ({audit_res['total_uncompressed_bytes'] / (1024*1024):.2f} MB)")
    print(f"Main Binary:       {audit_res['main_executable']['file_name']} ({audit_res['main_executable']['size_bytes']} bytes)")
    print(f"Main Binary Hash:  {audit_res['main_executable']['sha256']}")
    print(f"ARM64 Verified:    {audit_res['main_executable']['is_arm64']}")
    print(f"Unencrypted:       {audit_res['main_executable']['is_unencrypted']} (cryptid={audit_res['main_executable']['cryptid']})")
    print(f"Frameworks Count:  {len(audit_res['frameworks'])}")
    print(f"Extensions Count:  {len(audit_res['extensions'])}")
    print("--------------------------------------------------------------------------------")

    if args.validate_only:
        print("[MODE] Validation-only completed successfully.")
        if args.json:
            print(json.dumps(audit_res, indent=2))
        return

    pkg_res = package_ipa(args.app_dir, args.output_ipa)
    print("--------------------------------------------------------------------------------")
    print("REPACKAGING SUMMARY:")
    print(f"  Output IPA:      {pkg_res['output_ipa_path']}")
    print(f"  Size:            {pkg_res['size_bytes']} bytes ({pkg_res['size_bytes'] / (1024*1024):.2f} MB)")
    print(f"  SHA-256:         {pkg_res['sha256']}")
    print(f"  Files Included:  {pkg_res['entry_count']}")
    print(f"  ZIP Integrity:   {'PASSED' if pkg_res['integrity_verified'] else 'FAILED'}")
    print("================================================================================")

if __name__ == "__main__":
    main()
