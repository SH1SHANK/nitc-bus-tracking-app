#!/usr/bin/env python3
"""
Automated Android Keystore Provisioning & GitHub Secrets Deployment Script.
Generates an industry-standard PKCS12 release keystore and registers credentials
in GitHub Actions repository & environment secrets via GitHub CLI (gh).
"""

import base64
import os
import secrets
import shutil
import subprocess
import sys

REPO_NAME = "SH1SHANK/nitc-bus-tracking-app"
ALIAS_NAME = "tracklet-release"
KEYSTORE_DIR = os.path.expanduser("~/.android")
KEYSTORE_PATH = os.path.join(KEYSTORE_DIR, "tracklet-release.jks")
PROJECT_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
LOCAL_KEYSTORE_PATH = os.path.join(PROJECT_ROOT, "android", "upload-keystore.jks")
LOCAL_KEY_PROPERTIES = os.path.join(PROJECT_ROOT, "android", "key.properties")
INFO_BACKUP_PATH = os.path.join(KEYSTORE_DIR, "tracklet-keystore-backup.txt")

SUPABASE_URL = "https://fnngudikrvelpuhngtlw.supabase.co"
SUPABASE_ANON_KEY = (
    "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9."
    "eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZubmd1ZGlrcnZlbHB1aG5ndGx3Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTE0Mjc0MDAsImV4cCI6MjEwNzAwMzQwMH0."
    "K7L2ESSZjV3R7OCwcOy_WA8XNCivIrUqZGRMitRrMEc"
)
MAP_TILE_URL = "https://tile.openstreetmap.org/{z}/{x}/{y}.png"
MAP_ATTRIBUTION = "© OpenStreetMap contributors"

def run_command(cmd, input_data=None, env=None):
    """Executes a command safely without shell quoting vulnerabilities."""
    proc_env = os.environ.copy()
    if env:
        proc_env.update(env)

    stdin_arg = subprocess.PIPE if input_data is not None else None
    proc = subprocess.Popen(
        cmd,
        stdin=stdin_arg,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        env=proc_env
    )
    stdout, stderr = proc.communicate(input=input_data.encode("utf-8") if input_data else None)
    if proc.returncode != 0:
        err_msg = stderr.decode("utf-8").strip() or stdout.decode("utf-8").strip()
        raise RuntimeError(f"Command failed ({' '.join(cmd)}): {err_msg}")
    return stdout.decode("utf-8").strip()

def set_gh_secret(name, value, env=None):
    """Sets a secret in GitHub using gh CLI via standard input."""
    cmd = ["gh", "secret", "set", name, "--repo", REPO_NAME]
    if env:
        cmd.extend(["--env", env])
    run_command(cmd, input_data=value)
    target = f"env:{env}" if env else "repository"
    print(f"  ✓ Secret '{name}' configured in {target}")

def set_gh_variable(name, value, env=None):
    """Sets a repository or environment variable in GitHub using gh CLI."""
    cmd = ["gh", "variable", "set", name, "--body", value, "--repo", REPO_NAME]
    if env:
        cmd.extend(["--env", env])
    run_command(cmd)
    target = f"env:{env}" if env else "repository"
    print(f"  ✓ Variable '{name}' configured in {target}")

