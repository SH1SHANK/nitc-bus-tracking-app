import 'package:tracklet/design_system/tokens/typography.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import '../../../design_system/tokens/shadows.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/validation/username_validator.dart';
import '../../../data/profile/profile_repository.dart';
import '../../../design_system/tokens/colors.dart';
import '../../../design_system/components/icons/tracklet_icons.dart';
import '../../../design_system/tokens/radii.dart';
import '../../../design_system/tokens/spacing.dart';
import '../../../design_system/tokens/tracklet_fonts.dart';
import '../../profile/providers/profile_provider.dart';

/// Modal dialog for editing the user's campus username with instant format
/// validation and debounced uniqueness checks against Supabase.
class ChangeUsernameDialog extends ConsumerStatefulWidget {
  const ChangeUsernameDialog({super.key, required this.currentUsername});

  final String currentUsername;

  static Future<void> show(
    BuildContext context, {
    required String currentUsername,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder:
          (context) => ChangeUsernameDialog(currentUsername: currentUsername),
    );
  }

  @override
  ConsumerState<ChangeUsernameDialog> createState() =>
      _ChangeUsernameDialogState();
}

class _ChangeUsernameDialogState extends ConsumerState<ChangeUsernameDialog> {
  late final TextEditingController _controller;
  Timer? _debounceTimer;

