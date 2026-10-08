import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tracklet/design_system/components/tracklet_button.dart';

import '../helpers/pump_app.dart';

void main() {
  group('TrackletButton', () {
    testWidgets('renders label and handles tap', (tester) async {
      var tapped = false;

      await tester.pumpTrackletWidget(
        TrackletButton(label: 'Track Bus', onPressed: () => tapped = true),
      );

      expect(find.text('Track Bus'), findsOneWidget);
      await tester.tap(find.text('Track Bus'));
      await tester.pump();

      expect(tapped, isTrue);
    });

    testWidgets('shows loading spinner when isLoading is true', (tester) async {
      await tester.pumpTrackletWidget(
        const TrackletButton(label: 'Loading...', isLoading: true),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });
}
