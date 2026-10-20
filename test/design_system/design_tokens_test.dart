import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tracklet/design_system/components/tracklet_button.dart';
import 'package:tracklet/design_system/components/tracklet_card.dart';
import 'package:tracklet/design_system/theme/tracklet_theme.dart';
import 'package:tracklet/design_system/tokens/colors.dart';
import 'package:tracklet/design_system/tokens/radii.dart';
import 'package:tracklet/design_system/tokens/spacing.dart';
import 'package:tracklet/design_system/tokens/typography.dart';

void main() {
  group('design tokens', () {
    test('semantic colors share their palette value', () {
      expect(TrackletColors.primary, TrackletPalette.argbFF6F61EF);
      expect(TrackletColors.primaryBackground, TrackletColors.background);
      expect(TrackletColors.busLive, TrackletColors.success);
      expect(TrackletColors.routeActive, TrackletColors.primary);
      expect(TrackletColors.stopActive, TrackletColors.primary);
    });

    test('light and dark themes expose the expected semantic roles', () {
      final light = TrackletTheme.lightTheme;
      final dark = TrackletTheme.darkTheme;

      expect(light.brightness, Brightness.light);
      expect(dark.brightness, Brightness.dark);
      expect(light.colorScheme.primary, TrackletColors.primary);
      expect(dark.colorScheme.primary, TrackletColors.primary);
      expect(light.colorScheme.primaryFixed, TrackletColors.primaryFixed);
      expect(dark.colorScheme.primaryFixed, TrackletColors.primaryFixed);
      expect(light.colorScheme.secondaryFixed, TrackletColors.secondaryFixed);
      expect(dark.colorScheme.secondaryFixed, TrackletColors.secondaryFixed);
      expect(light.colorScheme.tertiaryFixed, TrackletColors.tertiaryFixed);
      expect(dark.colorScheme.tertiaryFixed, TrackletColors.tertiaryFixed);
      expect(light.colorScheme.surfaceTint, TrackletColors.surfaceTint);
      expect(dark.colorScheme.surfaceTint, TrackletColors.darkSurfaceTint);
      expect(light.colorScheme.inversePrimary, TrackletColors.inversePrimary);
      expect(
        dark.colorScheme.inversePrimary,
        TrackletColors.darkInversePrimary,
      );
      expect(light.colorScheme.surfaceDim, TrackletColors.surfaceDim);
      expect(dark.colorScheme.surfaceDim, TrackletColors.darkSurfaceDim);
      expect(light.colorScheme.surfaceBright, TrackletColors.surfaceBright);
      expect(dark.colorScheme.surfaceBright, TrackletColors.darkSurfaceBright);
      expect(light.colorScheme.shadow, TrackletColors.shadow);
      expect(dark.colorScheme.shadow, TrackletColors.shadow);
      expect(light.colorScheme.scrim, TrackletColors.scrim);
      expect(dark.colorScheme.scrim, TrackletColors.scrim);
      expect(light.scaffoldBackgroundColor, TrackletColors.background);
      expect(dark.scaffoldBackgroundColor, TrackletColors.darkBackground);
      expect(TrackletSpacing.minTouchTarget, 48);
      expect(TrackletSpacing.mapViewportInset, 48);
      expect(TrackletSpacing.appBarHeight, 56);
      expect(TrackletSpacing.appBarSubtitleHeight, 68);
      expect(TrackletRadii.roundedCard, BorderRadius.circular(12));
      expect(TrackletTypography.fontSize17, 17);
    });

    test('Material DSP manifest and aliases are consistent', () {
      final manifest =
          jsonDecode(File('design_tokens/dsp.json').readAsStringSync())
              as Map<String, Object?>;
      final imports = manifest['import']! as List<Object?>;
      final dataPath =
          (imports.single! as Map<String, Object?>)['src']! as String;
      final data =
          jsonDecode(File('design_tokens/$dataPath').readAsStringSync())
              as Map<String, Object?>;
      final entities =
          (data['entities']! as List<Object?>).cast<Map<String, Object?>>();
      final ids = entities.map((entity) => entity['id']! as String).toSet();
      final byId = {
        for (final entity in entities) entity['id']! as String: entity,
      };
      final semanticColors = entities.where(
        (entity) => (entity['id']! as String).startsWith('color-'),
      );

      expect(manifest['dsp_spec_version'], '1.0');
      expect(ids.length, entities.length);
      for (final entity in entities) {
        final id = entity['id']! as String;
        expect(id, matches(RegExp(r'^[a-z0-9]+(?:-[a-z0-9]+)*$')));
        if (entity['type'] == 'alias') {
          final value = entity['value']! as String;
          final alias = RegExp(r'^\{([^}]+)\}$').firstMatch(value);
          expect(alias, isNotNull);
          expect(ids, contains(alias!.group(1)));
        }
      }
      expect(ids, containsAll(['color-primary', 'color-dark-background']));
      expect(byId['color-primary']!['value'], '{palette-ff6f61ef}');
      expect(byId['palette-ff6f61ef']!['value'], '#6F61EFFF');
      expect(byId['space-min-touch-target']!['value'], '{space-xxxl}');
      expect(byId['space-xxxl']!['value'], '48dp');
      expect(byId['radius-rounded-card']!['value'], '{radius-card}');
      expect(byId['type-size-14']!['value'], '14sp');
      expect(
        byId['color-primary-fixed']!['value'],
        '{color-primary-container}',
      );
      expect(byId['color-surface-dim']!['value'], '{palette-fff1f4f8}');
      expect(byId['color-dark-surface-dim']!['value'], '{palette-ff0f1117}');
      expect(byId['type-letter-spacing-label']!['value'], '0.5px');
      expect(byId['type-weight-semi-bold']!['value'], '600');
      expect(byId['type-line-height-body']!['value'], '1.4');
      expect(byId['type-line-height-loading']!['value'], '1.12');
      expect(byId['space-avatar-ring-inset']!['value'], '3dp');
      expect(byId['radius-compact-md']!['value'], '10dp');
      expect(
        semanticColors.every((entity) {
          final tags = (entity['tags']! as List<Object?>).cast<String>();
          return tags.any(
            (tag) =>
                tag == 'theme:light' ||
                tag == 'theme:dark' ||
                tag == 'theme:all',
          );
        }),
        isTrue,
      );
    });

    testWidgets('shared card and button consume the themed system', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: TrackletTheme.lightTheme,
          home: Scaffold(
            body: TrackletCard(
              child: TrackletButton(label: 'View route', onPressed: () {}),
            ),
          ),
        ),
      );

      expect(find.byType(TrackletCard), findsOneWidget);
      expect(find.text('View route'), findsOneWidget);
    });
  });
}
