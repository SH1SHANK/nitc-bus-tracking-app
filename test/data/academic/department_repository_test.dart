import 'package:flutter_test/flutter_test.dart';
import 'package:tracklet/data/academic/department.dart';
import 'package:tracklet/data/academic/department_repository.dart';

void main() {
  group('Department Model Tests', () {
    test('Department serializes and deserializes correctly', () {
      const dept = Department(id: 'CS', name: 'Computer Science & Engineering');

      final json = dept.toJson();
      expect(json['department_id'], 'CS');
      expect(json['department_name'], 'Computer Science & Engineering');

      final fromJson = Department.fromJson(json);
      expect(fromJson.id, 'CS');
      expect(fromJson.name, 'Computer Science & Engineering');
      expect(fromJson, dept);
      expect(fromJson.hashCode, dept.hashCode);
      expect(dept.toString(), contains('CS'));
    });

    test('Department.fromJson handles alternate keys', () {
      final dept = Department.fromJson({
        'id': 'EC',
        'name': 'Electronics & Communication Engineering',
      });
      expect(dept.id, 'EC');
      expect(dept.name, 'Electronics & Communication Engineering');
    });
  });

  group('SupabaseDepartmentRepository Tests', () {
    test(
      'returns empty list when Supabase client is null (no silent production fallback)',
      () async {
        final repo = SupabaseDepartmentRepository(null);
        final list = await repo.getDepartments();

        expect(list, isEmpty);
      },
    );
  });
}
