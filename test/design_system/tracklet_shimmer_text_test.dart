import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tracklet/design_system/components/tracklet_shimmer_text.dart';
import 'package:tracklet/design_system/components/tracklet_skeleton.dart';

void main() {
  group('TrackletShimmerText tests', () {
    testWidgets('renders shimmer text content', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TrackletShimmerText(text: 'Loading campus routes...'),
          ),
        ),
      );

      expect(find.text('Loading campus routes...'), findsOneWidget);
      expect(find.byType(ShaderMask), findsOneWidget);
    });

    testWidgets('disables shimmer animation when reduced motion is requested', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: MaterialApp(
            home: Scaffold(
              body: TrackletShimmerText(text: 'Reduced motion active'),
            ),
          ),
        ),
      );

      expect(find.text('Reduced motion active'), findsOneWidget);
      // When reduced motion is requested, ShaderMask shimmer is bypassed
      expect(find.byType(ShaderMask), findsNothing);
    });

    testWidgets('TrackletMapSkeleton renders TrackletShimmerText placeholder', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: TrackletMapSkeleton())),
      );

      expect(find.text('Loading transit map...'), findsOneWidget);
      expect(find.byType(TrackletShimmerText), findsOneWidget);
    });
  });
}
