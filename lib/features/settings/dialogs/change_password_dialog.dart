import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/auth/auth_repository.dart';
import '../../../design_system/tokens/colors.dart';
import '../../../design_system/components/icons/tracklet_icons.dart';
import '../../../design_system/tokens/radii.dart';
import '../../../design_system/tokens/spacing.dart';
import '../../../design_system/tokens/tracklet_fonts.dart';
import '../../auth/providers/auth_provider.dart';

/// Modal dialog for changing account password.
///
/// Intelligently branches:
/// - If authenticated via Google OAuth, explains that credentials are managed by Google.
/// - If authenticated via Email/Password, renders old/new/confirm password validation.
class ChangePasswordDialog extends ConsumerStatefulWidget {
  const ChangePasswordDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (context) => const ChangePasswordDialog(),
    );
  }

  @override
  ConsumerState<ChangePasswordDialog> createState() =>
      _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends ConsumerState<ChangePasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _oldPasswordVisibility = false;
  bool _newPasswordVisibility = false;
  bool _confirmPasswordVisibility = false;
  bool _isSaving = false;

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isSaving = true);
    try {
      final authRepo = ref.read(authRepositoryProvider);
      final result = await authRepo.updatePassword(
        _newPasswordController.text.trim(),
      );

      if (!mounted) return;

      if (result.isSuccess) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Password changed successfully!',
              style: TrackletFonts.outfit(
                fontWeight: FontWeight.w600,
                fontSize: 12.0,
                color: TrackletColors.info,
              ),
            ),
            backgroundColor: TrackletColors.success,
            duration: const Duration(milliseconds: 3000),
          ),
        );
      } else {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result.errorMessage ??
                  'Failed to update password. Please check your credentials.',
              style: TrackletFonts.outfit(
                fontWeight: FontWeight.w600,
                fontSize: 12.0,
                color: TrackletColors.info,
              ),
            ),
            backgroundColor: TrackletColors.error,
            duration: const Duration(milliseconds: 3000),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to update password. Please check your credentials.',
              style: TrackletFonts.outfit(
                fontWeight: FontWeight.w600,
                fontSize: 12.0,
                color: TrackletColors.info,
              ),
            ),
            backgroundColor: TrackletColors.error,
            duration: const Duration(milliseconds: 3000),
          ),
        );
      }
    }
  }

  static InputDecoration _passwordFieldDecoration({
    required BuildContext context,
    required String hintText,
    required bool isVisible,
    required VoidCallback onToggleVisibility,
  }) {
    final isDark = TrackletColors.isDark(context);

    return InputDecoration(
      hintText: hintText,
      hintStyle: TrackletFonts.outfit(
        fontSize: 14.0,
        color: TrackletColors.adaptiveTextSecondary(context),
      ),
      filled: true,
      fillColor:
          isDark
              ? TrackletColors.darkSurfaceElevated
              : TrackletColors.primaryBackground,
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(
          color: isDark ? TrackletColors.darkBorder : TrackletColors.alternate,
          width: TrackletSpacing.xxs,
        ),
        borderRadius: TrackletRadii.roundedCard,
      ),
      focusedBorder: const OutlineInputBorder(
        borderSide: BorderSide(
          color: TrackletColors.primary,
          width: TrackletSpacing.xxs,
        ),
        borderRadius: TrackletRadii.roundedCard,
      ),
      errorBorder: const OutlineInputBorder(
        borderSide: BorderSide(
          color: TrackletColors.errorBorder,
          width: TrackletSpacing.xxs,
        ),
        borderRadius: TrackletRadii.roundedCard,
      ),
      focusedErrorBorder: const OutlineInputBorder(
        borderSide: BorderSide(
          color: TrackletColors.errorBorder,
          width: TrackletSpacing.xxs,
        ),
        borderRadius: TrackletRadii.roundedCard,
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: TrackletSpacing.compactLg,
        vertical: TrackletSpacing.md,
      ),
      suffixIcon: IconButton(
        icon: Icon(
          isVisible ? TrackletIcons.eye : TrackletIcons.eyeOff,
          color: TrackletColors.adaptiveTextSecondary(context),
          size: 20.0,
        ),
        onPressed: onToggleVisibility,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = TrackletColors.isDark(context);
    final authState = ref.watch(authNotifierProvider);
    final isGoogleUser = authState.isGoogleUser;

    if (isGoogleUser) {
      return Dialog(
        elevation: 0,
        insetPadding: const EdgeInsets.symmetric(
          horizontal: TrackletSpacing.section,
        ),
        backgroundColor: Colors.transparent,
        alignment: Alignment.center,
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 400.0),
          decoration: BoxDecoration(
            color: TrackletColors.adaptiveSurface(context),
            borderRadius: TrackletRadii.roundedCard,
            border: Border.all(color: TrackletColors.adaptiveBorder(context)),
            boxShadow: const [
              BoxShadow(
                blurRadius: 16.0,
                color: TrackletColors.scrim,
                offset: Offset(0.0, 4.0),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(TrackletSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Change Password',
                        style: TrackletFonts.outfit(
                          fontSize: 20.0,
                          fontWeight: FontWeight.w700,
                          color: TrackletColors.adaptiveTextPrimary(context),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        TrackletIcons.x,
                        color: TrackletColors.textTertiary,
                        size: 22.0,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: TrackletSpacing.md),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color:
                        isDark
                            ? TrackletColors.primary.withValues(alpha: 0.12)
                            : TrackletColors.permissionBlueBg,
                    borderRadius: TrackletRadii.roundedCard,
                    border: Border.all(
                      color:
                          isDark
                              ? TrackletColors.primary.withValues(alpha: 0.3)
                              : TrackletColors.permissionBlueIcon.withValues(
                                alpha: 0.2,
                              ),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        TrackletIcons.lock,
                        size: 22,
                        color:
                            isDark
                                ? TrackletColors.velvetSky
                                : TrackletColors.permissionBlueIcon,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Managed by Google Workspace',
                              style: TrackletFonts.outfit(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: TrackletColors.adaptiveTextPrimary(
                                  context,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'You signed in with your official NITC Google account. Your password is managed securely through your Google Account settings, so you do not need a separate BusTracker password.',
                              style: TrackletFonts.outfit(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w400,
                                height: 1.4,
                                color: TrackletColors.adaptiveTextSecondary(
                                  context,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: TrackletSpacing.lg),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: TrackletColors.primary,
                      foregroundColor: TrackletColors.pure,
                      shape: const RoundedRectangleBorder(
                        borderRadius: TrackletRadii.roundedMd,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                    ),
                    child: Text(
                      'Understood',
                      style: TrackletFonts.outfit(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Dialog(
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(
        horizontal: TrackletSpacing.section,
      ),
      backgroundColor: Colors.transparent,
      alignment: Alignment.center,
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 400.0),
        decoration: BoxDecoration(
          color: TrackletColors.adaptiveSurface(context),
          borderRadius: TrackletRadii.roundedCard,
          border: Border.all(color: TrackletColors.adaptiveBorder(context)),
          boxShadow: const [
            BoxShadow(
              blurRadius: 16.0,
              color: TrackletColors.scrim,
              offset: Offset(0.0, 4.0),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(TrackletSpacing.lg),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'Change Password',
                          style: TrackletFonts.outfit(
                            fontSize: 22.0,
                            fontWeight: FontWeight.w700,
                            color: TrackletColors.adaptiveTextPrimary(context),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          TrackletIcons.x,
                          color: TrackletColors.textTertiary,
                          size: 24.0,
                        ),
                        splashRadius: 20.0,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: TrackletSpacing.lg),

                  // Old Password
                  Text(
                    'Old Password',
                    style: TrackletFonts.outfit(
                      fontSize: 13.0,
                      fontWeight: FontWeight.w500,
                      color: TrackletColors.adaptiveTextSecondary(context),
                    ),
                  ),
                  const SizedBox(height: TrackletSpacing.xs),
                  TextFormField(
                    controller: _oldPasswordController,
                    obscureText: !_oldPasswordVisibility,
                    textInputAction: TextInputAction.next,
                    style: TrackletFonts.outfit(
                      color: TrackletColors.adaptiveTextPrimary(context),
                    ),
                    decoration: _passwordFieldDecoration(
                      context: context,
                      hintText: 'Enter current password',
                      isVisible: _oldPasswordVisibility,
                      onToggleVisibility:
                          () => setState(
                            () =>
                                _oldPasswordVisibility =
                                    !_oldPasswordVisibility,
                          ),
                    ),
                    validator: (val) {
                      if (val == null || val.isEmpty) {
                        return 'Please enter your old password';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: TrackletSpacing.md),

                  // New Password
                  Text(
                    'New Password',
                    style: TrackletFonts.outfit(
                      fontSize: 13.0,
                      fontWeight: FontWeight.w500,
                      color: TrackletColors.adaptiveTextSecondary(context),
                    ),
                  ),
                  const SizedBox(height: TrackletSpacing.xs),
                  TextFormField(
                    controller: _newPasswordController,
                    obscureText: !_newPasswordVisibility,
                    textInputAction: TextInputAction.next,
                    style: TrackletFonts.outfit(
                      color: TrackletColors.adaptiveTextPrimary(context),
                    ),
                    decoration: _passwordFieldDecoration(
                      context: context,
                      hintText: 'Enter new password',
                      isVisible: _newPasswordVisibility,
                      onToggleVisibility:
                          () => setState(
                            () =>
                                _newPasswordVisibility =
                                    !_newPasswordVisibility,
                          ),
                    ),
                    validator: (val) {
                      if (val == null || val.isEmpty) {
                        return 'Please enter a new password';
                      }
                      if (val.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: TrackletSpacing.md),

                  // Confirm Password
                  Text(
                    'Confirm Password',
                    style: TrackletFonts.outfit(
                      fontSize: 13.0,
                      fontWeight: FontWeight.w500,
                      color: TrackletColors.adaptiveTextSecondary(context),
                    ),
                  ),
                  const SizedBox(height: TrackletSpacing.xs),
                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: !_confirmPasswordVisibility,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _handleSave(),
                    style: TrackletFonts.outfit(
                      color: TrackletColors.adaptiveTextPrimary(context),
                    ),
                    decoration: _passwordFieldDecoration(
                      context: context,
                      hintText: 'Re-enter new password',
                      isVisible: _confirmPasswordVisibility,
                      onToggleVisibility:
                          () => setState(
                            () =>
                                _confirmPasswordVisibility =
                                    !_confirmPasswordVisibility,
                          ),
                    ),
                    validator: (val) {
                      if (val == null || val.isEmpty) {
                        return 'Please confirm your new password';
                      }
                      if (val != _newPasswordController.text) {
                        return 'Passwords do not match';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: TrackletSpacing.xl),

                  // Actions
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed:
                            _isSaving ? null : () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          backgroundColor:
                              isDark
                                  ? TrackletColors.darkSurfaceElevated
                                  : TrackletColors.alternate,
                          padding: const EdgeInsets.symmetric(
                            horizontal: TrackletSpacing.md,
                            vertical: TrackletSpacing.compactMd,
                          ),
                          shape: const RoundedRectangleBorder(
                            borderRadius: TrackletRadii.roundedCard,
                          ),
                        ),
                        child: Text(
                          'Cancel',
                          style: TrackletFonts.outfit(
                            fontSize: 14.0,
                            fontWeight: FontWeight.w600,
                            color: TrackletColors.adaptiveTextPrimary(context),
                          ),
                        ),
                      ),
                      const SizedBox(width: TrackletSpacing.sm),
                      ElevatedButton(
                        onPressed: _isSaving ? null : _handleSave,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: TrackletColors.primary,
                          foregroundColor: TrackletColors.textInverse,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                            horizontal: TrackletSpacing.md,
                            vertical: TrackletSpacing.compactMd,
                          ),
                          shape: const RoundedRectangleBorder(
                            borderRadius: TrackletRadii.roundedCard,
                          ),
                        ),
                        child:
                            _isSaving
                                ? const SizedBox(
                                  width: TrackletSpacing.lg,
                                  height: TrackletSpacing.lg,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.0,
                                    color: TrackletColors.textInverse,
                                  ),
                                )
                                : Text(
                                  'Update Password',
                                  style: TrackletFonts.outfit(
                                    fontSize: 14.0,
                                    fontWeight: FontWeight.w600,
                                    color: TrackletColors.textInverse,
                                  ),
                                ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
