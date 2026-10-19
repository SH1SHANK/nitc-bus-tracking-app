import 'package:flutter_test/flutter_test.dart';
import 'package:tracklet/features/profile/profile_screen.dart';
import 'package:tracklet/features/settings/settings_screen.dart';

import '../../helpers/pump_app.dart';

void main() {
  group('ProfileScreen', () {
    testWidgets(
      'renders full App Settings experience with student profile and sections',
      (tester) async {
        await tester.pumpTrackletWidget(const ProfileScreen());
        await tester.pumpAndSettle();

        expect(find.text('App Settings'), findsOneWidget);
        expect(find.byType(SettingsScreen), findsOneWidget);
        expect(find.text('Student Profile'), findsOneWidget);
        expect(find.text('Account & Security'), findsOneWidget);
        expect(find.text('Location & Permissions'), findsOneWidget);
        expect(find.text('Appearance & Display'), findsOneWidget);
        expect(find.text('Support & Feedback'), findsOneWidget);
        expect(find.text('About BusTracker & Legal'), findsOneWidget);
        expect(find.text('Account Actions'), findsOneWidget);
        expect(find.text('Notifications'), findsNothing);
      },
    );

    testWidgets(
      'renders Back to Home leading button in AppBar',
      (tester) async {
        await tester.pumpTrackletWidget(const ProfileScreen());
        await tester.pumpAndSettle();

        final backBtn = find.byTooltip('Back to Home');
        expect(backBtn, findsOneWidget);
      },
    );
  });
}
