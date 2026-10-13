import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/logging/app_logger.dart';
import '../supabase/supabase_client_provider.dart';
import 'department.dart';

/// Repository interface for institutional academic departments.
abstract class DepartmentRepository {
  Future<List<Department>> getDepartments();
}

/// Supabase implementation querying public.departments table / get_departments() RPC.
class SupabaseDepartmentRepository implements DepartmentRepository {
  SupabaseDepartmentRepository(this._supabase);

  final SupabaseClient? _supabase;

  @override
  Future<List<Department>> getDepartments() async {
    final client = _supabase;
    if (client == null) {
      return const [];
    }

    try {
      final rpcData = await client.rpc<dynamic>('get_departments');
      if (rpcData is List) {
        return rpcData
            .map(
              (row) =>
                  Department.fromJson(Map<String, dynamic>.from(row as Map)),
            )
            .toList();
      }

      final tableData = await client
          .from('departments')
          .select('department_id, department_name')
          .order('department_name', ascending: true);

      return tableData
          .map((row) => Department.fromJson(Map<String, dynamic>.from(row)))
          .toList();
    } catch (e) {
      AppLogger.error('Failed to fetch departments from Supabase: $e');
      rethrow;
    }
  }
}

final departmentRepositoryProvider = Provider<DepartmentRepository>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return SupabaseDepartmentRepository(supabase);
});

final departmentsProvider = FutureProvider<List<Department>>((ref) {
  return ref.watch(departmentRepositoryProvider).getDepartments();
});
