import 'package:flutter_test/flutter_test.dart';
import 'package:tracklet/features/profile/profile_screen.dart';
import 'package:tracklet/features/profile/widgets/app_info_card.dart';
import 'package:tracklet/features/profile/widgets/notification_preferences_tile.dart';
import 'package:tracklet/features/profile/widgets/profile_header.dart';

import '../../helpers/pump_app.dart';

void main() {
  group('ProfileScreen', () {
    testWidgets('renders profile header, notification settings, and app info', (
      tester,
    ) async {
      await tester.pumpTrackletWidget(const ProfileScreen());
      await tester.pumpAndSettle();

      expect(find.text('Profile & Settings'), findsOneWidget);
      expect(find.byType(ProfileHeader), findsOneWidget);
      expect(find.byType(NotificationPreferencesTile), findsOneWidget);
      expect(find.byType(AppInfoCard), findsOneWidget);
    });
  });
}
