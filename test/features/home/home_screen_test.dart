import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tracklet/features/home/home_screen.dart';
import 'package:tracklet/features/home/widgets/at_a_glance_transit_card.dart';
import 'package:tracklet/features/home/widgets/next_buses_card.dart';

import '../../helpers/pump_app.dart';

void main() {
  group('HomeScreen', () {
    testWidgets(
      'renders greeting, AtAGlance hero card, and Next buses list when loaded',
      (tester) async {
        await tester.pumpTrackletWidget(const HomeScreen());
        // Let FutureProvider complete
        await tester.pumpAndSettle();

        expect(find.textContaining('Shashank'), findsOneWidget);
        expect(find.text('Catch your next ride.'), findsOneWidget);
        expect(find.byType(AtAGlanceTransitCard), findsOneWidget);
        expect(find.byType(NextBusesCard), findsOneWidget);
        expect(find.text('Next buses'), findsOneWidget);
        expect(find.text('From Main Gate'), findsOneWidget);
        expect(find.text('ROUTE TRACKER'), findsOneWidget);
      },
    );

    testWidgets('opens drawer on tapping hamburger icon', (tester) async {
      await tester.pumpTrackletWidget(const HomeScreen());
      await tester.pumpAndSettle();

      final menuIcon = find.byIcon(Icons.menu_rounded);
      expect(menuIcon, findsOneWidget);

      await tester.tap(menuIcon);
      await tester.pumpAndSettle();

      expect(find.text('Account Options'), findsOneWidget);
      expect(find.text('Sync Timetable'), findsOneWidget);
      expect(find.text('Log Out'), findsOneWidget);
    });
  });
}
