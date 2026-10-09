import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tracklet/design_system/components/bottom_sheets/why_do_we_need_your_info_bottom_sheet.dart';

import '../helpers/pump_app.dart';

void main() {
  testWidgets(
    'explains profile use and keeps its action available on small screens',
    (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpTrackletWidget(
        Scaffold(
          body: Builder(
            builder:
                (context) => Center(
                  child: ElevatedButton(
                    onPressed:
                        () => WhyDoWeNeedYourInfoBottomSheet.show(context),
                    child: const Text('Open info'),
                  ),
                ),
          ),
        ),
      );
      await tester.tap(find.text('Open info'));
      await tester.pumpAndSettle();

      expect(find.text('Why we need your info'), findsOneWidget);
      expect(find.text('Plan your walk'), findsOneWidget);
      expect(
        find.text('Sync class lecture times with transit departures.'),
        findsNothing,
      );
      expect(tester.takeException(), isNull);

      await tester.ensureVisible(find.text('Got it'));
      expect(find.text('Got it'), findsOneWidget);
      await tester.tap(find.text('Got it'));
      await tester.pumpAndSettle();
      expect(find.text('Why we need your info'), findsNothing);
    },
  );
}
