import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/logging/app_logger.dart';
import '../supabase/supabase_client_provider.dart';
import 'hostel.dart';

/// Repository interface for campus hostels and residential options.
abstract class HostelRepository {
  Future<List<Hostel>> getHostels();
}

/// Supabase implementation querying public.hostels table / get_hostels() RPC.
class SupabaseHostelRepository implements HostelRepository {
  SupabaseHostelRepository(this._supabase);

  final SupabaseClient? _supabase;

  @override
  Future<List<Hostel>> getHostels() async {
    final client = _supabase;
    if (client == null) {
      return const [];
    }

    try {
      final rpcData = await client.rpc<dynamic>('get_hostels');
      if (rpcData is List) {
        return rpcData
            .map(
              (row) => Hostel.fromJson(Map<String, dynamic>.from(row as Map)),
            )
            .toList();
      }

      final tableData = await client
          .from('hostels')
          .select('hostel_id, hostel_name, short_code, gender')
          .order('hostel_name', ascending: true);

      return tableData
          .map((row) => Hostel.fromJson(Map<String, dynamic>.from(row)))
          .toList();
    } catch (e) {
      AppLogger.error('Failed to fetch hostels from Supabase: $e');
      rethrow;
    }
  }
}

final hostelRepositoryProvider = Provider<HostelRepository>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return SupabaseHostelRepository(supabase);
});

final hostelsProvider = FutureProvider<List<Hostel>>((ref) {
  return ref.watch(hostelRepositoryProvider).getHostels();
});
