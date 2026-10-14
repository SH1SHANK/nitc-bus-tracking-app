#!/usr/bin/env bash
set -euo pipefail

FLUTTER_VERSION="${FLUTTER_VERSION:-3.47.5}"
INSTALL_DIR="${FLUTTER_HOME:-$HOME/.flutter-sdk}"

echo "=== Vercel Build: Ensuring Flutter $FLUTTER_VERSION is available ==="

if command -v flutter >/dev/null 2>&1 && flutter --version 2>&1 | grep -q "$FLUTTER_VERSION"; then
  echo "Using system Flutter $(flutter --version | head -n 1)"
elif [ -x "$INSTALL_DIR/bin/flutter" ]; then
  echo "Adding $INSTALL_DIR/bin to PATH"
  export PATH="$INSTALL_DIR/bin:$PATH"
else
  echo "Flutter $FLUTTER_VERSION not found in PATH or $INSTALL_DIR. Running vercel-install.sh..."
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  bash "$SCRIPT_DIR/vercel-install.sh"
  export PATH="$INSTALL_DIR/bin:$PATH"
fi

git config --global --add safe.directory "$INSTALL_DIR" 2>/dev/null || true

echo "=== Flutter Environment ==="
flutter --version

echo "=== Ensuring Dependencies ==="
flutter pub get

echo "=== Building Flutter Web Release ==="
flutter build web --release \
  --dart-define=ENVIRONMENT="${ENVIRONMENT:-production}" \
  --dart-define=SUPABASE_URL="${SUPABASE_URL:-}" \
  --dart-define=SUPABASE_ANON_KEY="${SUPABASE_ANON_KEY:-}" \
  --dart-define=ONESIGNAL_APP_ID="${ONESIGNAL_APP_ID:-}" \
  --dart-define=MAP_TILE_URL_TEMPLATE="${MAP_TILE_URL_TEMPLATE:-https://tile.openstreetmap.org/{z}/{x}/{y}.png}" \
  --dart-define=MAP_ATTRIBUTION="${MAP_ATTRIBUTION:-© OpenStreetMap contributors}"

echo "=== Verifying Web Build Output ==="
if [ ! -f "build/web/index.html" ]; then
  echo "Error: build/web/index.html not found!" >&2
  exit 1
fi

echo "=== Build Succeeded! Web output ready in build/web ==="
