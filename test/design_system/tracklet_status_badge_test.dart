import 'package:flutter_test/flutter_test.dart';
import 'package:tracklet/design_system/components/tracklet_status_badge.dart';

import '../helpers/pump_app.dart';

void main() {
  group('TrackletStatusBadge', () {
    testWidgets('renders status label correctly', (tester) async {
      await tester.pumpTrackletWidget(
        const TrackletStatusBadge(
          label: 'Live',
          status: TrackletBadgeStatus.live,
        ),
      );

      expect(find.text('Live'), findsOneWidget);
    });
  });
}
