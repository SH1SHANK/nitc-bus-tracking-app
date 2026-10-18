# Changelog

All notable changes to the **BusTracker** application are documented in this file.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [v1.0.0-rc-1] - 2026-10-18

### 🚀 First Public Release Candidate

This milestone represents the first public release candidate of **BusTracker** (formerly Tracklet), a modern, high-precision public-transit tracking platform engineered specifically for the National Institute of Technology Calicut (NITC) campus community.

---

### Added

#### 🗺️ Real-Time Telemetry & Map Engine
- **Live GNSS Telemetry Streaming**: Sub-second GPS tracking for campus shuttle buses via Fastify gateway and Supabase Realtime.
- **Cartographic Campus Map**: Vector-rendered campus map powered by Mapbox custom tiles and OpenStreetMap NITC building footprint geometry.
- **Intelligent Polyline Snapping**: Automatically snaps raw coordinates to campus road network polylines, eliminating GPS drift and scatter.
- **Shortest-Arc Heading Rotation**: Smooth marker rotation towards heading vectors over the shortest angular arc.
- **Virtual Stop Geofencing**: 30-meter arrival and 45-meter departure geofences evaluated atomically inside PostgreSQL stored procedures (`ingest_telemetry_packet`).
- **Dynamic ETA Engine**: Real-time arrival calculations factoring road distance, dwell time at intermediate stops, and smoothed velocity.
- **Stale Telemetry Safeguards**: Automatically marks buses as "Stale" (amber status) and suspends arrival estimates if fixes are older than 60 seconds.

#### 🎨 Moon Design System & UI Overhaul
- **Animated Navigation Dock**: Curved floating dock with haptic feedback, fluid indicator pills, and Lucide animated icons.
- **Prominent Center Map Action**: Dedicated elevated circular action button featuring the official Lucide folding map icon (`TrackletIcons.map`).
- **3D Voxel Avatar Personalization**: DiceBear 3D voxel engine integration with pure visual cards and "Roll New" randomized dice button (`Icons.casino_rounded`).
- **Fluid Splash Screen**: Clean brand lockup with entry/exit animations and robust route hydration that directly resolves `/home`, `/login`, `/map`, or `/profile`.
- **Pure Solid Surfaces**: Removed all glassmorphic gradients and blur artifacts in favor of clean, contrast-compliant Moon Design System v1 adaptive tokens.
- **Proportional Brand Lockup**: Pixel-perfect vector and transparent isometric bus icon and wordmark lockup (`TrackletBrandLockup`), adaptive to light and dark themes.

#### 🔐 Authentication & Onboarding
- **Institute SSO & Email Auth**: Secure authentication for `@nitc.ac.in` students and staff with Bcrypt password hashing.
- **Guest Explorer Mode**: Instant access to live map, stops, and schedule timetables without requiring mandatory sign-in.
- **Streamlined Auth UI**: Distraction-free Login and Create Account screens featuring prominent BusTracker branding.
- **Interactive Academic Onboarding**: 11-step customizable onboarding for department, hostel selection, batch year, and favorite bus stops.
- **Bot Mitigation**: Cloudflare Turnstile token validation on auth endpoints.

#### 🛡️ Zero-Legacy Backend Infrastructure
- **Strict Bcrypt Standard**: Hardware tracker credentials hashed exclusively using 8-round Bcrypt (`pgcrypto` `gen_salt('bf', 8)`).
- **16-Character Secret Invariant**: Enforced 16-character minimum secret length across API schemas, database functions, and provisioning tools.
- **Monotonic Reboot Sessions**: Hardware cold-boot reset protocol (`POST /api/v1/auth/reset-session`) with epoch advancement and sequence zeroing.
- **Advisory-Locked Telemetry Ingestion**: High-concurrency Postgres advisory locks preventing duplicate or out-of-order packet processing.
- **Secure Telemetry Simulator**: Edge Function telemetry simulator hardened with HMAC SHA-256 signature verification and pg_cron scheduling.

#### 📦 Deployment & Tooling
- **Automated Vercel Deployment**: Web distribution with custom domain [nitc-bustracker.vercel.app](https://nitc-bustracker.vercel.app), strict Content Security Policy (CSP), and Wasm build compatibility.
- **Android Release Pipeline**: GitHub Actions workflow for signed APK builds, automated keystore injection, SHA-256 checksum generation, and GitHub release drafting.
- **Architecture Enforcement**: Automated validation script (`tool/verify_architecture.dart`) preventing layer boundary violations across the codebase.

---

### Changed
- Rebranded application universally from "Tracklet" to **BusTracker**.
- Updated `pubspec.yaml` versioning to `1.0.0-rc-1+1`.
- Cleaned and cropped brand icon (`bustracker_bus_icon.png`) and wordmark (`bustracker_wordmark.png`) to eliminate transparent padding and ensure balanced rendering across drawers, headers, and splash screens.
- Standardized navigation icons to Lucide font family.
- Redesigned Home screen drawer header with clean alignment and high-contrast typography.

---

### Fixed
- Fixed splash screen freeze when deep-linking directly to `/home`, `/login`, or other sub-routes on Web.
- Fixed missing Lucide navigation icons on deployed Web URLs by embedding font assets and configuring font-src CSP directives.
- Fixed map button icon in bottom dock displaying a location pin instead of the folding map icon.
- Removed container boxes and white borders around transparent isometric bus icon.
- Removed seed/username text clutter from avatar selection bottom sheet.
- Fixed telemetry packet race conditions under high network jitter with Postgres advisory locks.

---

### Verification
- **Automated Tests**: 389 passing unit, widget, and integration tests (100% pass rate).
- **Static Analysis**: `dart analyze --fatal-infos` passing with 0 warnings or errors.
- **Architecture Guardrails**: 100% compliant with zero boundary violations.
- **Live Deployment**: Verified and operational at [nitc-bustracker.vercel.app](https://nitc-bustracker.vercel.app).