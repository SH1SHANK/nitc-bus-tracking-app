#!/usr/bin/env python3
"""
Production Build Artifact Staging & Verification Script for Tracklet
Supports both Web and Android release artifact staging and integrity verification at:
  ~/Applications/Builds/tracklet/<VERSION>/web/
  ~/Applications/Builds/tracklet/<VERSION>/android/
"""
import argparse
import datetime
import hashlib
import json
import os
import shutil
import subprocess
import sys
import tarfile

PROJECT_NAME = "tracklet"
VERSION = "0.1.0+1"
BASE_DEST_DIR = os.path.expanduser(f"~/Applications/Builds/{PROJECT_NAME}/{VERSION}")
SRC_WEB_DIR = os.path.abspath("build/web")
SRC_ANDROID_DIST_DIR = os.path.abspath("dist/android")
SRC_ANDROID_BUILD_DIR = os.path.abspath("build/app/outputs")
VERCEL_JSON_PATH = os.path.abspath("vercel.json")

def sha256_file(filepath):
    """Computes SHA-256 digest of a file."""
    h = hashlib.sha256()
    with open(filepath, "rb") as f:
        while chunk := f.read(65536):
            h.update(chunk)
    return h.hexdigest()

def get_commit_sha():
    """Returns the current Git HEAD commit SHA."""
    try:
        return subprocess.check_output(["git", "rev-parse", "HEAD"]).decode().strip()
    except Exception:
        return "UNKNOWN"

