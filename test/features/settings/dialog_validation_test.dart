import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import 'package:flutter_test/flutter_test.dart';
import 'package:tracklet/data/auth/auth_repository.dart';
import 'package:tracklet/data/auth/auth_result.dart';
import 'package:tracklet/data/auth/auth_state.dart';
import 'package:tracklet/features/settings/dialogs/change_display_name_dialog.dart';
import 'package:tracklet/features/settings/dialogs/change_password_dialog.dart';
import 'package:tracklet/features/settings/dialogs/legal_content_dialog.dart';

import '../../helpers/pump_app.dart';

void main() {
  group('Settings Dialogs Validation & Edge Cases Tests', () {
    testWidgets('ChangeDisplayNameDialog validates empty and short names', (
      tester,
    ) async {
      await tester.pumpTrackletWidget(
        Scaffold(
          body: Builder(
            builder:
                (context) => ElevatedButton(
                  onPressed: () => ChangeDisplayNameDialog.show(context),
                  child: const Text('Open'),
                ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Change Display Name'), findsOneWidget);

      // Enter empty/whitespace name
      final inputField = find.byType(TextFormField);
      await tester.enterText(inputField, '   ');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(find.text('Please enter your display name'), findsOneWidget);

      // Enter 1 char (too short)
      await tester.enterText(inputField, 'A');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(find.text('Name must be at least 2 characters'), findsOneWidget);

      // Enter valid name
      await tester.enterText(inputField, 'Arjun V');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(find.byType(ChangeDisplayNameDialog), findsNothing);
      expect(find.text('Display name updated successfully!'), findsOneWidget);
    });

    testWidgets(
      'ChangePasswordDialog validates old password, length, and confirmation matching',
      (tester) async {
        await tester.pumpTrackletWidget(
          Scaffold(
            body: Builder(
              builder:
                  (context) => ElevatedButton(
                    onPressed: () => ChangePasswordDialog.show(context),
                    child: const Text('Open'),
                  ),
            ),
          ),
          overrides: [
            authRepositoryProvider.overrideWithValue(
              _SuccessfulAuthRepository(),
            ),
          ],
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();

        expect(find.text('Change Password'), findsOneWidget);

        // Tap submit with empty fields
        await tester.tap(find.text('Update Password'));
        await tester.pumpAndSettle();

        expect(find.text('Please enter your old password'), findsOneWidget);

        // Fill old password, but short new password
        final fields = find.byType(TextFormField);
        await tester.enterText(fields.at(0), 'oldPassword123');
        await tester.enterText(fields.at(1), 'short');
        await tester.tap(find.text('Update Password'));
        await tester.pumpAndSettle();

        expect(
          find.text('Password must be at least 6 characters'),
          findsOneWidget,
        );

        // Fill mismatched confirm password
        await tester.enterText(fields.at(1), 'newPassword123');
        await tester.enterText(fields.at(2), 'mismatchPassword');
        await tester.tap(find.text('Update Password'));
        await tester.pumpAndSettle();

        expect(find.text('Passwords do not match'), findsOneWidget);

        // Fill matching confirm password and submit
        await tester.enterText(fields.at(2), 'newPassword123');
        await tester.tap(find.text('Update Password'));
        await tester.pumpAndSettle();

        expect(find.byType(ChangePasswordDialog), findsNothing);
        expect(find.text('Password changed successfully!'), findsOneWidget);
      },
    );

    testWidgets('LegalContentDialog renders title and content cleanly', (
      tester,
    ) async {
      await tester.pumpTrackletWidget(
        const LegalContentDialog(
          title: 'Custom Legal Title',
          content: 'This is test legal content.',
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Custom Legal Title'), findsOneWidget);
      expect(find.text('This is test legal content.'), findsOneWidget);
    });
  });
}

class _SuccessfulAuthRepository implements AuthRepository {
  @override
  Stream<AuthState> get authStateChanges => const Stream.empty();

  @override
  AuthState get currentAuthState =>
      const AuthState(status: AuthStatus.authenticated);

  @override
  User? get currentUser => null;

  @override
  Session? get currentSession => null;

  @override
  bool get isAuthenticated => true;

  @override
  Future<AuthResult> updatePassword(String newPassword) async =>
      AuthResult.success();

  @override
  Future<AuthResult> signInWithEmail(String email, String password) async =>
      AuthResult.success();

  @override
  Future<AuthResult> signUpWithEmail(
    String email,
    String password, {
    String? fullName,
  }) async => AuthResult.success();

  @override
  Future<AuthResult> resetPasswordForEmail(
    String email, {
    String? redirectTo,
  }) async => AuthResult.success();

  @override
  Future<AuthResult> resendVerificationEmail(String email) async =>
      AuthResult.success();

  @override
  Future<AuthResult> signInWithGoogle() async => AuthResult.success();

  @override
  Future<void> signOut() async {}

  @override
  void dispose() {}
}
