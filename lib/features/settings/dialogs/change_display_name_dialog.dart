import 'package:tracklet/design_system/tokens/typography.dart';
import 'package:flutter/material.dart';
import '../../../design_system/tokens/shadows.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/profile/profile.dart';
import '../../../data/profile/profile_repository.dart';
import '../../../design_system/tokens/colors.dart';
import '../../../design_system/components/icons/tracklet_icons.dart';
import '../../../design_system/tokens/spacing.dart';
import '../../../design_system/tokens/radii.dart';
import '../../../design_system/tokens/tracklet_fonts.dart';
import '../../profile/providers/profile_provider.dart';

/// Modal dialog matching Attendrix ChangeDisplayNameWidget styling and interaction.
class ChangeDisplayNameDialog extends ConsumerStatefulWidget {
  const ChangeDisplayNameDialog({super.key, required this.initialName});

  final String initialName;

  static Future<void> show(BuildContext context, {String initialName = ''}) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (context) => ChangeDisplayNameDialog(initialName: initialName),
    );
  }

  @override
  ConsumerState<ChangeDisplayNameDialog> createState() =>
      _ChangeDisplayNameDialogState();
}

class _ChangeDisplayNameDialogState
    extends ConsumerState<ChangeDisplayNameDialog> {
  late final TextEditingController _controller;
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialName);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() => _isSaving = true);
    try {
      final currentProfile =
          ref.read(profileStateProvider).value ??
          Profile(
            id: 'user-nitc-student',
            name: text,
            email: 'student@nitc.ac.in',
            rollNumber: 'B210000CS',
            semester: 'Semester 6',
            branch: 'Computer Science & Engineering',
            batch: '2026',
            hostel: 'MBH II',
          );
      final updated = currentProfile.copyWith(name: text);
      await ref.read(profileRepositoryProvider).saveProfile(updated);
      ref.invalidate(profileStateProvider);

      if (mounted) {
        Navigator.pop(context, text);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Display name updated successfully!',
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
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Could not update display name. Try again.',
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

  @override
  Widget build(BuildContext context) {
    final isDark = TrackletColors.isDark(context);

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
          color: TrackletColors.adaptiveSurfaceElevated(context),
          borderRadius: TrackletRadii.roundedCard,
          border: Border.all(
            color: TrackletColors.adaptiveCardBorder(context),
            width: 1.0,
          ),
          boxShadow: [
            BoxShadow(
              blurRadius: 16.0,
              color: TrackletColors.scrim.withValues(
                alpha: isDark ? 0.3 : 0.08,
              ),
              offset: const Offset(0.0, 4.0),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(TrackletSpacing.lg),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Change Display Name',
                  style: TrackletFonts.outfit(
                    fontSize: TrackletTypography.fontSize20,
                    fontWeight: TrackletTypography.weightBold,
                    color: TrackletColors.adaptiveTextPrimary(context),
                  ),
                ),
                const SizedBox(height: TrackletSpacing.xs),
                Text(
                  'Change how your name appears to others in BusTracker',
                  style: TrackletFonts.outfit(
                    fontSize: TrackletTypography.fontSize13,
                    fontWeight: TrackletTypography.weightMedium,
                    color: TrackletColors.adaptiveTextSecondary(context),
                  ),
                ),
                const SizedBox(height: TrackletSpacing.lg),
                TextFormField(
                  controller: _controller,
                  autofocus: true,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _handleSave(),
                  style: TextStyle(
                    color: TrackletColors.adaptiveTextPrimary(context),
                  ),
                  decoration: InputDecoration(
                    hintText: 'Type your name',
                    hintStyle: TrackletFonts.outfit(
                      fontSize: TrackletTypography.fontSize15,
                      fontWeight: TrackletTypography.weightMedium,
                      color: TrackletColors.adaptiveTextMuted(context),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: TrackletColors.adaptiveBorder(context),
                        width: TrackletSpacing.xxs,
                      ),
                      borderRadius: TrackletRadii.roundedButton,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color:
                            isDark
                                ? TrackletColors.primaryDark
                                : TrackletColors.primary,
                        width: TrackletSpacing.xxs,
                      ),
                      borderRadius: TrackletRadii.roundedButton,
                    ),
                    filled: true,
                    fillColor:
                        isDark
                            ? TrackletColors.darkSurfaceContainerHighest
                            : TrackletColors.surface,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: TrackletSpacing.lg,
                      vertical: TrackletSpacing.compactLg,
                    ),
                    suffixIcon:
                        _controller.text.isNotEmpty
                            ? IconButton(
                              icon: Icon(
                                TrackletIcons.x,
                                color: TrackletColors.adaptiveTextSecondary(
                                  context,
                                ),
                                size: 20.0,
                              ),
                              onPressed: () {
                                _controller.clear();
                                setState(() {});
                              },
                            )
                            : null,
                  ),
                  validator: (value) {
                    final trimmed = value?.trim() ?? '';
                    if (trimmed.isEmpty) {
                      return 'Please enter your display name';
                    }
                    if (trimmed.length < 2) {
                      return 'Name must be at least 2 characters';
                    }
                    if (trimmed.length > 50) {
                      return 'Name must be at most 50 characters';
                    }
                    return null;
                  },
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: TrackletSpacing.section),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        backgroundColor:
                            isDark
                                ? TrackletColors.darkSurfaceContainerHighest
                                : TrackletColors.alternate,
                        padding: const EdgeInsets.symmetric(
                          horizontal: TrackletSpacing.lg,
                          vertical: TrackletSpacing.md,
                        ),
                        shape: const RoundedRectangleBorder(
                          borderRadius: TrackletRadii.roundedButton,
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: TrackletFonts.outfit(
                          fontSize: TrackletTypography.fontSize15,
                          fontWeight: TrackletTypography.weightSemiBold,
                          color: TrackletColors.adaptiveTextPrimary(context),
                        ),
                      ),
                    ),
                    const SizedBox(width: TrackletSpacing.md),
                    ElevatedButton(
                      onPressed: _isSaving ? null : _handleSave,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: TrackletColors.primary,
                        foregroundColor: TrackletColors.textInverse,
                        elevation: TrackletShadows.elevationLevel0,
                        padding: const EdgeInsets.symmetric(
                          horizontal: TrackletSpacing.xl,
                          vertical: TrackletSpacing.md,
                        ),
                        shape: const RoundedRectangleBorder(
                          borderRadius: TrackletRadii.roundedButton,
                        ),
                      ),
                      child:
                          _isSaving
                              ? const SizedBox(
                                width: TrackletSpacing.smallIcon,
                                height: TrackletSpacing.smallIcon,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.0,
                                  color: TrackletColors.textInverse,
                                ),
                              )
                              : Text(
                                'Save',
                                style: TrackletFonts.outfit(
                                  fontSize: TrackletTypography.fontSize16,
                                  fontWeight: TrackletTypography.weightSemiBold,
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
    );
  }
}
