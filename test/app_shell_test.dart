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
      await tester.tap(find.text('MAP'));
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

    testWidgets('exposes accessible semantics for navigation items', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      try {
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

        // Check Home item has selected semantics
        expect(
          tester
              .getSemantics(find.text('Home'))
              .flagsCollection
              .toStrings()
              .contains('isSelected'),
          isTrue,
        );

        // Tap Profile and check updated semantics
        await tester.tap(find.text('Profile'));
        await tester.pumpAndSettle();

        expect(
          tester
              .getSemantics(find.text('Profile'))
              .flagsCollection
              .toStrings()
              .contains('isSelected'),
          isTrue,
        );
      } finally {
        handle.dispose();
      }
    });

    testWidgets('MAP button responds to press gestures with scale animation', (
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

      final mapFinder = find.text('MAP');
      final gesture = await tester.startGesture(tester.getCenter(mapFinder));
      await tester.pump(const Duration(milliseconds: 50));

      // Button is in pressed state
      await gesture.up();
      await tester.pumpAndSettle();

      expect(find.byType(MapScreen), findsOneWidget);
    });

    testWidgets(
      'tapping Back to Home button on Profile screen navigates back to Home',
      (tester) async {
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
        expect(find.byType(HomeScreen), findsOneWidget);

        // Navigate to Profile
        await tester.tap(find.text('Profile'));
        await tester.pumpAndSettle();
        expect(find.byType(ProfileScreen), findsOneWidget);

        // Find leading back button and tap it
        final backButton = find.byTooltip('Back to Home');
        expect(backButton, findsOneWidget);
        await tester.tap(backButton);
        await tester.pumpAndSettle();

        // Successfully returned to Home
        expect(find.byType(HomeScreen), findsOneWidget);
      },
    );

    testWidgets('pressing system back from Profile screen returns to Home', (
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
      expect(find.byType(HomeScreen), findsOneWidget);

      // Navigate to Profile
      await tester.tap(find.text('Profile'));
      await tester.pumpAndSettle();
      expect(find.byType(ProfileScreen), findsOneWidget);

      // Simulate system back button / gesture
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      // Returned to Home instead of exiting
      expect(find.byType(HomeScreen), findsOneWidget);
    });
  });
}
