# Map Reliability and Performance Hardening

Date: 2026-10-21

## Scope and baseline

This is a focused follow-up on the shared Mapbox implementation used by Android and Web. The starting worktree already contained an extensive user-owned map refactor, simulator removal, lockfile edits, and unrelated application changes. Those changes were preserved; this report describes only the incremental map reliability edits from this pass. No backend, Supabase, migration, authentication, deployment, or production configuration changes were made.

The active renderer is `TrackletMapView` in `lib/services/maps/map_adapter.dart`. `MapScreen` supplies live bus positions and planned route geometry. Live bus data continues to come from the existing Supabase-backed transit repository; the renderer derives visual frames from successive received coordinates and does not write or invent telemetry.

Before this pass, `MapMarkerData.animatePosition` was supplied for buses but the Mapbox adapter sent each received coordinate directly to its GeoJSON source. Ordinary position updates could therefore jump. The fleet listener also refit bounds whenever the valid bus count changed, including during routine refreshes.

## Changes

- Added a single 33 ms timer shared by moving bus markers. Each frame interpolates between the previously rendered point and the newest valid telemetry point, with a 0.5–3 second duration bounded by telemetry cadence. There is no extrapolation after the received target.
- Geographic longitude interpolation uses the shortest wrapped path across ±180°. Heading interpolation uses the existing shortest-angle helper. Missing headings do not trigger an invented heading.
- Discontinuities over the existing 300 m jump threshold, non-advancing timestamps, and telemetry gaps over 30 seconds snap to the new valid point instead of animating across the map.
- The renderer coalesces in-flight marker frame updates, stops its timer when transitions finish or the app backgrounds, resumes toward the latest telemetry, removes state for vanished buses, and cancels the timer on disposal. It updates the native 3D model position and 2D marker source from the same visual coordinate.
- Marker and route GeoJSON are compared by serialized content before Mapbox source updates. Route source changes are therefore skipped when a rebuild produces identical geometry and style data.
- Fleet bounds now auto-fit only on the first non-empty fleet. Later bus count changes preserve the current camera; explicit fit controls remain available.
- Mapbox load and source errors shown to riders now use concise generic text; detailed exceptions remain in application logs. This prevents SDK error text from being surfaced directly.
- Existing transit-loading skeleton, empty-fleet state, and retryable fleet error state remain in use; they were not redesigned in this pass.
- Added a regression assertion for antimeridian interpolation. Fixed existing map preview integration-test analyzer warnings by removing an unused import and moving `setState` calls behind state-owned methods.

## Verification

Commands run in the app repository:

| Command | Result |
| --- | --- |
| `dart format lib/services/maps/map_adapter.dart lib/data/transit/bus_telemetry.dart lib/features/map/map_screen.dart test/data/bus_telemetry_test.dart` | Exit 0; formatted the telemetry helper. |
| `flutter test test/data/bus_telemetry_test.dart test/services/maps/bus_model_style_test.dart` | Exit 0; all 16 tests passed. |
| `flutter test test/features/map/map_screen_test.dart test/features/map/fleet_map_tracking_test.dart` | Exit 0; all 31 tests passed. |
| `flutter test` | Exit 0; all 426 tests passed. |
| `flutter analyze` | Initially exit 1 due to three pre-existing warnings in `integration_test/bus_model_preview_test.dart` and one style lint in the edited adapter. Those were corrected within this map scope; rerun exited 0 with “No issues found.” |
| `flutter build apk --debug` | Exit 0; APK built. Gradle reported the Mapbox plugin Kotlin Gradle Plugin compatibility warning and an Android SDK XML version warning. |
| `flutter build web --release` | Exit 0; Web build completed. Flutter reported a missing CupertinoIcons font-family asset warning and the wasm dry-run advisory. |
| `git diff --check` | Exit 0 for scoped changes. |

Flutter commands resolved the already-present dependency graph and reported newer incompatible package versions; no dependency upgrade was requested. The app `pubspec.yaml` and `pubspec.lock` were already modified before this pass and were not changed by these edits.

## Performance evidence and limitations

The local environment has Android hardware, an Android emulator, and Chrome available, but the checked-in configuration has no Mapbox token, so the Mapbox runtime cannot be profiled in this session. The map preview integration test waits for a live Mapbox style and requires a configured public token, so it was not run. There is no trustworthy before/after measurement for first usable map frame, frame-time percentiles, CPU, memory, live source-update counts, or recovery time; no such numbers are claimed.

The verified structural change is that identical route data no longer triggers a Mapbox route-source update, and bus animation uses at most one outstanding adapter frame sync at a time. The timer still updates marker GeoJSON during movement, so representative-device profiling is needed to quantify frame cost with large fleets. Labels continue to use the existing update path. The 33 ms timer is a best-effort cadence and native Mapbox rendering may coalesce frames differently on Android and Web.

## Remaining risks and follow-up

- Confirm smoothness and source-update cost on a representative Android device and a supported browser with a valid Mapbox token; measure first usable map frame, live bus readiness, frame-time distribution, and CPU/memory under a realistic fleet.
- The Mapbox style loader does not expose a trustworthy tile percentage; the implementation does not invent one. A map style/configuration failure requires runtime verification to confirm the SDK can recover after connectivity returns.
- The map screen still waits for its required transit stop data before showing the full map skeleton-to-map transition. Progressive map construction ahead of that request was not changed in this pass because it requires a broader loading-lifecycle adjustment.
- No production deployment, production configuration change, database operation, migration application, or production data access occurred.
