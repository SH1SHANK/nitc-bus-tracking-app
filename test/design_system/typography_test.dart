import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:tracklet/design_system/tokens/typography.dart';

void main() {
  group('TrackletTypography Tokens', () {
    test('primary font family is Outfit', () {
      expect(TrackletTypography.primaryFontFamily, 'Outfit');
      expect(TrackletTypography.displayLarge.fontFamily, 'Outfit');
      expect(TrackletTypography.headlineMedium.fontFamily, 'Outfit');
      expect(TrackletTypography.bodyMedium.fontFamily, 'Outfit');
    });

    test('secondary font family is Satoshi', () {
      expect(TrackletTypography.secondaryFontFamily, 'Satoshi');
      expect(TrackletTypography.bodyLarge.fontFamily, 'Satoshi');
      expect(TrackletTypography.caption.fontFamily, 'Satoshi');
    });

    test('numeric typography contains Tabular Figures font feature', () {
      expect(
        TrackletTypography.numericLarge.fontFeatures,
        contains(const FontFeature.tabularFigures()),
      );
      expect(
        TrackletTypography.numericMedium.fontFeatures,
        contains(const FontFeature.tabularFigures()),
      );
      expect(
        TrackletTypography.numericSmall.fontFeatures,
        contains(const FontFeature.tabularFigures()),
      );
    });

    test('withTabularFigures adds tabular figures to any TextStyle', () {
      const baseStyle = TrackletTypography.bodyLarge;
      final modified = TrackletTypography.withTabularFigures(baseStyle);

      expect(
        modified.fontFeatures,
        contains(const FontFeature.tabularFigures()),
      );
    });
  });
}
