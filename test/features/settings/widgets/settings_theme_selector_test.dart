import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tracklet/features/settings/widgets/settings_theme_selector.dart';

void main() {
  group('SettingsThemeSelector widget tests', () {
    testWidgets('renders all three theme options (System, Light, Dark)', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SettingsThemeSelector(
              selectedMode: 'Light',
              onChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('System'), findsOneWidget);
      expect(find.text('Light'), findsOneWidget);
      expect(find.text('Dark'), findsOneWidget);
      expect(find.byIcon(Icons.brightness_auto_rounded), findsOneWidget);
      expect(find.byIcon(Icons.light_mode_rounded), findsOneWidget);
      expect(find.byIcon(Icons.dark_mode_rounded), findsOneWidget);
    });

    testWidgets(
      'indicates selected state and triggers onChanged on selection',
      (tester) async {
        String? updatedMode;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: StatefulBuilder(
                builder: (context, setState) {
                  return SettingsThemeSelector(
                    selectedMode: updatedMode ?? 'Light',
                    onChanged: (val) {
                      setState(() => updatedMode = val);
                    },
                  );
                },
              ),
            ),
          ),
        );

        // Tap 'Dark'
        await tester.tap(find.text('Dark'));
        await tester.pumpAndSettle();

        expect(updatedMode, 'Dark');

        // Tapping 'Dark' again should not fire onChanged
        var secondCallFired = false;
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SettingsThemeSelector(
                selectedMode: 'Dark',
                onChanged: (_) {
                  secondCallFired = true;
                },
              ),
            ),
          ),
        );

        await tester.tap(find.text('Dark'));
        await tester.pumpAndSettle();
        expect(secondCallFired, isFalse);
      },
    );

    testWidgets('has accessible semantic buttons with selected states', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SettingsThemeSelector(
              selectedMode: 'Dark',
              onChanged: (_) {},
            ),
          ),
        ),
      );

      final darkFinder = find.byWidgetPredicate(
        (w) => w is Semantics && w.properties.label == 'Dark theme mode',
      );
      final lightFinder = find.byWidgetPredicate(
        (w) => w is Semantics && w.properties.label == 'Light theme mode',
      );

      final darkSemantics = tester.widget<Semantics>(darkFinder);
      expect(darkSemantics.properties.selected, isTrue);

      final lightSemantics = tester.widget<Semantics>(lightFinder);
      expect(lightSemantics.properties.selected, isFalse);
    });
  });
}
