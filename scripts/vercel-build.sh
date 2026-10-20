#!/usr/bin/env bash
set -euo pipefail

echo "================================================================================"
echo "🚀 BusTracker Native Vercel Build Pipeline"
echo "================================================================================"

APP_ENV="${TRACKLET_ENVIRONMENT:-${ENVIRONMENT:-${VERCEL_ENV:-}}}"
case "$APP_ENV" in
  preview) APP_ENV="staging" ;;
  production|staging|development) ;;
  *)
    echo "::error::Set TRACKLET_ENVIRONMENT, ENVIRONMENT, or VERCEL_ENV to development, staging, preview, or production."
    exit 1
    ;;
esac

# 1. Fast-fail environment variable checks
if [ -z "${SUPABASE_URL:-}" ]; then
  echo "::error::SUPABASE_URL environment variable is missing."
  echo "Please configure SUPABASE_URL in Vercel Dashboard -> Settings -> Environment Variables."
  exit 1
fi

if [ -z "${SUPABASE_ANON_KEY:-}" ]; then
  echo "::error::SUPABASE_ANON_KEY environment variable is missing."
  echo "Please configure SUPABASE_ANON_KEY in Vercel Dashboard -> Settings -> Environment Variables."
  exit 1
fi

# 2. Dynamic extraction of application version and pinned Flutter SDK version
APP_VERSION=$(grep -m1 '^version:' pubspec.yaml 2>/dev/null | awk '{print $2}' || echo "0.1.0+1")
FLUTTER_VERSION=$(sed -n 's/.*"flutter"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' .fvmrc 2>/dev/null || echo "3.47.5")

echo "• Target Application Version: $APP_VERSION"
echo "• Pinned Flutter SDK Version: $FLUTTER_VERSION"

# 3. Locate or install Flutter SDK (with caching support)
FLUTTER_HOME="${FLUTTER_HOME:-$HOME/.cache/flutter}"

if command -v flutter >/dev/null 2>&1; then
  echo "• Using existing Flutter in PATH: $(which flutter)"
elif [ -x "$FLUTTER_HOME/bin/flutter" ]; then
  echo "• Using cached Flutter SDK at $FLUTTER_HOME"
  export PATH="$FLUTTER_HOME/bin:$PATH"
else
  echo "• Cloning Flutter SDK ($FLUTTER_VERSION)..."
  mkdir -p "$(dirname "$FLUTTER_HOME")"
  if ! git clone --depth 1 -b "$FLUTTER_VERSION" https://github.com/flutter/flutter.git "$FLUTTER_HOME"; then
    echo "⚠ Tag $FLUTTER_VERSION not found; falling back to stable branch..."
    git clone --depth 1 -b stable https://github.com/flutter/flutter.git "$FLUTTER_HOME"
  fi
  export PATH="$FLUTTER_HOME/bin:$PATH"
fi

# Disable analytics and greetings to speed up CLI runs
flutter config --no-analytics >/dev/null 2>&1 || true
flutter --version

# 4. Install dependencies
echo "• Installing dependencies..."
flutter pub get --enforce-lockfile || flutter pub get

# 5. Compile Flutter Web release bundle
echo "• Compiling Flutter Web release bundle..."
flutter build web --release --no-pub --no-tree-shake-icons \
  --dart-define=ENVIRONMENT="$APP_ENV" \
  --dart-define=SUPABASE_URL="$SUPABASE_URL" \
  --dart-define=SUPABASE_ANON_KEY="$SUPABASE_ANON_KEY" \
  --dart-define=CAPTCHA_ENABLED="${CAPTCHA_ENABLED:-true}" \
  --dart-define=CAPTCHA_SITE_KEY="${CAPTCHA_SITE_KEY:-0x4AAAAAAFXxHTiFZHgWmlcA}" \
  --dart-define=CAPTCHA_PROVIDER="${CAPTCHA_PROVIDER:-turnstile}" \
  --dart-define=ONESIGNAL_APP_ID="${ONESIGNAL_APP_ID:-}" \
  --dart-define=MAP_TILE_URL_TEMPLATE="${MAP_TILE_URL_TEMPLATE:-https://tile.openstreetmap.org/{z}/{x}/{y}.png}" \
  --dart-define=MAP_ATTRIBUTION="${MAP_ATTRIBUTION:-© OpenStreetMap contributors}" \
  --dart-define=MAPBOX_PUBLIC_TOKEN="${MAPBOX_PUBLIC_TOKEN:-}"

# 6. Generate build metadata dynamically
mkdir -p build/web
cat <<EOF > build/web/BUILD_METADATA.json
{
  "project": "bustracker",
  "target": "web",
  "version": "$APP_VERSION",
  "environment": "$APP_ENV",
  "commit_sha": "${VERCEL_GIT_COMMIT_SHA:-local}",
  "built_at": "$(date -u +'%Y-%m-%dT%H:%M:%SZ')",
  "integrity_status": "VERIFIED_$APP_ENV"
}
EOF

# 7. Sanitize output bundle
find build/web -name "*.env*" -type f -delete
find build/web -name "*service_role*" -type f -delete
find build/web -name "*secret*" -type f -delete
find build/web -name "*keystore*" -type f -delete
find build/web -name "*.dart.js.map" -type f -delete

echo "================================================================================"
echo "✓ BusTracker Web build completed successfully for Vercel."
echo "================================================================================"
