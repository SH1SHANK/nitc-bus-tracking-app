# Tracklet

Tracklet is a modern, college-only public-transit tracking application designed specifically for the National Institute of Technology Calicut (NITC) campus community. It delivers real-time campus bus tracking, live telemetry, ETA predictions, route navigation, and transit announcements on Android and Web.

---

## Platforms

- **Android** (API 21+)
- **Web** (Modern evergreen browsers with clean URL paths)

*(Note: iOS is intentionally not targeted).*

---

## Stack

- **Framework**: [Flutter](https://flutter.dev) (SDK `3.47.5`, Dart `3.13.4`, pinned in `.fvmrc`)
- **State Management**: [Riverpod](https://riverpod.dev) (`flutter_riverpod`)
- **Routing**: [go_router](https://pub.dev/packages/go_router) with `StatefulShellRoute.indexedStack` and clean browser URL paths
- **Backend & Realtime**: [Supabase](https://supabase.com) (`supabase_flutter`)
- **Notifications**: [OneSignal](https://onesignal.com) (`onesignal_flutter`)
- **Spatial / Maps**: [flutter_map](https://pub.dev/packages/flutter_map) + [latlong2](https://pub.dev/packages/latlong2), behind `services/maps`
- **Design System**: [Moon Design System](https://moon.io) foundation (`moon_design`) + Tracklet design layer (Outfit and Satoshi typography)

---

## Architecture

Tracklet enforces a simple, layered architecture designed to keep UI, application state, domain data, and external platform services strictly decoupled:

```
lib/
├── main.dart                      # Application entrypoint
│
├── app/                           # App initialization & navigation shell
│   ├── app.dart                   # Root MaterialApp with theme & routing
│   ├── bootstrap.dart             # Asynchronous service bootstrap & URL strategy
│   ├── router.dart                # go_router declarative routes
│   └── app_shell.dart             # Bottom navigation shell with emphasized Map action
│
├── core/                          # Cross-cutting utilities & configuration
│   ├── config/                    # Compile-time AppConfig boundary
│   ├── errors/                    # AppException hierarchy
│   ├── formatting/                # TransitFormatter (ETAs, distances, speed)
│   ├── geo/                       # GeoPoint platform-neutral coordinate abstraction
│   └── logging/                   # AppLogger structured logging
│
├── design_system/                 # Reusable Tracklet design system foundation
│   ├── components/                # TrackletButton, TrackletCard, TrackletStatusBadge, etc.
│   ├── theme/                     # TrackletTheme combining Material 3 & MoonDesign
│   ├── tokens/                    # Colors, typography (DM Sans), spacing, radii
│   └── design_system.dart         # Barrel export
│
├── data/                          # Data models and repository implementations
│   ├── profile/                   # User Profile model & ProfileRepository
│   ├── supabase/                  # Supabase client provider & safe initialization
│   └── transit/                   # Bus, BusPosition, BusRoute, Stop, TransitRepository
│
├── services/                      # Platform & hardware capability wrappers
│   ├── location/                  # LocationService (geolocator wrapper with typed states)
│   ├── maps/                      # MapAdapter & MapConfig boundary
│   ├── notifications/             # OneSignal notification service boundary
│   └── storage/                   # SharedPreferences key-value wrapper
│
└── features/                      # Feature modules
    ├── home/                      # Minimal greeting, nearest stop, next bus card, upcoming buses
    ├── map/                       # Spatial live campus map, bus/stop markers, telemetry sheet
    └── profile/                   # Academic profile, notification settings, app info
```

### Architectural Guardrails

Architectural boundary enforcement is automated via `dart run tool/verify_architecture.dart`:
- Feature modules cannot cross-import other feature modules.
- Feature UI code cannot directly import external vendor SDKs (`supabase_flutter`, `onesignal_flutter`, `geolocator`).
- Shared layers cannot depend on feature modules.
- The design system cannot depend on data, services, or features.
- No `dart:io` leaks into shared web code.

---

## Repository Structure

```
nitc-bus-tracking-app/
├── .github/
│   ├── workflows/                 # CI and manual release artifact workflows
│   ├── dependabot.yml
│   ├── CODEOWNERS
│   └── pull_request_template.md
├── android/                       # Android native host project
├── assets/                        # Static application assets
│   ├── fonts/
│   ├── icons/
│   └── images/
├── config/                        # Committed templates; real files are ignored
│   ├── dev.example.json
│   ├── staging.example.json
│   └── prod.example.json
├── docs/                          # Architecture & design documentation
├── integration_test/
│   └── smoke_test.dart            # End-to-end integration smoke test
├── lib/                           # Application source code
├── supabase/
│   └── migrations/                # Transit & RLS SQL migrations
├── test/                          # Unit & widget tests
├── tool/
│   └── verify_architecture.dart   # Architectural lint script
├── .fvmrc                         # Flutter SDK version pin
├── .gitignore                     # Production Git ignore rules
├── analysis_options.yaml          # Strict analyzer rules
├── pubspec.yaml                   # Dependency declarations
└── README.md
```

---

## Development & Setup

### Prerequisites

- Flutter SDK `3.47.5` (or latest stable)
- Dart SDK `3.13.4`
- Java 17+ (for Android builds)
- Optional: [FVM](https://fvm.app/) (configured in `.fvmrc`)

### 1. Clone & Install Dependencies

```bash
git clone https://github.com/SH1SHANK/nitc-bus-tracking-app.git
cd nitc-bus-tracking-app
flutter pub get
```

### 2. Configure Environment

Copy the configuration template:

```bash
cp config/env.json.example config/env.json
```

Edit `config/env.json` with your development endpoints. `config/env.json` is gitignored and will never be committed:

```json
{
  "ENVIRONMENT": "development",
  "SUPABASE_URL": "https://your-project.supabase.co",
  "SUPABASE_ANON_KEY": "your-anon-key-here",
  "ONESIGNAL_APP_ID": "your-onesignal-app-id",
  "MAP_TILE_URL_TEMPLATE": "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
  "MAP_ATTRIBUTION": "© OpenStreetMap contributors",
  "CAMPUS_NAME": "National Institute of Technology Calicut",
  "CAMPUS_CENTER_LAT": 11.3216,
  "CAMPUS_CENTER_LNG": 75.9337,
  "DEFAULT_ZOOM": 16.5
}
```

*Note: If no Supabase or OneSignal credentials are supplied, Tracklet automatically operates in seamless local/offline seed simulation mode for NITC campus transit.*

### 3. Run the Application

#### Android
```bash
flutter run -d android --dart-define-from-file=config/env.json
```

#### Web
```bash
flutter run -d chrome --dart-define-from-file=config/env.json
```

---

## Testing & Quality Assurance

Run all checks prior to submitting changes:

```bash
# Verify architecture boundaries
dart run tool/verify_architecture.dart

# Check code formatting
dart format --set-exit-if-changed .

# Static code analysis (0 errors/warnings)
flutter analyze

# Unit and widget test suite
flutter test

# Integration smoke tests
flutter test integration_test/smoke_test.dart

# Build validation
flutter build web --release
flutter build apk --debug
```

---

## Engineering documentation

- [Architecture](docs/architecture.md)
- [Development guide](docs/development.md)
- [Release checklist](docs/release-checklist.md)
- [Changelog](CHANGELOG.md)

The repository has no `LICENSE` file yet. Licensing is a project-owner decision and has intentionally not been inferred.
