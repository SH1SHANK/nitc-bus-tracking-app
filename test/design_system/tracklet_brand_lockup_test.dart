import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tracklet/design_system/components/tracklet_brand_lockup.dart';

import '../helpers/pump_app.dart';

void main() {
  group('TrackletBrandLockup Tests', () {
    testWidgets('renders both bus icon and wordmark by default', (tester) async {
      await tester.pumpTrackletWidget(
        const TrackletBrandLockup(),
      );

      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Image &&
              widget.image is AssetImage &&
              (widget.image as AssetImage).assetName ==
                  'assets/branding/bustracker_bus_icon.png',
        ),
        findsOneWidget,
      );
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Image &&
              widget.image is AssetImage &&
              (widget.image as AssetImage).assetName ==
                  'assets/branding/bustracker_wordmark.png',
        ),
        findsOneWidget,
      );
    });

    testWidgets('TrackletBrandLockup.logoOnly renders only bus icon', (
      tester,
    ) async {
      await tester.pumpTrackletWidget(
        const TrackletBrandLockup.logoOnly(),
      );

      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Image &&
              widget.image is AssetImage &&
              (widget.image as AssetImage).assetName ==
                  'assets/branding/bustracker_bus_icon.png',
        ),
        findsOneWidget,
      );
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Image &&
              widget.image is AssetImage &&
              (widget.image as AssetImage).assetName ==
                  'assets/branding/bustracker_wordmark.png',
        ),
        findsNothing,
      );
    });

    testWidgets('TrackletBrandLockup.wordmarkOnly renders only wordmark', (
      tester,
    ) async {
      await tester.pumpTrackletWidget(
        const TrackletBrandLockup.wordmarkOnly(),
      );

      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Image &&
              widget.image is AssetImage &&
              (widget.image as AssetImage).assetName ==
                  'assets/branding/bustracker_bus_icon.png',
        ),
        findsNothing,
      );
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Image &&
              widget.image is AssetImage &&
              (widget.image as AssetImage).assetName ==
                  'assets/branding/bustracker_wordmark.png',
        ),
        findsOneWidget,
      );
    });

    testWidgets('renders container background when withContainer is true', (
      tester,
    ) async {
      await tester.pumpTrackletWidget(
        const TrackletBrandLockup(withContainer: true),
      );

      expect(find.byType(Container), findsWidgets);
    });
  });
}
