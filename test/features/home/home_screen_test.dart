import 'package:flutter_test/flutter_test.dart';
import 'package:tracklet/features/home/home_screen.dart';
import 'package:tracklet/features/home/widgets/next_bus_card.dart';

import '../../helpers/pump_app.dart';

void main() {
  group('HomeScreen', () {
    testWidgets('renders greeting and next bus card when loaded', (
      tester,
    ) async {
      await tester.pumpTrackletWidget(const HomeScreen());
      // Let FutureProvider complete
      await tester.pumpAndSettle();

      expect(find.textContaining('Shashank'), findsOneWidget);
      expect(find.text('Catch your next ride.'), findsOneWidget);
      expect(find.byType(NextBusCard), findsOneWidget);
    });
  });
}
