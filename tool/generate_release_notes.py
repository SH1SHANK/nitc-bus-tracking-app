#!/usr/bin/env python3
"""
Automated Changelog & Version Tag Resolver for Tracklet (NITC Bus Tracking App)
Generates structured, categorized release notes from Git commit history and
appends an Artifact Verification & Installation Guide with SHA-256 checksums.
"""

import argparse
import hashlib
import json
import os
import re
import subprocess
import sys

REPO_DEFAULT_URL = "https://github.com/SH1SHANK/nitc-bus-tracking-app"

def get_pubspec_version(pubspec_path="pubspec.yaml"):
    """Reads and parses canonical version from pubspec.yaml."""
    if not os.path.isfile(pubspec_path):
        raise FileNotFoundError(f"pubspec.yaml not found at: {pubspec_path}")

    with open(pubspec_path, "r", encoding="utf-8") as f:
        content = f.read()

    match = re.search(r"^version:\s*([0-9]+\.[0-9]+\.[0-9]+)(?:\+([0-9]+))?", content, re.MULTILINE)
    if not match:
        raise ValueError("Could not find valid 'version: X.Y.Z+N' in pubspec.yaml")

    semver = match.group(1)
    build_number = match.group(2) or "1"
    canonical = f"{semver}+{build_number}"
    return {
        "semver": semver,
        "build_number": build_number,
        "canonical": canonical,
        "tag": f"v{semver}",
        "full_tag": f"v{canonical}"
    }

def validate_tag_against_pubspec(tag, pubspec_info):
    """Validates that a given tag corresponds to the version defined in pubspec.yaml."""
    normalized_tag = tag.lstrip("v")
    # Accept either 0.1.0 or 0.1.0+1
    if normalized_tag not in (pubspec_info["semver"], pubspec_info["canonical"]):
        return False
    return True

def run_git(args):
    """Executes a git command and returns standard output trimmed."""
    try:
        return subprocess.check_output(["git"] + args, stderr=subprocess.DEVNULL).decode("utf-8").strip()
    except subprocess.CalledProcessError:
        return ""

def find_previous_tag(current_tag=None):
    """Finds the most recent release tag prior to current_tag, or returns root commit."""
    # List tags sorted by commit date descending
    all_tags = run_git(["tag", "--sort=-creatordate"]).splitlines()
    all_tags = [t.strip() for t in all_tags if t.strip()]

    filtered = [t for t in all_tags if t != current_tag]
    if filtered:
        return filtered[0]

    # If no prior tag, locate root commit
    root_commit = run_git(["rev-list", "--max-parents=0", "HEAD"]).splitlines()
    if root_commit:
        return root_commit[0]
    return ""

def get_commits_between(base_ref, head_ref="HEAD"):
    """Returns list of commits between base_ref and head_ref."""
    if not base_ref or base_ref == head_ref:
        commit_range = head_ref
    else:
        commit_range = f"{base_ref}..{head_ref}"

    output = run_git(["log", "--no-merges", "--pretty=format:%H%x09%s%x09%an", commit_range])
    commits = []
    if not output:
        return commits

    for line in output.splitlines():
        parts = line.split("\t")
        if len(parts) >= 2:
            full_sha = parts[0]
            subject = parts[1]
            author = parts[2] if len(parts) > 2 else "Contributor"
            commits.append({
                "sha": full_sha,
                "short_sha": full_sha[:7],
                "subject": subject,
                "author": author
            })
    return commits

def categorize_commits(commits):
    """Categorizes commits into clean, semantic release sections."""
    categories = {
        "features": {
            "title": "🚀 Features & UX Improvements",
            "commits": []
        },
        "fixes": {
            "title": "🐛 Bug Fixes",
            "commits": []
        },
        "security_infra": {
            "title": "🔒 Security & Infrastructure",
            "commits": []
        },
        "docs_refactor": {
            "title": "📚 Documentation & Refactoring",
            "commits": []
        }
    }

    feat_pattern = re.compile(r"^(feat|perf)(\([^\)]+\))?[:!]\s*(.+)$", re.IGNORECASE)
    fix_pattern = re.compile(r"^(fix|patch)(\([^\)]+\))?[:!]\s*(.+)$", re.IGNORECASE)
    sec_infra_pattern = re.compile(r"^(sec|security|ci|build|chore|deploy)(\([^\)]+\))?[:!]\s*(.+)$", re.IGNORECASE)
    docs_refactor_pattern = re.compile(r"^(docs|refactor|test|style)(\([^\)]+\))?[:!]\s*(.+)$", re.IGNORECASE)

    for c in commits:
        subj = c["subject"].strip()

        if fix_pattern.match(subj):
            categories["fixes"]["commits"].append(c)
        elif sec_infra_pattern.match(subj):
            categories["security_infra"]["commits"].append(c)
        elif feat_pattern.match(subj):
            categories["features"]["commits"].append(c)
        elif docs_refactor_pattern.match(subj):
            categories["docs_refactor"]["commits"].append(c)
        else:
            # Fallback heuristic based on keywords
            lower = subj.lower()
            if any(k in lower for k in ["fix", "bug", "crash", "issue", "resolve"]):
                categories["fixes"]["commits"].append(c)
            elif any(k in lower for k in ["sec", "token", "auth", "ci", "action", "workflow", "deploy", "keystore"]):
                categories["security_infra"]["commits"].append(c)
            elif any(k in lower for k in ["doc", "readme", "comment", "refactor", "clean"]):
                categories["docs_refactor"]["commits"].append(c)
            else:
                categories["features"]["commits"].append(c)

    return categories

