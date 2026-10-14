# Home Journey Planner and Live Route Context

**Status:** Approved interaction direction; awaiting spec review before implementation planning
**Date:** 2026-10-15

## Goal

Make the Home screen answer two rider questions at a glance: where the approaching bus is on its route, and how to travel from the rider's boarding stop to a selected destination. Preserve the existing Tracklet visual language, offline map, telemetry and route data contracts.

The attached screenshot is visual reference only. Example names, ETAs, distances, and speeds in the request are illustrative and must never be presented as live data unless derived from current app data.

## Existing flow and constraints

- `HomeScreen` already derives a nearest campus stop from permitted device location, offers a default boarding stop when location is unavailable, searches stop names/codes, and records a selected destination locally.
- `NextBusCard` shows the next live arrival or a scheduled departure. The live arrival helper currently uses straight-line distance and a speed fallback; it is not suitable as proof of along-route arrival time.
- `LiveBusRoutePreview` renders ordered stop nodes and destination highlighting, but does not render the provided bus location.
- `MapStateNotifier` can select a route, bus, and stop. `MapScreen` follows a selected bus and fits a selected route, but journey origin/destination bounds and a journey-only route segment are not represented in shared map state.
- Route order, canonical geometry, live telemetry, stop events, and typed along-route ETA helpers exist in the repository. They are the data sources; no new backend schema or mock telemetry is part of this design.

## Proposed experience

### Origin and destination

1. When location is permitted and a campus stop is within the existing campus range, use the nearest stop as the origin and label it as GPS-derived.
2. If location is unavailable or outside the campus range, use the existing default boarding stop and say it is the default. Do not claim that it is nearest.
3. Tapping the destination search opens a compact planner with `From [origin]` and `To [destination]`. Selecting a stop keeps the planner summary visible with edit/clear actions. When the destination field is empty, offer a short in-session recent-stops list; do not add persistence solely for recents.

### Route recommendation

- Find active route occurrences that serve both origin and destination in forward travel order, respecting repeated stop occurrences and loops.
- Recommend the best eligible live bus only when its route/direction matches and its along-route arrival to the origin can be resolved from valid telemetry and trip progress. Do not reuse straight-line ETA or fallback-speed estimates as a live arrival claim.
- Show route name/code, board stop, alight stop, and number of route stops between them. Show arrival ETA only when supported by valid telemetry; otherwise show `ETA unavailable`. Show in-vehicle travel time only if the available route data supports a defensible calculation; otherwise mark it unavailable.
- If no live bus qualifies, show the route itinerary without a live bus claim and retain any timetable departure as explicitly scheduled data. If no route serves both stops in direction, explain that no direct route is available instead of inventing a transfer.

### Live route timeline

- Keep the ordered route timeline and visually distinguish origin and destination.
- Place a small directional bus icon at its projected position along canonical route geometry only when its projection is valid and unambiguous. Tie its position to route progress, not the nearest geometry vertex. Do not imply interpolation when telemetry is stale or the bus is off-route; display the corresponding stale/unavailable state.
- Add distance to the boarding stop and speed only when the relevant along-route distance and actual telemetry speed are available. Preserve units (km and km/h) and omit unsupported values.
- Make the green `Live` pill itself an accessible button with a minimum 48 dp touch target and a material tap ripple. Activating either it or `Track bus` opens the Map tab with that bus selected and following; use the map's existing motion rather than continuous decorative pulsing.

### Map journey handoff

- Selecting a destination with a valid direct route opens the Map tab with that route, the destination stop, and the relevant origin-to-destination segment selected.
- Highlight only the canonical geometry segment between the selected ordered stop occurrences in the route color; dim unrelated routes and buses. Preserve offline tiles and route rendering.
- Fit bounds to include the journey segment and both stops. If the segment cannot be derived reliably from route geometry, show the whole selected route and both stop markers, and do not imply a precise segment highlight.
- A live-bus action takes precedence over journey framing and enters the existing follow-bus mode. Manual pan continues to disengage follow mode according to existing map behavior.

## Data and failure behavior

- GPS permission remains optional. Manual/default origin selection continues to work without location.
- Missing route order, ambiguous loop occurrence, unprojectable stop, invalid/stale telemetry, absent trip events, or missing geometry must lead to clear unavailable states, not fabricated ETA, speed, distance, or route segment.
- No backend migrations, schema changes, new dependencies, or network polling beyond existing providers are required by this design.

## Implementation scope

Expected touch points are `home_screen.dart`, `home_transit_logic.dart`, `live_bus_route_preview.dart`, `next_bus_card.dart`, `map_state_provider.dart`, `map_screen.dart`, and focused home/map tests. Keep changes in existing providers and widgets; add no new abstraction unless current APIs cannot safely represent journey selection and segment bounds.

## Acceptance checks

1. With location available, journey origin is the nearest in-range stop; without it, the UI clearly identifies the default boarding stop.
2. Destination selection updates the origin/destination summary, route itinerary, and destination marker.
3. A live bus marker appears at a deterministic, valid projected route position; stale, off-route, missing-geometry, and ambiguous cases do not show a false precise position.
4. Speed, route distance, arrival ETA, and in-vehicle duration are shown only when their source data and direction are valid.
5. Route recommendation respects ordered stop occurrences and loop wrap-around; unsupported or indirect routes do not produce a fabricated direct recommendation.
6. Live-bus action enters bus follow mode; destination action selects the route and frames the journey in the Map tab.
7. Small-screen and enlarged-text widget tests show no overflow and retain accessible touch targets.
8. Existing map, transit, offline-map, and full Flutter test suites continue to pass.
