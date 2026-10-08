import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tracklet/app/app.dart';
import 'package:tracklet/app/router.dart';
import 'package:tracklet/data/transit/bus.dart';
import 'package:tracklet/features/home/home_screen.dart';
import 'package:tracklet/features/home/providers/home_provider.dart';
import 'package:tracklet/features/map/map_screen.dart';
import 'package:tracklet/features/profile/profile_screen.dart';

void main() {
  group('AppShell Navigation', () {
    testWidgets('navigates seamlessly between Home, Map, and Profile', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            routerProvider.overrideWithValue(
              createRouter(initialLocation: '/'),
            ),
            activeBusesStreamProvider.overrideWith(
              (ref) => Stream.value(<Bus>[]),
            ),
          ],
          child: const TrackletApp(),
        ),
      );

      await tester.pumpAndSettle();

      // 1. Initial destination is Home
      expect(find.byType(HomeScreen), findsOneWidget);

      // 2. Tap Map
      await tester.tap(find.text('Map'));
      await tester.pumpAndSettle();
      expect(find.byType(MapScreen), findsOneWidget);

      // 3. Tap Profile
      await tester.tap(find.text('Profile'));
      await tester.pumpAndSettle();
      expect(find.byType(ProfileScreen), findsOneWidget);

      // 4. Tap Home
      await tester.tap(find.text('Home'));
      await tester.pumpAndSettle();
      expect(find.byType(HomeScreen), findsOneWidget);
    });
  });
}
