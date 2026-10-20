import 'package:tracklet/design_system/tokens/typography.dart';
import 'package:flutter/material.dart';
import '../../../design_system/tokens/shadows.dart';
import 'package:flutter_lucide_animated/flutter_lucide_animated.dart'
    as animated;
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
                fontWeight: TrackletTypography.weightSemiBold,
                fontSize: TrackletTypography.fontSize12,
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
                  'Could not update password. Check your credentials and try again.',
              style: TrackletFonts.outfit(
                fontWeight: TrackletTypography.weightSemiBold,
                fontSize: TrackletTypography.fontSize12,
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
              'Could not update password. Check your credentials and try again.',
              style: TrackletFonts.outfit(
                fontWeight: TrackletTypography.weightSemiBold,
                fontSize: TrackletTypography.fontSize12,
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
        fontSize: TrackletTypography.fontSize14,
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
        icon: IgnorePointer(
          child: animated.LucideAnimatedIcon(
            key: ValueKey(isVisible),
            icon: isVisible ? animated.eye : animated.eye_off,
            trigger: animated.AnimationTrigger.manual,
            color: TrackletColors.adaptiveTextSecondary(context),
            size: 20.0,
          ),
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
        elevation: TrackletShadows.elevationLevel0,
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
                          fontSize: TrackletTypography.fontSize20,
                          fontWeight: TrackletTypography.weightBold,
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
                  padding: const EdgeInsets.all(TrackletSpacing.md),
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
                                fontSize: TrackletTypography.fontSize14,
                                fontWeight: TrackletTypography.weightBold,
                                color: TrackletColors.adaptiveTextPrimary(
                                  context,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'You signed in with your NITC Google account. Your password is managed through Google Account settings, so a separate BusTracker password is not required.',
                              style: TrackletFonts.outfit(
                                fontSize: TrackletTypography.fontSize12_5,
                                fontWeight: TrackletTypography.weightRegular,
                                height: TrackletTypography.lineHeightBody,
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
                        horizontal: TrackletSpacing.section,
                        vertical: TrackletSpacing.compactMd,
                      ),
                    ),
                    child: Text(
                      'Done',
                      style: TrackletFonts.outfit(
                        fontWeight: TrackletTypography.weightSemiBold,
                        fontSize: TrackletTypography.fontSize14,
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
      elevation: TrackletShadows.elevationLevel0,
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
                            fontSize: TrackletTypography.fontSize22,
                            fontWeight: TrackletTypography.weightBold,
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
                      fontSize: TrackletTypography.fontSize13,
                      fontWeight: TrackletTypography.weightMedium,
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
                      fontSize: TrackletTypography.fontSize13,
                      fontWeight: TrackletTypography.weightMedium,
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
                      fontSize: TrackletTypography.fontSize13,
                      fontWeight: TrackletTypography.weightMedium,
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
                            fontSize: TrackletTypography.fontSize14,
                            fontWeight: TrackletTypography.weightSemiBold,
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
                          elevation: TrackletShadows.elevationLevel0,
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
                                    fontSize: TrackletTypography.fontSize14,
                                    fontWeight:
                                        TrackletTypography.weightSemiBold,
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
