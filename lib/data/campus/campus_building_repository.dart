import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../supabase/supabase_client_provider.dart';
import '../transit/transit_cache_metrics.dart';
import 'campus_building.dart';

abstract interface class CampusBuildingRepository {
  Future<List<CampusBuilding>> getBuildings();
}

class SupabaseCampusBuildingRepository implements CampusBuildingRepository {
  SupabaseCampusBuildingRepository(this._supabase, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final SupabaseClient? _supabase;
  final DateTime Function() _clock;

  static const Duration _cacheTtl = Duration(minutes: 30);
  ({List<CampusBuilding> buildings, DateTime expiresAt})? _cache;
  Future<List<CampusBuilding>>? _inFlight;

  @override
  Future<List<CampusBuilding>> getBuildings() async {
    final client = _supabase;
    if (client == null) return const [];

    final now = _clock();
    if (_cache != null && _cache!.expiresAt.isAfter(now)) {
      TransitCacheMetrics.instance.recordHit('buildings');
      return _cache!.buildings;
    }

    final inFlight = _inFlight;
    if (inFlight != null) {
      TransitCacheMetrics.instance.recordDeduplicated('buildings');
      return inFlight;
    }

    final future = _fetchBuildings(client);
    _inFlight = future;
    return future.whenComplete(() {
      if (identical(_inFlight, future)) {
        _inFlight = null;
      }
    });
  }

  Future<List<CampusBuilding>> _fetchBuildings(SupabaseClient client) async {
    TransitCacheMetrics.instance.recordMiss('buildings');
    final now = _clock();
    final rows = await client
        .from('campus_buildings')
        .select('id,name,category,lat,lng,lon,amenity,building_type')
        .order('name', ascending: true);

    final buildings = (rows as List)
        .whereType<Map<String, dynamic>>()
        .map(CampusBuilding.tryFromJson)
        .whereType<CampusBuilding>()
        .toList(growable: false);

    _cache = (buildings: buildings, expiresAt: now.add(_cacheTtl));
    return buildings;
  }

  void invalidateCache() {
    _cache = null;
    _inFlight = null;
  }
}

final campusBuildingRepositoryProvider = Provider<CampusBuildingRepository>((
  ref,
) {
  final supabase = ref.watch(supabaseClientProvider);
  return SupabaseCampusBuildingRepository(supabase);
});

/// Cached by Riverpod for the lifetime of the map feature; presentation rebuilds
/// do not trigger another campus-building query.
final campusBuildingsProvider = FutureProvider<List<CampusBuilding>>((ref) {
  return ref.watch(campusBuildingRepositoryProvider).getBuildings();
}, retry: (retryCount, error) => null);
