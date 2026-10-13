import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../data/preferences/user_preferences.dart';
import '../../../data/profile/profile.dart';
import '../../../data/profile/profile_repository.dart';
import '../../../data/supabase/supabase_client_provider.dart';
import '../../../design_system/tokens/colors.dart';
import '../../../design_system/tokens/spacing.dart';
import '../../../design_system/tokens/radii.dart';
import '../../../design_system/tokens/tracklet_fonts.dart';
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
    await Future<void>.delayed(const Duration(milliseconds: 600));

    try {
      // Reset local profile and user preferences
      await ref.read(userPreferencesProvider.notifier).resetPreferences();
      await ref
          .read(profileRepositoryProvider)
          .saveProfile(
            const Profile(
              id: 'guest',
              name: 'Guest Student',
              email: 'guest@nitc.ac.in',
            ),
          );
      ref.invalidate(profileStateProvider);

      try {
        final supabase = ref.read(supabaseClientProvider);
        if (supabase != null) {
          await supabase.auth.signOut();
        }
      } catch (_) {}

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Your account has been permanently deleted.',
              style: TrackletFonts.outfit(
                fontWeight: FontWeight.w600,
                fontSize: 12.0,
                color: TrackletColors.info,
              ),
              textAlign: TextAlign.center,
            ),
            backgroundColor: TrackletColors.error,
            duration: const Duration(milliseconds: 3500),
          ),
        );
        context.go('/login');
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isDeleting = false);
        Navigator.pop(context);
      }
    }
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
          borderRadius: TrackletRadii.roundedLg,
          boxShadow: [
            BoxShadow(
              blurRadius: 24.0,
              color: TrackletColors.scrim,
              offset: Offset(0.0, 8.0),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(TrackletSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Red Alert Icon Circle
              Container(
                width: TrackletSpacing.minTouchTarget,
                height: TrackletSpacing.minTouchTarget,
                decoration: const BoxDecoration(
                  color: TrackletColors.dangerSurface,
                  borderRadius: TrackletRadii.roundedXl,
                ),
                child: const Icon(
                  Icons.warning_amber_rounded,
                  color: TrackletColors.absentRed,
                  size: 28.0,
                ),
              ),
              const SizedBox(height: TrackletSpacing.sm),
              Text(
                'Delete your account?',
                textAlign: TextAlign.center,
                style: TrackletFonts.outfit(
                  fontSize: 19.0,
                  fontWeight: FontWeight.w700,
                  color: TrackletColors.absentRed,
                ),
              ),
              const SizedBox(height: TrackletSpacing.md),

              // Bullet points
              Align(
                alignment: Alignment.centerLeft,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'This action will permanently delete:',
                      style: TrackletFonts.outfit(
                        fontSize: 14.0,
                        fontWeight: FontWeight.w500,
                        color: TrackletColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: TrackletSpacing.compact),
                    _buildBullet('Your email, student roll number & username'),
                    const SizedBox(height: TrackletSpacing.xs),
                    _buildBullet(
                      'All saved transit preferences & favorite routes',
                    ),
                    const SizedBox(height: TrackletSpacing.xs),
                    _buildBullet('All commute notification registrations'),
                  ],
                ),
              ),
              const SizedBox(height: TrackletSpacing.lg),

              // Monospace instruction & input
              Align(
                alignment: Alignment.centerLeft,
                child: RichText(
                  text: TextSpan(
                    style: TrackletFonts.outfit(
                      fontSize: 13.0,
                      color: TrackletColors.secondaryText,
                    ),
                    children: [
                      const TextSpan(text: 'Type '),
                      TextSpan(
                        text:
                            widget.username.isNotEmpty
                                ? widget.username
                                : 'DELETE',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: TrackletColors.textPrimary,
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
                    color: TrackletColors.secondaryText,
                  ),
                  filled: true,
                  fillColor: TrackletColors.dangerInputSurface,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: TrackletSpacing.compactLg,
                    vertical: TrackletSpacing.md,
                  ),
                  enabledBorder: const OutlineInputBorder(
                    borderSide: BorderSide(
                      color: TrackletColors.secondaryText,
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
                  color: TrackletColors.textPrimary,
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
                    disabledBackgroundColor: TrackletColors.alternate,
                    foregroundColor: TrackletColors.textInverse,
                    disabledForegroundColor: TrackletColors.secondaryText,
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
                    backgroundColor: TrackletColors.primaryBackground,
                    shape: const RoundedRectangleBorder(
                      borderRadius: TrackletRadii.roundedSm,
                      side: BorderSide(
                        color: TrackletColors.alternate,
                        width: 1.5,
                      ),
                    ),
                  ),
                  child: Text(
                    'Cancel',
                    style: TrackletFonts.outfit(
                      fontSize: 15.0,
                      fontWeight: FontWeight.w600,
                      color: TrackletColors.secondaryText,
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

  Widget _buildBullet(String text) {
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
          decoration: const BoxDecoration(
            color: TrackletColors.primaryText,
            shape: BoxShape.circle,
          ),
        ),
        Expanded(
          child: Text(
            text,
            style: TrackletFonts.outfit(
              fontSize: 13.0,
              fontWeight: FontWeight.w400,
              color: TrackletColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}
