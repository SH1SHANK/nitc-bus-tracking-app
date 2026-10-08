import 'package:flutter_test/flutter_test.dart';
import 'package:tracklet/features/map/map_screen.dart';
import 'package:tracklet/features/map/widgets/map_controls.dart';
import 'package:tracklet/services/maps/map_adapter.dart';

import '../../helpers/pump_app.dart';

void main() {
  group('MapScreen', () {
    testWidgets('renders map view and floating controls', (tester) async {
      await tester.pumpTrackletWidget(const MapScreen());
      await tester.pumpAndSettle();

      expect(find.byType(TrackletMapView), findsOneWidget);
      expect(find.byType(MapControls), findsOneWidget);
      expect(find.text('Live NITC Network'), findsOneWidget);
    });
  });
}
