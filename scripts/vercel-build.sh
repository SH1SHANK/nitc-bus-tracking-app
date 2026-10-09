#!/usr/bin/env bash
set -e

echo "=== Checking Flutter SDK ==="
if ! command -v flutter &> /dev/null; then
  echo "Flutter not found in PATH. Downloading Flutter stable..."
  git clone https://github.com/flutter/flutter.git --depth 1 -b stable /tmp/flutter
  export PATH="/tmp/flutter/bin:$PATH"
fi

flutter --version

echo "=== Getting dependencies ==="
flutter pub get

echo "=== Building Flutter Web Release ==="
flutter build web --release \
  --dart-define=ENVIRONMENT="${ENVIRONMENT:-production}" \
  --dart-define=SUPABASE_URL="${SUPABASE_URL:-}" \
  --dart-define=SUPABASE_ANON_KEY="${SUPABASE_ANON_KEY:-}" \
  --dart-define=MAPBOX_PUBLIC_TOKEN="${MAPBOX_PUBLIC_TOKEN:-}" \
  --dart-define=ONESIGNAL_APP_ID="${ONESIGNAL_APP_ID:-}" \
  --dart-define=MAP_TILE_URL_TEMPLATE="${MAP_TILE_URL_TEMPLATE:-https://tile.openstreetmap.org/{z}/{x}/{y}.png}" \
  --dart-define=MAP_ATTRIBUTION="${MAP_ATTRIBUTION:-© OpenStreetMap contributors}"
