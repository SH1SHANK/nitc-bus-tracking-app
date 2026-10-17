import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/logging/app_logger.dart';
import '../supabase/supabase_client_provider.dart';
import '../transit/transit_cache_metrics.dart';
import 'department.dart';

/// Repository interface for institutional academic departments.
abstract class DepartmentRepository {
  Future<List<Department>> getDepartments();
}

/// Supabase implementation querying public.departments table / get_departments() RPC.
class SupabaseDepartmentRepository implements DepartmentRepository {
  SupabaseDepartmentRepository(this._supabase, {DateTime Function()? clock})
      : _clock = clock ?? DateTime.now;

  final SupabaseClient? _supabase;
  final DateTime Function() _clock;

  static const Duration _cacheTtl = Duration(minutes: 30);
  ({List<Department> departments, DateTime expiresAt})? _cache;
  Future<List<Department>>? _inFlight;

  @override
  Future<List<Department>> getDepartments() async {
    final client = _supabase;
    if (client == null) {
      return const [];
    }

    final now = _clock();
    if (_cache != null && _cache!.expiresAt.isAfter(now)) {
      TransitCacheMetrics.instance.recordHit('departments');
      return _cache!.departments;
    }

    final inFlight = _inFlight;
    if (inFlight != null) {
      TransitCacheMetrics.instance.recordDeduplicated('departments');
      return inFlight;
    }

    final future = _fetchDepartments(client);
    _inFlight = future;
    return future.whenComplete(() {
      if (identical(_inFlight, future)) {
        _inFlight = null;
      }
    });
  }

  Future<List<Department>> _fetchDepartments(SupabaseClient client) async {
    TransitCacheMetrics.instance.recordMiss('departments');
    final now = _clock();
    try {
      final rpcData = await client.rpc<dynamic>('get_departments');
      List<Department> departments;
      if (rpcData is List) {
        departments = rpcData
            .map(
              (row) =>
                  Department.fromJson(Map<String, dynamic>.from(row as Map)),
            )
            .toList();
      } else {
        final tableData = await client
            .from('departments')
            .select('department_id, department_name')
            .order('department_name', ascending: true);

        departments = tableData
            .map((row) => Department.fromJson(Map<String, dynamic>.from(row)))
            .toList();
      }

      _cache = (
        departments: List.unmodifiable(departments),
        expiresAt: now.add(_cacheTtl),
      );
      return departments;
    } catch (e) {
      AppLogger.error('Failed to fetch departments from Supabase: $e');
      rethrow;
    }
  }

  void invalidateCache() {
    _cache = null;
    _inFlight = null;
  }
}

final departmentRepositoryProvider = Provider<DepartmentRepository>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return SupabaseDepartmentRepository(supabase);
});

final departmentsProvider = FutureProvider<List<Department>>((ref) {
  return ref.watch(departmentRepositoryProvider).getDepartments();
});
