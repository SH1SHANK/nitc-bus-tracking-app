import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/geo/geo_point.dart';
import '../../core/logging/app_logger.dart';
import '../supabase/supabase_client_provider.dart';
import 'bus.dart';
import 'bus_stop_event.dart';
import 'bus_route.dart';
import 'route_stop_occurrence.dart';
import 'scheduled_departure.dart';
import 'stop.dart';
import 'transit_cache_metrics.dart';

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
  Future<List<BusStopEvent>> getBusStopEvents(String tripId);
}

class SupabaseTransitRepository implements TransitRepository {
  SupabaseTransitRepository(
    this._supabase, {
    DateTime Function()? clock,
    Future<List<BusStopEvent>> Function(String tripId)? stopEventLoader,
  }) : _clock = clock ?? DateTime.now,
       _stopEventLoader = stopEventLoader;

  final SupabaseClient? _supabase;
  final DateTime Function() _clock;
  final Future<List<BusStopEvent>> Function(String tripId)? _stopEventLoader;
  List<Bus> _lastKnownBuses = const [];
  DateTime? _lastSuccessfulBusFetch;
  final Map<String, ({List<BusStopEvent> events, DateTime expiresAt})>
  _stopEventCache = {};
  final Map<String, Future<List<BusStopEvent>>> _stopEventRequests = {};
  final Map<String, int> _stopEventGenerations = {};

  static const Duration _referenceDataTtl = Duration(minutes: 10);
  ({List<Stop> stops, DateTime expiresAt})? _stopsCache;
  ({List<BusRoute> routes, DateTime expiresAt})? _routesCache;
  final Map<
    String,
    ({List<RouteStopOccurrence> occurrences, DateTime expiresAt})
  >
  _routeStopsCache = {};
  ({List<ScheduledDeparture> departures, DateTime expiresAt})?
  _scheduledDeparturesCache;

  // In-flight request deduplication futures
  Future<List<Bus>>? _inFlightActiveBuses;
  Future<List<Stop>>? _inFlightStops;
  Future<List<BusRoute>>? _inFlightRoutes;
  final Map<String, Future<List<RouteStopOccurrence>>> _inFlightRouteStops = {};
  Future<List<ScheduledDeparture>>? _inFlightScheduledDepartures;

  // Unified active buses stream management
  StreamController<List<Bus>>? _activeBusesController;
  RealtimeChannel? _activeBusesChannel;
  Timer? _activeBusesFallbackTimer;
  DateTime _lastBroadcastReceived = DateTime.fromMillisecondsSinceEpoch(0);
  bool _isRefreshingActiveBuses = false;
  bool _pendingRefreshActiveBuses = false;

  DateTime? get lastSuccessfulBusFetch => _lastSuccessfulBusFetch;
  List<Bus> get lastKnownBuses => _lastKnownBuses;

  @override
  Future<List<BusRoute>> getRoutes({List<Stop>? knownStops}) async {
    final client = _supabase;
    if (client == null) return const [];

    final now = _clock();
    if (knownStops == null &&
        _routesCache != null &&
        _routesCache!.expiresAt.isAfter(now)) {
      TransitCacheMetrics.instance.recordHit('routes');
      return _routesCache!.routes;
    }

    if (knownStops == null) {
      final inFlight = _inFlightRoutes;
      if (inFlight != null) {
        TransitCacheMetrics.instance.recordDeduplicated('routes');
        return inFlight;
      }
      final future = _doGetRoutes(client, null);
      _inFlightRoutes = future;
      return future.whenComplete(() {
        if (identical(_inFlightRoutes, future)) {
          _inFlightRoutes = null;
        }
      });
    }

    return _doGetRoutes(client, knownStops);
  }

