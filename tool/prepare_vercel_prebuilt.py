#!/usr/bin/env python3
"""
Prepares the Vercel Build Output API v3 directory structure for prebuilt deployment:
  .vercel/output/
    ├── config.json
    └── static/
        └── [all static assets from build/web]
"""
import os
import sys
import json
import shutil

SRC_DIR = os.path.abspath("build/web")
OUTPUT_DIR = os.path.abspath(".vercel/output")
STATIC_DIR = os.path.join(OUTPUT_DIR, "static")

def generate_config():
    """Generates strictly valid Build Output API v3 config.json."""
    csp_directives = (
        "default-src 'self'; "
        "script-src 'self' 'wasm-unsafe-eval' 'unsafe-inline' https://www.gstatic.com https://unpkg.com; "
        "style-src 'self' 'unsafe-inline' https://fonts.googleapis.com; "
        "font-src 'self' https://fonts.gstatic.com data:; "
        "img-src 'self' data: blob: https://*.tile.openstreetmap.org https://tile.openstreetmap.org https://*.googleusercontent.com; "
        "connect-src 'self' https://fnngudikrvelpuhngtlw.supabase.co wss://fnngudikrvelpuhngtlw.supabase.co "
        "https://bus-telemetry-api.onrender.com https://tile.openstreetmap.org https://*.tile.openstreetmap.org "
        "https://*.onesignal.com https://onesignal.com https://unpkg.com; "
        "worker-src 'self' blob:; "
        "frame-ancestors 'none'; "
        "frame-src 'self' https://accounts.google.com; "
        "form-action 'self' https://accounts.google.com https://fnngudikrvelpuhngtlw.supabase.co; "
        "base-uri 'self';"
    )

    routes = [
        # 1. Asset & CanvasKit Cache-Control (Immutable 1-year cache)
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
        # 2. App Shell & Service Worker Cache-Control (Strict revalidation)
        {
            "src": "^/(index\\.html|flutter_service_worker\\.js|flutter_bootstrap\\.js|version\\.json|BUILD_METADATA\\.json)$",
            "headers": {
                "cache-control": "no-cache, no-store, must-revalidate"
            },
            "continue": True
        },
        # 3. Global HTTP Defensive Security Headers applied across all responses
        {
            "src": "^/.*$",
            "headers": {
                "strict-transport-security": "max-age=63072000; includeSubDomains; preload",
                "x-content-type-options": "nosniff",
                "x-frame-options": "DENY",
                "referrer-policy": "strict-origin-when-cross-origin",
                "permissions-policy": "geolocation=(self), camera=(), microphone=(), payment=(), usb=()",
                "content-security-policy": csp_directives
            },
            "continue": True
        },
        # 4. Filesystem handler: if matched static file exists in static/, serve immediately
        {
            "handle": "filesystem"
        },
        # 5. SPA Rewrite Fallback: route any non-filesystem URI (e.g. /auth/callback, /map, /login) to /index.html
        {
            "src": "^/.*$",
            "dest": "/index.html"
        }
    ]

    return {
        "version": 3,
        "routes": routes
    }

def main():
    print("=== Preparing Prebuilt Vercel Build Output API v3 Structure ===")
    if not os.path.isdir(SRC_DIR):
        print(f"Error: Source build directory not found: {SRC_DIR}")
        print("Run 'flutter build web --release' before preparing prebuilt output.")
        sys.exit(1)

    if not os.path.exists(os.path.join(SRC_DIR, "index.html")):
        print(f"Error: {SRC_DIR}/index.html missing. Invalid Flutter Web build.")
        sys.exit(1)

    # 1. Clean and initialize .vercel/output
    if os.path.exists(OUTPUT_DIR):
        shutil.rmtree(OUTPUT_DIR)
    os.makedirs(STATIC_DIR, exist_ok=True)

    # 2. Copy static web build artifacts to .vercel/output/static
    shutil.copytree(SRC_DIR, STATIC_DIR, dirs_exist_ok=True)

    # 3. Purge forbidden artifacts & debug source maps from output
    forbidden_patterns = [".env", "service_role", "keystore", ".dart.js.map"]
    removed_count = 0
    for root, dirs, files in os.walk(STATIC_DIR):
        for fname in files:
            for pat in forbidden_patterns:
                if pat in fname.lower():
                    fpath = os.path.join(root, fname)
                    os.remove(fpath)
                    removed_count += 1
                    print(f"Purged forbidden artifact from prebuilt bundle: {fname}")

    # 4. Generate .vercel/output/config.json with strict Build Output API v3 schema
    config = generate_config()
    config_path = os.path.join(OUTPUT_DIR, "config.json")
    with open(config_path, "w", encoding="utf-8") as f:
        json.dump(config, f, indent=2)

    print(f"✓ Vercel prebuilt bundle configured at {OUTPUT_DIR}")
    print(f"  - Static asset count: {len(os.listdir(STATIC_DIR))}")
    print(f"  - Config generated at: {config_path}")
    print(f"  - Routes defined: {len(config['routes'])}")
    print("✓ Build Output API v3 structure is ready for: vercel deploy --prebuilt")

if __name__ == "__main__":
    main()
