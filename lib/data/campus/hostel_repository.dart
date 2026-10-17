import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/logging/app_logger.dart';
import '../supabase/supabase_client_provider.dart';
import '../transit/transit_cache_metrics.dart';
import 'hostel.dart';

/// Repository interface for campus hostels and residential options.
abstract class HostelRepository {
  Future<List<Hostel>> getHostels();
}

/// Supabase implementation querying public.hostels table / get_hostels() RPC.
class SupabaseHostelRepository implements HostelRepository {
  SupabaseHostelRepository(this._supabase, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final SupabaseClient? _supabase;
  final DateTime Function() _clock;

  static const Duration _cacheTtl = Duration(minutes: 30);
  ({List<Hostel> hostels, DateTime expiresAt})? _cache;
  Future<List<Hostel>>? _inFlight;

  @override
  Future<List<Hostel>> getHostels() async {
    final client = _supabase;
    if (client == null) {
      return const [];
    }

    final now = _clock();
    if (_cache != null && _cache!.expiresAt.isAfter(now)) {
      TransitCacheMetrics.instance.recordHit('hostels');
      return _cache!.hostels;
    }

    final inFlight = _inFlight;
    if (inFlight != null) {
      TransitCacheMetrics.instance.recordDeduplicated('hostels');
      return inFlight;
    }

    final future = _fetchHostels(client);
    _inFlight = future;
    return future.whenComplete(() {
      if (identical(_inFlight, future)) {
        _inFlight = null;
      }
    });
  }

  Future<List<Hostel>> _fetchHostels(SupabaseClient client) async {
    TransitCacheMetrics.instance.recordMiss('hostels');
    final now = _clock();
    try {
      final rpcData = await client.rpc<dynamic>('get_hostels');
      List<Hostel> hostels;
      if (rpcData is List) {
        hostels =
            rpcData
                .map(
                  (row) =>
                      Hostel.fromJson(Map<String, dynamic>.from(row as Map)),
                )
                .toList();
      } else {
        final tableData = await client
            .from('hostels')
            .select('hostel_id, hostel_name, short_code, gender')
            .order('hostel_name', ascending: true);

        hostels =
            tableData
                .map((row) => Hostel.fromJson(Map<String, dynamic>.from(row)))
                .toList();
      }

      _cache = (
        hostels: List.unmodifiable(hostels),
        expiresAt: now.add(_cacheTtl),
      );
      return hostels;
    } catch (e) {
      AppLogger.error('Failed to fetch hostels from Supabase: $e');
      rethrow;
    }
  }

  void invalidateCache() {
    _cache = null;
    _inFlight = null;
  }
}

final hostelRepositoryProvider = Provider<HostelRepository>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return SupabaseHostelRepository(supabase);
});

final hostelsProvider = FutureProvider<List<Hostel>>((ref) {
  return ref.watch(hostelRepositoryProvider).getHostels();
});
