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

DEFAULT_SRC_DIR = os.path.abspath("build/web")
DEFAULT_OUTPUT_DIR = os.path.abspath(".vercel/output")

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

    security_headers = {
        "Strict-Transport-Security": "max-age=63072000; includeSubDomains; preload",
        "X-Content-Type-Options": "nosniff",
        "X-Frame-Options": "DENY",
        "Referrer-Policy": "strict-origin-when-cross-origin",
        "Permissions-Policy": "geolocation=(self), camera=(), microphone=(), payment=(), usb=()",
        "Content-Security-Policy": csp_directives,
    }

    entrypoint_headers = {
        "Cache-Control": "no-cache, no-store, must-revalidate",
        **security_headers,
    }

    routes = [
        {
            "src": "^/assets/(.*)$",
            "headers": {
                "Cache-Control": "public, max-age=31536000, immutable"
            },
            "continue": True,
        },
        {
            "src": "^/canvaskit/(.*)$",
            "headers": {
                "Cache-Control": "public, max-age=31536000, immutable"
            },
            "continue": True,
        },
        {
            "src": "^/(index\\.html|flutter_service_worker\\.js|flutter_bootstrap\\.js|version\\.json|BUILD_METADATA\\.json)$",
            "headers": entrypoint_headers,
            "continue": True,
        },
        {
            "handle": "filesystem"
        },
        {
            "src": "^/.*$",
            "headers": security_headers,
            "dest": "/index.html",
        },
    ]

    return {
        "version": 3,
        "routes": routes,
    }

def prepare_prebuilt(src_dir=None, output_dir=None):
    """Prepares the prebuilt bundle and writes .vercel/output/config.json."""
    src_dir = os.path.abspath(src_dir or DEFAULT_SRC_DIR)
    output_dir = os.path.abspath(output_dir or DEFAULT_OUTPUT_DIR)
    static_dir = os.path.join(output_dir, "static")

    if not os.path.isdir(src_dir):
        raise FileNotFoundError(f"Source build directory not found: {src_dir}")

    if not os.path.exists(os.path.join(src_dir, "index.html")):
        raise FileNotFoundError(f"{src_dir}/index.html missing. Invalid Flutter Web build.")

    # 1. Clean and initialize output_dir
    if os.path.exists(output_dir):
        shutil.rmtree(output_dir)
    os.makedirs(static_dir, exist_ok=True)

    # 2. Copy static web build artifacts to static_dir
    shutil.copytree(src_dir, static_dir, dirs_exist_ok=True)

    # 3. Purge forbidden artifacts & debug source maps from output
    forbidden_patterns = [".env", "service_role", "keystore", ".dart.js.map"]
    removed_count = 0
    for root, dirs, files in os.walk(static_dir):
        for fname in files:
            for pat in forbidden_patterns:
                if pat in fname.lower():
                    fpath = os.path.join(root, fname)
                    os.remove(fpath)
                    removed_count += 1
                    print(f"Purged forbidden artifact from prebuilt bundle: {fname}")

    # 4. Generate output_dir/config.json with strict Build Output API v3 schema
    config = generate_config()
    config_path = os.path.join(output_dir, "config.json")
    with open(config_path, "w", encoding="utf-8") as f:
        json.dump(config, f, indent=2)

    return config_path, static_dir, config

def main():
    print("=== Preparing Prebuilt Vercel Build Output API v3 Structure ===")
    try:
        config_path, static_dir, config = prepare_prebuilt()
    except FileNotFoundError as err:
        print(f"Error: {err}")
        print("Run 'flutter build web --release' before preparing prebuilt output.")
        sys.exit(1)

    print(f"✓ Vercel prebuilt bundle configured at {os.path.dirname(config_path)}")
    print(f"  - Static asset count: {len(os.listdir(static_dir))}")
    print(f"  - Config generated at: {config_path}")
    print(f"  - Routes defined: {len(config['routes'])}")
    print("✓ Build Output API v3 structure is ready for: vercel deploy --prebuilt")

if __name__ == "__main__":
    main()
