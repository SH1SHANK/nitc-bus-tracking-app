#!/usr/bin/env bash
set -euo pipefail

# Pinned Flutter SDK version matching .fvmrc and pubspec.yaml
FLUTTER_VERSION="${FLUTTER_VERSION:-3.47.5}"
INSTALL_DIR="${FLUTTER_HOME:-$HOME/.flutter-sdk}"

echo "=== Vercel Install: Setting up Flutter $FLUTTER_VERSION ==="

if command -v flutter >/dev/null 2>&1 && flutter --version 2>&1 | grep -q "$FLUTTER_VERSION"; then
  echo "Using Flutter $(flutter --version | head -n 1) from system PATH."
elif [ -x "$INSTALL_DIR/bin/flutter" ] && "$INSTALL_DIR/bin/flutter" --version 2>&1 | grep -q "$FLUTTER_VERSION"; then
  echo "Using Flutter $FLUTTER_VERSION already installed at $INSTALL_DIR."
  export PATH="$INSTALL_DIR/bin:$PATH"
else
  echo "Downloading pinned Flutter SDK $FLUTTER_VERSION to $INSTALL_DIR..."
  rm -rf "$INSTALL_DIR"
  mkdir -p "$(dirname "$INSTALL_DIR")"
  git clone --depth 1 --branch "$FLUTTER_VERSION" https://github.com/flutter/flutter.git "$INSTALL_DIR"
  export PATH="$INSTALL_DIR/bin:$PATH"
fi

git config --global --add safe.directory "$INSTALL_DIR" 2>/dev/null || true

echo "=== Verifying Flutter SDK ==="
flutter --version

echo "=== Pre-caching Web Artifacts ==="
flutter precache --web

echo "=== Resolving Locked Dependencies ==="
flutter pub get