  bool _isChecking = false;
  bool? _isAvailable;
  String? _errorMessage;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.currentUsername);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onUsernameChanged(String text) {
    _debounceTimer?.cancel();
    final clean = text.replaceAll('@', '').trim().toLowerCase();

    if (clean == widget.currentUsername.toLowerCase()) {
      setState(() {
        _isChecking = false;
        _isAvailable = null;
        _errorMessage = null;
      });
      return;
    }

    final validation = UsernameValidator.validate(clean);
    if (!validation.isValid) {
      setState(() {
        _isChecking = false;
        _isAvailable = false;
        _errorMessage = validation.errorMessage;
      });
      return;
    }

    const reserved = [
      'admin',
      'root',
      'support',
      'nitc',
      'bustracker',
      'tracklet',
    ];
    if (reserved.contains(clean)) {
      setState(() {
        _isChecking = false;
        _isAvailable = false;
        _errorMessage = 'This username is reserved.';
      });
      return;
    }

    setState(() {
      _isChecking = true;
      _isAvailable = null;
      _errorMessage = null;
    });

    _debounceTimer = Timer(const Duration(milliseconds: 300), () async {
      try {
        final repo = ref.read(profileRepositoryProvider);
        final available = await repo.isUsernameAvailable(clean);
        if (!mounted) return;
        if (_controller.text.replaceAll('@', '').trim().toLowerCase() ==
            clean) {
          setState(() {
            _isChecking = false;
            _isAvailable = available;
            _errorMessage = available ? null : 'Username is already taken.';
          });
        }
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _isChecking = false;
          _isAvailable = null;
          _errorMessage = 'Could not verify username availability.';
        });
      }
    });
  }

  Future<void> _handleSubmit() async {
    final clean = _controller.text.replaceAll('@', '').trim().toLowerCase();
    if (clean == widget.currentUsername.toLowerCase()) {
      Navigator.pop(context);
      return;
    }

    final validation = UsernameValidator.validate(clean);
    if (!validation.isValid || _isAvailable != true) {
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final repo = ref.read(profileRepositoryProvider);
      await repo.changeUsername(clean);
      ref.invalidate(profileStateProvider);

      if (!mounted) return;
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Username updated to @$clean',
            style: TrackletFonts.outfit(
              fontWeight: TrackletTypography.weightSemiBold,
              fontSize: TrackletTypography.fontSize13,
              color: TrackletColors.info,
            ),
          ),
          backgroundColor: TrackletColors.success,
          duration: const Duration(milliseconds: 3000),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not update username: ${e.toString().replaceAll("Exception: ", "")}',
            style: TrackletFonts.outfit(
              fontWeight: TrackletTypography.weightSemiBold,
              fontSize: TrackletTypography.fontSize13,
              color: TrackletColors.info,
            ),
          ),
          backgroundColor: TrackletColors.error,
          duration: const Duration(milliseconds: 3500),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = TrackletColors.isDark(context);
    final clean = _controller.text.replaceAll('@', '').trim().toLowerCase();
    final isUnchanged = clean == widget.currentUsername.toLowerCase();
    final canSubmit =
        !_isSubmitting &&
        !_isChecking &&
        !isUnchanged &&
        _isAvailable == true &&
        _errorMessage == null;

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
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Change Username',
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
                    splashRadius: 20.0,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: TrackletSpacing.sm),
              Text(
                'Choose a unique campus handle between 3 and 20 characters.',
                style: TrackletFonts.outfit(
                  fontSize: TrackletTypography.fontSize13,
                  fontWeight: TrackletTypography.weightRegular,
                  color: TrackletColors.adaptiveTextSecondary(context),
                ),
              ),
              const SizedBox(height: TrackletSpacing.md),

              // Username input
              TextField(
                controller: _controller,
                onChanged: _onUsernameChanged,
                autocorrect: false,
                textCapitalization: TextCapitalization.none,
                style: TrackletFonts.outfit(
                  fontSize: TrackletTypography.fontSize15,
                  fontWeight: TrackletTypography.weightSemiBold,
                  color: TrackletColors.adaptiveTextPrimary(context),
                ),
                decoration: InputDecoration(
                  prefixText: '@',
                  prefixStyle: TrackletFonts.outfit(
                    fontSize: TrackletTypography.fontSize15,
                    fontWeight: TrackletTypography.weightBold,
                    color: TrackletColors.primary,
                  ),
                  hintText: 'new_username',
                  hintStyle: TrackletFonts.outfit(
                    fontSize: TrackletTypography.fontSize14,
                    color: TrackletColors.adaptiveTextSecondary(context),
                  ),
                  filled: true,
                  fillColor:
                      isDark
                          ? TrackletColors.darkSurfaceElevated
                          : TrackletColors.primaryBackground,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: TrackletSpacing.compactLg,
                    vertical: TrackletSpacing.compactLg,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: TrackletRadii.roundedInput,
                    borderSide: BorderSide(
                      color:
                          _errorMessage != null
                              ? TrackletColors.errorBorder
                              : TrackletColors.adaptiveBorder(context),
                      width: 1.5,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: TrackletRadii.roundedInput,
                    borderSide: BorderSide(
                      color:
                          _errorMessage != null
                              ? TrackletColors.errorBorder
                              : TrackletColors.primary,
                      width: 1.8,
                    ),
                  ),
                  suffixIcon:
                      _isChecking
                          ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: Center(
                              child: SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: TrackletColors.primary,
                                ),
                              ),
                            ),
                          )
                          : _isAvailable == true && !isUnchanged
                          ? const Icon(
                            TrackletIcons.checkCircle2,
                            color: TrackletColors.success,
                            size: 20,
                          )
                          : _errorMessage != null
                          ? const Icon(
                            TrackletIcons.alertCircle,
                            color: TrackletColors.errorBorder,
                            size: 20,
                          )
                          : null,
                ),
              ),

              // Validation / Status feedback
              if (_errorMessage != null) ...[
                const SizedBox(height: 6),
                Text(
                  _errorMessage!,
                  style: TrackletFonts.outfit(
                    fontSize: TrackletTypography.fontSize12,
                    fontWeight: TrackletTypography.weightMedium,
                    color: TrackletColors.errorBorder,
                  ),
                ),
              ] else if (_isAvailable == true && !isUnchanged) ...[
                const SizedBox(height: 6),
                Text(
                  'Username is available!',
                  style: TrackletFonts.outfit(
                    fontSize: TrackletTypography.fontSize12,
                    fontWeight: TrackletTypography.weightSemiBold,
                    color: TrackletColors.success,
                  ),
                ),
              ],

              const SizedBox(height: TrackletSpacing.lg),

              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed:
                        _isSubmitting ? null : () => Navigator.pop(context),
                    child: Text(
                      'Cancel',
                      style: TrackletFonts.outfit(
                        fontWeight: TrackletTypography.weightSemiBold,
                        color: TrackletColors.adaptiveTextSecondary(context),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: canSubmit ? _handleSubmit : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: TrackletColors.primary,
                      foregroundColor: TrackletColors.pure,
                      elevation: TrackletShadows.elevationLevel0,
                      shape: const RoundedRectangleBorder(
                        borderRadius: TrackletRadii.roundedMd,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: TrackletSpacing.section,
                        vertical: 11,
                      ),
                    ),
                    child:
                        _isSubmitting
                            ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: TrackletColors.pure,
                              ),
                            )
                            : Text(
                              'Save Username',
                              style: TrackletFonts.outfit(
                                fontWeight: TrackletTypography.weightBold,
                                fontSize: TrackletTypography.fontSize14,
                              ),
                            ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