def compute_sha256(filepath):
    """Computes SHA-256 hash for a local file."""
    h = hashlib.sha256()
    with open(filepath, "rb") as f:
        while chunk := f.read(65536):
            h.update(chunk)
    return h.hexdigest()

def get_artifact_checksums(artifacts_dir=None, checksums_file=None):
    """Retrieves or calculates checksums for release artifacts."""
    checksums = {}

    if checksums_file and os.path.isfile(checksums_file):
        with open(checksums_file, "r", encoding="utf-8") as f:
            for line in f:
                line = line.strip()
                if line and not line.startswith("#"):
                    parts = line.split(maxsplit=1)
                    if len(parts) == 2:
                        checksums[os.path.basename(parts[1])] = parts[0]

    if artifacts_dir and os.path.isdir(artifacts_dir):
        for fname in os.listdir(artifacts_dir):
            fpath = os.path.join(artifacts_dir, fname)
            if os.path.isfile(fpath) and fname not in checksums:
                checksums[fname] = compute_sha256(fpath)

    return checksums

def generate_markdown(version_info, release_tag, prev_tag, categories, checksums, repo_url=REPO_DEFAULT_URL):
    """Generates the full Markdown release notes document."""
    semver = version_info["semver"]
    build_num = version_info["build_number"]

    lines = []
    lines.append(f"# Tracklet {release_tag}")
    lines.append("")
    lines.append(f"**Application:** Tracklet — NITC Campus Bus Tracking  ")
    lines.append(f"**Version:** `{semver}` (Build `{build_num}`)  ")
    lines.append(f"**Release Tag:** `{release_tag}`  ")
    if prev_tag:
        lines.append(f"**Previous Release:** [`{prev_tag}`]({repo_url}/releases/tag/{prev_tag})  ")
    lines.append("")
    lines.append("---")
    lines.append("")
    lines.append("## What's Changed")
    lines.append("")

    total_commits = sum(len(cat["commits"]) for cat in categories.values())
    if total_commits == 0:
        lines.append("*No commit changes detected since the previous reference.*")
        lines.append("")
    else:
        for key in ["features", "fixes", "security_infra", "docs_refactor"]:
            cat = categories[key]
            if cat["commits"]:
                lines.append(f"### {cat['title']}")
                lines.append("")
                for c in cat["commits"]:
                    sha_link = f"[`{c['short_sha']}`]({repo_url}/commit/{c['sha']})"
                    lines.append(f"* {c['subject']} in {sha_link} by @{c['author']}")
                lines.append("")

    lines.append("---")
    lines.append("")
    lines.append("## 📦 Artifact Verification & Installation Guide")
    lines.append("")
    lines.append("Choose the appropriate package for your device. For modern Android smartphones, the **`arm64-v8a`** APK is recommended for optimal performance and reduced download size.")
    lines.append("")
    lines.append("| Downloadable Artifact | Architecture / Target | Minimum OS | Recommended For | SHA-256 Checksum |")
    lines.append("| :--- | :--- | :--- | :--- | :--- |")

    catalog = [
        (
            f"tracklet-v{semver}-arm64-v8a.apk",
            "64-bit ARM (`arm64-v8a`)",
            "Android 5.0 (API 21)",
            "**Recommended for 95%+ of modern smartphones** (Pixel, Galaxy, OnePlus, Xiaomi)",
        ),
        (
            f"tracklet-v{semver}-universal.apk",
            "Universal (All ABIs)",
            "Android 5.0 (API 21)",
            "Compatibility fallback / sideloading on any Android device",
        ),
        (
            f"tracklet-v{semver}-armeabi-v7a.apk",
            "32-bit ARM (`armeabi-v7a`)",
            "Android 5.0 (API 21)",
            "Older or budget 32-bit smartphones and legacy tablets",
        ),
        (
            f"tracklet-v{semver}-x86_64.apk",
            "64-bit x86 (`x86_64`)",
            "Android 5.0 (API 21)",
            "Android Studio Emulators and Intel-based Chromebooks",
        ),
        (
            f"tracklet-v{semver}.aab",
            "Android App Bundle (`.aab`)",
            "Android 5.0 (API 21)",
            "Google Play Console release submission",
        ),
        (
            f"tracklet-v{semver}-debug-symbols.tar.gz",
            "R8 / Native Debug Symbols",
            "N/A",
            "Stack unwinding and crash symbolication",
        ),
        (
            "BUILD_METADATA.json",
            "Build Provenance Manifest",
            "N/A",
            "Cryptographic build verification and Git audit trail",
        ),
        (
            "checksums.sha256",
            "Checksum Manifest",
            "N/A",
            "Automated integrity verification",
        )
    ]

    for fname, arch, min_os, purpose in catalog:
        csum = checksums.get(fname, "`Pending CI build`")
        if csum != "`Pending CI build`":
            csum = f"`{csum[:16]}...`"
        lines.append(f"| **`{fname}`** | {arch} | {min_os} | {purpose} | {csum} |")

    lines.append("")
    lines.append("### Verification Instructions")
    lines.append("To verify the integrity of any downloaded artifact locally:")
    lines.append("```bash")
    lines.append("# Check all files against checksums.sha256")
    lines.append("sha256sum -c checksums.sha256")
    lines.append("")
    lines.append("# Or compute an individual file's hash")
    lines.append(f"shasum -a 256 tracklet-v{semver}-arm64-v8a.apk")
    lines.append("```")
    lines.append("")
    lines.append("### Sideloading Instructions")
    lines.append("1. Download the `.apk` directly to your phone via Chrome or a file manager.")
    lines.append("2. Open the downloaded file. When prompted, permit your browser to **Install unknown apps**.")
    lines.append("3. Complete installation and authenticate using your `@nitc.ac.in` institute account.")

    return "\n".join(lines)

