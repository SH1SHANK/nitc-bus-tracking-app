import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/auth/auth_repository.dart';
import '../../../design_system/tokens/colors.dart';
import '../../../design_system/tokens/spacing.dart';
import '../../../design_system/tokens/radii.dart';
import '../../../design_system/tokens/tracklet_fonts.dart';

/// Modal dialog matching Attendrix ChangePasswordWidget styling and fields.
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
    required String hintText,
    required bool isVisible,
    required VoidCallback onToggleVisibility,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: TrackletFonts.outfit(
        fontSize: 14.0,
        color: TrackletColors.secondaryText,
      ),
      enabledBorder: const OutlineInputBorder(
        borderSide: BorderSide(
          color: TrackletColors.alternate,
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
      contentPadding: const EdgeInsets.symmetric(
        horizontal: TrackletSpacing.compactLg,
        vertical: TrackletSpacing.md,
      ),
      suffixIcon: IconButton(
        icon: Icon(
          isVisible ? Icons.visibility_rounded : Icons.visibility_off_rounded,
          color: TrackletColors.secondaryText,
          size: 20.0,
        ),
        onPressed: onToggleVisibility,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
        decoration: const BoxDecoration(
          color: TrackletColors.secondaryBackground,
          borderRadius: TrackletRadii.roundedCard,
          boxShadow: [
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
                            color: TrackletColors.textPrimary,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.close_rounded,
                          color: TrackletColors.absentRed,
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
                      color: TrackletColors.secondaryText,
                    ),
                  ),
                  const SizedBox(height: TrackletSpacing.xs),
                  TextFormField(
                    controller: _oldPasswordController,
                    obscureText: !_oldPasswordVisibility,
                    textInputAction: TextInputAction.next,
                    decoration: _passwordFieldDecoration(
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
                      color: TrackletColors.secondaryText,
                    ),
                  ),
                  const SizedBox(height: TrackletSpacing.xs),
                  TextFormField(
                    controller: _newPasswordController,
                    obscureText: !_newPasswordVisibility,
                    textInputAction: TextInputAction.next,
                    decoration: _passwordFieldDecoration(
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
                      if (val == null || val.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: TrackletSpacing.md),

                  // Confirm Password
                  Text(
                    'Confirm New Password',
                    style: TrackletFonts.outfit(
                      fontSize: 13.0,
                      fontWeight: FontWeight.w500,
                      color: TrackletColors.secondaryText,
                    ),
                  ),
                  const SizedBox(height: TrackletSpacing.xs),
                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: !_confirmPasswordVisibility,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _handleSave(),
                    decoration: _passwordFieldDecoration(
                      hintText: 'Confirm new password',
                      isVisible: _confirmPasswordVisibility,
                      onToggleVisibility:
                          () => setState(
                            () =>
                                _confirmPasswordVisibility =
                                    !_confirmPasswordVisibility,
                          ),
                    ),
                    validator: (val) {
                      if (val != _newPasswordController.text) {
                        return 'Passwords do not match';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: TrackletSpacing.section),

                  Wrap(
                    alignment: WrapAlignment.end,
                    spacing: 8.0,
                    runSpacing: 8.0,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          backgroundColor: TrackletColors.alternate,
                          padding: const EdgeInsets.symmetric(
                            horizontal: TrackletSpacing.lg,
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
                            color: TrackletColors.textPrimary,
                          ),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: _isSaving ? null : _handleSave,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: TrackletColors.primary,
                          foregroundColor: TrackletColors.textInverse,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                            horizontal: TrackletSpacing.section,
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
