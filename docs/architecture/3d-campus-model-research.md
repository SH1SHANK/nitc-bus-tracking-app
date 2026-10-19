# Geographically Anchored 3D Campus Model: Research and Architecture

**Status:** Research only; no application implementation was performed.  
**Repository branch inspected:** `feat/glb-map-integration` (the requested literal `glb-map-inetgration` is not the active branch name).  
**Model inspected:** `/Users/shashankmergu/Downloads/NITCmap (1).glb`  
**Research date:** 2026-10-19 (Asia/Kolkata)

## Executive summary

The app has two different map engines today. Android and other non-Web builds use `flutter_map` 8.3.2, with Mapbox raster tiles when online and bundled MBTiles as the offline basemap. Web uses Mapbox GL JS 3.9.4 through the existing JavaScript bridge. There is no `mapbox_maps_flutter` dependency or resolved version in `pubspec.lock`, so there is no installed Flutter Mapbox ModelLayer API to verify or call. Android currently has a 2D Flutter map, not a Mapbox vector-map camera; the Web map is the only current Mapbox GL map.

The GLB is a Blender-exported glTF 2.0 binary of 36,150,600 bytes (about 34.5 MiB). Static inspection found 117 nodes, 115 meshes, 425 primitives, 565,395 position vertices, 886,047 indices, 236 materials, 78 textures, and 72 embedded images. One mesh has 145,792 vertices, above Mapbox's documented 65,536-vertex per-mesh limit. The model also requires `EXT_texture_webp`, which Mapbox documents as unsupported, and uses optional material extensions beyond metallic-roughness. It is not ready for a Mapbox ModelLayer without asset conversion and geometry splitting.

**Recommendation:** use map-native ModelLayers on each platform, with the map engine that already exists on Web and a deliberate Android migration from `flutter_map` to the official Mapbox Maps SDK for Flutter (or a native Android Mapbox view if the Flutter wrapper proves unsuitable). On Web, add a GL JS `model` layer to the existing bridge. On Android, use the Flutter SDK's `MapWidget`, style-loaded callback, `addStyleModel`, GeoJSON source, and `ModelLayer`. Keep Riverpod as the source for buses, stops, routes, and building labels; adapt those data into each platform's native map sources and annotations. This approach is map-projected and camera-synchronized by the map renderer. It is a material Android map-engine change and requires an offline-map plan. No single currently installed Flutter map package provides this complete implementation on both targets.

Use a separate campus viewer as fallback if preserving the current Android `flutter_map` and MBTiles behavior is a stronger constraint than seeing the model in the live map. `flutter_3d_controller` 2.3.0 is suitable for such a viewer, but it is not a geospatial map layer and cannot by itself keep the campus model geographically registered to Mapbox.

## Existing project and SDK findings

### Runtime and dependencies

| Item | Verified project value |
|---|---|
| Flutter / Dart on inspection host | Flutter 3.47.5 stable; Dart 3.13.4 (`flutter --version`) |
| Dart SDK constraint | `>=3.7.0 <4.0.0` in `pubspec.yaml` |
| `flutter_map` | 8.3.2 resolved in `pubspec.lock` |
| `flutter_riverpod` | 3.4.3 resolved in `pubspec.lock` |
| `mapbox_maps_flutter` | Not a direct or transitive resolved dependency; no installed version to check |
| Web Mapbox GL JS | 3.9.4 loaded from `web/index.html` |
| Android minimum SDK | At least API 24 (`flutter.minSdkVersion.coerceAtLeast(24)`) |

The prompt's request for the exact resolved `mapbox_maps_flutter` version therefore has a negative answer: none is resolved. The app's current Mapbox usage is map tile/style services, not the Mapbox Flutter Maps SDK on Android.

### Map implementation, state, and lifecycle

1. `TrackletMapView` in `lib/services/maps/map_adapter.dart` chooses a Web implementation under `kIsWeb`; non-Web builds create `flutter_map`'s `FlutterMap` with `TileLayer`, route `PolylineLayer`, and animated `MarkerLayer`.
2. Online mobile tiles are fetched through a Mapbox raster URL template. Offline mode loads the packaged `assets/maps/nitc_campus.mbtiles` through `flutter_map_mbtiles`. The Web bridge instead constructs a Mapbox GL JS map.
3. `lib/features/map/providers/map_state_provider.dart` owns transit map state through Riverpod `mapStateNotifierProvider`; bus data is supplied by `activeBusesStreamProvider`, campus building labels by `campusBuildingsProvider`, and `mapLabelsProvider` combines building and stop labels.
4. The Web map lifecycle is in `web/mapbox_adapter.js` and `lib/services/maps/mapbox_web_bridge.dart`. It creates a `mapboxgl.Map`, adds route and stop sources/layers after `load`, restores those sources on `style.load`, keeps bus markers as DOM markers, and applies light/dark styles through `setStyle`.
5. Current Web map layers include route lines, stop circles, stop text labels, DOM bus markers, and user location. The app's Flutter overlay widgets include map controls and panels. Style reload currently re-adds route and stop sources; any new model source/layer must follow the same idempotent reconstruction path.
6. `flutter_map` camera projection helpers can project a `LatLng` to a screen offset and account for map rotation. They do not provide a shared 3D depth buffer with the raster basemap. The mobile map is not currently configured with pitch/tilt. Web Mapbox GL JS has the native camera and model-layer renderer required for integrated rotation and pitch.