def main():
    parser = argparse.ArgumentParser(description="Generate release notes and changelog from Git history.")
    parser.add_argument("--pubspec", default="pubspec.yaml", help="Path to pubspec.yaml")
    parser.add_argument("--tag", default="", help="Target release tag (e.g. v0.1.0 or v0.1.0+1)")
    parser.add_argument("--prev-tag", default="", help="Previous tag override")
    parser.add_argument("--artifacts-dir", default="", help="Directory containing compiled artifacts")
    parser.add_argument("--checksums-file", default="", help="Path to checksums.sha256 file")
    parser.add_argument("--output", default="", help="Path to write output RELEASE_NOTES.md")
    parser.add_argument("--repo-url", default=REPO_DEFAULT_URL, help="GitHub repository URL")
    parser.add_argument("--resolve-tag", action="store_true", help="Print derived/validated tag and exit")
    parser.add_argument("--validate-tag", action="store_true", help="Validate tag strictly against pubspec.yaml")
    parser.add_argument("--json", action="store_true", help="Output release data as JSON")

    args = parser.parse_args()

    pubspec_info = get_pubspec_version(args.pubspec)

    # Determine target release tag
    release_tag = args.tag.strip() if args.tag else pubspec_info["tag"]
    if not release_tag.startswith("v"):
        release_tag = f"v{release_tag}"

    if args.validate_tag:
        if not validate_tag_against_pubspec(release_tag, pubspec_info):
            print(f"Error: Release tag '{release_tag}' does not match pubspec.yaml version '{pubspec_info['canonical']}' (or '{pubspec_info['semver']}').", file=sys.stderr)
            sys.exit(1)

    if args.resolve_tag:
        # Format for GitHub Actions environment injection
        print(f"RELEASE_TAG={release_tag}")
        print(f"VERSION={pubspec_info['semver']}")
        print(f"BUILD_NUMBER={pubspec_info['build_number']}")
        print(f"CANONICAL_VERSION={pubspec_info['canonical']}")
        return

    # Find previous tag
    prev_tag = args.prev_tag.strip() if args.prev_tag else find_previous_tag(release_tag)

    # Parse commits
    commits = get_commits_between(prev_tag, "HEAD")
    categories = categorize_commits(commits)

    # Gather checksums
    checksums = get_artifact_checksums(args.artifacts_dir, args.checksums_file)

    # Build Markdown notes
    markdown_content = generate_markdown(pubspec_info, release_tag, prev_tag, categories, checksums, args.repo_url)

    if args.json:
        data = {
            "tag": release_tag,
            "previous_tag": prev_tag,
            "version": pubspec_info,
            "commits_count": len(commits),
            "categories": categories,
            "checksums": checksums,
            "markdown": markdown_content
        }
        print(json.dumps(data, indent=2))
        return

    if args.output:
        os.makedirs(os.path.dirname(os.path.abspath(args.output)), exist_ok=True)
        with open(args.output, "w", encoding="utf-8") as f:
            f.write(markdown_content)
        print(f"✓ Release notes written to: {args.output}")
    else:
        print(markdown_content)

if __name__ == "__main__":
    main()