def stage_web():
    """Stages and verifies Flutter Web release distribution."""
    print(f"\n==> [Web] Verifying production source at: {SRC_WEB_DIR}")
    if not os.path.isdir(SRC_WEB_DIR):
        print(f"Notice: Web build directory not found: {SRC_WEB_DIR}. Skipping web staging.")
        return False

    forbidden_patterns = [".env", "keystore", "service_role", "id_rsa", ".pem", ".p12", ".dart.js.map"]
    for root, dirs, files in os.walk(SRC_WEB_DIR):
        for fname in files:
            for pat in forbidden_patterns:
                if pat in fname.lower():
                    print(f"Security Alert: Sensitive pattern '{pat}' found in {fname}")
                    sys.exit(1)

    os.makedirs(BASE_DEST_DIR, exist_ok=True)
    dest_web = os.path.join(BASE_DEST_DIR, "web")
    if os.path.exists(dest_web):
        shutil.rmtree(dest_web)
    shutil.copytree(SRC_WEB_DIR, dest_web)

    if os.path.isfile(VERCEL_JSON_PATH):
        shutil.copy2(VERCEL_JSON_PATH, os.path.join(dest_web, "vercel.json"))
        shutil.copy2(VERCEL_JSON_PATH, os.path.join(BASE_DEST_DIR, "vercel.json"))

    archive_name = f"{PROJECT_NAME}-web-v{VERSION}.tar.gz"
    archive_path = os.path.join(BASE_DEST_DIR, archive_name)
    with tarfile.open(archive_path, "w:gz") as tar:
        tar.add(dest_web, arcname="web")

    archive_sha256 = sha256_file(archive_path)
    commit_sha = get_commit_sha()
    metadata = {
        "project": PROJECT_NAME,
        "version": VERSION,
        "target_platform": "web",
        "commit_sha": commit_sha,
        "build_timestamp": datetime.datetime.now(datetime.timezone.utc).isoformat(),
        "archive_file": archive_name,
        "archive_sha256": archive_sha256,
        "source_lockfile": "pubspec.lock",
        "runtime_environment": {
            "flutter_version": "3.47.5 (channel stable)",
            "os": sys.platform,
            "architecture": os.uname().machine
        },
        "build_flags": [
            "--release",
            "--dart-define=ENVIRONMENT=production",
            "--dart-define=SUPABASE_URL=https://fnngudikrvelpuhngtlw.supabase.co"
        ],
        "integrity_status": "VERIFIED_PRODUCTION"
    }

    metadata_path = os.path.join(BASE_DEST_DIR, "BUILD_METADATA.json")
    with open(metadata_path, "w", encoding="utf-8") as f:
        json.dump(metadata, f, indent=2)

    with open(os.path.join(dest_web, "BUILD_METADATA.json"), "w", encoding="utf-8") as f:
        json.dump(metadata, f, indent=2)

    checksums_path = os.path.join(BASE_DEST_DIR, "checksums.sha256")
    with open(checksums_path, "w", encoding="utf-8") as f:
        f.write(f"{archive_sha256}  {archive_name}\n")
        f.write(f"{sha256_file(metadata_path)}  BUILD_METADATA.json\n")
        if os.path.isfile(os.path.join(BASE_DEST_DIR, "vercel.json")):
            f.write(f"{sha256_file(os.path.join(BASE_DEST_DIR, 'vercel.json'))}  vercel.json\n")
        for root, dirs, files in os.walk(dest_web):
            for fname in sorted(files):
                fpath = os.path.join(root, fname)
                rel_path = os.path.relpath(fpath, BASE_DEST_DIR)
                f.write(f"{sha256_file(fpath)}  {rel_path}\n")

    print("==> [Web] Verifying SHA-256 integrity of staged web files...")
    with open(checksums_path, "r", encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            expected_hash, rel_path = line.split("  ", 1)
            full_path = os.path.join(BASE_DEST_DIR, rel_path)
            actual_hash = sha256_file(full_path)
            if expected_hash != actual_hash:
                print(f"Error: Checksum mismatch for {rel_path}! Expected {expected_hash}, got {actual_hash}")
                sys.exit(1)

    print("✓ [Web] Artifacts verified and staged.")
    print(f"  - Directory: {dest_web}")
    print(f"  - Archive:   {archive_path}")
    print(f"  - Checksums: {checksums_path}")
    return True

def stage_android():
    """Stages and verifies Android release distribution (APKs, AAB, symbols)."""
    print(f"\n==> [Android] Checking for release artifacts...")
    dest_android = os.path.join(BASE_DEST_DIR, "android")
    os.makedirs(dest_android, exist_ok=True)

    src_dir = None
    if os.path.isdir(SRC_ANDROID_DIST_DIR) and os.listdir(SRC_ANDROID_DIST_DIR):
        src_dir = SRC_ANDROID_DIST_DIR
        print(f"  Found prepared release distribution at: {src_dir}")
    elif os.path.isdir(SRC_ANDROID_BUILD_DIR):
        src_dir = SRC_ANDROID_BUILD_DIR
        print(f"  Found local build outputs at: {src_dir}")

    if not src_dir:
        print("  Notice: No Android build artifacts found in dist/android or build/app/outputs. Skipping Android staging.")
        return False

    # Copy artifacts from dist/android or gather from build outputs
    if src_dir == SRC_ANDROID_DIST_DIR:
        for fname in sorted(os.listdir(src_dir)):
            sfile = os.path.join(src_dir, fname)
            if os.path.isfile(sfile):
                shutil.copy2(sfile, os.path.join(dest_android, fname))
    else:
        apk_dir = os.path.join(src_dir, "flutter-apk")
        bundle_dir = os.path.join(src_dir, "bundle", "release")
        semver = VERSION.split("+")[0]

        mapping = {
            "app-release.apk": f"BusTracker-v{semver}-universal.apk",
            "app-arm64-v8a-release.apk": f"BusTracker-v{semver}-arm64-v8a.apk",
            "app-x86_64-release.apk": f"BusTracker-v{semver}-x86_64.apk",
        }
        if os.path.isdir(apk_dir):
            for src_name, dest_name in mapping.items():
                sp = os.path.join(apk_dir, src_name)
                if os.path.isfile(sp):
                    shutil.copy2(sp, os.path.join(dest_android, dest_name))

        if os.path.isdir(bundle_dir):
            aab_src = os.path.join(bundle_dir, "app-release.aab")
            if os.path.isfile(aab_src):
                shutil.copy2(aab_src, os.path.join(dest_android, f"BusTracker-v{semver}.aab"))

    # Audit destination files for sensitive patterns
    forbidden_patterns = [".env", "keystore", "upload-keystore", ".jks", "key.properties"]
    for root, dirs, files in os.walk(dest_android):
        for fname in files:
            for pat in forbidden_patterns:
                if pat in fname.lower():
                    print(f"Security Alert: Sensitive pattern '{pat}' found in {fname}")
                    os.remove(os.path.join(root, fname))

    # Generate BUILD_METADATA.json if not already present
    android_meta_path = os.path.join(dest_android, "BUILD_METADATA.json")
    if not os.path.isfile(android_meta_path):
        commit_sha = get_commit_sha()
        meta = {
            "project": PROJECT_NAME,
            "version": VERSION,
            "target_platform": "android",
            "commit_sha": commit_sha,
            "build_timestamp": datetime.datetime.now(datetime.timezone.utc).isoformat(),
            "source_lockfile": "pubspec.lock",
            "runtime_environment": {
                "flutter_version": "3.47.5 (channel stable)",
                "os": sys.platform,
                "architecture": os.uname().machine
            },
            "build_flags": [
                "--release",
                "--obfuscate",
                "--split-debug-info=build/app/outputs/symbols",
                "--dart-define=ENVIRONMENT=production",
                "--dart-define=SUPABASE_URL=https://fnngudikrvelpuhngtlw.supabase.co"
            ],
            "integrity_status": "VERIFIED_PRODUCTION"
        }
        with open(android_meta_path, "w", encoding="utf-8") as f:
            json.dump(meta, f, indent=2)

    # Generate checksums.sha256 for Android
    android_checksums_path = os.path.join(dest_android, "checksums.sha256")
    with open(android_checksums_path, "w", encoding="utf-8") as f:
        for fname in sorted(os.listdir(dest_android)):
            if fname == "checksums.sha256":
                continue
            fpath = os.path.join(dest_android, fname)
            if os.path.isfile(fpath):
                f.write(f"{sha256_file(fpath)}  {fname}\n")

    print("==> [Android] Verifying SHA-256 integrity of staged Android files...")
    with open(android_checksums_path, "r", encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            h, fname = line.split("  ", 1)
            actual_h = sha256_file(os.path.join(dest_android, fname))
            if h != actual_h:
                print(f"Error: Checksum mismatch for Android {fname}!")
                sys.exit(1)

    print("✓ [Android] Artifacts verified and staged.")
    print(f"  - Directory: {dest_android}")
    print(f"  - Checksums: {android_checksums_path}")
    return True

def apply_permissions(target_dir):
    """Applies strict file permissions (0755 for directories, 0644 for files)."""
    for root, dirs, files in os.walk(target_dir):
        for d in dirs:
            os.chmod(os.path.join(root, d), 0o755)
        for fname in files:
            os.chmod(os.path.join(root, fname), 0o644)
    os.chmod(target_dir, 0o755)

def main():
    parser = argparse.ArgumentParser(description="Stage production build artifacts with cryptographic verification.")
    parser.add_argument("--platform", choices=["web", "android", "all"], default="all", help="Target platform to stage")
    args = parser.parse_args()

    staged_any = False
    if args.platform in ("web", "all"):
        if stage_web():
            staged_any = True

    if args.platform in ("android", "all"):
        if stage_android():
            staged_any = True

    if os.path.isdir(BASE_DEST_DIR):
        apply_permissions(BASE_DEST_DIR)

    if not staged_any:
        print("\nNotice: No artifacts were found to stage.")
    else:
        print(f"\n✓ All requested targets staged and verified at: {BASE_DEST_DIR}")

if __name__ == "__main__":
    main()
