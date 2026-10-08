import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tracklet/design_system/components/tracklet_card.dart';

import '../helpers/pump_app.dart';

void main() {
  group('TrackletCard', () {
    testWidgets('renders child content correctly', (tester) async {
      await tester.pumpTrackletWidget(
        const TrackletCard(child: Text('Card Content')),
      );

      expect(find.text('Card Content'), findsOneWidget);
    });

    testWidgets('handles onTap callback when provided', (tester) async {
      var tapped = false;
      await tester.pumpTrackletWidget(
        TrackletCard(onTap: () => tapped = true, child: const Text('Tap Me')),
      );

      await tester.tap(find.text('Tap Me'));
      await tester.pump();

      expect(tapped, isTrue);
    });
  });
}
