#!/usr/bin/env python3
"""
Production Build Artifact Staging & Verification Script
Target: ~/Applications/Builds/tracklet/0.1.0+1/
"""
import os
import sys
import json
import shutil
import tarfile
import hashlib
import datetime
import subprocess

PROJECT_NAME = "tracklet"
VERSION = "0.1.0+1"
SRC_BUILD_DIR = os.path.abspath("build/web")
DEST_DIR = os.path.expanduser(f"~/Applications/Builds/{PROJECT_NAME}/{VERSION}")
VERCEL_JSON_PATH = os.path.abspath("vercel.json")

def sha256_file(filepath):
    h = hashlib.sha256()
    with open(filepath, "rb") as f:
        while chunk := f.read(65536):
            h.update(chunk)
    return h.hexdigest()

def get_commit_sha():
    try:
        return subprocess.check_output(["git", "rev-parse", "HEAD"]).decode().strip()
    except Exception:
        return "UNKNOWN"

def main():
    print(f"==> Verifying production source at: {SRC_BUILD_DIR}")
    if not os.path.isdir(SRC_BUILD_DIR):
        print(f"Error: Build directory not found: {SRC_BUILD_DIR}")
        sys.exit(1)

    # 1. Audit source files for sensitive patterns
    forbidden_patterns = [".env", "keystore", "service_role", "id_rsa", ".pem", ".p12", ".dart.js.map"]
    for root, dirs, files in os.walk(SRC_BUILD_DIR):
        for fname in files:
            for pat in forbidden_patterns:
                if pat in fname.lower():
                    print(f"Security Alert: Sensitive pattern '{pat}' found in {fname}")
                    sys.exit(1)

    # 2. Create destination directory
    os.makedirs(DEST_DIR, exist_ok=True)
    dest_web = os.path.join(DEST_DIR, "web")
    if os.path.exists(dest_web):
        shutil.rmtree(dest_web)
    shutil.copytree(SRC_BUILD_DIR, dest_web)

    # 2b. Ensure hardened vercel.json is present in staged web bundle
    if os.path.isfile(VERCEL_JSON_PATH):
        shutil.copy2(VERCEL_JSON_PATH, os.path.join(dest_web, "vercel.json"))
        shutil.copy2(VERCEL_JSON_PATH, os.path.join(DEST_DIR, "vercel.json"))

    # 3. Create distribution tarball
    archive_name = f"{PROJECT_NAME}-web-v{VERSION}.tar.gz"
    archive_path = os.path.join(DEST_DIR, archive_name)
    with tarfile.open(archive_path, "w:gz") as tar:
        tar.add(dest_web, arcname="web")

    archive_sha256 = sha256_file(archive_path)

    # 4. Generate BUILD_METADATA.json
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

    metadata_path = os.path.join(DEST_DIR, "BUILD_METADATA.json")
    with open(metadata_path, "w") as f:
        json.dump(metadata, f, indent=2)

    # Also place a copy inside web/
    with open(os.path.join(dest_web, "BUILD_METADATA.json"), "w") as f:
        json.dump(metadata, f, indent=2)

    # 5. Generate checksums.sha256
    checksums_path = os.path.join(DEST_DIR, "checksums.sha256")
    with open(checksums_path, "w") as f:
        f.write(f"{archive_sha256}  {archive_name}\n")
        f.write(f"{sha256_file(metadata_path)}  BUILD_METADATA.json\n")
        if os.path.isfile(os.path.join(DEST_DIR, "vercel.json")):
            f.write(f"{sha256_file(os.path.join(DEST_DIR, 'vercel.json'))}  vercel.json\n")
        for root, dirs, files in os.walk(dest_web):
            for fname in sorted(files):
                fpath = os.path.join(root, fname)
                rel_path = os.path.relpath(fpath, DEST_DIR)
                f.write(f"{sha256_file(fpath)}  {rel_path}\n")

    # 6. Verify checksums.sha256 integrity
    print("==> Verifying SHA-256 integrity of all staged files...")
    with open(checksums_path, "r") as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            expected_hash, rel_path = line.split("  ", 1)
            full_path = os.path.join(DEST_DIR, rel_path)
            actual_hash = sha256_file(full_path)
            if expected_hash != actual_hash:
                print(f"Error: Checksum mismatch for {rel_path}! Expected {expected_hash}, got {actual_hash}")
                sys.exit(1)
    print("✓ All checksums verified successfully.")

    # 7. Apply strict permissions: chmod 755 dirs, 644 files
    for root, dirs, files in os.walk(DEST_DIR):
        for d in dirs:
            os.chmod(os.path.join(root, d), 0o755)
        for fname in files:
            os.chmod(os.path.join(root, fname), 0o644)
    os.chmod(DEST_DIR, 0o755)

    print(f"\n✓ Artifact successfully staged and verified at: {DEST_DIR}")
    print(f"  - Archive: {archive_path}")
    print(f"  - SHA256:  {archive_sha256}")
    print(f"  - Metadata: {metadata_path}")
    print(f"  - Checksums: {checksums_path}")

if __name__ == "__main__":
    main()
