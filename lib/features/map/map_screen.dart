import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../design_system/tokens/colors.dart';
import '../../design_system/tokens/spacing.dart';
import '../../services/location/location_service.dart';
import '../../services/maps/map_adapter.dart';
import '../../services/maps/map_config.dart';
import 'providers/map_state_provider.dart';
import 'widgets/bus_detail_sheet.dart';
import 'widgets/bus_marker_widget.dart';
import 'widgets/map_controls.dart';
import 'widgets/stop_marker_widget.dart';

/// Spatial, live-first Map screen for NITC campus transit tracking.
class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  late final TrackletMapController _mapController;

  @override
  void initState() {
    super.initState();
    _mapController = TrackletMapController();
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mapState = ref.watch(mapStateNotifierProvider);
    final locationState = ref.watch(locationStateProvider);

    // Build markers for stops, buses, and user location
    final markers = <MapMarkerData>[];

    // 1. Bus Stops
    for (final stop in mapState.stops) {
      final isSelected = mapState.selectedStop?.id == stop.id;
      markers.add(
        MapMarkerData(
          id: stop.id,
          point: stop.location,
          width: 50.0,
          height: 38.0,
          child: StopMarkerWidget(
            stop: stop,
            isSelected: isSelected,
            onTap: () {
              ref.read(mapStateNotifierProvider.notifier).selectStop(stop);
              _mapController.moveTo(stop.location);
            },
          ),
        ),
      );
    }

    // 2. Active Live Buses
    for (final bus in mapState.buses) {
      final isSelected = mapState.selectedBus?.id == bus.id;
      markers.add(
        MapMarkerData(
          id: bus.id,
          point: bus.position.point,
          width: isSelected ? 48.0 : 40.0,
          height: isSelected ? 48.0 : 40.0,
          child: BusMarkerWidget(
            bus: bus,
            isSelected: isSelected,
            onTap: () {
              ref.read(mapStateNotifierProvider.notifier).selectBus(bus);
              _mapController.moveTo(bus.position.point);
            },
          ),
        ),
      );
    }

    // 3. User Location Marker
    if (locationState.currentLocation != null) {
      markers.add(
        MapMarkerData(
          id: 'user_location',
          point: locationState.currentLocation!,
          width: 28.0,
          height: 28.0,
          child: Container(
            decoration: BoxDecoration(
              color: TrackletColors.primary,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: const [
                BoxShadow(color: Color(0x33000000), blurRadius: 6),
              ],
            ),
          ),
        ),
      );
    }

    // Build Route Polylines
    final polylines = <MapPolylineData>[];
    if (mapState.activeRoute != null && mapState.activeRoute!.path.isNotEmpty) {
      polylines.add(
        MapPolylineData(
          id: mapState.activeRoute!.id,
          points: mapState.activeRoute!.path,
          color: TrackletColors.routeActive.withValues(alpha: 0.8),
          strokeWidth: 4.5,
        ),
      );
    }

    return Scaffold(
      backgroundColor: TrackletColors.background,
      body: Stack(
        children: [
          // Underlying Map
          Positioned.fill(
            child: TrackletMapView(
              controller: _mapController,
              initialCenter: mapState.cameraCenter,
              initialZoom: MapConfig.defaultZoom,
              markers: markers,
              polylines: polylines,
              onTap: (point) {
                ref.read(mapStateNotifierProvider.notifier).clearSelection();
              },
            ),
          ),

          // Top Floating Header
          Positioned(
            top: MediaQuery.paddingOf(context).top + TrackletSpacing.sm,
            left: TrackletSpacing.screenMargin,
            right: TrackletSpacing.screenMargin,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: TrackletSpacing.md,
                vertical: TrackletSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: TrackletColors.surfaceElevated.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: TrackletColors.border),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x10000000),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.directions_bus_rounded,
                    color: TrackletColors.primary,
                    size: 20,
                  ),
                  const SizedBox(width: TrackletSpacing.sm),
                  Text(
                    '${mapState.buses.where((b) => b.isLive).length} Active Buses',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: TrackletColors.busLiveBg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Live NITC Network',
                      style: TextStyle(
                        fontSize: 11,
                        color: TrackletColors.busLive,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Map Control Floating Buttons (Recenter / Locate)
          Positioned(
            right: TrackletSpacing.screenMargin,
            bottom: mapState.selectedBus != null ? 180.0 : 32.0,
            child: MapControls(
              isLocating: locationState.isLoading,
              onRecenterCampus: () {
                _mapController.moveTo(MapConfig.campusCenter);
                ref.read(mapStateNotifierProvider.notifier).centerCampus();
              },
              onLocateUser: () async {
                await ref
                    .read(locationStateProvider.notifier)
                    .requestAndFetchLocation();
                final loc = ref.read(locationStateProvider).currentLocation;
                if (loc != null) {
                  _mapController.moveTo(loc, zoom: 17.5);
                } else {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          ref.read(locationStateProvider).errorMessage ??
                              'Location unavailable',
                        ),
                      ),
                    );
                  }
                }
              },
            ),
          ),

          // Selected Bus Detail Sheet
          if (mapState.selectedBus != null)
            Positioned(
              left: TrackletSpacing.screenMargin,
              right: TrackletSpacing.screenMargin,
              bottom: TrackletSpacing.lg,
              child: BusDetailSheet(
                bus: mapState.selectedBus!,
                route: mapState.activeRoute,
                onClose: () {
                  ref.read(mapStateNotifierProvider.notifier).clearSelection();
                },
              ),
            ),
        ],
      ),
    );
  }
}
