import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../services/storage/storage_service.dart';
import '../supabase/supabase_client_provider.dart';
import '../transit/transit_cache_metrics.dart';
import 'campus_building.dart';

abstract interface class CampusBuildingRepository {
  Future<List<CampusBuilding>> getBuildings();
}

class SupabaseCampusBuildingRepository implements CampusBuildingRepository {
  SupabaseCampusBuildingRepository(
    this._supabase, {
    StorageService? storageService,
    DateTime Function()? clock,
  }) : _storageService = storageService,
       _clock = clock ?? DateTime.now;

  final SupabaseClient? _supabase;
  final StorageService? _storageService;
  final DateTime Function() _clock;

  static const Duration _cacheTtl = Duration(minutes: 30);
  static const String _persistentCacheKey = 'tracklet_campus_buildings_cache';
  ({List<CampusBuilding> buildings, DateTime expiresAt})? _cache;
  Future<List<CampusBuilding>>? _inFlight;

  @override
  Future<List<CampusBuilding>> getBuildings() async {
    final client = _supabase;

    final now = _clock();
    if (_cache != null && _cache!.expiresAt.isAfter(now)) {
      TransitCacheMetrics.instance.recordHit('buildings');
      return _cache!.buildings;
    }

    // Try restoring from persistent local storage if memory cache is empty
    if (_cache == null && _storageService != null) {
      final raw = _storageService.getString(_persistentCacheKey);
      if (raw != null && raw.isNotEmpty) {
        try {
          final decoded = jsonDecode(raw) as List;
          final cached = decoded
              .whereType<Map<String, dynamic>>()
              .map(CampusBuilding.tryFromJson)
              .whereType<CampusBuilding>()
              .toList(growable: false);
          if (cached.isNotEmpty) {
            _cache = (buildings: cached, expiresAt: now.add(_cacheTtl));
            TransitCacheMetrics.instance.recordHit('buildings');
            if (client == null) return cached;
            // Background refresh without blocking initial return
            _inFlight = _fetchBuildings(client).whenComplete(() {
              _inFlight = null;
            });
            return cached;
          }
        } catch (_) {}
      }
    }

    if (client == null) return _cache?.buildings ?? const [];

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
        .select(
          'id,name,category,description,lat,lng,lon,amenity,building_type',
        )
        .order('name', ascending: true);

    final buildings = (rows as List)
        .whereType<Map<String, dynamic>>()
        .map(CampusBuilding.tryFromJson)
        .whereType<CampusBuilding>()
        .toList(growable: false);

    _cache = (buildings: buildings, expiresAt: now.add(_cacheTtl));

    // Save to persistent local storage for instant offline hydration
    if (_storageService != null && buildings.isNotEmpty) {
      try {
        final encoded = jsonEncode(buildings.map((b) => b.toJson()).toList());
        await _storageService.setString(_persistentCacheKey, encoded);
      } catch (_) {}
    }

    return buildings;
  }

  void invalidateCache() {
    _cache = null;
    _inFlight = null;
    _storageService?.remove(_persistentCacheKey);
  }
}

final campusBuildingRepositoryProvider = Provider<CampusBuildingRepository>((
  ref,
) {
  final supabase = ref.watch(supabaseClientProvider);
  final storage = ref.watch(storageServiceProvider);
  return SupabaseCampusBuildingRepository(supabase, storageService: storage);
});

/// Cached by Riverpod for the lifetime of the map feature; presentation rebuilds
/// do not trigger another campus-building query.
final campusBuildingsProvider = FutureProvider<List<CampusBuilding>>((ref) {
  return ref.watch(campusBuildingRepositoryProvider).getBuildings();
}, retry: (retryCount, error) => null);
