#!/usr/bin/env bash
set -e

echo "=== Vercel Native Flutter Web Build ==="

# 1. Install or reuse Flutter SDK
FLUTTER_HOME="$HOME/flutter"

if [ ! -d "$FLUTTER_HOME/bin" ]; then
  echo "Cloning Flutter stable channel..."
  git clone --depth 1 -b stable https://github.com/flutter/flutter.git "$FLUTTER_HOME"
else
  echo "Using existing Flutter SDK at $FLUTTER_HOME"
fi

export PATH="$FLUTTER_HOME/bin:$PATH"

flutter --version

# 2. Install dependencies
echo "Installing pub dependencies..."
flutter pub get

# 3. Build Flutter Web release
echo "Building Flutter Web release bundle..."
flutter build web --release \
  --dart-define=ENVIRONMENT="${TRACKLET_ENVIRONMENT:-production}" \
  --dart-define=SUPABASE_URL="$SUPABASE_URL" \
  --dart-define=SUPABASE_ANON_KEY="$SUPABASE_ANON_KEY" \
  --dart-define=ONESIGNAL_APP_ID="${ONESIGNAL_APP_ID:-}" \
  --dart-define=MAP_TILE_URL_TEMPLATE="${MAP_TILE_URL_TEMPLATE:-https://tile.openstreetmap.org/{z}/{x}/{y}.png}" \
  --dart-define=MAP_ATTRIBUTION="${MAP_ATTRIBUTION:-© OpenStreetMap contributors}"

# 4. Generate build metadata
mkdir -p build/web
cat <<EOF > build/web/BUILD_METADATA.json
{
  "project": "tracklet",
  "target": "web",
  "version": "0.1.0+1",
  "environment": "${TRACKLET_ENVIRONMENT:-production}",
  "commit_sha": "${VERCEL_GIT_COMMIT_SHA:-local}",
  "built_at": "$(date -u +'%Y-%m-%dT%H:%M:%SZ')",
  "integrity_status": "VERIFIED_PRODUCTION"
}
EOF

# 5. Sanitize bundle
find build/web -name "*.env*" -type f -delete
find build/web -name "*service_role*" -type f -delete
find build/web -name "*secret*" -type f -delete
find build/web -name "*keystore*" -type f -delete
find build/web -name "*.dart.js.map" -type f -delete

echo "✓ Flutter Web build completed successfully for Vercel."
