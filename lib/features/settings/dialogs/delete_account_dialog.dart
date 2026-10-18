import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../data/preferences/user_preferences.dart';
import '../../../data/profile/profile.dart';
import '../../../data/profile/profile_repository.dart';
import '../../../design_system/tokens/colors.dart';
import '../../../design_system/components/icons/tracklet_icons.dart';
import '../../../design_system/tokens/spacing.dart';
import '../../../design_system/tokens/radii.dart';
import '../../../design_system/tokens/tracklet_fonts.dart';
import '../../auth/providers/auth_provider.dart';
import '../../profile/providers/profile_provider.dart';

/// Modal dialog strictly conforming to Attendrix DeleleAccountWidget layout and deletion confirmation rules.
class DeleteAccountDialog extends ConsumerStatefulWidget {
  const DeleteAccountDialog({super.key, required this.username});

  final String username;

  static Future<void> show(
    BuildContext context, {
    String username = 'shashank',
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (context) => DeleteAccountDialog(username: username),
    );
  }

  @override
  ConsumerState<DeleteAccountDialog> createState() =>
      _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends ConsumerState<DeleteAccountDialog> {
  final _confirmationController = TextEditingController();
  bool _isDeleting = false;

  @override
  void dispose() {
    _confirmationController.dispose();
    super.dispose();
  }

  bool get _isConfirmationValid =>
      (widget.username.trim().isNotEmpty &&
          _confirmationController.text.trim().toLowerCase() ==
              widget.username.trim().toLowerCase()) ||
      _confirmationController.text.trim().toUpperCase() == 'DELETE';

  Future<void> _handleDelete() async {
    if (!_isConfirmationValid) return;

    setState(() => _isDeleting = true);

    try {
      // 1. Invoke authoritative delete_user_account RPC
      await ref.read(authNotifierProvider.notifier).deleteAccount();

      // 2. Reset local profile and user preferences
      await ref.read(userPreferencesProvider.notifier).resetPreferences();
      await ref
          .read(profileRepositoryProvider)
          .saveProfile(
            const Profile(
              id: 'guest',
              name: 'Guest Rider',
              email: '',
              role: 'Guest',
              hasCompletedOnboarding: false,
            ),
          );
      ref.invalidate(profileStateProvider);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Your account has been permanently deleted.',
              style: TrackletFonts.outfit(
                fontWeight: FontWeight.w600,
                fontSize: 13.0,
                color: TrackletColors.info,
              ),
              textAlign: TextAlign.center,
            ),
            backgroundColor: TrackletColors.absentRed,
            duration: const Duration(milliseconds: 3500),
          ),
        );
        context.go('/login');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isDeleting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Could not delete account. Try again.',
              style: TrackletFonts.outfit(
                fontWeight: FontWeight.w500,
                fontSize: 12.5,
                color: TrackletColors.info,
              ),
            ),
            backgroundColor: TrackletColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = TrackletColors.isDark(context);

    return Dialog(
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(
        horizontal: TrackletSpacing.section,
      ),
      backgroundColor: Colors.transparent,
      alignment: Alignment.center,
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 420.0),
        decoration: BoxDecoration(
          color: TrackletColors.adaptiveSurface(context),
          borderRadius: TrackletRadii.roundedLg,
          border: Border.all(color: TrackletColors.adaptiveBorder(context)),
          boxShadow: const [
            BoxShadow(
              blurRadius: 24.0,
              color: TrackletColors.scrim,
              offset: Offset(0.0, 8.0),
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(TrackletSpacing.md),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Red Alert Icon Circle
                Container(
                  width: 40.0,
                  height: 40.0,
                  decoration: BoxDecoration(
                    color: TrackletColors.absentRed.withValues(
                      alpha: isDark ? 0.2 : 0.1,
                    ),
                    borderRadius: TrackletRadii.roundedXl,
                  ),
                  child: const Icon(
                    TrackletIcons.alertTriangle,
                    color: TrackletColors.absentRed,
                    size: 24.0,
                  ),
                ),
                const SizedBox(height: TrackletSpacing.xs),
                Text(
                  'Delete your account?',
                  textAlign: TextAlign.center,
                  style: TrackletFonts.outfit(
                    fontSize: 18.0,
                    fontWeight: FontWeight.w700,
                    color: TrackletColors.absentRed,
                  ),
                ),
                const SizedBox(height: TrackletSpacing.sm),

                // Prominent Warning Box
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: TrackletSpacing.md,
                    vertical: TrackletSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: TrackletColors.absentRed.withValues(
                      alpha: isDark ? 0.15 : 0.08,
                    ),
                    borderRadius: TrackletRadii.roundedCard,
                    border: Border.all(
                      color: TrackletColors.absentRed.withValues(
                        alpha: isDark ? 0.35 : 0.25,
                      ),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        TrackletIcons.alertCircle,
                        color: TrackletColors.absentRed,
                        size: 18.0,
                      ),
                      const SizedBox(width: TrackletSpacing.compactMd),
                      Expanded(
                        child: Text(
                          'Warning: This action is permanent. All your saved stops, alert rules, profile details, and login credentials will be erased immediately.',
                          style: TrackletFonts.outfit(
                            fontSize: 12.0,
                            fontWeight: FontWeight.w500,
                            color: TrackletColors.absentRed,
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: TrackletSpacing.sm),

                // Bullet points
                Align(
                  alignment: Alignment.centerLeft,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'This action will permanently delete:',
                        style: TrackletFonts.outfit(
                          fontSize: 13.0,
                          fontWeight: FontWeight.w600,
                          color: TrackletColors.adaptiveTextPrimary(context),
                        ),
                      ),
                      const SizedBox(height: TrackletSpacing.xs),
                      _buildBullet(
                        'Your email, student roll number & username',
                        isDark,
                      ),
                      const SizedBox(height: TrackletSpacing.xxs),
                      _buildBullet(
                        'All saved transit preferences & favorite routes',
                        isDark,
                      ),
                      const SizedBox(height: TrackletSpacing.xxs),
                      _buildBullet(
                        'All saved device settings and preferences',
                        isDark,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: TrackletSpacing.sm),

                // Monospace instruction & input
                Align(
                  alignment: Alignment.centerLeft,
                  child: RichText(
                    text: TextSpan(
                      style: TrackletFonts.outfit(
                        fontSize: 13.0,
                        color: TrackletColors.adaptiveTextSecondary(context),
                      ),
                      children: [
                        const TextSpan(text: 'Type '),
                        TextSpan(
                          text:
                              widget.username.isNotEmpty
                                  ? widget.username
                                  : 'DELETE',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: TrackletColors.adaptiveTextPrimary(context),
                          ),
                        ),
                        const TextSpan(text: ' to confirm account deletion.'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: TrackletSpacing.sm),
                TextFormField(
                  controller: _confirmationController,
                  autofocus: true,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Type ${widget.username} or DELETE',
                    hintStyle: TrackletFonts.outfit(
                      fontSize: 13.0,
                      color: TrackletColors.adaptiveTextSecondary(context),
                    ),
                    filled: true,
                    fillColor:
                        isDark
                            ? TrackletColors.darkSurfaceElevated
                            : TrackletColors.dangerInputSurface,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: TrackletSpacing.compactLg,
                      vertical: TrackletSpacing.md,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color:
                            isDark
                                ? TrackletColors.darkBorder
                                : TrackletColors.secondaryText,
                        width: 1.5,
                      ),
                      borderRadius: TrackletRadii.roundedSm,
                    ),
                    focusedBorder: const OutlineInputBorder(
                      borderSide: BorderSide(
                        color: TrackletColors.absentRed,
                        width: TrackletSpacing.xxs,
                      ),
                      borderRadius: TrackletRadii.roundedSm,
                    ),
                  ),
                  style: TrackletFonts.outfit(
                    fontSize: 14.0,
                    fontWeight: FontWeight.w600,
                    color: TrackletColors.adaptiveTextPrimary(context),
                  ),
                ),
                const SizedBox(height: TrackletSpacing.lg),

                // Delete Account Button (Danger)
                SizedBox(
                  width: double.infinity,
                  height: TrackletSpacing.minTouchTarget,
                  child: ElevatedButton(
                    onPressed:
                        _isConfirmationValid && !_isDeleting
                            ? _handleDelete
                            : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: TrackletColors.absentRed,
                      disabledBackgroundColor:
                          isDark
                              ? TrackletColors.darkSurfaceContainerHighest
                              : TrackletColors.alternate,
                      foregroundColor: TrackletColors.textInverse,
                      disabledForegroundColor:
                          TrackletColors.adaptiveTextSecondary(context),
                      elevation: 0,
                      shape: const RoundedRectangleBorder(
                        borderRadius: TrackletRadii.roundedSm,
                      ),
                    ),
                    child:
                        _isDeleting
                            ? const SizedBox(
                              width: TrackletSpacing.smallIcon,
                              height: TrackletSpacing.smallIcon,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.0,
                                color: TrackletColors.textInverse,
                              ),
                            )
                            : Text(
                              'Delete Account',
                              style: TrackletFonts.outfit(
                                fontSize: 15.0,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                  ),
                ),
                const SizedBox(height: TrackletSpacing.sm),

                // Cancel Button
                SizedBox(
                  width: double.infinity,
                  height: TrackletSpacing.minTouchTarget,
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      backgroundColor:
                          isDark
                              ? TrackletColors.darkSurfaceElevated
                              : TrackletColors.primaryBackground,
                      shape: RoundedRectangleBorder(
                        borderRadius: TrackletRadii.roundedSm,
                        side: BorderSide(
                          color: TrackletColors.adaptiveBorder(context),
                          width: 1.5,
                        ),
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: TrackletFonts.outfit(
                        fontSize: 15.0,
                        fontWeight: FontWeight.w600,
                        color: TrackletColors.adaptiveTextSecondary(context),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBullet(String text, [bool isDark = false]) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(
            top: TrackletSpacing.compact,
            right: TrackletSpacing.sm,
          ),
          width: TrackletSpacing.xs,
          height: TrackletSpacing.xs,
          decoration: BoxDecoration(
            color:
                isDark
                    ? TrackletColors.darkTextSecondary
                    : TrackletColors.primaryText,
            shape: BoxShape.circle,
          ),
        ),
        Expanded(
          child: Text(
            text,
            style: TrackletFonts.outfit(
              fontSize: 13.0,
              fontWeight: FontWeight.w400,
              color:
                  isDark
                      ? TrackletColors.darkTextPrimary
                      : TrackletColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}
