import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/geo/geo_point.dart';
import '../../core/logging/app_logger.dart';
import '../supabase/supabase_client_provider.dart';
import 'bus.dart';
import 'bus_position.dart';
import 'bus_route.dart';
import 'stop.dart';

/// Repository interface and implementation for transit operations.
abstract class TransitRepository {
  Future<List<BusRoute>> getRoutes();
  Future<List<Stop>> getStops();
  Future<List<Bus>> getActiveBuses();
  Stream<List<Bus>> watchActiveBuses();
  Future<Stop?> getNearestStop(GeoPoint userLocation);
  Future<Bus?> getBusById(String busId);
}

class SupabaseTransitRepository implements TransitRepository {
  SupabaseTransitRepository(this._supabase);

  final SupabaseClient? _supabase;
  StreamController<List<Bus>>? _busStreamController;
  Timer? _simulationTimer;
  List<Bus> _currentBuses = _defaultNitcBuses;

  @override
  Future<List<BusRoute>> getRoutes() async {
    if (_supabase != null) {
      try {
        final response = await _supabase
            .from('routes')
            .select()
            .eq('is_active', true);
        return (response as List)
            .map((e) => BusRoute.fromJson(e as Map<String, dynamic>))
            .toList();
      } catch (e) {
        AppLogger.warning(
          'Failed to fetch routes from Supabase, falling back to local data: $e',
        );
      }
    }
    return _defaultNitcRoutes;
  }

  @override
  Future<List<Stop>> getStops() async {
    if (_supabase != null) {
      try {
        final response = await _supabase
            .from('stops')
            .select()
            .order('order_index');
        return (response as List)
            .map((e) => Stop.fromJson(e as Map<String, dynamic>))
            .toList();
      } catch (e) {
        AppLogger.warning(
          'Failed to fetch stops from Supabase, falling back to local data: $e',
        );
      }
    }
    return _defaultNitcStops;
  }

  @override
  Future<List<Bus>> getActiveBuses() async {
    if (_supabase != null) {
      try {
        final response = await _supabase.from('buses').select();
        final buses = (response as List)
            .map((e) => Bus.fromJson(e as Map<String, dynamic>))
            .toList();
        if (buses.isNotEmpty) return buses;
      } catch (e) {
        AppLogger.warning(
          'Failed to fetch buses from Supabase, falling back to local data: $e',
        );
      }
    }
    return _currentBuses;
  }

  @override
  Stream<List<Bus>> watchActiveBuses() {
    _busStreamController ??= StreamController<List<Bus>>.broadcast(
      onListen: () {
        _busStreamController?.add(_currentBuses);
        _startSimulationTimer();
      },
      onCancel: () {
        if (!(_busStreamController?.hasListener ?? false)) {
          _simulationTimer?.cancel();
        }
      },
    );

    return _busStreamController!.stream;
  }

  void _startSimulationTimer() {
    _simulationTimer?.cancel();
    _simulationTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (!(_busStreamController?.hasListener ?? false)) {
        timer.cancel();
        return;
      }

      // Slightly update bus positions along their campus loops for realistic live movement
      _currentBuses = _currentBuses.map((bus) {
        if (!bus.isLive) return bus;

        final currentPt = bus.position.point;
        // Jitter / animate coordinate slightly along campus road axis
        final deltaLat = (DateTime.now().second % 4 - 1.5) * 0.00008;
        final deltaLng = (DateTime.now().second % 3 - 1.0) * 0.00008;

        return bus.copyWith(
          lastUpdated: DateTime.now(),
          position: bus.position.copyWith(
            point: GeoPoint(
              latitude: currentPt.latitude + deltaLat,
              longitude: currentPt.longitude + deltaLng,
            ),
            speedKmH: 18.0 + (DateTime.now().second % 8),
          ),
        );
      }).toList();

      _busStreamController?.add(_currentBuses);
    });
  }

  @override
  Future<Stop?> getNearestStop(GeoPoint userLocation) async {
    final stops = await getStops();
    if (stops.isEmpty) return null;

    Stop? nearest;
    var minDistance = double.infinity;

    for (final stop in stops) {
      final dist = userLocation.distanceToMeters(stop.location);
      if (dist < minDistance) {
        minDistance = dist;
        nearest = stop;
      }
    }

    return nearest;
  }

  @override
  Future<Bus?> getBusById(String busId) async {
    final buses = await getActiveBuses();
    try {
      return buses.firstWhere((b) => b.id == busId);
    } catch (_) {
      return null;
    }
  }
}

