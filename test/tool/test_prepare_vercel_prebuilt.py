#!/usr/bin/env python3
"""
Unit test for Vercel Build Output API v3 execution in tool/prepare_vercel_prebuilt.py
"""
import os
import sys
import json
import shutil
import tempfile
import unittest

# Add project root to sys.path
PROJECT_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "../.."))
sys.path.insert(0, PROJECT_ROOT)

from tool.prepare_vercel_prebuilt import prepare_prebuilt, generate_config

class TestPrepareVercelPrebuilt(unittest.TestCase):
    def setUp(self):
        self.temp_dir = tempfile.mkdtemp(prefix="tracklet_test_vercel_")
        self.mock_src_dir = os.path.join(self.temp_dir, "build_web")
        self.mock_output_dir = os.path.join(self.temp_dir, "vercel_output")
        os.makedirs(self.mock_src_dir, exist_ok=True)

        # Create minimal mock Flutter Web build
        with open(os.path.join(self.mock_src_dir, "index.html"), "w", encoding="utf-8") as f:
            f.write("<!DOCTYPE html><html><head><title>Tracklet</title></head><body></body></html>")
        with open(os.path.join(self.mock_src_dir, "flutter_service_worker.js"), "w", encoding="utf-8") as f:
            f.write("// service worker")
        with open(os.path.join(self.mock_src_dir, "main.dart.js"), "w", encoding="utf-8") as f:
            f.write("// main dart js")

        # Create assets and canvaskit subdirectories
        assets_dir = os.path.join(self.mock_src_dir, "assets")
        os.makedirs(assets_dir, exist_ok=True)
        with open(os.path.join(assets_dir, "FontManifest.json"), "w", encoding="utf-8") as f:
            f.write("[]")

    def tearDown(self):
        shutil.rmtree(self.temp_dir, ignore_errors=True)

    def test_prepare_prebuilt_execution_and_config(self):
        """Execute prepare_prebuilt with mock directories and assert schema compliance."""
        config_path, static_dir, config = prepare_prebuilt(
            src_dir=self.mock_src_dir,
            output_dir=self.mock_output_dir
        )

        self.assertTrue(os.path.isfile(config_path), f"config.json was not created at {config_path}")
        self.assertTrue(os.path.isdir(static_dir), f"static dir was not created at {static_dir}")

        # Assert static files copied
        self.assertTrue(os.path.isfile(os.path.join(static_dir, "index.html")))
        self.assertTrue(os.path.isfile(os.path.join(static_dir, "flutter_service_worker.js")))
        self.assertTrue(os.path.isfile(os.path.join(static_dir, "assets", "FontManifest.json")))

        # Read generated JSON from disk to ensure valid serialization
        with open(config_path, "r", encoding="utf-8") as f:
            saved_config = json.load(f)

        # 1. Assert "version": 3
        self.assertEqual(saved_config.get("version"), 3, "Build Output API v3 must define 'version': 3")
        routes = saved_config.get("routes", [])
        self.assertIsInstance(routes, list, "Config must contain a 'routes' array")

        # 2. Assert presence of the filesystem handle route
        filesystem_routes = [r for r in routes if r.get("handle") == "filesystem"]
        self.assertEqual(len(filesystem_routes), 1, "Exactly one {'handle': 'filesystem'} route must exist")
        filesystem_index = routes.index(filesystem_routes[0])
        self.assertGreater(filesystem_index, 0, "Static routes must precede 'handle': 'filesystem'")

        # 3. Assert security headers in static entrypoint route
        entrypoint_route = None
        for r in routes[:filesystem_index]:
            if "index\\.html" in r.get("src", ""):
                entrypoint_route = r
                break
        self.assertIsNotNone(entrypoint_route, "Missing static entrypoint header route")
        self.assertTrue(entrypoint_route.get("continue"), "Entrypoint route must specify 'continue': True")

        ep_headers = entrypoint_route.get("headers", {})
        self.assertIn("Cache-Control", ep_headers)
        self.assertIn("no-cache", ep_headers["Cache-Control"])
        self.assertIn("Strict-Transport-Security", ep_headers)
        self.assertIn("Content-Security-Policy", ep_headers)
        self.assertIn("X-Frame-Options", ep_headers)
        self.assertEqual(ep_headers["X-Frame-Options"], "DENY")
        self.assertIn("Permissions-Policy", ep_headers)

        # 4. Assert SPA fallback route after filesystem handle
        fallback_routes = [
            r for r in routes[filesystem_index + 1:]
            if r.get("dest") == "/index.html"
        ]
        self.assertGreaterEqual(len(fallback_routes), 1, "Missing SPA fallback rewrite route to /index.html")

        fallback_route = fallback_routes[-1]
        self.assertEqual(fallback_route.get("dest"), "/index.html")
        self.assertEqual(fallback_route.get("src"), "^/.*$")

        # Assert security headers in fallback route
        fallback_headers = fallback_route.get("headers", {})
        self.assertIn("Strict-Transport-Security", fallback_headers)
        self.assertIn("max-age=63072000", fallback_headers["Strict-Transport-Security"])
        self.assertIn("Content-Security-Policy", fallback_headers)
        self.assertIn("X-Frame-Options", fallback_headers)
        self.assertEqual(fallback_headers["X-Frame-Options"], "DENY")
        self.assertIn("Permissions-Policy", fallback_headers)
        self.assertIn("X-Content-Type-Options", fallback_headers)
        self.assertEqual(fallback_headers["X-Content-Type-Options"], "nosniff")
        self.assertIn("Referrer-Policy", fallback_headers)

        # Assert CSP content
        csp = fallback_headers["Content-Security-Policy"]
        self.assertIn("default-src 'self'", csp)
        self.assertIn("wasm-unsafe-eval", csp)
        self.assertIn("fnngudikrvelpuhngtlw.supabase.co", csp)
        self.assertIn("frame-ancestors 'none'", csp)

    def test_forbidden_artifacts_purged(self):
        """Verify sensitive patterns (.env, service_role, .map) are purged from static directory."""
        with open(os.path.join(self.mock_src_dir, ".env.production"), "w", encoding="utf-8") as f:
            f.write("SECRET=leak")
        with open(os.path.join(self.mock_src_dir, "supabase_service_role.key"), "w", encoding="utf-8") as f:
            f.write("role")
        with open(os.path.join(self.mock_src_dir, "main.dart.js.map"), "w", encoding="utf-8") as f:
            f.write("{}")

        config_path, static_dir, config = prepare_prebuilt(
            src_dir=self.mock_src_dir,
            output_dir=self.mock_output_dir
        )

        self.assertFalse(os.path.exists(os.path.join(static_dir, ".env.production")))
        self.assertFalse(os.path.exists(os.path.join(static_dir, "supabase_service_role.key")))
        self.assertFalse(os.path.exists(os.path.join(static_dir, "main.dart.js.map")))

if __name__ == "__main__":
    unittest.main()
