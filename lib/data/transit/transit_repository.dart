import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/geo/geo_point.dart';
import '../../core/logging/app_logger.dart';
import '../supabase/supabase_client_provider.dart';
import 'bus.dart';
import 'bus_route.dart';
import 'route_stop_occurrence.dart';
import 'scheduled_departure.dart';
import 'stop.dart';

/// Repository interface for database-backed transit operations.
abstract class TransitRepository {
  Future<List<BusRoute>> getRoutes({List<Stop>? knownStops});
  Future<List<Stop>> getStops();
  Future<List<RouteStopOccurrence>> getRouteStops(String routeId);
  Future<List<Bus>> getActiveBuses();
  Future<List<ScheduledDeparture>> getScheduledDepartures();
  Stream<List<Bus>> watchActiveBuses();
  Future<Stop?> getNearestStop(GeoPoint userLocation);
  Future<Bus?> getBusById(String busId);
}

class SupabaseTransitRepository implements TransitRepository {
  SupabaseTransitRepository(this._supabase);

  final SupabaseClient? _supabase;
  List<Bus> _lastKnownBuses = const [];

  @override
  Future<List<BusRoute>> getRoutes({List<Stop>? knownStops}) async {
    final client = _supabase;
    if (client == null) return const [];

    try {
      final stops = knownStops ?? await getStops();
      final stopMap = {for (final stop in stops) stop.id: stop};
      final routeRows = await client
          .from('routes')
          .select(
            'id,name,route_code,description,direction,path,path_source,path_verified,is_active',
          )
          .eq('is_active', true)
          .order('route_code', ascending: true);

      if (routeRows.isEmpty) return const [];

      final occurrenceRows = await client
          .from('route_stops')
          .select(
            'route_id,stop_id,sequence,distance_from_start,estimated_duration_sec',
          )
          .order('sequence', ascending: true);
      final occurrencesByRoute = <String, List<RouteStopOccurrence>>{};
      for (final rawRow in occurrenceRows) {
        final row = Map<String, dynamic>.from(rawRow);
        final stopId = row['stop_id']?.toString() ?? '';
        final occurrence = RouteStopOccurrence.fromJson(
          row,
          stop: stopMap[stopId],
        );
        (occurrencesByRoute[occurrence.routeId] ??= []).add(occurrence);
      }

      return routeRows.map((rawRoute) {
        final route = Map<String, dynamic>.from(rawRoute);
        final routeId = route['id']?.toString() ?? '';
        return BusRoute.fromJson(
          route,
          stops: stops,
          stopOccurrences: occurrencesByRoute[routeId] ?? const [],
        );
      }).toList();
    } catch (error, stackTrace) {
      AppLogger.error(
        'Failed to fetch routes from Supabase',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  @override
  Future<List<Stop>> getStops() async {
    final client = _supabase;
    if (client == null) return const [];

    try {
      final response = await client
          .from('stops')
          .select()
          .eq('is_active', true)
          .order('name', ascending: true);
      return response
          .map((row) => Stop.fromJson(Map<String, dynamic>.from(row)))
          .toList();
    } catch (error, stackTrace) {
      AppLogger.error(
        'Failed to fetch stops from Supabase',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  @override
  Future<List<RouteStopOccurrence>> getRouteStops(String routeId) async {
    final client = _supabase;
    if (client == null) return const [];

    try {
      final stops = await getStops();
      final stopMap = {for (final stop in stops) stop.id: stop};
      final response = await client
          .from('route_stops')
          .select(
            'route_id,stop_id,sequence,distance_from_start,estimated_duration_sec',
          )
          .eq('route_id', routeId)
          .order('sequence', ascending: true);

      return response.map((rawRow) {
        final row = Map<String, dynamic>.from(rawRow);
        final stopId = row['stop_id']?.toString() ?? '';
        return RouteStopOccurrence.fromJson(row, stop: stopMap[stopId]);
      }).toList();
    } catch (error, stackTrace) {
      AppLogger.error(
        'Failed to fetch route stops from Supabase',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  @override
  Future<List<ScheduledDeparture>> getScheduledDepartures() async {
    final client = _supabase;
    if (client == null) return const [];

    try {
      final response = await client.from('bus_timings').select();
      return response.map((row) => ScheduledDeparture.fromJson(row)).toList();
    } catch (error, stackTrace) {
      AppLogger.error(
        'Failed to fetch scheduled bus departures from Supabase',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  @override
  Future<List<Bus>> getActiveBuses() async {
    final client = _supabase;
    if (client == null) return const [];
    return _fetchActiveBuses(client);
  }

  Future<List<Bus>> _fetchActiveBuses(SupabaseClient client) async {
    try {
      final response = await client.rpc<List<dynamic>>(
        'get_active_bus_positions',
      );
      _lastKnownBuses =
          response
              .map((row) => Bus.fromJson(row as Map<String, dynamic>))
              .toList();
      return _lastKnownBuses;
    } catch (error, stackTrace) {
      AppLogger.error(
        'Failed to fetch active bus positions from Supabase',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  @override
  Stream<List<Bus>> watchActiveBuses() {
    final client = _supabase;
    if (client == null) return Stream.value(const []);

    late final RealtimeChannel channel;
    late final StreamController<List<Bus>> controller;
    var refreshInProgress = false;
    var refreshPending = false;

    Future<void> refresh() async {
      if (refreshInProgress) {
        refreshPending = true;
        return;
      }

      refreshInProgress = true;
      try {
        do {
          refreshPending = false;
          try {
            final buses = await _fetchActiveBuses(client);
            if (!controller.isClosed) controller.add(buses);
          } catch (error, stackTrace) {
            if (!controller.isClosed) controller.addError(error, stackTrace);
          }
        } while (refreshPending && !controller.isClosed);
      } finally {
        refreshInProgress = false;
      }
    }

    controller = StreamController<List<Bus>>(
      onListen: () {
        channel =
            client
                .channel('active-bus-positions')
                .onPostgresChanges(
                  event: PostgresChangeEvent.all,
                  schema: 'public',
                  table: 'bus_current_state',
                  callback: (_) => unawaited(refresh()),
                )
                .subscribe();
        unawaited(refresh());
      },
      onCancel: () async {
        await client.removeChannel(channel);
        await controller.close();
      },
    );
    return controller.stream;
  }

  @override
  Future<Stop?> getNearestStop(GeoPoint userLocation) async {
    final stops = await getStops();
    if (stops.isEmpty) return null;

    Stop? nearest;
    var minDistance = double.infinity;
    for (final stop in stops) {
      final distance = userLocation.distanceToMeters(stop.location);
      if (distance < minDistance) {
        minDistance = distance;
        nearest = stop;
      }
    }
    return nearest;
  }

  @override
  Future<Bus?> getBusById(String busId) async {
    final cached = _lastKnownBuses.where((bus) => bus.id == busId).firstOrNull;
    if (cached != null) return cached;
    final buses = await getActiveBuses();
    return buses.where((bus) => bus.id == busId).firstOrNull;
  }
}

final transitRepositoryProvider = Provider<TransitRepository>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return SupabaseTransitRepository(supabase);
});
