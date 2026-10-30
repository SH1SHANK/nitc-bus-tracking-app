import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tracklet/features/settings/dialogs/change_display_name_dialog.dart';
import 'package:tracklet/features/settings/dialogs/change_password_dialog.dart';
import 'package:tracklet/features/settings/dialogs/change_username_dialog.dart';
import 'package:tracklet/features/settings/dialogs/delete_account_dialog.dart';
import 'package:tracklet/data/profile/profile.dart';
import 'package:tracklet/data/profile/profile_repository.dart';
import 'package:tracklet/features/settings/dialogs/transit_faq_dialog.dart';
import 'package:tracklet/features/settings/settings_screen.dart';
import 'package:tracklet/design_system/components/icons/tracklet_icons.dart';
import 'package:tracklet/services/location/location_service.dart';

import '../../helpers/pump_app.dart';

class _TestProfileRepo implements ProfileRepository {
  Profile profile = const Profile(
    id: 'test-user-1',
    name: 'Shashank Mergu',
    username: 'shashank',
    email: 'shashank@nitc.ac.in',
    role: 'Student',
    notificationsEnabled: true,
    locationPermissionGranted: false,
    hasCompletedOnboarding: true,
  );

  @override
  Future<Profile> getProfile() async => profile;

  @override
  Future<void> saveProfile(Profile p) async {
    profile = p;
  }

  @override
  Future<void> setOnboardingCompleted(bool completed) async {
    profile = profile.copyWith(hasCompletedOnboarding: completed);
  }

  @override
  Future<bool> isUsernameAvailable(String username) async => true;

  @override
  Future<Profile> changeUsername(String newUsername) async {
    profile = profile.copyWith(username: newUsername);
    return profile;
  }
}

