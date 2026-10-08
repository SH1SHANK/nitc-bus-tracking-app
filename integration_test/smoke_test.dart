import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:tracklet/app/app.dart';
import 'package:tracklet/features/home/home_screen.dart';
import 'package:tracklet/features/map/map_screen.dart';
import 'package:tracklet/features/profile/profile_screen.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Tracklet End-to-End Smoke Test', () {
    testWidgets(
      'verify full launch, shell destinations and transit interaction',
      (tester) async {
        await tester.pumpWidget(const ProviderScope(child: TrackletApp()));

        await tester.pumpAndSettle();

        // Launch -> Verify Home
        expect(find.byType(HomeScreen), findsOneWidget);
        expect(find.textContaining('Shashank'), findsOneWidget);

        // Navigate -> Map
        final mapTab = find.text('Map');
        expect(mapTab, findsOneWidget);
        await tester.tap(mapTab);
        await tester.pumpAndSettle();
        expect(find.byType(MapScreen), findsOneWidget);

        // Navigate -> Profile
        final profileTab = find.text('Profile');
        expect(profileTab, findsOneWidget);
        await tester.tap(profileTab);
        await tester.pumpAndSettle();
        expect(find.byType(ProfileScreen), findsOneWidget);

        // Return -> Home
        final homeTab = find.text('Home');
        expect(homeTab, findsOneWidget);
        await tester.tap(homeTab);
        await tester.pumpAndSettle();
        expect(find.byType(HomeScreen), findsOneWidget);
      },
    );
  });
}
