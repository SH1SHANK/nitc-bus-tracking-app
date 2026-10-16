# Tracklet

Tracklet is a modern, college-only public-transit tracking application designed specifically for the National Institute of Technology Calicut (NITC) campus community. It delivers real-time campus bus tracking, live telemetry, ETA predictions, route navigation, and transit announcements on Android and Web.

---

## Platforms

- **Android** (API 21+)
- **Web** (Modern evergreen browsers with clean URL paths)

*(Note: iOS is intentionally not targeted).*

---

## How It Works: The Entire System Explained Simply

Think of Tracklet like a private Uber or Google Maps designed specifically for the NITC campus shuttles. The system is split into two halves that work together seamlessly:

1. **The Bus Side:** The bus figures out where it is and sends its GPS coordinates to the cloud.
2. **The Student Side:** The student opens their phone app and sees the bus moving on the campus map in real time with arrival estimates.

```
 [GPS Box on Bus] ──► [Fastify "Toll Booth"] ──► [Supabase Database] ──► [Student's Phone]
   (Hardware fix)       (Security & Filters)      (Authoritative State)      (Map & Route Math)
```

### The Step-by-Step Journey of a Single Bus Update

#### 1. The GPS Box on the Bus (The Hardware)
Inside each NITC shuttle bus, there is a dedicated hardware tracker (powered by an **ESP32** microcontroller equipped with a high-gain GNSS antenna and a cellular SIM module).
- **Every second**, the GPS receiver reads satellite signals and calculates:
  - *Where is the bus right now?* (Latitude and Longitude in standard WGS 84 format).
  - *How fast is it driving?* (e.g. 25 km/h).
  - *Which direction is it pointing?* (Heading in degrees, e.g. 180° South).
- The box numbers every message sequentially (1, 2, 3...) so nothing gets mixed up, wraps it into a secure digital JSON packet, and sends it over the cellular network via HTTPS to our cloud gateway.

#### 2. The Security Guard & Filter (Fastify Backend Gateway)
The bus tracker does not talk directly to the database. Instead, it connects to a **Node.js Fastify API server**, which acts like a secure toll booth:
- **Authentication:** It checks the tracker’s encrypted password (hashed with 8-round Bcrypt) and issues a short-lived token. If an unauthorized device tries to spoof Bus 1, it is kicked out immediately.
- **Physical Sanity Checks:** It validates whether the GPS point makes physical sense:
  - *Is this coordinate actually inside the NITC campus area?* (If a GPS glitch claims the bus is in Bangalore or the ocean, it gets rejected immediately).
  - *Is the speed plausible?* (If a reading claims the bus is moving at 300 km/h, it gets dropped).
- Once screened and verified, Fastify hands the clean GPS packet over to the database.

#### 3. The Brain & Ground Truth (Supabase PostgreSQL Database)
The database is the **single authoritative source of truth**. When a GPS packet arrives, the database executes an atomic stored procedure (`ingest_telemetry_packet`) that does three things in one transaction:
1. **Prevents Duplicates & Collisions:** It places an advisory lock on the bus's record so rapid messages don't collide. If network lag caused message #105 to be sent twice, the database safely ignores the duplicate without corrupting data.
2. **Updates the "Live" Board:** It updates the `bus_current_state` table with the bus's latest location, speed, and timestamp, while simultaneously appending the fix to a historical trip log (`bus_positions`).
3. **Monitors Virtual Stop Fences (Geofencing):** 
   - Every campus bus stop has an invisible 30-meter circle around it.
   - When the bus crosses into that circle, the database logs: *"Bus arrived at Main Gate Stop"*.
   - When it drives 45 meters away, it logs: *"Bus departed Main Gate Stop"*.

#### 4. The Student’s Screen (Flutter Mobile App)
A student standing outside Mega Hostel or the Central Library opens the Tracklet app:
- **Periodic Snapshot:** Every 15 seconds (or via Realtime push), the app calls `get_active_bus_positions_v2()` to get the latest coordinates of all active buses.
- **Smart On-Device Math:** Instead of forcing the cloud database to do heavy analytical calculations, **your phone does the route math locally**:
  - It snaps the bus icon onto the actual campus road map polyline.
  - It reads recent stop events to figure out whether the bus is on its outbound leg or returning on a circular loop.
  - It calculates how many minutes until the bus reaches your stop based on remaining road distance, dwell time at intermediate stops, and smoothed driving speed.

---

### How Real-Life Edge Cases Are Handled

- **Cellular Dead Zones (Offline Buffering):** If a bus passes through an area with zero cellular reception, the hardware tracker doesn't lose data. It saves GPS packets into its onboard flash memory FIFO queue. When the signal returns, it flushes the backlog in an offline batch (`/api/v1/telemetry/batch`).
- **Engine Reboots (Session Epochs):** When the bus engine turns off and on, the tracker restarts its counter from 1. To prevent the server from rejecting message #1 as "old", the tracker does a cold-boot handshake (`/api/v1/auth/reset-session`). The server increments the session `epoch` (e.g. from Epoch 1 to Epoch 2) and allows sequence counting to restart cleanly.
- **Traffic Jams & Bus Breaks (Stale Telemetry):** If a bus stops transmitting or is delayed, Tracklet never fabricates an imaginary moving bus. If telemetry is older than 60 seconds, the bus badge turns **Amber ("Stale")** and the arrival time honestly displays as **"Unavailable"**.

---

### Why the Architecture Is Built This Way

- **Fastify absorbs the firehose:** High-frequency raw GPS pings (up to 300 per minute per bus) are screened, rate-limited, and validated before touching the database.
- **PostgreSQL guarantees consistency:** Sequence locks, foreign keys, and atomic stored procedures prevent race conditions and orphaned trips.
- **Flutter calculates on the client:** Calculating complex curves, loop disambiguation, and arrival minutes happens right inside the mobile app, keeping database CPU load low and cloud hosting costs near zero.

For in-depth architectural specifications, schemas, and API contracts, see the [Canonical Architecture Documentation](docs/README.md).

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
│   ├── tokens/                    # Colors, Outfit/Satoshi typography, spacing, radii
│   └── design_system.dart         # Barrel export
│
├── data/                          # Data models and repository implementations
│   ├── academic/                  # Database-driven department catalog
│   ├── auth/                      # Authentication state, results, and repository
│   ├── campus/                    # Campus building and hostel data
│   ├── preferences/               # Persisted user preference model/state
│   ├── profile/                   # User Profile model & ProfileRepository
│   ├── supabase/                  # Supabase client provider & safe initialization
│   └── transit/                   # Bus, route, stop, geometry, and repository
│
├── services/                      # Platform & hardware capability wrappers
│   ├── location/                  # LocationService (geolocator wrapper with typed states)
│   ├── maps/                      # MapAdapter & MapConfig boundary
│   ├── notifications/             # OneSignal notification service boundary
│   └── storage/                   # SharedPreferences key-value wrapper
│
└── features/                      # Feature modules
    ├── auth/                      # Sign-in, registration, and password recovery
    ├── home/                      # Nearest stop, next bus, and upcoming departures
    ├── map/                       # Campus map, bus/stop markers, route details
    ├── onboarding/                # Academic profile and setup flow
    ├── profile/                   # Academic profile and account information
    └── settings/                  # Preferences, notifications, and help
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

Supabase credentials are required for authentication and database-driven transit data. When transit data is unavailable, Tracklet shows an empty or retryable state instead of substituting synthetic campus stops, routes, or buses. OneSignal remains optional.

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
