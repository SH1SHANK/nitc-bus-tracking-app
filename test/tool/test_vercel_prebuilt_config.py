#!/usr/bin/env python3
"""
Unit test for Vercel Build Output API v3 config generation in tool/prepare_vercel_prebuilt.py
"""
import os
import sys
import unittest

# Add project root to sys.path
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "../..")))
from tool.prepare_vercel_prebuilt import generate_config

class TestVercelPrebuiltConfig(unittest.TestCase):
    def setUp(self):
        self.config = generate_config()

    def test_schema_top_level(self):
        """Build Output API v3 only accepts 'version': 3 and 'routes'."""
        self.assertEqual(self.config.get("version"), 3)
        self.assertIn("routes", self.config)
        self.assertIsInstance(self.config["routes"], list)
        # Must NOT have top-level rewrites or headers
        self.assertNotIn("rewrites", self.config)
        self.assertNotIn("headers", self.config)
        self.assertNotIn("cleanUrls", self.config)

    def test_route_ordering(self):
        """Header routes (continue: true) must precede handle: filesystem, followed by SPA fallback."""
        routes = self.config["routes"]
        filesystem_index = -1
        for idx, route in enumerate(routes):
            if route.get("handle") == "filesystem":
                filesystem_index = idx
                break

        self.assertNotEqual(filesystem_index, -1, "Missing {'handle': 'filesystem'} route")
        self.assertGreater(filesystem_index, 0, "Header routes must precede {'handle': 'filesystem'}")

        # All routes before filesystem MUST have continue: True and headers
        for idx in range(filesystem_index):
            route = routes[idx]
            self.assertTrue(route.get("continue"), f"Route at index {idx} must have 'continue': True")
            self.assertIn("headers", route, f"Route at index {idx} must define 'headers'")

        # Routes after filesystem must handle fallback SPA routing
        self.assertGreater(len(routes), filesystem_index + 1)
        fallback_route = routes[-1]
        self.assertEqual(fallback_route.get("dest"), "/index.html")
        self.assertIn(".*", fallback_route.get("src", ""))

    def test_security_headers_present(self):
        """Verify all mandated security headers are defined."""
        routes = self.config["routes"]
        security_headers = {}
        for route in routes:
            if route.get("src") == "^/.*$" and "headers" in route:
                security_headers = {k.lower(): v for k, v in route["headers"].items()}
                break

        required_headers = [
            "strict-transport-security",
            "content-security-policy",
            "x-content-type-options",
            "x-frame-options",
            "referrer-policy",
            "permissions-policy"
        ]

        for header in required_headers:
            self.assertIn(header, security_headers, f"Missing required security header: {header}")

        self.assertIn("max-age=63072000", security_headers["strict-transport-security"])
        self.assertEqual(security_headers["x-content-type-options"], "nosniff")
        self.assertEqual(security_headers["x-frame-options"], "DENY")
        self.assertEqual(security_headers["referrer-policy"], "strict-origin-when-cross-origin")
        self.assertIn("geolocation=(self)", security_headers["permissions-policy"])

        csp = security_headers["content-security-policy"]
        self.assertIn("default-src 'self'", csp)
        self.assertIn("wasm-unsafe-eval", csp)
        self.assertIn("fnngudikrvelpuhngtlw.supabase.co", csp)
        self.assertIn("bus-telemetry-api.onrender.com", csp)
        self.assertIn("frame-ancestors 'none'", csp)

    def test_cache_control_headers(self):
        """Verify cache-control rules for assets and app shell."""
        routes = self.config["routes"]
        headers_by_src = {
            r.get("src"): {k.lower(): v for k, v in r.get("headers", {}).items()}
            for r in routes if "headers" in r
        }

        # Assets & CanvasKit: immutable
        assets_cache = headers_by_src.get("^/assets/(.*)$", {}).get("cache-control", "")
        self.assertIn("immutable", assets_cache)
        canvaskit_cache = headers_by_src.get("^/canvaskit/(.*)$", {}).get("cache-control", "")
        self.assertIn("immutable", canvaskit_cache)

        # App Shell / Service Worker: no-cache
        shell_src = "^/(|index\\.html|flutter_service_worker\\.js|flutter_bootstrap\\.js|version\\.json|BUILD_METADATA\\.json)$"
        shell_cache = headers_by_src.get(shell_src, {}).get("cache-control", "")
        self.assertIn("no-cache", shell_cache)
        self.assertIn("no-store", shell_cache)

if __name__ == "__main__":
    unittest.main()
