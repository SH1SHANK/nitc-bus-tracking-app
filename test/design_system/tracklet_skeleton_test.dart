import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tracklet/design_system/components/tracklet_skeleton.dart';

void main() {
  testWidgets('skeleton respects reduced motion and preserves its size', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: Center(child: TrackletSkeleton(width: 120, height: 24)),
        ),
      ),
    );

    expect(tester.getSize(find.byType(TrackletSkeleton)), const Size(120, 24));
    await tester.pump(const Duration(seconds: 2));
    expect(find.byType(TrackletSkeleton), findsOneWidget);
  });
}