  Future<List<BusRoute>> _doGetRoutes(
    SupabaseClient client,
    List<Stop>? knownStops,
  ) async {
    TransitCacheMetrics.instance.recordMiss('routes');
    final now = _clock();
    try {
      final stops = knownStops ?? await getStops();
      final stopMap = {for (final stop in stops) stop.id: stop};
      final routeRows = await client
          .from('routes')
          .select(
            'id,name,route_code,description,direction,path,path_source,path_verified,route_color,is_active',
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

      final routes =
          routeRows.map((rawRoute) {
            final route = Map<String, dynamic>.from(rawRoute);
            final routeId = route['id']?.toString() ?? '';
            return BusRoute.fromJson(
              route,
              stops: stops,
              stopOccurrences: occurrencesByRoute[routeId] ?? const [],
            );
          }).toList();

      if (knownStops == null) {
        _routesCache = (
          routes: List.unmodifiable(routes),
          expiresAt: now.add(_referenceDataTtl),
        );
      }
      return routes;
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

    final now = _clock();
    if (_stopsCache != null && _stopsCache!.expiresAt.isAfter(now)) {
      TransitCacheMetrics.instance.recordHit('stops');
      return _stopsCache!.stops;
    }

    final inFlight = _inFlightStops;
    if (inFlight != null) {
      TransitCacheMetrics.instance.recordDeduplicated('stops');
      return inFlight;
    }

    final future = _doGetStops(client);
    _inFlightStops = future;
    return future.whenComplete(() {
      if (identical(_inFlightStops, future)) {
        _inFlightStops = null;
      }
    });
  }

  Future<List<Stop>> _doGetStops(SupabaseClient client) async {
    TransitCacheMetrics.instance.recordMiss('stops');
    final now = _clock();
    try {
      final response = await client
          .from('stops')
          .select()
          .eq('is_active', true)
          .order('name', ascending: true);
      final stops =
          response
              .map((row) => Stop.fromJson(Map<String, dynamic>.from(row)))
              .toList();
      _stopsCache = (
        stops: List.unmodifiable(stops),
        expiresAt: now.add(_referenceDataTtl),
      );
      return stops;
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

    final now = _clock();
    final cached = _routeStopsCache[routeId];
    if (cached != null && cached.expiresAt.isAfter(now)) {
      TransitCacheMetrics.instance.recordHit('route_stops');
      return cached.occurrences;
    }

    final inFlight = _inFlightRouteStops[routeId];
    if (inFlight != null) {
      TransitCacheMetrics.instance.recordDeduplicated('route_stops');
      return inFlight;
    }

    final future = _doGetRouteStops(client, routeId);
    _inFlightRouteStops[routeId] = future;
    return future.whenComplete(() {
      if (identical(_inFlightRouteStops[routeId], future)) {
        _inFlightRouteStops.remove(routeId);
      }
    });
  }

  Future<List<RouteStopOccurrence>> _doGetRouteStops(
    SupabaseClient client,
    String routeId,
  ) async {
    TransitCacheMetrics.instance.recordMiss('route_stops');
    final now = _clock();
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

      final rawOccurrences =
          response.map((rawRow) {
            final row = Map<String, dynamic>.from(rawRow);
            final stopId = row['stop_id']?.toString() ?? '';
            return RouteStopOccurrence.fromJson(row, stop: stopMap[stopId]);
          }).toList();
      final occurrences = RouteStopOccurrence.normalizeOutAndBack(
        rawOccurrences,
      );
      _routeStopsCache[routeId] = (
        occurrences: List.unmodifiable(occurrences),
        expiresAt: now.add(_referenceDataTtl),
      );
      return occurrences;
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

    final now = _clock();
    if (_scheduledDeparturesCache != null &&
        _scheduledDeparturesCache!.expiresAt.isAfter(now)) {
      TransitCacheMetrics.instance.recordHit('departures');
      return _scheduledDeparturesCache!.departures;
    }

    final inFlight = _inFlightScheduledDepartures;
    if (inFlight != null) {
      TransitCacheMetrics.instance.recordDeduplicated('departures');
      return inFlight;
    }

    final future = _doGetScheduledDepartures(client);
    _inFlightScheduledDepartures = future;
    return future.whenComplete(() {
      if (identical(_inFlightScheduledDepartures, future)) {
        _inFlightScheduledDepartures = null;
      }
    });
  }

  Future<List<ScheduledDeparture>> _doGetScheduledDepartures(
    SupabaseClient client,
  ) async {
    TransitCacheMetrics.instance.recordMiss('departures');
    final now = _clock();
    try {
      final response = await client.from('bus_timings').select();
      final departures =
          response.map((row) => ScheduledDeparture.fromJson(row)).toList();
      _scheduledDeparturesCache = (
        departures: List.unmodifiable(departures),
        expiresAt: now.add(_referenceDataTtl),
      );
      return departures;
    } catch (error, stackTrace) {
      AppLogger.error(
        'Failed to fetch scheduled bus departures from Supabase',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  void invalidateStaticCaches() {
    _stopsCache = null;
    _routesCache = null;
    _routeStopsCache.clear();
    _scheduledDeparturesCache = null;
    _inFlightStops = null;
    _inFlightRoutes = null;
    _inFlightRouteStops.clear();
    _inFlightScheduledDepartures = null;
  }

  @override
  Future<List<Bus>> getActiveBuses() async {
    final client = _supabase;
    if (client == null) return const [];
    return _fetchActiveBuses(client);
  }

  Future<List<Bus>> _fetchActiveBuses(SupabaseClient client) {
    final inFlight = _inFlightActiveBuses;
    if (inFlight != null) {
      TransitCacheMetrics.instance.recordDeduplicated('active_buses');
      return inFlight;
    }
    final future = _doFetchActiveBuses(client);
    _inFlightActiveBuses = future;
    return future.whenComplete(() {
      if (identical(_inFlightActiveBuses, future)) {
        _inFlightActiveBuses = null;
      }
    });
  }

  Future<List<Bus>> _doFetchActiveBuses(SupabaseClient client) async {
    TransitCacheMetrics.instance.recordMiss('active_buses');
    try {
      final response = await client.rpc<List<dynamic>>(
        'get_active_bus_positions_v2',
      );
      final buses =
          response
              .map((row) => Bus.fromJson(row as Map<String, dynamic>))
              .toList();
      for (final previous in _lastKnownBuses) {
        final current = buses.where((bus) => bus.id == previous.id).firstOrNull;
        if (current != null &&
            (current.tripId != previous.tripId ||
                current.routeId != previous.routeId)) {
          if (previous.tripId != null) {
            invalidateBusStopEvents(previous.tripId!);
          }
          if (current.tripId != null) {
            invalidateBusStopEvents(current.tripId!);
          }
        }
      }
      _lastKnownBuses = buses;
      _lastSuccessfulBusFetch = _clock();
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

    _ensureActiveBusesStreamInitialized(client);
    return _buildActiveBusesStream();
  }

  void _ensureActiveBusesStreamInitialized(SupabaseClient client) {
    if (_activeBusesController != null && !_activeBusesController!.isClosed) {
      return;
    }

    _activeBusesController = StreamController<List<Bus>>.broadcast(
      onListen: () => _startActiveBusesSubscription(client),
      onCancel: () => _stopActiveBusesSubscription(client),
    );
  }

  void _startActiveBusesSubscription(SupabaseClient client) {
    _activeBusesChannel =
        client
            .channel('active-bus-positions')
            .onBroadcast(
              event: 'bus_state_updated',
              callback: (_) {
                _lastBroadcastReceived = _clock();
                TransitCacheMetrics.instance.recordRealtimeBroadcast();
                unawaited(_triggerActiveBusesStreamRefresh(client));
              },
            )
            .subscribe();

    _activeBusesFallbackTimer = Timer.periodic(const Duration(seconds: 20), (
      _,
    ) {
      final timeSinceBroadcast = _clock().difference(_lastBroadcastReceived);
      if (timeSinceBroadcast >= const Duration(seconds: 18)) {
        TransitCacheMetrics.instance.recordFallbackPoll();
        unawaited(_triggerActiveBusesStreamRefresh(client));
      }
    });

    unawaited(_triggerActiveBusesStreamRefresh(client));
  }

  void _stopActiveBusesSubscription(SupabaseClient client) {
    _activeBusesFallbackTimer?.cancel();
    _activeBusesFallbackTimer = null;
    if (_activeBusesChannel != null) {
      final ch = _activeBusesChannel!;
      _activeBusesChannel = null;
      unawaited(client.removeChannel(ch));
    }
  }

  Future<void> _triggerActiveBusesStreamRefresh(SupabaseClient client) async {
    if (_isRefreshingActiveBuses) {
      _pendingRefreshActiveBuses = true;
      return;
    }

    _isRefreshingActiveBuses = true;
    try {
      do {
        _pendingRefreshActiveBuses = false;
        try {
          final buses = await _fetchActiveBuses(client);
          if (_activeBusesController != null &&
              !_activeBusesController!.isClosed) {
            _activeBusesController!.add(buses);
          }
        } catch (error, stackTrace) {
          if (_activeBusesController != null &&
              !_activeBusesController!.isClosed) {
            _activeBusesController!.addError(error, stackTrace);
          }
        }
      } while (_pendingRefreshActiveBuses &&
          _activeBusesController != null &&
          !_activeBusesController!.isClosed);
    } finally {
      _isRefreshingActiveBuses = false;
    }
  }

  Stream<List<Bus>> _buildActiveBusesStream() {
    return Stream<List<Bus>>.multi((controller) {
      if (_lastKnownBuses.isNotEmpty) {
        controller.add(_lastKnownBuses);
      }
      final subscription = _activeBusesController!.stream.listen(
        controller.add,
        onError: controller.addError,
        onDone: controller.close,
      );
      controller.onCancel = () {
        subscription.cancel();
      };
    });
  }

  void dispose() {
    _activeBusesFallbackTimer?.cancel();
    _activeBusesFallbackTimer = null;
    if (_supabase != null && _activeBusesChannel != null) {
      unawaited(_supabase.removeChannel(_activeBusesChannel!));
      _activeBusesChannel = null;
    }
    _activeBusesController?.close();
    _activeBusesController = null;
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

  @override
  Future<List<BusStopEvent>> getBusStopEvents(String tripId) async {
    final loader = _stopEventLoader;
    if (loader != null) return _cachedStopEvents(tripId, () => loader(tripId));
    final client = _supabase;
    if (client == null) return const [];
    return _cachedStopEvents(tripId, () => _fetchBusStopEvents(client, tripId));
  }

  Future<List<BusStopEvent>> _cachedStopEvents(
    String tripId,
    Future<List<BusStopEvent>> Function() load,
  ) async {
    final cached = _stopEventCache[tripId];
    if (cached != null && _clock().isBefore(cached.expiresAt)) {
      return cached.events;
    }
    final pending = _stopEventRequests[tripId];
    if (pending != null) return pending;
    final generation = _stopEventGenerations[tripId] ?? 0;
    final request = Future<List<BusStopEvent>>.sync(
      load,
    ).then<List<BusStopEvent>>(
      (events) {
        if ((_stopEventGenerations[tripId] ?? 0) == generation) {
          _stopEventCache[tripId] = (
            events: List.unmodifiable(events),
            expiresAt: _clock().add(const Duration(seconds: 10)),
          );
        }
        return events;
      },
      onError: (Object error, StackTrace stackTrace) {
        AppLogger.error(
          'Failed to fetch stop progress for active bus trip',
          error: error,
          stackTrace: stackTrace,
          tag: 'TransitRepository',
        );
        return const <BusStopEvent>[];
      },
    );
    _stopEventRequests[tripId] = request;
    try {
      return await request;
    } finally {
      if (identical(_stopEventRequests[tripId], request)) {
        unawaited(_stopEventRequests.remove(tripId));
      }
    }
  }

  void invalidateBusStopEvents(String tripId) {
    _stopEventGenerations.update(
      tripId,
      (value) => value + 1,
      ifAbsent: () => 1,
    );
    _stopEventCache.remove(tripId);
    unawaited(_stopEventRequests.remove(tripId));
  }

  Future<List<BusStopEvent>> _fetchBusStopEvents(
    SupabaseClient client,
    String tripId,
  ) async {
    final rows = await client.rpc<List<dynamic>>(
      'get_active_trip_stop_events',
      params: {'p_trip_id': tripId},
    );
    return rows
        .map(
          (row) => BusStopEvent.fromJson(Map<String, dynamic>.from(row as Map)),
        )
        .where((event) => event.stopId.isNotEmpty)
        .toList();
  }
}

final transitRepositoryProvider = Provider<TransitRepository>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return SupabaseTransitRepository(supabase);
});
