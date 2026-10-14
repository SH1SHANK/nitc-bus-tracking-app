#!/usr/bin/env python3
"""
Unit tests for tool/generate_release_notes.py
Verifies version parsing, tag validation, commit categorization, and markdown structure.
"""

import os
import sys
import tempfile
import unittest

# Add project root to sys.path
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "../..")))
from tool.generate_release_notes import (
    get_pubspec_version,
    validate_tag_against_pubspec,
    categorize_commits,
    generate_markdown,
    get_artifact_checksums
)

class TestReleaseNotesGenerator(unittest.TestCase):

    def test_pubspec_version_parsing(self):
        with tempfile.NamedTemporaryFile("w+", delete=False) as tmp:
            tmp.write("name: tracklet\nversion: 1.2.3+45\nenvironment:\n  sdk: '>=3.0.0 <4.0.0'\n")
            tmp_path = tmp.name

        try:
            info = get_pubspec_version(tmp_path)
            self.assertEqual(info["semver"], "1.2.3")
            self.assertEqual(info["build_number"], "45")
            self.assertEqual(info["canonical"], "1.2.3+45")
            self.assertEqual(info["tag"], "v1.2.3")
            self.assertEqual(info["full_tag"], "v1.2.3+45")
        finally:
            os.remove(tmp_path)

    def test_tag_validation(self):
        info = {
            "semver": "0.1.0",
            "build_number": "1",
            "canonical": "0.1.0+1"
        }
        self.assertTrue(validate_tag_against_pubspec("v0.1.0", info))
        self.assertTrue(validate_tag_against_pubspec("v0.1.0+1", info))
        self.assertTrue(validate_tag_against_pubspec("0.1.0", info))
        self.assertTrue(validate_tag_against_pubspec("0.1.0+1", info))
        self.assertFalse(validate_tag_against_pubspec("v0.2.0", info))
        self.assertFalse(validate_tag_against_pubspec("v1.0.0", info))

    def test_commit_categorization(self):
        sample_commits = [
            {"sha": "11111111", "short_sha": "1111111", "subject": "feat(map): add live vehicle heading", "author": "Alice"},
            {"sha": "22222222", "short_sha": "2222222", "subject": "fix(auth): handle expired refresh token", "author": "Bob"},
            {"sha": "33333333", "short_sha": "3333333", "subject": "sec(ci): pin action SHAs and shred keystores", "author": "Charlie"},
            {"sha": "44444444", "short_sha": "4444444", "subject": "docs: update production checklist", "author": "David"},
            {"sha": "55555555", "short_sha": "5555555", "subject": "refactor(data): clean up repository interfaces", "author": "Eve"},
            {"sha": "66666666", "short_sha": "6666666", "subject": "chore: bump dependencies in pubspec", "author": "Frank"},
        ]

        categories = categorize_commits(sample_commits)
        self.assertEqual(len(categories["features"]["commits"]), 1)
        self.assertEqual(len(categories["fixes"]["commits"]), 1)
        self.assertEqual(len(categories["security_infra"]["commits"]), 2)  # sec and chore
        self.assertEqual(len(categories["docs_refactor"]["commits"]), 2)  # docs and refactor

    def test_markdown_and_checksum_rendering(self):
        version_info = {
            "semver": "0.1.0",
            "build_number": "1",
            "canonical": "0.1.0+1"
        }
        categories = {
            "features": {"title": "🚀 Features & UX Improvements", "commits": []},
            "fixes": {"title": "🐛 Bug Fixes", "commits": []},
            "security_infra": {"title": "🔒 Security & Infrastructure", "commits": []},
            "docs_refactor": {"title": "📚 Documentation & Refactoring", "commits": []}
        }
        checksums = {
            "tracklet-v0.1.0-arm64-v8a.apk": "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"
        }

        md = generate_markdown(version_info, "v0.1.0", "v0.0.9", categories, checksums)
        self.assertIn("# Tracklet v0.1.0", md)
        self.assertIn("`e3b0c44298fc1c14...`", md)
        self.assertIn("arm64-v8a", md)
        self.assertIn("Universal (All ABIs)", md)
        self.assertIn("sha256sum -c checksums.sha256", md)

if __name__ == "__main__":
    unittest.main()
