import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../supabase/supabase_client_provider.dart';
import 'campus_building.dart';

abstract interface class CampusBuildingRepository {
  Future<List<CampusBuilding>> getBuildings();
}

class SupabaseCampusBuildingRepository implements CampusBuildingRepository {
  const SupabaseCampusBuildingRepository(this._supabase);

  final SupabaseClient? _supabase;

  @override
  Future<List<CampusBuilding>> getBuildings() async {
    final client = _supabase;
    if (client == null) return const [];

    final rows = await client
        .from('campus_buildings')
        .select('id,name,category,lat,lng,lon,amenity,building_type')
        .order('name', ascending: true);

    return (rows as List)
        .whereType<Map<String, dynamic>>()
        .map(CampusBuilding.tryFromJson)
        .whereType<CampusBuilding>()
        .toList(growable: false);
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
});
