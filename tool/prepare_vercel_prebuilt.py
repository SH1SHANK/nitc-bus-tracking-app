#!/usr/bin/env python3
"""
Prepares the Vercel Build Output API v3 directory structure:
  .vercel/output/
    ├── config.json
    └── static/
        └── [all files from build/web]
"""
import os
import sys
import json
import shutil

SRC_DIR = os.path.abspath("build/web")
OUTPUT_DIR = os.path.abspath(".vercel/output")
STATIC_DIR = os.path.join(OUTPUT_DIR, "static")
VERCEL_JSON = os.path.abspath("vercel.json")

def main():
    print("=== Preparing Prebuilt Vercel Deployment Output ===")
    if not os.path.isdir(SRC_DIR):
        print(f"Error: Source directory {SRC_DIR} not found. Run flutter build web first.")
        sys.exit(1)

    if not os.path.exists(os.path.join(SRC_DIR, "index.html")):
        print(f"Error: {SRC_DIR}/index.html missing. Invalid Flutter Web build.")
        sys.exit(1)

    # 1. Clean and prepare .vercel/output/static
    if os.path.exists(OUTPUT_DIR):
        shutil.rmtree(OUTPUT_DIR)
    os.makedirs(STATIC_DIR, exist_ok=True)

    # 2. Copy web assets to static/
    shutil.copytree(SRC_DIR, STATIC_DIR, dirs_exist_ok=True)

    # 3. Ensure vercel.json is present in static directory
    if os.path.isfile(VERCEL_JSON):
        shutil.copy2(VERCEL_JSON, os.path.join(STATIC_DIR, "vercel.json"))
        shutil.copy2(VERCEL_JSON, os.path.join(SRC_DIR, "vercel.json"))

    # 4. Generate .vercel/output/config.json
    config = {
        "version": 3,
        "routes": [
            {
                "src": "^/assets/(.*)$",
                "headers": {
                    "cache-control": "public, max-age=31536000, immutable"
                },
                "continue": True
            },
            {
                "src": "^/canvaskit/(.*)$",
                "headers": {
                    "cache-control": "public, max-age=31536000, immutable"
                },
                "continue": True
            },
            {
                "src": "^/(index\\.html|flutter_service_worker\\.js|flutter_bootstrap\\.js|version\\.json|BUILD_METADATA\\.json)$",
                "headers": {
                    "cache-control": "no-cache, no-store, must-revalidate"
                },
                "continue": True
            },
            {
                "src": "^/.*$",
                "headers": {
                    "strict-transport-security": "max-age=63072000; includeSubDomains; preload",
                    "x-content-type-options": "nosniff",
                    "x-frame-options": "DENY",
                    "referrer-policy": "strict-origin-when-cross-origin",
                    "permissions-policy": "geolocation=(self), camera=(), microphone=(), payment=(), usb=()",
                    "content-security-policy": (
                        "default-src 'self'; "
                        "script-src 'self' 'wasm-unsafe-eval' 'unsafe-inline' https://www.gstatic.com https://unpkg.com; "
                        "style-src 'self' 'unsafe-inline' https://fonts.googleapis.com; "
                        "font-src 'self' https://fonts.gstatic.com data:; "
                        "img-src 'self' data: blob: https://*.tile.openstreetmap.org https://tile.openstreetmap.org https://*.googleusercontent.com; "
                        "connect-src 'self' https://fnngudikrvelpuhngtlw.supabase.co wss://fnngudikrvelpuhngtlw.supabase.co https://bus-telemetry-api.onrender.com https://tile.openstreetmap.org https://*.tile.openstreetmap.org https://*.onesignal.com https://onesignal.com https://unpkg.com; "
                        "worker-src 'self' blob:; "
                        "frame-ancestors 'none'; "
                        "frame-src 'self' https://accounts.google.com; "
                        "form-action 'self' https://accounts.google.com https://fnngudikrvelpuhngtlw.supabase.co; "
                        "base-uri 'self';"
                    )
                },
                "continue": True
            },
            {
                "handle": "filesystem"
            },
            {
                "src": "^/auth/callback$",
                "dest": "/index.html"
            },
            {
                "src": "^/.*$",
                "dest": "/index.html"
            }
        ],
        "overrides": {}
    }

    config_path = os.path.join(OUTPUT_DIR, "config.json")
    with open(config_path, "w") as f:
        json.dump(config, f, indent=2)

    # 5. Sanitize static output
    forbidden = [".env", "service_role", "keystore", ".dart.js.map"]
    removed_count = 0
    for root, dirs, files in os.walk(STATIC_DIR):
        for fname in files:
            for pat in forbidden:
                if pat in fname.lower():
                    fpath = os.path.join(root, fname)
                    os.remove(fpath)
                    removed_count += 1
                    print(f"Purged forbidden artifact from bundle: {fname}")

    print(f"✓ Vercel prebuilt bundle configured at {OUTPUT_DIR}")
    print(f"  - Static asset count: {len(os.listdir(STATIC_DIR))}")
    print(f"  - Config generated at: {config_path}")
    print("✓ Ready for: vercel deploy --prebuilt")

if __name__ == "__main__":
    main()
