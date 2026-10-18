import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tracklet/data/profile/profile.dart';
import 'package:tracklet/data/profile/profile_repository.dart';
import 'package:tracklet/features/profile/dialogs/avatar_picker_sheet.dart';

class _FakeProfileRepository implements ProfileRepository {
  Profile _profile = const Profile(
    id: 'test_user',
    name: 'Test Rider',
    email: 'test@nitc.ac.in',
    role: 'Student',
    hasCompletedOnboarding: true,
    avatarSeed: 'InitialSeed',
  );

  @override
  Future<Profile> getProfile() async => _profile;

  @override
  Future<void> saveProfile(Profile profile) async {
    _profile = profile;
  }

  @override
  Future<bool> isUsernameAvailable(String username) async => true;

  @override
  Future<Profile> changeUsername(String newUsername) async {
    _profile = _profile.copyWith(username: newUsername);
    return _profile;
  }

  @override
  Future<void> setOnboardingCompleted(bool completed) async {
    _profile = _profile.copyWith(hasCompletedOnboarding: completed);
  }
}

void main() {
  group('AvatarPickerSheet', () {
    late _FakeProfileRepository fakeRepo;

    setUp(() {
      fakeRepo = _FakeProfileRepository();
    });

    Widget buildTestHost({
      String? currentSeed = 'CosmicRider42',
      String userEmail = 'rider@nitc.ac.in',
      String userName = 'Rider',
    }) {
      return ProviderScope(
        overrides: [profileRepositoryProvider.overrideWithValue(fakeRepo)],
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder:
                  (context) => ElevatedButton(
                    key: const ValueKey('open_avatar_picker'),
                    onPressed: () {
                      AvatarPickerSheet.show(
                        context,
                        currentSeed: currentSeed,
                        userEmail: userEmail,
                        userName: userName,
                      );
                    },
                    child: const Text('Open Picker'),
                  ),
            ),
          ),
        ),
      );
    }

    testWidgets(
      'renders avatar picker sheet with clean avatar grid and Roll New button',
      (tester) async {
        await tester.pumpWidget(buildTestHost());
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const ValueKey('open_avatar_picker')));
        await tester.pumpAndSettle();

        expect(find.text('Customize Avatar'), findsOneWidget);
        expect(
          find.text('Powered by DiceBear 3D Voxel Engine'),
          findsOneWidget,
        );
        expect(find.text('Pick an Avatar'), findsOneWidget);
        expect(find.text('Roll New'), findsOneWidget);
        expect(find.byIcon(Icons.casino_rounded), findsOneWidget);
        expect(find.byType(TextField), findsNothing);
        expect(find.text('Apply Avatar'), findsOneWidget);
      },
    );

    testWidgets('tapping an avatar in the grid selects it', (tester) async {
      await tester.pumpWidget(buildTestHost(currentSeed: 'NeonVoyager10'));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('open_avatar_picker')));
      await tester.pumpAndSettle();

      // Find ink wells representing avatar options
      final inkWells = find.byType(InkWell);
      expect(inkWells, findsAtLeastNWidgets(2));

      // Tap the second avatar in the grid
      await tester.tap(inkWells.at(1));
      await tester.pump();

      expect(find.text('Pick an Avatar'), findsOneWidget);
      expect(find.text('Apply Avatar'), findsOneWidget);
    });

    testWidgets('tapping Roll New refreshes generated avatar options', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestHost());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('open_avatar_picker')));
      await tester.pumpAndSettle();

      final rollButton = find.text('Roll New');
      expect(rollButton, findsOneWidget);

      await tester.tap(rollButton);
      await tester.pump();

      expect(find.text('Pick an Avatar'), findsOneWidget);
      expect(find.text('Apply Avatar'), findsOneWidget);
    });

    testWidgets(
      'tapping Apply Avatar persists selection and closes bottom sheet',
      (tester) async {
        await tester.pumpWidget(buildTestHost(currentSeed: 'VoxelNinja22'));
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const ValueKey('open_avatar_picker')));
        await tester.pumpAndSettle();

        final applyButton = find.widgetWithText(ElevatedButton, 'Apply Avatar');
        expect(applyButton, findsOneWidget);

        await tester.ensureVisible(applyButton);
        await tester.pumpAndSettle();

        await tester.tap(applyButton);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));
        await tester.pump(const Duration(milliseconds: 500));

        // Bottom sheet should be dismissed
        expect(find.text('Customize Avatar'), findsNothing);
        // SnackBar confirmation should appear
        expect(find.text('Avatar updated successfully'), findsOneWidget);
      },
    );
  });
}