void main() {
  group('SettingsScreen Widget Tests', () {
    testWidgets(
      'renders all core settings sections with user profile data',
      (tester) async {
        final mockRepo = _TestProfileRepo();
        await tester.pumpTrackletWidget(
          const SettingsScreen(),
          overrides: [profileRepositoryProvider.overrideWithValue(mockRepo)],
        );
        await tester.pumpAndSettle();

        expect(find.text('App Settings'), findsOneWidget);
        expect(find.text('Student Profile'), findsOneWidget);
        expect(find.text('@shashank'), findsWidgets);
        expect(find.text('shashank@nitc.ac.in'), findsOneWidget);

        expect(find.text('Account & Security'), findsOneWidget);
        expect(find.text('Location & Permissions'), findsOneWidget);
        expect(find.text('Appearance & Display'), findsOneWidget);
        expect(find.text('Commute Preferences'), findsNothing);
        expect(find.text('Notifications'), findsOneWidget);
        expect(find.text('Push notifications'), findsOneWidget);
      },
    );

    testWidgets('opens Change Display Name dialog on tap', (tester) async {
      await tester.pumpTrackletWidget(const SettingsScreen());
      await tester.pumpAndSettle();

      final editNameItem = find.text('Edit Display Name');
      await tester.scrollUntilVisible(editNameItem, 200);
      await tester.tap(editNameItem);
      await tester.pumpAndSettle();

      expect(find.byType(ChangeDisplayNameDialog), findsOneWidget);
      expect(find.text('Change Display Name'), findsOneWidget);

      // Cancel dialog
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.byType(ChangeDisplayNameDialog), findsNothing);
    });

    testWidgets('opens Change Password dialog on tap', (tester) async {
      await tester.pumpTrackletWidget(const SettingsScreen());
      await tester.pumpAndSettle();

      final changePwItem = find.text('Change Password');
      await tester.scrollUntilVisible(changePwItem, 200);
      await tester.tap(changePwItem);
      await tester.pumpAndSettle();

      expect(find.byType(ChangePasswordDialog), findsOneWidget);
      expect(find.text('Old Password'), findsOneWidget);
      expect(find.text('New Password'), findsOneWidget);

      // Cancel dialog via close icon
      await tester.tap(find.byIcon(TrackletIcons.close));
      await tester.pumpAndSettle();

      expect(find.byType(ChangePasswordDialog), findsNothing);
    });

    testWidgets('opens Change Username dialog on tap', (tester) async {
      final mockRepo = _TestProfileRepo();
      await tester.pumpTrackletWidget(
        const SettingsScreen(),
        overrides: [profileRepositoryProvider.overrideWithValue(mockRepo)],
      );
      await tester.pumpAndSettle();

      final changeUsernameItem = find.text('Change Username');
      await tester.scrollUntilVisible(changeUsernameItem, 200);
      await tester.tap(changeUsernameItem);
      await tester.pumpAndSettle();

      expect(find.byType(ChangeUsernameDialog), findsOneWidget);
      expect(find.text('Change Username'), findsWidgets);

      // Cancel dialog via close icon
      await tester.tap(find.byIcon(TrackletIcons.close));
      await tester.pumpAndSettle();

      expect(find.byType(ChangeUsernameDialog), findsNothing);
    });

    testWidgets('does not display removed customization options', (
      tester,
    ) async {
      await tester.pumpTrackletWidget(const SettingsScreen());
      await tester.pumpAndSettle();

      expect(find.text('Favorite Bus Stop'), findsNothing);
      expect(find.text('Favorite Route'), findsNothing);
      expect(find.text('Transit Time Format'), findsNothing);
      expect(find.text('3D Campus Buildings'), findsNothing);
      expect(find.text('Sync Transit Schedules'), findsNothing);
      expect(find.text('Clear Cache'), findsNothing);
      expect(find.text('Export Preferences'), findsNothing);
    });

    testWidgets('opens and cancels logout dialog', (tester) async {
      await tester.pumpTrackletWidget(const SettingsScreen());
      await tester.pumpAndSettle();

      final logoutItem = find.text('Log Out');
      await tester.scrollUntilVisible(logoutItem, 200);
      await tester.tap(logoutItem);
      await tester.pumpAndSettle();

      expect(
        find.text(
          'Are you sure you want to log out of BusTracker on this device?',
        ),
        findsOneWidget,
      );

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(
        find.text(
          'Are you sure you want to log out of BusTracker on this device?',
        ),
        findsNothing,
      );
    });

    testWidgets('opens Transit FAQ dialog on tap', (tester) async {
      await tester.pumpTrackletWidget(const SettingsScreen());
      await tester.pumpAndSettle();

      final faqItem = find.text('Transit FAQ');
      await tester.scrollUntilVisible(faqItem, 200);
      await tester.tap(faqItem);
      await tester.pumpAndSettle();

      expect(find.byType(TransitFaqDialog), findsOneWidget);
      expect(find.text('Transit FAQ'), findsWidgets);

      // Close dialog
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();

      expect(find.byType(TransitFaqDialog), findsNothing);
    });

    testWidgets('renders About BusTracker and Legal rows in settings list', (
      tester,
    ) async {
      await tester.pumpTrackletWidget(const SettingsScreen());
      await tester.pumpAndSettle();

      final aboutItem = find.text('About BusTracker');
      await tester.scrollUntilVisible(aboutItem, 200);
      expect(aboutItem, findsOneWidget);

      final termsItem = find.text('Terms of Service');
      await tester.scrollUntilVisible(termsItem, 200);
      expect(termsItem, findsOneWidget);

      final privacyItem = find.text('Privacy Policy');
      await tester.scrollUntilVisible(privacyItem, 200);
      expect(privacyItem, findsOneWidget);

      final licensesItem = find.text('Open Source Licenses');
      await tester.scrollUntilVisible(licensesItem, 200);
      expect(licensesItem, findsOneWidget);
    });

    testWidgets(
      'opens Delete Account danger dialog with confirmation input validation',
      (tester) async {
        await tester.pumpTrackletWidget(const SettingsScreen());
        await tester.pumpAndSettle();

        final deleteAccountItem = find.text('Delete My Account');
        await tester.scrollUntilVisible(deleteAccountItem, 200);
        await tester.tap(deleteAccountItem);
        await tester.pumpAndSettle();

        expect(find.byType(DeleteAccountDialog), findsOneWidget);
        expect(find.text('Delete your account?'), findsOneWidget);

        // Verify Delete button disabled before matching input
        final deleteBtn = tester.widget<ElevatedButton>(
          find.widgetWithText(ElevatedButton, 'Delete Account'),
        );
        expect(deleteBtn.onPressed, isNull);

        // Enter matching confirmation
        await tester.enterText(find.byType(TextFormField), 'DELETE');
        await tester.pumpAndSettle();

        final activeDeleteBtn = tester.widget<ElevatedButton>(
          find.widgetWithText(ElevatedButton, 'Delete Account'),
        );
        expect(activeDeleteBtn.onPressed, isNotNull);

        // Cancel
        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();

        expect(find.byType(DeleteAccountDialog), findsNothing);
      },
    );

    testWidgets(
      'renders location section with status badge and handles location actions',
      (tester) async {
        await tester.pumpTrackletWidget(
          const SettingsScreen(),
          overrides: [
            locationStateProvider.overrideWith(
              () => _StubLocationNotifier(
                const LocationState(
                  permissionState: LocationPermissionState.deniedForever,
                ),
              ),
            ),
          ],
        );
        await tester.pumpAndSettle();

        final locationHeader = find.text('Location & Permissions');
        await tester.scrollUntilVisible(locationHeader, 200);
        await tester.pumpAndSettle();

        expect(find.text('Location & Permissions'), findsOneWidget);
        expect(find.text('Location Access'), findsOneWidget);
        expect(find.text('Blocked'), findsOneWidget);
        expect(find.text('Open Device Settings'), findsOneWidget);
      },
    );
  });
}

class _StubLocationNotifier extends LocationNotifier {
  _StubLocationNotifier(this._initialState);

  final LocationState _initialState;

  @override
  LocationState build() => _initialState;

  @override
  Future<void> refreshLocationIfPermitted() async {}

  @override
  Future<LocationPermissionState> refreshPermission() async =>
      _initialState.permissionState;
}