final transitRepositoryProvider = Provider<TransitRepository>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return SupabaseTransitRepository(supabase);
});

// Seed data representing NIT Calicut campus transit
final List<Stop> _defaultNitcStops = [
  const Stop(
    id: 'stop-main-gate',
    name: 'Main Gate',
    code: 'MG',
    location: GeoPoint(latitude: 11.3216, longitude: 75.9337),
    walkingTimeMinutes: 2,
    isMajorHub: true,
    orderIndex: 0,
  ),
  const Stop(
    id: 'stop-lhc',
    name: 'Lecture Hall Complex (LHC)',
    code: 'LHC',
    location: GeoPoint(latitude: 11.3228, longitude: 75.9348),
    walkingTimeMinutes: 4,
    isMajorHub: true,
    orderIndex: 1,
  ),
  const Stop(
    id: 'stop-mega-hostel',
    name: 'Mega Hostel',
    code: 'MH',
    location: GeoPoint(latitude: 11.3260, longitude: 75.9380),
    walkingTimeMinutes: 8,
    isMajorHub: true,
    orderIndex: 2,
  ),
  const Stop(
    id: 'stop-aryabhatta',
    name: 'Aryabhatta Hostel',
    code: 'AB',
    location: GeoPoint(latitude: 11.3245, longitude: 75.9365),
    walkingTimeMinutes: 6,
    isMajorHub: false,
    orderIndex: 3,
  ),
  const Stop(
    id: 'stop-east-gate',
    name: 'East Campus Gate',
    code: 'EG',
    location: GeoPoint(latitude: 11.3200, longitude: 75.9395),
    walkingTimeMinutes: 10,
    isMajorHub: false,
    orderIndex: 4,
  ),
];

final List<BusRoute> _defaultNitcRoutes = [
  const BusRoute(
    id: 'route-campus-express',
    name: 'Campus Express',
    code: 'CE-1',
    colorHex: '#0B6BCB',
    description: 'Main Gate ↔ LHC ↔ Mega Hostel ↔ Aryabhatta',
    stopIds: [
      'stop-main-gate',
      'stop-lhc',
      'stop-mega-hostel',
      'stop-aryabhatta',
    ],
    path: [
      GeoPoint(latitude: 11.3216, longitude: 75.9337),
      GeoPoint(latitude: 11.3228, longitude: 75.9348),
      GeoPoint(latitude: 11.3245, longitude: 75.9365),
      GeoPoint(latitude: 11.3260, longitude: 75.9380),
      GeoPoint(latitude: 11.3200, longitude: 75.9395),
    ],
    isActive: true,
  ),
  const BusRoute(
    id: 'route-hostel-shuttle',
    name: 'Hostel Shuttle',
    code: 'HS-2',
    colorHex: '#5B47C8',
    description: 'Mega Hostel ↔ East Campus Gate ↔ Main Gate',
    stopIds: ['stop-mega-hostel', 'stop-east-gate', 'stop-main-gate'],
    path: [
      GeoPoint(latitude: 11.3260, longitude: 75.9380),
      GeoPoint(latitude: 11.3200, longitude: 75.9395),
      GeoPoint(latitude: 11.3216, longitude: 75.9337),
    ],
    isActive: true,
  ),
];

final List<Bus> _defaultNitcBuses = [
  Bus(
    id: 'bus-1',
    numberPlate: 'KL-11-NITC-101',
    name: 'Bus 1 (Campus Express)',
    routeId: 'route-campus-express',
    status: BusStatus.live,
    position: BusPosition(
      point: const GeoPoint(latitude: 11.3222, longitude: 75.9342),
      heading: 45.0,
      speedKmH: 22.5,
      timestamp: DateTime.now(),
    ),
    occupancy: 'Seats Available',
    lastUpdated: DateTime.now(),
  ),
  Bus(
    id: 'bus-2',
    numberPlate: 'KL-11-NITC-102',
    name: 'Bus 2 (Hostel Shuttle)',
    routeId: 'route-hostel-shuttle',
    status: BusStatus.due,
    position: BusPosition(
      point: const GeoPoint(latitude: 11.3255, longitude: 75.9375),
      heading: 180.0,
      speedKmH: 0.0,
      timestamp: DateTime.now().subtract(const Duration(minutes: 2)),
    ),
    occupancy: 'Standing Only',
    lastUpdated: DateTime.now().subtract(const Duration(minutes: 2)),
  ),
];
