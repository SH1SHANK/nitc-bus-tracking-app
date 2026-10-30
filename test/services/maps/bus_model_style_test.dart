import 'package:flutter_test/flutter_test.dart';
import 'package:tracklet/core/geo/geo_point.dart';
import 'package:tracklet/services/maps/bus_model_style.dart';

void main() {
  group('BusModelStyle', () {
    test(
      'limits runtime tinting to material_4 and preserves default colors',
      () {
        expect(BusModelStyle.bodyMaterialName, 'material_4');
        expect(
          BusModelStyle.bodyColorMixIntensityExpression,
          contains(BusModelStyle.bodyMaterialName),
        );
        expect(BusModelStyle.bodyColorMixIntensityExpression.last, 0.0);
      },
    );

    test('converts map heading to normalized clockwise z rotation', () {
      expect(BusModelStyle.rotation(370), [0, 0, 10]);
      expect(BusModelStyle.rotation(null), [0, 0, 0]);
    });

    test('computes local east and north telemetry offsets in metres', () {
      const anchor = GeoPoint(latitude: 11.32, longitude: 75.93);
      const point = GeoPoint(latitude: 11.321, longitude: 75.931);

      final translation = BusModelStyle.translation(anchor, point);

      expect(translation[0], closeTo(109.13, 0.1));
      expect(translation[1], closeTo(111.32, 0.1));
      expect(translation[2], 0);
    });
  });
}
