# BusTracker • NITC Campus Transit

[![Live Web App](https://img.shields.io/badge/Live%20App-nitc--bustracker.vercel.app-6366F1?style=for-the-badge&logo=vercel&logoColor=white)](https://nitc-bustracker.vercel.app)
[![Release](https://img.shields.io/badge/Release-v1.0.0--rc--1-10B981?style=for-the-badge&logo=github)](https://github.com/SH1SHANK/nitc-bus-tracking-app/releases/tag/v1.0.0-rc-1)
[![Flutter](https://img.shields.io/badge/Flutter-3.47.5-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.13.4-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)
[![Supabase](https://img.shields.io/badge/Backend-Supabase-3ECF8E?style=for-the-badge&logo=supabase&logoColor=white)](https://supabase.com)
[![Tests](https://img.shields.io/badge/Tests-389%20Passed-brightgreen?style=for-the-badge&logo=checkmarx&logoColor=white)](test/)

**BusTracker** is the official next-generation campus public transit tracking platform engineered specifically for the **National Institute of Technology Calicut (NITC)** community. Built from the ground up with Flutter, Fastify, and Supabase, BusTracker delivers sub-second GNSS bus location streaming, intelligent road-snapped arrival estimates (ETAs), dynamic stop geofencing, and an illustrative campus vector map on **Android** and **Web**.

---

## 🌐 Live Access

- **Production Web Application**: [https://nitc-bustracker.vercel.app](https://nitc-bustracker.vercel.app)
- **Target Platforms**:
  - **Android** (API 21+, Android 5.0 through 15)
  - **Web** (Chrome, Firefox, Safari, Edge with HTML5 Canvas & Wasm support)

---

## ✨ Detailed Features

### 📍 1. Real-Time GNSS Bus Tracking
- **Sub-Second Streaming**: Live telemetry emitted by on-bus ESP32 cellular trackers is validated and streamed via WebSocket to active rider screens.
- **Polyline Route Snapping**: Raw GPS coordinates are snapped to canonical campus road polylines, completely eliminating GPS jitter and cross-building drifting.
- **Shortest-Arc Heading Rotation**: Bus markers fluidly rotate to face their true heading along the shortest angular arc, preventing awkward 360° spins.
- **No Synthetic Buses**: The system guarantees zero synthetic or hallucinated buses. If a bus stops transmitting or is delayed past 60 seconds, it is honestly marked as **Stale (Amber status)** and its ETA displays as **Unavailable**.

### ⏱️ 2. Intelligent Arrival (ETA) Engine
- **Remaining Road Distance**: ETAs are computed locally on the client along actual road segments rather than straight-line distance.
- **Dwell Time Compensation**: Factoring scheduled and observed dwell times at intermediate stops along the route.
- **Velocity Smoothing**: Moving-average velocity filters smooth out momentary stops at traffic intersections or speed breakers.

### 🗺️ 3. Cartographic Campus Map
- **Custom NITC Cartography**: Geographically grounded campus map derived from OpenStreetMap (OSM) building footprint geometry and Mapbox vector tile overlays.
- **Campus Landmark Footprints**: Crisp, simplified vector outlines of academic blocks, administrative complexes, hostels (Mega, PG, Ladies), and Central Library.
- **Interactive Bus & Stop Markers**: Tappable stops showing upcoming departures, and interactive bus markers displaying current speed, capacity, and active driver notes.
- **Dynamic Centering & Recenter**: Smooth spring cameras to lock onto selected buses or re-center to the user's current campus location.

### 🎭 4. 3D Voxel Avatar Personalization
- **DiceBear 3D Voxel Engine**: Unique 3D voxel avatar generation for all students and riders.
- **Instant Dice Rolling ("Roll New")**: Randomize and browse 8 fresh personas with a single tap of the dice button (`Icons.casino_rounded`).
- **Clean Visual Cards**: Pure visual avatar selection with no seed string clutter or awkward usernames.
- **Haptic Feedback**: Selection clicks and impact haptics provide satisfying micro-interactions when switching personas.

### 🚀 5. Fluid Navigation Shell & Splash Screen
- **Floating Dock Navigation**: Modern, curved bottom dock featuring official Lucide animated navigation icons (`home`, `map`, `user`).
- **Elevated Center MAP Button**: High-visibility circular action button with the Lucide folding map icon for instantaneous one-tap transit map navigation.
- **Fluid Splash Transition**: Clean, centered BusTracker brand lockup with entry/exit animations and robust route hydration that directly resolves sub-routes like `/home`, `/login`, `/map`, and `/profile`.

### 🔐 6. Secure Authentication & Guest Mode
- **Institute Email Sign-In**: Dedicated authentication for `@nitc.ac.in` students, faculty, and campus staff.
- **Guest Explorer Mode**: Instant one-tap guest access allowing visitors and prospective students to inspect live transit without mandatory registration.
- **Password Recovery**: Self-serve password reset flows with validated deep-linking and security token verification.
- **Bot Mitigation**: Cloudflare Turnstile token validation on authentication endpoints.

### 🛑 7. Virtual Stop Geofencing & Timetables
- **Atomic Database Geofencing**: 30-meter arrival circles and 45-meter departure thresholds evaluated atomically inside PostgreSQL stored procedures (`ingest_telemetry_packet`).
- **Stop Selector Sheet**: Search, filter, and sort campus stops by nearest walking distance or earliest upcoming bus.
- **Full Transit Schedules**: View comprehensive timetables for all active loops (Campus Inner Loop, East Campus Shuttle, Hostel Circular).

### 🎨 8. Moon Design System v1 & Dark Mode
- **Zero Glassmorphic Gradients**: Built exclusively with solid, high-contrast surfaces conforming to the Moon Design System v1 specification.
- **Adaptive Day/Night Themes**: Seamless contrast switching between light and dark modes with dedicated dark-mode typography tinting.
- **Accessible Semantics**: Complete screen reader labels, scalable font factors, and minimum 48x48 tap targets across all interactive elements.

### 🛡️ 9. Zero-Legacy Backend Infrastructure
- **Strict Bcrypt Standard**: Hardware tracker secrets hashed exclusively with 8-round Bcrypt (`pgcrypto` `gen_salt('bf', 8)`).
- **16-Character Secret Invariant**: Rigidly enforced 16-character minimum secret length across API schemas, database functions, and provisioning tools.
- **Monotonic Reboot Sessions**: Tracker reboot handshake (`POST /api/v1/auth/reset-session`) advancing session epochs and resetting sequence counters to 0 to prevent replay attacks.
- **Advisory-Locked Telemetry Ingestion**: High-concurrency Postgres advisory locks preventing duplicate or out-of-order packet processing under cellular jitter.

---

## 🏗️ System Architecture & Data Flow

```
 ┌─────────────────┐       HTTPS       ┌────────────────────────┐
 │ Hardware GNSS   │ ────────────────► │ Fastify Cloud Gateway  │
 │ Tracker on Bus  │  (Bcrypt Auth &   │ (Rate Limiting, Sanity │
 │ (ESP32 + SIM)   │   16-char secret) │  Checks & Sanitization)│
 └─────────────────┘                   └───────────┬────────────┘
                                                   │
                                                   ▼
 ┌─────────────────┐    Realtime/RPC   ┌────────────────────────┐
 │ Student Device  │ ◄──────────────── │ Supabase PostgreSQL    │
 │ (Flutter App on │   (Sub-second WS) │ (ingest_telemetry_rpc, │
 │  Android & Web) │                   │  Advisory Lock, Fence) │
 └─────────────────┘                   └────────────────────────┘
```

### The Journey of a GPS Update
1. **The Bus Emits**: The on-bus tracker calculates coordinates, speed, and heading every 1 second, packages them into a sequence-numbered JSON payload, and posts to the cloud gateway.
2. **Fastify Screens**: The gateway validates the device token, checks whether coordinates fall within valid NIT Calicut geographic bounding boxes, and filters out non-physical velocities (>80 km/h).
3. **PostgreSQL Ingests**: In a single atomic transaction protected by an advisory lock:
   - Duplicates and out-of-order sequence packets are rejected.
   - `bus_current_state` is updated and historical trip points are appended to `bus_positions`.
   - Virtual 30m/45m stop geofences trigger arrival/departure events.
4. **The Client Visualizes**: The student's phone receives the updated state, snaps the bus to the campus road polyline, recalculates ETA, and smoothly rotates the bus marker.

---

## 🛠️ Technology Stack

| Layer | Technologies |
|---|---|
| **Frontend Framework** | [Flutter](https://flutter.dev) (SDK `3.47.5`, Dart `3.13.4`, pinned in `.fvmrc`) |
| **State Architecture** | [Riverpod](https://riverpod.dev) (`flutter_riverpod` 3.4.3) with Notifier providers |
| **Navigation & Routing** | [go_router](https://pub.dev/packages/go_router) 18.0.2 with `StatefulShellRoute.indexedStack` |
| **Maps & Cartography** | [flutter_map](https://pub.dev/packages/flutter_map), [latlong2](https://pub.dev/packages/latlong2), Mapbox Vector Tiles |
| **Icons & Motion** | [flutter_lucide_animated](https://pub.dev/packages/flutter_lucide_animated), custom Lucide icon fonts |
| **Design System** | Moon Design System v1 tokens, Satoshi & Outfit typography |
| **Backend & Realtime** | [Supabase](https://supabase.com) (PostgreSQL 15, PostGIS, Realtime WebSockets, Edge Functions) |
| **Ingestion Gateway** | [Fastify](https://fastify.io) (Node.js 20+, TypeScript, Bcrypt 8 rounds) |
| **Web Distribution** | [Vercel](https://vercel.com) Edge Network with custom HTTP Content Security Policy |
| **CI / CD Pipeline** | GitHub Actions (Dart format, analyzer, architecture linter, APK signer, Vercel deploy) |

---

## 🚀 Getting Started

### Prerequisites
- [Flutter SDK](https://flutter.dev/docs/get-started/install) `3.47.5`
- [Dart SDK](https://dart.dev/get-dart) `3.13.4`
- Java 17+ (for Android compilation)
- Node.js 20+ (for backend and Vercel tooling)

### 1. Clone & Install Dependencies
```bash
git clone https://github.com/SH1SHANK/nitc-bus-tracking-app.git
cd nitc-bus-tracking-app
flutter pub get
```

### 2. Configure Environment
Copy the example configuration:
```bash
cp config/env.json.example config/env.json
```

Populate your development credentials in `config/env.json`:
```json
{
  "ENVIRONMENT": "development",
  "SUPABASE_URL": "https://your-project.supabase.co",
  "SUPABASE_ANON_KEY": "your-anon-key-here",
  "MAPBOX_PUBLIC_TOKEN": "your-mapbox-public-token",
  "CAMPUS_NAME": "National Institute of Technology Calicut",
  "CAMPUS_CENTER_LAT": 11.3216,
  "CAMPUS_CENTER_LNG": 75.9337,
  "DEFAULT_ZOOM": 16.5
}
```

### 3. Run the Application
```bash
# Android Device / Emulator
flutter run -d android --dart-define-from-file=config/env.json

# Web (Chrome)
flutter run -d chrome --dart-define-from-file=config/env.json
```

---

## 🧪 Verification & Quality Gates

Run all automated checks before submitting pull requests:

```bash
# 1. Verify architecture boundaries (0 violations required)
dart run tool/verify_architecture.dart

# 2. Check strict code formatting
dart format --output=none --set-exit-if-changed lib test

# 3. Static analysis (0 errors, 0 warnings, 0 infos)
dart analyze --fatal-infos

# 4. Run automated test suite (389 tests)
flutter test

# 5. Build Web release
flutter build web --release --no-tree-shake-icons

# 6. Build Android debug package
flutter build apk --debug
```

---

## 📋 Release Notes: v1.0.0-rc-1

### Summary of Changes
- **Complete Rebranding**: Transitioned entire UI, documentation, and metadata from Tracklet to **BusTracker**.
- **Branding Alignment**: High-resolution isometric bus logo and wordmark cropped to zero padding for crisp alignment across all app drawers and headers.
- **Navigation Dock Overhaul**: Center floating action button upgraded to the Lucide folding map icon (`TrackletIcons.map`).
- **3D Voxel Avatar Picker**: Cleaned avatar customization sheet to focus purely on visual cards with an intuitive dice button (`Icons.casino_rounded`) to roll new personas.
- **Deep-Link Resolution**: Fixed web splash screen hang when directly navigating to `/home`, `/login`, `/profile`, or `/map`.
- **Icon Bundling**: Embedded offline Lucide font assets in Web distribution, resolving cross-origin font failures on Vercel.
- **Zero-Legacy Telemetry Standards**: Standardized Fastify and PostgreSQL telemetry ingestion on 8-round Bcrypt with 16-character minimum secrets and monotonic session resets.

For detailed historical release notes, see the [Changelog](CHANGELOG.md).

---

## 📄 License & Attribution
- **Campus Geography**: © [OpenStreetMap](https://www.openstreetmap.org/copyright) contributors.
- **Design Tokens**: Moon Design System v1 specification.
- **3D Personas**: Powered by [DiceBear](https://dicebear.com) 3D Voxel Engine.
- **Maintainer**: Shashank Mergu ([@SH1SHANK](https://github.com/SH1SHANK)) • National Institute of Technology Calicut.