def main():
    print("=== Tracklet Android Release Keystore Provisioning ===")

    # 1. Generate strong 32-character alphanumeric password
    password = secrets.token_urlsafe(24)

    os.makedirs(KEYSTORE_DIR, exist_ok=True)
    if os.path.exists(KEYSTORE_PATH):
        backup_existing = f"{KEYSTORE_PATH}.bak"
        shutil.copy2(KEYSTORE_PATH, backup_existing)
        print(f"Notice: Existing keystore backed up to {backup_existing}")

    # 2. Generate PKCS12 release keystore via keytool
    print(f"==> Generating 2048-bit RSA release keystore at {KEYSTORE_PATH}...")
    dname = "CN=Tracklet Release, OU=NITC Bus Tracking, O=National Institute of Technology Calicut, L=Kozhikode, ST=Kerala, C=IN"
    keytool_cmd = [
        "keytool", "-genkeypair",
        "-v",
        "-keystore", KEYSTORE_PATH,
        "-alias", ALIAS_NAME,
        "-keyalg", "RSA",
        "-keysize", "2048",
        "-validity", "10000",
        "-dname", dname,
        "-storetype", "PKCS12",
        "-storepass:env", "KEY_PASS",
        "-keypass:env", "KEY_PASS"
    ]
    run_command(keytool_cmd, env={"KEY_PASS": password})
    os.chmod(KEYSTORE_PATH, 0o600)
    print("✓ Keystore generated with chmod 600.")

    # 3. Verify keystore entry and extract SHA-256 fingerprint
    print("==> Verifying certificate fingerprint...")
    list_cmd = [
        "keytool", "-list", "-v",
        "-keystore", KEYSTORE_PATH,
        "-alias", ALIAS_NAME,
        "-storetype", "PKCS12",
        "-storepass:env", "KEY_PASS"
    ]
    cert_info = run_command(list_cmd, env={"KEY_PASS": password})
    sha256_fp = "UNKNOWN"
    for line in cert_info.splitlines():
        if "SHA256:" in line:
            sha256_fp = line.split("SHA256:", 1)[1].strip()
            break
    print(f"✓ Certificate SHA-256 Fingerprint: {sha256_fp}")

    # 4. Copy to local project (gitignored) and write android/key.properties
    shutil.copy2(KEYSTORE_PATH, LOCAL_KEYSTORE_PATH)
    os.chmod(LOCAL_KEYSTORE_PATH, 0o600)

    with open(LOCAL_KEY_PROPERTIES, "w", encoding="utf-8") as f:
        f.write(f"storePassword={password}\n")
        f.write(f"keyPassword={password}\n")
        f.write(f"keyAlias={ALIAS_NAME}\n")
        f.write("storeFile=upload-keystore.jks\n")
    os.chmod(LOCAL_KEY_PROPERTIES, 0o600)
    print("✓ Local gitignored android/upload-keystore.jks and android/key.properties configured.")

    # 5. Encode keystore to Base64
    with open(KEYSTORE_PATH, "rb") as f:
        keystore_base64 = base64.b64encode(f.read()).decode("utf-8")

    # 6. Save backup info file for developer
    with open(INFO_BACKUP_PATH, "w", encoding="utf-8") as f:
        f.write("=================================================================\n")
        f.write("TRACKLET ANDROID RELEASE SIGNING CREDENTIALS (DURABLE BACKUP)\n")
        f.write("KEEP THIS FILE SAFE AND SECURE. NEVER COMMIT IT TO GIT.\n")
        f.write("=================================================================\n\n")
        f.write(f"Keystore Path:  {KEYSTORE_PATH}\n")
        f.write(f"Key Alias:      {ALIAS_NAME}\n")
        f.write(f"Key Password:   {password}\n")
        f.write(f"Store Password: {password}\n")
        f.write(f"Certificate SHA-256: {sha256_fp}\n")
        f.write(f"Validity:       10,000 days\n")
        f.write(f"Distinguished Name: {dname}\n\n")
        f.write("GitHub Actions Secret Names:\n")
        f.write("  - ANDROID_KEYSTORE_BASE64\n")
        f.write("  - ANDROID_KEY_ALIAS\n")
        f.write("  - ANDROID_KEY_PASSWORD\n")
        f.write("  - ANDROID_STORE_PASSWORD\n")
    os.chmod(INFO_BACKUP_PATH, 0o600)
    print(f"✓ Secure developer credential backup written to: {INFO_BACKUP_PATH}")

    # 7. Upload secrets and variables to GitHub
    print("\n==> Deploying credentials to GitHub Actions (Repository Level)...")
    set_gh_secret("ANDROID_KEYSTORE_BASE64", keystore_base64)
    set_gh_secret("ANDROID_KEY_ALIAS", ALIAS_NAME)
    set_gh_secret("ANDROID_KEY_PASSWORD", password)
    set_gh_secret("ANDROID_STORE_PASSWORD", password)
    set_gh_secret("SUPABASE_ANON_KEY", SUPABASE_ANON_KEY)

    print("\n==> Deploying credentials to GitHub Actions (production Environment)...")
    set_gh_secret("ANDROID_KEYSTORE_BASE64", keystore_base64, env="production")
    set_gh_secret("ANDROID_KEY_ALIAS", ALIAS_NAME, env="production")
    set_gh_secret("ANDROID_KEY_PASSWORD", password, env="production")
    set_gh_secret("ANDROID_STORE_PASSWORD", password, env="production")
    set_gh_secret("SUPABASE_ANON_KEY", SUPABASE_ANON_KEY, env="production")

    print("\n==> Deploying runtime variables to GitHub Actions...")
    set_gh_variable("SUPABASE_URL", SUPABASE_URL)
    set_gh_variable("MAP_TILE_URL_TEMPLATE", MAP_TILE_URL)
    set_gh_variable("MAP_ATTRIBUTION", MAP_ATTRIBUTION)
    set_gh_variable("TRACKLET_ENVIRONMENT", "production")

    set_gh_variable("SUPABASE_URL", SUPABASE_URL, env="production")
    set_gh_variable("MAP_TILE_URL_TEMPLATE", MAP_TILE_URL, env="production")
    set_gh_variable("MAP_ATTRIBUTION", MAP_ATTRIBUTION, env="production")
    set_gh_variable("TRACKLET_ENVIRONMENT", "production", env="production")

    print("\n✓ Keystore generation and GitHub Secrets deployment completed successfully!")

if __name__ == "__main__":
    main()
