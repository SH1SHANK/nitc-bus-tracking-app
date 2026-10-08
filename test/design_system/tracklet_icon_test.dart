import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tracklet/design_system/components/icons/tracklet_icon.dart';
import 'package:tracklet/design_system/components/icons/tracklet_icons.dart';

void main() {
  group('TrackletIcons & TrackletIcon Widget', () {
    test('TrackletIcons constants are non-null and valid IconData', () {
      expect(TrackletIcons.home, isNotNull);
      expect(TrackletIcons.map, isNotNull);
      expect(TrackletIcons.profile, isNotNull);
      expect(TrackletIcons.bus, isNotNull);
      expect(TrackletIcons.busStop, isNotNull);
      expect(TrackletIcons.location, isNotNull);
      expect(TrackletIcons.navigation, isNotNull);
      expect(TrackletIcons.settings, isNotNull);
      expect(TrackletIcons.notifications, isNotNull);
      expect(TrackletIcons.chevronLeft, isNotNull);
      expect(TrackletIcons.chevronRight, isNotNull);
      expect(TrackletIcons.close, isNotNull);
      expect(TrackletIcons.search, isNotNull);
      expect(TrackletIcons.info, isNotNull);
      expect(TrackletIcons.warning, isNotNull);
      expect(TrackletIcons.seat, isNotNull);
      expect(TrackletIcons.speed, isNotNull);
      expect(TrackletIcons.time, isNotNull);
    });

    testWidgets(
      'TrackletIcon renders with expected size, color, and semantic label',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: TrackletIcon(
                TrackletIcons.bus,
                size: 28.0,
                color: Colors.blue,
                semanticLabel: 'Campus Bus',
              ),
            ),
          ),
        );

        final iconFinder = find.byType(Icon);
        expect(iconFinder, findsOneWidget);

        final iconWidget = tester.widget<Icon>(iconFinder);
        expect(iconWidget.icon, TrackletIcons.bus);
        expect(iconWidget.size, 28.0);
        expect(iconWidget.color, Colors.blue);
        expect(iconWidget.semanticLabel, 'Campus Bus');
      },
    );
  });
}
