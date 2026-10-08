import 'package:flutter_test/flutter_test.dart';
import 'package:tracklet/core/formatting/transit_formatter.dart';

void main() {
  group('TransitFormatter', () {
    test('formats ETA properly', () {
      expect(TransitFormatter.formatEta(0), equals('Arriving now'));
      expect(TransitFormatter.formatEta(1), equals('1 min'));
      expect(TransitFormatter.formatEta(5), equals('5 mins'));
      expect(TransitFormatter.formatEta(60), equals('1h'));
      expect(TransitFormatter.formatEta(75), equals('1h 15m'));
    });

    test('formats walking times properly', () {
      expect(TransitFormatter.formatWalkingTime(1), equals('1 min walk'));
      expect(TransitFormatter.formatWalkingTime(4), equals('4 mins walk'));
    });

    test('formats distance in meters and km', () {
      expect(TransitFormatter.formatDistance(350), equals('350 m'));
      expect(TransitFormatter.formatDistance(1500), equals('1.5 km'));
    });
  });
}