The existing adapter and Riverpod data flow are useful boundaries: keep domain state in Riverpod, and put style/source/model lifecycle details inside the map adapter and its platform bridges. The Android rendering implementation would still need a map-engine replacement or a separately built native Mapbox surface; it is not a drop-in addition to the current FlutterMap layer list.

### Android and Web configuration

- Android already has Internet and network-state permissions and a minimum SDK of 24. The Android map renderer is FlutterMap, not a Mapbox Android `MapView`.
- Web loads Mapbox GL JS/CSS v3.9.4 plus the app's `web/mapbox_adapter.js`. Mapbox GL JS native `model` layers are supported from v3.0 according to the current style specification; v3.9.4 is therefore in the documented version range. The actual app's map configuration and custom style still need a runtime proof of concept.
- `MapConfig` defines a campus camera center `(11.3216, 75.9337)` and an approximate display bounding box. This is an application camera default, not evidence that the GLB is aligned to that location or a surveyed control point. No georeference is embedded in the GLB.
- No GLB/glTF, campus-building model, or geographic-alignment sidecar asset is listed in the app's declared Flutter assets. Existing campus building labels come from the app's building data provider, not a 3D campus asset.
- Static inspection only was performed. No builds, tests, deployments, GLB conformance validator, or device/browser rendering checks were run.

## Skills and research method

| Skill or capability | Use in this research |
|---|---|
| `superpowers:brainstorming` | Classified this as architectural exploration and compared alternatives before recommending a design. This document is a research recommendation, not approval to implement it. |
| `flutter-apply-architecture-best-practices` | Reviewed layer boundaries and compared them with the existing Riverpod/map-adapter architecture. Its generic MVVM examples do not override the repository's Riverpod conventions. |
| `flutter-build-responsive-layout` | Considered Web viewport resizing and map-widget sizing; it does not solve synchronized 3D projection or occlusion. |
| `research` | Followed its primary-source citation workflow and delegated a focused read of official Mapbox Android, Flutter, and GL JS documentation. |
| `performance` | Applied its static-inspection limitation: all performance numbers below are proposed engineering goals, not measured results. |
| Context7 | Used to locate documentation for the exact Flutter map packages and for ModelLayer and `flutter_3d_controller`; then checked consequential claims against official docs/specification pages. |

No dedicated Mapbox integration or GLB asset-audit skill was available. Official Mapbox, Flutter, Khronos, and package documentation was used instead. The research skill's background-source review was used for Mapbox documentation; all repository/asset inspection and this report are from the active task checkout.

## Verified sources and support classification

