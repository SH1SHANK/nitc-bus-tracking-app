import 'package:flutter_test/flutter_test.dart';
import 'package:tracklet/data/campus/hostel.dart';
import 'package:tracklet/data/campus/hostel_repository.dart';

void main() {
  group('Hostel Model Tests', () {
    test('Hostel serializes and deserializes correctly', () {
      const hostel = Hostel(
        id: 'MBH_1',
        name: 'Mega Hostel (MBH - Phase 1)',
        shortCode: 'MBH-1',
        gender: 'boys',
      );

      final json = hostel.toJson();
      expect(json['hostel_id'], 'MBH_1');
      expect(json['hostel_name'], 'Mega Hostel (MBH - Phase 1)');
      expect(json['short_code'], 'MBH-1');
      expect(json['gender'], 'boys');

      final fromJson = Hostel.fromJson(json);
      expect(fromJson.id, 'MBH_1');
      expect(fromJson.name, 'Mega Hostel (MBH - Phase 1)');
      expect(fromJson.shortCode, 'MBH-1');
      expect(fromJson.gender, 'boys');
      expect(fromJson, hostel);
      expect(fromJson.hashCode, hostel.hashCode);
      expect(hostel.toString(), contains('MBH_1'));
    });

    test('Hostel.fromJson handles alternate keys', () {
      final hostel = Hostel.fromJson({
        'id': 'LH_MAIN',
        'name': 'Ladies Hostel (LH - Main Block)',
      });
      expect(hostel.id, 'LH_MAIN');
      expect(hostel.name, 'Ladies Hostel (LH - Main Block)');
    });
  });

  group('SupabaseHostelRepository Tests', () {
    test(
      'returns empty list when Supabase client is null (no silent production fallback)',
      () async {
        final repo = SupabaseHostelRepository(null);
        final list = await repo.getHostels();

        expect(list, isEmpty);
      },
    );
  });
}
