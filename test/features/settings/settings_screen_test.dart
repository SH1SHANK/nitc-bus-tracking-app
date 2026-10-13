import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tracklet/features/settings/dialogs/change_display_name_dialog.dart';
import 'package:tracklet/features/settings/dialogs/change_password_dialog.dart';
import 'package:tracklet/features/settings/dialogs/delete_account_dialog.dart';
import 'package:tracklet/features/settings/dialogs/favorite_route_picker_dialog.dart';
import 'package:tracklet/features/settings/dialogs/favorite_stop_picker_dialog.dart';
import 'package:tracklet/core/geo/geo_point.dart';
import 'package:tracklet/data/profile/profile.dart';
import 'package:tracklet/data/transit/bus.dart';
import 'package:tracklet/data/transit/bus_route.dart';
import 'package:tracklet/data/transit/route_stop_occurrence.dart';
import 'package:tracklet/data/transit/scheduled_departure.dart';
import 'package:tracklet/data/transit/stop.dart';
import 'package:tracklet/data/transit/transit_repository.dart';
import 'package:tracklet/data/profile/profile_repository.dart';
import 'package:tracklet/features/settings/dialogs/legal_content_dialog.dart';
import 'package:tracklet/features/settings/dialogs/transit_faq_dialog.dart';
import 'package:tracklet/features/settings/settings_screen.dart';
import 'package:tracklet/services/location/location_service.dart';

import '../../helpers/pump_app.dart';

class _TestProfileRepo implements ProfileRepository {
  Profile profile = const Profile(
    id: 'test-user-1',
    name: 'Shashank Mergu',
    username: 'shashank',
    rollNumber: 'B210000CS',
    email: 'shashank@nitc.ac.in',
    role: 'Student',
    department: 'Computer Science & Engineering',
    branch: 'Computer Science & Engineering',
    batch: '2026',
    semester: 'Semester 6',
    hostel: 'MBH II',
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
  Future<void> updateNotificationPreference(bool enabled) async {
    profile = profile.copyWith(notificationsEnabled: enabled);
  }
}

const _settingsTestStops = <Stop>[
  Stop(
    id: 'department-building',
    name: 'Department Building',
    code: 'DB',
    location: GeoPoint(latitude: 11.32, longitude: 75.93),
  ),
];

const _settingsTestRoutes = <BusRoute>[
  BusRoute(id: 'r2', name: 'East ↔ LH (R2)', code: 'R2'),
];

class _SettingsTransitRepository implements TransitRepository {
  @override
  Future<List<BusRoute>> getRoutes({List<Stop>? knownStops}) async =>
      _settingsTestRoutes;

  @override
  Future<List<Stop>> getStops() async => _settingsTestStops;

  @override
  Future<List<RouteStopOccurrence>> getRouteStops(String routeId) async =>
      const [];

  @override
  Future<List<Bus>> getActiveBuses() async => const [];

  @override
  Future<List<ScheduledDeparture>> getScheduledDepartures() async => const [];

  @override
  Stream<List<Bus>> watchActiveBuses() => Stream.value(const []);

  @override
  Future<Stop?> getNearestStop(GeoPoint userLocation) async => null;