| Capability | Finding | Classification and evidence |
|---|---|---|
| Mapbox native model layer | Mapbox documents a `model` style layer fed by GeoJSON/vector model features or a model source, with model ID, scale, rotation, translation, and type properties. | **Confirmed supported** in Mapbox GL JS >=3.0 and Mapbox Android SDK >=11.0 per [Mapbox Style Specification: layers](https://docs.mapbox.com/mapbox-gl-js/style-spec/layers/). |
| Android Mapbox GLB example | Official Android sample registers GLB models, creates a GeoJSON point source, then adds a `ModelLayer`. | **Confirmed supported** for the documented native Android SDK; see [Mapbox Android 3D Model Layer example](https://docs.mapbox.com/android/maps/examples/android-view/3D-model-layer/). |
| Flutter Mapbox ModelLayer | Official Flutter example uses `MapWidget`, `onStyleLoadedListener`, `addStyleModel`, a GeoJSON point source, and `ModelLayer`. The example also shows Flutter asset URI resolution. | **Confirmed supported** in the current documented Flutter SDK; see [Mapbox Flutter ModelLayer example](https://docs.mapbox.com/flutter/maps/examples/model_layer/). **Unverified for this repository**, because no `mapbox_maps_flutter` version is in its lockfile. |
| Mapbox GL JS ModelLayer | Official JS example registers a GLB in the style's `models` table and renders it for GeoJSON point features with `type: 'model'`. | **Confirmed supported** in current GL JS; [Mapbox GL JS GeoJSON model example](https://docs.mapbox.com/mapbox-gl-js/example/add-3d-models-using-geojson-source/). Model layers are documented from GL JS 3.0, so local v3.9.4 meets the documented minimum; app-specific runtime behavior remains unverified. |
| Model source parity | Mapbox's style source reference and newer Android examples are not fully consistent about model-source platform support. | **Version-sensitive / unverified** across this app's targets. Prefer GeoJSON point source plus ModelLayer until the exact selected Android SDK is tested. |
| Mapbox model GLTF support | Supports glTF 2.0 binary or JSON; triangle meshes and PBR metallic-roughness materials. Mapbox documents a 65,536-vertex per-mesh limit, no WebP extension, no animation/skin/morph support, and only metallic-roughness materials. | **Confirmed limitations** in [Mapbox Using 3D Models](https://docs.mapbox.com/style-spec/guides/using-3d-models/). |
| `flutter_3d_controller` 2.3.0 | Pub.dev lists Android, iOS, macOS, and Web; package docs accept GLB and load a standalone `Flutter3DViewer`. Package README says it uses Google's `<model-viewer>`. | **Confirmed as standalone viewing support**, not map integration; [pub.dev 2.3.0 version listing](https://pub.dev/packages/flutter_3d_controller/versions/2.3.0) and [package source README](https://github.com/m-r-davari/flutter_3d_controller). Its Web renderer still depends on browser WebGL and static asset delivery. Exact compatibility with this app's Web embedding and this particular GLB has not been run. |
| FlutterMap geographic overlay | `MapCamera.latLngToScreenOffset` accounts for map rotation; map layers can follow camera transforms. | **Supported with limitations** for screen-positioned widgets and simple 2D features; [FlutterMap MapCamera API](https://pub.dev/documentation/flutter_map/8.3.2/flutter_map/MapCamera/latLngToScreenOffset.html). It does not supply map-native 3D model depth, terrain occlusion, or pitch synchronization for a separately rendered GLB. |
| glTF axes and units | glTF 2.0 uses right-handed axes, +Y up and +Z forward; linear distances are metres. | **Confirmed format convention** by [Khronos glTF 2.0 specification §3.4](https://registry.khronos.org/glTF/specs/2.0/glTF-2.0.html#coordinate-system-and-units). That does not establish that the authored campus measurements correspond to real-world surveyed metres. |
| Flutter asset packaging | Flutter's asset bundle can package a static GLB; Mapbox Flutter's own example resolves the Flutter asset path before registering a local model. | **Confirmed at API-example level** in the [Flutter ModelLayer example](https://docs.mapbox.com/flutter/maps/examples/model_layer/). Web delivery/CORS and cache behavior need target-host verification. |

## Inspection of the supplied GLB

The GLB header and JSON chunk were read without modifying the file. The asset declares glTF 2.0 and generator `Khronos glTF Blender I/O v4.2.70`. The following are metadata-derived counts, not a successful render or Khronos validator result.

| Property | Observed value | Geographic/rendering implication |
|---|---:|---|
| File size | 36,150,600 bytes (34.5 MiB) | Large initial download if network-loaded; local bundle avoids network fetch but increases app/web deployment size. |
| Nodes / meshes / primitives | 117 / 115 / 425 | Substantial scene and primitive complexity; do not equate primitive count directly with measured draw calls. |
| POSITION vertices / indices | 565,395 / 886,047 (295,349 indexed triangles) | Needs device profiling and likely LOD/mesh simplification for gesture-time rendering. |
| Highest per-mesh vertex count | `Terrain.002`: 145,792 | Exceeds Mapbox's published 65,536 vertices per mesh; that mesh must be split or simplified before Mapbox model rendering. |
| Materials / textures / images | 236 / 78 / 72 embedded images | High material and texture count; reduce materials and texture resolution where visual review allows. |
| Alpha | 235 opaque materials, one blended, zero masked | Mostly opaque, but the transparent material should be checked for sorting/overdraw. |
| glTF extensions | Required `EXT_texture_webp`; optional `KHR_materials_clearcoat`, `KHR_materials_transmission`, `KHR_materials_specular` | Mapbox explicitly does not support WebP texture extension and supports metallic-roughness only. Re-encode WebP to PNG/JPEG, remove that required extension, and bake/simplify unsupported material appearance to the supported PBR model. |
| Animation / skin / camera | None / none / none | Static-model limitations do not block the current asset. |
| Scene metadata | No `extras`, geospatial CRS, anchor coordinates, or authoring-unit declaration | The model has no evidence of being georeferenced. A map anchor alone cannot recover origin, rotation, or surveyed scale. |
| Approximate transformed bounds | X ≈ 1,119.2 m; Y ≈ 220.6 m; Z ≈ 975.8 m | Calculated by transforming POSITION accessor AABB corners through node TRS; this is a conservative estimate, not a survey. Y is the apparent vertical axis and X/Z the apparent campus plane. Confirm with the source Blender project and measured control points. |

The raw GLB uses unitless-looking node translations such as `[-138.09, 9, -27.68]`, with root nodes distributed across hundreds of units. glTF defines linear units as metres, but the file does not state whether those exported numbers were authored from measured metre-scale campus dimensions. Several node transforms include nonuniform scaling and rotations. The model appears to be a visual campus scene, not a geographic scene: there is no longitude/latitude, projection, CRS, north arrow, or anchor metadata.

### Required asset preparation

1. Preserve this input GLB unchanged and obtain the Blender source if possible. Confirm whether the mesh positions are surveyed, approximate, or visually composed; identify north and a stable local origin.
2. Validate the file with the Khronos glTF Validator and render it in a glTF viewer to catch structural/visual issues. This research did not run either check.
3. Convert the WebP image referenced by `EXT_texture_webp` to PNG or JPEG and remove the extension declaration. Bake transmission/clearcoat/specular appearance into base color/roughness/normal maps or simplify those materials to metallic-roughness.
4. Split `Terrain.002` so each mesh is below Mapbox's 65,536-vertex ceiling. Also evaluate splitting the campus into geographically registered buildings/tiles and simpler LOD variants. Keep shared materials and textures where that lowers duplicated memory without creating unsupported extensions.
5. Reduce the 236 materials, 425 primitives, unseen geometry, and texture dimensions. Consider KTX2/Basis only after confirming identical decoding support on the selected Android SDK and exact GL JS version; do not assume it is a transparent drop-in replacement.
6. Export a repeatable geospatial manifest beside the model: local origin in model coordinates, surveyed anchor coordinate, local north azimuth, horizontal and vertical scale controls, terrain/elevation datum, and per-tile anchors if split.

Mapbox's model format documentation and optimization guidance are in [Using 3D Models](https://docs.mapbox.com/style-spec/guides/using-3d-models/). Khronos glTF Transform documents the WebP extension and GPU-memory implications in [EXT_texture_webp](https://gltf-transform.dev/modules/extensions/classes/EXTTextureWebP). A conversion must be checked visually because removing non-metallic-roughness material effects changes appearance.

## Geographic alignment requirements

### Why one longitude/latitude is not enough

A model layer's point feature supplies a geographic placement point, but the displayed footprint also depends on the model's local origin, axis orientation, metre scale, vertical datum, and model rotation. If the model origin sits at the northwest corner while the feature is placed at the campus center, the offset is preserved; if north is rotated relative to the model plane, the campus rotates with it; if authored scale is inaccurate, the footprint is uniformly wrong even when the anchor is exact. A single anchor corrects only translation.

### Required registration data and transformation

Use at least three non-collinear, surveyed control points tied to recognizable model locations to solve the horizontal transform. With the model's local +Y as vertical, identify the horizontal local axes (likely X/Z) and solve a local-plane-to-ground transform:

1. Translate model coordinates so a documented local origin (preferably a campus survey control point or campus-center ground point) becomes `(0, 0, 0)`.
2. Rotate the horizontal plane so the model's local north aligns with true/grid north at the anchor. Record the chosen north reference and its azimuth.
3. Apply horizontal scale based on measured distances between controls; check both axes to detect nonuniform distortion rather than hiding it with an arbitrary single scale.
4. Transform horizontal offsets into geographic coordinates in a local east-north-up frame (or a suitable local projected CRS) around the anchor. Use a local projection appropriate to the campus extent; avoid treating longitude degrees as constant metres.
5. Set the vertical origin and heights against a documented ground/elevation datum. Decide whether the model sits on a flat campus plane, follows terrain, or is vertically exaggerated.
6. Reproject control points through the map renderer and quantify residual error before accepting the anchor.

The repository's `(11.3216, 75.9337)` is labelled as a campus center and used as the camera default. Treat it as a candidate starting point only; it is not a supplied survey control point and was not validated in this research. The campus building provider contains individual mapped building locations and can help with visual checks, but those records are not automatically survey-grade controls. Do not infer missing origin, north, or model dimensions from the GLB filename.

### Map layer placement semantics

For Web GL JS, use a GeoJSON source with a point at the model origin and a model layer referencing the model registry entry (or use a `model` source only where both target SDKs prove that source path). For Android Flutter Mapbox, the current official example uses `mapboxMap.addStyleModel(...)`, `GeoJsonSource`, and `ModelLayer(id, sourceId)` in `onStyleLoadedListener`. Set scale and rotation only after registration values are solved. A source feature at one coordinate plus a correctly transformed model can track pan, zoom, bearing, and pitch because the same map renderer projects both; it does not fix inaccurate source geometry.

For tiled/building assets, each tile/building needs its own documented origin and GeoJSON feature location. The campus is only a few square kilometres, so a local tangent/projected transformation is a reasonable candidate, but elevation and metres-per-pixel errors still need measurement. If map terrain is enabled, verify vertical placement against its terrain datum; the app currently uses raster tiles and does not configure terrain elevation.

## Technical approaches

| Approach | Geographic anchoring and camera | Android / Web fit | Trade-offs for this repository |
|---|---|---|---|
| **A. Native Mapbox ModelLayer** | **True map-native placement** via GeoJSON feature + model layer; renderer handles camera projection, bearing, pitch, and depth integration. | Web: existing GL JS 3.9.4 documents model layers from v3.0. Android: requires adding/adopting Mapbox Maps SDK; Flutter wrapper exposes ModelLayer in current docs, but no version is resolved here. | Best fit for live map. Web integration is incremental. Android requires replacing FlutterMap map rendering or embedding a native Mapbox surface, porting markers/routes/controls, and deciding how the MBTiles offline map behaves. GLB must meet Mapbox format limits. Style reload must reinstall model registry/source/layer. |
| **B. `flutter_3d_controller: ^2.3.0`** | No geographic coordinate, Mapbox camera, map depth, or source/layer interface; standalone view only. | Pub.dev lists Android and Web. Uses an embedded WebView/model-viewer route; Web needs the package's model-viewer JavaScript asset and browser WebGL. | Good for a separate campus viewer, not a live geographically anchored map. An overlay would be a second camera and conflict with map gestures unless explicitly separated. Requires package and Android manifest/asset setup; not a drop-in adapter for existing layer stack. |
| **C. Flutter geographic overlay** | Can project simple points with FlutterMap `MapCamera.latLngToScreenOffset`; a native 3D view over it does not share map perspective/depth and must sync projection, viewport, DPR, camera and frame timing. | Flutter overlay code can run on Android/Web, but geometry still renders outside Mapbox's map scene. Web Mapbox GL camera and Flutter widget overlay also have different renderers/compositing. | Feasible for markers, footprints, or simplified screen-space annotations. Fragile for a complete campus mesh under pitch, rotation, occlusion, resizing, and gestures. Not recommended as an equivalent 3D map. |
| **D. Split/building/tile models** | No renderer by itself. Paired with native model layers, every unit can carry a surveyed anchor and be culled/LOD-switched. | Can target both platforms through approach A if formats/features are common; package and model-loading behavior still need per-platform validation. | More preparation and lifecycle complexity, but necessary for this asset's mesh ceiling, progressive detail, asset loading, and possible visibility control. Avoid assuming that arbitrary tiling will itself improve performance: measure draw calls, texture residency, and feature count. |
| **E. Separate 3D campus viewer** | Independent 3D camera; can show a campus model, optionally alongside a static/small map locator, but it is not geographically registered to the active live map camera. | Android and Web can use `flutter_3d_controller` 2.3.0 or another GLB viewer, subject to this GLB's extension support. | Least disruptive fallback for Android if changing map engine is not acceptable. Preserve live bus tracking in the map screen and offer a campus viewer as a separate destination; do not claim synchronized geo-anchoring. |

### Geographic overlay feasibility

For markers, the projection step is straightforward: in FlutterMap, `final offset = camera.latLngToScreenOffset(point);`. A complete campus GLB requires transforming every model vertex or a full model camera against the map's projection matrix and redoing that work during camera motion. A FlutterMap screen offset does not provide perspective-correct ground projection or map depth-buffer occlusion. In Web, painting a separate Flutter/WebGL viewer over GL JS produces a second GPU scene with its own camera. Matching only the campus center while the map pitches or rotates will visibly drift. This is unsuitable as the primary architecture for a complete campus model.

## Android / Web compatibility matrix

| Capability | Android in current app | Web in current app | Assessment |
|---|---|---|---|
| Current map engine | FlutterMap 8.3.2 with Mapbox raster tiles and MBTiles fallback | Mapbox GL JS 3.9.4 through JS bridge | Different rendering APIs and camera behavior |
| Current map's 3D ModelLayer | Unsupported by current FlutterMap renderer | ModelLayer documented from GL JS 3.0 | Web can add native GL JS model layer; Android cannot add it to FlutterMap |
| Flutter Mapbox SDK resolved version | None | None; Web map is directly GL JS, not `mapbox_maps_flutter` | Exact installed Mapbox Flutter API is inapplicable/unverified |
| Mapbox native ModelLayer | Requires map engine migration to Mapbox Android/Flutter Maps SDK | Supported by existing GL JS version range | Good cross-target outcome with distinct platform implementation |
| Model follows pan/zoom/bearing/pitch | FlutterMap supports 2D camera movement/rotation; current map lacks pitch and model depth rendering | Mapbox GL JS model layer is in the map render scene | Android needs Mapbox map engine for parity |
| GLB currently compatible | No model renderer in current map engine | Model layer exists, but this asset violates Mapbox's documented mesh/WebP/material limitations | Convert before either target POC |
| Bundled/offline GLB | Flutter asset + Mapbox SDK local asset API can be tested after migration | Same-origin static Flutter asset URL can avoid remote GLB fetch; verify generated asset URL and hosting headers | Keep model local for offline use; basemap offline policy remains separate |
| Existing offline basemap | MBTiles fallback works through FlutterMap | Not the same Mapbox offline implementation | Android migration risks current offline behavior; acceptance criteria must cover fallback |
| `flutter_3d_controller` standalone view | Listed as supported; embedded renderer | Listed as supported; model-viewer Web component | Suitable for Approach E only, not map layer |

No single implementation is already installed that satisfies the live-map requirement on both targets. A platform-specific map-native design can satisfy the intended behavior, but Android must move off its current FlutterMap renderer and use an SDK whose ModelLayer API is verified at the version actually selected.

## Performance and user experience

### Static risk assessment

- **Transfer and cold start:** 34.5 MiB bundled GLB affects Android package size and Web deployment/cache download. If fetched remotely instead, network and CORS availability become runtime requirements. Bundle only the variant needed at a given detail level.
- **Geometry:** 565k vertices and 295k indexed triangles are nontrivial. One 145,792-vertex mesh exceeds Mapbox's documented per-mesh limit. Mesh split alone resolves the ceiling but may increase primitive/draw complexity.
- **Materials/textures:** 236 materials and 72 images create texture upload and material-state costs. Compressed file bytes understate decoded GPU memory; actual texture dimensions and GPU allocations were not measured. WebP must be converted for Mapbox; WebP still expands to GPU texture memory at runtime.
- **Transparency:** one blended material may cause overdraw/sorting artifacts; simplify or make opaque if it does not need transparency.
- **Map composition:** at campus-detail zoom, buildings may compete with bus icons, stop labels, and routes. Put transit layers above the model where their readability requires it; preserve click target sizes and avoid the model intercepting bus/stop interaction.
- **Zoom visibility:** keep the full model off at distant zooms, show low-detail footprints/extrusions at intermediate campus zoom, and show detailed 3D only inside a defined campus zoom range. This also avoids rendering the whole model while users track buses at regional scale.
- **Themes:** keep geometry/materials stable across light/dark basemaps. Recreate style-owned sources/layers after `setStyle`/style reload; theme changes should not trigger redundant model downloads.
- **Offline:** bundle the model or validated tiles and load locally. An offline model does not guarantee an offline basemap; Android's existing MBTiles fallback is coupled to FlutterMap and needs an explicit migration decision.
- **Browser/device variability:** WebGL capability, GPU texture budgets, browser asset paths, and cross-origin headers vary. Android GPU fill rate and memory vary widely. Unsupported required glTF extensions can cause a total load failure, not just lower fidelity.

### Proposed engineering goals (not measurements)

Establish a baseline with the current app first, then target the following on a representative low-end supported Android device and a mid-range phone/browser:

- Maintain at least 30 FPS during combined map gestures on the low-end Android target; aim for 50–60 FPS on mid-range devices. Record frame-time percentiles rather than relying on visual judgment.
- Keep p95 map-frame time at or below 33 ms on the low-end profile and 20 ms on the mid-range profile while the detailed model is visible.
- Keep detailed-model compressed transfer below 15 MiB per highest-detail asset set, and the initial low-detail model payload below 3 MiB. These are proposed budgets for this campus use case, not platform limits.
- Show a usable basemap and transit data without waiting for the 3D model. Target model-ready under 3 seconds on a warm local load and under 6 seconds on representative campus Wi-Fi for high detail; report conditions and failures separately.
- Keep model draw cost bounded by a measured GPU profile. Set model geometry to fewer than 65,536 POSITION vertices per mesh to satisfy the documented Mapbox limit, and reduce detail while moving or at low zoom if profiling shows gesture frame drops.
- Verify route and stop label contrast in both map themes, retain readable bus markers, and ensure model taps do not block transit interactions.

Use device/browser traces and GPU tools to compare: model hidden, low LOD, full model; cold/warm cache; pan/zoom/rotate/pitch gestures; style reload; and offline startup. These are a future verification plan, not completed checks.

## Decision matrix

Ratings are relative to this repository and the requested live geographic integration: **High**, **Medium**, **Low**, or **None**. Performance/memory ratings are hypotheses until profiled.

| Criterion | A: Mapbox model layers | B: 3D controller overlay | C: Flutter geographic overlay | D: split/tiled assets with map layers | E: separate viewer |
|---|---|---|---|---|---|
| True geographic anchoring | High | None | Low for full model | High when paired with A | Low / separate context |
| Android compatibility | Medium: requires renderer migration | High as a viewer | Medium for 2D projection; low for full 3D | Medium, paired with A | High as a viewer |
| Web compatibility | High with GL JS 3.9.4 | High as viewer | Medium, projection/compositing risk | High with A | High as viewer |
| Compatibility with currently installed SDKs | Web high; Android none | Not installed; standalone | FlutterMap can project 2D overlay only | Requires model renderer | Not installed; standalone |
| Camera accuracy | High (same map renderer) | None | Low; separate camera/depth | High if map-native | None relative to live map |
| Integration complexity | High overall, especially Android | Low for separate screen; high as overlay | High | High asset-pipeline + runtime | Low to medium |
| Runtime performance potential | High if asset optimized; one map scene | Medium; second renderer/platform view | Low for full campus mesh | High potential with LOD/culling | Medium; isolated viewer |
| Asset size / memory | High current risk; optimize/split | High current risk; no Mapbox mesh limit guarantee | High current risk | Medium/High; per-tile/LOD controls | High current risk |
| Maintenance burden | Medium/High: two map adapters | Medium standalone dependency | High custom sync math | High content pipeline plus adapters | Medium |
| Existing bus/stop compatibility | Medium: port feature layers/markers on Android | Low in same map; preserved if separate screen | Medium; hit test and occlusion conflicts | Medium/High with same source data | High if separate screen |
| Required architecture changes | Android map adapter and offline policy | Add viewer route and package | Custom renderer/projection layer | Asset pipeline plus A | Add viewer route and package |

Approach D is an asset strategy that complements A; it is not an alternative renderer. The score for A assumes Android adopts a compatible Mapbox map SDK and Web retains its current GL JS bridge.

## Recommended architecture

### Primary recommendation: platform-specific, map-native ModelLayers

1. **Web renderer:** retain `web/mapbox_adapter.js` and the existing `TrackletMapController` bridge. On initial `load` and each `style.load`, register the campus GLB in the style model registry, add a GeoJSON source for the campus anchor(s), then add a `type: 'model'` layer referencing model IDs. Set appropriate `minzoom`/`maxzoom`, layer order, and model styling. Use the existing Web Mapbox map so model, map gestures, route layers, stops, buses, and map depth share the same projection.
2. **Android renderer:** evaluate the official `mapbox_maps_flutter` SDK on Android and implement a map adapter using `MapWidget`, `onMapCreated`, and `onStyleLoadedListener`; register the local asset using `mapboxMap.addStyleModel` and `MapboxMapsOptions.getFlutterAssetPath`, then add a GeoJSON source and `ModelLayer`. Do not treat the present FlutterMap `TileLayer` as a ModelLayer host. Select an exact SDK release only after confirming Android API availability, min SDK, licensing/token handling, offline capability, and Flutter 3.47.5 compatibility.
3. **Riverpod boundary:** continue consuming the current map state and bus/campus providers. Keep data definitions and selection state in Riverpod; convert those records into Web JS sources/markers or Android Mapbox sources/annotations inside the platform-specific adapter. Preserve map tap/selection callbacks, recenter/fit-bounds, stop labels, selected-route styling, user location, and camera callbacks.
4. **Style lifecycle:** treat model registration, GeoJSON source, model layer, route layers, and stop layers as style-scoped objects. Re-add idempotently on every style load and retain last model/transit data so a theme switch restores all features. Do not rebuild Riverpod state or download an unchanged local GLB on light/dark transitions.
5. **Offline behavior:** initially keep the model bundled locally. Android must explicitly choose one of: (a) accept the current 2D MBTiles view when Mapbox is unavailable, with the 3D model hidden; (b) add an offline-capable Mapbox tiles path; or (c) keep the existing FlutterMap in a separate offline fallback. Reusing the `flutter_map_mbtiles` provider inside a Mapbox ModelLayer map is not supported by the current architecture.
6. **Asset preparation and zoom strategy:** convert unsupported WebP/material features, split oversized mesh, simplify to fewer materials/primitives, and make a low-detail campus representation. Show only the low-detail representation at overview zoom; show detailed campus pieces after the user zooms into the campus; keep transit markers/labels visually dominant.
7. **Coordinate registration:** solve local origin, axis rotation, horizontal scale, vertical datum, and per-piece anchors from at least three surveyed non-collinear control points. Keep transformation values in an explicit manifest reviewed against current campus building coordinates, then check independent points for residual error.

**Why this path:** a native map layer is the only evaluated approach that naturally stays registered under the map's pan, zoom, rotation, and pitch while sharing its depth/render order. The Web side can reuse the existing GL JS engine. Android cost is an engine migration; the user's camera and bus functionality must be ported deliberately, and offline MBTiles behavior is the main product trade-off.

### Fallback: separate campus 3D viewer

If an Android Mapbox engine migration is too disruptive, keep `flutter_map` and its MBTiles path as the live bus map. Add a separately navigated campus viewer using `flutter_3d_controller` 2.3.0 or another validated GLB renderer, and show a plain map context or location cue alongside it if useful. Label it as an independent 3D view; do not claim the GLB is locked to the live map camera. Web can still use the GL JS native model layer after conversion if the product accepts platform asymmetry. If cross-platform parity is mandatory, defer full 3D on Android until its map renderer can host the model natively.

## Implementation roadmap

| Stage | Outputs | Acceptance criteria | Main risks / dependencies |
|---|---|---|---|
| 1. Repository and SDK compatibility verification | Select exact Android Mapbox Flutter SDK release or native bridge; verify current GL JS model-layer support at v3.9.4; document offline and token behavior | A minimal compatibility matrix tied to pinned versions; no capability inferred from other platform/version | Current repo has no Mapbox Flutter SDK; package support and Web implementation may differ by release |
| 2. GLB validation and geographic alignment | Khronos validator report, viewer screenshots, optimized GLB(s), source/anchor manifest, surveyed control-point residuals | No required unsupported extension; every mesh below Mapbox's limit; scale/orientation/origin and errors documented; independent controls meet agreed campus tolerance | Source model may be approximate; missing survey/Blender source; conversion alters materials |
| 3. Minimal proof of concept | One model on a blank/simple map on Android and existing Web GL JS | Same anchor remains stable while pan, zoom, bearing, pitch, resize, and style change; cold load and failure states recorded | Local Web asset URL/CORS; wrapper version mismatch; GPU/device support |
| 4. Android and Web compatibility testing | Low/mid-range Android and target browsers; online/offline tests | Model loads on each target; no unsupported-feature failure; screen-space drift within the agreed measured tolerance at surveyed controls | Browser/GPU variation; Android offline map migration decision |
| 5. Existing map-layer integration | Port route lines, bus markers, stops/labels, user location, selection and camera actions | Existing tracking flows and interactions still work with model hidden/visible and after map-style reload | Platform implementation parity; hit testing and layer order regressions |
| 6. Performance and asset optimization | LOD variants or per-building assets, measured transfer/memory/frame-time report | Meets the proposed engineering goals or an explicitly agreed revised budget on target devices | Larger asset bundle, duplicated textures, model draw cost, 3D terrain overlap |
| 7. Regression and release readiness | Regression plan/results, offline policy, release asset/license notes, rollback path | Android and Web acceptance criteria pass; style theme transitions recover layers; buses/stops/routes remain legible and selectable | Mapbox account/token/style dependencies; increased Android binary and Web deployment size |

No roadmap stage has been implemented or verified in this research task.

## Risks, assumptions, and unresolved questions

- **Branch name:** active branch is `feat/glb-map-integration`; the requested literal `glb-map-inetgration` is not active. No branch switch was made. The report is on the active branch.
- **Model authorship and accuracy:** the file contains no CRS, georeference, north, or surveyed dimensions. Its coordinate geometry and visible shape may be manually modeled. Need source Blender file or measured ground controls.
- **Android renderer migration:** adding Mapbox Flutter Maps SDK replaces the current FlutterMap rendering path on Android. This risks the existing offline MBTiles fallback, marker visuals, and map interaction behavior; the migration must be explicit and tested.
- **Mapbox account and version:** Mapbox token, style access, current pricing/usage policies, Web CORS, and selected SDK compatibility were not verified in this task. Keep this technical comparison independent of current account entitlement.
- **GLB conformance:** custom header/chunk inspection established structure and metadata but did not run the Khronos validator or render the asset. Image decoder support, material visuals, malformed accessors, and all runtime effects remain unverified.
- **File dimension estimate:** transformed bounds are estimated from accessor AABBs, not surveyed ground truth or a source CAD/BIM extent.
- **Approach B runtime:** package claims Web/Android and GLB support, but exact GLB behavior with its required extension is unverified. A standalone viewer is not a workaround for map projection.
- **Mapbox documentation/version skew:** the Flutter docs and Android examples represent current SDKs; this repository has no resolved Mapbox Flutter version. Do not port API names until an exact version is pinned and proven in a small POC.
- **Product trade-off:** if retaining the current Android offline basemap is mandatory and a Mapbox offline path is unacceptable, the fallback viewer is the least disruptive path but does not satisfy live map anchoring on Android.
- **Outstanding alignment decisions:** What positional tolerance is required for the model's building footprints? Which source supplies survey/control coordinates and elevation datum? Is a flat campus plane acceptable, or must the model sit on terrain? Which buildings/features need clickable identity versus visual geometry only?

## References

- [Mapbox Style Specification: model layer](https://docs.mapbox.com/mapbox-gl-js/style-spec/layers/)
- [Mapbox: Using 3D Models, supported glTF and limitations](https://docs.mapbox.com/style-spec/guides/using-3d-models/)
- [Mapbox Android 3D Model Layer example](https://docs.mapbox.com/android/maps/examples/android-view/3D-model-layer/)
- [Mapbox Flutter: Display a 3D model](https://docs.mapbox.com/flutter/maps/examples/model_layer/)
- [Mapbox GL JS: Add 3D models using GeoJSON](https://docs.mapbox.com/mapbox-gl-js/example/add-3d-models-using-geojson-source/)
- [Mapbox GL JS sources API: ModelSource](https://docs.mapbox.com/mapbox-gl-js/api/sources/#modelsourcetype)
- [FlutterMap 8.3.2 MapCamera projection API](https://pub.dev/documentation/flutter_map/8.3.2/flutter_map/MapCamera/latLngToScreenOffset.html)
- [flutter_3d_controller 2.3.0 on pub.dev](https://pub.dev/packages/flutter_3d_controller/versions/2.3.0)
- [flutter_3d_controller source README](https://github.com/m-r-davari/flutter_3d_controller)
- [Khronos glTF 2.0 specification: coordinate system and units](https://registry.khronos.org/glTF/specs/2.0/glTF-2.0.html#coordinate-system-and-units)
- [Khronos glTF Validator](https://github.com/KhronosGroup/glTF-Validator)
- [glTF Transform: EXT_texture_webp](https://gltf-transform.dev/modules/extensions/classes/EXTTextureWebP)
- [Mapbox GL JS performance model](https://docs.mapbox.com/help/troubleshooting/mapbox-gl-js-performance/)

## Scope and verification record

Only repository files read were in `NITC_BUS_TRACKING_APP`; the supplied GLB in Downloads was read-only inspected as explicitly requested. No source, package, lockfile, asset, config, backend, Supabase resource, deployment, or remote setting was changed. The only permitted repository output created was this document. Git branch/status were checked before editing. No test, build, runtime render, device profile, browser GPU profile, or GLTF validator run is claimed.