  @override
  Future<Bus?> getBusById(String busId) async => null;
}

void main() {
  group('SettingsScreen Widget Tests', () {
    testWidgets(
      'renders all core settings sections with academic profile data',
      (tester) async {
        final mockRepo = _TestProfileRepo();
        await tester.pumpTrackletWidget(
          const SettingsScreen(),
          overrides: [profileRepositoryProvider.overrideWithValue(mockRepo)],
        );
        await tester.pumpAndSettle();

        expect(find.text('App Settings'), findsOneWidget);
        expect(find.text('Student Profile'), findsOneWidget);
        expect(find.text('Shashank Mergu'), findsWidgets);
        expect(find.text('B210000CS'), findsOneWidget);
        expect(find.text('Semester 6'), findsOneWidget);
        expect(find.text('Computer Science & Engineering'), findsOneWidget);
        expect(find.text('Batch 2026'), findsOneWidget);
        expect(find.text('MBH II'), findsOneWidget);

        expect(find.text('Account & Security'), findsOneWidget);
        expect(find.text('Commute Preferences'), findsOneWidget);
        expect(find.text('Notifications'), findsOneWidget);
      },
    );

    testWidgets(
      'toggles Transit Time Format chips between 12-Hour and 24-Hour',
      (tester) async {
        await tester.pumpTrackletWidget(const SettingsScreen());
        await tester.pumpAndSettle();

        final chip24 = find.text('24-Hour (17:30)');
        await tester.scrollUntilVisible(chip24, 200);
        await tester.pumpAndSettle();

        expect(find.text('05:30 PM'), findsWidgets);

        // Tap 24-Hour chip
        await tester.tap(chip24);
        await tester.pumpAndSettle();

        expect(find.text('17:30'), findsWidgets);
      },
    );

    testWidgets('increments and decrements alert lead time stepper', (
      tester,
    ) async {
      await tester.pumpTrackletWidget(const SettingsScreen());
      await tester.pumpAndSettle();

      final plusIcon = find.byIcon(Icons.add_rounded).first;
      await tester.scrollUntilVisible(plusIcon, 200);
      await tester.pumpAndSettle();

      expect(find.text('5 min'), findsOneWidget);

      // Tap + button
      await tester.tap(plusIcon);
      await tester.pumpAndSettle();

      expect(find.text('6 min'), findsOneWidget);

      // Tap - button
      final minusIcon = find.byIcon(Icons.remove_rounded).first;
      await tester.tap(minusIcon);
      await tester.pumpAndSettle();

      expect(find.text('5 min'), findsOneWidget);
    });

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
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();

      expect(find.byType(ChangePasswordDialog), findsNothing);
    });

    testWidgets('opens Favorite Stop picker dialog on tap', (tester) async {
      await tester.pumpTrackletWidget(const SettingsScreen());
      await tester.pumpAndSettle();

      final favStopItem = find.text('Favorite Bus Stop');
      await tester.scrollUntilVisible(favStopItem, 200);
      await tester.tap(favStopItem);
      await tester.pumpAndSettle();

      expect(find.byType(FavoriteStopPickerDialog), findsOneWidget);
      expect(find.text('Select Favorite Stop'), findsOneWidget);

      // Close dialog
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();

      expect(find.byType(FavoriteStopPickerDialog), findsNothing);
    });

    testWidgets('opens Favorite Route picker dialog on tap', (tester) async {
      await tester.pumpTrackletWidget(const SettingsScreen());
      await tester.pumpAndSettle();

      final favRouteItem = find.text('Favorite Route');
      await tester.scrollUntilVisible(favRouteItem, 200);
      await tester.tap(favRouteItem);
      await tester.pumpAndSettle();

      expect(find.byType(FavoriteRoutePickerDialog), findsOneWidget);
      expect(find.text('Select Favorite Route'), findsOneWidget);

      // Close dialog
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();

      expect(find.byType(FavoriteRoutePickerDialog), findsNothing);
    });

    testWidgets('selects a favorite stop and updates preferences', (
      tester,
    ) async {
      await tester.pumpTrackletWidget(
        const SettingsScreen(),
        overrides: [
          transitRepositoryProvider.overrideWithValue(
            _SettingsTransitRepository(),
          ),
        ],
      );
      await tester.pumpAndSettle();

      final favStopItem = find.text('Favorite Bus Stop');
      await tester.scrollUntilVisible(favStopItem, 200);
      await tester.tap(favStopItem);
      await tester.pumpAndSettle();

      expect(find.byType(FavoriteStopPickerDialog), findsOneWidget);

      // Select Department Building stop (first stop in list)
      final deptTile = find.text('Department Building');
      expect(deptTile, findsOneWidget);
      await tester.tap(deptTile);
      await tester.pumpAndSettle();

      expect(find.byType(FavoriteStopPickerDialog), findsNothing);
      expect(
        find.text('Favorite stop set to Department Building'),
        findsOneWidget,
      );
    });

    testWidgets('selects a favorite route and updates preferences', (
      tester,
    ) async {
      await tester.pumpTrackletWidget(
        const SettingsScreen(),
        overrides: [
          transitRepositoryProvider.overrideWithValue(
            _SettingsTransitRepository(),
          ),
        ],
      );
      await tester.pumpAndSettle();

      final favRouteItem = find.text('Favorite Route');
      await tester.scrollUntilVisible(favRouteItem, 200);
      await tester.tap(favRouteItem);
      await tester.pumpAndSettle();

      expect(find.byType(FavoriteRoutePickerDialog), findsOneWidget);

      // Select R2 route
      final r2Tile = find.text('East ↔ LH (R2)');
      expect(r2Tile, findsOneWidget);
      await tester.tap(r2Tile);
      await tester.pumpAndSettle();

      expect(find.byType(FavoriteRoutePickerDialog), findsNothing);
      expect(find.text('Favorite route set to East ↔ LH (R2)'), findsOneWidget);
    });

    testWidgets('triggers sync transit schedules and shows feedback', (
      tester,
    ) async {
      await tester.pumpTrackletWidget(const SettingsScreen());
      await tester.pumpAndSettle();

      final syncItem = find.text('Sync Transit Schedules');
      await tester.scrollUntilVisible(syncItem, 200);
      await tester.tap(syncItem);
      await tester.pumpAndSettle();

      expect(
        find.text('Transit schedules synced successfully'),
        findsOneWidget,
      );
    });

    testWidgets('triggers clear cache and displays confirmation', (
      tester,
    ) async {
      await tester.pumpTrackletWidget(const SettingsScreen());
      await tester.pumpAndSettle();

      final clearCacheItem = find.text('Clear Cache');
      await tester.scrollUntilVisible(clearCacheItem, 200);
      await tester.tap(clearCacheItem);
      await tester.pumpAndSettle();

      expect(
        find.text('Cached map tiles and temporary data cleared'),
        findsOneWidget,
      );
    });

    testWidgets('opens export preferences dialog and allows copy', (
      tester,
    ) async {
      await tester.pumpTrackletWidget(const SettingsScreen());
      await tester.pumpAndSettle();

      final exportItem = find.text('Export Preferences');
      await tester.scrollUntilVisible(exportItem, 200);
      await tester.tap(exportItem);
      await tester.pumpAndSettle();

      expect(find.text('Exported Preferences'), findsOneWidget);
      expect(find.text('Copy to Clipboard'), findsOneWidget);

      await tester.tap(find.text('Copy to Clipboard'));
      await tester.pumpAndSettle();

      expect(find.text('Preferences copied to clipboard'), findsOneWidget);
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
          'Are you sure you want to log out of Tracklet on this device?',
        ),
        findsOneWidget,
      );

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(
        find.text(
          'Are you sure you want to log out of Tracklet on this device?',
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

    testWidgets('opens Terms of Service and Privacy Policy legal dialogs', (
      tester,
    ) async {
      await tester.pumpTrackletWidget(const SettingsScreen());
      await tester.pumpAndSettle();

      // Tap Terms of Service
      final termsItem = find.text('Terms of Service');
      await tester.scrollUntilVisible(termsItem, 200);
      await tester.tap(termsItem);
      await tester.pumpAndSettle();

      expect(find.byType(LegalContentDialog), findsOneWidget);
      expect(find.text('Terms of Service'), findsWidgets);

      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();

      // Tap Privacy Policy
      final privacyItem = find.text('Privacy Policy');
      await tester.scrollUntilVisible(privacyItem, 200);
      await tester.tap(privacyItem);
      await tester.pumpAndSettle();

      expect(find.byType(LegalContentDialog), findsOneWidget);
      expect(find.text('Privacy Policy'), findsWidgets);

      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();
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
